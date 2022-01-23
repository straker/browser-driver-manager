#!/bin/bash

testDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
rootDir="$(cd "${testDir}/.." && pwd)"
srcDir="$rootDir/src"
tmpDir="$rootDir/tmp"

chromedriverPath="/usr/local/bin/chromedriver"
chromedriverVersion=$(sh $testDir/mocks/mock-chromedriver97)
chromedriverVersionString=$(echo "$chromedriverVersion" | cut -d ' ' -f 2)

chromeStableVersion=$(sh $testDir/mocks/mock-chrome)
chromeBetaVersion=$(sh $testDir/mocks/mock-chrome-beta)
chromeDevVersion=$(sh $testDir/mocks/mock-chrome-dev)
chromeCanaryVersion=$(sh $testDir/mocks/mock-chrome-canary)

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
    if [ -f "$chromedriverPath" ]; then
      sudo mv "$chromedriverPath" "$tmpDir/chromedriver"
    fi
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

  # Modify the path to use mock curl / wget commands instead of the
  # built in ones. That way we can control the responses and check
  # that we are hitting the correct URLs
  originalPath=$(echo $PATH)
  export PATH="$testDir/mocks:$PATH"
}

oneTimeTearDown() {
  if [ "$cleanedUp" == false ]; then
    cleanedUp=true

    # Unmodify path
    PATH=$(echo $originalPath)

    # Clear the contents of the mock-log-file
    > "$testDir/mocks/mock-log-file.txt"

    sudo rm -f "$tmpDir/chromedriver.zip"

    if [ -f "$tmpDir/chromedriver" ]; then
      sudo mv "$tmpDir/chromedriver" "$chromedriverPath"
    else
      sudo rm -f "$chromedriverPath"
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
  # Clear the contents of the mock-log-file
  > "$testDir/mocks/mock-log-file.txt"

  sudo cp "$testDir/mocks/mock-chromedriver97" "$chromedriverPath"
  sudo cp "$testDir/mocks/mock-chromedriver97.zip" "$tmpDir/chromedriver.zip"

  if [ $os == 'Linux' ]; then
    sudo cp "$testDir/mocks/mock-chrome" "$linuxChromeStablePath"
    sudo cp "$testDir/mocks/mock-chrome-beta" "$linuxChromeBetaPath"
    sudo cp "$testDir/mocks/mock-chrome-dev" "$linuxChromeDevPath"
  elif [ $os == 'MacOs' ]; then
    sudo cp "$testDir/mocks/mock-chrome" "$macChromeStablePath"
    sudo cp "$testDir/mocks/mock-chrome-beta" "$macChromeBetaPath"
    sudo cp "$testDir/mocks/mock-chrome-dev" "$macChromeDevPath"
    sudo cp "$testDir/mocks/mock-chrome-canary" "$macChromeCanaryPath"
  fi
}

#-------------------------------------------------
# Which Chromedriver
#-------------------------------------------------
test_which_chromedriver_should_ouput_dir() {
  output=$($srcDir/index.sh which chromedriver)
  assertEquals "$output" "$chromedriverPath"
}

