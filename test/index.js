const sinon = require('sinon');
const proxyquire = require('proxyquire').noCallThru();
const nock = require('nock')
const expect = require('chai').expect;
const chromdriver = require('chromedriver');

const originalProcessStdout = process.stdout;
const originalProcessStderr = process.stderr;
const originalConsoleLog = console.log;
const originalConsoleError = console.error;

let mockStdoutChunk;

const mockSpawn = {
  stdout: {
    on(evt, callback) {
      if (mockStdoutChunk) {
        callback('Google Chrome 97.0.4692.71');
        mockStdoutChunk = null;
      }
    }
  },
  stderr: {
    on: sinon.stub()
  },
  on(event, callback) {
    callback();
  }
};
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

const spawnStub = sinon.stub().returns(mockSpawn);
const browserDriverManager = proxyquire(
  '../src/browser-driver-manager',
  {
    'child_process': {
      spawn: spawnStub
    }
  }
);

let chromdriverNock;
beforeEach(() => {
  global.process.stdout = mockProcessStdout;
  global.process.stderr = mockProcessStderr;

  chromdriverNock = nock('https://registry.npmjs.org/')
    .get('/chromedriver')
    .reply(200, {
      'dist-tags': {
        latest: '97.0.2'
      }
    });
});

afterEach(() => {
  global.process.stdout = originalProcessStdout;
  global.process.stderr = originalProcessStderr;
  console.log = originalConsoleLog;
  console.error = originalConsoleError;

  mockStdoutChunk = null;

  spawnStub.resetHistory();
  mockConsoleLog.resetHistory();
  nock.cleanAll()
  nock.enableNetConnect()
});

describe('browser-driver-manager', () => {
  it('should pass args through to bash script', async () => {
    const args = ['which', 'chrome', '--verbose'];
    await browserDriverManager(args);

    expect(spawnStub.calledWith(sinon.match.string, args)).to.be.true;
  });

  it('should output npm chromedriver path', async () => {
    const args = ['which', 'chromedriver'];
    console.log = mockConsoleLog;
    await browserDriverManager(args);

    expect(mockConsoleLog.calledWith(chromdriver.path)).to.be.true;
  });

  it('should output npm chromedriver version', async () => {
    const args = ['version', 'chromedriver'];
    console.log = mockConsoleLog;
    await browserDriverManager(args);

    expect(mockConsoleLog.calledWith(chromdriver.version)).to.be.true;
  });

  it('should pass install of chrome to bash script', async () => {
    const args = ['install', 'chrome'];
    await browserDriverManager(args);

    expect(spawnStub.calledWith('sudo', sinon.match.array.contains(args))).to.be.true;
  });

  it('should pass verbose option to install chrome', async () => {
    const args = ['install', 'chrome', '--verbose'];
    await browserDriverManager(args);

    expect(spawnStub.calledWith('sudo', sinon.match.array.contains(args))).to.be.true;
  });

  describe('install chromedriver', () => {
    it('should call "version chrome"', async () => {
      const args = ['install', 'chromedriver'];
      const expected = ['version', 'chrome=stable'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith(sinon.match.string, expected)).to.be.true;
    });

    it('should pass verbose option to "version chrome"', async () => {
      const args = ['install', 'chromedriver', '--verbose'];
      const expected = ['version', 'chrome=stable', '--verbose'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith(sinon.match.string, expected)).to.be.true;
    });

    it('should pass stable channel to "version chrome"', async () => {
      const args = ['install', 'chromedriver=stable'];
      const expected = ['version', 'chrome=stable'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith(sinon.match.string, expected)).to.be.true;
    });

    it('should pass beta channel to "version chrome"', async () => {
      const args = ['install', 'chromedriver=beta'];
      const expected = ['version', 'chrome=beta'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith(sinon.match.string, expected)).to.be.true;
    });

    it('should pass dev channel to "version chrome"', async () => {
      const args = ['install', 'chromedriver=dev'];
      const expected = ['version', 'chrome=dev'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith(sinon.match.string, expected)).to.be.true;
    });

    it('should pass canary channel to "version chrome"', async () => {
      const args = ['install', 'chromedriver=canary'];
      const expected = ['version', 'chrome=canary'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith(sinon.match.string, expected)).to.be.true;
    });

    it('should error if chromedriver version is invalid', async () => {
      const args = ['install', 'chromedriver=invalid'];
      console.log = mockConsoleLog;
      console.error = mockConsoleError;
      await browserDriverManager(args);

      expect(mockConsoleError.calledWith(sinon.match.string, 'Chrome version "invalid" is not a number')).to.be.true;
    });

    it('should correctly get major version of chrome', async () => {
      const args = ['install', 'chromedriver'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(mockConsoleLog.calledWith('Installing ChromeDriver 97')).to.be.true;
    });

    it('should fetch npm chromedriver version', async () => {
      const args = ['install', 'chromedriver', '--verbose'];
      mockStdoutChunk = 'Google Chrome 97.0.4692.71';
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(chromdriverNock.isDone()).to.be.true;
    });

    it('should use the version if it is equal to the latest npm chromedriver', async () => {
      const args = ['install', 'chromedriver=97'];
      const expected = ['install', '--no-save', 'chromedriver@97'];
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith('npm', expected)).to.be.true;
    });

    it('should use the version if it is below to the latest npm chromedriver', async () => {
      const args = ['install', 'chromedriver=96'];
      const expected = ['install', '--no-save', 'chromedriver@96'];
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith('npm', expected)).to.be.true;
    });

    it('should use the version before if it is above to the latest npm chromedriver', async () => {
      const args = ['install', 'chromedriver=98'];
      const expected = ['install', '--no-save', 'chromedriver@97'];
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(spawnStub.calledWith('npm', expected)).to.be.true;
    });

    it('should error if the version does not exist', async () => {
      const args = ['install', 'chromedriver=100', '--verbose'];
      console.log = mockConsoleLog;
      console.error = mockConsoleError;
      await browserDriverManager(args);

      expect(mockConsoleError.calledWith(sinon.match.string, 'Unable to get ChromeDriver version; Something went wrong')).to.be.true;
    });

    it('should output verbose logs', async () => {
      const args = ['install', 'chromedriver=97', '--verbose'];
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(mockConsoleLog.calledWith(sinon.match.any, 'Received response of 97.0.2')).to.be.true;
    });

    it('should not output verbose logs if flag is not set', async () => {
      const args = ['install', 'chromedriver=97'];
      console.log = mockConsoleLog;
      await browserDriverManager(args);

      expect(mockConsoleLog.calledWith(sinon.match.any, 'Received response of 97.0.2')).to.be.false;
    });
  });
});