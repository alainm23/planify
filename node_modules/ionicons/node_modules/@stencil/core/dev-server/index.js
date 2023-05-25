/*!
 Stencil Dev Server v2.22.3 | MIT Licensed | https://stenciljs.com
 */
'use strict';

const path = require('path');
const child_process = require('child_process');

function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

function _interopNamespace(e) {
    if (e && e.__esModule) return e;
    var n = Object.create(null);
    if (e) {
        Object.keys(e).forEach(function (k) {
            if (k !== 'default') {
                var d = Object.getOwnPropertyDescriptor(e, k);
                Object.defineProperty(n, k, d.get ? d : {
                    enumerable: true,
                    get: function () {
                        return e[k];
                    }
                });
            }
        });
    }
    n['default'] = e;
    return Object.freeze(n);
}

const path__default = /*#__PURE__*/_interopDefaultLegacy(path);

function initServerProcessWorkerProxy(sendToMain) {
    const workerPath = require.resolve(path__default['default'].join(__dirname, 'server-worker-thread.js'));
    const filteredExecArgs = process.execArgv.filter((v) => !/^--(debug|inspect)/.test(v));
    const forkOpts = {
        execArgv: filteredExecArgs,
        env: process.env,
        cwd: process.cwd(),
        stdio: ['pipe', 'pipe', 'pipe', 'ipc'],
    };
    // start a new child process of the CLI process
    // for the http and web socket server
    let serverProcess = child_process.fork(workerPath, [], forkOpts);
    const receiveFromMain = (msg) => {
        // get a message from main to send to the worker
        if (serverProcess) {
            serverProcess.send(msg);
        }
        else if (msg.closeServer) {
            sendToMain({ serverClosed: true });
        }
    };
    // get a message from the worker and send it to main
    serverProcess.on('message', (msg) => {
        if (msg.serverClosed && serverProcess) {
            serverProcess.kill('SIGINT');
            serverProcess = null;
        }
        sendToMain(msg);
    });
    serverProcess.stdout.on('data', (data) => {
        // the child server process has console logged data
        console.log(`dev server: ${data}`);
    });
    serverProcess.stderr.on('data', (data) => {
        // the child server process has console logged an error
        sendToMain({ error: { message: 'stderr: ' + data } });
    });
    return receiveFromMain;
}

