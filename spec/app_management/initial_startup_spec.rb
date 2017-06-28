require 'spec_helper'
require 'rspec'
require 'tmpdir'
require_relative '../../app_management/initial_startup.rb'
require_relative '../../app_management/utils/simple_logger.rb'

module InitialStartup
end

describe InitialStartup do
  let(:app_dir) { Dir.mktmpdir }
  let(:proxy_handler) { double(start_script: './proxy_script') }
  let(:sync_handler) { double(start_script: './sync_script') }
  let(:other_handler) { double(start_script: './other_script') }

  describe '#handler_list' do
    context 'BLUEMIX_APP_MGMT_ENABLE is set' do
      before do
        ENV['BLUEMIX_APP_MGMT_ENABLE'] = 'devconsole+shell'
      end

      it 'returns an array of handlers' do
        expect(handler_list).to match(%w[devconsole shell])
      end
    end

    context 'BLUEMIX_APP_MGMT_ENABLE is not set' do
      before do
        ENV['BLUEMIX_APP_MGMT_ENABLE'] = nil
      end

      it 'returns nil' do
        expect(handler_list).to be_nil
      end
    end
  end

  describe '#start_runtime' do
    before do
      ENV['PORT'] = '9080'
    end

    it 'calls a bash script passing the $PORT environment variable' do
      allow_any_instance_of(Kernel).to receive(:exec).with(anything)
      expect_any_instance_of(Kernel).to receive(:exec).with('.app-management/scripts/start 9080', chdir: app_dir)
      start_runtime(app_dir)
    end
  end

  describe '#start_proxy' do
    it 'calls a bash script relative to the app dir and prints an info level log message' do
      allow_any_instance_of(Kernel).to receive(:exec).with(anything)
      expect(Utils::SimpleLogger).to receive(:info).with('Starting proxy agent')
      expect_any_instance_of(Kernel).to receive(:exec).with('.app-management/bin/proxyAgent', chdir: app_dir)
      start_proxy(app_dir)
    end
  end

  describe '#run' do
    context 'there are no handlers' do
      it 'returns nil' do
        expect(run(app_dir, {}, false)).to be_nil
      end
    end

    context 'there is 1 handler' do
      context 'background is false' do
        it 'makes a system call to execute the handler start script from the app directory' do
          allow_any_instance_of(Kernel).to receive(:system).with(anything)
          expect_any_instance_of(Kernel).to receive(:system).with(proxy_handler.start_script.to_s, chdir: app_dir)
          run(app_dir, [proxy_handler], false)
        end
      end

      context 'background is true' do
        it 'makes a system call to execute the handler start script in the background from the app directory' do
          allow_any_instance_of(Kernel).to receive(:system).with(anything)
          expect_any_instance_of(Kernel).to receive(:system).with("( #{proxy_handler.start_script} ) &", chdir: app_dir)
          run(app_dir, [proxy_handler], true)
        end
      end
    end

    context 'there are multiple handlers' do
      context 'background is false' do
        it 'makes a system call to execute the handlers start scripts from the app directory' do
          allow_any_instance_of(Kernel).to receive(:system).with(anything)
          expect_any_instance_of(Kernel).to receive(:system).with("#{proxy_handler.start_script} ; #{other_handler.start_script}", chdir: app_dir)
          run(app_dir, [proxy_handler, other_handler], false)
        end
      end

      context 'background is true' do
        it 'makes a system call to execute the handlers start scripts in the background from the app directory' do
          allow_any_instance_of(Kernel).to receive(:system).with(anything)
          expect_any_instance_of(Kernel).to receive(:system).with("( #{proxy_handler.start_script} ; #{other_handler.start_script} ) &", chdir: app_dir)
          run(app_dir, [proxy_handler, other_handler], true)
        end
      end
    end
  end

  describe '#run_handlers' do
    # proxy_handler and sync_handler are returned as sync_handlers, other_handler is returned as async_handlers
    let(:handler_executions) { [[proxy_handler, sync_handler], [other_handler]] }
    let(:handlers) { double(:handlers, executions: handler_executions) }

    context 'there are valid handlers' do
      let(:valid_handlers) { [proxy_handler, sync_handler, other_handler] }

      context 'there are no invalid handlers' do
        let(:invalid_handlers) { [] }

        it 'logs an info level message including a list of valid handlers' do
          allow(self).to receive(:run).and_return(0)
          allow(Utils::SimpleLogger).to receive(:warning)
          expect(Utils::SimpleLogger).to receive(:info).with("Activating App Management utilities: #{valid_handlers.join(', ')}")
          run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)
        end

        it 'does not log any warning level messages' do
          allow(self).to receive(:run).and_return(0)
          allow(Utils::SimpleLogger).to receive(:info)
          expect(Utils::SimpleLogger).not_to receive(:warning).with(anything)
          run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)
        end
      end

      context 'there are invalid handlers' do
        let(:invalid_handlers) { [other_handler] }

        it 'logs a warning level message including a list of invalid handlers' do
          allow(self).to receive(:run).and_return(0)
          allow(Utils::SimpleLogger).to receive(:info)
          expect(Utils::SimpleLogger).to receive(:warning).with(/#{invalid_handlers}/)
          run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)
        end
      end
    end
  end

  describe '#write_json' do
    context 'the given file does not exist' do
      it 'raises an exception' do
        expect(File.exist?(File.join(app_dir, 'bad_file_name.json'))).not_to be_truthy
        expect { write_json(File.join(app_dir, 'bad_file_name.json'), 'newKey1', 'newValue1') }.to raise_error(Errno::ENOENT)
      end
    end

    context 'the given file exists, but contains invalid json' do
      before do
        File.open(File.join(app_dir, 'invalid_syntax.json'), 'w') { |f| f.write 'not valid json' }
      end

      it 'raises an exception' do
        expect { write_json(File.join(app_dir, 'invalid_syntax.json'), 'newKey1', 'newValue1') }.to raise_error(JSON::ParserError)
      end
    end

    context 'the given file exists and contains valid json' do
      before do
        File.open(File.join(app_dir, 'valid_syntax.json'), 'w') { |f| f.write '{"key1": "value1"}' }
      end

      it 'adds the given key and value to the json file' do
        expect { write_json(File.join(app_dir, 'valid_syntax.json'), 'newKey1', 'newValue1') }.not_to raise_error
        json_hash = JSON.parse(File.read(File.join(app_dir, 'valid_syntax.json')))
        expect(json_hash['key1']).to eq('value1')
        expect(json_hash['newKey1']).to eq('newValue1')
      end
    end
  end

  describe '#startup_with_handlers' do
    context 'proxy is required' do
      context 'it is not the first index' do
        before do
          ENV['VCAP_APPLICATION'] =  {"instance_index": 1}.to_json
        end

        it 'calls start_runtime' do
          allow_any_instance_of(Object).to receive(:handler_list).and_return(%w[handler1 handler2])
          allow_any_instance_of(Utils::Handlers).to receive(:proxy_required?).and_return(true)
          allow_any_instance_of(Object).to receive(:start_runtime).with(anything)
          expect_any_instance_of(Object).to receive(:start_runtime).with(app_dir)
          startup_with_handlers(app_dir)
        end

        after do
          ENV['VCAP_APPLICATION'] = nil
        end
      end

      context 'it is the first index' do
        before do
          ENV['VCAP_APPLICATION'] = {"instance_index": 0}.to_json
        end

        it 'calls run_handlers, write_json, and start_proxy' do
          allow_any_instance_of(Object).to receive(:handler_list).and_return(%w[handler1 handler2])
          allow_any_instance_of(Utils::Handlers).to receive(:proxy_required?).and_return(true)
          expect_any_instance_of(Object).to receive(:run_handlers)
          expect_any_instance_of(Object).to receive(:write_json)
          expect_any_instance_of(Object).to receive(:start_proxy)
          startup_with_handlers(app_dir)
        end

        after do
          ENV['VCAP_APPLICATION'] = nil
        end

      end
    end

    context 'proxy not required' do
      it 'calls run_handlers and start_runtime' do
        allow_any_instance_of(Object).to receive(:handler_list).and_return(%w[handler1 handler2])
        allow_any_instance_of(Utils::Handlers).to receive(:proxy_required?).and_return(false)
        allow_any_instance_of(Object).to receive(:start_runtime).with(anything)
        expect_any_instance_of(Object).to receive(:start_runtime).with(app_dir)
        startup_with_handlers(app_dir)
      end
    end
  end

  describe '#startup' do
    context 'handler_list is nil' do
      it 'calls start_runtime and not startup_with_handlers' do
        allow_any_instance_of(Object).to receive(:start_runtime).with(anything)
        expect_any_instance_of(Object).not_to receive(:startup_with_handlers).with(anything)
        expect_any_instance_of(Object).to receive(:start_runtime).with(anything)
        expect(Utils::SimpleLogger).to receive(:info).with('App Management handlers: ')
        startup
      end
    end

    context 'handler_list is not nil or empty' do
      it 'calls startup_with_handlers' do
        allow_any_instance_of(Object).to receive(:handler_list).and_return(%w[handler1 handler2])
        allow_any_instance_of(Object).to receive(:startup_with_handlers)
        expect_any_instance_of(Object).not_to receive(:start_runtime)
        expect_any_instance_of(Object).to receive(:startup_with_handlers)
        expect(Utils::SimpleLogger).to receive(:info).with(anything)
        startup
      end
    end
  end
end
