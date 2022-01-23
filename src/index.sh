#! /bin/bash

# Display verbose log file descriptor
exec 3>&1

# Get path of current script
# @see https://medium.com/@Aenon/bash-location-of-current-script-76db7fd2e388
export BDM_SRC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BDM_ROOT_DIR="$(cd "${BDM_SRC_DIR}/.." && pwd)"
export BDM_TMP_DIR="$BDM_ROOT_DIR/tmp"

export BDM_VERBOSE=0

# Import utils
source "$BDM_SRC_DIR/utils.sh"

# Remove files in tmp directory on process kill
function cleanup {
  cd $BDM_TMP_DIR

  # @see https://stackoverflow.com/questions/8525437/list-files-not-matching-a-pattern
  sudo ls | grep -v "README.md" | xargs rm
  exit $?
}

trap cleanup SIGINT
trap cleanup SIGTERM

# Detect operating system
# @see https://stackoverflow.com/a/27776822/2124254
# @see https://stackoverflow.com/a/18434831/2124254
# $OSTYPE doesn't seem to work on Ubuntu Server
os=$(uname)
case $os in
  'Linux')
    export BDM_OS='Linux' ;;
  'Darwin')
    export BDM_OS='MacOs' ;;
  *)
    error "$os system not supported"
    exit 1 ;;
esac

# Display help information
function help() {
  echo "usage: $0 -i [browsers]"
  echo ""
  echo "options:"
  echo "  -i, --install [browsers]   Install the list of browsers"
  echo "  -h, --help                 Display this help and exit"
  echo "  -v, --version              Output version information and exit"
  echo "  --verbose                  Output verbose debugging logs"
}

# Display version from package.json file
# @see https://gist.github.com/DarrenN/8c6a5b969481725a4413
function version() {
  echo $(cat "$BDM_ROOT_DIR/package.json" \
    | grep version \
    | head -1 \
    | awk -F: '{ print $2 }' \
    | sed 's/[",]//g' \
    | tr -d '[[:space:]]')
}

# Display help if no arguments were passed
if [ $# -eq 0 ]; then
  help
  exit 1
fi

install=()
# Parse arguments
# @see https://stackoverflow.com/a/33826763/2124254
while [[ "$#" > 0 ]]; do
  case $1 in
    install)
      command="install";
      shift ;;
    which)
      command="which"
      which=$(lowercase $2)
      shift 2 ;;
    version)
      command="version"
      version=$(lowercase $2)
      shift 2 ;;
    -h|--help)
      help
      exit 0 ;;
    -v|--version)
      version
      exit 0 ;;
    --verbose)
      export BDM_VERBOSE=1
      shift ;;
    *)
      if [ "$command" == "install" ]; then
        install+=($1)
      else
        help
        exit 1
      fi

      shift ;;
  esac
done

verboseLog "System detected as $BDM_OS"

# Run install scripts
if [ "$command" == "install" ]; then
  for package in "${install[@]}"; do
    # Split string
    # @see https://linuxhandbook.com/bash-split-string/
    IFS='=' read -ra parts <<< "$package"

    # Run install scripts
    if [ "${parts[0]}" == "chrome" ]; then
      "$BDM_SRC_DIR/install/chrome.sh" "${parts[1]}"
    elif [ "${parts[0]}" == "chromedriver" ]; then
      "$BDM_SRC_DIR/install/chromedriver.sh" "${parts[1]}"
    else
      error "${parts[0]} is not a valid browser or driver"
      exit 1
    fi
  done

elif [ "$command" == "which" ]; then
  IFS='=' read -ra parts <<< "$which"

  if [ "${parts[0]}" == "chrome" ]; then
    "$BDM_SRC_DIR/which/chrome.sh" "${parts[1]}"
  elif [ "${parts[0]}" == "chromedriver" ]; then
    "$BDM_SRC_DIR/which/chromedriver.sh" "${parts[1]}"
  else
    error "${parts[0]} is not a valid browser or driver"
    exit 1
  fi

elif [ "$command" == "version" ]; then
  IFS='=' read -ra parts <<< "$version"

  if [ "${parts[0]}" == "chrome" ]; then
    "$BDM_SRC_DIR/version/chrome.sh" "${parts[1]}"
  elif [ "${parts[0]}" == "chromedriver" ]; then
    "$BDM_SRC_DIR/version/chromedriver.sh" "${parts[1]}"
  else
    error "${parts[0]} is not a valid browser or driver"
    exit 1
  fi

fi