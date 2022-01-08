const process = require('process');

function getPlatform() {
  const os = process.platform;

  if (os === 'win32') {
    const arch = process.arch;
    if (arch === 'x32') {
      return 'win32';
    }

    return 'win64';
  }

  if (os === 'darwin') {
    return 'macos';
  }

  if (os === 'android') {
    return 'android';
  }

  return 'linux';
}

module.exports = {
  getPlatform
};

