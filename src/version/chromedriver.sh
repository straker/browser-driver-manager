#!/bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateChromeChannel $BDM_OS $channel

output=$($BDM_SRC_DIR/which/chromedriver.sh "$channel")
path=$(getLastLine "$output")

# Output everything but the last line from the output to display verbose
# log info
IFS=$'\n' read -rd '' -a lines <<<"$output"
for line in "${lines[@]}"; do
  if [ "$line" != "$path" ]; then
    echo "$line"
  fi
done

"$path" --version