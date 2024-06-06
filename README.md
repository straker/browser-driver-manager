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

So now instead of relying on pinning, you can ask the system which version of Chrome is installed and always get the version of ChromeDriver that matches. This will even work for Chrome channels that are not just Stable (i.e. Beta, Dev, and Canary).

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
    "install:chromedriver": "browser-driver-manager install chrome@beta"
  }
}
```

## Supported Platforms and Browsers

MacOS, Linux, and Windows platforms, and Chrome browser and drivers are supported. Firefox support is planned. 

## System Requirements

Node is required to run commands.

Install dependencies with

`npm install`

## Commands and Options

### Commands

- **install:** 
    Install the browser and driver. Can also pass the specific browser channel or version for each browser and driver. The latest Stable channel is used if no channel is passed.

    ```bash
    # Install latest Chrome Stable and matching Chromedriver version
    browser-driver-manager install chrome

    # Install latest Chrome Beta and matching Chromedriver
    browser-driver-manager install chrome@beta

- **version:** 
    Get the installed version of the browser or driver.

    ```bash
    # Get installed Chrome and Chromedriver versions
    browser-driver-manager version

- **which:** 
    Get the installed location of the browser and driver.

    ```bash
    # Get installed Chrome and Chromedriver locations
    browser-driver-manager which
    ```

### Options

- **-h,--help:** Display the help information
- **--verbose:** Output verbose logs
- **-v,--version:** Display the version information