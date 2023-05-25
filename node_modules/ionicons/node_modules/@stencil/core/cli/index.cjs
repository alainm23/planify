/*!
 Stencil CLI (CommonJS) v2.22.3 | MIT Licensed | https://stenciljs.com
 */
'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

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

/**
 * Convert a string from dash-case / kebab-case to PascalCase (or CamelCase,
 * or whatever you call it!)
 *
 * @param str a string to convert
 * @returns a converted string
 */
const dashToPascalCase = (str) => str
    .toLowerCase()
    .split('-')
    .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
    .join('');
/**
 * Convert a string to 'camelCase'
 *
 * @param str the string to convert
 * @returns the converted string
 */
const toCamelCase = (str) => {
    const pascalCase = dashToPascalCase(str);
    return pascalCase.charAt(0).toLowerCase() + pascalCase.slice(1);
};
const isFunction = (v) => typeof v === 'function';
const isString = (v) => typeof v === 'string';

/**
 * Builds a template `Diagnostic` entity for a build error. The created `Diagnostic` is returned, and have little
 * detail attached to it regarding the specifics of the error - it is the responsibility of the caller of this method
 * to attach the specifics of the error message.
 *
 * The created `Diagnostic` is pushed to the `diagnostics` argument as a side effect of calling this method.
 *
 * @param diagnostics the existing diagnostics that the created template `Diagnostic` should be added to
 * @returns the created `Diagnostic`
 */
const buildError = (diagnostics) => {
    const diagnostic = {
        level: 'error',
        type: 'build',
        header: 'Build Error',
        messageText: 'build error',
        relFilePath: null,
        absFilePath: null,
        lines: [],
    };
    if (diagnostics) {
        diagnostics.push(diagnostic);
    }
    return diagnostic;
};
/**
 * Builds a diagnostic from an `Error`, appends it to the `diagnostics` parameter, and returns the created diagnostic
 * @param diagnostics the series of diagnostics the newly created diagnostics should be added to
 * @param err the error to derive information from in generating the diagnostic
 * @param msg an optional message to use in place of `err` to generate the diagnostic
 * @returns the generated diagnostic
 */
const catchError = (diagnostics, err, msg) => {
    const diagnostic = {
        level: 'error',
        type: 'build',
        header: 'Build Error',
        messageText: 'build error',
        relFilePath: null,
        absFilePath: null,
        lines: [],
    };
    if (isString(msg)) {
        diagnostic.messageText = msg.length ? msg : 'UNKNOWN ERROR';
    }
    else if (err != null) {
        if (err.stack != null) {
            diagnostic.messageText = err.stack.toString();
        }
        else {
            if (err.message != null) {
                diagnostic.messageText = err.message.length ? err.message : 'UNKNOWN ERROR';
            }
            else {
                diagnostic.messageText = err.toString();
            }
        }
    }
    if (diagnostics != null && !shouldIgnoreError(diagnostic.messageText)) {
        diagnostics.push(diagnostic);
    }
    return diagnostic;
};
/**
 * Determine if the provided diagnostics have any build errors
 * @param diagnostics the diagnostics to inspect
 * @returns true if any of the diagnostics in the list provided are errors that did not occur at runtime. false
 * otherwise.
 */
const hasError = (diagnostics) => {
    if (diagnostics == null || diagnostics.length === 0) {
        return false;
    }
    return diagnostics.some((d) => d.level === 'error' && d.type !== 'runtime');
};
const shouldIgnoreError = (msg) => {
    return msg === TASK_CANCELED_MSG;
};
const TASK_CANCELED_MSG = `task canceled`;

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

/**
 * Check whether a string is a member of a ReadonlyArray<string>
 *
 * We need a little helper for this because unfortunately `includes` is typed
 * on `ReadonlyArray<T>` as `(el: T): boolean` so a `string` cannot be passed
 * to `includes` on a `ReadonlyArray` 😢 thus we have a little helper function
 * where we do the type coercion just once.
 *
 * see microsoft/TypeScript#31018 for some discussion of this
 *
 * @param readOnlyArray the array we're checking
 * @param maybeMember a value which is possibly a member of the array
 * @returns whether the array contains the member or not
 */
const readOnlyArrayHasStringMember = (readOnlyArray, maybeMember) => readOnlyArray.includes(maybeMember);

/**
 * Validates that a component tag meets required naming conventions to be used for a web component
 * @param tag the tag to validate
 * @returns an error message if the tag has an invalid name, undefined if the tag name passes all checks
 */
const validateComponentTag = (tag) => {
    // we want to check this first since we call some String.prototype methods below
    if (typeof tag !== 'string') {
        return `Tag "${tag}" must be a string type`;
    }
    if (tag !== tag.trim()) {
        return `Tag can not contain white spaces`;
    }
    if (tag !== tag.toLowerCase()) {
        return `Tag can not contain upper case characters`;
    }
    if (tag.length === 0) {
        return `Received empty tag value`;
    }
    if (tag.indexOf(' ') > -1) {
        return `"${tag}" tag cannot contain a space`;
    }
    if (tag.indexOf(',') > -1) {
        return `"${tag}" tag cannot be used for multiple tags`;
    }
    const invalidChars = tag.replace(/\w|-/g, '');
    if (invalidChars !== '') {
        return `"${tag}" tag contains invalid characters: ${invalidChars}`;
    }
    if (tag.indexOf('-') === -1) {
        return `"${tag}" tag must contain a dash (-) to work as a valid web component`;
    }
    if (tag.indexOf('--') > -1) {
        return `"${tag}" tag cannot contain multiple dashes (--) next to each other`;
    }
    if (tag.indexOf('-') === 0) {
        return `"${tag}" tag cannot start with a dash (-)`;
    }
    if (tag.lastIndexOf('-') === tag.length - 1) {
        return `"${tag}" tag cannot end with a dash (-)`;
    }
    return undefined;
};

/**
 * This sets the log level hierarchy for our terminal logger, ranging from
 * most to least verbose.
 *
 * Ordering the levels like this lets us easily check whether we should log a
 * message at a given time. For instance, if the log level is set to `'warn'`,
 * then anything passed to the logger with level `'warn'` or `'error'` should
 * be logged, but we should _not_ log anything with level `'info'` or `'debug'`.
 *
 * If we have a current log level `currentLevel` and a message with level
 * `msgLevel` is passed to the logger, we can determine whether or not we should
 * log it by checking if the log level on the message is further up or at the
 * same level in the hierarchy than `currentLevel`, like so:
 *
 * ```ts
 * LOG_LEVELS.indexOf(msgLevel) >= LOG_LEVELS.indexOf(currentLevel)
 * ```
 *
 * NOTE: for the reasons described above, do not change the order of the entries
 * in this array without good reason!
 */
const LOG_LEVELS = ['debug', 'info', 'warn', 'error'];

/**
 * All the Boolean options supported by the Stencil CLI
 */
const BOOLEAN_CLI_FLAGS = [
    'build',
    'cache',
    'checkVersion',
    'ci',
    'compare',
    'debug',
    'dev',
    'devtools',
    'docs',
    'e2e',
    'es5',
    'esm',
    'headless',
    'help',
    'log',
    'open',
    'prerender',
    'prerenderExternal',
    'prod',
    'profile',
    'serviceWorker',
    'screenshot',
    'serve',
    'skipNodeCheck',
    'spec',
    'ssr',
    'stats',
    'updateScreenshot',
    'verbose',
    'version',
    'watch',
    // JEST CLI OPTIONS
    'all',
    'automock',
    'bail',
    // 'cache', Stencil already supports this argument
    'changedFilesWithAncestor',
    // 'ci', Stencil already supports this argument
    'clearCache',
    'clearMocks',
    'collectCoverage',
    'color',
    'colors',
    'coverage',
    // 'debug', Stencil already supports this argument
    'detectLeaks',
    'detectOpenHandles',
    'errorOnDeprecated',
    'expand',
    'findRelatedTests',
    'forceExit',
    'init',
    'injectGlobals',
    'json',
    'lastCommit',
    'listTests',
    'logHeapUsage',
    'noStackTrace',
    'notify',
    'onlyChanged',
    'onlyFailures',
    'passWithNoTests',
    'resetMocks',
    'resetModules',
    'restoreMocks',
    'runInBand',
    'runTestsByPath',
    'showConfig',
    'silent',
    'skipFilter',
    'testLocationInResults',
    'updateSnapshot',
    'useStderr',
    // 'verbose', Stencil already supports this argument
    // 'version', Stencil already supports this argument
    // 'watch', Stencil already supports this argument
    'watchAll',
    'watchman',
];
/**
 * All the Number options supported by the Stencil CLI
 */
const NUMBER_CLI_FLAGS = [
    'port',
    // JEST CLI ARGS
    'maxConcurrency',
    'testTimeout',
];
/**
 * All the String options supported by the Stencil CLI
 */
const STRING_CLI_FLAGS = [
    'address',
    'config',
    'docsApi',
    'docsJson',
    'emulate',
    'root',
    'screenshotConnector',
    // JEST CLI ARGS
    'cacheDirectory',
    'changedSince',
    'collectCoverageFrom',
    // 'config', Stencil already supports this argument
    'coverageDirectory',
    'coverageThreshold',
    'env',
    'filter',
    'globalSetup',
    'globalTeardown',
    'globals',
    'haste',
    'moduleNameMapper',
    'notifyMode',
    'outputFile',
    'preset',
    'prettierPath',
    'resolver',
    'rootDir',
    'runner',
    'testEnvironment',
    'testEnvironmentOptions',
    'testFailureExitCode',
    'testNamePattern',
    'testResultsProcessor',
    'testRunner',
    'testSequencer',
    'testURL',
    'timers',
    'transform',
];
const STRING_ARRAY_CLI_FLAGS = [
    'collectCoverageOnlyFrom',
    'coveragePathIgnorePatterns',
    'coverageReporters',
    'moduleDirectories',
    'moduleFileExtensions',
    'modulePathIgnorePatterns',
    'modulePaths',
    'projects',
    'reporters',
    'roots',
    'selectProjects',
    'setupFiles',
    'setupFilesAfterEnv',
    'snapshotSerializers',
    'testMatch',
    'testPathIgnorePatterns',
    'testPathPattern',
    'testRegex',
    'transformIgnorePatterns',
    'unmockedModulePathPatterns',
    'watchPathIgnorePatterns',
];
/**
 * All the CLI arguments which may have string or number values
 *
 * `maxWorkers` is an argument which is used both by Stencil _and_ by Jest,
 * which means that we need to support parsing both string and number values.
 */
const STRING_NUMBER_CLI_FLAGS = ['maxWorkers'];
/**
 * All the LogLevel-type options supported by the Stencil CLI
 *
 * This is a bit silly since there's only one such argument atm,
 * but this approach lets us make sure that we're handling all
 * our arguments in a type-safe way.
 */
const LOG_LEVEL_CLI_FLAGS = ['logLevel'];
/**
 * For a small subset of CLI options we support a short alias e.g. `'h'` for `'help'`
 */
const CLI_FLAG_ALIASES = {
    c: 'config',
    h: 'help',
    p: 'port',
    v: 'version',
};
/**
 * A regular expression which can be used to match a CLI flag for one of our
 * short aliases.
 */
const CLI_FLAG_REGEX = new RegExp(`^-[chpv]{1}$`);
/**
 * Helper function for initializing a `ConfigFlags` object. Provide any overrides
 * for default values and off you go!
 *
 * @param init an object with any overrides for default values
 * @returns a complete CLI flag object
 */
