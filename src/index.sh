#!/bin/bash

# Get path of current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Import utils
. "$DIR/utils.sh"

# Display usage information
function usage() {
  echo "usage: $0 -i [browsers]"
  echo ""
  echo "options:"
  echo "  -i, --install [browsers]   Install the list of browsers"
  echo "  -h, --help                 Print this list and exit"
  echo "  -v, --version              Print the version and exit"
  echo "  --verbose                  Output verbose debugging logs"
}

# Display version from package.json file
# @see https://gist.github.com/DarrenN/8c6a5b969481725a4413
function version() {
  PACKAGE_VERSION=$(cat package.json \
    | grep version \
    | head -1 \
    | awk -F: '{ print $2 }' \
    | sed 's/[",]//g' \
    | tr -d '[[:space:]]')
  echo $PACKAGE_VERSION
}

# Display usage if no arguments were passed
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

# Parse arguments
# @see https://stackoverflow.com/a/33826763/2124254
while [[ "$#" > 0 ]]; do case $1 in
  -i|--install) INSTALL=$(lowercase $2); shift;shift;;
  -h|--help) usage; exit 0;;
  -v|--version) version; exit 0;;
  --verbose) VERBOSE=1; shift;;
  *) usage; exit 1;;
esac; done

# Run install scripts
if [[ $INSTALL ]]; then

  # Split comma-delimited list
  # @see https://linuxhandbook.com/bash-split-string/
  IFS=',' read -ra BROWSERS <<< "$INSTALL"
  for i in "${BROWSERS[@]}"
  do
    IFS='=' read -ra PARTS <<< "$i"

    # Run install scripts
    if [ "${PARTS[0]}" == "chrome" ]; then
      "$DIR/chrome.sh" "${PARTS[1]}"
    fi

  done

fi