function start(stencilDevServerConfig, logger, watcher) {
    return new Promise(async (resolve, reject) => {
        try {
            const devServerConfig = {
                devServerDir: __dirname,
                ...stencilDevServerConfig,
            };
            if (!path__default['default'].isAbsolute(devServerConfig.root)) {
                devServerConfig.root = path__default['default'].join(process.cwd(), devServerConfig.root);
            }
            let initServerProcess;
            if (stencilDevServerConfig.worker === true || stencilDevServerConfig.worker === undefined) {
                // fork a worker process
                initServerProcess = initServerProcessWorkerProxy;
            }
            else {
                // same process
                const devServerProcess = await Promise.resolve().then(function () { return /*#__PURE__*/_interopNamespace(require('./server-process.js')); });
                initServerProcess = devServerProcess.initServerProcess;
            }
            startServer(devServerConfig, logger, watcher, initServerProcess, resolve, reject);
        }
        catch (e) {
            reject(e);
        }
    });
}
function startServer(devServerConfig, logger, watcher, initServerProcess, resolve, reject) {
    var _a;
    const timespan = logger.createTimeSpan(`starting dev server`, true);
    const startupTimeout = logger.getLevel() !== 'debug' || devServerConfig.startupTimeout !== 0
        ? setTimeout(() => {
            reject(`dev server startup timeout`);
        }, (_a = devServerConfig.startupTimeout) !== null && _a !== void 0 ? _a : 15000)
        : null;
    let isActivelyBuilding = false;
    let lastBuildResults = null;
    let devServer = null;
    let removeWatcher = null;
    let closeResolve = null;
    let hasStarted = false;
    let browserUrl = '';
    let sendToWorker = null;
    const closePromise = new Promise((resolve) => (closeResolve = resolve));
    const close = async () => {
        clearTimeout(startupTimeout);
        isActivelyBuilding = false;
        if (removeWatcher) {
            removeWatcher();
        }
        if (devServer) {
            devServer = null;
        }
        if (sendToWorker) {
            sendToWorker({
                closeServer: true,
            });
            sendToWorker = null;
        }
        return closePromise;
    };
    const emit = async (eventName, data) => {
        if (sendToWorker) {
            if (eventName === 'buildFinish') {
                isActivelyBuilding = false;
                lastBuildResults = { ...data };
                sendToWorker({ buildResults: { ...lastBuildResults }, isActivelyBuilding });
            }
            else if (eventName === 'buildLog') {
                sendToWorker({
                    buildLog: { ...data },
                });
            }
            else if (eventName === 'buildStart') {
                isActivelyBuilding = true;
            }
        }
    };
    const serverStarted = (msg) => {
        hasStarted = true;
        clearTimeout(startupTimeout);
        devServerConfig = msg.serverStarted;
        devServer = {
            address: devServerConfig.address,
            basePath: devServerConfig.basePath,
            browserUrl: devServerConfig.browserUrl,
            protocol: devServerConfig.protocol,
            port: devServerConfig.port,
            root: devServerConfig.root,
            emit,
            close,
        };
        browserUrl = devServerConfig.browserUrl;
        timespan.finish(`dev server started: ${browserUrl}`);
        resolve(devServer);
    };
    const requestLog = (msg) => {
        if (devServerConfig.logRequests) {
            if (msg.requestLog.status >= 500) {
                logger.info(logger.red(`${msg.requestLog.method} ${msg.requestLog.url} (${msg.requestLog.status})`));
            }
            else if (msg.requestLog.status >= 400) {
                logger.info(logger.dim(logger.red(`${msg.requestLog.method} ${msg.requestLog.url} (${msg.requestLog.status})`)));
            }
            else if (msg.requestLog.status >= 300) {
                logger.info(logger.dim(logger.magenta(`${msg.requestLog.method} ${msg.requestLog.url} (${msg.requestLog.status})`)));
            }
            else {
                logger.info(logger.dim(`${logger.cyan(msg.requestLog.method)} ${msg.requestLog.url}`));
            }
        }
    };
    const serverError = async (msg) => {
        if (hasStarted) {
            logger.error(msg.error.message + ' ' + msg.error.stack);
        }
        else {
            await close();
            reject(msg.error.message);
        }
    };
    const requestBuildResults = () => {
        // we received a request to send up the latest build results
        if (sendToWorker) {
            if (lastBuildResults != null) {
                // we do have build results, so let's send them to the child process
                const msg = {
                    buildResults: { ...lastBuildResults },
                    isActivelyBuilding: isActivelyBuilding,
                };
                // but don't send any previous live reload data
                delete msg.buildResults.hmr;
                sendToWorker(msg);
            }
            else {
                sendToWorker({
                    isActivelyBuilding: true,
                });
            }
        }
    };
    const compilerRequest = async (compilerRequestPath) => {
        if (watcher && watcher.request && sendToWorker) {
            const compilerRequestResults = await watcher.request({ path: compilerRequestPath });
            sendToWorker({ compilerRequestResults });
        }
    };
    const receiveFromWorker = (msg) => {
        try {
            if (msg.serverStarted) {
                serverStarted(msg);
            }
            else if (msg.serverClosed) {
                logger.debug(`dev server closed: ${browserUrl}`);
                closeResolve();
            }
            else if (msg.requestBuildResults) {
                requestBuildResults();
            }
            else if (msg.compilerRequestPath) {
                compilerRequest(msg.compilerRequestPath);
            }
            else if (msg.requestLog) {
                requestLog(msg);
            }
            else if (msg.error) {
                serverError(msg);
            }
            else {
                logger.debug(`server msg not handled: ${JSON.stringify(msg)}`);
            }
        }
        catch (e) {
            logger.error('receiveFromWorker: ' + e);
        }
    };
    try {
        if (watcher) {
            removeWatcher = watcher.on(emit);
        }
        sendToWorker = initServerProcess(receiveFromWorker);
        sendToWorker({
            startServer: devServerConfig,
        });
    }
    catch (e) {
        close();
        reject(e);
    }
}

exports.start = start;
