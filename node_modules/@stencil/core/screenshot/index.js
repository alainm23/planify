'use strict';

const os = require('os');
const path = require('path');
const fs = require('fs');

function _interopDefaultLegacy (e) { return e && typeof e === 'object' && 'default' in e ? e : { 'default': e }; }

const path__default = /*#__PURE__*/_interopDefaultLegacy(path);
const fs__default = /*#__PURE__*/_interopDefaultLegacy(fs);

function fileExists(filePath) {
    return new Promise((resolve) => {
        fs__default['default'].access(filePath, (err) => resolve(!err));
    });
}
function readFile(filePath) {
    return new Promise((resolve, reject) => {
        fs__default['default'].readFile(filePath, 'utf-8', (err, data) => {
            if (err) {
                reject(err);
            }
            else {
                resolve(data);
            }
        });
    });
}
function readFileBuffer(filePath) {
    return new Promise((resolve, reject) => {
        fs__default['default'].readFile(filePath, (err, data) => {
            if (err) {
                reject(err);
            }
            else {
                resolve(data);
            }
        });
    });
}
function writeFile(filePath, data) {
    return new Promise((resolve, reject) => {
        fs__default['default'].writeFile(filePath, data, (err) => {
            if (err) {
                reject(err);
            }
            else {
                resolve();
            }
        });
    });
}
function mkDir(filePath) {
    return new Promise((resolve) => {
        fs__default['default'].mkdir(filePath, () => {
            resolve();
        });
    });
}
function rmDir(filePath) {
    return new Promise((resolve) => {
        fs__default['default'].rmdir(filePath, () => {
            resolve();
        });
    });
}
async function emptyDir(dir) {
    const files = await readDir(dir);
    const promises = files.map(async (fileName) => {
        const filePath = path__default['default'].join(dir, fileName);
        const isDirFile = await isFile(filePath);
        if (isDirFile) {
            await unlink(filePath);
        }
    });
    await Promise.all(promises);
}
async function readDir(dir) {
    return new Promise((resolve) => {
        fs__default['default'].readdir(dir, (err, files) => {
            if (err) {
                resolve([]);
            }
            else {
                resolve(files);
            }
        });
    });
}
async function isFile(itemPath) {
    return new Promise((resolve) => {
        fs__default['default'].stat(itemPath, (err, stat) => {
            if (err) {
                resolve(false);
            }
            else {
                resolve(stat.isFile());
            }
        });
    });
}
async function unlink(filePath) {
    return new Promise((resolve) => {
        fs__default['default'].unlink(filePath, () => {
            resolve();
        });
    });
}

