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
  if command -v google-chrome >/dev/null; then
    echo $(which google-chrome)
  else
    echo $(red "ERROR:") "$appname not installed"
    exit 1
  fi

elif [ $BDM_OS == "MacOs" ]; then
  path="/Applications/$appname.app/Contents/MacOS/$appname"

  if [ -f "$path" ]; then
    echo "$path"
  else
    error "$appname not installed"
    exit 1
  fi

fi