const createConfigFlags = (init = {}) => {
    const flags = {
        task: null,
        args: [],
        knownArgs: [],
        unknownArgs: [],
        ...init,
    };
    return flags;
};

/**
 * Parse command line arguments into a structured `ConfigFlags` object
 *
 * @param args an array of CLI flags
 * @param _sys an optional compiler system
 * @returns a structured ConfigFlags object
 */
const parseFlags = (args, _sys) => {
    // TODO(STENCIL-509): remove the _sys parameter here ^^ (for v3)
    const flags = createConfigFlags();
    // cmd line has more priority over npm scripts cmd
    flags.args = Array.isArray(args) ? args.slice() : [];
    if (flags.args.length > 0 && flags.args[0] && !flags.args[0].startsWith('-')) {
        flags.task = flags.args[0];
        // if the first argument was a "task" (like `build`, `test`, etc) then
        // we go on to parse the _rest_ of the CLI args
        parseArgs(flags, args.slice(1));
    }
    else {
        // we didn't find a leading flag, so we should just parse them all
        parseArgs(flags, flags.args);
    }
    if (flags.task != null) {
        const i = flags.args.indexOf(flags.task);
        if (i > -1) {
            flags.args.splice(i, 1);
        }
    }
    // to find unknown / unrecognized arguments we filter `args`, including only
    // arguments whose normalized form is not found in `knownArgs`. `knownArgs`
    // is populated during the call to `parseArgs` above. For arguments like
    // `--foobar` the string `"--foobar"` will be added, while for more
    // complicated arguments like `--bizBoz=bop` or `--bizBoz bop` just the
    // string `"--bizBoz"` will be added.
    flags.unknownArgs = flags.args.filter((arg) => !flags.knownArgs.includes(parseEqualsArg(arg)[0]));
    return flags;
};
/**
 * Parse the supported command line flags which are enumerated in the
 * `config-flags` module. Handles leading dashes on arguments, aliases that are
 * defined for a small number of arguments, and parsing values for non-boolean
 * arguments (e.g. port number for the dev server).
 *
 * This parses the following grammar:
 *
 * CLIArguments    → ""
 *                 | CLITerm ( " " CLITerm )* ;
 * CLITerm         → EqualsArg
 *                 | AliasEqualsArg
 *                 | AliasArg
 *                 | NegativeDashArg
 *                 | NegativeArg
 *                 | SimpleArg ;
 * EqualsArg       → "--" ArgName "=" CLIValue ;
 * AliasEqualsArg  → "-" AliasName "=" CLIValue ;
 * AliasArg        → "-" AliasName ( " " CLIValue )? ;
 * NegativeDashArg → "--no-" ArgName ;
 * NegativeArg     → "--no" ArgName ;
 * SimpleArg       → "--" ArgName ( " " CLIValue )? ;
 * ArgName         → /^[a-zA-Z-]+$/ ;
 * AliasName       → /^[a-z]{1}$/ ;
 * CLIValue        → '"' /^[a-zA-Z0-9]+$/ '"'
 *                 | /^[a-zA-Z0-9]+$/ ;
 *
 * There are additional constraints (not shown in the grammar for brevity's sake)
 * on the type of `CLIValue` which will be associated with a particular argument.
 * We enforce this by declaring lists of boolean, string, etc arguments and
 * checking the types of values before setting them.
 *
 * We don't need to turn the list of CLI arg tokens into any kind of
 * intermediate representation since we aren't concerned with doing anything
 * other than setting the correct values on our ConfigFlags object. So we just
 * parse the array of string arguments using a recursive-descent approach
 * (which is not very deep since our grammar is pretty simple) and make the
 * modifications we need to make to the {@link ConfigFlags} object as we go.
 *
 * @param flags a ConfigFlags object to which parsed arguments will be added
 * @param args  an array of command-line arguments to parse
 */
const parseArgs = (flags, args) => {
    const argsCopy = args.concat();
    while (argsCopy.length > 0) {
        // there are still unprocessed args to deal with
        parseCLITerm(flags, argsCopy);
    }
};
/**
 * Given an array of CLI arguments, parse it and perform a series of side
 * effects (setting values on the provided `ConfigFlags` object).
 *
 * @param flags a {@link ConfigFlags} object which is updated as we parse the CLI
 * arguments
 * @param args a list of args to work through. This function (and some functions
 * it calls) calls `Array.prototype.shift` to get the next argument to look at,
 * so this parameter will be modified.
 */
const parseCLITerm = (flags, args) => {
    // pull off the first arg from the argument array
    const arg = args.shift();
    // array is empty, we're done!
    if (arg === undefined)
        return;
    // EqualsArg → "--" ArgName "=" CLIValue ;
    if (arg.startsWith('--') && arg.includes('=')) {
        // we're dealing with an EqualsArg, we have a special helper for that
        const [originalArg, value] = parseEqualsArg(arg);
        setCLIArg(flags, arg.split('=')[0], normalizeFlagName(originalArg), value);
    }
    // AliasEqualsArg  → "-" AliasName "=" CLIValue ;
    else if (arg.startsWith('-') && arg.includes('=')) {
        // we're dealing with an AliasEqualsArg, we have a special helper for that
        const [originalArg, value] = parseEqualsArg(arg);
        setCLIArg(flags, arg.split('=')[0], normalizeFlagName(originalArg), value);
    }
    // AliasArg → "-" AliasName ( " " CLIValue )? ;
    else if (CLI_FLAG_REGEX.test(arg)) {
        // this is a short alias, like `-c` for Config
        setCLIArg(flags, arg, normalizeFlagName(arg), parseCLIValue(args));
    }
    // NegativeDashArg → "--no-" ArgName ;
    else if (arg.startsWith('--no-') && arg.length > '--no-'.length) {
        // this is a `NegativeDashArg` term, so we need to normalize the negative
        // flag name and then set an appropriate value
        const normalized = normalizeNegativeFlagName(arg);
        setCLIArg(flags, arg, normalized, '');
    }
    // NegativeArg → "--no" ArgName ;
    else if (arg.startsWith('--no') &&
        !readOnlyArrayHasStringMember(BOOLEAN_CLI_FLAGS, normalizeFlagName(arg)) &&
        readOnlyArrayHasStringMember(BOOLEAN_CLI_FLAGS, normalizeNegativeFlagName(arg))) {
        // possibly dealing with a `NegativeArg` here. There is a little ambiguity
        // here because we have arguments that already begin with `no` like
        // `notify`, so we need to test if a normalized form of the raw argument is
        // a valid and supported boolean flag.
        setCLIArg(flags, arg, normalizeNegativeFlagName(arg), '');
    }
    // SimpleArg → "--" ArgName ( " " CLIValue )? ;
    else if (arg.startsWith('--') && arg.length > '--'.length) {
        setCLIArg(flags, arg, normalizeFlagName(arg), parseCLIValue(args));
    }
    // if we get here it is not an argument in our list of supported arguments.
    // This doesn't necessarily mean we want to report an error or anything
    // though! Instead, with unknown / unrecognized arguments we stick them into
    // the `unknownArgs` array, which is used when we pass CLI args to Jest, for
    // instance. So we just return void here.
};
/**
 * Normalize a 'negative' flag name, just to do a little pre-processing before
 * we pass it to `setCLIArg`.
 *
 * @param flagName the flag name to normalize
 * @returns a normalized flag name
 */
const normalizeNegativeFlagName = (flagName) => {
    const trimmed = flagName.replace(/^--no[-]?/, '');
    return normalizeFlagName(trimmed.charAt(0).toLowerCase() + trimmed.slice(1));
};
/**
 * Normalize a flag name by:
 *
 * - replacing any leading dashes (`--foo` -> `foo`)
 * - converting `dash-case` to camelCase (if necessary)
 *
 * Normalizing in this context basically means converting the various
 * supported flag spelling variants to the variant defined in our lists of
 * supported arguments (e.g. BOOLEAN_CLI_FLAGS, etc). So, for instance,
 * `--log-level` should be converted to `logLevel`.
 *
 * @param flagName the flag name to normalize
 * @returns a normalized flag name
 *
 */
const normalizeFlagName = (flagName) => {
    const trimmed = flagName.replace(/^-+/, '');
    return trimmed.includes('-') ? toCamelCase(trimmed) : trimmed;
};
/**
 * Set a value on a provided {@link ConfigFlags} object, given an argument
 * name and a raw string value. This function dispatches to other functions
 * which make sure that the string value can be properly parsed into a JS
 * runtime value of the right type (e.g. number, string, etc).
 *
 * @throws if a value cannot be parsed to the right type for a given flag
 * @param flags a {@link ConfigFlags} object
 * @param rawArg the raw argument name matched by the parser
 * @param normalizedArg an argument with leading control characters (`--`,
 * `--no-`, etc) removed
 * @param value the raw value to be set onto the config flags object
 */
const setCLIArg = (flags, rawArg, normalizedArg, value) => {
    normalizedArg = dereferenceAlias(normalizedArg);
    // We're setting a boolean!
    if (readOnlyArrayHasStringMember(BOOLEAN_CLI_FLAGS, normalizedArg)) {
        flags[normalizedArg] =
            typeof value === 'string'
                ? Boolean(value)
                : // no value was supplied, default to true
                    true;
        flags.knownArgs.push(rawArg);
    }
    // We're setting a string!
    else if (readOnlyArrayHasStringMember(STRING_CLI_FLAGS, normalizedArg)) {
        if (typeof value === 'string') {
            flags[normalizedArg] = value;
            flags.knownArgs.push(rawArg);
            flags.knownArgs.push(value);
        }
        else {
            throwCLIParsingError(rawArg, 'expected a string argument but received nothing');
        }
    }
    // We're setting a string, but it's one where the user can pass multiple values,
    // like `--reporters="default" --reporters="jest-junit"`
    else if (readOnlyArrayHasStringMember(STRING_ARRAY_CLI_FLAGS, normalizedArg)) {
        if (typeof value === 'string') {
            if (!Array.isArray(flags[normalizedArg])) {
                flags[normalizedArg] = [];
            }
            const targetArray = flags[normalizedArg];
            // this is irritating, but TS doesn't know that the `!Array.isArray`
            // check above guarantees we have an array to work with here, and it
            // doesn't want to narrow the type of `flags[normalizedArg]`, so we need
            // to grab a reference to that array and then `Array.isArray` that. Bah!
            if (Array.isArray(targetArray)) {
                targetArray.push(value);
                flags.knownArgs.push(rawArg);
                flags.knownArgs.push(value);
            }
        }
        else {
            throwCLIParsingError(rawArg, 'expected a string argument but received nothing');
        }
    }
    // We're setting a number!
    else if (readOnlyArrayHasStringMember(NUMBER_CLI_FLAGS, normalizedArg)) {
        if (typeof value === 'string') {
            const parsed = parseInt(value, 10);
            if (isNaN(parsed)) {
                throwNumberParsingError(rawArg, value);
            }
            else {
                flags[normalizedArg] = parsed;
                flags.knownArgs.push(rawArg);
                flags.knownArgs.push(value);
            }
        }
        else {
            throwCLIParsingError(rawArg, 'expected a number argument but received nothing');
        }
    }
    // We're setting a value which could be either a string _or_ a number
    else if (readOnlyArrayHasStringMember(STRING_NUMBER_CLI_FLAGS, normalizedArg)) {
        if (typeof value === 'string') {
            if (CLI_ARG_STRING_REGEX.test(value)) {
                // if it matches the regex we treat it like a string
                flags[normalizedArg] = value;
            }
            else {
                const parsed = Number(value);
                if (isNaN(parsed)) {
                    // parsing didn't go so well, we gotta get out of here
                    // this is unlikely given our regex guard above
                    // but hey, this is ultimately JS so let's be safe
                    throwNumberParsingError(rawArg, value);
                }
                else {
                    flags[normalizedArg] = parsed;
                }
            }
            flags.knownArgs.push(rawArg);
            flags.knownArgs.push(value);
        }
        else {
            throwCLIParsingError(rawArg, 'expected a string or a number but received nothing');
        }
    }
    // We're setting the log level, which can only be a set of specific string values
    else if (readOnlyArrayHasStringMember(LOG_LEVEL_CLI_FLAGS, normalizedArg)) {
        if (typeof value === 'string') {
            if (isLogLevel(value)) {
                flags[normalizedArg] = value;
                flags.knownArgs.push(rawArg);
                flags.knownArgs.push(value);
            }
            else {
                throwCLIParsingError(rawArg, `expected to receive a valid log level but received "${String(value)}"`);
            }
        }
        else {
            throwCLIParsingError(rawArg, 'expected to receive a valid log level but received nothing');
        }
    }
};
/**
 * We use this regular expression to detect CLI parameters which
 * should be parsed as string values (as opposed to numbers) for
 * the argument types for which we support both a string and a
 * number value.
 *
 * The regex tests for the presence of at least one character which is
 * _not_ a digit (`\d`), a period (`\.`), or one of the characters `"e"`,
 * `"E"`, `"+"`, or `"-"` (the latter four characters are necessary to
 * support the admittedly unlikely use of scientific notation, like `"4e+0"`
 * for `4`).
 *
 * Thus we'll match a string like `"50%"`, but not a string like `"50"` or
 * `"5.0"`. If it matches a given string we conclude that the string should
 * be parsed as a string literal, rather than using `Number` to convert it
 * to a number.
 */
