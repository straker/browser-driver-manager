#! /bin/bash

testDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
userDir="$testDir/user-files"
rootDir="$(cd "${testDir}/.." && pwd)"
srcDir="$rootDir/src"
tmpDir="$rootDir/tmp"

chromedriverPath="/usr/local/bin/chromedriver"
chromedriverVersion=$(sh $testDir/mocks/mock-chromedriver)
chromedriverVersionString=$(echo "$chromedriverVersion" | cut -d ' ' -f 2)

chromeStableVersion=$(sh $testDir/mocks/mock-chrome)
chromeBetaVersion=$(sh $testDir/mocks/mock-chrome-beta)
chromeDevVersion=$(sh $testDir/mocks/mock-chrome-dev)
chromeCanaryVersion=$(sh $testDir/mocks/mock-chrome-canary)

linuxChromeStablePath="/usr/bin/google-chrome"
linuxChromeBetaPath="/usr/bin/google-chrome-beta"
linuxChromeDevPath="/usr/bin/google-chrome-dev"

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
      sudo mv "$chromedriverPath" "$userDir/chromedriver"
    fi
  fi

  if [ $os == 'Linux' ]; then
    if [ -f "$linuxChromeStablePath" ]; then
      sudo mv "$linuxChromeStablePath" "$userDir"
    fi

    if [ -f "$linuxChromeBetaPath" ]; then
      sudo mv "$linuxChromeBetaPath" "$userDir"
    fi

    if [ -f "$linuxChromeDevPath" ]; then
      sudo mv "$linuxChromeDevPath" "$userDir"
    fi
  elif [ $os == 'MacOs' ]; then
    if [ -f "$macChromeStablePath" ]; then
      sudo mv "$macChromeStablePath" "$userDir"
    else
      sudo mkdir -p "$macChromePath.app/$macChromeDir"
    fi

    if [ -f "$macChromeBetaPath" ]; then
      sudo mv "$macChromeBetaPath" "$userDir"
    else
      sudo mkdir -p "$macChromePath Beta.app/$macChromeDir"
    fi

    if [ -f "$macChromeDevPath" ]; then
      sudo mv "$macChromeDevPath" "$userDir"
    else
      sudo mkdir -p "$macChromePath Dev.app/$macChromeDir"
    fi

    if [ -f "$macChromeCanaryPath" ]; then
      sudo mv "$macChromeCanaryPath" "$userDir"
    else
      sudo mkdir -p "$macChromePath Canary.app/$macChromeDir"
    fi
  fi

  # Move mock files into tmp dir for file download confirmation
  sudo cp "$testDir/mocks/mock-chromedriver.zip" "$tmpDir/chromedriver.zip"

  # Create fake files that are downloaded
  sudo touch "$tmpDir/google-chrome.dmg"
  sudo touch "$tmpDir/google-chrome-beta.dmg"
  sudo touch "$tmpDir/google-chrome-dev.dmg"
  sudo touch "$tmpDir/google-chrome-canary.dmg"
  sudo touch "$tmpDir/google-chrome.deb"
  sudo touch "$tmpDir/google-chrome-beta.deb"
  sudo touch "$tmpDir/google-chrome-dev.deb"
  sudo touch "$tmpDir/google-chrome.rpm"
  sudo touch "$tmpDir/google-chrome-beta.rpm"
  sudo touch "$tmpDir/google-chrome-dev.rpm"
}

