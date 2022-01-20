#!/bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateChromeChannel $channel

driver="chromedriver"
if command -v "$driver" >/dev/null; then
  which "$driver"
else
  error "chromedriver is not installed"
  exit 1
fi