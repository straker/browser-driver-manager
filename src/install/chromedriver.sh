#! /bin/bash

# Force install script to run in sudo privileges
# @see https://serverfault.com/a/677876
if [[ $EUID -ne 0 ]]; then
  echo "$0 is not running as root. Try using \"sudo $0\""
  exit 2
fi

chromedriverZip="$BDM_TMP_DIR/chromedriver.zip"
chromedriverFile="$BDM_TMP_DIR/chromedriver"
isNumberRegex='^[0-9]+$'

# Import utils
source "$BDM_SRC_DIR/utils.sh"

# @see https://chromedriver.chromium.org/downloads/version-selection
latestUrl="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"

version="stable"
if [[ $1 ]]; then
  version=$1
fi

# Find which version of Chrome is installed and use the matching
# ChromeDriver version
if [ $version == "stable" ] || [ $version == "beta" ] || [ $version == "dev" ] || [ $version == "canary" ]; then

  channel=$version
  chomeVersion=$($BDM_SRC_DIR/version/chrome.sh "$version")
  exitCode=$?
  if [ "$exitCode" -ne 0 ]; then
    exit "$exitCode"
  fi

  # Extract the version number and major number
  versionNumber="$(echo $chomeVersion | sed 's/^Google Chrome //' | sed 's/^Chromium //')"
  version="${versionNumber%%.*}"

  # Ensure version is a number
  # @see https://stackoverflow.com/a/806923
  if ! [[ $version =~ $isNumberRegex ]]; then
     error "Chrome version \"$version\" is not a number"
     exit 1
  fi

  echo "Chrome $(titleCase $channel) version detected as $versionNumber"
elif ! [[ $version =~ $isNumberRegex ]]; then
  validateChromeChannel $version
fi

echo "Installing ChromeDriver $version"

# Determine how to download ChromeDriver
tries=0
function getChromeDriverVersion() {
  latestUrl="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$version"
  if command -v curl >/dev/null; then
    verboseLog "Using curl to get response from $latestUrl"

    chromedriverVersion=$(curl --location --retry 3 --silent --fail $latestUrl)
  elif command -v wget >/dev/null; then
    verboseLog "Using wget to get response from $latestUrl"

    chromedriverVersion=$(wget --tries=3 --quiet $latestUrl)
  fi

  # Verify we got a response back
  if [[ ! $chromedriverVersion = $version* ]]; then

    # If chromedriver doesn't exist for the current version, reduce by
    # one major version and try again
    # @see https://chromedriver.chromium.org/downloads/version-selection
    if [ $tries -eq 0 ]; then
      triedVersion=$version
      tries=$((tries+1))
      version=$((version-1))

      echo "ChromeDriver $triedVersion not found. Retrying with ChromeDriver $version"

      getChromeDriverVersion
      return 0
    else
      error "Unable to get ChromeDriver version; Something went wrong"
      exit 1
    fi
  fi

  verboseLog "Received response of $chromedriverVersion"

  echo "chromedriver already installed: $(chromedriver --version)"

  if command -v chromedriver >/dev/null && chromedriver --version | grep "$chromedriverVersion" > /dev/null 2>&1; then
    echo "ChromeDriver $chromedriverVersion already installed"
    exit 0
  fi
}

getChromeDriverVersion

if [ $BDM_OS == "Linux" ]; then
  chromedriverUrl="https://chromedriver.storage.googleapis.com/$chromedriverVersion/chromedriver_linux64.zip"
elif [ $BDM_OS == "MacOs" ]; then
  chromedriverUrl="https://chromedriver.storage.googleapis.com/$chromedriverVersion/chromedriver_mac64.zip"
fi

download "$chromedriverUrl" "$chromedriverZip"
exitCode=$?
if [ "$exitCode" -ne 0 ]; then
  exit "$exitCode"
fi

if command -v unzip >/dev/null; then
  verboseLog "Unzipping ChromeDriver to $BDM_TMP_DIR"
  unzip "$chromedriverZip" -d "$BDM_TMP_DIR" > /dev/null 2>&1

  verboseLog "Changing ChromeDriver permissions to executable"
  chmod +x "$chromedriverFile"

  verboseLog "Moving ChromeDriver to /usr/local/bin"
  mv "$chromedriverFile" /usr/local/bin

  verboseLog "Deleting ChromeDriver zip"
  rm -f "$chromedriverZip"
else
  error "Unable to install ChromeDriver; System does not support unzip"
  exit 1
fi

# Verify success
if chromedriver --version | grep "$chromedriverVersion" > /dev/null 2>&1; then
  echo "Successfully installed ChromeDriver $chromedriverVersion"
else
  echo "Unable to install ChromeDriver; Something went wrong"

  verboseLog "Tried to install ChromeDriver $chromedriverVersion but installed version is $(chromedriver --version)"
  exit 1
fi