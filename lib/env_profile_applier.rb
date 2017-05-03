#!/usr/bin/env ruby
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

require 'yaml'
require 'fileutils'

class EnvProfileApplier
  def initialize(app_dir, log_env = false)
    @app_dir = app_dir
    @log_env = log_env
    @bp_dir = File.expand_path(File.join('..', '..'), __FILE__)
  end

  def apply_env_profile
    profiled_dir = File.join(@app_dir, '.profile.d')

    # load config file
    config = YAML.load_file(File.join(bp_dir, 'config', 'env.yml'))
    variables = {}
    # apply default variables
    copy_variables(variables, config)

    # apply profiles
    profiles.each do |profile|
      profile = profile.strip
      profile_variables = config[profile]
      copy_variables(variables, profile_variables) unless profile_variables.nil?
    end

    # create bluemix_env.sh file in app's '.profile.d' folder
    FileUtils.mkdir_p(profiled_dir)
    env_file_name = File.join(profiled_dir, 'bluemix_env.sh')
    env_file = File.new(env_file_name, 'w')
    variables.each do |key, value|
      env_file.puts("export #{key}=\"#{value}\"")
    end
    env_file.close

    log_env(env_file_name) if @log_env
  end

  private

  attr_reader :bp_dir

  def log_env(env_file_name)
    if profiles.empty?
      puts '-----> No configuration profiles applied'
    else
      puts "-----> Applied configuration profiles: #{profiles}"
      if File.exist?(env_file_name)
        env_contents = File.open(env_file_name, &:read)
        puts "-----> Generated 'bluemix_env.sh' in application's '.profile.d' folder"
        puts "'bluemix_env.sh' contents:\n#{env_contents}"
      end
    end
  end

  def copy_variables(variables, configuration)
    configuration.each do |key, value|
      key = key.strip
      variables[key] = value unless value.is_a?(Hash) || value.is_a?(Array) || key.empty?
    end
  end

  def profiles
    profiles_var = ENV['IBM_ENV_PROFILE']
    if profiles_var.nil?
      region = ENV['BLUEMIX_REGION']
      region.nil? ? [] : [region]
    else
      profiles_var.split(',').map(&:strip)
    end
  end
end
