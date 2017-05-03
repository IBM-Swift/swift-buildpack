require 'spec_helper'
require 'rspec'
require 'tmpdir'
require_relative '../lib/start_cmd_finder.rb'

describe StartCmdFinder do
  let(:app_dir) { Dir.mktmpdir }

  subject { described_class.new(app_dir) }

  describe '#find_start_cmd' do
    context 'Procfile exists' do
      before do
        # create the Procfile
        File.open(File.join(app_dir, 'Procfile'), 'w') { |f| f.write('web: MyWebApplication') }
      end

      it 'returns the start command' do
        expect(subject.find_start_cmd).to match('MyWebApplication')
      end
    end
  end
end
