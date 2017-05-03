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

class StartCmdFinder
  def initialize(app_dir)
    @app_dir = app_dir
  end

  def find_start_cmd
    procfile_file = File.join(@app_dir, 'Procfile')
    start_cmd = ''

    if File.exist? procfile_file
      procfile_content = File.open(procfile_file, 'r', &:read)
      # verify this works with multiple lines via unit test
      if (matched = /web:\s+(.+)/.match(procfile_content))
        start_cmd = matched[1]
      end
    end

    start_cmd
  end
end
