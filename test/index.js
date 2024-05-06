const sinon = require('sinon');
const proxyquire = require('proxyquire').noCallThru();
const expect = require('chai').expect;
const path = require('path');
const fs = require('fs');

const originalProcessStdoutWrite = process.stdout.write;
const originalConsoleLog = console.log;
const originalConsoleError = console.error;

const mockProcessStdoutWrite = sinon.stub();
const mockConsoleLog = sinon.stub();
const mockConsoleError = sinon.stub();

const mockBuildId = '90810624976';
const mockVersion = '126.0.6442.0';
const MOCK_HOME_DIR = './mock-user-home-dir';
const MOCK_BDM_CACHE_DIR = path.resolve(
  MOCK_HOME_DIR,
  '.browser-driver-manager'
);
const envPath = path.resolve(MOCK_BDM_CACHE_DIR, '.env');
const chromeTestPath = `${MOCK_BDM_CACHE_DIR}/chrome/os_arch-${mockVersion}/chrome`;
const chromedriverTestPath = `${MOCK_BDM_CACHE_DIR}/chromedriver/os_arch-${mockVersion}/chromedriver`;
const envContents = `CHROME_TEST_PATH="${chromeTestPath}"\nCHROMEDRIVER_TEST_PATH="${chromedriverTestPath}"`;

const mockResolveBuildId = sinon.stub().returns(mockBuildId);
const mockDetectBrowserPlatform = sinon.stub().returns('mac');
const mockInstall = sinon.stub().returns({ executablePath: 'foo/bar' });
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

beforeEach(() => {
  console.log = mockConsoleLog;
  console.error = mockConsoleError;

  mockDetectBrowserPlatform.returns('mac');

  browser = 'chrome';
});

afterEach(() => {
  console.log = originalConsoleLog;
  console.error = originalConsoleError;

  mockConsoleLog.resetHistory();
  mockConsoleError.resetHistory();
  mockProcessStdoutWrite.resetHistory();

  mockResolveBuildId.resetHistory();
  mockDetectBrowserPlatform.resetHistory();
  mockInstall.resetHistory();

  if (fs.existsSync(MOCK_HOME_DIR)) {
    fs.rmSync(MOCK_HOME_DIR, { recursive: true });
  }
});

const makeEnvFile = (contents = envContents) => {
  fs.mkdirSync(MOCK_BDM_CACHE_DIR, { recursive: true });
  fs.writeFileSync(envPath, contents);
};

describe('browser-driver-manager', () => {
  describe('which', () => {
    it('should log the locations of chrome and chromedriver if they exist', () => {
      makeEnvFile();
      which();

      sinon.assert.calledWith(mockConsoleLog, envContents);
    });
    it("shouldn't log if no environment path dir exists", () => {
      which();

      sinon.assert.calledWith(mockConsoleLog, null);
    });
  });
  describe('version', () => {
    it('should log the version when a valid one exists', () => {
      makeEnvFile();
      version();

      sinon.assert.calledWith(mockConsoleLog, 'Version:', mockVersion);
    });
    it("should error when the path doesn't exist", () => {
      const notFoundMessage = 'Version not found in the file path.';
      version();

      sinon.assert.calledWith(mockConsoleLog, notFoundMessage);
    });
    it('should error when version is not found', () => {
      const notFoundMessage = 'Version not found in the file path.';
      makeEnvFile('bad env file format');
      version();

      sinon.assert.calledWith(mockConsoleLog, notFoundMessage);
    });
  });
  describe('install', () => {
    it("should create the cache directory if it doesn't already exist", async () => {
      expect(fs.existsSync(MOCK_BDM_CACHE_DIR)).to.be.false;
      await install(browser);
      expect(fs.existsSync(MOCK_BDM_CACHE_DIR)).to.be.true;
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
          buildId: mockBuildId,
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
          buildId: mockBuildId,
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
        'Setting env CHROME/CHROMEDRIVER_TEST_PATH'
      );

      expect(fs.readFileSync(envPath, 'utf-8').match(chromeTestPath)).to.not.be
        .null;
      expect(fs.readFileSync(envPath, 'utf-8').match(chromedriverTestPath)).to
        .not.be.null;
    });

    it('should log an error if unable to write the file', async () => {
      sinon.stub(fs.promises, 'writeFile').rejects('unable to write file');

      await install(browser);

      sinon.assert.calledWith(
        mockConsoleError,
        'Error setting CHROME/CHROMEDRIVER_TEST_PATH'
      );
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
