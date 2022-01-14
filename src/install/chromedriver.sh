#!/bin/bash

chromedriverZip="$BDM_TMP_DIR/chromedriver.zip"
chromedriverFile="$BDM_TMP_DIR/chromedriver"

# Import utils
source "$BDM_SRC_DIR/utils.sh"

# @see https://chromedriver.chromium.org/downloads/version-selection
latestUrl="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"
chromedriverUrl="https://chromedriver.storage.googleapis.com/index.html?path="

version="stable"
if [[ $1 ]]; then
  version=$1
fi

# Find which version of Chrome is installed and use the matching
# ChromeDriver version
if [ $version == "stable" ] || [ $version == "beta" ] || [ $version == "dev" ] || [ $version == "canary" ]; then

  channel=$version
  output=$($BDM_SRC_DIR/version/chrome.sh "$version")
  lastLine=$(getLastLine "$output")

  # Output everything but the last line from the output to display
  # verbose log info
  IFS=$'\n' read -rd '' -a lines <<<"$output"
  for line in "${lines[@]}"; do
    if [ "$line" != "$lastLine" ]; then
      echo "$line"
    fi
  done

  # Extract the version number and major number
  versionNumber="$(echo $lastLine | sed 's/^Google Chrome //' | sed 's/^Chromium //')"
  version="${versionNumber%%.*}"

  echo "Chrome $(titleCase $channel) version detected as $versionNumber"
fi

echo "Installing ChromeDriver $version"

# Determine how to download ChromeDriver
tries=0
function getChromeDriverVersion() {
  latestUrl="https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$version"
  if command -v curl >/dev/null; then
    if [ $BDM_VERBOSE -eq 1 ]; then
      echo "Using curl to get response from $latestUrl"
    fi

    chromedriverVersion=$(curl --location --retry 3 --silent --fail $latestUrl)
  elif command -v wget >/dev/null; then
    if [ $BDM_VERBOSE -eq 1 ]; then
      echo "Using wget to get response from $latestUrl"
    fi

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

  if [ $BDM_VERBOSE -eq 1 ]; then
    echo "Received response of $chromedriverVersion"
  fi

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

download "$chromedriverUrl" "$chromedriverZip" "$BDM_VERBOSE"

if command -v unzip >/dev/null; then
  if [ $BDM_VERBOSE -eq 1 ]; then
    echo "Unzipping ChromeDriver to $BDM_TMP_DIR"
  fi
  unzip "$chromedriverZip" -d "$BDM_TMP_DIR" > /dev/null 2>&1

  if [ $BDM_VERBOSE -eq 1 ]; then
    echo "Changing ChromeDriver permissions to executable"
  fi
  chmod +x "$chromedriverFile"

  if [ $BDM_VERBOSE -eq 1 ]; then
    echo "Moving ChromeDriver to /usr/local/bin"
  fi
  sudo mv "$chromedriverFile" /usr/local/bin

  if [ $BDM_VERBOSE -eq 1 ]; then
    echo "Deleting ChromeDriver zip"
  fi
  sudo rm -f "$chromedriverZip"
else
  error "Unable to install ChromeDriver; System does not support unzip"
  exit 1
fi

# Verify success
if chromedriver --version | grep "$chromedriverVersion" > /dev/null 2>&1; then
  echo "Successfully installed ChromeDriver $chromedriverVersion"
else
  echo "Unable to install ChromeDriver; Something went wrong"

  if [ $BDM_VERBOSE -eq 1 ]; then
    echo "Tried to install ChromeDriver $chromedriverVersion but installed version is $(chromedriver --version)"
  fi
  exit 1
fi