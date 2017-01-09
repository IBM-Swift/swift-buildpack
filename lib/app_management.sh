#!/usr/bin/env bash
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

function installAgent() {
  mkdir $BUILD_DIR/.app-management
  mkdir $BUILD_DIR/.app-management/utils
  mkdir $BUILD_DIR/.app-management/handlers
  mkdir $BUILD_DIR/.app-management/scripts

  cp $BP_DIR/app_management/scripts/* $BUILD_DIR/.app-management/scripts
  cp $BP_DIR/app_management/utils/* $BUILD_DIR/.app-management/utils
  cp -ra $BP_DIR/app_management/handlers/* $BUILD_DIR/.app-management/handlers

  cp $BP_DIR/app_management/initial_startup.rb $BUILD_DIR/.app-management
  cp $BP_DIR/app_management/env.json $BUILD_DIR/.app-management

  chmod +x $BUILD_DIR/.app-management/utils/*
  chmod +x $BUILD_DIR/.app-management/scripts/*
  chmod -R +x $BUILD_DIR/.app-management/handlers/
  chmod +x $BUILD_DIR/.app-management/initial_startup.rb
}

# https://docs.cloudfoundry.org/buildpacks/custom.html#release-script
function updateStartCommands() {
  # Update start command on start script (used by agent/initial startup)
  local start_command=$(sed -n -e '/^web:/p' ${BUILD_DIR}/Procfile | sed 's/^web: //')
  sed -i s#%COMMAND%#"${start_command}"# "${BUILD_DIR}"/.app-management/scripts/start
  # Use initial_startup to start application
  sed -i 's#web:.*#web: ./.app-management/initial_startup.rb#' $BUILD_DIR/Procfile
  status "Updated start command in Procfile:"
  cat ${BUILD_DIR}/Procfile | indent

  #if test -f ${BUILD_DIR}/Procfile; then
  #  status "updateStartCommands fi 1"
  #  local start_command=$(sed -n -e '/^web:/p' ${BUILD_DIR}/Procfile | sed 's/^web: //')
  #   sed -i s#%COMMAND%#"${start_command}"# "${BUILD_DIR}"/.app-management/scripts/start

    # Use initial_startup to start application
  #  sed -i 's#web:.*#web: ./.app-management/initial_startup.rb#' $BUILD_DIR/Procfile
  #else
  #  status "updateStartCommands fi 2"
  #  sed -i s#%COMMAND%#"npm start"# "${BUILD_DIR}"/.app-management/scripts/start
    # Use initial_startup to start application
  #  touch $BUILD_DIR/Procfile
  #  echo "web: ./.app-management/initial_startup.rb" > $BUILD_DIR/Procfile
  #fi

  # Update env vars used for dev mode
  #echo "export BOOT_SCRIPT=${start_cmd}" >> ${BUILD_DIR}/.profile.d/bluemix_env.sh
}

function generateAppMgmtInfo() {
  status "generateAppMgmtInfo start"
  local CONTAINER="warden"
  local SSH_ENABLED="false"
  local PROXY_SUPPORTED='["v1", "v2"]'

  # Generate app management info file. proxy_enabled is set during startup.
cat > $BUILD_DIR/.app-management/app_mgmt_info.json << EOL
{
  "container": "$CONTAINER",
  "ssh_enabled": $SSH_ENABLED,
  "proxy_enabled": false,
  "proxy_supported_version": $PROXY_SUPPORTED
}
EOL
status "generateAppMgmtInfo end"
}

function copyLLDBServer() {
  # Copy lldb-server executable to .swift-bin
  find $CACHE_DIR/$SWIFT_NAME_VERSION -name "lldb-server-*" -type f -perm /a+x -exec cp {} $BUILD_DIR/.swift-bin/lldb-server \;

  #TO BE REMOVED
  echo "COPYING LLDBD!!!!!!!"
  find $CACHE_DIR/$SWIFT_NAME_VERSION -name "lldb" -type f -perm /a+x -exec cp {} $BUILD_DIR/.swift-bin/lldb \;
  ls -la $BUILD_DIR/.swift-bin
  echo "COPIED LLDBD!!!!!!!"
  find $CACHE_DIR/$SWIFT_NAME_VERSION -name "lldb" -type f -perm /a+x
  echo "ANYTHING HERE???"
  #TO BE REMOVED
}

function downloadPython() {
  status "Getting Python"
  local pkgs=('libpython2.7')
  download_packages "${pkgs[@]}"
}

function removePythonDEBs() {
  find $APT_CACHE_DIR/archives -name "*python*.deb" -type f -delete
}

function installAppManagement() {
  status "installAppManagement start"
  # Find boot script file
  start_cmd=$($BP_DIR/lib/find_start_cmd.rb $BUILD_DIR)

  status "start_cmd (app_management): $start_cmd"

  if [ "$start_cmd" == "" ]; then
    status "WARNING: App Management cannot be installed because the start command could not be found."
    status "WARNING: To install App Management utilities, specify a start command for your Swift application in a 'Procfile'."
  else
    # Install development mode utilities
    installAgent && updateStartCommands && generateAppMgmtInfo && copyLLDBServer && downloadPython
    status "installAppManagement end"
  fi

  status "installAppManagement end"
}

install_app_management() {
  # Install App Management only if user asked for it
  if [ "$INSTALL_BLUEMIX_APP_MGMT" == "true" ]; then
    status "Installing App Management"
    installAppManagement
    status "Finished installing App Management"
  else
    removePythonDEBs
    status "Skipping installation of App Management"
  fi
}