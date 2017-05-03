require 'bundler/setup'
require 'rspec/retry'
require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter 'spec'
  add_filter 'compile-extensions'
  add_filter 'vendor'
end

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.verbose_retry = true
  config.default_retry_count = 3
  config.default_sleep_interval = 5

  config.filter_run_excluding cached: ENV['BUILDPACK_MODE'] == 'uncached'
  config.filter_run_excluding uncached: ENV['BUILDPACK_MODE'] == 'cached'
end