const CLI_ARG_STRING_REGEX = /[^\d\.Ee\+\-]+/g;
const Empty = Symbol('Empty');
/**
 * A little helper which tries to parse a CLI value (as opposed to a flag) off
 * of the argument array.
 *
 * We support a variety of different argument formats, but all of them start
 * with `-`, so we can check the first character to test whether the next token
 * in our array of CLI arguments is a flag name or a value.
 *
 * @param args an array of CLI args
 * @returns either a string result or an Empty sentinel
 */
const parseCLIValue = (args) => {
    // it's possible the arguments array is empty, if so, return empty
    if (args[0] === undefined) {
        return Empty;
    }
    // all we're concerned with here is that it does not start with `"-"`,
    // which would indicate it should be parsed as a CLI flag and not a value.
    if (!args[0].startsWith('-')) {
        // It's not a flag, so we return the value and defer any specific parsing
        // until later on.
        const value = args.shift();
        if (typeof value === 'string') {
            return value;
        }
    }
    return Empty;
};
/**
 * Parse an 'equals' argument, which is a CLI argument-value pair in the
 * format `--foobar=12` (as opposed to a space-separated format like
 * `--foobar 12`).
 *
 * To parse this we split on the `=`, returning the first part as the argument
 * name and the second part as the value. We join the value on `"="` in case
 * there is another `"="` in the argument.
 *
 * This function is safe to call with any arg, and can therefore be used as
 * an argument 'normalizer'. If CLI argument is not an 'equals' argument then
 * the return value will be a tuple of the original argument and an empty
 * string `""` for the value.
 *
 * In code terms, if you do:
 *
 * ```ts
 * const [arg, value] = parseEqualsArg("--myArgument")
 * ```
 *
 * Then `arg` will be `"--myArgument"` and `value` will be `""`, whereas if
 * you do:
 *
 *
 * ```ts
 * const [arg, value] = parseEqualsArg("--myArgument=myValue")
 * ```
 *
 * Then `arg` will be `"--myArgument"` and `value` will be `"myValue"`.
 *
 * @param arg the arg in question
 * @returns a tuple containing the arg name and the value (if present)
 */
const parseEqualsArg = (arg) => {
    const [originalArg, ...splitSections] = arg.split('=');
    const value = splitSections.join('=');
    return [originalArg, value === '' ? Empty : value];
};
/**
 * Small helper for getting type-system-level assurance that a `string` can be
 * narrowed to a `LogLevel`
 *
 * @param maybeLogLevel the string to check
 * @returns whether this is a `LogLevel`
 */
const isLogLevel = (maybeLogLevel) => readOnlyArrayHasStringMember(LOG_LEVELS, maybeLogLevel);
/**
 * A little helper for constructing and throwing an error message with info
 * about what went wrong
 *
 * @param flag the flag which encountered the error
 * @param message a message specific to the error which was encountered
 */
const throwCLIParsingError = (flag, message) => {
    throw new Error(`when parsing CLI flag "${flag}": ${message}`);
};
/**
 * Throw a specific error for the situation where we ran into an issue parsing
 * a number.
 *
 * @param flag the flag for which we encountered the issue
 * @param value what we were trying to parse
 */
const throwNumberParsingError = (flag, value) => {
    throwCLIParsingError(flag, `expected a number but received "${value}"`);
};
/**
 * A little helper to 'dereference' a flag alias, which if you squint a little
 * you can think of like a pointer to a full flag name. Thus 'c' is like a
 * pointer to 'config', so here we're doing something like `*c`. Of course, this
 * being JS, this is just a metaphor!
 *
 * If no 'dereference' is found for the possible alias we just return the
 * passed string unmodified.
 *
 * @param maybeAlias a string which _could_ be an alias to a full flag name
 * @returns the full aliased flag name, if found, or the passed string if not
 */
const dereferenceAlias = (maybeAlias) => {
    const possibleDereference = CLI_FLAG_ALIASES[maybeAlias];
    if (typeof possibleDereference === 'string') {
        return possibleDereference;
    }
    return maybeAlias;
};

const dependencies = [
	{
		name: "@stencil/core",
		version: "2.22.3",
		main: "compiler/stencil.js",
		resources: [
			"package.json",
			"compiler/lib.d.ts",
			"compiler/lib.dom.d.ts",
			"compiler/lib.dom.iterable.d.ts",
			"compiler/lib.es2015.collection.d.ts",
			"compiler/lib.es2015.core.d.ts",
			"compiler/lib.es2015.d.ts",
			"compiler/lib.es2015.generator.d.ts",
			"compiler/lib.es2015.iterable.d.ts",
			"compiler/lib.es2015.promise.d.ts",
			"compiler/lib.es2015.proxy.d.ts",
			"compiler/lib.es2015.reflect.d.ts",
			"compiler/lib.es2015.symbol.d.ts",
			"compiler/lib.es2015.symbol.wellknown.d.ts",
			"compiler/lib.es2016.array.include.d.ts",
			"compiler/lib.es2016.d.ts",
			"compiler/lib.es2016.full.d.ts",
			"compiler/lib.es2017.d.ts",
			"compiler/lib.es2017.full.d.ts",
			"compiler/lib.es2017.intl.d.ts",
			"compiler/lib.es2017.object.d.ts",
			"compiler/lib.es2017.sharedmemory.d.ts",
			"compiler/lib.es2017.string.d.ts",
			"compiler/lib.es2017.typedarrays.d.ts",
			"compiler/lib.es2018.asyncgenerator.d.ts",
			"compiler/lib.es2018.asynciterable.d.ts",
			"compiler/lib.es2018.d.ts",
			"compiler/lib.es2018.full.d.ts",
			"compiler/lib.es2018.intl.d.ts",
			"compiler/lib.es2018.promise.d.ts",
			"compiler/lib.es2018.regexp.d.ts",
			"compiler/lib.es2019.array.d.ts",
			"compiler/lib.es2019.d.ts",
			"compiler/lib.es2019.full.d.ts",
			"compiler/lib.es2019.intl.d.ts",
			"compiler/lib.es2019.object.d.ts",
			"compiler/lib.es2019.string.d.ts",
			"compiler/lib.es2019.symbol.d.ts",
			"compiler/lib.es2020.bigint.d.ts",
			"compiler/lib.es2020.d.ts",
			"compiler/lib.es2020.date.d.ts",
			"compiler/lib.es2020.full.d.ts",
			"compiler/lib.es2020.intl.d.ts",
			"compiler/lib.es2020.number.d.ts",
			"compiler/lib.es2020.promise.d.ts",
			"compiler/lib.es2020.sharedmemory.d.ts",
			"compiler/lib.es2020.string.d.ts",
			"compiler/lib.es2020.symbol.wellknown.d.ts",
			"compiler/lib.es2021.d.ts",
			"compiler/lib.es2021.full.d.ts",
			"compiler/lib.es2021.intl.d.ts",
			"compiler/lib.es2021.promise.d.ts",
			"compiler/lib.es2021.string.d.ts",
			"compiler/lib.es2021.weakref.d.ts",
			"compiler/lib.es2022.array.d.ts",
			"compiler/lib.es2022.d.ts",
			"compiler/lib.es2022.error.d.ts",
			"compiler/lib.es2022.full.d.ts",
			"compiler/lib.es2022.intl.d.ts",
			"compiler/lib.es2022.object.d.ts",
			"compiler/lib.es2022.sharedmemory.d.ts",
			"compiler/lib.es2022.string.d.ts",
			"compiler/lib.es5.d.ts",
			"compiler/lib.es6.d.ts",
			"compiler/lib.esnext.d.ts",
			"compiler/lib.esnext.full.d.ts",
			"compiler/lib.esnext.intl.d.ts",
			"compiler/lib.esnext.promise.d.ts",
			"compiler/lib.esnext.string.d.ts",
			"compiler/lib.esnext.weakref.d.ts",
			"compiler/lib.scripthost.d.ts",
			"compiler/lib.webworker.d.ts",
			"compiler/lib.webworker.importscripts.d.ts",
			"compiler/lib.webworker.iterable.d.ts",
			"internal/index.d.ts",
			"internal/index.js",
			"internal/package.json",
			"internal/stencil-ext-modules.d.ts",
			"internal/stencil-private.d.ts",
			"internal/stencil-public-compiler.d.ts",
			"internal/stencil-public-docs.d.ts",
			"internal/stencil-public-runtime.d.ts",
			"mock-doc/index.js",
			"mock-doc/package.json",
			"internal/client/css-shim.js",
			"internal/client/dom.js",
			"internal/client/index.js",
			"internal/client/package.json",
			"internal/client/patch-browser.js",
			"internal/client/patch-esm.js",
			"internal/client/shadow-css.js",
			"internal/hydrate/index.js",
			"internal/hydrate/package.json",
			"internal/hydrate/runner.js",
			"internal/hydrate/shadow-css.js",
			"internal/stencil-core/index.d.ts",
			"internal/stencil-core/index.js"
		]
	},
	{
		name: "rollup",
		version: "2.42.3",
		main: "dist/es/rollup.browser.js"
	},
	{
		name: "terser",
		version: "5.16.1",
		main: "dist/bundle.min.js"
	},
	{
		name: "typescript",
		version: "4.9.4",
		main: "lib/typescript.js"
	}
];

const IS_NODE_ENV = typeof global !== 'undefined' &&
    typeof require === 'function' &&
    !!global.process &&
    typeof __filename === 'string' &&
    (!global.origin || typeof global.origin !== 'string');
