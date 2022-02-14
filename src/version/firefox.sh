#! /bin/bash

# Import utils
source "$BDM_SRC_DIR/utils.sh"

channel="stable"
if [[ $1 ]]; then
  channel=$(lowercase $1)
fi

validateFirefoxChannel $channel

path=$($BDM_SRC_DIR/which/firefox.sh "$channel")
exitCode=$?
if [ "$exitCode" -ne 0 ]; then
  exit "$exitCode"
fi

# Firefox does not allow running as sudo while in user session, so switch back
# to user when running the version command
# @see https://stackoverflow.com/questions/15982273/bash-script-change-to-root-then-exit-root
# @see https://stackoverflow.com/questions/3522341/identify-user-in-a-bash-script-called-by-sudo
sudo -u $(logname) "$path" --version