test_which_chromedriver_should_error_if_not_installed() {
  sudo rm -f "$chromedriverPath"
  output=$($srcDir/index.sh which chromedriver 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "chromedriver is not installed"
}

test_which_chromedriver_should_accept_stable_channel() {
  output=$($srcDir/index.sh which chromedriver=stable)
  assertEquals "$output" "$chromedriverPath"
}

test_which_chromedriver_should_error_for_invalid_channel() {
  output=$($srcDir/index.sh which chromedriver=invalid 2>&1)
  assertContains "$output" "Chrome supported channels"
}

#-------------------------------------------------
# Which Chrome
#-------------------------------------------------
test_which_chrome_should_output_dir() {
  output=$($srcDir/index.sh which chrome)

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

  output=$($srcDir/index.sh which chrome 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Google Chrome is not installed"
}

test_which_chrome_should_accept_stable_channel() {
  output=$($srcDir/index.sh which chrome=stable)

  if [ $os == "Linux" ]; then
    assertEquals "$output" "$linuxChromeStablePath"
  else
    assertEquals "$output" "$macChromeStablePath"
  fi
}

test_which_chrome_should_accept_beta_channel() {
  output=$($srcDir/index.sh which chrome=beta)

  if [ $os == "Linux" ]; then
    assertEquals "$output" "$linuxChromeBetaPath"
  else
    assertEquals "$output" "$macChromeBetaPath"
  fi
}

test_which_chrome_should_accept_dev_channel() {
  output=$($srcDir/index.sh which chrome=dev)

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

  output=$($srcDir/index.sh which chrome=canary 2>/dev/null)
  assertEquals "$output" "$macChromeCanaryPath"
}

test_which_chrome_should_error_for_invalid_channel() {
  output=$($srcDir/index.sh which chrome=invalid 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Chrome supported channels"
}

test_which_chrome_should_not_output_verbose_logs() {
  output=$($srcDir/index.sh which chrome=beta)
  assertNotContains "$output" "Looking for path for Google Chrome Beta"
}

test_which_chrome_should_output_verbose_logs_with_flag() {
  output=$($srcDir/index.sh which chrome=beta --verbose)
  assertContains "$output" "Looking for path for Google Chrome Beta"
}

#-------------------------------------------------
# Version Chromedriver
#-------------------------------------------------
test_version_chromedriver_should_ouput_version() {
  output=$($srcDir/index.sh version chromedriver)
  assertEquals "$output" "$chromedriverVersion"
}

test_version_chromedriver_should_error_if_not_installed() {
  sudo rm -f "$chromedriverPath"
  output=$($srcDir/index.sh version chromedriver 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "chromedriver is not installed"
}

test_version_chromedriver_should_accept_stable_channel() {
  output=$($srcDir/index.sh version chromedriver=stable)
  assertEquals "$output" "$chromedriverVersion"
}

test_version_chromedriver_should_error_for_invalid_channel() {
  output=$($srcDir/index.sh version chromedriver=invalid 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Chrome supported channels"
}

#-------------------------------------------------
# Version Chrome
#-------------------------------------------------
test_version_chrome_should_ouput_version() {
  output=$($srcDir/index.sh version chrome)
  assertEquals "$output" "$chromeStableVersion"
}

test_version_chrome_should_error_if_not_installed() {
  if [ $os == "Linux" ]; then
    sudo rm -f "$linuxChromeStablePath"
  else
    sudo rm -f "$macChromeStablePath"
  fi

  output=$($srcDir/index.sh version chrome 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Google Chrome is not installed"
}

test_version_chrome_should_accept_stable_channel() {
  output=$($srcDir/index.sh version chrome=stable)
  assertEquals "$output" "$chromeStableVersion"
}

test_version_chrome_should_accept_beta_channel() {
  output=$($srcDir/index.sh version chrome=beta)
  assertEquals "$output" "$chromeBetaVersion"
}

test_version_chrome_should_accept_dev_channel() {
  output=$($srcDir/index.sh version chrome=dev)
  assertEquals "$output" "$chromeDevVersion"
}

test_version_chrome_should_accept_canary_channel() {
  # Linux doesn't support canary channel
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$($srcDir/index.sh version chrome=canary)
  assertEquals "$output" "$chromeCanaryVersion"
}

test_version_chrome_should_error_for_invalid_channel() {
  output=$($srcDir/index.sh version chrome=invalid 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Chrome supported channels"
}

test_version_chrome_should_not_output_verbose_logs() {
  output=$($srcDir/index.sh version chrome=beta --verbose)
  assertContains "$output" "Looking for path for Google Chrome Beta"
}

test_version_chrome_should_output_verbose_logs_with_flag() {
  output=$($srcDir/index.sh version chrome=beta --verbose)
  assertContains "$output" "Looking for path for Google Chrome Beta"
}

#-------------------------------------------------
# Install Chromedriver
#-------------------------------------------------
test_install_chromedriver_should_accept_stable_channel_and_get_version_from_chrome() {
  output=$($srcDir/index.sh install chromedriver=stable 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 97"
}

test_install_chromedriver_should_accept_beta_channel_and_get_version_from_chrome() {
  output=$($srcDir/index.sh install chromedriver=beta 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 98"
}

test_install_chromedriver_should_accept_dev_channel_and_get_version_from_chrome() {
  output=$($srcDir/index.sh install chromedriver=dev 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 99"
}

test_install_chromedriver_should_accept_canary_channel_and_get_version_from_chrome() {
  # Linux doesn't support canary channel
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$($srcDir/index.sh install chromedriver=canary 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 100"
}

test_install_chromedriver_should_error_for_invalid_channel() {
  output=$($srcDir/index.sh install chromedriver=invalid 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Chrome supported channels"
}

test_install_chromedriver_should_error_if_chrome_version_is_bad() {
  if [ $os == 'Linux' ]; then
    sudo cp "$testDir/mocks/mock-bad-chrome" "$linuxChromeStablePath"
  elif [ $os == 'MacOs' ]; then
    sudo cp "$testDir/mocks/mock-bad-chrome" "$macChromeStablePath"
  fi

  output=$($srcDir/index.sh install chromedriver 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Chrome version \"Not a Number\" is not a number"
}

test_install_chromedriver_should_error_if_not_installed() {
  if [ $os == "Linux" ]; then
    sudo rm -f "$linuxChromeStablePath"
  else
    sudo rm -f "$macChromeStablePath"
  fi

  output=$($srcDir/index.sh install chromedriver=stable 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Google Chrome is not installed"
}


test_install_chromedriver_should_print_chrome_version() {
  output=$($srcDir/index.sh install chromedriver=stable 2>/dev/null)
  assertContains "$output" "Chrome Stable version detected as 97"
}

test_install_chromedriver_should_print_chromedriver_version_to_install() {
  output=$($srcDir/index.sh install chromedriver=97 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 97"
}

test_install_chromedriver_should_get_lastest_release_using_version() {
  $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_97"
}

test_install_chromedriver_should_use_one_version_lower_and_try_again_if_version_is_not_found() {
  # version >100 is used in mock-http to return a bad request
  output=$($srcDir/index.sh install chromedriver=101 2>/dev/null)
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$output" "ChromeDriver 101 not found. Retrying with ChromeDriver 100"
  assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_101"
  assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_100"
}

test_install_chromedriver_should_error_if_chromedriver_version_is_not_available() {
  output=$($srcDir/index.sh install chromedriver=200 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Unable to get ChromeDriver version; Something went wrong"
}

test_install_chromedriver_should_exit_if_chromedriver_version_already_is_installed() {
  output=$($srcDir/index.sh install chromedriver=97 2>/dev/null)
  exitCode=$?
  assertEquals "$exitCode" 0
  assertContains "$output" "ChromeDriver $chromedriverVersionString already installed"
}

test_install_chromedriver_should_download_zip_from_version() {
  sudo rm -f "$chromedriverPath"
  output=$($srcDir/index.sh install chromedriver=97 2>/dev/null)
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")

  if [ $os == "Linux" ]; then
    assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/$chromedriverVersionString/chromedriver_linux64.zip"
  else
    assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/$chromedriverVersionString/chromedriver_mac64.zip"
  fi
}

test_install_chromedriver_should_unzip_download() {
  sudo rm -f "$chromedriverPath"
  $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "unzip $tmpDir/chromedriver.zip -d $tmpDir"
}

test_install_chromedriver_should_change_permissions_of_download() {
  sudo rm -f "$chromedriverPath"
  $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "chmod +x $tmpDir/chromedriver"
}

test_install_chromedriver_should_move_download() {
  sudo rm -f "$chromedriverPath"
  $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "mv $tmpDir/chromedriver /usr/local/bin"
}

test_install_chromedriver_should_cleanup_zip() {
  sudo rm -f "$chromedriverPath"
  $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null

  if [[ -f "$tmpDir/chromedriver.zip" ]]; then
    fail "Zip was not removed"
  fi
}

test_install_chromedriver_should_verify_install_matches_version() {
  sudo rm -f "$chromedriverPath"
  output=$($srcDir/index.sh install chromedriver=97 2>/dev/null)
  assertContains "$output" "Successfully installed ChromeDriver $chromedriverVersionString"
}

test_install_chromedriver_should_error_if_installed_version_does_not_match() {
  sudo rm -f "$chromedriverPath"
  output=$($srcDir/index.sh install chromedriver=98 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Unable to install ChromeDriver; Something went wrong"
}

test_install_chromedriver_should_output_verbose_logs_with_flag() {
  output=$($srcDir/index.sh install chromedriver=97 --verbose)
  assertContains "$output" "Received response of $chromedriverVersionString"
}

# Load shUnit2
source "$testDir/shunit2/shunit2"