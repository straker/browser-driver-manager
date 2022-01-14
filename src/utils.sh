#!/bin/bash

# How functions work in bash
# @see https://linuxize.com/post/bash-functions/

# Colors
# @see https://www.shellhacks.com/bash-colors/
# @see https://stackoverflow.com/a/10466960/2124254
colorReset="\033[0m"
colorRed="\033[00;31m"

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

# Lowercase a string
function lowercase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Uppercase first character of a string
# @see https://stackoverflow.com/a/12487469/2124254
function titleCase() {
  echo "$(tr '[:lower:]' '[:upper:]' <<< ${1:0:1})${1:1}"
}

# Show an error message
function error() {
  echo $(red "browser-driver-manager error:") $1
}

# Validate that the desired channel is supported
# $1 = system
# $2 = channel
function validateChromeChannel() {
  if [ $1 == "Linux" ] && [[ ! " ${chromeLinuxChannels[*]} " =~ " ${channel} " ]]; then
    error "$1 Chrome supported channels: ${chromeLinuxChannels[*]}"
  elif [ $1 == "MacOs" ] && [[ ! " ${chromeMacChannels[*]} " =~ " ${channel} " ]]; then
    error "$1 Chrome supported channels: ${chromeMacChannels[*]}"
  fi
}

# Download a file from a specific URL to a file
# $1 = URL to resource
# $2 = filepath to save resource to
# $3 = if verbose logging is enabled
function download() {
  if command -v curl >/dev/null; then
    options="--location --retry 3 --fail"
    if [ "$3" -eq 1 ]; then
      echo "Using curl to download $1 to $2"
      options="$options --show-error --progress-bar"
    else
      options="$options --silent"
    fi

    curl $options --output "$2" "$1"
  elif command -v wget >/dev/null; then
    options="--tries=3 --quiet"
    if [ "$3" -eq 1 ]; then
      echo "Using wget to download $1 to $2"
    fi

    wget $options --output-document="$2" "$1"
  else
    error "Unable to download file; System does not support curl or wget"
  fi

  if [ ! -f "$2" ]; then
    error "Unable to download file; Something went wrong"
  fi
}

function getLastLine() {
  echo "${1##*$'\n'}"
}