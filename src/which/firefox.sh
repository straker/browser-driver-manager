#! /bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateFirefoxChannel $channel

appname="Firefox"
if [ $channel != "stable" ]; then
  if [ $channel == "dev" ]; then
    appname="$appname Developer Edition"
  else
    appname="$appname $(titleCase $channel)"
  fi
fi

verboseLog "Looking for path for $appname"

if [ $BDM_OS == "Linux" ]; then
  googleChrome="google-chrome"
  if [ $channel != "stable" ]; then
    googleChrome="$googleChrome-$channel"
  fi

  if command -v $googleChrome >/dev/null; then
    echo $(which $googleChrome)
  else
    error "$appname is not installed"
    exit 1
  fi

elif [ $BDM_OS == "MacOs" ]; then
  path="/Applications/$appname.app/Contents/MacOS/firefox"

  verboseLog "Checking path $path"

  if [ -f "$path" ]; then
    echo "$path"
    exit 0
  else
    error "$appname is not installed"
    exit 1
  fi

fi