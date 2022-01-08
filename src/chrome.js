// Install Chrome Channels and Chromedriver
const { getPlatform } = require('./utils');

const channel = 'stable';

// @see https://www.chromium.org/getting-involved/dev-channel/
const supportedChannels = {
  win32: ['stable', 'beta', 'dev', 'canary'],
  win64: ['stable', 'beta', 'dev', 'canary'],
  macos: ['stable', 'beta', 'dev', 'canary'],
  linux: ['stable', 'beta', 'dev']
};
const URLs = {
  macos: {
    stable: 'https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg'
    beta: 'https://dl.google.com/chrome/mac/universal/beta/googlechromebeta.dmg',
    dev: 'https://dl.google.com/chrome/mac/universal/dev/googlechromedev.dmg',
    canary: 'https://dl.google.com/chrome/mac/universal/canary/googlechromecanary.dmg'
  },
  linux: {
    deb: {
      stable: 'https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb',
      beta: 'https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb',
      dev: 'https://dl.google.com/linux/direct/google-chrome-unstable_current_amd64.deb'
    },
    rpm {
      stable: 'https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm',
      beta: 'https://dl.google.com/linux/direct/google-chrome-beta_current_x86_64.rpm',
      dev: 'https://dl.google.com/linux/direct/google-chrome-unstable_current_x86_64.rpm'
    }
  }
};

const platform = getPlatform();

if (!supportedChannels[platform].includes(channel)) {
  throw new Error(`${platform} does not support the ${channel} channel`);
}

if (platform === 'linux') {
  // wget https://dl.google.com/linux/direct/google-chrome-beta_current_amd64.deb
  // sudo apt install ./google-chrome-beta_current_amd64.deb
}
else if (['win32', 'win64'].includes(platform)) {

}
else if (platform === 'macos') {

}
else {
  throw new Error('Platform not supported');
}