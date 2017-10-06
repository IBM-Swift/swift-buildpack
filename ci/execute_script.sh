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

./ci/performance_validator.sh Kitura-Starter $KITURA_STARTER_PUSH_TIME $TIMES_TO_REPEAT_TO_SUCCESS $KITURA_STARTER_REPUSH_TIME
rm -rf Kitura-Starter
./ci/performance_validator.sh swift-helloworld $SWIFT_HELLOWORLD_PUSH_TIME $TIMES_TO_REPEAT_TO_SUCCESS $SWIFT_HELLOWORLD_REPUSH_TIME
cp -R credentials-buildpack-test/.ssh swift-helloworld/.ssh
chmod 600 swift-helloworld/.ssh/swiftdevops_test_rsa
# Following replacement line below assumes the dependencies element in the Package.swift file is "dependencies: [", followed by each package definition in its own line
sed -i 's/^ *dependencies: \[$/dependencies: [\n\t.Package(url: "git@github.ibm.com\:IBM-Swift\/credentials-buildpack-test.git", majorVersion: 1, minor: 0),/' swift-helloworld/Package.swift
./ci/performance_validator.sh swift-helloworld $SWIFT_HELLOWORLD_PUSH_TIME $TIMES_TO_REPEAT_TO_SUCCESS $SWIFT_HELLOWORLD_REPUSH_TIME
rm -rf swift-helloworld
# If all above steps succeeded, then create Git tags
./ci/create_git_tag.sh
