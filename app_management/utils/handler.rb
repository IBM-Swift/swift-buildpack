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

module Utils
  class Handler
    PUBLIC = 'public'.freeze
    PROXY_REQUIRED = 'proxy_required'.freeze
    BACKGROUND = 'background'.freeze

    attr_reader :start_script

    def initialize(base_dir, name, info, type = 'start')
      @info = info
      @start_script = "#{base_dir}/#{type}-#{name}/run"
    end

    def proxy_required?
      # default is true
      @info[PROXY_REQUIRED].nil? || @info[PROXY_REQUIRED]
    end

    def background?
      # default is false
      if @info[BACKGROUND].nil?
        false
      else
        @info[BACKGROUND]
      end
    end

    def public?
      # default is true
      @info[PUBLIC].nil? || @info[PUBLIC]
    end
  end
end