class ScreenshotConnector {
    constructor() {
        this.screenshotDirName = 'screenshot';
        this.imagesDirName = 'images';
        this.buildsDirName = 'builds';
        this.masterBuildFileName = 'master.json';
        this.screenshotCacheFileName = 'screenshot-cache.json';
    }
    async initBuild(opts) {
        this.logger = opts.logger;
        this.buildId = opts.buildId;
        this.buildMessage = opts.buildMessage || '';
        this.buildAuthor = opts.buildAuthor;
        this.buildUrl = opts.buildUrl;
        this.previewUrl = opts.previewUrl;
        (this.buildTimestamp = typeof opts.buildTimestamp === 'number' ? opts.buildTimestamp : Date.now()),
            (this.cacheDir = opts.cacheDir);
        this.packageDir = opts.packageDir;
        this.rootDir = opts.rootDir;
        this.appNamespace = opts.appNamespace;
        this.waitBeforeScreenshot = opts.waitBeforeScreenshot;
        this.pixelmatchModulePath = opts.pixelmatchModulePath;
        if (!opts.logger) {
            throw new Error(`logger option required`);
        }
        if (typeof opts.buildId !== 'string') {
            throw new Error(`buildId option required`);
        }
        if (typeof opts.cacheDir !== 'string') {
            throw new Error(`cacheDir option required`);
        }
        if (typeof opts.packageDir !== 'string') {
            throw new Error(`packageDir option required`);
        }
        if (typeof opts.rootDir !== 'string') {
            throw new Error(`rootDir option required`);
        }
        this.updateMaster = !!opts.updateMaster;
        this.allowableMismatchedPixels = opts.allowableMismatchedPixels;
        this.allowableMismatchedRatio = opts.allowableMismatchedRatio;
        this.pixelmatchThreshold = opts.pixelmatchThreshold;
        this.logger.debug(`screenshot build: ${this.buildId}, ${this.buildMessage}, updateMaster: ${this.updateMaster}`);
        this.logger.debug(`screenshot, allowableMismatchedPixels: ${this.allowableMismatchedPixels}, allowableMismatchedRatio: ${this.allowableMismatchedRatio}, pixelmatchThreshold: ${this.pixelmatchThreshold}`);
        if (typeof opts.screenshotDirName === 'string') {
            this.screenshotDirName = opts.screenshotDirName;
        }
        if (typeof opts.imagesDirName === 'string') {
            this.imagesDirName = opts.imagesDirName;
        }
        if (typeof opts.buildsDirName === 'string') {
            this.buildsDirName = opts.buildsDirName;
        }
        this.screenshotDir = path.join(this.rootDir, this.screenshotDirName);
        this.imagesDir = path.join(this.screenshotDir, this.imagesDirName);
        this.buildsDir = path.join(this.screenshotDir, this.buildsDirName);
        this.masterBuildFilePath = path.join(this.buildsDir, this.masterBuildFileName);
        this.screenshotCacheFilePath = path.join(this.cacheDir, this.screenshotCacheFileName);
        this.currentBuildDir = path.join(os.tmpdir(), 'screenshot-build-' + this.buildId);
        this.logger.debug(`screenshotDirPath: ${this.screenshotDir}`);
        this.logger.debug(`imagesDirPath: ${this.imagesDir}`);
        this.logger.debug(`buildsDirPath: ${this.buildsDir}`);
        this.logger.debug(`currentBuildDir: ${this.currentBuildDir}`);
        this.logger.debug(`cacheDir: ${this.cacheDir}`);
        await mkDir(this.screenshotDir);
        await Promise.all([
            mkDir(this.imagesDir),
            mkDir(this.buildsDir),
            mkDir(this.currentBuildDir),
            mkDir(this.cacheDir),
        ]);
    }
    async pullMasterBuild() {
        /**/
    }
    async getMasterBuild() {
        let masterBuild = null;
        try {
            masterBuild = JSON.parse(await readFile(this.masterBuildFilePath));
        }
        catch (e) { }
        return masterBuild;
    }
    async completeBuild(masterBuild) {
        const filePaths = (await readDir(this.currentBuildDir))
            .map((f) => path.join(this.currentBuildDir, f))
            .filter((f) => f.endsWith('.json'));
        const screenshots = await Promise.all(filePaths.map(async (f) => JSON.parse(await readFile(f))));
        this.sortScreenshots(screenshots);
        if (!masterBuild) {
            masterBuild = {
                id: this.buildId,
                message: this.buildMessage,
                author: this.buildAuthor,
                url: this.buildUrl,
                previewUrl: this.previewUrl,
                appNamespace: this.appNamespace,
                timestamp: this.buildTimestamp,
                screenshots: screenshots,
            };
        }
        const results = {
            appNamespace: this.appNamespace,
            masterBuild: masterBuild,
            currentBuild: {
                id: this.buildId,
                message: this.buildMessage,
                author: this.buildAuthor,
                url: this.buildUrl,
                previewUrl: this.previewUrl,
                appNamespace: this.appNamespace,
                timestamp: this.buildTimestamp,
                screenshots: screenshots,
            },
            compare: {
                id: `${masterBuild.id}-${this.buildId}`,
                a: {
                    id: masterBuild.id,
                    message: masterBuild.message,
                    author: masterBuild.author,
                    url: masterBuild.url,
                    previewUrl: masterBuild.previewUrl,
                },
                b: {
                    id: this.buildId,
                    message: this.buildMessage,
                    author: this.buildAuthor,
                    url: this.buildUrl,
                    previewUrl: this.previewUrl,
                },
                url: null,
                appNamespace: this.appNamespace,
                timestamp: this.buildTimestamp,
                diffs: [],
            },
        };
        results.currentBuild.screenshots.forEach((screenshot) => {
            screenshot.diff.device = screenshot.diff.device || screenshot.diff.userAgent;
            results.compare.diffs.push(screenshot.diff);
            delete screenshot.diff;
        });
        this.sortCompares(results.compare.diffs);
        await emptyDir(this.currentBuildDir);
        await rmDir(this.currentBuildDir);
        return results;
    }
    async publishBuild(results) {
        return results;
    }
    async generateJsonpDataUris(build) {
        if (build && Array.isArray(build.screenshots)) {
            for (let i = 0; i < build.screenshots.length; i++) {
                const screenshot = build.screenshots[i];
                const jsonpFileName = `screenshot_${screenshot.image}.js`;
                const jsonFilePath = path.join(this.cacheDir, jsonpFileName);
                const jsonpExists = await fileExists(jsonFilePath);
                if (!jsonpExists) {
                    const imageFilePath = path.join(this.imagesDir, screenshot.image);
                    const imageBuf = await readFileBuffer(imageFilePath);
                    const jsonpContent = `loadScreenshot("${screenshot.image}","data:image/png;base64,${imageBuf.toString('base64')}");`;
                    await writeFile(jsonFilePath, jsonpContent);
                }
            }
        }
    }
    async getScreenshotCache() {
        return null;
    }
    async updateScreenshotCache(screenshotCache, buildResults) {
        screenshotCache = screenshotCache || {};
        screenshotCache.timestamp = this.buildTimestamp;
        screenshotCache.lastBuildId = this.buildId;
        screenshotCache.size = 0;
        screenshotCache.items = screenshotCache.items || [];
        if (buildResults && buildResults.compare && Array.isArray(buildResults.compare.diffs)) {
            buildResults.compare.diffs.forEach((diff) => {
                if (typeof diff.cacheKey !== 'string') {
                    return;
                }
                if (diff.imageA === diff.imageB) {
                    // no need to cache identical matches
                    return;
                }
                const existingItem = screenshotCache.items.find((i) => i.key === diff.cacheKey);
                if (existingItem) {
                    // already have this cached, but update its timestamp
                    existingItem.ts = this.buildTimestamp;
                }
                else {
                    // add this item to the cache
                    screenshotCache.items.push({
                        key: diff.cacheKey,
                        ts: this.buildTimestamp,
                        mp: diff.mismatchedPixels,
                    });
                }
            });
        }
        // sort so the newest items are on top
        screenshotCache.items.sort((a, b) => {
            if (a.ts > b.ts)
                return -1;
            if (a.ts < b.ts)
                return 1;
            if (a.mp > b.mp)
                return -1;
            if (a.mp < b.mp)
                return 1;
            return 0;
        });
        // keep only the most recent items
        screenshotCache.items = screenshotCache.items.slice(0, 1000);
        screenshotCache.size = screenshotCache.items.length;
        return screenshotCache;
    }
    toJson(masterBuild, screenshotCache) {
        const masterScreenshots = {};
        if (masterBuild && Array.isArray(masterBuild.screenshots)) {
            masterBuild.screenshots.forEach((masterScreenshot) => {
                masterScreenshots[masterScreenshot.id] = masterScreenshot.image;
            });
        }
        const mismatchCache = {};
        if (screenshotCache && Array.isArray(screenshotCache.items)) {
            screenshotCache.items.forEach((cacheItem) => {
                mismatchCache[cacheItem.key] = cacheItem.mp;
            });
        }
        const screenshotBuild = {
            buildId: this.buildId,
            rootDir: this.rootDir,
            screenshotDir: this.screenshotDir,
            imagesDir: this.imagesDir,
            buildsDir: this.buildsDir,
            masterScreenshots: masterScreenshots,
            cache: mismatchCache,
            currentBuildDir: this.currentBuildDir,
            updateMaster: this.updateMaster,
            allowableMismatchedPixels: this.allowableMismatchedPixels,
            allowableMismatchedRatio: this.allowableMismatchedRatio,
            pixelmatchThreshold: this.pixelmatchThreshold,
            timeoutBeforeScreenshot: this.waitBeforeScreenshot,
            pixelmatchModulePath: this.pixelmatchModulePath,
        };
        return JSON.stringify(screenshotBuild);
    }
    sortScreenshots(screenshots) {
        return screenshots.sort((a, b) => {
            if (a.desc && b.desc) {
                if (a.desc.toLowerCase() < b.desc.toLowerCase())
                    return -1;
                if (a.desc.toLowerCase() > b.desc.toLowerCase())
                    return 1;
            }
            if (a.device && b.device) {
                if (a.device.toLowerCase() < b.device.toLowerCase())
                    return -1;
                if (a.device.toLowerCase() > b.device.toLowerCase())
                    return 1;
            }
            if (a.userAgent && b.userAgent) {
                if (a.userAgent.toLowerCase() < b.userAgent.toLowerCase())
                    return -1;
                if (a.userAgent.toLowerCase() > b.userAgent.toLowerCase())
                    return 1;
            }
            if (a.width < b.width)
                return -1;
            if (a.width > b.width)
                return 1;
            if (a.height < b.height)
                return -1;
            if (a.height > b.height)
                return 1;
            if (a.id < b.id)
                return -1;
            if (a.id > b.id)
                return 1;
            return 0;
        });
    }
    sortCompares(compares) {
        return compares.sort((a, b) => {
            if (a.allowableMismatchedPixels > b.allowableMismatchedPixels)
                return -1;
            if (a.allowableMismatchedPixels < b.allowableMismatchedPixels)
                return 1;
            if (a.allowableMismatchedRatio > b.allowableMismatchedRatio)
                return -1;
            if (a.allowableMismatchedRatio < b.allowableMismatchedRatio)
                return 1;
            if (a.desc && b.desc) {
                if (a.desc.toLowerCase() < b.desc.toLowerCase())
                    return -1;
                if (a.desc.toLowerCase() > b.desc.toLowerCase())
                    return 1;
            }
            if (a.device && b.device) {
                if (a.device.toLowerCase() < b.device.toLowerCase())
                    return -1;
                if (a.device.toLowerCase() > b.device.toLowerCase())
                    return 1;
            }
            if (a.userAgent && b.userAgent) {
                if (a.userAgent.toLowerCase() < b.userAgent.toLowerCase())
                    return -1;
                if (a.userAgent.toLowerCase() > b.userAgent.toLowerCase())
                    return 1;
            }
            if (a.width < b.width)
                return -1;
            if (a.width > b.width)
                return 1;
            if (a.height < b.height)
                return -1;
            if (a.height > b.height)
                return 1;
            if (a.id < b.id)
                return -1;
            if (a.id > b.id)
                return 1;
            return 0;
        });
    }
}

