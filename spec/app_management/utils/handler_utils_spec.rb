require 'spec_helper'
require 'rspec'
require_relative '../../../app_management/utils/simple_logger.rb'
require_relative '../../../app_management/utils/handler_utils.rb'

describe Utils::HandlerUtils do
  describe '#get_configuration' do
    context 'valid user provided env variable is set' do
      before do
        ENV['BLUEMIX_APP_MGMT_VALIDTESTVAR'] = <<-YAML
          key1:
          key2: value2
        YAML
      end

      it 'returns a hash of values' do
        expect(Utils::SimpleLogger).not_to receive(:error)
        expect(Utils::HandlerUtils.get_configuration('validtestvar')).to eq('key1' => nil, 'key2' => 'value2')
      end

      after do
        ENV['BLUEMIX_APP_MGMT_VALIDTESTVAR'] = nil
      end
    end

    context 'user provided env variable is set but contains invalid syntax' do
      before do
        ENV['BLUEMIX_APP_MGMT_INVALIDTESTVAR'] = <<-YAML
          ---
          key1:
          key2: value2
        YAML
      end

      it 'logs an error message but does not throw an exception' do
        expect(Utils::SimpleLogger).to receive(:error).with('Configuration value in environment variable BLUEMIX_APP_MGMT_INVALIDTESTVAR has invalid syntax: (<unknown>): mapping values are not allowed in this context at line 2 column 15')
        expect(Utils::HandlerUtils.get_configuration('invalidtestvar')).to eq({})
      end

      after do
        ENV['BLUEMIX_APP_MGMT_INVALIDTESTVAR'] = nil
      end
    end

    context 'user provided env variable is set but contains invalid value' do
      before do
        ENV['BLUEMIX_APP_MGMT_INVALIDVALUETESTVAR'] = <<-YAML
        ---
        YAML
      end

      it 'logs an error message but does not throw an exception' do
        expect(Utils::SimpleLogger).to receive(:error).with('Configuration value in environment variable BLUEMIX_APP_MGMT_INVALIDVALUETESTVAR is not valid: ---')
        expect(Utils::HandlerUtils.get_configuration('invalidvaluetestvar')).to eq({})
      end

      after do
        ENV['BLUEMIX_APP_MGMT_INVALIDVALUETESTVAR'] = nil
      end
    end

    context 'user provided env variable is not set' do
      before do
        ENV['BLUEMIX_APP_MGMT_NOTSETVAR'] = nil
      end

      it 'returns an empty hash with no error messages' do
        expect(Utils::SimpleLogger).not_to receive(:error)
        expect(Utils::HandlerUtils.get_configuration('notsetvar')).to eq({})
      end
    end
  end

  describe '#environment_variable_name' do
    context 'with lowercase handler name' do
      it 'returns environment variable in all uppercase' do
        expect(Utils::HandlerUtils.send(:environment_variable_name, 'test')).to eq('BLUEMIX_APP_MGMT_TEST')
      end
    end

    context 'with mixed case handler name' do
      it 'returns environment variable in all uppercase' do
        expect(Utils::HandlerUtils.send(:environment_variable_name, 'test')).to eq('BLUEMIX_APP_MGMT_TEST')
      end
    end
  end
end
