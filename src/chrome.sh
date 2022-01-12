#!/bin/bash

# Default verbose to 0 if not set
VERBOSE=${2:-0}

# Get path of current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DIR="`cd "${DIR}/../tmp";pwd`"

# Import utils
source "$DIR/utils.sh"

# Supported channels
# @see https://www.chromium.org/getting-involved/dev-channel/
LINUX_CHANNELS=("stable" "beta" "dev")
MAC_CHANNELS=("stable" "beta" "dev" "canary")

# Download URLs
LINUX_DEB_STABLE_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
LINUX_DEB_BETA_URL="https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb"
LINUX_DEB_DEV_URL="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"

LINUX_RPM_STABLE_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
LINUX_RPM_BETA_URL="https://dl.google.com/linux/direct/google-chrome-beta_current_x86_64.rpm"
LINUX_RPM_DEV_URL="https://dl.google.com/linux/direct/google-chrome-unstable_current_x86_64.rpm"

MAC_STABLE_URL="https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
MAC_BETA_URL="https://dl.google.com/chrome/mac/universal/beta/googlechromebeta.dmg"
MAC_DEV_URL="https://dl.google.com/chrome/mac/universal/dev/googlechromedev.dmg"
MAC_CANARY_URL="https://dl.google.com/chrome/mac/universal/canary/googlechromecanary.dmg"

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
    if [ "$VERBOSE" -eq 1 ]; then
      echo "Using apt to install $TMP_DIR/$FILENAME"
    fi

    sudo apt --yes --quiet install "$TMP_DIR/$FILENAME"
  elif command -v yum >/dev/null; then
    if [ "$VERBOSE" -eq 1 ]; then
      echo "Using yum to install $TMP_DIR/$FILENAME"
    fi

    sudo yum --assumeyes --quiet install "$TMP_DIR/$FILENAME"
  else
    echo "Unable to install Chrome. System does not support apt or yum"
    exit 1
  fi

elif [ $OS == 'Mac' ]; then

  # Check that mac supports the desired channel
  if [[ ! " ${MAC_CHANNELS[*]} " =~ " ${CHANNEL} " ]]; then
    echo "Invalid Channel. MacOS does not support the \"$( titleCase $CHANNEL)\" channel"
    exit
  fi

  FILENAME="$FILENAME.dmg"
  if [ $CHANNEL == "stable" ]; then
    URL=$MAC_STABLE_URL
  elif [ $CHANNEL == "beta" ]; then
    URL=$MAC_BETA_URL
  elif [ $CHANNEL == "dev" ]; then
    URL=$MAC_DEV_URL
  else
    URL=$MAC_CANARY_URL
  fi

  download "$URL" "$TMP_DIR/$FILENAME" "$VERBOSE"

  # Install application
  # @see https://itectec.com/askdifferent/bash-script-that-automates-a-software-install/
  if [ "$VERBOSE" -eq 1 ]; then
    echo "Mounting $FILENAME"
  fi
  hdiutil attach -nobrowse -quiet "$TMP_DIR/$FILENAME"

  APPNAME="Google Chrome"
  if [ $CHANNEL != "stabe" ]; then
    APPNAME="$APPNAME $(titleCase $CHANNEL)"
  fi

  # copy app, remove old version first if installed
  if [[ -d "/Applications/$APPNAME.app" ]]; then
    if [ "$VERBOSE" -eq 1 ]; then
      echo "Removing existing /Applications/$APPNAME.app"
    fi

    sudo rm -rf "/Applications/$APPNAME.app"
  fi

  if [ "$VERBOSE" -eq 1 ]; then
    echo "Copying $APPNAME to /Applications/$APPNAME"
  fi
  sudo cp -r "/Volumes/$APPNAME/$APPNAME.app" "/Applications/$APPNAME.app"

  if [ "$VERBOSE" -eq 1 ]; then
    echo "Unmounting $APPNAME"
  fi
  hdiutil detach -quiet "/Volumes/$APPNAME"

  if [ "$VERBOSE" -eq 1 ]; then
    echo "Deleting $FILENAME"
  fi
  sudo rm -rf "$TMP_DIR/$FILENAME"

else
  echo "Unable to install Chrome. Operating System not supported"
  exit 1
fi