const IS_BROWSER_ENV = typeof location !== 'undefined' && typeof navigator !== 'undefined' && typeof XMLHttpRequest !== 'undefined';

/**
 * Creates an instance of a logger
 * @returns the new logger instance
 */
const createLogger = () => {
    let useColors = IS_BROWSER_ENV;
    let level = 'info';
    return {
        enableColors: (uc) => (useColors = uc),
        getLevel: () => level,
        setLevel: (l) => (level = l),
        emoji: (e) => e,
        info: console.log.bind(console),
        warn: console.warn.bind(console),
        error: console.error.bind(console),
        debug: console.debug.bind(console),
        red: (msg) => msg,
        green: (msg) => msg,
        yellow: (msg) => msg,
        blue: (msg) => msg,
        magenta: (msg) => msg,
        cyan: (msg) => msg,
        gray: (msg) => msg,
        bold: (msg) => msg,
        dim: (msg) => msg,
        bgRed: (msg) => msg,
        createTimeSpan: (_startMsg, _debug = false) => ({
            duration: () => 0,
            finish: () => 0,
        }),
        printDiagnostics(diagnostics) {
            diagnostics.forEach((diagnostic) => logDiagnostic(diagnostic, useColors));
        },
    };
};
const logDiagnostic = (diagnostic, useColors) => {
    let color = BLUE;
    let prefix = 'Build';
    let msg = '';
    if (diagnostic.level === 'error') {
        color = RED;
        prefix = 'Error';
    }
    else if (diagnostic.level === 'warn') {
        color = YELLOW;
        prefix = 'Warning';
    }
    if (diagnostic.header) {
        prefix = diagnostic.header;
    }
    const filePath = diagnostic.relFilePath || diagnostic.absFilePath;
    if (filePath) {
        msg += filePath;
        if (typeof diagnostic.lineNumber === 'number' && diagnostic.lineNumber > 0) {
            msg += ', line ' + diagnostic.lineNumber;
            if (typeof diagnostic.columnNumber === 'number' && diagnostic.columnNumber > 0) {
                msg += ', column ' + diagnostic.columnNumber;
            }
        }
        msg += '\n';
    }
    msg += diagnostic.messageText;
    if (diagnostic.lines && diagnostic.lines.length > 0) {
        diagnostic.lines.forEach((l) => {
            msg += '\n' + l.lineNumber + ':  ' + l.text;
        });
        msg += '\n';
    }
    if (useColors) {
        const styledPrefix = [
            '%c' + prefix,
            `background: ${color}; color: white; padding: 2px 3px; border-radius: 2px; font-size: 0.8em;`,
        ];
        console.log(...styledPrefix, msg);
    }
    else if (diagnostic.level === 'error') {
        console.error(msg);
    }
    else if (diagnostic.level === 'warn') {
        console.warn(msg);
    }
    else {
        console.log(msg);
    }
};
const YELLOW = `#f39c12`;
const RED = `#c0392b`;
const BLUE = `#3498db`;

/**
 * Attempt to find a Stencil configuration file on the file system
 * @param opts the options needed to find the configuration file
 * @returns the results of attempting to find a configuration file on disk
 */
const findConfig = async (opts) => {
    const sys = opts.sys;
    const cwd = sys.getCurrentDirectory();
    const rootDir = normalizePath(cwd);
    let configPath = opts.configPath;
    if (isString(configPath)) {
        if (!sys.platformPath.isAbsolute(configPath)) {
            // passed in a custom stencil config location,
            // but it's relative, so prefix the cwd
            configPath = normalizePath(sys.platformPath.join(cwd, configPath));
        }
        else {
            // config path already an absolute path, we're good here
            configPath = normalizePath(opts.configPath);
        }
    }
    else {
        // nothing was passed in, use the current working directory
        configPath = rootDir;
    }
    const results = {
        configPath,
        rootDir: normalizePath(cwd),
        diagnostics: [],
    };
    const stat = await sys.stat(configPath);
    if (stat.error) {
        const diagnostic = buildError(results.diagnostics);
        diagnostic.absFilePath = configPath;
        diagnostic.header = `Invalid config path`;
        diagnostic.messageText = `Config path "${configPath}" not found`;
        return results;
    }
    if (stat.isFile) {
        results.configPath = configPath;
        results.rootDir = sys.platformPath.dirname(configPath);
    }
    else if (stat.isDirectory) {
        // this is only a directory, so let's make some assumptions
        for (const configName of ['stencil.config.ts', 'stencil.config.js']) {
            const testConfigFilePath = sys.platformPath.join(configPath, configName);
            const stat = await sys.stat(testConfigFilePath);
            if (stat.isFile) {
                results.configPath = testConfigFilePath;
                results.rootDir = sys.platformPath.dirname(testConfigFilePath);
                break;
            }
        }
    }
    return results;
};

const loadCoreCompiler = async (sys) => {
    await sys.dynamicImport(sys.getCompilerExecutingPath());
    return globalThis.stencil;
};

/**
 * Log the name of this package (`@stencil/core`) to an output stream
 *
 * The output stream is determined by the {@link Logger} instance that is provided as an argument to this function
 *
 * The name of the package may not be logged, by design, for certain `task` types and logging levels
 *
 * @param logger the logging entity to use to output the name of the package
 * @param task the current task
 */
const startupLog = (logger, task) => {
    if (task === 'info' || task === 'serve' || task === 'version') {
        return;
    }
    logger.info(logger.cyan(`@stencil/core`));
};
/**
 * Log this package's version to an output stream
 *
 * The output stream is determined by the {@link Logger} instance that is provided as an argument to this function
 *
 * The package version may not be logged, by design, for certain `task` types and logging levels
 *
 * @param logger the logging entity to use for output
 * @param task the current task
 * @param coreCompiler the compiler instance to derive version information from
 */
const startupLogVersion = (logger, task, coreCompiler) => {
    if (task === 'info' || task === 'serve' || task === 'version') {
        return;
    }
    const isDevBuild = coreCompiler.version.includes('-dev.');
    let startupMsg;
    if (isDevBuild) {
        startupMsg = logger.yellow('[LOCAL DEV]');
    }
    else {
        startupMsg = logger.cyan(`v${coreCompiler.version}`);
    }
    startupMsg += logger.emoji(' ' + coreCompiler.vermoji);
    logger.info(startupMsg);
};
/**
 * Log details from a {@link CompilerSystem} used by Stencil to an output stream
 *
 * The output stream is determined by the {@link Logger} instance that is provided as an argument to this function
 *
 * @param sys the `CompilerSystem` to report details on
 * @param logger the logging entity to use for output
 * @param flags user set flags for the current invocation of Stencil
 * @param coreCompiler the compiler instance being used for this invocation of Stencil
 */
const loadedCompilerLog = (sys, logger, flags, coreCompiler) => {
    const sysDetails = sys.details;
    const runtimeInfo = `${sys.name} ${sys.version}`;
    const platformInfo = sysDetails
        ? `${sysDetails.platform}, ${sysDetails.cpuModel}`
        : `Unknown Platform, Unknown CPU Model`;
    const statsInfo = sysDetails
        ? `cpus: ${sys.hardwareConcurrency}, freemem: ${Math.round(sysDetails.freemem() / 1000000)}MB, totalmem: ${Math.round(sysDetails.totalmem / 1000000)}MB`
        : 'Unknown CPU Core Count, Unknown Memory';
    if (logger.getLevel() === 'debug') {
        logger.debug(runtimeInfo);
        logger.debug(platformInfo);
        logger.debug(statsInfo);
        logger.debug(`compiler: ${sys.getCompilerExecutingPath()}`);
        logger.debug(`build: ${coreCompiler.buildId}`);
    }
    else if (flags.ci) {
        logger.info(runtimeInfo);
        logger.info(platformInfo);
        logger.info(statsInfo);
    }
};
/**
 * Log various warnings to an output stream
 *
 * The output stream is determined by the {@link Logger} instance attached to the `config` argument to this function
 *
 * @param coreCompiler the compiler instance being used for this invocation of Stencil
 * @param config a validated configuration object to be used for this run of Stencil
 */
const startupCompilerLog = (coreCompiler, config) => {
    if (config.suppressLogs === true) {
        return;
    }
    const { logger } = config;
    const isDebug = logger.getLevel() === 'debug';
    const isPrerelease = coreCompiler.version.includes('-');
    const isDevBuild = coreCompiler.version.includes('-dev.');
    if (isPrerelease && !isDevBuild) {
        logger.warn(logger.yellow(`This is a prerelease build, undocumented changes might happen at any time. Technical support is not available for prereleases, but any assistance testing is appreciated.`));
    }
    if (config.devMode && !isDebug) {
        if (config.buildEs5) {
            logger.warn(`Generating ES5 during development is a very task expensive, initial and incremental builds will be much slower. Drop the '--es5' flag and use a modern browser for development.`);
        }
        if (!config.enableCache) {
            logger.warn(`Disabling cache during development will slow down incremental builds.`);
        }
    }
};

const startCheckVersion = async (config, currentVersion) => {
    if (config.devMode && !config.flags.ci && !currentVersion.includes('-dev.') && isFunction(config.sys.checkVersion)) {
        return config.sys.checkVersion(config.logger, currentVersion);
    }
    return null;
};
const printCheckVersionResults = async (versionChecker) => {
    if (versionChecker) {
        const checkVersionResults = await versionChecker;
        if (isFunction(checkVersionResults)) {
            checkVersionResults();
        }
    }
};

const taskPrerender = async (coreCompiler, config) => {
    startupCompilerLog(coreCompiler, config);
    const hydrateAppFilePath = config.flags.unknownArgs[0];
    if (typeof hydrateAppFilePath !== 'string') {
        config.logger.error(`Missing hydrate app script path`);
        return config.sys.exit(1);
    }
    const srcIndexHtmlPath = config.srcIndexHtml;
    const diagnostics = await runPrerenderTask(coreCompiler, config, hydrateAppFilePath, null, srcIndexHtmlPath);
    config.logger.printDiagnostics(diagnostics);
    if (diagnostics.some((d) => d.level === 'error')) {
        return config.sys.exit(1);
    }
};
const runPrerenderTask = async (coreCompiler, config, hydrateAppFilePath, componentGraph, srcIndexHtmlPath) => {
    const diagnostics = [];
    try {
        const prerenderer = await coreCompiler.createPrerenderer(config);
        const results = await prerenderer.start({
            hydrateAppFilePath,
            componentGraph,
            srcIndexHtmlPath,
        });
        diagnostics.push(...results.diagnostics);
    }
    catch (e) {
        catchError(diagnostics, e);
    }
    return diagnostics;
};

const taskWatch = async (coreCompiler, config) => {
    let devServer = null;
    let exitCode = 0;
    try {
        startupCompilerLog(coreCompiler, config);
        const versionChecker = startCheckVersion(config, coreCompiler.version);
        const compiler = await coreCompiler.createCompiler(config);
        const watcher = await compiler.createWatcher();
        if (config.flags.serve) {
            const devServerPath = config.sys.getDevServerExecutingPath();
            const { start } = await config.sys.dynamicImport(devServerPath);
            devServer = await start(config.devServer, config.logger, watcher);
        }
        config.sys.onProcessInterrupt(() => {
            config.logger.debug(`close watch`);
            compiler && compiler.destroy();
        });
        const rmVersionCheckerLog = watcher.on('buildFinish', async () => {
            // log the version check one time
            rmVersionCheckerLog();
            printCheckVersionResults(versionChecker);
        });
        if (devServer) {
            const rmDevServerLog = watcher.on('buildFinish', () => {
                // log the dev server url one time
                rmDevServerLog();
                config.logger.info(`${config.logger.cyan(devServer.browserUrl)}\n`);
            });
        }
        const closeResults = await watcher.start();
        if (closeResults.exitCode > 0) {
            exitCode = closeResults.exitCode;
        }
    }
    catch (e) {
        exitCode = 1;
        config.logger.error(e);
    }
    if (devServer) {
        await devServer.close();
    }
    if (exitCode > 0) {
        return config.sys.exit(exitCode);
    }
};

