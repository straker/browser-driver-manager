# browser-driver-manager
A cli for managing Chrome browsers and drivers. Especially useful to keep Chrome and ChromeDriver versions in-sync for continuous integration.

## Installation

```terminal
npm install browser-driver-manager
```

## Usage

```terminal
browser-driver-manager install chrome chromedriver
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

So now instead of relying on pinning, you can ask the system which version of Chrome is installed and always get the version of ChromeDriver that matches.

Here's an example of doing just that in an npm script.

```json
{
  "scripts": {
    "install:chromedriver": "browser-driver-manager install chromedriver"
  }
}
```

Here's an example of getting the installed Chrome version and installing the matching ChromeDriver version from npm.

```bash
#! /bin/bash

chromeVersion=$(browser-driver-manager version chrome)

# Extract the version number and major number
versionNumber="$(echo $chromeVersion | sed 's/^Google Chrome //' | sed 's/^Chromium //')"
majorVersion="${versionNumber%%.*}"

npm install --no-save "chromedriver@$majorVersion"
```

## Supported Platforms and Browsers

Currently only MacOS and Linux platforms, and Chrome browser and drivers are supported. Firefox support is planned. 

Currently there are no plans to support Windows. If you need Windows support please reach out, but understand that adding Windows support is a paid feature request.

## System Requirements

Using the `version` or `which` commands do not require any bash built in commands. The `install` command requires the following support:

- `curl` or `wget` to download files
- `dpkg` or `rpm` to extract browser applications
- `apt` or `yum` to install browsers
- `unzip` to install ChromeDriver

Additionally, `sudo` permissions are needed in order to install browsers and drivers.

## Commands and Options

### Commands

- **install:** 
    Install one or multiple browsers or drivers Can also pass the specific browser channel or driver version for each browser or driver. The latest Stable channel is used if no channel is passed. When installing ChromeDriver without passing a channel or version, the ChromeDriver version that matches the installed Stable version of Chrome is used.

    ```bash
    # Install latest Chrome Stable
    browser-driver-manager install chrome

    # Install ChromeDriver version that matches install Chrome Stable
    browser-driver-manager install chromedriver    

    # Install latest Chrome Beta
    browser-driver-manager install chrome=beta

    # Install ChromeDriver version 97
    browser-driver-manager install chromedriver=97

    # Install both Chrome and ChromeDriver Beta
    browser-driver-manager install chrome=beta chromedriver=beta
    ```

- **version:** 
    Get the installed version of the browser or driver. Can also pass the specific browser channel or driver version.

    ```bash
    # Get installed Chrome version
    browser-driver-manager version chrome

    # Get installed Chrome Beta version
    browser-driver-manager version chrome=beta

    # Get ChromeDriver version
    browser-driver-manager version chromedriver
    ```

- **which:** 
    Get the installed location of the browser or driver. Can also pass the specific browser channel or driver version.

    ```bash
    # Get installed Chrome location
    browser-driver-manager which chrome

    # Get installed Chrome Beta location
    browser-driver-manager which chrome=beta

    # Get ChromeDriver location
    browser-driver-manager which chromedriver
    ```

### Options

- **-h,--help:** Display the help information
- **-v,--version:** Display the version information
- **-verbose:** Output verbose logs