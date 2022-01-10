#!/bin/bash

# Default verbose to 0 if not set
VERBOSE=${2:-0}

# Get path of current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DIR="`cd "${DIR}/../tmp";pwd`"

# Import utils
. "$DIR/utils.sh"

# Supported channels
# @see https://www.chromium.org/getting-involved/dev-channel/
LINUX_CHANNELS=("stable" "beta" "dev")

# Download URLs
LINUX_DEB_STABLE_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
LINUX_DEB_BETA_URL="https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb"
LINUX_DEB_DEV_URL="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"

LINUX_RPM_STABLE_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
LINUX_RPM_BETA_URL="https://dl.google.com/linux/direct/google-chrome-beta_current_x86_64.rpm"
LINUX_RPM_DEV_URL="https://dl.google.com/linux/direct/google-chrome-unstable_current_x86_64.rpm"

CHANNEL='stable'
if [[ $1 ]]; then
  CHANNEL=$1
fi
FILENAME="chrome-$CHANNEL"

echo "Installing Chrome $(titleCase $CHANNEL)"

OS=$(getOS)
if [[ $VERBOSE ]]; then
  echo "System detected as $OS"
fi

# Linux platform
if [ $OS == 'Linux' ]; then

  # Check that linux supports the desired channel
  if [[ ! " ${LINUX_CHANNELS[*]} " =~ " ${CHANNEL} " ]]; then
    echo "Invalid Channel. Linux does not support the \"$( titleCase $CHANNEL)\" channel"
    exit
  fi

  # Determine which package installer to use
  # @see https://unix.stackexchange.com/questions/665940/how-do-i-check-if-my-linux-is-deb-or-rpm
  if command -v dpkg >/dev/null; then
    FILENAME="$FILENAME.deb"

    if [ $CHANNEL == "stable" ]; then
      URL=$LINUX_DEB_STABLE_URL
    elif [ $CHANNEL == "beta" ]; then
      URL=$LINUX_DEB_BETA_URL
    else
      URL=$LINUX_DEB_DEV_URL
    fi

  elif command -v rpm >/dev/null; then
    FILENAME="$FILENAME.rpm"

    if [ $CHANNEL == "stable" ]; then
      URL=$LINUX_RPM_STABLE_URL
    elif [ $CHANNEL == "beta" ]; then
      URL=$LINUX_RPM_BETA_URL
    else
      URL=$LINUX_RPM_DEV_URL
    fi

  else
    echo "Unable to download Chrome. System does not support .dep or .rpm"
    exit 1
  fi

  download "$URL" "$TMP_DIR/$FILENAME" "$VERBOSE"

  # Install Chrome using system installer
  # @see https://unix.stackexchange.com/questions/519773/find-package-os-distribution-manager-for-automation
  if command -v apt >/dev/null; then
    apt install "$TMP_DIR/$FILENAME"
  elif command -v yum >/dev/null; then
    yum install "$TMP_DIR/$FILENAME"
  else
    echo "Unable to install Chrome. System does not support apt or yum"
    exit 1
  fi

else
  echo "Unable to install Chrome. Operating System not supported"
  exit 1
fi