const sinon = require('sinon');
const proxyquire = require('proxyquire').noCallThru();
const expect = require('chai').expect;
const path = require('path');
const fs = require('fs');

const originalProcessStdout = process.stdout;
const originalProcessStderr = process.stderr;
const originalConsoleLog = console.log;
const originalConsoleError = console.error;

const mockProcessStdout = {
  clearLine: sinon.stub(),
  cursorTo: sinon.stub(),
  write: sinon.stub()
};
const mockProcessStderr = {
  write: sinon.stub()
};

const mockConsoleLog = sinon.stub();
const mockConsoleError = sinon.stub();

const buildId = '90810624976';
const version = '126.0.6442.0';
const MOCK_HOME_DIR = './mock-user-home-dir';
const MOCK_BDM_CACHE_DIR = path.resolve(
  MOCK_HOME_DIR,
  '.browser-driver-manager'
);
const envPath = path.resolve(MOCK_BDM_CACHE_DIR, '.env');
const chromeTestPath = `${MOCK_BDM_CACHE_DIR}/chrome/os_arch-${version}/chrome`;
const chromedriverTestPath = `${MOCK_BDM_CACHE_DIR}/chromedriver/os_arch-${version}/chromedriver`;
const envContents = `CHROME_TEST_PATH="${chromeTestPath}"\nCHROMEDRIVER_TEST_PATH="${chromedriverTestPath}"`;

const mockResolveBuildId = sinon.stub().returns(buildId);
const mockDetectBrowserPlatform = sinon.stub().returns('mac');
const mockInstall = sinon.stub();
const mockExistsSync = sinon.stub();
const mockReadFileSync = sinon.stub();

const browserDriverManager = proxyquire('../src/browser-driver-manager', {
  '@puppeteer/browsers': {
    resolveBuildId: mockResolveBuildId.returns(buildId),
    detectBrowserPlatform: mockDetectBrowserPlatform,
    install: mockInstall.returns('TODO'),
    Browser: {
      CHROME: 'chrome',
      CHROMEDRIVER: 'chromedriver'
    }
  },
  os: {
    homedir: sinon.stub().returns(MOCK_HOME_DIR)
  }
});

beforeEach(() => {
  global.process.stdout = mockProcessStdout;
  global.process.stderr = mockProcessStderr;

  console.log = mockConsoleLog;
  console.error = mockConsoleError;
});

afterEach(() => {
  global.process.stdout = originalProcessStdout;
  global.process.stderr = originalProcessStderr;
  console.log = originalConsoleLog;
  console.error = originalConsoleError;

  mockConsoleLog.resetHistory();

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
    const args = ['which'];
    it('should log the locations of chrome and chromedriver if they exist', async () => {
      makeEnvFile();
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      sinon.assert.calledWith(mockConsoleLog, envContents);
    });
    it("shouldn't log if no environment path dir exists", async () => {
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      sinon.assert.calledWith(mockConsoleLog, null);
    });
  });
  describe('version', () => {
    const args = ['version'];
    it('should log the version when a valid one exists', async () => {
      makeEnvFile();
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      sinon.assert.calledWith(mockConsoleLog, 'Version:', version);
    });
    it('should log "not found" when the path doesn\'t exist', async () => {
      const notFoundMessage = 'Version not found in the file path.';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      sinon.assert.calledWith(mockConsoleLog, notFoundMessage);
    });
    it('should log not found when version is not found', async () => {
      const notFoundMessage = 'Version not found in the file path.';
      makeEnvFile('bad env file format');
      await browserDriverManager(args);

      sinon.assert.calledWith(mockConsoleLog, notFoundMessage);
    });
  });
  describe('chrome', () => {
    it("should create the cache directory if it doesn't already exist", async () => {
      expect(fs.existsSync(MOCK_BDM_CACHE_DIR)).to.be.false;
      const args = ['chrome'];
      await browserDriverManager(args);
      expect(fs.existsSync(MOCK_BDM_CACHE_DIR)).to.be.true;
    });

    it('should call detectBrowserPlatform', async () => {
      const args = ['chrome'];
      await browserDriverManager(args);

      sinon.assert.called(mockDetectBrowserPlatform);
    });

    it('should call resolveBuildId with the correct arguments when no version is given', async () => {
      const args = ['chrome'];
      await browserDriverManager(args);

      sinon.assert.calledWith(mockResolveBuildId, 'chrome', 'mac', 'latest');
    });

    it('should call resolveBuildId with the correct arguments when a version is given', async () => {
      const args = ['chrome@latest'];
      await browserDriverManager(args);

      sinon.assert.calledWith(mockResolveBuildId, 'chrome', 'mac', 'latest');
    });

    it('should call install with Chrome and the buildId', async () => {
      const args = ['chrome'];
      await browserDriverManager(args);

      sinon.assert.calledWith(mockInstall, {
        cacheDir: sinon.match.string,
        browser: 'chrome',
        buildId
      });
    });

    it('should call install with Chromedriver and the buildId', async () => {
      const args = ['chrome'];
      await browserDriverManager(args);

      sinon.assert.calledWith(mockInstall, {
        cacheDir: sinon.match.string,
        browser: 'chromedriver',
        buildId
      });
    });

    it('should write the environment variables to the file system', async () => {
      mockInstall
        .withArgs({
          cacheDir: sinon.match.string,
          browser: 'chrome',
          buildId: sinon.match.string
        })
        .returns({ executablePath: chromeTestPath });

      mockInstall
        .withArgs({
          cacheDir: sinon.match.string,
          browser: 'chromedriver',
          buildId: sinon.match.string
        })
        .returns({ executablePath: chromedriverTestPath });

      const args = ['chrome'];
      await browserDriverManager(args);

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

      const args = ['chrome'];
      await browserDriverManager(args);

      sinon.assert.calledWith(
        mockConsoleError,
        'Error setting CHROME/CHROMEDRIVER_TEST_PATH'
      );
    });
  });
});
