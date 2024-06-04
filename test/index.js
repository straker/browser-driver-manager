const sinon = require('sinon');
const proxyquire = require('proxyquire').noCallThru();
const path = require('path');
const fsPromises = require('fs').promises;
const os = require('os');
const chai = require('chai');
const { capitalize } = require('../src/utils');
const chaiAsPromised = require('chai-as-promised');
const expect = chai.expect;
chai.use(chaiAsPromised);

const mockVersion = '126.0.6442.0';
const mockOverwriteVersion = '124.0.6367.207';

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
const mockUninstall = sinon.stub();
const mockOSHomeDir = sinon.stub();
const mockBrowser = {
  CHROME: 'chrome',
  CHROMEDRIVER: 'chromedriver'
};
const puppeteerBrowserMocks = {
  detectBrowserPlatform: mockDetectBrowserPlatform,
  install: mockInstall,
  Browser: mockBrowser,
  resolveBuildId: mockResolveBuildId,
  uninstall: mockUninstall
};

const osMocks = {
  homedir: mockOSHomeDir,
  EOL: '\r\n'
};

const mockProcessStdoutWrite = sinon.stub();
const originalStdoutWrite = process.stdout.write;

let browser;

const { install, version, which } = proxyquire(
  '../src/browser-driver-manager',
  {
    '@puppeteer/browsers': puppeteerBrowserMocks,
    os: osMocks
  }
);

const setup = async () => {
  browser = 'chrome';

  mockDetectBrowserPlatform.returns('mac');
  mockInstall.returns({ executablePath: chromeTestPath });
  mockResolveBuildId.returns(mockVersion);
  mockOSHomeDir.returns(MOCK_HOME_DIR);
  try {
    await fsPromises.mkdir(MOCK_HOME_DIR, { recursive: true });
  } catch (e) {
    console.log('trying to mkdir error: ', e);
  }
};

const teardown = async () => {
  sinon.reset();
  await fsPromises.rm(MOCK_HOME_DIR, { recursive: true, force: true });
};

beforeEach(setup);

afterEach(teardown);

const makeEnvFile = async (contents = envContents) => {
  await fsPromises.mkdir(MOCK_BDM_CACHE_DIR, { recursive: true });
  await fsPromises.writeFile(envPath, contents);
};