oneTimeTearDown() {
  if [ "$cleanedUp" == false ]; then
    cleanedUp=true

    # Clear the contents of the mock-log-file
    > "$testDir/mocks/mock-log-file.txt"

    sudo rm -f "$tmpDir/chromedriver.zip"
    sudo rm -rf "$tmpDir/google-chrome"*

    if [ -f "$userDir/chromedriver" ]; then
      sudo mv "$userDir/chromedriver" "$chromedriverPath"
    else
      sudo rm -f "$chromedriverPath"
    fi

    if [ $os == 'Linux' ]; then
      if [ -f "$userDir/google-chrome" ]; then
        sudo mv "$userDir/google-chrome" "$linuxChromeStablePath"
      fi

      if [ -f "$userDir/google-chrome-beta" ]; then
        sudo mv "$userDir/google-chrome-beta" "$linuxChromeBetaPath"
      fi

      if [ -f "$userDir/google-chrome-dev" ]; then
        sudo mv "$userDir/google-chrome-dev" "$linuxChromeDevPath"
      fi
    elif [ $os == 'MacOs' ]; then
      if [ -f "$userDir/Google Chrome" ]; then
        sudo mv "$userDir/Google Chrome" "$macChromeStablePath"
      else
        sudo rm -rf "$macChromePath.app"
      fi

      if [ -f "$userDir/Google Chrome Beta" ]; then
        sudo mv "$userDir/Google Chrome Beta" "$macChromeBetaPath"
      else
        sudo rm -rf "$macChromePath Beta.app"
      fi

      if [ -f "$userDir/Google Chrome Dev" ]; then
        sudo mv "$userDir/Google Chrome Dev" "$macChromeDevPath"
      else
        sudo rm -rf "$macChromePath Dev.app"
      fi

      if [ -f "$userDir/Google Chrome Canary" ]; then
        sudo mv "$userDir/Google Chrome Canary" "$macChromeCanaryPath"
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

  sudo cp "$testDir/mocks/mock-chromedriver" "$chromedriverPath"

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

test_which_chromedriver_should_accept_beta_channel() {
  output=$($srcDir/index.sh which chromedriver=beta)
  assertEquals "$output" "$chromedriverPath"
}

test_which_chromedriver_should_accept_dev_channel() {
  output=$($srcDir/index.sh which chromedriver=dev)
  assertEquals "$output" "$chromedriverPath"
}

test_which_chromedriver_should_accept_canary_channel() {
  # Linux doesn't support canary channel
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$($srcDir/index.sh which chromedriver=canary)
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

  output=$($srcDir/index.sh version chrome=canary 2>/dev/null)
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
test_install_chromedriver_should_get_version_from_chrome() {
  # Modify the path to use mock commands instead of the
  # built in ones. That way we can control the responses
  #
  # Linux runs sudo commands with its own PATH variable, so in order
  # to add the mock path to the sudo PATH we need to use
  # "sudo env PATH="$PATH" <command>"
  # @see https://unix.stackexchange.com/questions/8646/why-are-path-variables-different-when-running-via-sudo-and-su
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 97"
}

test_install_chromedriver_should_accept_stable_channel_and_get_version_from_chrome() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=stable 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 97"
}

test_install_chromedriver_should_accept_beta_channel_and_get_version_from_chrome() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=beta 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 98"
}

test_install_chromedriver_should_accept_dev_channel_and_get_version_from_chrome() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=dev 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 99"
}

test_install_chromedriver_should_accept_canary_channel_and_get_version_from_chrome() {
  # Linux doesn't support canary channel
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=canary 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 100"
}

test_install_chromedriver_should_error_for_invalid_channel() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=invalid 2>&1)
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

  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Chrome version \"Not a Number\" is not a number"
}

test_install_chromedriver_should_error_if_chrome_is_not_installed() {
  if [ $os == "Linux" ]; then
    sudo rm -f "$linuxChromeStablePath"
  else
    sudo rm -f "$macChromeStablePath"
  fi

  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=stable 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Google Chrome is not installed"
}

test_install_chromedriver_should_output_chrome_version() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=stable 2>/dev/null)
  assertContains "$output" "Chrome Stable version detected as 97"
}

test_install_chromedriver_should_output_chromedriver_version_to_install() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 2>/dev/null)
  assertContains "$output" "Installing ChromeDriver 97"
}

test_install_chromedriver_should_get_lastest_release_using_version() {
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_97"
}

test_install_chromedriver_should_use_one_version_lower_and_try_again_if_version_is_not_found() {
  # version >100 is used in mock-http to return a bad request
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=101 2>/dev/null)
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$output" "ChromeDriver 101 not found. Retrying with ChromeDriver 100"
  assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_101"
  assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_100"
}

test_install_chromedriver_should_error_if_chromedriver_version_is_not_available() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=200 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Unable to get ChromeDriver version; Something went wrong"
}

test_install_chromedriver_should_exit_if_chromedriver_version_already_is_installed() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 2>/dev/null)
  exitCode=$?
  assertEquals "$exitCode" 0
  assertContains "$output" "ChromeDriver $chromedriverVersionString already installed"
}

