# browser-driver-manager
A cli for managing Chrome and Firefox browsers and drivers. Especially useful to keep Chrome and ChromeDriver versions in-sync.

## Installation

```terminal
npm install browser-driver-manager
```

## Usage

```terminal
browser-driver-manager --install chrome=beta,chromedriver=auto
```

## Supported Platforms and Browsers

Currently only MacOS and Linux platforms are supported, and Chrome and Firefox browsers and drivers.

## System Requirements

The system must support the following commands:

- `curl` or `wget` to download files
- `dpkg` or `rpm` to extract browser applications
- `apt` or `yum` to install browsers
- `unzip` to install ChromeDriver

Additionally, `sudo` permissions are needed in order to install browsers and drivers.

## Options

```terminal
browser-driver-manager --help
```

<!-- 

Get the currently installed version

```terminal
browser-driver-manager --installed-version chrome
```

Get the file path 

```terminal
browser-driver-manager --which chrome
```

Get the version to install

```terminal
browser-driver-manager --get-version chromedriver=auto
``` -->