const isOutputTargetHydrate = (o) => o.type === DIST_HYDRATE_SCRIPT;
const isOutputTargetDocs = (o) => o.type === DOCS_README || o.type === DOCS_JSON || o.type === DOCS_CUSTOM || o.type === DOCS_VSCODE;
const DIST_HYDRATE_SCRIPT = 'dist-hydrate-script';
const DOCS_CUSTOM = 'docs-custom';
const DOCS_JSON = 'docs-json';
const DOCS_README = 'docs-readme';
const DOCS_VSCODE = 'docs-vscode';
const WWW = 'www';

const tryFn = async (fn, ...args) => {
    try {
        return await fn(...args);
    }
    catch (_a) {
        // ignore
    }
    return null;
};
const isInteractive = (sys, flags, object) => {
    const terminalInfo = object ||
        Object.freeze({
            tty: sys.isTTY() ? true : false,
            ci: ['CI', 'BUILD_ID', 'BUILD_NUMBER', 'BITBUCKET_COMMIT', 'CODEBUILD_BUILD_ARN'].filter((v) => { var _a; return !!((_a = sys.getEnvironmentVar) === null || _a === void 0 ? void 0 : _a.call(sys, v)); }).length > 0 || !!flags.ci,
        });
    return terminalInfo.tty && !terminalInfo.ci;
};
const UUID_REGEX = new RegExp(/^[0-9A-F]{8}-[0-9A-F]{4}-4[0-9A-F]{3}-[89AB][0-9A-F]{3}-[0-9A-F]{12}$/i);
// Plucked from https://github.com/ionic-team/capacitor/blob/b893a57aaaf3a16e13db9c33037a12f1a5ac92e0/cli/src/util/uuid.ts
function uuidv4() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
        const r = (Math.random() * 16) | 0;
        const v = c == 'x' ? r : (r & 0x3) | 0x8;
        return v.toString(16);
    });
}
/**
 * Reads and parses a JSON file from the given `path`
 * @param sys The system where the command is invoked
 * @param path the path on the file system to read and parse
 * @returns the parsed JSON
 */
async function readJson(sys, path) {
    const file = await sys.readFile(path);
    return !!file && JSON.parse(file);
}
/**
 * Does the command have the debug flag?
 * @param flags The configuration flags passed into the Stencil command
 * @returns true if --debug has been passed, otherwise false
 */
function hasDebug(flags) {
    return !!flags.debug;
}
/**
 * Does the command have the verbose and debug flags?
 * @param flags The configuration flags passed into the Stencil command
 * @returns true if both --debug and --verbose have been passed, otherwise false
 */
function hasVerbose(flags) {
    return !!flags.verbose && hasDebug(flags);
}

const isTest$1 = () => process.env.JEST_WORKER_ID !== undefined;
const defaultConfig = (sys) => sys.resolvePath(`${sys.homeDir()}/.ionic/${isTest$1() ? 'tmp-config.json' : 'config.json'}`);
const defaultConfigDirectory = (sys) => sys.resolvePath(`${sys.homeDir()}/.ionic`);
/**
 * Reads an Ionic configuration file from disk, parses it, and performs any necessary corrections to it if certain
 * values are deemed to be malformed
 * @param sys The system where the command is invoked
 * @returns the config read from disk that has been potentially been updated
 */
async function readConfig(sys) {
    let config = await readJson(sys, defaultConfig(sys));
    if (!config) {
        config = {
            'tokens.telemetry': uuidv4(),
            'telemetry.stencil': true,
        };
        await writeConfig(sys, config);
    }
    else if (!config['tokens.telemetry'] || !UUID_REGEX.test(config['tokens.telemetry'])) {
        const newUuid = uuidv4();
        await writeConfig(sys, { ...config, 'tokens.telemetry': newUuid });
        config['tokens.telemetry'] = newUuid;
    }
    return config;
}
/**
 * Writes an Ionic configuration file to disk.
 * @param sys The system where the command is invoked
 * @param config The config passed into the Stencil command
 * @returns boolean If the command was successful
 */
async function writeConfig(sys, config) {
    let result = false;
    try {
        await sys.createDir(defaultConfigDirectory(sys), { recursive: true });
        await sys.writeFile(defaultConfig(sys), JSON.stringify(config, null, 2));
        result = true;
    }
    catch (error) {
        console.error(`Stencil Telemetry: couldn't write configuration file to ${defaultConfig(sys)} - ${error}.`);
    }
    return result;
}
/**
 * Update a subset of the Ionic config.
 * @param sys The system where the command is invoked
 * @param newOptions The new options to save
 * @returns boolean If the command was successful
 */
async function updateConfig(sys, newOptions) {
    const config = await readConfig(sys);
    return await writeConfig(sys, Object.assign(config, newOptions));
}

/**
 * Used to determine if tracking should occur.
 * @param config The config passed into the Stencil command
 * @param sys The system where the command is invoked
 * @param ci whether or not the process is running in a Continuous Integration (CI) environment
 * @returns true if telemetry should be sent, false otherwise
 */
async function shouldTrack(config, sys, ci) {
    return !ci && isInteractive(sys, config.flags) && (await checkTelemetry(sys));
}

/**
 * Used to within taskBuild to provide the component_count property.
 *
 * @param sys The system where the command is invoked
 * @param config The config passed into the Stencil command
 * @param coreCompiler The compiler used to do builds
 * @param result The results of a compiler build.
 */
async function telemetryBuildFinishedAction(sys, config, coreCompiler, result) {
    const tracking = await shouldTrack(config, sys, !!config.flags.ci);
    if (!tracking) {
        return;
    }
    const component_count = result.componentGraph ? Object.keys(result.componentGraph).length : undefined;
    const data = await prepareData(coreCompiler, config, sys, result.duration, component_count);
    await sendMetric(sys, config, 'stencil_cli_command', data);
    config.logger.debug(`${config.logger.blue('Telemetry')}: ${config.logger.gray(JSON.stringify(data))}`);
}
/**
 * A function to wrap a compiler task function around. Will send telemetry if, and only if, the machine allows.
 *
 * @param sys The system where the command is invoked
 * @param config The config passed into the Stencil command
 * @param coreCompiler The compiler used to do builds
 * @param action A Promise-based function to call in order to get the duration of any given command.
 * @returns void
 */
async function telemetryAction(sys, config, coreCompiler, action) {
    const tracking = await shouldTrack(config, sys, !!config.flags.ci);
    let duration = undefined;
    let error;
    if (action) {
        const start = new Date();
        try {
            await action();
        }
        catch (e) {
            error = e;
        }
        const end = new Date();
        duration = end.getTime() - start.getTime();
    }
    // We'll get componentCount details inside the taskBuild, so let's not send two messages.
    if (!tracking || (config.flags.task == 'build' && !config.flags.args.includes('--watch'))) {
        return;
    }
    const data = await prepareData(coreCompiler, config, sys, duration);
    await sendMetric(sys, config, 'stencil_cli_command', data);
    config.logger.debug(`${config.logger.blue('Telemetry')}: ${config.logger.gray(JSON.stringify(data))}`);
    if (error) {
        throw error;
    }
}
/**
 * Helper function to determine if a Stencil configuration builds an application.
 *
 * This function is a rough approximation whether an application is generated as a part of a Stencil build, based on
 * contents of the project's `stencil.config.ts` file.
 *
 * @param config the configuration used by the Stencil project
 * @returns true if we believe the project generates an application, false otherwise
 */
function hasAppTarget(config) {
    return config.outputTargets.some((target) => target.type === WWW && (!!target.serviceWorker || (!!target.baseUrl && target.baseUrl !== '/')));
}
function isUsingYarn(sys) {
    var _a;
    return ((_a = sys.getEnvironmentVar('npm_execpath')) === null || _a === void 0 ? void 0 : _a.includes('yarn')) || false;
}
/**
 * Build a list of the different types of output targets used in a Stencil configuration.
 *
 * Duplicate entries will not be returned from the list
 *
 * @param config the configuration used by the Stencil project
 * @returns a unique list of output target types found in the Stencil configuration
 */
function getActiveTargets(config) {
    const result = config.outputTargets.map((t) => t.type);
    return Array.from(new Set(result));
}
/**
 * Prepare data for telemetry
 *
 * @param coreCompiler the core compiler
 * @param config the current Stencil config
 * @param sys the compiler system instance in use
 * @param duration_ms the duration of the action being tracked
 * @param component_count the number of components being built (optional)
 * @returns a Promise wrapping data for the telemetry endpoint
 */
const prepareData = async (coreCompiler, config, sys, duration_ms, component_count = undefined) => {
    var _a, _b, _c;
    const { typescript, rollup } = coreCompiler.versions || { typescript: 'unknown', rollup: 'unknown' };
    const { packages, packagesNoVersions } = await getInstalledPackages(sys, config);
    const targets = getActiveTargets(config);
    const yarn = isUsingYarn(sys);
    const stencil = coreCompiler.version || 'unknown';
    const system = `${sys.name} ${sys.version}`;
    const os_name = (_a = sys.details) === null || _a === void 0 ? void 0 : _a.platform;
    const os_version = (_b = sys.details) === null || _b === void 0 ? void 0 : _b.release;
    const cpu_model = (_c = sys.details) === null || _c === void 0 ? void 0 : _c.cpuModel;
    const build = coreCompiler.buildId || 'unknown';
    const has_app_pwa_config = hasAppTarget(config);
    const anonymizedConfig = anonymizeConfigForTelemetry(config);
    const is_browser_env = IS_BROWSER_ENV;
    return {
        arguments: config.flags.args,
        build,
        component_count,
        config: anonymizedConfig,
        cpu_model,
        duration_ms,
        has_app_pwa_config,
        is_browser_env,
        os_name,
        os_version,
        packages,
        packages_no_versions: packagesNoVersions,
        rollup,
        stencil,
        system,
        system_major: getMajorVersion(system),
        targets,
        task: config.flags.task,
        typescript,
        yarn,
    };
};
// props in output targets for which we retain their original values when
// preparing a config for telemetry
//
// we omit the values of all other fields on output targets.
const OUTPUT_TARGET_KEYS_TO_KEEP = ['type'];
// top-level config props that we anonymize for telemetry
const CONFIG_PROPS_TO_ANONYMIZE = [
    'rootDir',
    'fsNamespace',
    'packageJsonFilePath',
    'namespace',
    'srcDir',
    'srcIndexHtml',
    'buildLogFilePath',
    'cacheDir',
    'configPath',
    'tsconfig',
];
// Props we delete entirely from the config for telemetry
//
// TODO(STENCIL-469): Investigate improving anonymization for tsCompilerOptions and devServer
const CONFIG_PROPS_TO_DELETE = [
    'commonjs',
    'devServer',
    'env',
    'logger',
    'rollupConfig',
    'sys',
    'testing',
    'tsCompilerOptions',
];
/**
 * Anonymize the config for telemetry, replacing potentially revealing config props
 * with a placeholder string if they are present (this lets us still track how frequently
 * these config options are being used)
 *
 * @param config the config to anonymize
 * @returns an anonymized copy of the same config
 */
