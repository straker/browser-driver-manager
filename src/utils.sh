#! /bin/bash

# How functions work in bash
# @see https://linuxize.com/post/bash-functions/

# Colors
# @see https://www.shellhacks.com/bash-colors/
# @see https://stackoverflow.com/a/10466960/2124254
colorReset="\033[0m"
colorRed="\033[00;31m"
colorBlue="\033[00;34m"

# Chrome supported channels
# @see https://www.chromium.org/getting-involved/dev-channel/
chromeLinuxChannels=("stable" "beta" "dev")
chromeMacChannels=("stable" "beta" "dev" "canary")

# Output text in the specified color
# $1 = color
# $2 = text
function color() {
  echo -e -n "${1}${2}${colorReset}"
}

function red() {
  color "$colorRed" "$1"
}

function blue() {
  color "$colorBlue" "$1"
}

# Lowercase a string
function lowercase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Uppercase first character of a string
# @see https://stackoverflow.com/a/12487469/2124254
function titleCase() {
  echo "$(tr '[:lower:]' '[:upper:]' <<< ${1:0:1})${1:1}"
}

# Output an error message to stderr
function error() {
  >&2 echo $(red "browser-driver-manager error:") $1
}

# Output a message for verbose logging
# Use file descriptor 3 to output the logs so we can display the log
# while still allowing the normal stdout to be captured in parent script
# @see https://stackoverflow.com/questions/64530573/in-bash-how-to-capture-some-output-in-variable-letting-rest-got-to-standard-ou
function verboseLog() {
  if [ $BDM_VERBOSE -eq 1 ]; then
    >&3 echo $(blue "log:") $1
  fi
}

# Validate that the desired channel is supported
function validateChromeChannel() {
  if [ $BDM_OS == "Linux" ] && [[ ! " ${chromeLinuxChannels[*]} " =~ " ${1} " ]]; then
    error "$BDM_OS Chrome supported channels: ${chromeLinuxChannels[*]}"
    exit 1
  elif [ $BDM_OS == "MacOs" ] && [[ ! " ${chromeMacChannels[*]} " =~ " ${1} " ]]; then
    error "$BDM_OS Chrome supported channels: ${chromeMacChannels[*]}"
    exit 1
  fi
}

# Download a file from a specific URL to a file
# $1 = URL to resource
# $2 = filepath to save resource to
function download() {
  if command -v curl >/dev/null; then
    options="--location --retry 3 --fail"
    verboseLog "Using curl to download $1 to $2"

    if [ "$BDM_VERBOSE" -eq 1 ]; then
      options="$options --show-error --progress-bar"
    else
      options="$options --silent"
    fi

    curl $options --output "$2" "$1"
  elif command -v wget >/dev/null; then
    options="--tries=3 --quiet"
    verboseLog "Using wget to download $1 to $2"

    wget $options --output-document="$2" "$1"
  else
    error "Unable to download file; System does not support curl or wget"
    exit 1
  fi

  if [ ! -f "$2" ]; then
    error "Unable to download file; Something went wrong"
    exit 1
  fi
}