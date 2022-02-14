#! /bin/bash

# Display verbose log file descriptor
# @see https://stackoverflow.com/questions/64530573/in-bash-how-to-capture-some-output-in-variable-letting-rest-got-to-standard-ou
exec 3>&1

# Get path of current script, following symlinks (such as node_modules/.bin) or when run through the $PATH
# @see https://stackoverflow.com/a/697552/2124254

# get the absolute path of the executable
selfPath=$(cd -P -- "$(dirname -- "$0")" && pwd -P) && selfPath=$selfPath/$(basename -- "$0")

# resolve symlinks
while [[ -h $selfPath ]]; do
  # 1) cd to directory of the symlink
  # 2) cd to the directory of where the symlink points
  # 3) get the pwd
  # 4) append the basename
  dir=$(dirname -- "$selfPath")
  sym=$(readlink "$selfPath")
  selfPath=$(cd "$dir" && cd "$(dirname -- "$sym")" && pwd)/$(basename -- "$sym")
done

export BDM_SRC_DIR="$(dirname $selfPath)"
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
  echo "usage: $0 [options] [command]"
  echo ""
  echo "commands:"
  echo "  install        Install browsers or drivers"
  echo "  version        Get the installed version of the browser or driver"
  echo "  which          Get the installed location of the browser or driver"
  echo ""
  echo "options:"
  echo "  -h, --help     Display this help and exit"
  echo "  -v, --version  Output version information and exit"
  echo "  --verbose      Output verbose logs"
  echo ""
  echo "examples:"
  echo "  $0 install chrome"
  echo "  $0 install chrome=beta chromedriver=beta"
  echo "  $0 install chromedriver=97"
  echo "  $0 version chrome"
  echo "  $0 which chromedriver"
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
      if [[ ! $2 ]]; then
        echo "usage: $0 which [ chrome | chromedriver ] [{=version}]"
        exit 1
      fi

      command="which"
      which=$(lowercase $2)
      shift 2 ;;
    version)
      if [[ ! $2 ]]; then
        echo "usage: $0 version [ chrome | chromedriver ] [{=version}]"
        exit 1
      fi

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
  if [[ ${#install[@]} -eq 0 ]]; then
    echo "usage: $0 install [ chrome | chromedriver ] [{=version}]..."
    exit 1
  fi

  for package in "${install[@]}"; do
    # Split string
    # @see https://linuxhandbook.com/bash-split-string/
    IFS='=' read -ra parts <<< "$package"

    # Run install scripts
    if [ "${parts[0]}" == "chrome" ]; then
      "$BDM_SRC_DIR/install/chrome.sh" "${parts[1]}"
    elif [ "${parts[0]}" == "chromedriver" ]; then
      "$BDM_SRC_DIR/install/chromedriver.sh" "${parts[1]}"
    elif [ "${parts[0]}" == "firefox" ]; then
    "$BDM_SRC_DIR/install/firefox.sh" "${parts[1]}"
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
  elif [ "${parts[0]}" == "firefox" ]; then
    "$BDM_SRC_DIR/which/firefox.sh" "${parts[1]}"
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
  elif [ "${parts[0]}" == "firefox" ]; then
    "$BDM_SRC_DIR/version/firefox.sh" "${parts[1]}"
  else
    error "${parts[0]} is not a valid browser or driver"
    exit 1
  fi

fi