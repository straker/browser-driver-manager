#!/usr/bin/env node
const fsPromises = require('fs').promises;
const fs = require('fs');
const os = require('os');
const path = require('path');
const readline = require('readline');
const puppeteerBrowsers = require('@puppeteer/browsers');
const puppeteerInstall = puppeteerBrowsers.install;
const { resolveBuildId, detectBrowserPlatform, Browser } = puppeteerBrowsers;

const HOME_DIR = os.homedir();
const BDM_CACHE_DIR = path.resolve(HOME_DIR, '.browser-driver-manager');

const showDownloadProgress = (downloadedBytes, totalBytes) => {
  // closes over browser, options, and cursorEnabled
  if (!options.verbose) {
    return;
  }
  const browserTitle = browser[0].toUpperCase() + browser.slice(1);
  let progressMessage = `Downloading ${browserTitle}: `;
  if (downloadedBytes < totalBytes) {
    if (cursorEnabled) {
      const cursorDisablingString = '\x1B[?25l';
      progressMessage = `${cursorDisablingString}${progressMessage}`;
      cursorEnabled = false;
    }
    progressMessage += `${Math.ceil((downloadedBytes * 100) / totalBytes)}%`;
  } else {
    const cursorEnablingString = '\n\x1B[?25h';
    progressMessage += `Done!${cursorEnablingString}`;
    cursorEnabled = true;
  }
  readline.cursorTo(process.stdout, 0);
  process.stdout.write(progressMessage);
};

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
      const cursorEnablingString = '\n\x1B[?25h';
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

async function setEnv({ chromePath, chromedriverPath }) {
  console.log('Setting env CHROME/CHROMEDRIVER_TEST_PATH');

  try {
    await fsPromises.writeFile(
      path.resolve(BDM_CACHE_DIR, '.env'),
      `CHROME_TEST_PATH="${chromePath}"\nCHROMEDRIVER_TEST_PATH="${chromedriverPath}"`
    );
    console.log(
      'CHROME_TEST_PATH is set in',
      chromePath,
      '\nCHROMEDRIVER_TEST_PATH is set in',
      chromedriverPath
    );
  } catch (e) {
    console.error('Error setting CHROME/CHROMEDRIVER_TEST_PATH', e);
  }
}

function getEnv() {
  const envPath = path.resolve(BDM_CACHE_DIR, '.env');
  try {
    const env = fs.readFileSync(envPath, 'utf8');
    return env;
  } catch {
    return null;
  }
}

function which() {
  const env = getEnv();
  console.log(env);
  return;
}

function version() {
  const pattern = /-(\d+\.\d+\.\d+\.\d+)/;
  const filePath = getEnv();
  // Search for the pattern in the file path
  const match = filePath?.match(pattern);

  if (match) {
    const version = match[1];
    console.log('Version:', version);
  } else {
    console.log('Version not found in the file path.');
  }
  return;
}

async function install(browserId, options) {
  // When parsing the values the version value could be set
  // as a version number (e.g. 116.0.5845.96) or a channel (e.g. beta, dev, canary)
  const [browser, version = 'latest'] = browserId.split('@');

  // Create a cache directory if it does not exist on the user's home directory
  // This will be where environment variables will be stored for the tests
  // since it is a consistent location across different platforms
  if (!fs.existsSync(BDM_CACHE_DIR)) {
    await fsPromises.mkdir(BDM_CACHE_DIR, { recursive: true });
  }

  if (browser.includes('chrome')) {
    const platform = detectBrowserPlatform();

    if (!platform) {
      throw new Error('Unable to detect browser platform');
    }
    // This will sync the browser and chromedriver versions
    const chromeBuildId = await resolveBuildId(
      Browser.CHROME,
      platform,
      version
    );

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
      chromedriverPath: installedChromedriver.executablePath
    });
  }
}

module.exports = { install, version, which };
