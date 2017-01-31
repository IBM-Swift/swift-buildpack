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

APPLICATION_DIR=$1
APPLICATION_TIMEOUT=$2
TIMES_TO_REPEAT=$3
APPLICATION_REPUSH_TIMEOUT=$4
GHE_USER=$5
GHE_TOKEN=$6


push_application () {
	local DELETE_FLAG=$1
	local TIMEOUT=$2
	local RETVAL=1

	if [ "$DELETE_FLAG" = true ]; then
		echo "Executing cf push tests..."
		echo "Clearing out any previous instances of: $APPLICATION_DIR"
		cf delete $APPLICATION_DIR -r -f
	else
		echo "Executing cf re-push tests..."
	fi

	echo "$APPLICATION_DIR threshold value is: $TIMEOUT"
	echo

	for num in `seq 1 $TIMES_TO_REPEAT`; do
		START_TIME=$SECONDS
		cf push -b https://github.com/IBM-Swift/swift-buildpack.git#$TRAVIS_BRANCH
		ELAPSED_TIME=$(($SECONDS - $START_TIME))

		if [ "$DELETE_FLAG" = true ]; then
			cf delete $APPLICATION_DIR -r -f
		fi

		echo "$APPLICATION_DIR took $ELAPSED_TIME seconds."

		if [ "$ELAPSED_TIME" -lt "$TIMEOUT" ]; then
			echo "Application was under threshold value."
			RETVAL=0
			break
		fi

		echo "$APPLICATION_DIR took longer than the threshold value."
	done
	echo "$RETVAL"
}

cd $APPLICATION_DIR

if [ -z $GHE_USER ]; then
    echo "Preparing for standard application push..."

else
    echo "Preparing for SSH Key validation application push..."
    mkdir .ssh/

    touch .ssh/config

    echo "Host github.ibm.com
    HostName github.ibm.com
    User git
    IdentityFile ~/.ssh/swiftdevops_test_rsa" >> .ssh/config

    git clone https://$GHE_USER:$GHE_TOKEN@github.ibm.com/IBM-Swift/credentials-buildpack-test.git
    cp credentials-buildpack-test/swiftdevops_test_rsa .ssh
    chmod 600 .ssh/swiftdevops_test_rsa
    rm -rf credentials-buildpack-test

    sed -i 's/^ *dependencies:.*/dependencies: [\.Package(url: "git@github.ibm.com:IBM-Swift\/credentials-buildpack-test.git", majorVersion: 1, minor: 0)]/' Package.swift
fi

push_application true $APPLICATION_TIMEOUT
passed=$?

push_application false $APPLICATION_REPUSH_TIMEOUT
passed_repush=$?
cd ..

! (( $passed | $passed_repush ));

exit $?
