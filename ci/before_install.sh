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


# Install Cloud Foundry command line
set -e

BLUEMIX_REGION=$1
BLUEMIX_USER=$2
BLUEMIX_PASS=$3
GHE_USER=$4
GHE_TOKEN=$5

wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
echo "deb http://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
sudo apt-get update
sudo apt-get install cf-cli
export CF_DIAL_TIMEOUT=30
cf version
cf login -a https://$BLUEMIX_REGION -u $BLUEMIX_USER -p $BLUEMIX_PASS -s applications-ci -o $BLUEMIX_USER
# Clone test repos
git clone https://github.com/IBM-Bluemix/Kitura-Starter
git clone -b bluemix-estado https://github.com/IBM-Bluemix/swift-helloworld.git
git clone https://$GHE_USER:$GHE_TOKEN@github.ibm.com/IBM-Swift/credentials-buildpack-test.git
