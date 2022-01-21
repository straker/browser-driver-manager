testDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
rootDir="$(cd "${testDir}/.." && pwd)"
BDM_SRC_DIR="$rootDir/src"
tmpDir="$rootDir/tmp"

chromedriverPath="/usr/local/bin/chromedriver"
chromedriverVersion=$(sh $testDir/assets/mock-chromedriver97)

chromeStableVersion=$(sh $testDir/assets/mock-chrome)
chromeBetaVersion=$(sh $testDir/assets/mock-chrome-beta)
chromeDevVersion=$(sh $testDir/assets/mock-chrome-dev)
chromeCanaryVersion=$(sh $testDir/assets/mock-chrome-canary)

# linuxChromeStablePath=$(which google-chrome)
# linuxChromeBetaPath=$(which google-chrome-beta)
# linuxChromeDevPath=$(which google-chrome-dev)

macChromePath="/Applications/Google Chrome"
macChromeDir="Contents/MacOS"
macChromeStablePath="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
macChromeBetaPath="/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta"
macChromeDevPath="/Applications/Google Chrome Dev.app/Contents/MacOS/Google Chrome Dev"
macChromeCanaryPath="/Applications/Google Chrome Canary.app/Contents/MacOS/Google Chrome Canary"

# Make sure to restore chromedriver and chrome if tests quit
# expectantly
trap oneTimeTearDown SIGINT
trap oneTimeTearDown SIGTERM

# Because we're running the oneTimeTearDown function on exit, we
# need to make sure it's only run once or we'll end up deleting
# Chrome on accident
cleanedUp=false

# Detect operating system
os=$(uname)
case $os in
  'Linux')
    os='Linux' ;;
  'Darwin')
    os='MacOs' ;;
  *)
    error "$os system not supported"
    exit 1 ;;
esac

# Save original chromedriver so we can restore it at the end of the test
oneTimeSetUp() {
  if command -v $chromedriver >/dev/null; then
    sudo mv "$chromedriverPath" "$tmpDir/chromedriver"
  fi

  if [ $os == 'Linux' ]; then
    if [ -f "$linuxChromeStablePath" ]; then
      sudo mv "$linuxChromeStablePath" "$tmpDir"
    fi

    if [ -f "$linuxChromeBetaPath" ]; then
      sudo mv "$linuxChromeBetaPath" "$tmpDir"
    fi

    if [ -f "$linuxChromeDevPath" ]; then
      sudo mv "$linuxChromeDevPath" "$tmpDir"
    fi
  elif [ $os == 'MacOs' ]; then
    if [ -f "$macChromeStablePath" ]; then
      sudo mv "$macChromeStablePath" "$tmpDir"
    else
      sudo mkdir -p "$macChromePath.app/$macChromeDir"
    fi

    if [ -f "$macChromeBetaPath" ]; then
      sudo mv "$macChromeBetaPath" "$tmpDir"
    else
      sudo mkdir -p "$macChromePath Beta.app/$macChromeDir"
    fi

    if [ -f "$macChromeDevPath" ]; then
      sudo mv "$macChromeDevPath" "$tmpDir"
    else
      sudo mkdir -p "$macChromePath Dev.app/$macChromeDir"
    fi

    if [ -f "$macChromeCanaryPath" ]; then
      sudo mv "$macChromeCanaryPath" "$tmpDir"
    else
      sudo mkdir -p "$macChromePath Canary.app/$macChromeDir"
    fi
  fi
}

oneTimeTearDown() {
  if [ "$cleanedUp" == false ]; then
    cleanedUp=true

    if [ -f "$tmpDir/chromedriver" ]; then
      sudo mv "$tmpDir/chromedriver" "$chromedriverPath"
    fi

    if [ $os == 'Linux' ]; then
      if [ -f "$tmpDir/google-chrome" ]; then
        sudo mv "$tmpDir/google-chrome" "$linuxChromeStablePath"
      fi

      if [ -f "$tmpDir/google-chrome-beta" ]; then
        sudo mv "$tmpDir/google-chrome-beta" "$linuxChromeBetaPath"
      fi

      if [ -f "$tmpDir/google-chrome-dev" ]; then
        sudo mv "$tmpDir/google-chrome-dev" "$linuxChromeDevPath"
      fi
    elif [ $os == 'MacOs' ]; then
      if [ -f "$tmpDir/Google Chrome" ]; then
        sudo mv "$tmpDir/Google Chrome" "$macChromeStablePath"
      else
        sudo rm -rf "$macChromePath.app"
      fi

      if [ -f "$tmpDir/Google Chrome Beta" ]; then
        sudo mv "$tmpDir/Google Chrome Beta" "$macChromeBetaPath"
      else
        sudo rm -rf "$macChromePath Beta.app"
      fi

      if [ -f "$tmpDir/Google Chrome Dev" ]; then
        sudo mv "$tmpDir/Google Chrome Dev" "$macChromeDevPath"
      else
        sudo rm -rf "$macChromePath Dev.app"
      fi

      if [ -f "$tmpDir/Google Chrome Canary" ]; then
        sudo mv "$tmpDir/Google Chrome Canary" "$macChromeCanaryPath"
      else
        sudo rm -rf "$macChromePath Canary.app"
      fi
    fi

  fi
}

