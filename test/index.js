const sinon = require('sinon');
const proxyquire = require('proxyquire').noCallThru();
const expect = require('chai').expect;
const path = require('path');
const fs = require('fs').promises;
const os = require('os');

const originalProcessStdoutWrite = process.stdout.write;

const mockProcessStdoutWrite = sinon.stub();
const mockConsoleLog = sinon.stub(console, 'log');

const mockVersion = '126.0.6442.0';
const MOCK_HOME_DIR = './mock-user-home-dir';
const MOCK_BDM_CACHE_DIR = path.resolve(
  MOCK_HOME_DIR,
  '.browser-driver-manager'
);
const envPath = path.resolve(MOCK_BDM_CACHE_DIR, '.env');
const chromeTestPath = `${MOCK_BDM_CACHE_DIR}/chrome/os_arch-${mockVersion}/chrome`;
const chromedriverTestPath = `${MOCK_BDM_CACHE_DIR}/chromedriver/os_arch-${mockVersion}/chromedriver`;
const envContents = `CHROME_TEST_PATH="${chromeTestPath}"${os.EOL}CHROMEDRIVER_TEST_PATH="${chromedriverTestPath}"${os.EOL}VERSION="${mockVersion}"`;

const mockResolveBuildId = sinon.stub();
const mockDetectBrowserPlatform = sinon.stub();
const mockInstall = sinon.stub();
const mockBrowser = {
  CHROME: 'chrome',
  CHROMEDRIVER: 'chromedriver'
};
const puppeteerBrowserMocks = {
  detectBrowserPlatform: mockDetectBrowserPlatform,
  install: mockInstall,
  Browser: mockBrowser,
  resolveBuildId: mockResolveBuildId
};

let browser;

const { install, version, which } = proxyquire(
  '../src/browser-driver-manager',
  {
    '@puppeteer/browsers': puppeteerBrowserMocks,
    os: {
      homedir: sinon.stub().returns(MOCK_HOME_DIR)
    }
  }
);

beforeEach(async () => {
  browser = 'chrome';

  mockDetectBrowserPlatform.returns('mac');
  mockInstall.returns({ executablePath: chromeTestPath });
  mockResolveBuildId.returns(mockVersion);

  try {
    await fs.rm(MOCK_HOME_DIR, { recursive: true });
  } catch (e) {}
});

afterEach(() => {
  sinon.reset();
});

const makeEnvFile = async (contents = envContents) => {
  await fs.mkdir(MOCK_BDM_CACHE_DIR, { recursive: true });
  await fs.writeFile(envPath, contents);
};

