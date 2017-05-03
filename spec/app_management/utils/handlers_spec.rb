require 'fileutils'
require 'spec_helper'
require 'rspec'
require 'tmpdir'
require_relative '../../../app_management/utils/handlers.rb'
require_relative '../../../app_management/utils/simple_logger.rb'

describe Utils::Handlers do
  let(:handlers_dir) { Dir.mktmpdir }
  subject do
    FileUtils.mkdir_p(File.join(handlers_dir, 'start-proxy'))
    File.open(File.join(handlers_dir, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true"}') }
    described_class.new(handlers_dir)
  end

  context 'a handler json file contains invalid json' do
    let(:handlers_dir2) { Dir.mktmpdir }

    before do
      FileUtils.mkdir_p(File.join(handlers_dir2, 'start-proxy'))
      FileUtils.mkdir_p(File.join(handlers_dir2, 'start-other'))
      File.open(File.join(handlers_dir2, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true"}') }
      File.open(File.join(handlers_dir2, 'start-other', 'info.json'), 'w') { |f| f.write('{"invalid:"json"}') }
    end

    it 'logs an error level error message' do
      expect(Utils::SimpleLogger).to receive(:error).with(/start-other.info\.json/)
      described_class.new(handlers_dir2)
    end

    it 'does not raise an exception' do
      allow(Utils::SimpleLogger).to receive(:error).with(anything)
      expect { described_class.new(handlers_dir2) }.not_to raise_error
    end
  end

  describe '#get_handler' do
    context 'handler exists' do
      it 'returns the handler' do
        expect(subject.get_handler('proxy')).not_to be_nil
      end
    end

    context 'handler does not exist' do
      it 'returns nil' do
        expect(subject.get_handler('not-a-real-handler')).to be_nil
      end
    end
  end

  describe '#validate' do
    context 'there are no enabled handlers' do
      let(:enabled_handlers) { [] }

      it 'returns empty arrays for both valid and invalid handlers' do
        expect(subject.validate(enabled_handlers)).to eq([[], []])
      end
    end

    context 'there are enabled handlers' do
      let(:valid_handlers) { %w[proxy valid] }
      let(:invalid_handlers) { %w[invalid other] }
      let(:validate_handlers_dir) { Dir.mktmpdir }
      let(:enabled_handlers) { %w[invalid valid proxy other] }
      let(:handlers) do
        allow(Utils::SimpleLogger).to receive(:error).with(anything)
        FileUtils.mkdir_p(File.join(validate_handlers_dir, 'start-proxy'))
        File.open(File.join(validate_handlers_dir, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true"}') }

        FileUtils.mkdir_p(File.join(validate_handlers_dir, 'start-other'))
        File.open(File.join(validate_handlers_dir, 'start-other', 'info.json'), 'w') { |f| f.write('{"public:"true"}') }

        FileUtils.mkdir_p(File.join(validate_handlers_dir, 'start-valid'))
        File.open(File.join(validate_handlers_dir, 'start-valid', 'info.json'), 'w') { |f| f.write('{"public":"true"}') }

        FileUtils.mkdir_p(File.join(validate_handlers_dir, 'start-invalid'))
        File.open(File.join(validate_handlers_dir, 'start-invalid', 'info.json'), 'w') { |f| f.write('{"public:"true"}') }

        described_class.new(validate_handlers_dir)
      end

      it 'returns an array whose first element is an array containing valid handlers and second element is invalid handlers' do
        result_handlers = handlers.validate(enabled_handlers)
        expect(result_handlers[0].sort).to eq(valid_handlers)
        expect(result_handlers[1].sort).to eq(invalid_handlers)
      end
    end
  end

  describe '#proxy_required?' do
    context 'there are no enabled handlers' do
      let(:enabled_handlers) { [] }

      it 'returns false' do
        expect(subject.proxy_required?(enabled_handlers)).not_to be_truthy
      end
    end

    context 'there is a proxy handler and no noproxy handler' do
      let(:enabled_handlers) { %w[proxy] }
      let(:proxy_required_handlers_dir) { Dir.mktmpdir }
      let(:handlers) do
        FileUtils.mkdir_p(File.join(proxy_required_handlers_dir, 'start-proxy'))
        File.open(File.join(proxy_required_handlers_dir, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true", "proxy_required":"true"}') }

        described_class.new(proxy_required_handlers_dir)
      end

      it 'returns true' do
        expect(handlers.proxy_required?(enabled_handlers)).to be_truthy
      end
    end

    context 'there is a proxy handler and a noproxy handler' do
      let(:enabled_handlers) { %w[proxy noproxy] }
      let(:noproxy_required_handlers_dir) { Dir.mktmpdir }
      let(:handlers) do
        FileUtils.mkdir_p(File.join(noproxy_required_handlers_dir, 'start-proxy'))
        File.open(File.join(noproxy_required_handlers_dir, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true", "proxy_required":"true"}') }
        FileUtils.mkdir_p(File.join(noproxy_required_handlers_dir, 'start-noproxy'))
        File.open(File.join(noproxy_required_handlers_dir, 'start-noproxy', 'info.json'), 'w') { |f| f.write('{"public":"true"}') }

        described_class.new(noproxy_required_handlers_dir)
      end

      it 'returns false' do
        expect(handlers.proxy_required?(enabled_handlers)).not_to be_truthy
      end
    end
  end

  describe '#executions' do
    let(:proxy_sync_handler) { Utils::Handler.new(executions_handlers_dir, 'proxy', JSON.parse('{"public":"true", "proxy_required":"true"}')) }
    let(:noproxy_sync_handler) { Utils::Handler.new(executions_handlers_dir, 'noproxy', JSON.parse('{"public":"true"}')) }
    let(:proxy_async_handler) { Utils::Handler.new(executions_handlers_dir, 'proxy', JSON.parse('{"public":"true", "background":"true", "proxy_required":"true"}')) }
    let(:noproxy_async_handler) { Utils::Handler.new(executions_handlers_dir, 'noproxy', JSON.parse('{"public":"true", "background":"true"}')) }

    context 'there are no enabled handlers' do
      let(:enabled_handlers) { [] }

      it 'returns an array of empty arrays' do
        expect(subject.executions(enabled_handlers)).to eq([[], []])
      end
    end

    context 'there are sync handlers but no async handlers' do
      let(:executions_handlers_dir) { Dir.mktmpdir }
      let(:enabled_handlers) { %w[noproxy proxy] }
      let(:handlers) do
        allow(Utils::Handler).to receive(:new).and_call_original
        allow(Utils::Handler).to receive(:new).with(anything, 'proxy', anything, anything).and_return(proxy_sync_handler)
        allow(Utils::Handler).to receive(:new).with(anything, 'noproxy', anything, anything).and_return(noproxy_sync_handler)
        FileUtils.mkdir_p(File.join(executions_handlers_dir, 'start-proxy'))
        File.open(File.join(executions_handlers_dir, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true", "proxy_required":"true"}') }
        FileUtils.mkdir_p(File.join(executions_handlers_dir, 'start-noproxy'))
        File.open(File.join(executions_handlers_dir, 'start-noproxy', 'info.json'), 'w') { |f| f.write('{"public":"true"}') }

        described_class.new(executions_handlers_dir)
      end

      it 'returns an array of sync handlers and an empty array for async handlers' do
        sync, async = handlers.executions(enabled_handlers)
        expect(sync).to eq([noproxy_sync_handler, proxy_sync_handler])
        expect(async.empty?).to be_truthy
      end
    end

    context 'there are async handlers but no sync handlers' do
      let(:executions_handlers_dir) { Dir.mktmpdir }
      let(:enabled_handlers) { %w[noproxy proxy] }
      let(:handlers) do
        allow(Utils::Handler).to receive(:new).and_call_original
        allow(Utils::Handler).to receive(:new).with(anything, 'proxy', anything, anything).and_return(proxy_async_handler)
        allow(Utils::Handler).to receive(:new).with(anything, 'noproxy', anything, anything).and_return(noproxy_async_handler)
        FileUtils.mkdir_p(File.join(executions_handlers_dir, 'start-proxy'))
        File.open(File.join(executions_handlers_dir, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true", "background":"true", "proxy_required":"true"}') }
        FileUtils.mkdir_p(File.join(executions_handlers_dir, 'start-noproxy'))
        File.open(File.join(executions_handlers_dir, 'start-noproxy', 'info.json'), 'w') { |f| f.write('{"public":"true", "background":"true"}') }

        described_class.new(executions_handlers_dir)
      end

      it 'returns an array of sync handlers and an empty array for async handlers' do
        sync, async = handlers.executions(enabled_handlers)
        expect(async).to eq([noproxy_async_handler, proxy_async_handler])
        expect(sync.empty?).to be_truthy
      end
    end

    context 'there are both sync handlers and async handlers' do
      let(:executions_handlers_dir) { Dir.mktmpdir }
      let(:enabled_handlers) { %w[proxy noproxy] }
      let(:handlers) do
        allow(Utils::Handler).to receive(:new).and_call_original
        allow(Utils::Handler).to receive(:new).with(anything, 'proxy', anything, anything).and_return(proxy_sync_handler)
        allow(Utils::Handler).to receive(:new).with(anything, 'noproxy', anything, anything).and_return(noproxy_async_handler)
        FileUtils.mkdir_p(File.join(executions_handlers_dir, 'start-proxy'))
        File.open(File.join(executions_handlers_dir, 'start-proxy', 'info.json'), 'w') { |f| f.write('{"public":"true", "proxy_required":"true"}') }
        FileUtils.mkdir_p(File.join(executions_handlers_dir, 'start-noproxy'))
        File.open(File.join(executions_handlers_dir, 'start-noproxy', 'info.json'), 'w') { |f| f.write('{"public":"true", "background":"true"}') }

        described_class.new(executions_handlers_dir)
      end

      it 'returns an array of sync handlers and an array of async handlers' do
        sync, async = handlers.executions(enabled_handlers)
        expect(sync).to eq([proxy_sync_handler])
        expect(async).to eq([noproxy_async_handler])
      end
    end
  end
end