const anonymizeConfigForTelemetry = (config) => {
    const anonymizedConfig = { ...config };
    for (const prop of CONFIG_PROPS_TO_ANONYMIZE) {
        if (anonymizedConfig[prop] !== undefined) {
            anonymizedConfig[prop] = 'omitted';
        }
    }
    anonymizedConfig.outputTargets = config.outputTargets.map((target) => {
        // Anonymize the outputTargets on our configuration, taking advantage of the
        // optional 2nd argument to `JSON.stringify`. If anything is not a string
        // we retain it so that any nested properties are handled, else we check
        // whether it's in our 'keep' list to decide whether to keep it or replace it
        // with `"omitted"`.
        const anonymizedOT = JSON.parse(JSON.stringify(target, (key, value) => {
            if (!(typeof value === 'string')) {
                return value;
            }
            if (OUTPUT_TARGET_KEYS_TO_KEEP.includes(key)) {
                return value;
            }
            return 'omitted';
        }));
        // this prop has to be handled separately because it is an array
        // so the replace function above will be called with all of its
        // members, giving us `["omitted", "omitted", ...]`.
        //
        // Instead, we check for its presence and manually copy over.
        if (isOutputTargetHydrate(target) && target.external) {
            anonymizedOT['external'] = target.external.concat();
        }
        return anonymizedOT;
    });
    // TODO(STENCIL-469): Investigate improving anonymization for tsCompilerOptions and devServer
    for (const prop of CONFIG_PROPS_TO_DELETE) {
        delete anonymizedConfig[prop];
    }
    return anonymizedConfig;
};
/**
 * Reads package-lock.json, yarn.lock, and package.json files in order to cross-reference
 * the dependencies and devDependencies properties. Pulls up the current installed version
 * of each package under the @stencil, @ionic, and @capacitor scopes.
 *
 * @param sys the system instance where telemetry is invoked
 * @param config the Stencil configuration associated with the current task that triggered telemetry
 * @returns an object listing all dev and production dependencies under the aforementioned scopes
 */
async function getInstalledPackages(sys, config) {
    let packages = [];
    let packagesNoVersions = [];
    const yarn = isUsingYarn(sys);
    try {
        // Read package.json and package-lock.json
        const appRootDir = sys.getCurrentDirectory();
        const packageJson = await tryFn(readJson, sys, sys.resolvePath(appRootDir + '/package.json'));
        // They don't have a package.json for some reason? Eject button.
        if (!packageJson) {
            return { packages, packagesNoVersions };
        }
        const rawPackages = Object.entries({
            ...packageJson.devDependencies,
            ...packageJson.dependencies,
        });
        // Collect packages only in the stencil, ionic, or capacitor org's:
        // https://www.npmjs.com/org/stencil
        const ionicPackages = rawPackages.filter(([k]) => k.startsWith('@stencil/') || k.startsWith('@ionic/') || k.startsWith('@capacitor/'));
        try {
            packages = yarn ? await yarnPackages(sys, ionicPackages) : await npmPackages(sys, ionicPackages);
        }
        catch (e) {
            packages = ionicPackages.map(([k, v]) => `${k}@${v.replace('^', '')}`);
        }
        packagesNoVersions = ionicPackages.map(([k]) => `${k}`);
        return { packages, packagesNoVersions };
    }
    catch (err) {
        hasDebug(config.flags) && console.error(err);
        return { packages, packagesNoVersions };
    }
}
/**
 * Visits the npm lock file to find the exact versions that are installed
 * @param sys The system where the command is invoked
 * @param ionicPackages a list of the found packages matching `@stencil`, `@capacitor`, or `@ionic` from the package.json file.
 * @returns an array of strings of all the packages and their versions.
 */
async function npmPackages(sys, ionicPackages) {
    const appRootDir = sys.getCurrentDirectory();
    const packageLockJson = await tryFn(readJson, sys, sys.resolvePath(appRootDir + '/package-lock.json'));
    return ionicPackages.map(([k, v]) => {
        var _a, _b, _c, _d;
        let version = (_d = (_b = (_a = packageLockJson === null || packageLockJson === void 0 ? void 0 : packageLockJson.dependencies[k]) === null || _a === void 0 ? void 0 : _a.version) !== null && _b !== void 0 ? _b : (_c = packageLockJson === null || packageLockJson === void 0 ? void 0 : packageLockJson.devDependencies[k]) === null || _c === void 0 ? void 0 : _c.version) !== null && _d !== void 0 ? _d : v;
        version = version.includes('file:') ? sanitizeDeclaredVersion(v) : version;
        return `${k}@${version}`;
    });
}
/**
 * Visits the yarn lock file to find the exact versions that are installed
 * @param sys The system where the command is invoked
 * @param ionicPackages a list of the found packages matching `@stencil`, `@capacitor`, or `@ionic` from the package.json file.
 * @returns an array of strings of all the packages and their versions.
 */
async function yarnPackages(sys, ionicPackages) {
    const appRootDir = sys.getCurrentDirectory();
    const yarnLock = sys.readFileSync(sys.resolvePath(appRootDir + '/yarn.lock'));
    const yarnLockYml = sys.parseYarnLockFile(yarnLock);
    return ionicPackages.map(([k, v]) => {
        var _a;
        const identifiedVersion = `${k}@${v}`;
        let version = (_a = yarnLockYml.object[identifiedVersion]) === null || _a === void 0 ? void 0 : _a.version;
        version = version.includes('undefined') ? sanitizeDeclaredVersion(identifiedVersion) : version;
        return `${k}@${version}`;
    });
}
/**
 * This function is used for fallback purposes, where an npm or yarn lock file doesn't exist in the consumers directory.
 * This will strip away '*', '^' and '~' from the declared package versions in a package.json.
 * @param version the raw semver pattern identifier version string
 * @returns a cleaned up representation without any qualifiers
 */
function sanitizeDeclaredVersion(version) {
    return version.replace(/[*^~]/g, '');
}
/**
 * If telemetry is enabled, send a metric to an external data store
 *
 * @param sys the system instance where telemetry is invoked
 * @param config the Stencil configuration associated with the current task that triggered telemetry
 * @param name the name of a trackable metric. Note this name is not necessarily a scalar value to track, like
 * "Stencil Version". For example, "stencil_cli_command" is a name that is used to track all CLI command information.
 * @param value the data to send to the external data store under the provided name argument
 */
async function sendMetric(sys, config, name, value) {
    const session_id = await getTelemetryToken(sys);
    const message = {
        name,
        timestamp: new Date().toISOString(),
        source: 'stencil_cli',
        value,
        session_id,
    };
    await sendTelemetry(sys, config, message);
}
/**
 * Used to read the config file's tokens.telemetry property.
 *
 * @param sys The system where the command is invoked
 * @returns string
 */
async function getTelemetryToken(sys) {
    const config = await readConfig(sys);
    if (config['tokens.telemetry'] === undefined) {
        config['tokens.telemetry'] = uuidv4();
        await writeConfig(sys, config);
    }
    return config['tokens.telemetry'];
}
/**
 * Issues a request to the telemetry server.
 * @param sys The system where the command is invoked
 * @param config The config passed into the Stencil command
 * @param data Data to be tracked
 */
async function sendTelemetry(sys, config, data) {
    try {
        const now = new Date().toISOString();
        const body = {
            metrics: [data],
            sent_at: now,
        };
        // This request is only made if telemetry is on.
        const response = await sys.fetch('https://api.ionicjs.com/events/metrics', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(body),
        });
        hasVerbose(config.flags) &&
            console.debug('\nSent %O metric to events service (status: %O)', data.name, response.status, '\n');
        if (response.status !== 204) {
            hasVerbose(config.flags) &&
                console.debug('\nBad response from events service. Request body: %O', response.body.toString(), '\n');
        }
    }
    catch (e) {
        hasVerbose(config.flags) && console.debug('Telemetry request failed:', e);
    }
}
/**
 * Checks if telemetry is enabled on this machine
 * @param sys The system where the command is invoked
 * @returns true if telemetry is enabled, false otherwise
 */
async function checkTelemetry(sys) {
    const config = await readConfig(sys);
    if (config['telemetry.stencil'] === undefined) {
        config['telemetry.stencil'] = true;
        await writeConfig(sys, config);
    }
    return config['telemetry.stencil'];
}
/**
 * Writes to the config file, enabling telemetry for this machine.
 * @param sys The system where the command is invoked
 * @returns true if writing the file was successful, false otherwise
 */
async function enableTelemetry(sys) {
    return await updateConfig(sys, { 'telemetry.stencil': true });
}
/**
 * Writes to the config file, disabling telemetry for this machine.
 * @param sys The system where the command is invoked
 * @returns true if writing the file was successful, false otherwise
 */
async function disableTelemetry(sys) {
    return await updateConfig(sys, { 'telemetry.stencil': false });
}
/**
 * Takes in a semver string in order to return the major version.
 * @param version The fully qualified semver version
 * @returns a string of the major version
 */
function getMajorVersion(version) {
    const parts = version.split('.');
    return parts[0];
}

const taskBuild = async (coreCompiler, config) => {
    if (config.flags.watch) {
        // watch build
        await taskWatch(coreCompiler, config);
        return;
    }
    // one-time build
    let exitCode = 0;
    try {
        startupCompilerLog(coreCompiler, config);
        const versionChecker = startCheckVersion(config, coreCompiler.version);
        const compiler = await coreCompiler.createCompiler(config);
        const results = await compiler.build();
        await telemetryBuildFinishedAction(config.sys, config, coreCompiler, results);
        await compiler.destroy();
        if (results.hasError) {
            exitCode = 1;
        }
        else if (config.flags.prerender) {
            const prerenderDiagnostics = await runPrerenderTask(coreCompiler, config, results.hydrateAppFilePath, results.componentGraph, null);
            config.logger.printDiagnostics(prerenderDiagnostics);
            if (prerenderDiagnostics.some((d) => d.level === 'error')) {
                exitCode = 1;
            }
        }
        await printCheckVersionResults(versionChecker);
    }
    catch (e) {
        exitCode = 1;
        config.logger.error(e);
    }
    if (exitCode > 0) {
        return config.sys.exit(exitCode);
    }
};

const taskDocs = async (coreCompiler, config) => {
    config.devServer = null;
    config.outputTargets = config.outputTargets.filter(isOutputTargetDocs);
    config.devMode = true;
    startupCompilerLog(coreCompiler, config);
    const compiler = await coreCompiler.createCompiler(config);
    await compiler.build();
    await compiler.destroy();
};

/**
 * Task to generate component boilerplate and write it to disk. This task can
 * cause the program to exit with an error under various circumstances, such as
 * being called in an inappropriate place, being asked to overwrite files that
 * already exist, etc.
 *
 * @param coreCompiler the CoreCompiler we're using currently, here we're
 * mainly accessing the `path` module
 * @param config the user-supplied config, which we need here to access `.sys`.
 */