/**
 * Convert Windows backslash paths to slash paths: foo\\bar ➔ foo/bar
 * Forward-slash paths can be used in Windows as long as they're not
 * extended-length paths and don't contain any non-ascii characters.
 * This was created since the path methods in Node.js outputs \\ paths on Windows.
 * @param path the Windows-based path to convert
 * @returns the converted path
 */
const normalizePath = (path) => {
    if (typeof path !== 'string') {
        throw new Error(`invalid path to normalize`);
    }
    path = normalizeSlashes(path.trim());
    const components = pathComponents(path, getRootLength(path));
    const reducedComponents = reducePathComponents(components);
    const rootPart = reducedComponents[0];
    const secondPart = reducedComponents[1];
    const normalized = rootPart + reducedComponents.slice(1).join('/');
    if (normalized === '') {
        return '.';
    }
    if (rootPart === '' &&
        secondPart &&
        path.includes('/') &&
        !secondPart.startsWith('.') &&
        !secondPart.startsWith('@')) {
        return './' + normalized;
    }
    return normalized;
};
const normalizeSlashes = (path) => path.replace(backslashRegExp, '/');
const altDirectorySeparator = '\\';
const urlSchemeSeparator = '://';
const backslashRegExp = /\\/g;
const reducePathComponents = (components) => {
    if (!Array.isArray(components) || components.length === 0) {
        return [];
    }
    const reduced = [components[0]];
    for (let i = 1; i < components.length; i++) {
        const component = components[i];
        if (!component)
            continue;
        if (component === '.')
            continue;
        if (component === '..') {
            if (reduced.length > 1) {
                if (reduced[reduced.length - 1] !== '..') {
                    reduced.pop();
                    continue;
                }
            }
            else if (reduced[0])
                continue;
        }
        reduced.push(component);
    }
    return reduced;
};
const getRootLength = (path) => {
    const rootLength = getEncodedRootLength(path);
    return rootLength < 0 ? ~rootLength : rootLength;
};
const getEncodedRootLength = (path) => {
    if (!path)
        return 0;
    const ch0 = path.charCodeAt(0);
    // POSIX or UNC
    if (ch0 === 47 /* CharacterCodes.slash */ || ch0 === 92 /* CharacterCodes.backslash */) {
        if (path.charCodeAt(1) !== ch0)
            return 1; // POSIX: "/" (or non-normalized "\")
        const p1 = path.indexOf(ch0 === 47 /* CharacterCodes.slash */ ? '/' : altDirectorySeparator, 2);
        if (p1 < 0)
            return path.length; // UNC: "//server" or "\\server"
        return p1 + 1; // UNC: "//server/" or "\\server\"
    }
    // DOS
    if (isVolumeCharacter(ch0) && path.charCodeAt(1) === 58 /* CharacterCodes.colon */) {
        const ch2 = path.charCodeAt(2);
        if (ch2 === 47 /* CharacterCodes.slash */ || ch2 === 92 /* CharacterCodes.backslash */)
            return 3; // DOS: "c:/" or "c:\"
        if (path.length === 2)
            return 2; // DOS: "c:" (but not "c:d")
    }
    // URL
    const schemeEnd = path.indexOf(urlSchemeSeparator);
    if (schemeEnd !== -1) {
        const authorityStart = schemeEnd + urlSchemeSeparator.length;
        const authorityEnd = path.indexOf('/', authorityStart);
        if (authorityEnd !== -1) {
            // URL: "file:///", "file://server/", "file://server/path"
            // For local "file" URLs, include the leading DOS volume (if present).
            // Per https://www.ietf.org/rfc/rfc1738.txt, a host of "" or "localhost" is a
            // special case interpreted as "the machine from which the URL is being interpreted".
            const scheme = path.slice(0, schemeEnd);
            const authority = path.slice(authorityStart, authorityEnd);
            if (scheme === 'file' &&
                (authority === '' || authority === 'localhost') &&
                isVolumeCharacter(path.charCodeAt(authorityEnd + 1))) {
                const volumeSeparatorEnd = getFileUrlVolumeSeparatorEnd(path, authorityEnd + 2);
                if (volumeSeparatorEnd !== -1) {
                    if (path.charCodeAt(volumeSeparatorEnd) === 47 /* CharacterCodes.slash */) {
                        // URL: "file:///c:/", "file://localhost/c:/", "file:///c%3a/", "file://localhost/c%3a/"
                        return ~(volumeSeparatorEnd + 1);
                    }
                    if (volumeSeparatorEnd === path.length) {
                        // URL: "file:///c:", "file://localhost/c:", "file:///c$3a", "file://localhost/c%3a"
                        // but not "file:///c:d" or "file:///c%3ad"
                        return ~volumeSeparatorEnd;
                    }
                }
            }
            return ~(authorityEnd + 1); // URL: "file://server/", "http://server/"
        }
        return ~path.length; // URL: "file://server", "http://server"
    }
    // relative
    return 0;
};
const isVolumeCharacter = (charCode) => (charCode >= 97 /* CharacterCodes.a */ && charCode <= 122 /* CharacterCodes.z */) ||
    (charCode >= 65 /* CharacterCodes.A */ && charCode <= 90 /* CharacterCodes.Z */);
