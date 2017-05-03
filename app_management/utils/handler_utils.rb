##
# Copyright IBM Corporation 2016
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

require 'yaml'
require_relative 'simple_logger'

module Utils
  class HandlerUtils
    def self.get_configuration(handler_name)
      var_name = environment_variable_name(handler_name)
      user_provided = ENV[var_name]
      if user_provided
        begin
          user_provided_value = YAML.safe_load(user_provided)
          return user_provided_value if user_provided_value.is_a?(Hash)
          SimpleLogger.error("Configuration value in environment variable #{var_name} is not valid: #{user_provided_value}")
        rescue Psych::SyntaxError => ex
          SimpleLogger.error("Configuration value in environment variable #{var_name} has invalid syntax: #{ex}")
        end
      end
      {}
    end

    ENVIRONMENT_VARIABLE_PATTERN = 'BLUEMIX_APP_MGMT_'.freeze

    def self.environment_variable_name(handler_name)
      ENVIRONMENT_VARIABLE_PATTERN + handler_name.upcase
    end

    private_constant :ENVIRONMENT_VARIABLE_PATTERN

    private_class_method :environment_variable_name
  end
end
