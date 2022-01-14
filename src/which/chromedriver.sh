#!/bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateChromeChannel $BDM_OS $channel

driver="chromedriver"
if command -v chromedriver >/dev/null; then
  which chromedriver
else
  error "chromedriver is not installed"
fi