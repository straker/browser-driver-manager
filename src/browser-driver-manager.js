#!/usr/bin/env node
const fsPromises = require('fs').promises;
const fs = require('fs');
const os = require('os');
const path = require('path');
const readline = require('readline');
const {
  install,
  resolveBuildId,
  detectBrowserPlatform,
  Browser
} = require('@puppeteer/browsers');
const { Command } = require('commander');

const HOME_DIR = os.homedir();
const BDM_CACHE_DIR = path.resolve(HOME_DIR, '.browser-driver-manager');

const program = new Command();

program.command('which').action(which);
program.command('version').action(version);

program.option('--verbose');

program.parse();

const options = program.opts();

async function installBrowser(cacheDir, browser, version) {
  let cursorEnabled = true;

  const downloadProgressCallback = (downloadedBytes, totalBytes) => {
    if (!options.verbose) {
      return;
    }
    let progressMessage = `Downloading ${browser[0].toUpperCase()}${browser.slice(
      1
    )}: `;
    if (downloadedBytes < totalBytes) {
      if (cursorEnabled) {
        // \x1B[?25l disables the cursor
        progressMessage = `\x1B[?25l${progressMessage}`;
        cursorEnabled = false;
      }
      progressMessage += `${Math.ceil((downloadedBytes * 100) / totalBytes)}%`;
    } else {
      // \x1B[?25h enables the cursor
      progressMessage += `Done!\n\x1B[?25h`;
      cursorEnabled = true;
    }
    readline.cursorTo(process.stdout, 0);
    process.stdout.write(progressMessage);
  };
  const platform = detectBrowserPlatform();
  const buildId = await resolveBuildId(browser, platform, version);
  const installedBrowser = await install({
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
      'CHROME_TEST_PATH is set in ',
      chromePath,
      '\nCHROMEDRIVER_TEST_PATH is set in ',
      chromedriverPath
    );
  } catch (e) {
    console.error('Error setting CHROME/CHROMEDRIVER_TEST_PATH', e);
  }
}

function getEnv() {
  const envPath = path.resolve(BDM_CACHE_DIR, '.env');
  if (!fs.existsSync(envPath)) {
    return null;
  }
  const env = fs.readFileSync(envPath, 'utf8');
  return env;
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

async function browserDriverManager(args) {
  if (!args[0]) {
    throw new Error(
      'Please specify browser and version in browser@version format'
    );
  }

  // When parsing the values the version value could be set
  // as a version number (e.g. 116.0.5845.96) or a channel (e.g. beta, dev, canary)
  const [browser, version = 'latest'] = args[0].split('@');

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

    const installChrome = await installBrowser(
      BDM_CACHE_DIR,
      Browser.CHROME,
      chromeBuildId
    );

    const installChromedriver = await installBrowser(
      BDM_CACHE_DIR,
      Browser.CHROMEDRIVER,
      chromeBuildId
    );

    await setEnv({
      chromePath: installChrome.executablePath,
      chromedriverPath: installChromedriver.executablePath
    });
  }
}

module.exports = browserDriverManager;