# Install mock chrome and chromedriver before each tests
setUp() {
  sudo cp "$testDir/assets/mock-chromedriver97" "$chromedriverPath"

  if [ $os == 'Linux' ]; then
    sudo cp "$testDir/assets/mock-chrome" "$linuxChromeStablePath"
    sudo cp "$testDir/assets/mock-chrome-beta" "$linuxChromeBetaPath"
    sudo cp "$testDir/assets/mock-chrome-dev" "$linuxChromeDevPath"
  elif [ $os == 'MacOs' ]; then
    sudo cp "$testDir/assets/mock-chrome" "$macChromeStablePath"
    sudo cp "$testDir/assets/mock-chrome-beta" "$macChromeBetaPath"
    sudo cp "$testDir/assets/mock-chrome-dev" "$macChromeDevPath"
    sudo cp "$testDir/assets/mock-chrome-canary" "$macChromeCanaryPath"
  fi

}

#-------------------------------------------------
# Which Chromedriver
#-------------------------------------------------
test_which_chromedriver_should_ouput_dir() {
  output=$($BDM_SRC_DIR/index.sh which chromedriver)
  assertEquals "$output" "$chromedriverPath"
}

test_which_chromedriver_should_error_if_not_installed() {
  sudo rm -f "$chromedriverPath"
  output=$($BDM_SRC_DIR/index.sh which chromedriver 2>&1)
  assertContains "$output" "chromedriver is not installed"
}