test_install_chromedriver_should_download_zip_from_version() {
  sudo rm -f "$chromedriverPath"
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 2>/dev/null)
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")

  if [ $os == "Linux" ]; then
    assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/$chromedriverVersionString/chromedriver_linux64.zip"
  else
    assertContains "$mockLogs" "https://chromedriver.storage.googleapis.com/$chromedriverVersionString/chromedriver_mac64.zip"
  fi
}

test_install_chromedriver_should_unzip_download() {
  sudo rm -f "$chromedriverPath"
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "unzip $tmpDir/chromedriver.zip -d $tmpDir"
}

test_install_chromedriver_should_change_permissions_of_download() {
  sudo rm -f "$chromedriverPath"
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "chmod +x $tmpDir/chromedriver"
}

test_install_chromedriver_should_move_download() {
  sudo rm -f "$chromedriverPath"
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "mv $tmpDir/chromedriver /usr/local/bin"
}

test_install_chromedriver_should_cleanup_zip() {
  sudo rm -f "$chromedriverPath"
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "rm -f $tmpDir/chromedriver.zip"
}

test_install_chromedriver_should_verify_install_matches_version() {
  sudo rm -f "$chromedriverPath"
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 2>/dev/null)
  assertContains "$output" "Successfully installed ChromeDriver $chromedriverVersionString"
}

test_install_chromedriver_should_error_if_installed_version_does_not_match() {
  sudo rm -f "$chromedriverPath"
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=98 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Unable to install ChromeDriver; Something went wrong"
}

test_install_chromedriver_should_output_verbose_logs_with_flag() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chromedriver=97 --verbose)
  assertContains "$output" "Received response of $chromedriverVersionString"
}

#-------------------------------------------------
# Install Chrome
#-------------------------------------------------
test_install_chrome_should_default_to_stable() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome 2>/dev/null)
  assertContains "$output" "Installing Google Chrome Stable"
}

test_install_chrome_should_accept_stable_channel() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=stable 2>/dev/null)
  assertContains "$output" "Installing Google Chrome Stable"
}

test_install_chrome_should_accept_beta_channel() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=beta 2>/dev/null)
  assertContains "$output" "Installing Google Chrome Beta"
}

test_install_chrome_should_accept_dev_channel() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=dev 2>/dev/null)
  assertContains "$output" "Installing Google Chrome Dev"
}

test_install_chrome_should_accept_canary_channel() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=canary 2>/dev/null)
  assertContains "$output" "Installing Google Chrome Canary"
}

test_install_chrome_should_error_for_invalid_channel() {
  output=$(sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=invalid 2>&1)
  exitCode=$?
  assertEquals "$exitCode" 1
  assertContains "$output" "Chrome supported channels"
}

test_install_chrome_should_download_chrome_stable() {
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")

  if [ $os == "Linux" ]; then
    if command -v dpkg >/dev/null; then
      assertContains "$mockLogs" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    else
      assertContains "$mockLogs" "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm"
    fi
  else
    assertContains "$mockLogs" "https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
  fi
}

test_install_chrome_should_download_chrome_beta() {
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=beta >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")

  if [ $os == "Linux" ]; then
    if command -v dpkg >/dev/null; then
      assertContains "$mockLogs" "https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb"
    else
      assertContains "$mockLogs" "https://dl.google.com/linux/direct/google-chrome-beta_current_x86_64.rpm"
    fi
  else
    assertContains "$mockLogs" "https://dl.google.com/chrome/mac/universal/beta/googlechromebeta.dmg"
  fi
}

test_install_chrome_should_download_chrome_dev() {
  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=dev >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")

  if [ $os == "Linux" ]; then
    if command -v dpkg >/dev/null; then
      assertContains "$mockLogs" "https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb"
    else
      assertContains "$mockLogs" "https://dl.google.com/linux/direct/google-chrome-unstable_current_x86_64.rpm"
    fi
  else
    assertContains "$mockLogs" "https://dl.google.com/chrome/mac/universal/dev/googlechromedev.dmg"
  fi
}

test_install_chrome_should_download_chrome_canary() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=canary >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "https://dl.google.com/chrome/mac/universal/canary/googlechromecanary.dmg"
}

test_install_chrome_mac_stable_should_mount_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil attach -nobrowse -quiet -noverify $tmpDir/google-chrome.dmg"
}

