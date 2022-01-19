#!/bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

# Download URLs
urlLinuxDebStable="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
urlLinuxDebBeta="https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb"
urlLinuxDebDev="https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"

urlLinuxRpmStable="https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
urlLinuxRpmBeta="https://dl.google.com/linux/direct/google-chrome-beta_current_x86_64.rpm"
urlLinuxRpmDev="https://dl.google.com/linux/direct/google-chrome-unstable_current_x86_64.rpm"

urlMacOsStable="https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
urlMacOsBeta="https://dl.google.com/chrome/mac/universal/beta/googlechromebeta.dmg"
urlMacOsDev="https://dl.google.com/chrome/mac/universal/dev/googlechromedev.dmg"
urlMacOsCanary="https://dl.google.com/chrome/mac/universal/canary/googlechromecanary.dmg"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateChromeChannel $channel

filename="google-chrome"
if [ $channel != "stable" ]; then
  filename="$filename-$channel"
fi

echo "Installing Google Chrome $(titleCase $channel) (this may take awhile)"

if [ $BDM_OS == "Linux" ]; then

  # Determine which package installer to use
  # @see https://unix.stackexchange.com/questions/665940/how-do-i-check-if-my-linux-is-deb-or-rpm
  if command -v dpkg >/dev/null; then
    filename="$filename.deb"

    if [ $channel == "stable" ]; then
      url=$urlLinuxDebStable
    elif [ $channel == "beta" ]; then
      url=$urlLinuxDebBeta
    else
      url=$urlLinuxDebDev
    fi

  elif command -v rpm >/dev/null; then
    filename="$filename.rpm"

    if [ $channel == "stable" ]; then
      url=$urlLinuxRpmStable
    elif [ $channel == "beta" ]; then
      url=$urlLinuxRpmBeta
    else
      url=$urlLinuxRpmDev
    fi

  else
    error "Unable to download Google Chrome; System does not support .dep or .rpm"
    exit 1
  fi

  download "$url" "$BDM_TMP_DIR/$filename"

  # Install Chrome using system installer
  # @see https://unix.stackexchange.com/questions/519773/find-package-os-distribution-manager-for-automation
  if command -v apt >/dev/null; then
    verboseLog "Using apt to install $BDM_TMP_DIR/$filename"

    sudo apt --yes --quiet install "$BDM_TMP_DIR/$filename"
  elif command -v yum >/dev/null; then
    verboseLog "Using yum to install $BDM_TMP_DIR/$filename"

    sudo yum --assumeyes --quiet install "$BDM_TMP_DIR/$filename"
  else
    error "Unable to install Google Chrome; System does not support apt or yum"
    exit 1
  fi

elif [ $BDM_OS == "MacOs" ]; then
  filename="$filename.dmg"
  if [ $channel == "stable" ]; then
    url=$urlMacOsStable
  elif [ $channel == "beta" ]; then
    url=$urlMacOsBeta
  elif [ $channel == "dev" ]; then
    url=$urlMacOsDev
  else
    url=$urlMacOsCanary
  fi

  download "$url" "$BDM_TMP_DIR/$filename"

  # Install application
  # @see https://itectec.com/askdifferent/bash-script-that-automates-a-software-install/
  verboseLog "Mounting $filename"
  hdiutil attach -nobrowse -quiet -noverify "$BDM_TMP_DIR/$filename"

  appname="Google Chrome"
  if [ $channel != "stable" ]; then
    appname="$appname $(titleCase $channel)"
  fi

  # copy app, remove old version first if installed
  if [[ -d "/Applications/$appname.app" ]]; then
    verboseLog "Removing existing /Applications/$appname.app"

    sudo rm -rf "/Applications/$appname.app"
  fi

  verboseLog "Copying $appname to /Applications/$appname"
  sudo cp -r "/Volumes/$appname/$appname.app" "/Applications/$appname.app"

  verboseLog "Unmounting $appname"
  hdiutil detach -quiet "/Volumes/$appname"

  verboseLog "Deleting $filename"
  sudo rm -rf "$BDM_TMP_DIR/$filename"

fi

echo "Successfully installed $($BDM_SRC_DIR/version/chrome.sh $channel)"