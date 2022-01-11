#!/bin/bash

# Default verbose to 0 if not set
VERBOSE=${2:-0}

# Get path of current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DIR="`cd "${DIR}/../tmp";pwd`"
CHROMEDRIVER_ZIP="$TMP_DIR/chromedriver.zip"
CHROMEDRIVER_FILE="$TMP_DIR/chromedriver"

# Import utils
source "$DIR/utils.sh"

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
TRIES=0
function getChromeDriverVersion() {
  LATEST_URL="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$VERSION"
  if command -v curl >/dev/null; then
    if [ "$VERBOSE" -eq 1 ]; then
      echo "Using curl to get response from $LATEST_URL"
    fi

    CHROMEDRIVER_VERSION=$(curl --location --retry 3 --silent --fail $LATEST_URL)
  elif command -v wget >/dev/null; then
    if [ "$VERBOSE" -eq 1 ]; then
      echo "Using wget to get response from $LATEST_URL"
    fi

    CHROMEDRIVER_VERSION=$(wget --tries=3 --quiet $LATEST_URL)
  fi

  # Verify we got a response back
  if [[ ! $CHROMEDRIVER_VERSION = $VERSION* ]]; then

    # If chromedriver doesn't exist for the current version, reduce by
    # one major version and try again
    # @see https://chromedriver.chromium.org/downloads/version-selection
    if [ $TRIES -eq 0 ]; then
      TRIED_VERSION=$VERSION
      TRIES=$((TRIES+1))
      VERSION=$((VERSION-1))

      echo "ChromeDriver $TRIED_VERSION not found. Retrying with ChromeDriver $VERSION"

      getChromeDriverVersion
      return 0
    else
      echo "Unable to get ChromeDriver version. Something went wrong"
      exit 1
    fi
  fi

  if [ "$VERBOSE" -eq 1 ]; then
    echo "Received response of $CHROMEDRIVER_VERSION"
  fi

  if command -v chromedriver >/dev/null && chromedriver --version | grep "$CHROMEDRIVER_VERSION" > /dev/null 2>&1; then
    echo "ChromeDriver $CHROMEDRIVER_VERSION already installed"
    exit 0
  fi
}

getChromeDriverVersion

#TODO: get platform for the url
CHROMEDRIVER_URL="https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_mac64.zip"
download "$CHROMEDRIVER_URL" "$CHROMEDRIVER_ZIP" "$VERBOSE"

if command -v unzip >/dev/null; then
  if [ "$VERBOSE" -eq 1 ]; then
    echo "Unzipping ChromeDriver to $TMP_DIR"
  fi
  unzip "$CHROMEDRIVER_ZIP" -d "$TMP_DIR" > /dev/null 2>&1
  chmod +x "$CHROMEDRIVER_FILE"
  mv "$CHROMEDRIVER_FILE" /usr/local/bin
  rm -f "$CHROMEDRIVER_FILE"
  rm -f "$CHROMEDRIVER_ZIP"
else
  echo "Unable to install ChromeDriver. System does not support unzip"
  exit 1
fi

# Verify success
if chromedriver --version | grep "$CHROMEDRIVER_VERSION" > /dev/null 2>&1; then
  echo "Successfully installed ChromeDriver $CHROMEDRIVER_VERSION"
else
  echo "Unable to install ChromeDriver. Something went wrong"

  if [ "$VERBOSE" -eq 1 ]; then
    echo "Tried to install ChromeDriver $CHROMEDRIVER_VERSION but installed version is $(chromedriver --version)"
  fi
  exit 1
fi