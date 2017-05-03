#!/bin/bash
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

set -ev

if [ "$TRAVIS_BRANCH" == "deploy-release" ]; then
  cd $TRAVIS_BUILD_DIR
  # These lines are commented about because Ruby packages are installed at the beginning of the CI
  #gem install bundler
  #bundle install --gemfile=cf.Gemfile
  #BUNDLE_GEMFILE=cf.Gemfile bundle install
  #BUNDLE_GEMFILE=cf.Gemfile bundle update
  BUNDLE_GEMFILE=cf.Gemfile bundle exec buildpack-packager --cached --use-custom-manifest manifest.yml
  export VERSION=`cat VERSION`
  export DATE=`date +"%Y%m%d-%H%M"`
  mv swift_buildpack-cached-v$VERSION.zip buildpack_swift_v$VERSION-$DATE.zip
  git tag $VERSION -f
  git push https://$GITHUB_USER:$GITHUB_PASS@github.com/IBM-Swift/swift-buildpack.git --tags --force --quiet
fi
