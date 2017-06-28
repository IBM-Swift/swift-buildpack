require 'fileutils'
require 'spec_helper'
require 'rspec'
require 'tmpdir'
require 'timeout'
require 'socket'
require_relative '../../../app_management/utils/droplet_utils.rb'

describe DropletUtils do
  # pick an open port between 8080 and 9080 for testing
  let(:server_port) { %x(bash -c 'for p in {8080..9080}; do if [ "`lsof -i:$p`" == "" ]; then echo $p; break; fi; done;').strip }

  describe '#proxy_config_filename' do
    it 'returns a constant name of the proxy config filename' do
      expect(DropletUtils.proxy_config_filename).to match(/proxy.config/)
    end
  end

  describe '#port_bound?' do
    context 'the port is not already bound' do
      it 'returns false' do
        expect(DropletUtils.port_bound?(server_port)).not_to be_truthy
      end
    end

    context 'the port is already bound' do
      it 'returns true' do
        s = TCPServer.new server_port
        expect(DropletUtils.port_bound?(server_port)).to be_truthy
        s.close
      end
    end

    context 'there is a timeout error' do
      it 'returns false' do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        expect(DropletUtils.port_bound?(server_port)).not_to be_truthy
      end
    end
  end

  describe '#find_port' do
    context 'at least one port is available in the given range' do
      it 'returns the first available port' do
        expect(DropletUtils.find_port(8080, 9080)).to eq(server_port.to_i)
      end
    end

    context 'the given range of ports begins with a port that is not available' do
      it 'returns the first available port' do
        s = TCPServer.new server_port
        expect(DropletUtils.find_port(8080, 9080)).to eq(%x(bash -c 'for p in {8080..9080}; do if [ "`lsof -i:$p`" == "" ]; then echo $p; break; fi; done;').strip.to_i)
        s.close
      end
    end

    context 'no ports are available in the given range' do
      it 'raises an exception' do
        s = TCPServer.new server_port
        expect { DropletUtils.find_port(server_port.to_i, server_port.to_i) }.to raise_error("Unable to find free port. Starting port #{server_port} and ending port #{server_port}")
        s.close
      end
    end
  end
end
