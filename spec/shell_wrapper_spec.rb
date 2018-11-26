require 'spec_helper'
require 'rspec'
require 'tmpdir'
require 'open3'

module SwiftBuildpack
  module ShellWrapper
  end
end

# only run these tests on Linux
describe SwiftBuildpack::ShellWrapper, :if => (/darwin/ =~ RUBY_PLATFORM).nil? do
  let(:app_dir) { Dir.mktmpdir }
  let(:apt_cache_dir) { Dir.mktmpdir }
  let(:buildpack_dir) { File.join(File.dirname(__FILE__), '../') }
  let(:common_shell_script) { File.join(buildpack_dir, 'lib', 'common.sh') }
  let(:default_swift_version) { '4.2.1' }

  describe '#install_packages' do
    context 'deb file exists in $APT_CACHE_DIR/archives' do
      before do
        ENV['APT_CACHE_DIR'] = apt_cache_dir
        ENV['BUILD_DIR'] = app_dir
        system("mkdir -p #{File.join(apt_cache_dir, 'archives')}")
        FileUtils.cp_r(File.join(buildpack_dir, 'spec', 'fixtures', 'swiftbuildpacktest_1.0-1.deb'), File.join(apt_cache_dir, 'archives', 'swiftbuildpacktest_1.0-1.deb'))
      end

      it 'extracts deb files into $BUILD_DIR/.apt/' do
        cmd = "bash -c 'source #{common_shell_script}; install_packages;'"
        Open3.popen3(cmd) do |_in, out, err, wait_thr|
          expect(err.read).to be_empty
          expect(out.read).to match('Installing swiftbuildpacktest_1.0-1.deb')
          expect(wait_thr.value.success?).to be_truthy
          expect(File.exist?(File.join(app_dir, '.apt', 'lib', 'dummy.so'))).to be_truthy
        end
      end
    end
  end

  describe '#get_swift_version' do
    before do
      ENV['BUILD_DIR'] = app_dir
    end

    context '.swift-version file exists' do
      context 'specifies version in format of swift-version-RELEASE' do
        before do
          File.open(File.join(app_dir, '.swift-version'), 'w') { |f| f.write('swift-2.0-RELEASE') }
        end

        it 'outputs the version in the .swift-version file' do
          cmd = "bash -c 'source #{common_shell_script}; get_swift_version;'"
          Open3.popen3(cmd) do |_in, out, err, wait_thr|
            expect(err.read).to be_empty
            expect(out.read).to match('2.0')
            expect(wait_thr.value.success?).to be_truthy
          end
        end
      end

      context 'specifies a plain version number' do
        before do
          File.open(File.join(app_dir, '.swift-version'), 'w') { |f| f.write('2.0') }
        end

        it 'outputs the version in the .swift-version file' do
          cmd = "bash -c 'source #{common_shell_script}; get_swift_version;'"
          Open3.popen3(cmd) do |_in, out, err, wait_thr|
            expect(err.read).to be_empty
            expect(out.read).to match('2.0')
            expect(wait_thr.value.success?).to be_truthy
          end
        end
      end
    end

    context '.swift-version does not exist' do
      it 'outputs the default version' do
        cmd = "bash -c 'source #{common_shell_script}; get_swift_version;'"
        Open3.popen3(cmd) do |_in, out, err, wait_thr|
          expect(err.read).to be_empty
          expect(out.read).to match(default_swift_version)
          expect(wait_thr.value.success?).to be_truthy
        end
      end
    end
  end
end
