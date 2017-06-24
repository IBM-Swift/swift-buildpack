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

create_swift_signature() {
  echo "$(swift --version)"
}

create_package_signature() {
  echo "$(cat $BUILD_DIR/Package.swift)"
}

create_pins_signature() {
  # Older versions of Swift do not use a Package.pins file
  if test -f $BUILD_DIR/Package.pins; then
    echo "$(cat $BUILD_DIR/Package.pins)"
  else
    echo ""
  fi
}

save_signatures() {
  echo "$(create_swift_signature)" > $CACHE_DIR/swift/.swift-signature
  echo "$(create_package_signature)" > $CACHE_DIR/swift/.package-signature
  echo "$(create_pins_signature)" > $CACHE_DIR/swift/.pins-signature
}

load_swift_signature() {
  load_signature ".swift-signature"
}

load_packages_signature() {
  load_signature ".package-signature"
}

load_pins_signature() {
  load_signature ".pins-signature"
}

load_signature() {
  local filename=$1
  if test -f $CACHE_DIR/swift/$filename; then
    cat $CACHE_DIR/swift/$filename
  else
    echo ""
  fi
}

get_cache_status() {
  if ! ${SWIFT_BUILD_DIR_CACHE:-true}; then
    echo "disabled by config"
  elif [ "$(create_swift_signature)" != "$(load_swift_signature)" ]; then
    echo "new swift signature"
  elif [ "$(create_package_signature)" != "$(load_packages_signature)" ]; then
    echo "new package signature"
  elif [[ ! -z "$(create_pins_signature)" ]] && [ "$(create_pins_signature)" != "$(load_pins_signature)" ]; then
    ##
    echo TEST1
    echo "$(create_pins_signature)"
    echo TEST1
    echo TEST2
    echo "$(load_pins_signature)"
    echo TEST2
    ##
    echo "new pins signature"
  else
    echo "valid"
  fi
}

restore_cache_directories() {
  local build_dir=${1:-}
  local cache_dir=${2:-}

  for cachepath in ${@:3}; do
    if [ -e "$build_dir/$cachepath" ]; then
      echo "-----> - $cachepath (exists - skipping)"
    else
      if [ -e "$cache_dir/swift/$cachepath" ]; then
        echo "-----> - $cachepath"
        mkdir -p $(dirname "$build_dir/$cachepath")
        mv "$cache_dir/swift/$cachepath" "$build_dir/$cachepath"
      else
        echo "-----> - $cachepath (not cached - skipping)"
      fi
    fi
  done
}

clear_cache() {
  rm -rf $CACHE_DIR/swift
  mkdir -p $CACHE_DIR/swift
}

save_cache_directories() {
  local build_dir=${1:-}
  local cache_dir=${2:-}

  for cachepath in ${@:3}; do
    if [ -e "$build_dir/$cachepath" ]; then
      echo "-----> - $cachepath"
      mkdir -p "$cache_dir/swift/$cachepath"
      cp -a "$build_dir/$cachepath" $(dirname "$cache_dir/swift/$cachepath")
    else
      echo "-----> - $cachepath (nothing to cache)"
    fi
  done
}
