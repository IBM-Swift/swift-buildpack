#!/usr/bin/env ruby
##
# Copyright IBM Corporation 2016,2017
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

# points to /home/vcap/app
app_dir = File.expand_path('..', File.dirname(__FILE__))

APP_MGMT_DIR = File.join(app_dir, '.app-management')

TEST = "HELLO!"

test_var = "HELLO2"

$LOAD_PATH.unshift APP_MGMT_DIR

require 'json'
require_relative 'utils/handlers'
require_relative 'utils/simple_logger'


def handler_list
  return nil if ENV['BLUEMIX_APP_MGMT_ENABLE'].nil?
  ENV['BLUEMIX_APP_MGMT_ENABLE'].downcase.split('+').map(&:strip)
end



def start_runtime(app_dir)
  exec(".app-management/scripts/start #{ENV['PORT']}", chdir: app_dir)
end

def start_proxy(app_dir)
  Utils::SimpleLogger.info('Starting proxy agent')
  exec('.app-management/bin/proxyAgent', chdir: app_dir)
end

def run(app_dir, handlers, background)
  return if handlers.empty?

  command = handlers.map(&:start_script).join(' ; ')
  command = "( #{command} ) &" if background
  system(command.to_s, chdir: app_dir)
end

def run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)
  Utils::SimpleLogger.warning("Ignoring unrecognized App Management utilities: #{invalid_handlers.join(', ')}") unless invalid_handlers.empty?
  Utils::SimpleLogger.info("Activating App Management utilities: #{valid_handlers.join(', ')}")

  # sort handlers for sync and async execution
  sync_handlers, async_handlers = handlers.executions(valid_handlers)

  # execute sync handlers
  run(app_dir, sync_handlers, false)

  # execute async handlers
  run(app_dir, async_handlers, true)
end

def write_json(file, key, value)
  hash = JSON.parse(File.read(file))
  hash[key] = value
  File.open(file, 'w') do |f|
    f.write(hash.to_json)
  end
end


def startup_with_handlers

  Utils::SimpleLogger.info("app_mgmt_dir3: #{APP_MGMT_DIR}")
  handlers_dir = File.join(APP_MGMT_DIR, 'handlers')

  handlers = Utils::Handlers.new(handlers_dir)

  # validate handlers
  valid_handlers, invalid_handlers = handlers.validate(handler_list)

  # check if proxy agent is required
  proxy_required = handlers.proxy_required?(valid_handlers)

  if proxy_required
    # check instance index
    index = JSON.parse(ENV['VCAP_APPLICATION'])['instance_index']
    if index != 0
      # Start the runtime normally. Only allow dev mode on index 0
      start_runtime(app_dir)
    else
      # Run handlers
      run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)

      # Start proxy
      write_json(File.join(APP_MGMT_DIR, 'app_mgmt_info.json'), 'proxy_enabled', 'true')
      start_proxy(app_dir)
    end
  else
    # Run handlers
    run_handlers(app_dir, handlers, valid_handlers, invalid_handlers)

    # Start runtime
    start_runtime(app_dir)
  end
end

def startup
  Utils::SimpleLogger.info("App Management handlers: #{handler_list}")
  Utils::SimpleLogger.info("app_mgmt_dir10: #{APP_MGMT_DIR}")

  # No handlers are specified. Start the runtime normally.
  start_runtime(app_dir) if handler_list.nil? || handler_list.empty?
  # Otherwise, start with handlers
  startup_with_handlers unless handler_list.nil? || handler_list.empty?
end

# do not execute this block if file is "required" rather than being run directly
startup if __FILE__ == $PROGRAM_NAME