describe('browser-driver-manager', () => {
  describe('which', async () => {
    it('logs the locations of chrome and chromedriver if they exist', async () => {
      await makeEnvFile();
      const consoleLogStub = sinon.stub(console, 'log');
      await which();

      sinon.assert.calledWith(consoleLogStub, envContents);
      consoleLogStub.restore();
    });
    it('errors if no environment file exists', async () => {
      await expect(which()).to.be.rejectedWith(
        'No environment file exists. Please install first'
      );
    });
  });
  describe('version', () => {
    it('logs the version when a valid one exists', async () => {
      await makeEnvFile();
      const consoleLogStub = sinon.stub(console, 'log');
      await version();

      sinon.assert.calledWith(consoleLogStub, mockVersion);
      consoleLogStub.restore();
    });
    it('errors if no environment file exists', async () => {
      await expect(which()).to.be.rejectedWith(
        'No environment file exists. Please install first'
      );
    });
  });
  describe('install', () => {
    const chromeArgs = sinon.match({
      cacheDir: sinon.match.string,
      browser: 'chrome',
      buildId: sinon.match.string
    });
    const chromedriverArgs = sinon.match({
      cacheDir: sinon.match.string,
      browser: 'chromedriver',
      buildId: sinon.match.string
    });
    it('calls the Puppeteer/browser installer when given a valid browser', async () => {
      await install(browser);
      sinon.assert.calledWith(mockInstall, chromeArgs);
      sinon.assert.calledWith(mockInstall, chromedriverArgs);
    });
    describe('creates', () => {
      it("the cache directory if it doesn't already exist", async () => {
        await install(browser);
        await expect(fsPromises.access(MOCK_BDM_CACHE_DIR)).to.be.fulfilled;
      });

      it('the environment file when Puppeteer installer successfully returns paths to executables', async () => {
        mockInstall
          .withArgs(chromeArgs)
          .returns({ executablePath: chromeTestPath });

        mockInstall
          .withArgs(chromedriverArgs)
          .returns({ executablePath: chromedriverTestPath });

        const consoleLogStub = sinon.stub(console, 'log');
        await install('chrome');

        sinon.assert.calledWith(
          consoleLogStub,
          'Setting env CHROME/CHROMEDRIVER_TEST_PATH/VERSION'
        );
        consoleLogStub.restore();
        await expect(fsPromises.readFile(envPath, 'utf-8')).to.be.fulfilled;
        const env = await fsPromises.readFile(envPath, 'utf-8');
        expect(env.match(chromeTestPath)).to.not.be.null;
        expect(env.match(chromedriverTestPath)).to.not.be.null;
        expect(env.match(mockVersion)).to.not.be.null;
      });
    });
    describe('errors when', () => {
      beforeEach(setup);
      afterEach(teardown);
      it('an unsupported browser is given', async () => {
        await expect(install('firefox')).to.be.rejectedWith(
          'The selected browser, firefox, could not be installed. Currently, only "chrome" is supported.'
        );
      });

      it("the platform can't be detected", async () => {
        mockDetectBrowserPlatform.returns(undefined);
        await expect(install(browser)).to.be.rejectedWith(
          'Unable to detect a valid platform for'
        );
      });

      it('fsPromises.writeFile rejects', async () => {
        const fsWriteFileStub = sinon.stub(fsPromises, 'writeFile').rejects();
        await expect(install(browser)).to.be.rejectedWith(
          'Error setting CHROME/CHROMEDRIVER_TEST_PATH/VERSION'
        );
        fsWriteFileStub.restore();
      });

      it('unable to remove cache dir', async () => {
        const fsRmStub = sinon.stub(fsPromises, 'rm').rejects();
        await expect(install(browser)).to.be.rejectedWith(
          'Unable to remove .env'
        );
        fsRmStub.restore();
      });

      it('an invalid chrome version is provided', async () => {
        mockResolveBuildId.throws('invalid version');
        await expect(install('chrome@broken')).to.be.rejectedWith(
          'invalid version'
        );
        sinon.assert.notCalled(mockInstall);
      });

      const browserInstallFailures = browser => {
        describe(`installing ${browser} fails with`, async () => {
          [
            {
              error: 'status code 404',
              message: `Tried to install version ${mockVersion} of ${browser}`
            },
            {
              error: 'any other error',
              message: 'any other error'
            }
          ].forEach(({ error, message }) => {
            it(error, async () => {
              mockInstall
                .withArgs(
                  sinon.match({
                    cacheDir: sinon.match.string,
                    browser,
                    buildId: mockVersion
                  })
                )
                .throws(error);
              await expect(install(browser)).to.be.rejectedWith(message);
            });
          });
        });
      };

      ['chrome', 'chromedriver'].forEach(browser =>
        browserInstallFailures(browser)
      );
    });

    describe('called twice', () => {
      it('does not repeat installation if the version is already installed', async () => {
        const consoleLogStub = sinon.stub(console, 'log');
        await install(browser);
        await install(browser);

        sinon.assert.calledWith(
          consoleLogStub,
          `Chrome and Chromedriver versions ${mockVersion} are already installed. Skipping installation.`
        );
        sinon.assert.calledTwice(mockInstall);
        await which();

        sinon.assert.calledWith(consoleLogStub, sinon.match(mockVersion));
        consoleLogStub.restore();
      });
      describe('when the given version differs from the previous version', () => {
        it(`logs the currently installed version and that we're overwriting`, async () => {
          const consoleLogStub = sinon.stub(console, 'log');
          await install(browser);
          mockResolveBuildId.returns(mockOverwriteVersion);
          await install(browser);
          sinon.assert.calledWith(
            consoleLogStub,
            sinon.match(
              `Chrome and Chromedriver versions ${mockVersion} are currently installed. Overwriting.`
            )
          );
          consoleLogStub.restore();
        });
        describe('uninstalls the previous version of', () => {
          ['chrome', 'chromedriver'].forEach(browser => {
            it(browser, async () => {
              await install(browser);
              mockResolveBuildId.returns(mockOverwriteVersion);
              await install(browser);
              sinon.assert.calledWith(
                mockUninstall,
                sinon.match({
                  buildId: mockVersion,
                  browser
                })
              );
            });
          });
        });
        describe('installs the new version of', () => {
          ['chrome', 'chromedriver'].forEach(browser => {
            it(browser, async () => {
              await install(browser);
              mockResolveBuildId.returns(mockOverwriteVersion);
              await install(browser);
              sinon.assert.calledWith(
                mockInstall,
                sinon.match({
                  buildId: mockOverwriteVersion,
                  browser
                })
              );
            });
          });
        });
        it('logs the correct current version after installation', async () => {
          const consoleLogStub = sinon.stub(console, 'log');
          await install(browser);
          mockResolveBuildId.returns(mockOverwriteVersion);
          await install(browser);
          await version();
          sinon.assert.calledWith(consoleLogStub, mockOverwriteVersion);
          consoleLogStub.restore();
        });
      });
    });
    describe('does not show download progress when', () => {
      it('there are no options passed', () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback(1, 1);
          return { executablePath: chromeTestPath };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          },
          process: {
            stdout: {
              write: mockProcessStdoutWrite
            }
          }
        });
        install(browser);
        sinon.assert.neverCalledWithMatch(
          mockProcessStdoutWrite,
          'Downloading Chrome'
        );
      });
      it('the verbose option is false', () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback(1, 1);
          return { executablePath: chromeTestPath };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          },
          process: {
            stdout: {
              write: mockProcessStdoutWrite
            }
          }
        });
        install(browser, { verbose: false });
        sinon.assert.neverCalledWithMatch(
          mockProcessStdoutWrite,
          'Downloading Chrome'
        );
      });
    });
    describe('when the verbose option is true', () => {
      it('writes the browser and download progress', async () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback(1, 100);
          return { executablePath: chromeTestPath };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          },
          os: osMocks
        });
        process.stdout.write = mockProcessStdoutWrite;
        await install(browser, { verbose: true });
        process.stdout.write = originalStdoutWrite;
        sinon.assert.calledWith(
          mockProcessStdoutWrite,
          sinon.match(/Downloading Chrome.../)
        );
      });
      it('writes when the download is done', async () => {
        const downloadProgressCaller = ({ downloadProgressCallback }) => {
          downloadProgressCallback(100, 100);
          return { executablePath: chromeTestPath };
        };
        let { install } = proxyquire('../src/browser-driver-manager', {
          '@puppeteer/browsers': {
            ...puppeteerBrowserMocks,
            ...{
              install: downloadProgressCaller
            }
          },
          os: osMocks
        });
        process.stdout.write = mockProcessStdoutWrite;
        await install(browser, { verbose: true });
        process.stdout.write = originalStdoutWrite;
        sinon.assert.calledWith(mockProcessStdoutWrite, sinon.match(/Done!/));
      });
    });
  });
});