const taskGenerate = async (coreCompiler, config) => {
    if (!IS_NODE_ENV) {
        config.logger.error(`"generate" command is currently only implemented for a NodeJS environment`);
        return config.sys.exit(1);
    }
    const path = coreCompiler.path;
    if (!config.configPath) {
        config.logger.error('Please run this command in your root directory (i. e. the one containing stencil.config.ts).');
        return config.sys.exit(1);
    }
    const absoluteSrcDir = config.srcDir;
    if (!absoluteSrcDir) {
        config.logger.error(`Stencil's srcDir was not specified.`);
        return config.sys.exit(1);
    }
    const { prompt } = await Promise.resolve().then(function () { return /*#__PURE__*/_interopNamespace(require('../sys/node/prompts.js')); });
    const input = config.flags.unknownArgs.find((arg) => !arg.startsWith('-')) ||
        (await prompt({ name: 'tagName', type: 'text', message: 'Component tag name (dash-case):' })).tagName;
    if (undefined === input) {
        // in some shells (e.g. Windows PowerShell), hitting Ctrl+C results in a TypeError printed to the console.
        // explicitly return here to avoid printing the error message.
        return;
    }
    const { dir, base: componentName } = path.parse(input);
    const tagError = validateComponentTag(componentName);
    if (tagError) {
        config.logger.error(tagError);
        return config.sys.exit(1);
    }
    const filesToGenerateExt = await chooseFilesToGenerate();
    if (undefined === filesToGenerateExt) {
        // in some shells (e.g. Windows PowerShell), hitting Ctrl+C results in a TypeError printed to the console.
        // explicitly return here to avoid printing the error message.
        return;
    }
    const extensionsToGenerate = ['tsx', ...filesToGenerateExt];
    const testFolder = extensionsToGenerate.some(isTest) ? 'test' : '';
    const outDir = path.join(absoluteSrcDir, 'components', dir, componentName);
    await config.sys.createDir(path.join(outDir, testFolder), { recursive: true });
    const filesToGenerate = extensionsToGenerate.map((extension) => ({
        extension,
        path: getFilepathForFile(coreCompiler, outDir, componentName, extension),
    }));
    await checkForOverwrite(filesToGenerate, config);
    const writtenFiles = await Promise.all(filesToGenerate.map((file) => getBoilerplateAndWriteFile(config, componentName, extensionsToGenerate.includes('css'), file))).catch((error) => config.logger.error(error));
    if (!writtenFiles) {
        return config.sys.exit(1);
    }
    // We use `console.log` here rather than our `config.logger` because we don't want
    // our TUI messages to be prefixed with timestamps and so on.
    //
    // See STENCIL-424 for details.
    console.log();
    console.log(`${config.logger.gray('$')} stencil generate ${input}`);
    console.log();
    console.log(config.logger.bold('The following files have been generated:'));
    const absoluteRootDir = config.rootDir;
    writtenFiles.map((file) => console.log(`  - ${path.relative(absoluteRootDir, file)}`));
};
/**
 * Show a checkbox prompt to select the files to be generated.
 *
 * @returns a read-only array of `GenerableExtension`, the extensions that the user has decided
 * to generate
 */
const chooseFilesToGenerate = async () => {
    const { prompt } = await Promise.resolve().then(function () { return /*#__PURE__*/_interopNamespace(require('../sys/node/prompts.js')); });
    return (await prompt({
        name: 'filesToGenerate',
        type: 'multiselect',
        message: 'Which additional files do you want to generate?',
        choices: [
            { value: 'css', title: 'Stylesheet (.css)', selected: true },
            { value: 'spec.tsx', title: 'Spec Test  (.spec.tsx)', selected: true },
            { value: 'e2e.ts', title: 'E2E Test (.e2e.ts)', selected: true },
        ],
    })).filesToGenerate;
};
/**
 * Get a filepath for a file we want to generate!
 *
 * The filepath for a given file depends on the path, the user-supplied
 * component name, the extension, and whether we're inside of a test directory.
 *
 * @param coreCompiler  the compiler we're using, here to acces the `.path` module
 * @param path          path to where we're going to generate the component
 * @param componentName the user-supplied name for the generated component
 * @param extension     the file extension
 * @returns the full filepath to the component (with a possible `test` directory
 * added)
 */
const getFilepathForFile = (coreCompiler, path, componentName, extension) => isTest(extension)
    ? coreCompiler.path.join(path, 'test', `${componentName}.${extension}`)
    : coreCompiler.path.join(path, `${componentName}.${extension}`);
/**
 * Get the boilerplate for a file and write it to disk
 *
 * @param config        the current config, needed for file operations
 * @param componentName the component name (user-supplied)
 * @param withCss       are we generating CSS?
 * @param file          the file we want to write
 * @returns a `Promise<string>` which holds the full filepath we've written to,
 * used to print out a little summary of our activity to the user.
 */
const getBoilerplateAndWriteFile = async (config, componentName, withCss, file) => {
    const boilerplate = getBoilerplateByExtension(componentName, file.extension, withCss);
    await config.sys.writeFile(file.path, boilerplate);
    return file.path;
};
/**
 * Check to see if any of the files we plan to write already exist and would
 * therefore be overwritten if we proceed, because we'd like to not overwrite
 * people's code!
 *
 * This function will check all the filepaths and if it finds any files log an
 * error and exit with an error code. If it doesn't find anything it will just
 * peacefully return `Promise<void>`.
 *
 * @param files  the files we want to check
 * @param config the Config object, used here to get access to `sys.readFile`
 */
const checkForOverwrite = async (files, config) => {
    const alreadyPresent = [];
    await Promise.all(files.map(async ({ path }) => {
        if ((await config.sys.readFile(path)) !== undefined) {
            alreadyPresent.push(path);
        }
    }));
    if (alreadyPresent.length > 0) {
        config.logger.error('Generating code would overwrite the following files:', ...alreadyPresent.map((path) => '\t' + path));
        await config.sys.exit(1);
    }
};
/**
 * Check if an extension is for a test
 *
 * @param extension the extension we want to check
 * @returns a boolean indicating whether or not its a test
 */
const isTest = (extension) => {
    return extension === 'e2e.ts' || extension === 'spec.tsx';
};
/**
 * Get the boilerplate for a file by its extension.
 *
 * @param tagName the name of the component we're generating
 * @param extension the file extension we want boilerplate for (.css, tsx, etc)
 * @param withCss a boolean indicating whether we're generating a CSS file
 * @returns a string container the file boilerplate for the supplied extension
 */
const getBoilerplateByExtension = (tagName, extension, withCss) => {
    switch (extension) {
        case 'tsx':
            return getComponentBoilerplate(tagName, withCss);
        case 'css':
            return getStyleUrlBoilerplate();
        case 'spec.tsx':
            return getSpecTestBoilerplate(tagName);
        case 'e2e.ts':
            return getE2eTestBoilerplate(tagName);
        default:
            throw new Error(`Unkown extension "${extension}".`);
    }
};
/**
 * Get the boilerplate for a file containing the definition of a component
 * @param tagName the name of the tag to give the component
 * @param hasStyle designates if the component has an external stylesheet or not
 * @returns the contents of a file that defines a component
 */
const getComponentBoilerplate = (tagName, hasStyle) => {
    const decorator = [`{`];
    decorator.push(`  tag: '${tagName}',`);
    if (hasStyle) {
        decorator.push(`  styleUrl: '${tagName}.css',`);
    }
    decorator.push(`  shadow: true,`);
    decorator.push(`}`);
    return `import { Component, Host, h } from '@stencil/core';

@Component(${decorator.join('\n')})
export class ${toPascalCase(tagName)} {

  render() {
    return (
      <Host>
        <slot></slot>
      </Host>
    );
  }

}
`;
};
/**
 * Get the boilerplate for style for a generated component
 * @returns a boilerplate CSS block
 */
const getStyleUrlBoilerplate = () => `:host {
  display: block;
}
`;
/**
 * Get the boilerplate for a file containing a spec (unit) test for a component
 * @param tagName the name of the tag associated with the component under test
 * @returns the contents of a file that unit tests a component
 */
const getSpecTestBoilerplate = (tagName) => `import { newSpecPage } from '@stencil/core/testing';
import { ${toPascalCase(tagName)} } from '../${tagName}';

describe('${tagName}', () => {
  it('renders', async () => {
    const page = await newSpecPage({
      components: [${toPascalCase(tagName)}],
      html: \`<${tagName}></${tagName}>\`,
    });
    expect(page.root).toEqualHtml(\`
      <${tagName}>
        <mock:shadow-root>
          <slot></slot>
        </mock:shadow-root>
      </${tagName}>
    \`);
  });
});
`;
/**
 * Get the boilerplate for a file containing an end-to-end (E2E) test for a component
 * @param tagName the name of the tag associated with the component under test
 * @returns the contents of a file that E2E tests a component
 */
const getE2eTestBoilerplate = (tagName) => `import { newE2EPage } from '@stencil/core/testing';

describe('${tagName}', () => {
  it('renders', async () => {
    const page = await newE2EPage();
    await page.setContent('<${tagName}></${tagName}>');

    const element = await page.find('${tagName}');
    expect(element).toHaveClass('hydrated');
  });
});
`;
/**
 * Convert a dash case string to pascal case.
 * @param str the string to convert
 * @returns the converted input as pascal case
 */
const toPascalCase = (str) => str.split('-').reduce((res, part) => res + part[0].toUpperCase() + part.slice(1), '');

/**
 * Entrypoint for the Telemetry task
 * @param flags configuration flags provided to Stencil when a task was called (either this task or a task that invokes
 * telemetry)
 * @param sys the abstraction for interfacing with the operating system
 * @param logger a logging implementation to log the results out to the user
 */
const taskTelemetry = async (flags, sys, logger) => {
    const prompt = logger.dim(sys.details.platform === 'windows' ? '>' : '$');
    const isEnabling = flags.args.includes('on');
    const isDisabling = flags.args.includes('off');
    const INFORMATION = `Opt in or out of telemetry. Information about the data we collect is available on our website: ${logger.bold('https://stenciljs.com/telemetry')}`;
    const THANK_YOU = `Thank you for helping to make Stencil better! 💖`;
    const ENABLED_MESSAGE = `${logger.green('Enabled')}. ${THANK_YOU}\n\n`;
    const DISABLED_MESSAGE = `${logger.red('Disabled')}\n\n`;
    const hasTelemetry = await checkTelemetry(sys);
    if (isEnabling) {
        const result = await enableTelemetry(sys);
        result
            ? console.log(`\n  ${logger.bold('Telemetry is now ') + ENABLED_MESSAGE}`)
            : console.log(`Something went wrong when enabling Telemetry.`);
        return;
    }
    if (isDisabling) {
        const result = await disableTelemetry(sys);
        result
            ? console.log(`\n  ${logger.bold('Telemetry is now ') + DISABLED_MESSAGE}`)
            : console.log(`Something went wrong when disabling Telemetry.`);
        return;
    }
    console.log(`  ${logger.bold('Telemetry:')} ${logger.dim(INFORMATION)}`);
    console.log(`\n  ${logger.bold('Status')}: ${hasTelemetry ? ENABLED_MESSAGE : DISABLED_MESSAGE}`);
    console.log(`    ${prompt} ${logger.green('stencil telemetry [off|on]')}

        ${logger.cyan('off')} ${logger.dim('.............')} Disable sharing anonymous usage data
        ${logger.cyan('on')} ${logger.dim('..............')} Enable sharing anonymous usage data
  `);
};

/**
 * Entrypoint for the Help task, providing Stencil usage context to the user
 * @param flags configuration flags provided to Stencil when a task was call (either this task or a task that invokes
 * telemetry)
 * @param logger a logging implementation to log the results out to the user
 * @param sys the abstraction for interfacing with the operating system
 */
