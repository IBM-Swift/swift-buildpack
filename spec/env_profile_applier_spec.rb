require 'fileutils'
require 'spec_helper'
require 'rspec'
require 'tmpdir'
require_relative '../lib/env_profile_applier.rb'

describe EnvProfileApplier do
  let(:app_dir) { Dir.mktmpdir }
  subject(:env_profile_applier) { described_class.new(app_dir) }

  describe '#apply_env_profile' do
    context 'env profile does not exist' do
      it 'raises an error' do
        allow(subject).to receive(:bp_dir).and_return('non-existent-directory')
        expect { subject.apply_env_profile }.to raise_error(Errno::ENOENT)
      end
    end

    context 'env profile exists' do
      let(:config_dir) { Dir.mktmpdir }
      let(:config_file) do <<-CONFIG_FILE
---
"ibm:env1":
  MANAGEMENT_SERVER_URL: https://rtmgmt.env1.bluemix.net
  cloud_controller_url: https://api.env1.bluemix.net
  authorization_endpoint: https://login.env1.bluemix.net/UAALoginServerWAR

"ibm:env2":
  MANAGEMENT_SERVER_URL: https://rtmgmt.env2.bluemix.net
  cloud_controller_url: https://api.env2.bluemix.net
  authorization_endpoint: https://login.env2.bluemix.net/UAALoginServerWAR
