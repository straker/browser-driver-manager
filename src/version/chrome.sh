#!/bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateChromeChannel $BDM_OS $channel

path=$($BDM_SRC_DIR/which/chrome.sh "$channel")
"$path" --version