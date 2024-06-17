# browser-driver-manager
A cli for managing Chrome browsers and drivers. Especially useful to keep Chrome and ChromeDriver versions in-sync for continuous integration.

## Installation

```terminal
npm install browser-driver-manager
```

## Usage

```terminal
npx browser-driver-manager install chrome
```

Managing browsers and drivers for continuous integration, especially Chrome and ChromeDriver, can be extremely difficult, if not utterly frustrating.

Take for example the following real world scenario. 

You need Chrome and ChromeDriver installed on your continuous integration system in order to run your tests. Most continuous integration systems come pre-installed with Chrome and other browsers. This is great until you need to install ChromeDriver yourself (e.g. as [an npm package](https://www.npmjs.com/package/chromedriver)).

If you try to pin to a specific version, your test setup will eventually break because Chrome gets updated by the system whereas ChromeDriver remains pinned. This means that as soon as Chrome is out-of-sync with the ChromeDriver version, you end up with the infamous message:

```terminal
SessionNotCreatedException: Message: session not created: This version of ChromeDriver only supports Chrome version <version>`
```

So instead you decided to pin to the `@latest` tag. This works great as now both Chrome and ChromeDriver are the latest version. However, this also can break if the continuous integration system does not install the latest version right away but ChromeDriver releases the latest. Now your versions are out-of-sync again and you're back at square one.

This is why this package exists. It will help keep the versions of Chrome and ChromeDriver in-sync so that your continuous integration system tests don't fail due to ChromeDriver versions. 

So now instead of relying on pinning, you can install the desired version of Chrome and Chromedriver. This will even work for Chrome channels that are not just Stable (i.e. Beta, Dev, and Canary).

Here's an example of doing just that in an npm script.

```json
{
  "scripts": {
    "install:chrome": "browser-driver-manager install chrome"
  }
}
```

If you wanted to install Chrome Beta and its associated driver:

```json
{
  "scripts": {
    "install:chrome": "browser-driver-manager install chrome@beta"
  }
}
```

Once installed, a directory is created in your home directory called `.browser-driver-manager`. The directory will contain a `.env` file which will list the install path of both Chrome and Chromedriver under `CHROME_TEST_PATH` and `CHROMEDRIVER_TEST_PATH` respectively. 

```
# ~/.browser-driver-manager/.env
CHROME_TEST_PATH=".browser-driver-manager/chrome/mac_arm-125.0.6422.141/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
CHROMEDRIVER_TEST_PATH=".browser-driver-manager/chromedriver/mac_arm-125.0.6422.141/chromedriver-mac-arm64/chromedriver"
```

To use the Chrome or Chromedriver binaries, you'll have to read the contents of the file and grab the path to the desired path. For example, using [dotenv](https://www.npmjs.com/package/dotenv) you can do the following:

```js
require('dotenv').config({ path: '~/.browser-driver-manager/.env' })
```

## Migration from v1 to v2

V1 use to detect the version of Chrome installed on the system and install the corresponding version of the [chromedriver npm package](https://www.npmjs.com/package/chromedriver). However this had problems as the [chromedriver package wasn't always up-to-date with the latest version](https://github.com/straker/browser-driver-manager/issues/10) so when Chrome updated to the next version, the chromedriver package could lag behind and still cause out-of-sync issues. Additionally the chromedriver package didn't always have the latest versions of non-stable channels so asking for Chrome Canary wasn't always reliable.

V2 uses the newly released [Chrome for Testing](https://developer.chrome.com/blog/chrome-for-testing) to manage Chrome. This enables both installing specific versions of Chrome and fixes the previous chromedriver package issue. V2 utilizes the [`puppeteer/browser`](https://pptr.dev/browsers-api) script to manage the installation of Chrome and Chromedriver as it can handle downloading the binaries (and the multiple changes to the chromedriver download URL). This means that v2 no longer uses the chromedriver npm package to get chromedriver.

This means in v2 you'll need to grab the Chromedriver path from the home directory `.browser-driver-manager/.env` file and not from the chromedriver npm package. Additionally, if using a browser driver, such as Webdriver, you'll need to grab the Chrome path and pass it to the browser driver.

Here's an example of grabbing the Chromedriver path in v1 and the change for v2.

```js
// v1
const chromedriver = require('chromedriver');
console.log(chromedriver.path);

// v2
require('dotenv').config({ path: '`~/.browser-driver-manager/.env' })
console.log(process.env.CHROMEDRIVER_TEST_PATH);
```

## Supported Platforms and Browsers

MacOS, Linux, and Windows platforms, and Chrome browser and drivers are supported. Firefox support is planned. 

## System Requirements

Node is required to run the commands.

## Commands and Options

### Commands

- **install:** 
    Install the browser and driver. Can also pass the specific browser channel or version for each browser and driver. The latest Stable channel is used if no channel is passed.

    ```bash
    # Install latest Chrome Stable and matching Chromedriver version
    browser-driver-manager install chrome

    # Install latest Chrome Beta and matching Chromedriver
    browser-driver-manager install chrome@beta

    # Install ChromeDriver version 97 and matching Chromedriver
    browser-driver-manager install chrome@97

- **version:** 
    Get the installed version of the browser or driver.

    ```bash
    # Get installed Chrome and Chromedriver versions
    browser-driver-manager version chrome

- **which:** 
    Get the installed location of the browser and driver.

    ```bash
    # Get installed Chrome and Chromedriver locations
    browser-driver-manager which chrome
    ```

### Options

- **-h,--help:** Display the help information
- **--verbose:** Output verbose logs
- **-v,--version:** Display the version information
