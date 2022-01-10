#!/bin/bash

# Default verbose to 0 if not set
VERBOSE=${2:-0}

# Get path of current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DIR="`cd "${DIR}/../tmp";pwd`"

# Import utils
. "$DIR/utils.sh"

# @see https://chromedriver.chromium.org/downloads/version-selection
LATEST_URL="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"
CHROMEDRIVER_URL="https://chromedriver.storage.googleapis.com/index.html?path="

VERSION='auto'
if [[ $1 ]]; then
  VERSION=$1
fi

echo "Installing ChromeDriver $VERSION"

OS=$(getOS)
if [ "$VERBOSE" -eq 1 ]; then
  echo "System detected as $OS"
fi

# Find which version of Chrome is installed and use the matching
# ChromeDriver version
# if [ $VERSION == 'auto' ]; then

#   if [ $OS == 'Linux' ]; then

#   fi

# fi

# Determine how to download ChromeDriver
LATEST_URL="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$VERSION"
if command -v curl >/dev/null; then
  if [ "$VERBOSE" -eq 1 ]; then
      echo "Using curl to download \"$LATEST_URL\""
  fi

  CHROMEDRIVER_VERSION=$(curl --location --retry 3 --silent --fail $LATEST_URL)
elif command -v wget >/dev/null; then
  if [ "$VERBOSE" -eq 1 ]; then
      echo "Using wget to download \"$LATEST_URL\""
  fi

  CHROMEDRIVER_VERSION=$(wget --tries=3 --quiet $LATEST_URL)
fi

# Verify we got a response back
if [[ ! $CHROMEDRIVER_VERSION = $VERSION* ]]; then
  echo "Unable to get ChromeDriver. Something went wrong"
  exit 1;
fi

if [ "$VERBOSE" -eq 1 ]; then
  echo "Downloading ChromeDriver $CHROMEDRIVER_VERSION"
fi

#TODO: get platform for the url
CHROMEDRIVER_URL="https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_mac64.zip"
download "$CHROMEDRIVER_URL" "$TMP_DIR/chromedriver.zip" "$VERBOSE"

if command -v unzip >/dev/null; then
  unzip "$TMP_DIR/chromedriver.zip" -d "$TMP_DIR" > /dev/null 2>&1
  chmod +x "$TMP_DIR/chromedriver"
  mv "$TMP_DIR/chromedriver" /usr/local/bin
  rm -f "$TMP_DIR/chromedriver"
  rm -f "$TMP_DIR/chromedriver.zip"
else
  echo "Unable to install ChromeDriver. System does not support unzip"
  exit 1
fi

# Verify success
if chromedriver --version | grep "$CHROMEDRIVER_VERSION" > /dev/null 2>&1; then
  echo "Successfully installed ChromeDriver"
else
  echo "Unable to install ChromeDriver. Something went wrong"

  if [ "$VERBOSE" -eq 1 ]; then
    echo "Tried to install ChromeDriver $CHROMEDRIVER_VERSION but installed version is $(chromedriver --version)"
  fi
  exit 1
fi