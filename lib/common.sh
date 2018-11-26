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

# Global/common vars
DEFAULT_SWIFT_VERSION=4.2.1
CLANG_VERSION=4.0.0

error() {
  echo " !     $*" >&2
  exit 1
}

status() {
  echo "-----> $*"
}

join_by_whitespace() {
  echo "$*"
}

protip() {
  tip=$1
  help_url=$2
  echo ""
  echo "PRO TIP: $tip" | indent
  if [[ "${2}X" != "X" ]]; then
    echo "Visit $2" | indent
  fi
  echo ""
  echo ""
}

# sed -l basically makes sed replace and buffer through stdin to stdout
# so you get updates while the command runs and dont wait for the end
# e.g. npm install | indent
indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
    *)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
  esac
}

export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  if [ -d "$env_dir" ]; then
    for e in $(ls $env_dir); do
      echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
      export "$e='$(cat $env_dir/$e)'"
      :
    done
  fi
}

set-env() {
  echo "export $1=$2" >> $PROFILE_PATH
}

download_dependency() {
  # Current folder must be CACHE_DIR
  dependency_name=$1
  dependency_version=$2
  dependency_version_extension=$3
  default_dependency_version=$4
  dependency_filename=$dependency_name.$dependency_version_extension

  # Download dependency
  if [[ ! -e "$CACHE_DIR/$dependency_filename" ]]; then
    status "Getting $dependency_name"
    # Place dependency tar file in CACHE_DIR
    in_cache=$($BP_DIR/compile-extensions/bin/download_dependency $dependency_filename $CACHE_DIR $default_dependency_version)
    if [[ $in_cache = "true" ]]; then
      echo "Cached $dependency_name" | indent
      #CACHED_ITEMS+=($dependency_filename)
    else
      echo "Downloaded $dependency_name" | indent
    fi
  fi

  # Unpack dependency - determine unpack options
  status "Unpacking $dependency_filename"
  mkdir -p $dependency_name
  if [[ "$dependency_version_extension" == *gz ]]; then
    # Assuming tar.gz file
    tar xz -C $dependency_name -f $CACHE_DIR/$dependency_filename
  else
    # Assuming tar.xz file
    echo $CACHE_DIR/$dependency_filename | xz -d -c --files | tar x -C $CLANG_NAME_VERSION &> /dev/null
  fi
}

download_packages() {
  # Using unset to remove elements from an array did not always yield
  # the expected outcome... for instance, removing "python2.7-doc"
  # resulted in the following error: invalid arithmetic operator (error token is ".7-doc")
  local packages=("$@")
  local pkgs=()
  for package in "${packages[@]}"; do
    # Check if package is installed as part of the root fs
    if dpkg -l "$package" >/dev/null 2>&1; then
      status "$package is already installed."
      continue
    else
      # Check if CACHE_DIR already contains DEB file for package
      if [ -f "$APT_CACHE_DIR/archives/$package*.deb" ]; then
        status "$package was already downloaded."
        continue
      fi
      pkgs+=($package)
    fi
  done

  # Update packages array contents
  packages=("${pkgs[@]}")
  if [ ${#packages[@]} -eq 0 ]; then
    status "No additional packages to download."
  else
    # Download one package at a time to highlight any failures
    for package in "${packages[@]}"; do
      status "Fetching .deb for $package"
      if [ "$APT_PCKGS_LIST_UPDATED" = false ] ; then
        apt-get $APT_OPTIONS update | indent
        APT_PCKGS_LIST_UPDATED=true
      fi
      # Continue execution even if we fail to download a system package
      # Separate the declaration of downloadOutput from its initialization
      # (needed in order to get the actual return code value)
      local downloadOutput
      set +e
      downloadOutput=$(apt-get $APT_OPTIONS -y --force-yes -d install --reinstall $package 2>&1)
      local returnCode=$(echo $?)
      set -e
      echo "$downloadOutput" | indent
      if [ $returnCode -ne 0 ]; then
        status "WARNING: Failed to download DEB file for $package. Application may fail to start (see above for details)."
      else
        status "Downloaded DEB file for $package"
      fi
    done
    # Turn string array into a space delimited string
    #packages="$(join_by_whitespace ${packages[@]})"
    #status "Fetching .debs for: $packages"
    #if [ "$APT_PCKGS_LIST_UPDATED" = false ] ; then
    #  apt-get $APT_OPTIONS update | indent
    #  APT_PCKGS_LIST_UPDATED=true
    #fi
    #apt-get $APT_OPTIONS -y --force-yes -d install --reinstall $packages | indent
    #status "Downloaded DEB files..."
  fi
}

install_packages() {
  deb_files=($APT_CACHE_DIR/archives/*.deb)
  if [ -f "${deb_files[0]}" ]; then
    for DEB in ${deb_files[@]}; do
      status "Installing $(basename $DEB)"
      dpkg -x $DEB $BUILD_DIR/.apt/
    done
  fi
}

get_swift_version() {
# Determine Swift version for the app
  if [ -f $BUILD_DIR/.swift-version ]; then
    # Take any pinned Swift version, stripping any redundant `swift-` prefix and/or `RELEASE` suffix if present
    local swift_version=$(cat $BUILD_DIR/.swift-version | sed $'s/\r$//' | sed -e "s/swift-//" | sed -e "s/-RELEASE//")
  else
    local swift_version=$DEFAULT_SWIFT_VERSION
  fi
  echo $swift_version
}

get_swift_version_from_cli() {
  local swift_version=$(swift -version | cut -d " " -f 3 | cut -d '-' -f1)
  echo $swift_version
}

is_swift_version_greater_or_equal_to() {
  target_version=$1
  local swift_version="$(get_swift_version_from_cli)"
  echo $swift_version $target_version | awk '{ print ($1 >= $2) ? "true" : "false" }'
}