describe('browser-driver-manager', () => {
  describe('which', () => {
    it('should log the locations of chrome and chromedriver if they exist', async () => {
      await makeEnvFile();
      await which();

      sinon.assert.calledWith(mockConsoleLog, envContents);
    });
    it('should error if no environment file exists', async () => {
      try {
        await which();
        throw new Error('should have thrown');
      } catch (e) {
        expect(e.message).to.contain(
          'No environment file exists. Please install first'
        );
      }
    });
  });
  describe('version', () => {
    it('should log the version when a valid one exists', async () => {
      await makeEnvFile();
      await version();

      sinon.assert.calledWith(mockConsoleLog, mockVersion);
    });
    it('should error if no environment file exists', async () => {
      try {
        await version();
        throw new Error('should have thrown');
      } catch (e) {
        expect(e.message).to.contain(
          'No environment file exists. Please install first'
        );
      }
    });
  });
  describe('install', () => {
    it('should error if an unsupported browser is given', async () => {
      try {
        await install('firefox');
        throw new Error('should have thrown');
      } catch (e) {
        expect(e.message).to.contain(
          'The selected browser, firefox, could not be installed. Currently, only "chrome" is supported.'
        );
      }
    });
    it("should create the cache directory if it doesn't already exist", async () => {
      await install(browser);
      expect(await fs.access(MOCK_BDM_CACHE_DIR)).not.to.throw;
    });

    it('should call detectBrowserPlatform', async () => {
      await install(browser);
      sinon.assert.called(mockDetectBrowserPlatform);
    });

    it("should throw if the platform couldn't be detected", async () => {
      mockDetectBrowserPlatform.returns(undefined);
      try {
        await install(browser);
        expect.fail();
      } catch (e) {
        expect(e.message).to.equal('Unable to detect browser platform');
      }
    });

    it('should call resolveBuildId with the correct arguments when no version is given', async () => {
      await install(browser);

      sinon.assert.calledWith(mockResolveBuildId, 'chrome', 'mac', 'latest');
    });

    it('should call resolveBuildId with the correct arguments when a version is given', async () => {
      browser = 'chrome@latest';
      await install(browser);

      sinon.assert.calledWith(mockResolveBuildId, 'chrome', 'mac', 'latest');
    });

    it('should call install with Chrome and the buildId', async () => {
      await install(browser);

      sinon.assert.calledWith(
        mockInstall,
        sinon.match({
          browser: 'chrome',
          buildId: mockVersion,
          downloadProgressCallback: sinon.match.func
        })
      );
    });

    it('should call install with Chromedriver and the buildId', async () => {
      await install(browser);

      sinon.assert.calledWith(
        mockInstall,
        sinon.match({
          browser: 'chromedriver',
          buildId: mockVersion,
          downloadProgressCallback: sinon.match.func
        })
      );
    });

    it('should write the environment variables to the file system', async () => {
      mockInstall
        .withArgs(
          sinon.match({
            cacheDir: sinon.match.string,
            browser: 'chrome',
            buildId: sinon.match.string
          })
        )
        .returns({ executablePath: chromeTestPath });

      mockInstall
        .withArgs(
          sinon.match({
            cacheDir: sinon.match.string,
            browser: 'chromedriver',
            buildId: sinon.match.string
          })
        )
        .returns({ executablePath: chromedriverTestPath });

      await install(browser);

      sinon.assert.calledWith(
        mockConsoleLog,
        'Setting env CHROME/CHROMEDRIVER_TEST_PATH/VERSION'
      );
      const env = await fs.readFile(envPath, 'utf-8');
      expect(env.match(chromeTestPath)).to.not.be.null;
      expect(env.match(chromedriverTestPath)).to.not.be.null;
    });

    it('should error if unable to write the file', async () => {
      sinon.stub(fs, 'writeFile').rejects('unable to write file');

      try {
        await install(browser);
        throw new Error('should have thrown');
      } catch (e) {
        expect(e.message).to.contain(
          'Error setting CHROME/CHROMEDRIVER_TEST_PATH/VERSION'
        );
      }
    });
    describe('does not show download progress when', () => {
      it('there are no options passed', () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback();
          return { executablePath: 'foo/bar' };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          }
        });
        install(browser);
        sinon.assert.notCalled(mockProcessStdoutWrite);
        // placing this in afterEach causes test logs to display incorrectly
        process.stdout.write = originalProcessStdoutWrite;
      });
      it('the verbose option is false', () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback();
          return { executablePath: 'foo/bar' };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          }
        });
        install(browser, { verbose: false });
        sinon.assert.notCalled(mockProcessStdoutWrite);
        process.stdout.write = originalProcessStdoutWrite;
      });
    });
    describe('when the the verbose option is true', () => {
      beforeEach(() => {
        process.stdout.write = mockProcessStdoutWrite;
      });
      it('writes the browser and download progress', async () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback(1, 100);
          return { executablePath: 'foo/bar' };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          }
        });
        await install(browser, { verbose: true });
        sinon.assert.calledWith(
          mockProcessStdoutWrite,
          sinon.match(/Downloading Chrome: 1%/)
        );
        process.stdout.write = originalProcessStdoutWrite;
      });
      it('writes when the download is done', async () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback(100, 100);
          return { executablePath: 'foo/bar' };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          }
        });
        await install(browser, { verbose: true });
        sinon.assert.calledWith(
          mockProcessStdoutWrite,
          sinon.match(/Downloading Chrome: Done!/)
        );
        process.stdout.write = originalProcessStdoutWrite;
      });
    });
  });
});