test_which_chromedriver_should_error_with_exit_code_1() {
  sudo rm -f "$chromedriverPath"
  output=$($BDM_SRC_DIR/index.sh which chromedriver 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
}

test_which_chromedriver_should_accept_stable_channel() {
  output=$($BDM_SRC_DIR/index.sh which chromedriver=stable)
  assertEquals "$output" "$chromedriverPath"
}

test_which_chromedriver_should_error_for_invalid_channel() {
  output=$($BDM_SRC_DIR/index.sh which chromedriver=invalid 2>&1)
  assertContains "$output" "Chrome supported channels"
}

#-------------------------------------------------
# Which Chrome
#-------------------------------------------------
test_which_chrome_should_output_dir() {
  output=$($BDM_SRC_DIR/index.sh which chrome)

  if [ $os == "Linux" ]; then
    assertEquals "$output" "$linuxChromeStablePath"
  else
    assertEquals "$output" "$macChromeStablePath"
  fi
}

test_which_chrome_should_error_if_not_installed() {
  if [ $os == "Linux" ]; then
    sudo rm -f "$linuxChromeStablePath"
  else
    sudo rm -f "$macChromeStablePath"
  fi

  output=$($BDM_SRC_DIR/index.sh which chrome 2>&1)
  assertContains "$output" "Google Chrome is not installed"
}

test_which_chrome_should_error_with_exit_code_1() {
  if [ $os == "Linux" ]; then
    sudo rm -f "$linuxChromeStablePath"
  else
    sudo rm -f "$macChromeStablePath"
  fi

  output=$($BDM_SRC_DIR/index.sh which chrome 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
}

test_which_chrome_should_accept_stable_channel() {
  output=$($BDM_SRC_DIR/index.sh which chrome=stable)

  if [ $os == "Linux" ]; then
    assertEquals "$output" "$linuxChromeStablePath"
  else
    assertEquals "$output" "$macChromeStablePath"
  fi
}

test_which_chrome_should_accept_beta_channel() {
  output=$($BDM_SRC_DIR/index.sh which chrome=beta)

  if [ $os == "Linux" ]; then
    assertEquals "$output" "$linuxChromeBetaPath"
  else
    assertEquals "$output" "$macChromeBetaPath"
  fi
}

test_which_chrome_should_accept_dev_channel() {
  output=$($BDM_SRC_DIR/index.sh which chrome=dev)

  if [ $os == "Linux" ]; then
    assertEquals "$output" "$linuxChromeDevPath"
  else
    assertEquals "$output" "$macChromeDevPath"
  fi
}

test_which_chrome_should_accept_canary_channel() {
  # Linux doesn't support canary channel
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$($BDM_SRC_DIR/index.sh which chrome=canary 2>/dev/null)
  assertEquals "$output" "$macChromeCanaryPath"
}

test_which_chrome_should_error_for_invalid_channel() {
  output=$($BDM_SRC_DIR/index.sh which chrome=invalid 2>&1)
  assertContains "$output" "Chrome supported channels"
}

test_which_chrome_should_output_verbose_logs() {
  output=$($BDM_SRC_DIR/index.sh which chrome=beta --verbose)
  assertContains "$output" "Looking for path for Google Chrome Beta"
}

#-------------------------------------------------
# Version Chromedriver
#-------------------------------------------------
test_version_chromedriver_should_ouput_version() {
  output=$($BDM_SRC_DIR/index.sh version chromedriver)
  assertEquals "$output" "$chromedriverVersion"
}

test_version_chromedriver_should_error_if_not_installed() {
  sudo rm -f "$chromedriverPath"
  output=$($BDM_SRC_DIR/index.sh version chromedriver 2>&1)
  assertContains "$output" "chromedriver is not installed"
}

test_version_chromedriver_should_error_with_exit_code_1() {
  sudo rm -f "$chromedriverPath"
  output=$($BDM_SRC_DIR/index.sh version chromedriver 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
}

test_version_chromedriver_should_accept_stable_channel() {
  output=$($BDM_SRC_DIR/index.sh version chromedriver=stable)
  assertEquals "$output" "$chromedriverVersion"
}

test_version_chromedriver_should_error_for_invalid_channel() {
  output=$($BDM_SRC_DIR/index.sh version chromedriver=invalid 2>&1)
  assertContains "$output" "Chrome supported channels"
}

#-------------------------------------------------
# Version Chrome
#-------------------------------------------------
test_version_chrome_should_ouput_version() {
  output=$($BDM_SRC_DIR/index.sh version chrome)
  assertEquals "$output" "$chromeStableVersion"
}

test_version_chrome_should_error_if_not_installed() {
  if [ $os == "Linux" ]; then
    sudo rm -f "$linuxChromeStablePath"
  else
    sudo rm -f "$macChromeStablePath"
  fi

  output=$($BDM_SRC_DIR/index.sh version chrome 2>&1)
  assertContains "$output" "Google Chrome is not installed"
}

test_version_chrome_should_error_with_exit_code_1() {
  if [ $os == "Linux" ]; then
    sudo rm -f "$linuxChromeStablePath"
  else
    sudo rm -f "$macChromeStablePath"
  fi

  output=$($BDM_SRC_DIR/index.sh version chrome 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
}

test_version_chrome_should_accept_stable_channel() {
  output=$($BDM_SRC_DIR/index.sh version chrome=stable)
  assertEquals "$output" "$chromeStableVersion"
}

test_version_chrome_should_accept_beta_channel() {
  output=$($BDM_SRC_DIR/index.sh version chrome=beta)
  assertEquals "$output" "$chromeBetaVersion"
}

test_version_chrome_should_accept_dev_channel() {
  output=$($BDM_SRC_DIR/index.sh version chrome=dev)
  assertEquals "$output" "$chromeDevVersion"
}

test_version_chrome_should_accept_stable_channel() {
  # Linux doesn't support canary channel
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$($BDM_SRC_DIR/index.sh version chrome=canary)
  assertEquals "$output" "$chromeCanaryVersion"
}

test_version_chrome_should_error_for_invalid_channel() {
  output=$($BDM_SRC_DIR/index.sh version chrome=invalid 2>&1)
  assertContains "$output" "Chrome supported channels"
}

test_version_chrome_should_output_verbose_logs() {
  output=$($BDM_SRC_DIR/index.sh version chrome=beta --verbose)
  assertContains "$output" "Looking for path for Google Chrome Beta"
}

# Load shUnit2
source "$testDir/shunit2/shunit2"