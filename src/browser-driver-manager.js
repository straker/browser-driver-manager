#!/usr/bin/env node
const fs = require('fs').promises;
const os = require('os');
const path = require('path');
const readline = require('readline');
const puppeteerBrowsers = require('@puppeteer/browsers');
const puppeteerInstall = puppeteerBrowsers.install;
const { resolveBuildId, detectBrowserPlatform, Browser } = puppeteerBrowsers;

const HOME_DIR = os.homedir();
const BDM_CACHE_DIR = path.resolve(HOME_DIR, '.browser-driver-manager');

async function installBrowser(cacheDir, browser, version, options) {
  const platform = detectBrowserPlatform();
  const buildId = await resolveBuildId(browser, platform, version);

  const downloadProgressCallback = (downloadedBytes, totalBytes) => {
    // closes over browser and options
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
      progressMessage += `Done!${cursorEnablingString}`;
      cursorEnabled = true;
    }
    readline.cursorTo(process.stdout, 0);
    process.stdout.write(progressMessage);
  };

  const installedBrowser = await puppeteerInstall({
    cacheDir,
    browser,
    buildId,
    downloadProgressCallback
  });

  return installedBrowser;
}

async function setEnv({ chromePath, chromedriverPath, version }) {
  console.log('Setting env CHROME/CHROMEDRIVER_TEST_PATH/VERSION');

  try {
    await fs.writeFile(
      path.resolve(BDM_CACHE_DIR, '.env'),
      `CHROME_TEST_PATH="${chromePath}"${os.EOL}CHROMEDRIVER_TEST_PATH="${chromedriverPath}"${os.EOL}VERSION="${version}"${os.EOL}`
    );
    console.log('CHROME_TEST_PATH is set in', chromePath);
    console.log('CHROMEDRIVER_TEST_PATH is set in', chromedriverPath);
    console.log('VERSION:', version);
  } catch (e) {
    console.error('Error setting CHROME/CHROMEDRIVER_TEST_PATH/VERSION', e);
  }
}

async function getEnv() {
  const envPath = path.resolve(BDM_CACHE_DIR, '.env');
  try {
    const env = await fs.readFile(envPath, 'utf8');
    return env;
  } catch (e) {
    throw new Error('No environment file exists. Please install first');
  }
}

async function which() {
  const env = await getEnv();
  console.log(env);
}

async function version() {
  const pattern = /^VERSION="([\d.]+)"$/m;
  const env = await getEnv();
  // Search for the pattern in the file path
  const match = env.match(pattern);

  const version = match[1];
  console.log('Version:', version);
}

async function install(browserId, options) {
  // When parsing the values the version value could be set
  // as a version number (e.g. 116.0.5845.96) or a channel (e.g. beta, dev, canary)
  const [browser, version = 'latest'] = browserId.split('@');

  // Create a cache directory if it does not exist on the user's home directory
  // This will be where environment variables will be stored for the tests
  // since it is a consistent location across different platforms
  try {
    await fs.mkdir(BDM_CACHE_DIR, { recursive: true });
  } catch {
    console.log(`${BDM_CACHE_DIR} already exists`);
  }

  // Should support for other browsers be added, commander should handle this check.
  // With only one supported browser, this error message is more meaningful than commander's.
  if (!browser.includes('chrome')) {
    console.error(
      `The browser ${browser} is not supported. Currently, only "chrome" is supported.`
    );
    return;
  }

  const platform = detectBrowserPlatform();

  if (!platform) {
    throw new Error('Unable to detect browser platform');
  }
  // This will sync the browser and chromedriver versions
  const chromeBuildId = await resolveBuildId(Browser.CHROME, platform, version);

  const installedChrome = await installBrowser(
    BDM_CACHE_DIR,
    Browser.CHROME,
    chromeBuildId,
    options
  );

  const installedChromedriver = await installBrowser(
    BDM_CACHE_DIR,
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

module.exports = { install, version, which };
