require 'fileutils'
require 'spec_helper'
require 'rspec'
require 'tmpdir'
require_relative '../../../app_management/utils/simple_logger.rb'

describe Utils::SimpleLogger do
  describe '#warning' do
    it 'prints a warning message to stderr' do
      expect($stderr).to receive(:puts).with('-----> Warning: warning details')
      Utils::SimpleLogger.warning('warning details')
    end
  end

  describe '#error' do
    it 'prints an error message to stderr' do
      expect($stderr).to receive(:puts).with('-----> Error: error details')
      Utils::SimpleLogger.error('error details')
    end
  end

  describe '#info' do
    it 'prints an info message to stdout' do
      expect($stdout).to receive(:puts).with('-----> info details')
      Utils::SimpleLogger.info('info details')
    end
  end
end
