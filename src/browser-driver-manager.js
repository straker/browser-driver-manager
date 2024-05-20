#!/usr/bin/env node
const fsPromises = require('fs').promises;
const os = require('os');
const path = require('path');
const readline = require('readline');
const puppeteerBrowsers = require('@puppeteer/browsers');
const puppeteerInstall = puppeteerBrowsers.install;
const { resolveBuildId, detectBrowserPlatform, Browser, uninstall } =
  puppeteerBrowsers;
const { capitalize } = require('./utils');

/**
 * Get the cache directory.
 * @returns {string} - Path to the cache directory.
 */
const getBDMCacheDir = () =>
  path.resolve(os.homedir(), '.browser-driver-manager');

/**
 * Install a single browser.
 * @param {string} cacheDir - The path to the root of the cache directory.
 * @param {string} browser - Which browser to install.
 * @param {string} buildId - Which build ID to download. Build IDs uniquely identify binaries.
 * @param {object} options - Options for customizing how the browser is installed.
 * @param {string} options.verbose - Show download progress information.
 * @throws {Error} - Puppeteer's `install` must succeed.
 * @returns {string} - The installed browser.
 */
async function installBrowser(cacheDir, browser, buildId, options) {
  const downloadProgressCallback = (downloadedBytes, totalBytes) => {
    // closes over `browser` and `options`
    if (!options?.verbose) {
      return;
    }
    const browserTitle = capitalize(browser);
    let progressMessage = `Downloading ${browserTitle}: `;
    if (downloadedBytes < totalBytes) {
      const cursorDisablingString = '\x1B[?25l';
      progressMessage = `${cursorDisablingString}${progressMessage}`;
      progressMessage += `${Math.ceil((downloadedBytes * 100) / totalBytes)}%`;
    } else {
      const cursorEnablingString = '\r\n\x1B[?25h';
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

/**
 * Write the environment file to the BDMCacheDir.
 * @param {object} data - The data to write.
 * @param {string} data.chromePath - The path to Chrome.
 * @param {string} data.chromedriverPath - The path to Chromedriver
 * @param {string} data.version - The version of Chrome and Chromedriver
 * @throws {Error} - Environment file must be writable.
 */
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

/**
 * Read the environment file from the BDMCacheDir.
 * @returns {string|undefined} - The content of the environment file.
 */
async function getEnv() {
  try {
    const envPath = path.resolve(getBDMCacheDir(), '.env');
    const env = await fsPromises.readFile(envPath, 'utf8');
    return env;
  } catch (e) {
    return;
  }
}

/**
 * Log the environment file to the console.
 * @throws {Error} - Environment file must exist.
 */
async function which() {
  const env = await getEnv();
  if (!env) {
    throw new Error('No environment file exists. Please install first');
  }
  console.log(env);
}

/**
 * Read the installed version from the environment file.
 * @returns {string|null} - The version if one exists.
 */
async function getVersion() {
  const pattern = /^VERSION="([\d.]+)"$/m;
  const env = await getEnv();

  // Search for the pattern in the file path
  const match = env?.match(pattern);

  const version = match?.[1];
  return version;
}

/**
 * Log the version to the console.
 * @throws {Error} - Version must exist.
 */
async function version() {
  const version = await getVersion();
  if (!version) {
    throw new Error('No installed version found. Please install first');
  }
  console.log(version);
}

/**
 * Install a version of Chrome and Chromedriver.
 * If already-installed Chrome and Chromedriver match this version, skip installation.
 * If already-installed Chrome and Chromedriver are a different version, overwrite them.
 * @param {string} browserId - Browser name (chrome), with an optional `@` and version number (e.g. 116.0.5845.96) or channel (e.g. beta, dev, canary)
 * @param {object} options - Pass-through to installBrowser
 * @throws {Error} Browser must be chrome
 * @throws {Error} Browser platform must be detectable
 * @throws {Error} Build ID must resolve
 * @throws {Error} Browser must be uninstallable when one is already installed
 * @throws {Error} Environment file must be removable when on already exists
 * @throws {Error} Version of chrome and chromedriver must be findable
 * @returns
 */
async function install(browserId, options) {
  const [browser, version = 'latest'] = browserId.split('@');

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

  // Get the version to install of both Chrome and Chromedriver
  let buildId;
  try {
    buildId = await resolveBuildId(Browser.CHROME, platform, version);
  } catch (e) {
    throw new Error(e);
  }

  // Get any currently installed version
  const currentVersion = getVersion();
  const cacheDir = getBDMCacheDir();
  if (currentVersion) {
    if (currentVersion === buildId) {
      console.log(
        `Chrome and Chromedriver versions ${currentVersion} are already installed. Skipping installation.`
      );
      return;
    }
    console.log(
      `Chrome and Chromedriver versions ${currentVersion} are currently installed. Overwriting.`
    );
    // Uninstall existing installs
    ['chrome', 'chromedriver'].map(async browser => {
      try {
        await uninstall({
          browser,
          buildId: currentVersion,
          cacheDir
        });
        fsPromises.rmdir(path, { recursive: true, force: true });
      } catch (e) {
        throw new Error(`Unable to remove ${browser}.`);
      }
    });
    try {
      // Remove the existing .env. setEnv creates it again later
      // Should execution stop beforehand, .env will not be in a bad (empty) state
      await fsPromises.rm(path.resolve(cacheDir, '.env'));
    } catch (e) {
      throw new Error(`Unable to remove .env from ${cacheDir}.`);
    }
  }

  // Create a cache directory if it does not exist on the user's home directory, or if it's been removed above
  // This will be where environment variables will be stored for the tests
  // since it is a consistent location across different platforms
  try {
    await fsPromises.mkdir(cacheDir, { recursive: true });
  } catch {
    console.log(`${cacheDir} already exists`);
  }

  let installedChrome, installedChromedriver;
  try {
    installedChrome = await installBrowser(
      cacheDir,
      Browser.CHROME,
      buildId,
      options
    );
  } catch (e) {
    e.message = /status code 404/.test(e.message)
      ? `Unable to find version ${buildId} of Chrome`
      : e.message;
    throw new Error(e);
  }

  try {
    installedChromedriver = await installBrowser(
      cacheDir,
      Browser.CHROMEDRIVER,
      buildId,
      options
    );
  } catch (e) {
    e.message = /status code 404/.test(e.message)
      ? `Unable to find version ${buildId} of Chromedriver`
      : e.message;
    throw new Error(e);
  }

  await setEnv({
    chromePath: installedChrome.executablePath,
    chromedriverPath: installedChromedriver.executablePath,
    version: buildId
  });
}

module.exports = { install, version, which };
