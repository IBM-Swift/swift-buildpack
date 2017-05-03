require 'spec_helper'
require 'rspec'
require 'tmpdir'
require_relative '../../../app_management/utils/handler.rb'

describe Utils::Handler do
  let(:base_dir) { Dir.mktmpdir }

  describe '#proxy_required?' do
    context 'info hash has no value for proxy_required' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', {}, 'start') }

      it 'returns true' do
        expect(handler.proxy_required?).to be_truthy
      end
    end

    context 'info hash has true value for proxy_required' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', { 'proxy_required' => true }, 'start') }

      it 'returns true' do
        expect(handler.proxy_required?).to be_truthy
      end
    end

    context 'info hash has false value for proxy_required' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', { 'proxy_required' => false }, 'start') }

      it 'returns false' do
        expect(handler.proxy_required?).not_to be_truthy
      end
    end
  end

  describe '#background?' do
    context 'info hash has no value for background' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', {}, 'start') }

      it 'returns false' do
        expect(handler.background?).not_to be_truthy
      end
    end

    context 'info hash has true value for background' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', { 'background' => true }, 'start') }

      it 'returns true' do
        expect(handler.background?).to be_truthy
      end
    end

    context 'info hash has false value for background' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', { 'background' => false }, 'start') }

      it 'returns false' do
        expect(handler.background?).not_to be_truthy
      end
    end
  end

  describe '#public?' do
    context 'info hash has no value for public' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', {}, 'start') }

      it 'returns true' do
        expect(handler.public?).to be_truthy
      end
    end

    context 'info hash has true value for public' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', { 'public' => true }, 'start') }

      it 'returns true' do
        expect(handler.public?).to be_truthy
      end
    end

    context 'info hash has false value for public' do
      let(:handler) { described_class.new(base_dir, 'test-handler-name', { 'public' => false }, 'start') }

      it 'returns false' do
        expect(handler.public?).not_to be_truthy
      end
    end
  end
end
