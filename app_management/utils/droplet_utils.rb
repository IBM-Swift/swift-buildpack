#!/usr/bin/env ruby
##
# Copyright IBM Corporation 2017
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

require 'timeout'
require 'socket'

class DropletUtils
  private_class_method :new
  class << self
    # Return the (constant) name of the proxy config filename relative to the app dir. A glorified Global Constant
    #
    # @return [String] the include file name.
    def proxy_config_filename
      File.join('.app-management', 'bin', 'proxy.config')
    end

    # Determine if someone is listening on the specified port. Typically used to see if the runtime is listening on the port
    def port_bound?(port)
      port_bound = false
      begin
        Timeout.timeout(5) do
          begin
            s = TCPSocket.open('localhost', port.to_i)
            # runtime is listening on port
            s.close
            port_bound = true
          rescue StandardError
            # imperfect code for an imperfect world. Parent class of network exceptions
            port_bound = false
          end
        end
      rescue Timeout::Error
        port_bound = false
      end
      port_bound
    end

    #------------------------------------------------------------------------------------
    # Return an available port within the specified port range.
    #
    # @param [String] start_port starting port to check
    # @param [String] end_port last port to check
    # @return [String] returns the first available port from start_port to end_port
    #------------------------------------------------------------------------------------
    def find_port(start_port, end_port)
      port = start_port
      while port < end_port
        begin
          s = TCPSocket.open('localhost', port)
          s.close
          port += 1
        rescue
          return port
        end
      end
      raise "Unable to find free port. Starting port #{start_port} and ending port #{end_port}"
    end
  end
end
