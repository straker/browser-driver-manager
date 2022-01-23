#! /bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateChromeChannel $channel

path=$($BDM_SRC_DIR/which/chrome.sh "$channel")
exitCode=$?
if [ "$exitCode" -ne 0 ]; then
  exit "$exitCode"
fi

"$path" --version