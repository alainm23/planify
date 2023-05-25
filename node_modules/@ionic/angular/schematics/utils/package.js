"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.addPackageToPackageJson = void 0;
/**
 * Adds a package to the package.json
 */
function addPackageToPackageJson(host, type, pkg, version) {
    var _a;
    if (host.exists('package.json')) {
        const sourceText = (_a = host.read('package.json')) === null || _a === void 0 ? void 0 : _a.toString('utf-8');
        const json = JSON.parse(sourceText);
        if (!json[type]) {
            json[type] = {};
        }
        if (!json[type][pkg]) {
            json[type][pkg] = version;
        }
        host.overwrite('package.json', JSON.stringify(json, null, 2));
    }
    return host;
}
exports.addPackageToPackageJson = addPackageToPackageJson;