test_install_chrome_mac_stable_should_copy_chrome_to_applications() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "cp -r /Volumes/Google Chrome/Google Chrome.app /Applications/Google Chrome.app"
}

test_install_chrome_mac_stable_should_detach_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil detach -quiet /Volumes/Google Chrome"
}

test_install_chrome_mac_stable_should_cleanup_dmg() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "rm -rf $tmpDir/google-chrome.dmg"
}

test_install_chrome_mac_beta_should_mount_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=beta >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil attach -nobrowse -quiet -noverify $tmpDir/google-chrome-beta.dmg"
}

test_install_chrome_mac_beta_should_copy_chrome_to_applications() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=beta >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "cp -r /Volumes/Google Chrome Beta/Google Chrome Beta.app /Applications/Google Chrome Beta.app"
}

test_install_chrome_mac_beta_should_detach_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=beta >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil detach -quiet /Volumes/Google Chrome Beta"
}

test_install_chrome_mac_beta_should_cleanup_dmg() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=beta >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "rm -rf $tmpDir/google-chrome-beta.dmg"
}

test_install_chrome_mac_dev_should_mount_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=dev >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil attach -nobrowse -quiet -noverify $tmpDir/google-chrome-dev.dmg"
}

test_install_chrome_mac_dev_should_copy_chrome_to_applications() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=dev >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "cp -r /Volumes/Google Chrome Dev/Google Chrome Dev.app /Applications/Google Chrome Dev.app"
}

test_install_chrome_mac_dev_should_detach_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=dev >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil detach -quiet /Volumes/Google Chrome Dev"
}

test_install_chrome_mac_dev_should_cleanup_dmg() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=dev >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "rm -rf $tmpDir/google-chrome-dev.dmg"
}

test_install_chrome_mac_canary_should_mount_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=canary >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil attach -nobrowse -quiet -noverify $tmpDir/google-chrome-canary.dmg"
}

test_install_chrome_mac_canary_should_copy_chrome_to_applications() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=canary >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "cp -r /Volumes/Google Chrome Canary/Google Chrome Canary.app /Applications/Google Chrome Canary.app"
}

test_install_chrome_mac_canary_should_detach_volume() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=canary >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "hdiutil detach -quiet /Volumes/Google Chrome Canary"
}

test_install_chrome_mac_canary_should_cleanup_dmg() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=canary >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "rm -rf $tmpDir/google-chrome-canary.dmg"
}

test_install_chrome_mac_should_not_output_verbose_logs() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$($srcDir/index.sh install chrome=beta)
  assertNotContains "$output" "Mounting Google Chrome Beta"
}

test_install_chrome_mac_should_output_verbose_logs_with_flag() {
  if [ $os == "Linux" ]; then
    startSkipping
  fi

  output=$($srcDir/index.sh install chrome=beta --verbose)
  assertContains "$output" "Mounting Google Chrome Beta"
}

test_install_chrome_linux_should_install_chrome_stable() {
  if [ $os == "MacOs" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "apt --yes --quiet install $tmpDir/google-chrome"
}

test_install_chrome_linux_should_install_chrome_beta() {
  if [ $os == "MacOs" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=beta >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "apt --yes --quiet install $tmpDir/google-chrome-beta"
}

test_install_chrome_linux_should_install_chrome_dev() {
  if [ $os == "MacOs" ]; then
    startSkipping
  fi

  sudo env PATH="$testDir/mocks:$PATH" $srcDir/index.sh install chrome=dev >/dev/null 2>/dev/null
  mockLogs=$(cat "$testDir/mocks/mock-log-file.txt")
  assertContains "$mockLogs" "apt --yes --quiet install $tmpDir/google-chrome-dev"
}

test_install_chrome_linux_should_not_output_verbose_logs() {
  if [ $os == "MacOs" ]; then
    startSkipping
  fi

  output=$($srcDir/index.sh install chrome=beta)
  assertNotContains "$output" "Using apt to install $tmpDir/google-chrome-beta"
}

test_install_chrome_linux_should_output_verbose_logs_with_flag() {
  if [ $os == "MacOs" ]; then
    startSkipping
  fi

  output=$($srcDir/index.sh install chrome=beta --verbose)
  assertContains "$output" "Using apt to install $tmpDir/google-chrome-beta"
}

# Load shUnit2
source "$testDir/shunit2/shunit2"