const taskHelp = async (flags, logger, sys) => {
    const prompt = logger.dim(sys.details.platform === 'windows' ? '>' : '$');
    console.log(`
  ${logger.bold('Build:')} ${logger.dim('Build components for development or production.')}

    ${prompt} ${logger.green('stencil build [--dev] [--watch] [--prerender] [--debug]')}

      ${logger.cyan('--dev')} ${logger.dim('.............')} Development build
      ${logger.cyan('--watch')} ${logger.dim('...........')} Rebuild when files update
      ${logger.cyan('--serve')} ${logger.dim('...........')} Start the dev-server
      ${logger.cyan('--prerender')} ${logger.dim('.......')} Prerender the application
      ${logger.cyan('--docs')} ${logger.dim('............')} Generate component readme.md docs
      ${logger.cyan('--config')} ${logger.dim('..........')} Set stencil config file
      ${logger.cyan('--stats')} ${logger.dim('...........')} Write stencil-stats.json file
      ${logger.cyan('--log')} ${logger.dim('.............')} Write stencil-build.log file
      ${logger.cyan('--debug')} ${logger.dim('...........')} Set the log level to debug


  ${logger.bold('Test:')} ${logger.dim('Run unit and end-to-end tests.')}

    ${prompt} ${logger.green('stencil test [--spec] [--e2e]')}

      ${logger.cyan('--spec')} ${logger.dim('............')} Run unit tests with Jest
      ${logger.cyan('--e2e')} ${logger.dim('.............')} Run e2e tests with Puppeteer


  ${logger.bold('Generate:')} ${logger.dim('Bootstrap components.')}

    ${prompt} ${logger.green('stencil generate')} or ${logger.green('stencil g')}

`);
    await taskTelemetry(flags, sys, logger);
    console.log(`
  ${logger.bold('Examples:')}

  ${prompt} ${logger.green('stencil build --dev --watch --serve')}
  ${prompt} ${logger.green('stencil build --prerender')}
  ${prompt} ${logger.green('stencil test --spec --e2e')}
  ${prompt} ${logger.green('stencil telemetry on')}
  ${prompt} ${logger.green('stencil generate')}
  ${prompt} ${logger.green('stencil g my-component')}
`);
};

const taskInfo = (coreCompiler, sys, logger) => {
    const details = sys.details;
    const versions = coreCompiler.versions;
    console.log(``);
    console.log(`${logger.cyan('      System:')} ${sys.name} ${sys.version}`);
    console.log(`${logger.cyan('     Plaform:')} ${details.platform} (${details.release})`);
    console.log(`${logger.cyan('   CPU Model:')} ${details.cpuModel} (${sys.hardwareConcurrency} cpu${sys.hardwareConcurrency !== 1 ? 's' : ''})`);
    console.log(`${logger.cyan('    Compiler:')} ${sys.getCompilerExecutingPath()}`);
    console.log(`${logger.cyan('       Build:')} ${coreCompiler.buildId}`);
    console.log(`${logger.cyan('     Stencil:')} ${coreCompiler.version}${logger.emoji(' ' + coreCompiler.vermoji)}`);
    console.log(`${logger.cyan('  TypeScript:')} ${versions.typescript}`);
    console.log(`${logger.cyan('      Rollup:')} ${versions.rollup}`);
    console.log(`${logger.cyan('      Parse5:')} ${versions.parse5}`);
    console.log(`${logger.cyan('      Sizzle:')} ${versions.sizzle}`);
    console.log(`${logger.cyan('      Terser:')} ${versions.terser}`);
    console.log(``);
};

const taskServe = async (config) => {
    config.suppressLogs = true;
    config.flags.serve = true;
    config.devServer.openBrowser = config.flags.open;
    config.devServer.reloadStrategy = null;
    config.devServer.initialLoadUrl = '/';
    config.devServer.websocket = false;
    config.maxConcurrentWorkers = 1;
    config.devServer.root = isString(config.flags.root) ? config.flags.root : config.sys.getCurrentDirectory();
    const devServerPath = config.sys.getDevServerExecutingPath();
    const { start } = await config.sys.dynamicImport(devServerPath);
    const devServer = await start(config.devServer, config.logger);
    console.log(`${config.logger.cyan('     Root:')} ${devServer.root}`);
    console.log(`${config.logger.cyan('  Address:')} ${devServer.address}`);
    console.log(`${config.logger.cyan('     Port:')} ${devServer.port}`);
    console.log(`${config.logger.cyan('   Server:')} ${devServer.browserUrl}`);
    console.log(``);
    config.sys.onProcessInterrupt(() => {
        if (devServer) {
            config.logger.debug(`dev server close: ${devServer.browserUrl}`);
            devServer.close();
        }
    });
};

/**
 * Entrypoint for any Stencil tests
 * @param config a validated Stencil configuration entity
 */
const taskTest = async (config) => {
    if (!IS_NODE_ENV) {
        config.logger.error(`"test" command is currently only implemented for a NodeJS environment`);
        return config.sys.exit(1);
    }
    config.buildDocs = false;
    const testingRunOpts = {
        e2e: !!config.flags.e2e,
        screenshot: !!config.flags.screenshot,
        spec: !!config.flags.spec,
        updateScreenshot: !!config.flags.updateScreenshot,
    };
    // always ensure we have jest modules installed
    const ensureModuleIds = ['@types/jest', 'jest', 'jest-cli'];
    if (testingRunOpts.e2e) {
        // if it's an e2e test, also make sure we're got
        // puppeteer modules installed and if browserExecutablePath is provided don't download Chromium use only puppeteer-core instead
        const puppeteer = config.testing.browserExecutablePath ? 'puppeteer-core' : 'puppeteer';
        ensureModuleIds.push(puppeteer);
        if (testingRunOpts.screenshot) {
            // ensure we've got pixelmatch for screenshots
            config.logger.warn(config.logger.yellow(`EXPERIMENTAL: screenshot visual diff testing is currently under heavy development and has not reached a stable status. However, any assistance testing would be appreciated.`));
        }
    }
    // ensure we've got the required modules installed
    const diagnostics = await config.sys.lazyRequire.ensure(config.rootDir, ensureModuleIds);
    if (diagnostics.length > 0) {
        config.logger.printDiagnostics(diagnostics);
        return config.sys.exit(1);
    }
    try {
        // let's test!
        const { createTesting } = await Promise.resolve().then(function () { return /*#__PURE__*/_interopNamespace(require('../testing/index.js')); });
        const testing = await createTesting(config);
        const passed = await testing.run(testingRunOpts);
        await testing.destroy();
        if (!passed) {
            return config.sys.exit(1);
        }
    }
    catch (e) {
        config.logger.error(e);
        return config.sys.exit(1);
    }
};

const run = async (init) => {
    const { args, logger, sys } = init;
    try {
        const flags = parseFlags(args);
        const task = flags.task;
        if (flags.debug || flags.verbose) {
            logger.setLevel('debug');
        }
        if (flags.ci) {
            logger.enableColors(false);
        }
        if (isFunction(sys.applyGlobalPatch)) {
            sys.applyGlobalPatch(sys.getCurrentDirectory());
        }
        if (!task || task === 'help' || flags.help) {
            await taskHelp(createConfigFlags({ task: 'help', args }), logger, sys);
            return;
        }
        startupLog(logger, task);
        const findConfigResults = await findConfig({ sys, configPath: flags.config });
        if (hasError(findConfigResults.diagnostics)) {
            logger.printDiagnostics(findConfigResults.diagnostics);
            return sys.exit(1);
        }
        const ensureDepsResults = await sys.ensureDependencies({
            rootDir: findConfigResults.rootDir,
            logger,
            dependencies: dependencies,
        });
        if (hasError(ensureDepsResults.diagnostics)) {
            logger.printDiagnostics(ensureDepsResults.diagnostics);
            return sys.exit(1);
        }
        const coreCompiler = await loadCoreCompiler(sys);
        if (task === 'version' || flags.version) {
            console.log(coreCompiler.version);
            return;
        }
        startupLogVersion(logger, task, coreCompiler);
        loadedCompilerLog(sys, logger, flags, coreCompiler);
        if (task === 'info') {
            taskInfo(coreCompiler, sys, logger);
            return;
        }
        const validated = await coreCompiler.loadConfig({
            config: {
                flags,
            },
            configPath: findConfigResults.configPath,
            logger,
            sys,
        });
        if (validated.diagnostics.length > 0) {
            logger.printDiagnostics(validated.diagnostics);
            if (hasError(validated.diagnostics)) {
                return sys.exit(1);
            }
        }
        if (isFunction(sys.applyGlobalPatch)) {
            sys.applyGlobalPatch(validated.config.rootDir);
        }
        await sys.ensureResources({ rootDir: validated.config.rootDir, logger, dependencies: dependencies });
        await telemetryAction(sys, validated.config, coreCompiler, async () => {
            await runTask(coreCompiler, validated.config, task, sys);
        });
    }
    catch (e) {
        if (!shouldIgnoreError(e)) {
            const details = `${logger.getLevel() === 'debug' && e instanceof Error ? e.stack : ''}`;
            logger.error(`uncaught cli error: ${e}${details}`);
            return sys.exit(1);
        }
    }
};
/**
 * Run a specified task
 * @param coreCompiler an instance of a minimal, bootstrap compiler for running the specified task
 * @param config a configuration for the Stencil project to apply to the task run
 * @param task the task to run
 * @param sys the {@link CompilerSystem} for interacting with the operating system
 * @public
 */
const runTask = async (coreCompiler, config, task, sys) => {
    var _a, _b, _c, _d, _e, _f;
    const logger = (_a = config.logger) !== null && _a !== void 0 ? _a : createLogger();
    const strictConfig = {
        ...config,
        flags: createConfigFlags((_b = config.flags) !== null && _b !== void 0 ? _b : { task }),
        logger,
        outputTargets: (_c = config.outputTargets) !== null && _c !== void 0 ? _c : [],
        rootDir: (_d = config.rootDir) !== null && _d !== void 0 ? _d : '/',
        sys: (_e = sys !== null && sys !== void 0 ? sys : config.sys) !== null && _e !== void 0 ? _e : coreCompiler.createSystem({ logger }),
        testing: (_f = config.testing) !== null && _f !== void 0 ? _f : {},
    };
    switch (task) {
        case 'build':
            await taskBuild(coreCompiler, strictConfig);
            break;
        case 'docs':
            await taskDocs(coreCompiler, strictConfig);
            break;
        case 'generate':
        case 'g':
            await taskGenerate(coreCompiler, strictConfig);
            break;
        case 'help':
            await taskHelp(strictConfig.flags, strictConfig.logger, sys);
            break;
        case 'prerender':
            await taskPrerender(coreCompiler, strictConfig);
            break;
        case 'serve':
            await taskServe(strictConfig);
            break;
        case 'telemetry':
            await taskTelemetry(strictConfig.flags, sys, strictConfig.logger);
            break;
        case 'test':
            await taskTest(strictConfig);
            break;
        case 'version':
            console.log(coreCompiler.version);
            break;
        default:
            strictConfig.logger.error(`${strictConfig.logger.emoji('❌ ')}Invalid stencil command, please see the options below:`);
            await taskHelp(strictConfig.flags, strictConfig.logger, sys);
            return config.sys.exit(1);
    }
};

exports.parseFlags = parseFlags;
exports.run = run;
exports.runTask = runTask;
//# sourceMappingURL=index.cjs.map
