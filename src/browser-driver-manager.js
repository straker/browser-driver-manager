#!/usr/bin/env node
const fsPromises = require('fs').promises;
const os = require('os');
const path = require('path');
const readline = require('readline');
const puppeteerBrowsers = require('@puppeteer/browsers');
const puppeteerInstall = puppeteerBrowsers.install;
const { resolveBuildId, detectBrowserPlatform, Browser } = puppeteerBrowsers;

const getBDMCacheDir = () =>
  path.resolve(os.homedir(), '.browser-driver-manager');

async function installBrowser(cacheDir, browser, buildId, options) {
  const downloadProgressCallback = (downloadedBytes, totalBytes) => {
    // closes over `browser` and `options`
    if (!options?.verbose) {
      return;
    }
    const browserTitle = browser[0].toUpperCase() + browser.slice(1);
    let progressMessage = `Downloading ${browserTitle}: `;
    if (downloadedBytes < totalBytes) {
      const cursorDisablingString = '\x1B[?25l';
      progressMessage = `${cursorDisablingString}${progressMessage}`;
      cursorEnabled = false;
      progressMessage += `${Math.ceil((downloadedBytes * 100) / totalBytes)}%`;
    } else {
      const cursorEnablingString = '\r\n\x1B[?25h';
      cursorEnabled = true;
      progressMessage += `Done!${cursorEnablingString}`;
    }
    readline.cursorTo(process.stdout, 0);
    process.stdout.write(progressMessage);
  };

  try {
    const installedBrowser = await puppeteerInstall({
      cacheDir,
      browser,
      buildId,
      downloadProgressCallback
    });

    return installedBrowser;
  } catch (e) {
    throw new Error(e);
  }
}

async function setEnv({ chromePath, chromedriverPath, version }) {
  console.log('Setting env CHROME/CHROMEDRIVER_TEST_PATH/VERSION');

  try {
    await fsPromises.writeFile(
      path.resolve(getBDMCacheDir(), '.env'),
      `CHROME_TEST_PATH="${chromePath}"${os.EOL}CHROMEDRIVER_TEST_PATH="${chromedriverPath}"${os.EOL}VERSION="${version}"${os.EOL}`
    );
    console.log('CHROME_TEST_PATH is set in', chromePath);
    console.log('CHROMEDRIVER_TEST_PATH is set in', chromedriverPath);
    console.log('VERSION:', version);
  } catch (e) {
    throw new Error('Error setting CHROME/CHROMEDRIVER_TEST_PATH/VERSION');
  }
}

async function getEnv() {
  try {
    const envPath = path.resolve(getBDMCacheDir(), '.env');
    const env = await fsPromises.readFile(envPath, 'utf8');
    return env;
  } catch (e) {
    return;
  }
}

async function which() {
  const env = await getEnv();
  if (!env) {
    throw new Error('No environment file exists. Please install first');
  }
  console.log(env);
}

async function getVersion() {
  const pattern = /^VERSION="([\d.]+)"$/m;
  const env = await getEnv();

  // Search for the pattern in the file path
  const match = env?.match(pattern);

  const version = match?.[1];
  return version;
}

async function version() {
  const version = await getVersion();
  if (!version) {
    throw new Error('No installed version found. Please install first');
  }
  console.log(version);
}

async function install(browserId, options) {
  // When parsing the values the version value could be set
  // as a version number (e.g. 116.0.5845.96) or a channel (e.g. beta, dev, canary)
  const [browser, version = 'latest'] = browserId.split('@');

  // Create a cache directory if it does not exist on the user's home directory
  // This will be where environment variables will be stored for the tests
  // since it is a consistent location across different platforms
  const BDMCacheDir = getBDMCacheDir();
  try {
    await fsPromises.mkdir(BDMCacheDir, { recursive: true });
  } catch {
    console.log(`${BDMCacheDir} already exists`);
  }

  // Should support for other browsers be added, commander should handle this check.
  // With only one supported browser, this error message is more meaningful than commander's.
  if (!browser.includes('chrome')) {
    throw new Error(
      `The selected browser, ${browser}, could not be installed. Currently, only "chrome" is supported.`
    );
  }

  const platform = detectBrowserPlatform();

  if (!platform) {
    throw new Error('Unable to detect browser platform');
  }
  // This will sync the browser and chromedriver versions
  let chromeBuildId;
  try {
    chromeBuildId = await resolveBuildId(Browser.CHROME, platform, version);
  } catch (e) {
    throw new Error(e);
  }

  const currentVersion = await getVersion();
  if (currentVersion) {
    if (currentVersion === chromeBuildId) {
      console.log(
        `Chrome and Chromedriver versions ${currentVersion} are already installed. Skipping installation.`
      );
      return;
    }
    console.log(
      `Chrome and Chromedriver versions ${currentVersion} are currently installed. Overwriting.`
    );
  }

  const installedChrome = await installBrowser(
    BDMCacheDir,
    Browser.CHROME,
    chromeBuildId,
    options
  );

  const installedChromedriver = await installBrowser(
    BDMCacheDir,
    Browser.CHROMEDRIVER,
    chromeBuildId,
    options
  );

  await setEnv({
    chromePath: installedChrome.executablePath,
    chromedriverPath: installedChromedriver.executablePath,
    version: chromeBuildId
  });
}

const capitalize = word =>
  word.split('')[0].toUpperCase() + word.split('').slice(1).join('');

module.exports = { install, version, which };
