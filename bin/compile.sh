#!/usr/bin/env bash
##
# Copyright IBM Corporation 2016,2017
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

# ----------------------------------------------------------------------------- #
# Configuration and setup.                                                      #
# ----------------------------------------------------------------------------- #
set -e
set -o pipefail

if [[ "${BP_DEBUG}X" != "X" ]]; then
  # Show all commands
  set -x
fi

# Global variables
BUILD_DIR=$1
CACHE_DIR=$2
BP_DIR=$(cd $(dirname $0); cd ..; pwd)
compile_buildpack_bin=$BP_DIR/bin
BUILDPACK_PATH=$BP_DIR
SWIFT_BUILD_DIR=.build
# If leveraging CACHE_DIR for tar files, then we'd need CACHED_ITEMS
#CACHED_ITEMS=()

# Apply Bluemix-specific environment configuration profile
$BP_DIR/lib/apply_env_profile.rb $BUILD_DIR

source $BP_DIR/compile-extensions/lib/common
# Check environment support
$BP_DIR/compile-extensions/bin/check_stack_support
# Load convenience functions like status(), echo(), and indent()
source ${BP_DIR}/lib/common.sh
# Load caching functions
source ${BP_DIR}/lib/cache.sh
# Load app management extension
source ${BP_DIR}/lib/app_management.sh

# Log default Swift version
status "Default supported Swift version is $DEFAULT_SWIFT_VERSION"

# Remove .build and Packages folders (in case they were pushed)
rm -rf $BUILD_DIR/.build
rm -rf $BUILD_DIR/Packages

# ----------------------------------------------------------------------------- #
# Create libraries and binnaries folders for droplet                            #
# ----------------------------------------------------------------------------- #
mkdir -p $BUILD_DIR/.swift-lib
mkdir -p $BUILD_DIR/.swift-bin

# ----------------------------------------------------------------------------- #
# Configuration for apt-get package installs                                    #
# ----------------------------------------------------------------------------- #
status "Configure for apt-get installs..."
APT_CACHE_DIR="$CACHE_DIR/apt/cache"
APT_STATE_DIR="$CACHE_DIR/apt/state"
APT_OPTIONS="-o debug::nolocking=true -o dir::cache=$APT_CACHE_DIR -o dir::state=$APT_STATE_DIR"
APT_PCKGS_LIST_UPDATED=false
mkdir -p "$APT_CACHE_DIR/archives/partial"
mkdir -p "$APT_STATE_DIR/lists/partial"
mkdir -p $BUILD_DIR/.apt

# ----------------------------------------------------------------------------- #
# Write profile script (for apt) and set additional environment variables       #
# ----------------------------------------------------------------------------- #
status "Writing profile script..."
mkdir -p $BUILD_DIR/.profile.d
cat <<EOF >$BUILD_DIR/.profile.d/apt.sh
export PATH="\$HOME/.apt/usr/bin:\$PATH"
export LD_LIBRARY_PATH="\$HOME/.apt/usr/lib/x86_64-linux-gnu:\$HOME/.apt/usr/lib/i386-linux-gnu:\$HOME/.apt/usr/lib:\$LD_LIBRARY_PATH"
export LIBRARY_PATH="\$HOME/.apt/usr/lib/x86_64-linux-gnu:\$HOME/.apt/usr/lib/i386-linux-gnu:\$HOME/.apt/usr/lib:\$LIBRARY_PATH"
export INCLUDE_PATH="\$HOME/.apt/usr/include:\$INCLUDE_PATH"
export CPATH="\$INCLUDE_PATH"
export CPPPATH="\$INCLUDE_PATH"
export PKG_CONFIG_PATH="\$HOME/.apt/usr/lib/x86_64-linux-gnu/pkgconfig:\$HOME/.apt/usr/lib/i386-linux-gnu/pkgconfig:\$HOME/.apt/usr/lib/pkgconfig:\$PKG_CONFIG_PATH"
EOF

