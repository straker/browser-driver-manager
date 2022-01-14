#!/bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateChromeChannel $BDM_OS $channel

appname="Google Chrome"
if [ $channel != "stable" ]; then
  appname="$appname $(titleCase $channel)"
fi

if [ $BDM_VERBOSE -eq 1 ]; then
  echo "Looking for path for $appname"
fi

if [ $BDM_OS == "Linux" ]; then
  googleChrome="google-chrome"
  if [ $channel != "stable" ]; then
    googleChrome="$googleChrome-$channel"
  fi

  if command -v $googleChrome >/dev/null; then
    echo $(which $googleChrome)
  else
    error "$appname not installed"
    exit 1
  fi

elif [ $BDM_OS == "MacOs" ]; then
  path="/Applications/$appname.app/Contents/MacOS/$appname"

  if [ $BDM_VERBOSE -eq 1 ]; then
    echo "Checking path $path"
  fi

  if [ -f "$path" ]; then
    echo "$path"
  else
    error "$appname not installed"
    exit 1
  fi

fi