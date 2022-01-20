testDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
rootDir="$(cd "${testDir}/.." && pwd)"
BDM_SRC_DIR="$rootDir/src"
tmpDir="$rootDir/tmp"

chromedriverPath="/usr/local/bin/chromedriver"

# Save original chromedriver so we can restore it at the end of the test
oneTimeSetUp() {
  if command -v $chromedriver >/dev/null; then
    sudo mv "$chromedriverPath" "$tmpDir/chromedriver"
  fi
}

oneTimeTearDown() {
  if [ -f "$tmpDir/chromedriver" ]; then
    sudo mv "$tmpDir/chromedriver" "$chromedriverPath"
  fi
}

# Install mock chromedriver before each tests
# It is expected that the system already has Chrome installed
setUp() {
  sudo cp "$testDir/assets/mock-chromedriver97" "$chromedriverPath"
}

# Which Chromedriver
test_which_chromedriver_should_ouput_dir() {
  output=$($BDM_SRC_DIR/index.sh which chromedriver)
  assertEquals $output $chromedriverPath
}

test_which_chromedriver_should_error_if_not_installed() {
  sudo rm -f "$chromedriverPath"
  output=$($BDM_SRC_DIR/index.sh which chromedriver 2>&1)
  assertContains "$output" "chromedriver is not installed"
}

test_which_chromedriver_should_accept_stable_channel() {
  output=$($BDM_SRC_DIR/index.sh which chromedriver=stable)
  assertEquals $output $chromedriverPath
}

test_which_chromedriver_should_error_for_invalid_channel() {
  output=$($BDM_SRC_DIR/index.sh which chromedriver=invalid 2>&1)
  assertContains "$output" "Chrome supported channels"
}

# Which Chrome

# Load shUnit2
source "$testDir/shunit2/shunit2"