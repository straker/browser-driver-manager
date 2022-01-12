#!/bin/bash

# How functions work in bash
# @see https://linuxize.com/post/bash-functions/

# Lowercase a string
function lowercase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Uppercase first character of a string
# @see https://stackoverflow.com/a/12487469/2124254
function titleCase() {
  echo "$(tr '[:lower:]' '[:upper:]' <<< ${1:0:1})${1:1}"
}

# Detect operating system
# @see https://stackoverflow.com/a/27776822/2124254
# @see https://stackoverflow.com/a/18434831/2124254
function getOS() {
  # $OSTYPE doesn't seem to work on Ubuntu Server
  OS="`uname`"
  case $OS in
    'Linux') OS='Linux';;
    'Darwin') OS='Mac';;
    *) ;;
  esac
  echo "$OS"
}

# Download a file from a specific URL to a file
# $1 = URL to resource
# $2 = filepath to save resource to
# $3 = if verbose logging is enabled
function download() {
  if command -v curl >/dev/null; then
    OPTIONS="--location --retry 3 --fail"
    if [ "$3" -eq 1 ]; then
      echo "Using curl to download $1 to $2"
      OPTIONS="$OPTIONS --show-error --progress-bar"
    else
      OPTIONS="$OPTIONS --silent"
    fi

    curl $OPTIONS --output "$2" "$1"
  elif command -v wget >/dev/null; then
    OPTIONS="--tries=3 --quiet"
    if [ "$3" -eq 1 ]; then
      echo "Using wget to download $1 to $2"
    fi

    wget $OPTIONS --output-document="$2" "$1"
  else
    echo "Unable to download file. System does not support curl or wget"
    exit 1
  fi

  if [ ! -f "$2" ]; then
    echo "Unable to download file. Something went wrong"
    exit 1;
  fi
}