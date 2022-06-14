const spawn = require('child_process').spawn;
const path = require('path');

const isNumberRegex = /\d/;
const chromedriverVersionRegex = /(\d+)/;
const chromeRegex = /^chrome$|^chrome=/;
const chromedriverRegex = /^chromedriver$|^chromedriver=/;

/**
 * Node wrapper around the bash script (export for testing);
 */
async function browserDriverManager(userArgs) {
  // dynamic import es6 npm packages
  const fetch = (await import('node-fetch')).default;
  const chalk = (await import('chalk')).default;

  const verbose = userArgs.includes('--verbose');

  const chrome = userArgs.find(arg => chromeRegex.test(arg));
  const chromedriver = userArgs.find(arg => chromedriverRegex.test(arg));

  // install npm chromedriver instead of regular bash script install
  if (userArgs[0] == 'install') {
    if (chrome) {
      const scriptArgs = ['install', chrome];
      if (verbose) {
        scriptArgs.push('--verbose');
      }

      try {
        await runBashScript({
          sudo: true,
          args: scriptArgs
        });
      } catch (err) {
        return;
      }
    }

    if (chromedriver) {
      let version = chromedriver.split('=')[1] || 'stable';

      if (['stable', 'beta', 'dev', 'canary'].includes(version)) {
        const channel = version;
        const scriptArgs = ['version', `chrome=${channel}`];
        if (verbose) {
          scriptArgs.push('--verbose');
        }

        let versionNumber;
        try {
          versionNumber = (
            await runBashScript({
              returnValue: true,
              args: scriptArgs
            })
          ).trim();
        } catch (err) {
          return;
        }

        version = chromedriverVersionRegex.exec(versionNumber)[1];

        console.log(
          `Chrome ${titleCase(channel)} version detected as ${versionNumber}`
        );
      } else if (!isNumberRegex.test(version)) {
        return error(chalk, `Chrome version "${version}" is not a number`);
      }

      version = parseInt(version, 10);
      console.log(`Installing ChromeDriver ${version}`);

      const response = await fetch('https://registry.npmjs.org/chromedriver');
      const data = await response.json();
      const chromedriverVersion = parseInt(
        chromedriverVersionRegex.exec(data['dist-tags'].latest)[1]
      );

      verboseLog(
        chalk,
        verbose,
        `Received response of ${data['dist-tags'].latest}`
      );

      if (version <= chromedriverVersion) {
        await installChromeDriver(version, verbose);
        console.log(`Successfully installed ChromeDriver ${version}`);

        return;
      } else {
        console.log(
          `ChromeDriver ${version} not found. Retrying with ChromeDriver ${
            version - 1
          }`
        );

        if (version - 1 <= chromedriverVersion) {
          try {
            await installChromeDriver(version - 1, verbose);
            console.log(`Successfully installed ChromeDriver ${version - 1}`);
          } catch (error) {
            console.log('Failed to install ChromeDriver');
            console.log('Please check error at: https://stackoverflow.com/search?q=[js]+', error.message.replace(' ', '+'));
            process.exit = 1
          }
          return;
        } else {
          return error(
            chalk,
            'Unable to get ChromeDriver version; Something went wrong'
          );
        }
      }
    }

    return;
  }
  // output version installed from npm
  else if (['version', 'which'].includes(userArgs[0]) && chromedriver) {
    try {
      const chromedriverPkg = require('chromedriver');

      if (userArgs[0] === 'version') {
        console.log(chromedriverPkg.version);
      } else {
        console.log(chromedriverPkg.path);
      }

      return;
    } catch (err) {
      return error(chalk, 'chromedriver is not installed');
    }
  }

  try {
    await runBashScript({
      args: userArgs
    });
  } catch (err) {
    return;
  }
}

/**
 * Output an error message
 * @param {Object} chalk
 * @param {String} msg - Message to display
 */
async function error(chalk, msg) {
  console.error(chalk.red('browser-driver-manager error:'), msg);
  process.exitCode = 1;
}

/**
 * Output a message for verbose logging
 * @param {Object} chalk
 * @param {Boolean} verbose - If verbose logging is enabled
 * @param {String} msg - Message to display
 */
async function verboseLog(chalk, verbose, msg) {
  if (verbose) {
    console.log(chalk.blue('log:'), msg);
  }
}

/**
 * Uppercase first character of a string
 * @param {String} str - String to Titlecase
 */
function titleCase(str) {
  return str.charAt(0).toUpperCase() + str.substr(1);
}

/**
 * Run the main bash script
 * @param {Object} options
 * @param {Boolean} [options.returnValue] - Return the bash script output rather than display it
 * @param {Boolean} [options.sudo] - Run the command as sudo
 * @param {String[]} options.args - List of script arguments
 * @returns {Promise<String|null>}
 */
function runBashScript({ returnValue = false, sudo = false, args } = {}) {
  return new Promise((resolve, reject) => {
    const lines = [];
    let lastChunk;

    const scriptPath = path.join(__dirname, 'index.sh');
    let child;
    if (sudo) {
      child = spawn('sudo', [scriptPath, ...args]);
    } else {
      child = spawn(scriptPath, args);
    }

    child.stdout.on('data', chunk => {
      lines.push(chunk);

      if (!returnValue) {
        process.stdout.write(chunk);
      }
    });

    // for some reason the install script will output curl download
    // percent through stderr
    child.stderr.on('data', chunk => {
      // mimic download percent bar by manually clearing lines
      // @see https://stackoverflow.com/questions/17309749/node-js-console-log-is-it-possible-to-update-a-line-rather-than-create-a-new-l
      if (chunk.indexOf('\r') !== -1) {
        process.stdout.clearLine();
      }
      if (lastChunk) {
        process.stdout.cursorTo(lastChunk.length - 1);
      }
      process.stdout.write(chunk);

      lastChunk = chunk;

      if (chunk.toString().indexOf('browser-driver-manager error') !== -1) {
        process.exitCode = 1;
        reject();
      }
    });
    child.on('close', () => {
      if (returnValue) {
        // output all logs except the last one
        for (let i = 0; i < lines.length - 1; i++) {
          process.stdout.write(lines[i]);
        }
        resolve(lines[lines.length - 1].toString());
      } else {
        resolve();
      }
    });
  });
}

/**
 * Install ChromeDriver from npm
 * @param {String} version - Version to install
 * @param {Boolean} verbose - If verbose logging is enabled
 */
function installChromeDriver(version, verbose) {
  return new Promise(resolve => {
    const child = spawn('npm', [
      'install',
      '--no-save',
      `chromedriver@${version}`
    ]);
    if (verbose) {
      child.stdout.on('data', chunk => {
        process.stdout.write(chunk);
      });
    }
    child.stderr.on('data', chunk => {
      process.stderr.write(chunk);
    });
    child.on('close', () => {
      resolve();
    });
  });
}

module.exports = browserDriverManager;