CONFIG_FILE
      end

      before do
        FileUtils.mkdir_p(File.join(config_dir, 'config'))
        File.open(File.join(config_dir, 'config', 'env.yml'), 'w') { |f| f.write(config_file) }
        allow(subject).to receive(:bp_dir).and_return(config_dir)
        allow(subject).to receive(:profiles).and_return(%w(ibm:env1 ibm:env2))
      end

      it 'creates a bluemix_env.sh file in the app\'s .profile.d folder with variables from the last env specified in the config file' do
        subject.apply_env_profile
        expect(File.exist?(File.join(app_dir, '.profile.d', 'bluemix_env.sh'))).to be_truthy
        expect(File.read(File.join(app_dir, '.profile.d', 'bluemix_env.sh'))).to eq(<<-ENV_SCRIPT
export MANAGEMENT_SERVER_URL="https://rtmgmt.env2.bluemix.net"
export cloud_controller_url="https://api.env2.bluemix.net"
export authorization_endpoint="https://login.env2.bluemix.net/UAALoginServerWAR"
ENV_SCRIPT
)
      end
    end
  end

  describe '#log_env' do
    context 'there are no configuration profiles' do
      it 'prints a message stating that no profiles were applied' do
        allow(subject).to receive(:profiles).and_return([])
        expect_any_instance_of(Kernel).to receive(:puts).with('-----> No configuration profiles applied')
        subject.send(:log_env, 'env.yml')
      end
    end

    context 'there is one configuration profile' do
      let(:profiles) { %w(env1) }

      it 'prints a message stating that it applied the configuration profile' do
        allow(subject).to receive(:profiles).and_return(profiles)
        expect_any_instance_of(Kernel).to receive(:puts).with('-----> Applied configuration profiles: ["env1"]')
        subject.send(:log_env, 'env.yml')
      end
    end

    context 'there are multiple configuration profile' do
      let(:profiles) { %w(env1 env2) }

      it 'prints a message stating that it applied the configuration profiles delimited by commas' do
        allow(subject).to receive(:profiles).and_return(profiles)
        expect_any_instance_of(Kernel).to receive(:puts).with('-----> Applied configuration profiles: ["env1", "env2"]')
        subject.send(:log_env, 'env.yml')
      end
    end

    context 'the specified env file name exists' do
      let(:profiles) { %w(env1 env2) }

      before do
        File.open(File.join(app_dir, 'env.yml'), 'w') { |f| f.write('hello world') }
      end

      it 'prints messages stating that it created bluemix_env.sh and including the content of the specified file' do
        allow(subject).to receive(:profiles).and_return(profiles)
        expect_any_instance_of(Kernel).to receive(:puts).with(anything)
        expect_any_instance_of(Kernel).to receive(:puts).with("-----> Generated 'bluemix_env.sh' in application's '.profile.d' folder")
        expect_any_instance_of(Kernel).to receive(:puts).with("'bluemix_env.sh' contents:\nhello world")
        subject.send(:log_env, File.join(app_dir, 'env.yml'))
      end
    end

    context 'the specified env file name does not exist' do
      let(:profiles) { %w(env1 env2) }

      it 'does not print messages stating that it created bluemix_env.sh' do
        allow(subject).to receive(:profiles).and_return(profiles)
        expect_any_instance_of(Kernel).to receive(:puts).with(anything)
        expect_any_instance_of(Kernel).not_to receive(:puts).with("-----> Generated 'bluemix_env.sh' in application's '.profile.d' folder")
        expect_any_instance_of(Kernel).not_to receive(:puts).with(/'bluemix_env.sh' contents:\n.*/)
        subject.send(:log_env, File.join(app_dir, 'env-nonexistent.yml'))
      end
    end
  end

  describe '#copy_variables' do
    context 'configuration parameter is nil' do
      it 'raises a NoMethodError' do
        expect { subject.send(:copy_variables, nil, nil) }.to raise_error(NoMethodError)
      end
    end

    context 'configuration parameter is not nil' do
      let(:configuration) { { 'key1' => 'value1', 'key2' => { 'key21': 'value2.1', 'key22': 'value2.2' }, '' => 'empty key', 'key4' => %w(key41 key42 key43) } }

      context 'variables parameter is nil' do
        it 'raises a NoMethodError' do
          expect { subject.send(:copy_variables, nil, configuration) }.to raise_error(NoMethodError)
        end
      end

      context 'variables parameter is not a hash' do
        let(:variables) { '[]' }

        it 'raises a NoMethodError' do
          expect { subject.send(:copy_variables, nil, configuration) }.to raise_error(NoMethodError)
        end
      end

      context 'variables parameter is a hash' do
        let(:variables) { {} }

        it 'does not raise any errors' do
          expect { subject.send(:copy_variables, variables, configuration) }.not_to raise_error
        end

        it 'copies all non-array, non-hash, and non-empty key values from configuration to variables' do
          subject.send(:copy_variables, variables, configuration)
          expect(variables['key1']).to eq(configuration['key1'])
          expect(variables['key2']).to be_nil
          expect(variables['']).to be_nil
          expect(variables['key4']).to be_nil
        end
      end
    end
  end

  describe '#profiles' do
    context 'IBM_ENV_PROFILE is set' do
      context 'it contains a single value with trailing whitespace' do
        before do
          ENV['IBM_ENV_PROFILE'] = 'env1 '
        end

        it 'returns an array containing the single value with extra whitespace stripped' do
          expect(subject.send(:profiles)).to eq(%w(env1))
        end
      end

      context 'it contains a single value with no trailing whitespace' do
        before do
          ENV['IBM_ENV_PROFILE'] = 'env1'
        end

        it 'returns an array containing the single value' do
          expect(subject.send(:profiles)).to eq(%w(env1))
        end
      end

      context 'it contains multiple values separated by commas and whitespace' do
        before do
          ENV['IBM_ENV_PROFILE'] = 'env1, env2, env3'
        end

        it 'returns an array of values with extra whitespace stripped' do
          expect(subject.send(:profiles)).to eq(%w(env1 env2 env3))
        end
      end

      context 'it contains multiple values seperated by commas and no whitespace' do
        before do
          ENV['IBM_ENV_PROFILE'] = 'env1,env2,env3'
        end

        it 'returns an array of values with extra whitespace stripped' do
          expect(subject.send(:profiles)).to eq(%w(env1 env2 env3))
        end
      end
    end

    context 'IBM_ENV_PROFILE is not set' do
      before do
        ENV['IBM_ENV_PROFILE'] = nil
      end

      context 'BLUEMIX_REGION is set' do
        before do
          ENV['BLUEMIX_REGION'] = 'env5'
        end

        it 'returns an array containing the value in BLUEMIX_REGION' do
          expect(subject.send(:profiles)).to eq(%w(env5))
        end
      end

      context 'BLUEMIX_REGION is not set' do
        before do
          ENV['BLUEMIX_REGION'] = nil
        end

        it 'returns an empty array' do
          expect(subject.send(:profiles)).to eq([])
        end
      end
    end
  end
end