const getFileUrlVolumeSeparatorEnd = (url, start) => {
    const ch0 = url.charCodeAt(start);
    if (ch0 === 58 /* CharacterCodes.colon */)
        return start + 1;
    if (ch0 === 37 /* CharacterCodes.percent */ && url.charCodeAt(start + 1) === 51 /* CharacterCodes._3 */) {
        const ch2 = url.charCodeAt(start + 2);
        if (ch2 === 97 /* CharacterCodes.a */ || ch2 === 65 /* CharacterCodes.A */)
            return start + 3;
    }
    return -1;
};
const pathComponents = (path, rootLength) => {
    const root = path.substring(0, rootLength);
    const rest = path.substring(rootLength).split('/');
    const restLen = rest.length;
    if (restLen > 0 && !rest[restLen - 1]) {
        rest.pop();
    }
    return [root, ...rest];
};

class ScreenshotLocalConnector extends ScreenshotConnector {
    async publishBuild(results) {
        if (this.updateMaster || !results.masterBuild) {
            results.masterBuild = {
                id: 'master',
                message: 'Master',
                appNamespace: this.appNamespace,
                timestamp: Date.now(),
                screenshots: [],
            };
        }
        results.currentBuild.screenshots.forEach((currentScreenshot) => {
            const masterHasScreenshot = results.masterBuild.screenshots.some((masterScreenshot) => {
                return currentScreenshot.id === masterScreenshot.id;
            });
            if (!masterHasScreenshot) {
                results.masterBuild.screenshots.push(Object.assign({}, currentScreenshot));
            }
        });
        this.sortScreenshots(results.masterBuild.screenshots);
        await writeFile(this.masterBuildFilePath, JSON.stringify(results.masterBuild, null, 2));
        await this.generateJsonpDataUris(results.currentBuild);
        const compareAppSourceDir = path.join(this.packageDir, 'screenshot', 'compare');
        const appSrcUrl = normalizePath(path.relative(this.screenshotDir, compareAppSourceDir));
        const imagesUrl = normalizePath(path.relative(this.screenshotDir, this.imagesDir));
        const jsonpUrl = normalizePath(path.relative(this.screenshotDir, this.cacheDir));
        const compareAppHtml = createLocalCompareApp(this.appNamespace, appSrcUrl, imagesUrl, jsonpUrl, results.masterBuild, results.currentBuild);
        const compareAppFileName = 'compare.html';
        const compareAppFilePath = path.join(this.screenshotDir, compareAppFileName);
        await writeFile(compareAppFilePath, compareAppHtml);
        const gitIgnorePath = path.join(this.screenshotDir, '.gitignore');
        const gitIgnoreExists = await fileExists(gitIgnorePath);
        if (!gitIgnoreExists) {
            const content = [this.imagesDirName, this.buildsDirName, compareAppFileName];
            await writeFile(gitIgnorePath, content.join('\n'));
        }
        const url = new URL(`file://${compareAppFilePath}`);
        results.compare.url = url.href;
        return results;
    }
    async getScreenshotCache() {
        let screenshotCache = null;
        try {
            screenshotCache = JSON.parse(await readFile(this.screenshotCacheFilePath));
        }
        catch (e) { }
        return screenshotCache;
    }
    async updateScreenshotCache(cache, buildResults) {
        cache = await super.updateScreenshotCache(cache, buildResults);
        await writeFile(this.screenshotCacheFilePath, JSON.stringify(cache, null, 2));
        return cache;
    }
}
function createLocalCompareApp(namespace, appSrcUrl, imagesUrl, jsonpUrl, a, b) {
    return `<!doctype html>
<html dir="ltr" lang="en">
<head>
  <meta charset="utf-8">
  <title>Local ${namespace || ''} - Stencil Screenshot Visual Diff</title>
  <meta name="viewport" content="viewport-fit=cover, width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <meta http-equiv="x-ua-compatible" content="IE=Edge">
  <link href="${appSrcUrl}/build/app.css" rel="stylesheet">
  <script type="module" src="${appSrcUrl}/build/app.esm.js"></script>
  <script nomodule src="${appSrcUrl}/build/app.js"></script>
  <link rel="icon" type="image/x-icon" href="${appSrcUrl}/assets/favicon.ico">
</head>
<body>
  <script>
    (function() {
      var app = document.createElement('screenshot-compare');
      app.appSrcUrl = '${appSrcUrl}';
      app.imagesUrl = '${imagesUrl}/';
      app.jsonpUrl = '${jsonpUrl}/';
      app.a = ${JSON.stringify(a)};
      app.b = ${JSON.stringify(b)};
      document.body.appendChild(app);
    })();
  </script>
</body>
</html>`;
}

exports.ScreenshotConnector = ScreenshotConnector;
exports.ScreenshotLocalConnector = ScreenshotLocalConnector;
