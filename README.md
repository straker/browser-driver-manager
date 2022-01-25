# browser-driver-manager
A cli for managing Chrome and Firefox browsers and drivers. Especially useful to keep Chrome and ChromeDriver versions in-sync.

## Installation

```terminal
npm install browser-driver-manager
```

## Usage

```terminal
browser-driver-manager install chrome=beta chromedriver
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

- **install:** Install browsers or drivers
- **which:** Get the installed version of the browser or driver
- **version:** Get the installed location of the browser or driver

### Options

- **-h,--help:** Display the help information
- **-v,--version:** Display the version information
- **-verbose:** Output verbose logs