export PATH="$BUILD_DIR/.apt/usr/bin:$PATH"
export LD_LIBRARY_PATH="$BUILD_DIR/.apt/usr/lib/x86_64-linux-gnu:$BUILD_DIR/.apt/usr/lib/i386-linux-gnu:$BUILD_DIR/.apt/usr/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$BUILD_DIR/.apt/usr/lib/x86_64-linux-gnu:$BUILD_DIR/.apt/usr/lib/i386-linux-gnu:$BUILD_DIR/.apt/usr/lib:$LIBRARY_PATH"
export INCLUDE_PATH="$BUILD_DIR/.apt/usr/include:$INCLUDE_PATH"
export CPATH="$INCLUDE_PATH"
export CPPPATH="$INCLUDE_PATH"
export PKG_CONFIG_PATH="$BUILD_DIR/.apt/usr/lib/x86_64-linux-gnu/pkgconfig:$BUILD_DIR/.apt/usr/lib/i386-linux-gnu/pkgconfig:$BUILD_DIR/.apt/usr/lib/pkgconfig:$PKG_CONFIG_PATH"

# ----------------------------------------------------------------------------- #
# Copy pre-cached system level dependencies for Kitura                          #
# ----------------------------------------------------------------------------- #
status "Copying deb files to installation folder..."
deb_files=($BP_DIR/binary-dependencies/*.deb)
if [ -f "${deb_files[0]}" ]; then
  cp $BP_DIR/binary-dependencies/*.deb $APT_CACHE_DIR/archives
fi

# ----------------------------------------------------------------------------- #
# Download system level dependencies for Kitura                                 #
# ----------------------------------------------------------------------------- #
# We are using DEB files again (see code block above)
#status "Downloading system level dependencies..."
#packages=("libicu-dev" "libcurl4-openssl-dev")
#download_packages "${packages[@]}"

# ----------------------------------------------------------------------------- #
# Download any application specific system dependencies specified               #
# in Aptfile (if present) using apt-get                                         #
# ----------------------------------------------------------------------------- #
if [ -f $BUILD_DIR/Aptfile ]; then
  status "Aptfile found."
  for PACKAGE in $(cat $BUILD_DIR/Aptfile | sed $'s/\r$//'); do
    status "Entry found in Aptfile for $PACKAGE."
    packages=($PACKAGE)
    download_packages "${packages[@]}"
  done
else
  status "No Aptfile found."
fi

# ----------------------------------------------------------------------------- #
# Install Swift dev tools & clang                                               #
# ----------------------------------------------------------------------------- #
# Determine Swift version for the app
SWIFT_VERSION="$(get_swift_version)"
SWIFT_NAME_VERSION="swift-${SWIFT_VERSION}"
CLANG_NAME_VERSION="clang-${CLANG_VERSION}"

mkdir -p $CACHE_DIR
cd $CACHE_DIR

# Download and unpack Swift binaries
download_dependency $SWIFT_NAME_VERSION $SWIFT_VERSION "tar.gz" "swift-$DEFAULT_SWIFT_VERSION"
SWIFT_PATH=$CACHE_DIR/$(echo $SWIFT_NAME_VERSION/swift*)

# Download and unpack clang
download_dependency $CLANG_NAME_VERSION $CLANG_VERSION "tar.xz"
CLANG_PATH=$CACHE_DIR/$(echo $CLANG_NAME_VERSION/clang*)

# Update PATH environment variable
export PATH="$SWIFT_PATH/usr/bin:$CLANG_PATH/bin:$PATH"

# ----------------------------------------------------------------------------- #
# Verify .ssh directory & configure known_hosts for SSH                         #
# ----------------------------------------------------------------------------- #
if [ -f $BUILD_DIR/.ssh/config ]; then
  status ".ssh directory and config file found."
  mkdir -p ~/.ssh
  touch ~/.ssh/known_hosts
  cp $BUILD_DIR/.ssh/* ~/.ssh

  # Add hosts to known_hosts file
  grep HostName ~/.ssh/config | while read line
  do
    SSHKey=$(ssh-keyscan -t rsa ${line//HostName } 2> /dev/null)
    echo $SSHKey >> ~/.ssh/known_hosts
  done

else
  status ".ssh directory and config file not found."
fi

# ----------------------------------------------------------------------------- #
# Restore Packages folder based on current state                                #
# ----------------------------------------------------------------------------- #
restore_cache() {
  local cache_status="$(get_cache_status)"
  if [ "$cache_status" == "valid" ]; then
    status "Loading from cache:"
    restore_cache_directories "$BUILD_DIR" "$CACHE_DIR" "$SWIFT_BUILD_DIR"
  else
    status "Skipping cache restore ($cache_status)"
  fi
}
restore_cache

# ----------------------------------------------------------------------------- #
# Parse Package.swift to determine any required system level dependencies.      #
# ----------------------------------------------------------------------------- #
cd $BUILD_DIR
status "Fetching Swift packages and parsing Package.swift files..."
if [ $(is_swift_version_greater_or_equal_to 4.0) == "true" ]; then
  swift package resolve | indent
else  
  swift package fetch | indent
fi
PACKAGES_TO_INSTALL=($(set +o pipefail;find . -type f -name "Package.swift" | xargs egrep -r "Apt *\(" | sed -e 's/^.*\.Apt *( *" *//' -e 's/".*$//' | sort | uniq; set -o pipefail))
if [ "${#PACKAGES_TO_INSTALL[@]}" -gt "0" ]; then
  status "Additional packages to download: ${PACKAGES_TO_INSTALL[@]}"
  download_packages "${PACKAGES_TO_INSTALL[@]}"
else
  status "No additional packages to download."
fi

# ----------------------------------------------------------------------------- #
# Install app management - see lib/bluemix_ext.sh                               #
# ----------------------------------------------------------------------------- #
install_app_management

# ----------------------------------------------------------------------------- #
# Install any downloaded system level packages (DEB files)                      #
# ----------------------------------------------------------------------------- #
status "Installing system level dependencies..."
install_packages

# ----------------------------------------------------------------------------- #
# Build/compile Swift application                                               #
# ----------------------------------------------------------------------------- #
status "Building Package..."
if [ -f $BUILD_DIR/.swift-build-options-linux ]; then
  # Expand variables in loaded string
  SWIFT_BUILD_OPTIONS=$(eval echo $(cat $BUILD_DIR/.swift-build-options-linux | sed $'s/\r$//'))
  status "Using custom swift build options: $SWIFT_BUILD_OPTIONS"
else
  SWIFT_BUILD_OPTIONS=""
fi

if [[ $BLUEMIX_APP_MGMT_ENABLE == *"debug"* ]]; then
  BUILD_CONFIGURATION="debug"
else
  BUILD_CONFIGURATION="release"
fi
status "Build config: $BUILD_CONFIGURATION"

swift build --configuration $BUILD_CONFIGURATION $SWIFT_BUILD_OPTIONS -Xcc -I$BUILD_DIR/.apt/usr/include -Xlinker -L$BUILD_DIR/.apt/usr/lib -Xlinker -L$BUILD_DIR/.apt/usr/lib/x86_64-linux-gnu -Xlinker -rpath=$BUILD_DIR/.apt/usr/lib | indent

# ----------------------------------------------------------------------------- #
# Generate binary path.                                                         #
# ----------------------------------------------------------------------------- #
generate_bin_path() {
  if [ $(is_swift_version_greater_or_equal_to 4.0) == "true" ]; then
    local bin_path=$(swift build --configuration $BUILD_CONFIGURATION --show-bin-path)
  else
    local bin_path=$BUILD_DIR/.build/$BUILD_CONFIGURATION
  fi
  echo $bin_path
}
BIN_PATH=$(generate_bin_path)
status "Bin path: $BIN_PATH"

# These should be statically linked, seems a Swift bug.
status "Copying dynamic libraries"
cp $SWIFT_PATH/usr/lib/swift/linux/*.so $BUILD_DIR/.swift-lib
cp $BIN_PATH/*.so $BUILD_DIR/.swift-lib 2>/dev/null || true
# Copying additional dynamic libraries
cp $SWIFT_PATH/usr/lib/*.so $BUILD_DIR/.swift-lib
cp $SWIFT_PATH/usr/lib/*.so.* $BUILD_DIR/.swift-lib

status "Copying binaries to 'bin'"
find $BIN_PATH -type f -perm /a+x -exec cp {} $BUILD_DIR/.swift-bin \;

# ----------------------------------------------------------------------------- #
# Generate Package.resolved or Package.pins (if there is not one).              #
# Applicable to Swift 3.1 (and later versions).                                 #
# ----------------------------------------------------------------------------- #
generate_pins_or_resolved_file() {
  local swift_version="$(get_swift_version_from_cli)"
  if [ $(is_swift_version_greater_or_equal_to 4.0) == "true" ]; then
    if [ ! -f $BUILD_DIR/Package.resolved ]; then
      swift package update
      status "Generated Package.resolved (Swift $swift_version)"
    fi
  elif [ $(is_swift_version_greater_or_equal_to 3.1) == "true" ]; then
    if [ ! -f $BUILD_DIR/Package.pins ]; then
      swift package pin --all
      status "Generated Package.pins (Swift $swift_version)"
    fi
  elif [ ! -f $BUILD_DIR/Package.resolved ] || [ ! -f $BUILD_DIR/Package.pins ]; then
     status "Skipping generation of Package.pins and Package.resolved (Swift $swift_version)"
  fi
}
generate_pins_or_resolved_file

# ----------------------------------------------------------------------------- #
# Copy Packages folder from BUILD_DIR to CACHE_DIR                              #
# ----------------------------------------------------------------------------- #
cache_build() {
  status "Clearing previous swift cache"
  clear_cache
  # cf set-env swift-helloworld SWIFT_PACKAGES_CACHE true
  # cf restage swift-helloworld
  if ! ${SWIFT_BUILD_DIR_CACHE:-true}; then
    status "Skipping cache save (disabled by config)"
  else
    status "Saving cache (default):"
    save_cache_directories "$BUILD_DIR" "$CACHE_DIR" "$SWIFT_BUILD_DIR"
  fi
  save_signatures
}
# Cache packages before removing '.build' directory
cache_build

#status "Cleaning up build files"
#rm -rf $BUILD_DIR/.build

# Remove /.ssh folder
rm -rf ~/.ssh

# ----------------------------------------------------------------------------- #
# Removing binaries and tar files from the CACHE_DIR to speed up                #
# the 'Uploading droplet' step. Caching tar files and/or large                  #
# directories results in a negative performance hit.                            #
# ----------------------------------------------------------------------------- #
status "Optimizing contents of cache folder..."
# Remove unpacked tars (~1 GB of data)
rm -rf $CACHE_DIR/$SWIFT_NAME_VERSION
rm -rf $CACHE_DIR/$CLANG_NAME_VERSION
rm -rf $CACHE_DIR/"$SWIFT_NAME_VERSION.tar.gz"
rm -rf $CACHE_DIR/"$CLANG_NAME_VERSION.tar.xz"
deb_files=($BP_DIR/binary-dependencies/*.deb)
if [ -f "${deb_files[0]}" ]; then
  for DEB in ${deb_files[@]}; do
    rm $APT_CACHE_DIR/archives/$(basename $DEB)
  done
fi
# Remove items already cached in the buildpack package
#for i in "${CACHED_ITEMS[@]}"
#do
#  rm -rf $i
#done

# ----------------------------------------------------------------------------- #
# Set up application environment                                                #
# ----------------------------------------------------------------------------- #
PROFILE_PATH="$BUILD_DIR/.profile.d/swift.sh"
set-env PATH '$HOME/.swift-bin:$PATH'
set-env LD_LIBRARY_PATH '$HOME/.swift-lib:$LD_LIBRARY_PATH'

# ----------------------------------------------------------------------------- #
# Copy utils scripts to BUILD_DIR                                               #
# ----------------------------------------------------------------------------- #
cp $BP_DIR/utils/setup-ssh-sesssion.sh $BUILD_DIR
