/*!
 Stencil Dev Server Process v2.22.3 | MIT Licensed | https://stenciljs.com
 */
'use strict';

const index_js = require('../sys/node/index.js');
const path = require('path');
const childProcess = require('child_process');
const fs$1 = require('fs');
const os = require('os');
const fs$2 = require('../sys/node/graceful-fs.js');
const util = require('util');
const http = require('http');
const https = require('https');
const net = require('net');
const openInEditorApi = require('./open-in-editor-api.js');
const buffer = require('buffer');
const zlib = require('zlib');
const ws = require('./ws.js');

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
const childProcess__default = /*#__PURE__*/_interopDefaultLegacy(childProcess);
const fs__default = /*#__PURE__*/_interopDefaultLegacy(fs$1);
const os__default = /*#__PURE__*/_interopDefaultLegacy(os);
const fs__default$1 = /*#__PURE__*/_interopDefaultLegacy(fs$2);
const util__default = /*#__PURE__*/_interopDefaultLegacy(util);
const http__namespace = /*#__PURE__*/_interopNamespace(http);
const https__namespace = /*#__PURE__*/_interopNamespace(https);
const net__namespace = /*#__PURE__*/_interopNamespace(net);
const openInEditorApi__default = /*#__PURE__*/_interopDefaultLegacy(openInEditorApi);
const zlib__namespace = /*#__PURE__*/_interopNamespace(zlib);
const ws__namespace = /*#__PURE__*/_interopNamespace(ws);

const noop = () => {
    /* noop*/
};
const isFunction = (v) => typeof v === 'function';
const isString = (v) => typeof v === 'string';

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

const DEV_SERVER_URL = '/~dev-server';
const DEV_MODULE_URL = '/~dev-module';
const DEV_SERVER_INIT_URL = `${DEV_SERVER_URL}-init`;
const OPEN_IN_EDITOR_URL = `${DEV_SERVER_URL}-open-in-editor`;

const version = '2.22.3';

const contentTypes = {"123":"application/vnd.lotus-1-2-3","1km":"application/vnd.1000minds.decision-model+xml","3dml":"text/vnd.in3d.3dml","3ds":"image/x-3ds","3g2":"video/3gpp2","3gp":"video/3gpp","3gpp":"video/3gpp","3mf":"model/3mf","7z":"application/x-7z-compressed","aab":"application/x-authorware-bin","aac":"audio/x-aac","aam":"application/x-authorware-map","aas":"application/x-authorware-seg","abw":"application/x-abiword","ac":"application/vnd.nokia.n-gage.ac+xml","acc":"application/vnd.americandynamics.acc","ace":"application/x-ace-compressed","acu":"application/vnd.acucobol","acutc":"application/vnd.acucorp","adp":"audio/adpcm","aep":"application/vnd.audiograph","afm":"application/x-font-type1","afp":"application/vnd.ibm.modcap","age":"application/vnd.age","ahead":"application/vnd.ahead.space","ai":"application/postscript","aif":"audio/x-aiff","aifc":"audio/x-aiff","aiff":"audio/x-aiff","air":"application/vnd.adobe.air-application-installer-package+zip","ait":"application/vnd.dvb.ait","ami":"application/vnd.amiga.ami","amr":"audio/amr","apk":"application/vnd.android.package-archive","apng":"image/apng","appcache":"text/cache-manifest","application":"application/x-ms-application","apr":"application/vnd.lotus-approach","arc":"application/x-freearc","arj":"application/x-arj","asc":"application/pgp-signature","asf":"video/x-ms-asf","asm":"text/x-asm","aso":"application/vnd.accpac.simply.aso","asx":"video/x-ms-asf","atc":"application/vnd.acucorp","atom":"application/atom+xml","atomcat":"application/atomcat+xml","atomdeleted":"application/atomdeleted+xml","atomsvc":"application/atomsvc+xml","atx":"application/vnd.antix.game-component","au":"audio/basic","avci":"image/avci","avcs":"image/avcs","avi":"video/x-msvideo","avif":"image/avif","aw":"application/applixware","azf":"application/vnd.airzip.filesecure.azf","azs":"application/vnd.airzip.filesecure.azs","azv":"image/vnd.airzip.accelerator.azv","azw":"application/vnd.amazon.ebook","b16":"image/vnd.pco.b16","bat":"application/x-msdownload","bcpio":"application/x-bcpio","bdf":"application/x-font-bdf","bdm":"application/vnd.syncml.dm+wbxml","bdoc":"application/x-bdoc","bed":"application/vnd.realvnc.bed","bh2":"application/vnd.fujitsu.oasysprs","bin":"application/octet-stream","blb":"application/x-blorb","blorb":"application/x-blorb","bmi":"application/vnd.bmi","bmml":"application/vnd.balsamiq.bmml+xml","bmp":"image/x-ms-bmp","book":"application/vnd.framemaker","box":"application/vnd.previewsystems.box","boz":"application/x-bzip2","bpk":"application/octet-stream","bsp":"model/vnd.valve.source.compiled-map","btif":"image/prs.btif","buffer":"application/octet-stream","bz":"application/x-bzip","bz2":"application/x-bzip2","c":"text/x-c","c11amc":"application/vnd.cluetrust.cartomobile-config","c11amz":"application/vnd.cluetrust.cartomobile-config-pkg","c4d":"application/vnd.clonk.c4group","c4f":"application/vnd.clonk.c4group","c4g":"application/vnd.clonk.c4group","c4p":"application/vnd.clonk.c4group","c4u":"application/vnd.clonk.c4group","cab":"application/vnd.ms-cab-compressed","caf":"audio/x-caf","cap":"application/vnd.tcpdump.pcap","car":"application/vnd.curl.car","cat":"application/vnd.ms-pki.seccat","cb7":"application/x-cbr","cba":"application/x-cbr","cbr":"application/x-cbr","cbt":"application/x-cbr","cbz":"application/x-cbr","cc":"text/x-c","cco":"application/x-cocoa","cct":"application/x-director","ccxml":"application/ccxml+xml","cdbcmsg":"application/vnd.contact.cmsg","cdf":"application/x-netcdf","cdfx":"application/cdfx+xml","cdkey":"application/vnd.mediastation.cdkey","cdmia":"application/cdmi-capability","cdmic":"application/cdmi-container","cdmid":"application/cdmi-domain","cdmio":"application/cdmi-object","cdmiq":"application/cdmi-queue","cdx":"chemical/x-cdx","cdxml":"application/vnd.chemdraw+xml","cdy":"application/vnd.cinderella","cer":"application/pkix-cert","cfs":"application/x-cfs-compressed","cgm":"image/cgm","chat":"application/x-chat","chm":"application/vnd.ms-htmlhelp","chrt":"application/vnd.kde.kchart","cif":"chemical/x-cif","cii":"application/vnd.anser-web-certificate-issue-initiation","cil":"application/vnd.ms-artgalry","cjs":"application/node","cla":"application/vnd.claymore","class":"application/java-vm","clkk":"application/vnd.crick.clicker.keyboard","clkp":"application/vnd.crick.clicker.palette","clkt":"application/vnd.crick.clicker.template","clkw":"application/vnd.crick.clicker.wordbank","clkx":"application/vnd.crick.clicker","clp":"application/x-msclip","cmc":"application/vnd.cosmocaller","cmdf":"chemical/x-cmdf","cml":"chemical/x-cml","cmp":"application/vnd.yellowriver-custom-menu","cmx":"image/x-cmx","cod":"application/vnd.rim.cod","coffee":"text/coffeescript","com":"application/x-msdownload","conf":"text/plain","cpio":"application/x-cpio","cpl":"application/cpl+xml","cpp":"text/x-c","cpt":"application/mac-compactpro","crd":"application/x-mscardfile","crl":"application/pkix-crl","crt":"application/x-x509-ca-cert","crx":"application/x-chrome-extension","cryptonote":"application/vnd.rig.cryptonote","csh":"application/x-csh","csl":"application/vnd.citationstyles.style+xml","csml":"chemical/x-csml","csp":"application/vnd.commonspace","css":"text/css","cst":"application/x-director","csv":"text/csv","cu":"application/cu-seeme","curl":"text/vnd.curl","cww":"application/prs.cww","cxt":"application/x-director","cxx":"text/x-c","dae":"model/vnd.collada+xml","daf":"application/vnd.mobius.daf","dart":"application/vnd.dart","dataless":"application/vnd.fdsn.seed","davmount":"application/davmount+xml","dbf":"application/vnd.dbf","dbk":"application/docbook+xml","dcr":"application/x-director","dcurl":"text/vnd.curl.dcurl","dd2":"application/vnd.oma.dd2+xml","ddd":"application/vnd.fujixerox.ddd","ddf":"application/vnd.syncml.dmddf+xml","dds":"image/vnd.ms-dds","deb":"application/x-debian-package","def":"text/plain","deploy":"application/octet-stream","der":"application/x-x509-ca-cert","dfac":"application/vnd.dreamfactory","dgc":"application/x-dgc-compressed","dic":"text/x-c","dir":"application/x-director","dis":"application/vnd.mobius.dis","disposition-notification":"message/disposition-notification","dist":"application/octet-stream","distz":"application/octet-stream","djv":"image/vnd.djvu","djvu":"image/vnd.djvu","dll":"application/x-msdownload","dmg":"application/x-apple-diskimage","dmp":"application/vnd.tcpdump.pcap","dms":"application/octet-stream","dna":"application/vnd.dna","doc":"application/msword","docm":"application/vnd.ms-word.document.macroenabled.12","docx":"application/vnd.openxmlformats-officedocument.wordprocessingml.document","dot":"application/msword","dotm":"application/vnd.ms-word.template.macroenabled.12","dotx":"application/vnd.openxmlformats-officedocument.wordprocessingml.template","dp":"application/vnd.osgi.dp","dpg":"application/vnd.dpgraph","dra":"audio/vnd.dra","drle":"image/dicom-rle","dsc":"text/prs.lines.tag","dssc":"application/dssc+der","dtb":"application/x-dtbook+xml","dtd":"application/xml-dtd","dts":"audio/vnd.dts","dtshd":"audio/vnd.dts.hd","dump":"application/octet-stream","dvb":"video/vnd.dvb.file","dvi":"application/x-dvi","dwd":"application/atsc-dwd+xml","dwf":"model/vnd.dwf","dwg":"image/vnd.dwg","dxf":"image/vnd.dxf","dxp":"application/vnd.spotfire.dxp","dxr":"application/x-director","ear":"application/java-archive","ecelp4800":"audio/vnd.nuera.ecelp4800","ecelp7470":"audio/vnd.nuera.ecelp7470","ecelp9600":"audio/vnd.nuera.ecelp9600","ecma":"application/ecmascript","edm":"application/vnd.novadigm.edm","edx":"application/vnd.novadigm.edx","efif":"application/vnd.picsel","ei6":"application/vnd.pg.osasli","elc":"application/octet-stream","emf":"image/emf","eml":"message/rfc822","emma":"application/emma+xml","emotionml":"application/emotionml+xml","emz":"application/x-msmetafile","eol":"audio/vnd.digital-winds","eot":"application/vnd.ms-fontobject","eps":"application/postscript","epub":"application/epub+zip","es":"application/ecmascript","es3":"application/vnd.eszigno3+xml","esa":"application/vnd.osgi.subsystem","esf":"application/vnd.epson.esf","et3":"application/vnd.eszigno3+xml","etx":"text/x-setext","eva":"application/x-eva","evy":"application/x-envoy","exe":"application/x-msdownload","exi":"application/exi","exp":"application/express","exr":"image/aces","ext":"application/vnd.novadigm.ext","ez":"application/andrew-inset","ez2":"application/vnd.ezpix-album","ez3":"application/vnd.ezpix-package","f":"text/x-fortran","f4v":"video/x-f4v","f77":"text/x-fortran","f90":"text/x-fortran","fbs":"image/vnd.fastbidsheet","fcdt":"application/vnd.adobe.formscentral.fcdt","fcs":"application/vnd.isac.fcs","fdf":"application/vnd.fdf","fdt":"application/fdt+xml","fe_launch":"application/vnd.denovo.fcselayout-link","fg5":"application/vnd.fujitsu.oasysgp","fgd":"application/x-director","fh":"image/x-freehand","fh4":"image/x-freehand","fh5":"image/x-freehand","fh7":"image/x-freehand","fhc":"image/x-freehand","fig":"application/x-xfig","fits":"image/fits","flac":"audio/x-flac","fli":"video/x-fli","flo":"application/vnd.micrografx.flo","flv":"video/x-flv","flw":"application/vnd.kde.kivio","flx":"text/vnd.fmi.flexstor","fly":"text/vnd.fly","fm":"application/vnd.framemaker","fnc":"application/vnd.frogans.fnc","fo":"application/vnd.software602.filler.form+xml","for":"text/x-fortran","fpx":"image/vnd.fpx","frame":"application/vnd.framemaker","fsc":"application/vnd.fsc.weblaunch","fst":"image/vnd.fst","ftc":"application/vnd.fluxtime.clip","fti":"application/vnd.anser-web-funds-transfer-initiation","fvt":"video/vnd.fvt","fxp":"application/vnd.adobe.fxp","fxpl":"application/vnd.adobe.fxp","fzs":"application/vnd.fuzzysheet","g2w":"application/vnd.geoplan","g3":"image/g3fax","g3w":"application/vnd.geospace","gac":"application/vnd.groove-account","gam":"application/x-tads","gbr":"application/rpki-ghostbusters","gca":"application/x-gca-compressed","gdl":"model/vnd.gdl","gdoc":"application/vnd.google-apps.document","ged":"text/vnd.familysearch.gedcom","geo":"application/vnd.dynageo","geojson":"application/geo+json","gex":"application/vnd.geometry-explorer","ggb":"application/vnd.geogebra.file","ggt":"application/vnd.geogebra.tool","ghf":"application/vnd.groove-help","gif":"image/gif","gim":"application/vnd.groove-identity-message","glb":"model/gltf-binary","gltf":"model/gltf+json","gml":"application/gml+xml","gmx":"application/vnd.gmx","gnumeric":"application/x-gnumeric","gph":"application/vnd.flographit","gpx":"application/gpx+xml","gqf":"application/vnd.grafeq","gqs":"application/vnd.grafeq","gram":"application/srgs","gramps":"application/x-gramps-xml","gre":"application/vnd.geometry-explorer","grv":"application/vnd.groove-injector","grxml":"application/srgs+xml","gsf":"application/x-font-ghostscript","gsheet":"application/vnd.google-apps.spreadsheet","gslides":"application/vnd.google-apps.presentation","gtar":"application/x-gtar","gtm":"application/vnd.groove-tool-message","gtw":"model/vnd.gtw","gv":"text/vnd.graphviz","gxf":"application/gxf","gxt":"application/vnd.geonext","gz":"application/gzip","h":"text/x-c","h261":"video/h261","h263":"video/h263","h264":"video/h264","hal":"application/vnd.hal+xml","hbci":"application/vnd.hbci","hbs":"text/x-handlebars-template","hdd":"application/x-virtualbox-hdd","hdf":"application/x-hdf","heic":"image/heic","heics":"image/heic-sequence","heif":"image/heif","heifs":"image/heif-sequence","hej2":"image/hej2k","held":"application/atsc-held+xml","hh":"text/x-c","hjson":"application/hjson","hlp":"application/winhlp","hpgl":"application/vnd.hp-hpgl","hpid":"application/vnd.hp-hpid","hps":"application/vnd.hp-hps","hqx":"application/mac-binhex40","hsj2":"image/hsj2","htc":"text/x-component","htke":"application/vnd.kenameaapp","htm":"text/html","html":"text/html","hvd":"application/vnd.yamaha.hv-dic","hvp":"application/vnd.yamaha.hv-voice","hvs":"application/vnd.yamaha.hv-script","i2g":"application/vnd.intergeo","icc":"application/vnd.iccprofile","ice":"x-conference/x-cooltalk","icm":"application/vnd.iccprofile","ico":"image/x-icon","ics":"text/calendar","ief":"image/ief","ifb":"text/calendar","ifm":"application/vnd.shana.informed.formdata","iges":"model/iges","igl":"application/vnd.igloader","igm":"application/vnd.insors.igm","igs":"model/iges","igx":"application/vnd.micrografx.igx","iif":"application/vnd.shana.informed.interchange","img":"application/octet-stream","imp":"application/vnd.accpac.simply.imp","ims":"application/vnd.ms-ims","in":"text/plain","ini":"text/plain","ink":"application/inkml+xml","inkml":"application/inkml+xml","install":"application/x-install-instructions","iota":"application/vnd.astraea-software.iota","ipfix":"application/ipfix","ipk":"application/vnd.shana.informed.package","irm":"application/vnd.ibm.rights-management","irp":"application/vnd.irepository.package+xml","iso":"application/x-iso9660-image","itp":"application/vnd.shana.informed.formtemplate","its":"application/its+xml","ivp":"application/vnd.immervision-ivp","ivu":"application/vnd.immervision-ivu","jad":"text/vnd.sun.j2me.app-descriptor","jade":"text/jade","jam":"application/vnd.jam","jar":"application/java-archive","jardiff":"application/x-java-archive-diff","java":"text/x-java-source","jhc":"image/jphc","jisp":"application/vnd.jisp","jls":"image/jls","jlt":"application/vnd.hp-jlyt","jng":"image/x-jng","jnlp":"application/x-java-jnlp-file","joda":"application/vnd.joost.joda-archive","jp2":"image/jp2","jpe":"image/jpeg","jpeg":"image/jpeg","jpf":"image/jpx","jpg":"image/jpeg","jpg2":"image/jp2","jpgm":"video/jpm","jpgv":"video/jpeg","jph":"image/jph","jpm":"video/jpm","jpx":"image/jpx","js":"application/javascript","json":"application/json","json5":"application/json5","jsonld":"application/ld+json","jsonml":"application/jsonml+json","jsx":"text/jsx","jxr":"image/jxr","jxra":"image/jxra","jxrs":"image/jxrs","jxs":"image/jxs","jxsc":"image/jxsc","jxsi":"image/jxsi","jxss":"image/jxss","kar":"audio/midi","karbon":"application/vnd.kde.karbon","kdbx":"application/x-keepass2","key":"application/x-iwork-keynote-sffkey","kfo":"application/vnd.kde.kformula","kia":"application/vnd.kidspiration","kml":"application/vnd.google-earth.kml+xml","kmz":"application/vnd.google-earth.kmz","kne":"application/vnd.kinar","knp":"application/vnd.kinar","kon":"application/vnd.kde.kontour","kpr":"application/vnd.kde.kpresenter","kpt":"application/vnd.kde.kpresenter","kpxx":"application/vnd.ds-keypoint","ksp":"application/vnd.kde.kspread","ktr":"application/vnd.kahootz","ktx":"image/ktx","ktx2":"image/ktx2","ktz":"application/vnd.kahootz","kwd":"application/vnd.kde.kword","kwt":"application/vnd.kde.kword","lasxml":"application/vnd.las.las+xml","latex":"application/x-latex","lbd":"application/vnd.llamagraphics.life-balance.desktop","lbe":"application/vnd.llamagraphics.life-balance.exchange+xml","les":"application/vnd.hhe.lesson-player","less":"text/less","lgr":"application/lgr+xml","lha":"application/x-lzh-compressed","link66":"application/vnd.route66.link66+xml","list":"text/plain","list3820":"application/vnd.ibm.modcap","listafp":"application/vnd.ibm.modcap","litcoffee":"text/coffeescript","lnk":"application/x-ms-shortcut","log":"text/plain","lostxml":"application/lost+xml","lrf":"application/octet-stream","lrm":"application/vnd.ms-lrm","ltf":"application/vnd.frogans.ltf","lua":"text/x-lua","luac":"application/x-lua-bytecode","lvp":"audio/vnd.lucent.voice","lwp":"application/vnd.lotus-wordpro","lzh":"application/x-lzh-compressed","m13":"application/x-msmediaview","m14":"application/x-msmediaview","m1v":"video/mpeg","m21":"application/mp21","m2a":"audio/mpeg","m2v":"video/mpeg","m3a":"audio/mpeg","m3u":"audio/x-mpegurl","m3u8":"application/vnd.apple.mpegurl","m4a":"audio/x-m4a","m4p":"application/mp4","m4s":"video/iso.segment","m4u":"video/vnd.mpegurl","m4v":"video/x-m4v","ma":"application/mathematica","mads":"application/mads+xml","maei":"application/mmt-aei+xml","mag":"application/vnd.ecowin.chart","maker":"application/vnd.framemaker","man":"text/troff","manifest":"text/cache-manifest","map":"application/json","mar":"application/octet-stream","markdown":"text/markdown","mathml":"application/mathml+xml","mb":"application/mathematica","mbk":"application/vnd.mobius.mbk","mbox":"application/mbox","mc1":"application/vnd.medcalcdata","mcd":"application/vnd.mcd","mcurl":"text/vnd.curl.mcurl","md":"text/markdown","mdb":"application/x-msaccess","mdi":"image/vnd.ms-modi","mdx":"text/mdx","me":"text/troff","mesh":"model/mesh","meta4":"application/metalink4+xml","metalink":"application/metalink+xml","mets":"application/mets+xml","mfm":"application/vnd.mfmp","mft":"application/rpki-manifest","mgp":"application/vnd.osgeo.mapguide.package","mgz":"application/vnd.proteus.magazine","mid":"audio/midi","midi":"audio/midi","mie":"application/x-mie","mif":"application/vnd.mif","mime":"message/rfc822","mj2":"video/mj2","mjp2":"video/mj2","mjs":"application/javascript","mk3d":"video/x-matroska","mka":"audio/x-matroska","mkd":"text/x-markdown","mks":"video/x-matroska","mkv":"video/x-matroska","mlp":"application/vnd.dolby.mlp","mmd":"application/vnd.chipnuts.karaoke-mmd","mmf":"application/vnd.smaf","mml":"text/mathml","mmr":"image/vnd.fujixerox.edmics-mmr","mng":"video/x-mng","mny":"application/x-msmoney","mobi":"application/x-mobipocket-ebook","mods":"application/mods+xml","mov":"video/quicktime","movie":"video/x-sgi-movie","mp2":"audio/mpeg","mp21":"application/mp21","mp2a":"audio/mpeg","mp3":"audio/mpeg","mp4":"video/mp4","mp4a":"audio/mp4","mp4s":"application/mp4","mp4v":"video/mp4","mpc":"application/vnd.mophun.certificate","mpd":"application/dash+xml","mpe":"video/mpeg","mpeg":"video/mpeg","mpf":"application/media-policy-dataset+xml","mpg":"video/mpeg","mpg4":"video/mp4","mpga":"audio/mpeg","mpkg":"application/vnd.apple.installer+xml","mpm":"application/vnd.blueice.multipass","mpn":"application/vnd.mophun.application","mpp":"application/vnd.ms-project","mpt":"application/vnd.ms-project","mpy":"application/vnd.ibm.minipay","mqy":"application/vnd.mobius.mqy","mrc":"application/marc","mrcx":"application/marcxml+xml","ms":"text/troff","mscml":"application/mediaservercontrol+xml","mseed":"application/vnd.fdsn.mseed","mseq":"application/vnd.mseq","msf":"application/vnd.epson.msf","msg":"application/vnd.ms-outlook","msh":"model/mesh","msi":"application/x-msdownload","msl":"application/vnd.mobius.msl","msm":"application/octet-stream","msp":"application/octet-stream","msty":"application/vnd.muvee.style","mtl":"model/mtl","mts":"model/vnd.mts","mus":"application/vnd.musician","musd":"application/mmt-usd+xml","musicxml":"application/vnd.recordare.musicxml+xml","mvb":"application/x-msmediaview","mvt":"application/vnd.mapbox-vector-tile","mwf":"application/vnd.mfer","mxf":"application/mxf","mxl":"application/vnd.recordare.musicxml","mxmf":"audio/mobile-xmf","mxml":"application/xv+xml","mxs":"application/vnd.triscape.mxs","mxu":"video/vnd.mpegurl","n-gage":"application/vnd.nokia.n-gage.symbian.install","n3":"text/n3","nb":"application/mathematica","nbp":"application/vnd.wolfram.player","nc":"application/x-netcdf","ncx":"application/x-dtbncx+xml","nfo":"text/x-nfo","ngdat":"application/vnd.nokia.n-gage.data","nitf":"application/vnd.nitf","nlu":"application/vnd.neurolanguage.nlu","nml":"application/vnd.enliven","nnd":"application/vnd.noblenet-directory","nns":"application/vnd.noblenet-sealer","nnw":"application/vnd.noblenet-web","npx":"image/vnd.net-fpx","nq":"application/n-quads","nsc":"application/x-conference","nsf":"application/vnd.lotus-notes","nt":"application/n-triples","ntf":"application/vnd.nitf","numbers":"application/x-iwork-numbers-sffnumbers","nzb":"application/x-nzb","oa2":"application/vnd.fujitsu.oasys2","oa3":"application/vnd.fujitsu.oasys3","oas":"application/vnd.fujitsu.oasys","obd":"application/x-msbinder","obgx":"application/vnd.openblox.game+xml","obj":"model/obj","oda":"application/oda","odb":"application/vnd.oasis.opendocument.database","odc":"application/vnd.oasis.opendocument.chart","odf":"application/vnd.oasis.opendocument.formula","odft":"application/vnd.oasis.opendocument.formula-template","odg":"application/vnd.oasis.opendocument.graphics","odi":"application/vnd.oasis.opendocument.image","odm":"application/vnd.oasis.opendocument.text-master","odp":"application/vnd.oasis.opendocument.presentation","ods":"application/vnd.oasis.opendocument.spreadsheet","odt":"application/vnd.oasis.opendocument.text","oga":"audio/ogg","ogex":"model/vnd.opengex","ogg":"audio/ogg","ogv":"video/ogg","ogx":"application/ogg","omdoc":"application/omdoc+xml","onepkg":"application/onenote","onetmp":"application/onenote","onetoc":"application/onenote","onetoc2":"application/onenote","opf":"application/oebps-package+xml","opml":"text/x-opml","oprc":"application/vnd.palm","opus":"audio/ogg","org":"text/x-org","osf":"application/vnd.yamaha.openscoreformat","osfpvg":"application/vnd.yamaha.openscoreformat.osfpvg+xml","osm":"application/vnd.openstreetmap.data+xml","otc":"application/vnd.oasis.opendocument.chart-template","otf":"font/otf","otg":"application/vnd.oasis.opendocument.graphics-template","oth":"application/vnd.oasis.opendocument.text-web","oti":"application/vnd.oasis.opendocument.image-template","otp":"application/vnd.oasis.opendocument.presentation-template","ots":"application/vnd.oasis.opendocument.spreadsheet-template","ott":"application/vnd.oasis.opendocument.text-template","ova":"application/x-virtualbox-ova","ovf":"application/x-virtualbox-ovf","owl":"application/rdf+xml","oxps":"application/oxps","oxt":"application/vnd.openofficeorg.extension","p":"text/x-pascal","p10":"application/pkcs10","p12":"application/x-pkcs12","p7b":"application/x-pkcs7-certificates","p7c":"application/pkcs7-mime","p7m":"application/pkcs7-mime","p7r":"application/x-pkcs7-certreqresp","p7s":"application/pkcs7-signature","p8":"application/pkcs8","pac":"application/x-ns-proxy-autoconfig","pages":"application/x-iwork-pages-sffpages","pas":"text/x-pascal","paw":"application/vnd.pawaafile","pbd":"application/vnd.powerbuilder6","pbm":"image/x-portable-bitmap","pcap":"application/vnd.tcpdump.pcap","pcf":"application/x-font-pcf","pcl":"application/vnd.hp-pcl","pclxl":"application/vnd.hp-pclxl","pct":"image/x-pict","pcurl":"application/vnd.curl.pcurl","pcx":"image/x-pcx","pdb":"application/x-pilot","pde":"text/x-processing","pdf":"application/pdf","pem":"application/x-x509-ca-cert","pfa":"application/x-font-type1","pfb":"application/x-font-type1","pfm":"application/x-font-type1","pfr":"application/font-tdpfr","pfx":"application/x-pkcs12","pgm":"image/x-portable-graymap","pgn":"application/x-chess-pgn","pgp":"application/pgp-encrypted","php":"application/x-httpd-php","pic":"image/x-pict","pkg":"application/octet-stream","pki":"application/pkixcmp","pkipath":"application/pkix-pkipath","pkpass":"application/vnd.apple.pkpass","pl":"application/x-perl","plb":"application/vnd.3gpp.pic-bw-large","plc":"application/vnd.mobius.plc","plf":"application/vnd.pocketlearn","pls":"application/pls+xml","pm":"application/x-perl","pml":"application/vnd.ctc-posml","png":"image/png","pnm":"image/x-portable-anymap","portpkg":"application/vnd.macports.portpkg","pot":"application/vnd.ms-powerpoint","potm":"application/vnd.ms-powerpoint.template.macroenabled.12","potx":"application/vnd.openxmlformats-officedocument.presentationml.template","ppam":"application/vnd.ms-powerpoint.addin.macroenabled.12","ppd":"application/vnd.cups-ppd","ppm":"image/x-portable-pixmap","pps":"application/vnd.ms-powerpoint","ppsm":"application/vnd.ms-powerpoint.slideshow.macroenabled.12","ppsx":"application/vnd.openxmlformats-officedocument.presentationml.slideshow","ppt":"application/vnd.ms-powerpoint","pptm":"application/vnd.ms-powerpoint.presentation.macroenabled.12","pptx":"application/vnd.openxmlformats-officedocument.presentationml.presentation","pqa":"application/vnd.palm","prc":"application/x-pilot","pre":"application/vnd.lotus-freelance","prf":"application/pics-rules","provx":"application/provenance+xml","ps":"application/postscript","psb":"application/vnd.3gpp.pic-bw-small","psd":"image/vnd.adobe.photoshop","psf":"application/x-font-linux-psf","pskcxml":"application/pskc+xml","pti":"image/prs.pti","ptid":"application/vnd.pvi.ptid1","pub":"application/x-mspublisher","pvb":"application/vnd.3gpp.pic-bw-var","pwn":"application/vnd.3m.post-it-notes","pya":"audio/vnd.ms-playready.media.pya","pyv":"video/vnd.ms-playready.media.pyv","qam":"application/vnd.epson.quickanime","qbo":"application/vnd.intu.qbo","qfx":"application/vnd.intu.qfx","qps":"application/vnd.publishare-delta-tree","qt":"video/quicktime","qwd":"application/vnd.quark.quarkxpress","qwt":"application/vnd.quark.quarkxpress","qxb":"application/vnd.quark.quarkxpress","qxd":"application/vnd.quark.quarkxpress","qxl":"application/vnd.quark.quarkxpress","qxt":"application/vnd.quark.quarkxpress","ra":"audio/x-realaudio","ram":"audio/x-pn-realaudio","raml":"application/raml+yaml","rapd":"application/route-apd+xml","rar":"application/x-rar-compressed","ras":"image/x-cmu-raster","rcprofile":"application/vnd.ipunplugged.rcprofile","rdf":"application/rdf+xml","rdz":"application/vnd.data-vision.rdz","relo":"application/p2p-overlay+xml","rep":"application/vnd.businessobjects","res":"application/x-dtbresource+xml","rgb":"image/x-rgb","rif":"application/reginfo+xml","rip":"audio/vnd.rip","ris":"application/x-research-info-systems","rl":"application/resource-lists+xml","rlc":"image/vnd.fujixerox.edmics-rlc","rld":"application/resource-lists-diff+xml","rm":"application/vnd.rn-realmedia","rmi":"audio/midi","rmp":"audio/x-pn-realaudio-plugin","rms":"application/vnd.jcp.javame.midlet-rms","rmvb":"application/vnd.rn-realmedia-vbr","rnc":"application/relax-ng-compact-syntax","rng":"application/xml","roa":"application/rpki-roa","roff":"text/troff","rp9":"application/vnd.cloanto.rp9","rpm":"application/x-redhat-package-manager","rpss":"application/vnd.nokia.radio-presets","rpst":"application/vnd.nokia.radio-preset","rq":"application/sparql-query","rs":"application/rls-services+xml","rsat":"application/atsc-rsat+xml","rsd":"application/rsd+xml","rsheet":"application/urc-ressheet+xml","rss":"application/rss+xml","rtf":"text/rtf","rtx":"text/richtext","run":"application/x-makeself","rusd":"application/route-usd+xml","s":"text/x-asm","s3m":"audio/s3m","saf":"application/vnd.yamaha.smaf-audio","sass":"text/x-sass","sbml":"application/sbml+xml","sc":"application/vnd.ibm.secure-container","scd":"application/x-msschedule","scm":"application/vnd.lotus-screencam","scq":"application/scvp-cv-request","scs":"application/scvp-cv-response","scss":"text/x-scss","scurl":"text/vnd.curl.scurl","sda":"application/vnd.stardivision.draw","sdc":"application/vnd.stardivision.calc","sdd":"application/vnd.stardivision.impress","sdkd":"application/vnd.solent.sdkm+xml","sdkm":"application/vnd.solent.sdkm+xml","sdp":"application/sdp","sdw":"application/vnd.stardivision.writer","sea":"application/x-sea","see":"application/vnd.seemail","seed":"application/vnd.fdsn.seed","sema":"application/vnd.sema","semd":"application/vnd.semd","semf":"application/vnd.semf","senmlx":"application/senml+xml","sensmlx":"application/sensml+xml","ser":"application/java-serialized-object","setpay":"application/set-payment-initiation","setreg":"application/set-registration-initiation","sfd-hdstx":"application/vnd.hydrostatix.sof-data","sfs":"application/vnd.spotfire.sfs","sfv":"text/x-sfv","sgi":"image/sgi","sgl":"application/vnd.stardivision.writer-global","sgm":"text/sgml","sgml":"text/sgml","sh":"application/x-sh","shar":"application/x-shar","shex":"text/shex","shf":"application/shf+xml","shtml":"text/html","sid":"image/x-mrsid-image","sieve":"application/sieve","sig":"application/pgp-signature","sil":"audio/silk","silo":"model/mesh","sis":"application/vnd.symbian.install","sisx":"application/vnd.symbian.install","sit":"application/x-stuffit","sitx":"application/x-stuffitx","siv":"application/sieve","skd":"application/vnd.koan","skm":"application/vnd.koan","skp":"application/vnd.koan","skt":"application/vnd.koan","sldm":"application/vnd.ms-powerpoint.slide.macroenabled.12","sldx":"application/vnd.openxmlformats-officedocument.presentationml.slide","slim":"text/slim","slm":"text/slim","sls":"application/route-s-tsid+xml","slt":"application/vnd.epson.salt","sm":"application/vnd.stepmania.stepchart","smf":"application/vnd.stardivision.math","smi":"application/smil+xml","smil":"application/smil+xml","smv":"video/x-smv","smzip":"application/vnd.stepmania.package","snd":"audio/basic","snf":"application/x-font-snf","so":"application/octet-stream","spc":"application/x-pkcs7-certificates","spdx":"text/spdx","spf":"application/vnd.yamaha.smaf-phrase","spl":"application/x-futuresplash","spot":"text/vnd.in3d.spot","spp":"application/scvp-vp-response","spq":"application/scvp-vp-request","spx":"audio/ogg","sql":"application/x-sql","src":"application/x-wais-source","srt":"application/x-subrip","sru":"application/sru+xml","srx":"application/sparql-results+xml","ssdl":"application/ssdl+xml","sse":"application/vnd.kodak-descriptor","ssf":"application/vnd.epson.ssf","ssml":"application/ssml+xml","st":"application/vnd.sailingtracker.track","stc":"application/vnd.sun.xml.calc.template","std":"application/vnd.sun.xml.draw.template","stf":"application/vnd.wt.stf","sti":"application/vnd.sun.xml.impress.template","stk":"application/hyperstudio","stl":"model/stl","stpx":"model/step+xml","stpxz":"model/step-xml+zip","stpz":"model/step+zip","str":"application/vnd.pg.format","stw":"application/vnd.sun.xml.writer.template","styl":"text/stylus","stylus":"text/stylus","sub":"text/vnd.dvb.subtitle","sus":"application/vnd.sus-calendar","susp":"application/vnd.sus-calendar","sv4cpio":"application/x-sv4cpio","sv4crc":"application/x-sv4crc","svc":"application/vnd.dvb.service","svd":"application/vnd.svd","svg":"image/svg+xml","svgz":"image/svg+xml","swa":"application/x-director","swf":"application/x-shockwave-flash","swi":"application/vnd.aristanetworks.swi","swidtag":"application/swid+xml","sxc":"application/vnd.sun.xml.calc","sxd":"application/vnd.sun.xml.draw","sxg":"application/vnd.sun.xml.writer.global","sxi":"application/vnd.sun.xml.impress","sxm":"application/vnd.sun.xml.math","sxw":"application/vnd.sun.xml.writer","t":"text/troff","t3":"application/x-t3vm-image","t38":"image/t38","taglet":"application/vnd.mynfc","tao":"application/vnd.tao.intent-module-archive","tap":"image/vnd.tencent.tap","tar":"application/x-tar","tcap":"application/vnd.3gpp2.tcap","tcl":"application/x-tcl","td":"application/urc-targetdesc+xml","teacher":"application/vnd.smart.teacher","tei":"application/tei+xml","teicorpus":"application/tei+xml","tex":"application/x-tex","texi":"application/x-texinfo","texinfo":"application/x-texinfo","text":"text/plain","tfi":"application/thraud+xml","tfm":"application/x-tex-tfm","tfx":"image/tiff-fx","tga":"image/x-tga","thmx":"application/vnd.ms-officetheme","tif":"image/tiff","tiff":"image/tiff","tk":"application/x-tcl","tmo":"application/vnd.tmobile-livetv","toml":"application/toml","torrent":"application/x-bittorrent","tpl":"application/vnd.groove-tool-template","tpt":"application/vnd.trid.tpt","tr":"text/troff","tra":"application/vnd.trueapp","trig":"application/trig","trm":"application/x-msterminal","ts":"video/mp2t","tsd":"application/timestamped-data","tsv":"text/tab-separated-values","ttc":"font/collection","ttf":"font/ttf","ttl":"text/turtle","ttml":"application/ttml+xml","twd":"application/vnd.simtech-mindmapper","twds":"application/vnd.simtech-mindmapper","txd":"application/vnd.genomatix.tuxedo","txf":"application/vnd.mobius.txf","txt":"text/plain","u32":"application/x-authorware-bin","u8dsn":"message/global-delivery-status","u8hdr":"message/global-headers","u8mdn":"message/global-disposition-notification","u8msg":"message/global","ubj":"application/ubjson","udeb":"application/x-debian-package","ufd":"application/vnd.ufdl","ufdl":"application/vnd.ufdl","ulx":"application/x-glulx","umj":"application/vnd.umajin","unityweb":"application/vnd.unity","uoml":"application/vnd.uoml+xml","uri":"text/uri-list","uris":"text/uri-list","urls":"text/uri-list","usdz":"model/vnd.usdz+zip","ustar":"application/x-ustar","utz":"application/vnd.uiq.theme","uu":"text/x-uuencode","uva":"audio/vnd.dece.audio","uvd":"application/vnd.dece.data","uvf":"application/vnd.dece.data","uvg":"image/vnd.dece.graphic","uvh":"video/vnd.dece.hd","uvi":"image/vnd.dece.graphic","uvm":"video/vnd.dece.mobile","uvp":"video/vnd.dece.pd","uvs":"video/vnd.dece.sd","uvt":"application/vnd.dece.ttml+xml","uvu":"video/vnd.uvvu.mp4","uvv":"video/vnd.dece.video","uvva":"audio/vnd.dece.audio","uvvd":"application/vnd.dece.data","uvvf":"application/vnd.dece.data","uvvg":"image/vnd.dece.graphic","uvvh":"video/vnd.dece.hd","uvvi":"image/vnd.dece.graphic","uvvm":"video/vnd.dece.mobile","uvvp":"video/vnd.dece.pd","uvvs":"video/vnd.dece.sd","uvvt":"application/vnd.dece.ttml+xml","uvvu":"video/vnd.uvvu.mp4","uvvv":"video/vnd.dece.video","uvvx":"application/vnd.dece.unspecified","uvvz":"application/vnd.dece.zip","uvx":"application/vnd.dece.unspecified","uvz":"application/vnd.dece.zip","vbox":"application/x-virtualbox-vbox","vbox-extpack":"application/x-virtualbox-vbox-extpack","vcard":"text/vcard","vcd":"application/x-cdlink","vcf":"text/x-vcard","vcg":"application/vnd.groove-vcard","vcs":"text/x-vcalendar","vcx":"application/vnd.vcx","vdi":"application/x-virtualbox-vdi","vds":"model/vnd.sap.vds","vhd":"application/x-virtualbox-vhd","vis":"application/vnd.visionary","viv":"video/vnd.vivo","vmdk":"application/x-virtualbox-vmdk","vob":"video/x-ms-vob","vor":"application/vnd.stardivision.writer","vox":"application/x-authorware-bin","vrml":"model/vrml","vsd":"application/vnd.visio","vsf":"application/vnd.vsf","vss":"application/vnd.visio","vst":"application/vnd.visio","vsw":"application/vnd.visio","vtf":"image/vnd.valve.source.texture","vtt":"text/vtt","vtu":"model/vnd.vtu","vxml":"application/voicexml+xml","w3d":"application/x-director","wad":"application/x-doom","wadl":"application/vnd.sun.wadl+xml","war":"application/java-archive","wasm":"application/wasm","wav":"audio/x-wav","wax":"audio/x-ms-wax","wbmp":"image/vnd.wap.wbmp","wbs":"application/vnd.criticaltools.wbs+xml","wbxml":"application/vnd.wap.wbxml","wcm":"application/vnd.ms-works","wdb":"application/vnd.ms-works","wdp":"image/vnd.ms-photo","weba":"audio/webm","webapp":"application/x-web-app-manifest+json","webm":"video/webm","webmanifest":"application/manifest+json","webp":"image/webp","wg":"application/vnd.pmi.widget","wgt":"application/widget","wif":"application/watcherinfo+xml","wks":"application/vnd.ms-works","wm":"video/x-ms-wm","wma":"audio/x-ms-wma","wmd":"application/x-ms-wmd","wmf":"image/wmf","wml":"text/vnd.wap.wml","wmlc":"application/vnd.wap.wmlc","wmls":"text/vnd.wap.wmlscript","wmlsc":"application/vnd.wap.wmlscriptc","wmv":"video/x-ms-wmv","wmx":"video/x-ms-wmx","wmz":"application/x-msmetafile","woff":"font/woff","woff2":"font/woff2","wpd":"application/vnd.wordperfect","wpl":"application/vnd.ms-wpl","wps":"application/vnd.ms-works","wqd":"application/vnd.wqd","wri":"application/x-mswrite","wrl":"model/vrml","wsc":"message/vnd.wfa.wsc","wsdl":"application/wsdl+xml","wspolicy":"application/wspolicy+xml","wtb":"application/vnd.webturbo","wvx":"video/x-ms-wvx","x32":"application/x-authorware-bin","x3d":"model/x3d+xml","x3db":"model/x3d+fastinfoset","x3dbz":"model/x3d+binary","x3dv":"model/x3d-vrml","x3dvz":"model/x3d+vrml","x3dz":"model/x3d+xml","x_b":"model/vnd.parasolid.transmit.binary","x_t":"model/vnd.parasolid.transmit.text","xaml":"application/xaml+xml","xap":"application/x-silverlight-app","xar":"application/vnd.xara","xav":"application/xcap-att+xml","xbap":"application/x-ms-xbap","xbd":"application/vnd.fujixerox.docuworks.binder","xbm":"image/x-xbitmap","xca":"application/xcap-caps+xml","xcs":"application/calendar+xml","xdf":"application/xcap-diff+xml","xdm":"application/vnd.syncml.dm+xml","xdp":"application/vnd.adobe.xdp+xml","xdssc":"application/dssc+xml","xdw":"application/vnd.fujixerox.docuworks","xel":"application/xcap-el+xml","xenc":"application/xenc+xml","xer":"application/patch-ops-error+xml","xfdf":"application/vnd.adobe.xfdf","xfdl":"application/vnd.xfdl","xht":"application/xhtml+xml","xhtml":"application/xhtml+xml","xhvml":"application/xv+xml","xif":"image/vnd.xiff","xla":"application/vnd.ms-excel","xlam":"application/vnd.ms-excel.addin.macroenabled.12","xlc":"application/vnd.ms-excel","xlf":"application/xliff+xml","xlm":"application/vnd.ms-excel","xls":"application/vnd.ms-excel","xlsb":"application/vnd.ms-excel.sheet.binary.macroenabled.12","xlsm":"application/vnd.ms-excel.sheet.macroenabled.12","xlsx":"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","xlt":"application/vnd.ms-excel","xltm":"application/vnd.ms-excel.template.macroenabled.12","xltx":"application/vnd.openxmlformats-officedocument.spreadsheetml.template","xlw":"application/vnd.ms-excel","xm":"audio/xm","xml":"text/xml","xns":"application/xcap-ns+xml","xo":"application/vnd.olpc-sugar","xop":"application/xop+xml","xpi":"application/x-xpinstall","xpl":"application/xproc+xml","xpm":"image/x-xpixmap","xpr":"application/vnd.is-xpr","xps":"application/vnd.ms-xpsdocument","xpw":"application/vnd.intercon.formnet","xpx":"application/vnd.intercon.formnet","xsd":"application/xml","xsl":"application/xslt+xml","xslt":"application/xslt+xml","xsm":"application/vnd.syncml+xml","xspf":"application/xspf+xml","xul":"application/vnd.mozilla.xul+xml","xvm":"application/xv+xml","xvml":"application/xv+xml","xwd":"image/x-xwindowdump","xyz":"chemical/x-xyz","xz":"application/x-xz","yaml":"text/yaml","yang":"application/yang","yin":"application/yin+xml","yml":"text/yaml","ymp":"text/x-suse-ymp","z1":"application/x-zmachine","z2":"application/x-zmachine","z3":"application/x-zmachine","z4":"application/x-zmachine","z5":"application/x-zmachine","z6":"application/x-zmachine","z7":"application/x-zmachine","z8":"application/x-zmachine","zaz":"application/vnd.zzazz.deck+xml","zip":"application/zip","zir":"application/vnd.zul","zirz":"application/vnd.zul","zmm":"application/vnd.handheld-entertainment+xml"};

function responseHeaders(headers, httpCache = false) {
    headers = { ...DEFAULT_HEADERS, ...headers };
    if (httpCache) {
        headers['cache-control'] = 'max-age=3600';
        delete headers['date'];
        delete headers['expires'];
    }
    return headers;
}
const DEFAULT_HEADERS = {
    'cache-control': 'no-cache, no-store, must-revalidate, max-age=0',
    expires: '0',
    date: 'Wed, 1 Jan 2000 00:00:00 GMT',
    server: 'Stencil Dev Server ' + version,
    'access-control-allow-origin': '*',
    'access-control-expose-headers': '*',
};
function getBrowserUrl(protocol, address, port, basePath, pathname) {
    address = address === `0.0.0.0` ? `localhost` : address;
    const portSuffix = !port || port === 80 || port === 443 ? '' : ':' + port;
    let path = basePath;
    if (pathname.startsWith('/')) {
        pathname = pathname.substring(1);
    }
    path += pathname;
    protocol = protocol.replace(/\:/g, '');
    return `${protocol}://${address}${portSuffix}${path}`;
}
function getDevServerClientUrl(devServerConfig, host, protocol) {
    let address = devServerConfig.address;
    let port = devServerConfig.port;
    if (host) {
        address = host;
        port = null;
    }
    return getBrowserUrl(protocol !== null && protocol !== void 0 ? protocol : devServerConfig.protocol, address, port, devServerConfig.basePath, DEV_SERVER_URL);
}
function getContentType(filePath) {
    const last = filePath.replace(/^.*[/\\]/, '').toLowerCase();
    const ext = last.replace(/^.*\./, '').toLowerCase();
    const hasPath = last.length < filePath.length;
    const hasDot = ext.length < last.length - 1;
    return ((hasDot || !hasPath) && contentTypes[ext]) || 'application/octet-stream';
}
function isHtmlFile(filePath) {
    filePath = filePath.toLowerCase().trim();
    return filePath.endsWith('.html') || filePath.endsWith('.htm');
}
function isCssFile(filePath) {
    filePath = filePath.toLowerCase().trim();
    return filePath.endsWith('.css');
}
const TXT_EXT = ['css', 'html', 'htm', 'js', 'json', 'svg', 'xml'];
function isSimpleText(filePath) {
    const ext = filePath.toLowerCase().trim().split('.').pop();
    return TXT_EXT.includes(ext);
}
function isExtensionLessPath(pathname) {
    const parts = pathname.split('/');
    const lastPart = parts[parts.length - 1];
    return !lastPart.includes('.');
}
function isSsrStaticDataPath(pathname) {
    const parts = pathname.split('/');
    const fileName = parts[parts.length - 1].split('?')[0];
    return fileName === 'page.state.json';
}
function getSsrStaticDataPath(req) {
    const parts = req.url.href.split('/');
    const fileName = parts[parts.length - 1];
    const fileNameParts = fileName.split('?');
    parts.pop();
    let ssrPath = new URL(parts.join('/')).href;
    if (!ssrPath.endsWith('/') && req.headers) {
        const h = new Headers(req.headers);
        if (h.get('referer').endsWith('/')) {
            ssrPath += '/';
        }
    }
    return {
        ssrPath,
        fileName: fileNameParts[0],
        hasQueryString: typeof fileNameParts[1] === 'string' && fileNameParts[1].length > 0,
    };
}
function isDevClient(pathname) {
    return pathname.startsWith(DEV_SERVER_URL);
}
function isDevModule(pathname) {
    return pathname.includes(DEV_MODULE_URL);
}
function isOpenInEditor(pathname) {
    return pathname === OPEN_IN_EDITOR_URL;
}
function isInitialDevServerLoad(pathname) {
    return pathname === DEV_SERVER_INIT_URL;
}
function isDevServerClient(pathname) {
    return pathname === DEV_SERVER_URL;
}
function shouldCompress(devServerConfig, req) {
    if (!devServerConfig.gzip) {
        return false;
    }
    if (req.method !== 'GET') {
        return false;
    }
    const acceptEncoding = req.headers && req.headers['accept-encoding'];
    if (typeof acceptEncoding !== 'string') {
        return false;
    }
    if (!acceptEncoding.includes('gzip')) {
        return false;
    }
    return true;
}

function createCommonjsModule(fn, basedir, module) {
	return module = {
		path: basedir,
		exports: {},
		require: function (path, base) {
			return commonjsRequire(path, (base === undefined || base === null) ? module.path : base);
		}
	}, fn(module, module.exports), module.exports;
}

function commonjsRequire () {
	throw new Error('Dynamic requires are not currently supported by @rollup/plugin-commonjs');
}

let isDocker;

function hasDockerEnv() {
	try {
		fs__default['default'].statSync('/.dockerenv');
		return true;
	} catch (_) {
		return false;
	}
}

function hasDockerCGroup() {
	try {
		return fs__default['default'].readFileSync('/proc/self/cgroup', 'utf8').includes('docker');
	} catch (_) {
		return false;
	}
}

var isDocker_1 = () => {
	if (isDocker === undefined) {
		isDocker = hasDockerEnv() || hasDockerCGroup();
	}

	return isDocker;
};

var isWsl_1 = createCommonjsModule(function (module) {




const isWsl = () => {
	if (process.platform !== 'linux') {
		return false;
	}

	if (os__default['default'].release().toLowerCase().includes('microsoft')) {
		if (isDocker_1()) {
			return false;
		}

		return true;
	}

	try {
		return fs__default['default'].readFileSync('/proc/version', 'utf8').toLowerCase().includes('microsoft') ?
			!isDocker_1() : false;
	} catch (_) {
		return false;
	}
};

if (process.env.__IS_WSL_TEST__) {
	module.exports = isWsl;
} else {
	module.exports = isWsl();
}
});

var defineLazyProp = (object, propertyName, fn) => {
	const define = value => Object.defineProperty(object, propertyName, {value, enumerable: true, writable: true});

	Object.defineProperty(object, propertyName, {
		configurable: true,
		enumerable: true,
		get() {
			const result = fn();
			define(result);
			return result;
		},
		set(value) {
			define(value);
		}
	});

	return object;
};

const {promises: fs, constants: fsConstants} = fs__default['default'];




// Path to included `xdg-open`.
const localXdgOpenPath = path__default['default'].join(__dirname, 'xdg-open');

const {platform, arch} = process;

/**
Get the mount point for fixed drives in WSL.

@inner
@returns {string} The mount point.
*/
const getWslDrivesMountPoint = (() => {
	// Default value for "root" param
	// according to https://docs.microsoft.com/en-us/windows/wsl/wsl-config
	const defaultMountPoint = '/mnt/';

	let mountPoint;

	return async function () {
		if (mountPoint) {
			// Return memoized mount point value
			return mountPoint;
		}

		const configFilePath = '/etc/wsl.conf';

		let isConfigFileExists = false;
		try {
			await fs.access(configFilePath, fsConstants.F_OK);
			isConfigFileExists = true;
		} catch {}

		if (!isConfigFileExists) {
			return defaultMountPoint;
		}

		const configContent = await fs.readFile(configFilePath, {encoding: 'utf8'});
		const configMountPoint = /(?<!#.*)root\s*=\s*(?<mountPoint>.*)/g.exec(configContent);

		if (!configMountPoint) {
			return defaultMountPoint;
		}

		mountPoint = configMountPoint.groups.mountPoint.trim();
		mountPoint = mountPoint.endsWith('/') ? mountPoint : `${mountPoint}/`;

		return mountPoint;
	};
})();

const pTryEach = async (array, mapper) => {
	let latestError;

	for (const item of array) {
		try {
			return await mapper(item); // eslint-disable-line no-await-in-loop
		} catch (error) {
			latestError = error;
		}
	}

	throw latestError;
};

const baseOpen = async options => {
	options = {
		wait: false,
		background: false,
		newInstance: false,
		allowNonzeroExitCode: false,
		...options
	};

	if (Array.isArray(options.app)) {
		return pTryEach(options.app, singleApp => baseOpen({
			...options,
			app: singleApp
		}));
	}

	let {name: app, arguments: appArguments = []} = options.app || {};
	appArguments = [...appArguments];

	if (Array.isArray(app)) {
		return pTryEach(app, appName => baseOpen({
			...options,
			app: {
				name: appName,
				arguments: appArguments
			}
		}));
	}

	let command;
	const cliArguments = [];
	const childProcessOptions = {};

	if (platform === 'darwin') {
		command = 'open';

		if (options.wait) {
			cliArguments.push('--wait-apps');
		}

		if (options.background) {
			cliArguments.push('--background');
		}

		if (options.newInstance) {
			cliArguments.push('--new');
		}

		if (app) {
			cliArguments.push('-a', app);
		}
	} else if (platform === 'win32' || (isWsl_1 && !isDocker_1())) {
		const mountPoint = await getWslDrivesMountPoint();

		command = isWsl_1 ?
			`${mountPoint}c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe` :
			`${process.env.SYSTEMROOT}\\System32\\WindowsPowerShell\\v1.0\\powershell`;

		cliArguments.push(
			'-NoProfile',
			'-NonInteractive',
			'–ExecutionPolicy',
			'Bypass',
			'-EncodedCommand'
		);

		if (!isWsl_1) {
			childProcessOptions.windowsVerbatimArguments = true;
		}

		const encodedArguments = ['Start'];

		if (options.wait) {
			encodedArguments.push('-Wait');
		}

		if (app) {
			// Double quote with double quotes to ensure the inner quotes are passed through.
			// Inner quotes are delimited for PowerShell interpretation with backticks.
			encodedArguments.push(`"\`"${app}\`""`, '-ArgumentList');
			if (options.target) {
				appArguments.unshift(options.target);
			}
		} else if (options.target) {
			encodedArguments.push(`"${options.target}"`);
		}

		if (appArguments.length > 0) {
			appArguments = appArguments.map(arg => `"\`"${arg}\`""`);
			encodedArguments.push(appArguments.join(','));
		}

		// Using Base64-encoded command, accepted by PowerShell, to allow special characters.
		options.target = Buffer.from(encodedArguments.join(' '), 'utf16le').toString('base64');
	} else {
		if (app) {
			command = app;
		} else {
			// When bundled by Webpack, there's no actual package file path and no local `xdg-open`.
			const isBundled = !__dirname || __dirname === '/';

			// Check if local `xdg-open` exists and is executable.
			let exeLocalXdgOpen = false;
			try {
				await fs.access(localXdgOpenPath, fsConstants.X_OK);
				exeLocalXdgOpen = true;
			} catch {}

			const useSystemXdgOpen = process.versions.electron ||
				platform === 'android' || isBundled || !exeLocalXdgOpen;
			command = useSystemXdgOpen ? 'xdg-open' : localXdgOpenPath;
		}

		if (appArguments.length > 0) {
			cliArguments.push(...appArguments);
		}

		if (!options.wait) {
			// `xdg-open` will block the process unless stdio is ignored
			// and it's detached from the parent even if it's unref'd.
			childProcessOptions.stdio = 'ignore';
			childProcessOptions.detached = true;
		}
	}

	if (options.target) {
		cliArguments.push(options.target);
	}

	if (platform === 'darwin' && appArguments.length > 0) {
		cliArguments.push('--args', ...appArguments);
	}

	const subprocess = childProcess__default['default'].spawn(command, cliArguments, childProcessOptions);

	if (options.wait) {
		return new Promise((resolve, reject) => {
			subprocess.once('error', reject);

			subprocess.once('close', exitCode => {
				if (options.allowNonzeroExitCode && exitCode > 0) {
					reject(new Error(`Exited with code ${exitCode}`));
					return;
				}

				resolve(subprocess);
			});
		});
	}

	subprocess.unref();

	return subprocess;
};

const open = (target, options) => {
	if (typeof target !== 'string') {
		throw new TypeError('Expected a `target`');
	}

	return baseOpen({
		...options,
		target
	});
};

const openApp = (name, options) => {
	if (typeof name !== 'string') {
		throw new TypeError('Expected a `name`');
	}

	const {arguments: appArguments = []} = options || {};
	if (appArguments !== undefined && appArguments !== null && !Array.isArray(appArguments)) {
		throw new TypeError('Expected `appArguments` as Array type');
	}

	return baseOpen({
		...options,
		app: {
			name,
			arguments: appArguments
		}
	});
};

function detectArchBinary(binary) {
	if (typeof binary === 'string' || Array.isArray(binary)) {
		return binary;
	}

	const {[arch]: archBinary} = binary;

	if (!archBinary) {
		throw new Error(`${arch} is not supported`);
	}

	return archBinary;
}

function detectPlatformBinary({[platform]: platformBinary}, {wsl}) {
	if (wsl && isWsl_1) {
		return detectArchBinary(wsl);
	}

	if (!platformBinary) {
		throw new Error(`${platform} is not supported`);
	}

	return detectArchBinary(platformBinary);
}

const apps = {};

defineLazyProp(apps, 'chrome', () => detectPlatformBinary({
	darwin: 'google chrome',
	win32: 'chrome',
	linux: ['google-chrome', 'google-chrome-stable', 'chromium']
}, {
	wsl: {
		ia32: '/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe',
		x64: ['/mnt/c/Program Files/Google/Chrome/Application/chrome.exe', '/mnt/c/Program Files (x86)/Google/Chrome/Application/chrome.exe']
	}
}));

defineLazyProp(apps, 'firefox', () => detectPlatformBinary({
	darwin: 'firefox',
	win32: 'C:\\Program Files\\Mozilla Firefox\\firefox.exe',
	linux: 'firefox'
}, {
	wsl: '/mnt/c/Program Files/Mozilla Firefox/firefox.exe'
}));

defineLazyProp(apps, 'edge', () => detectPlatformBinary({
	darwin: 'microsoft edge',
	win32: 'msedge',
	linux: ['microsoft-edge', 'microsoft-edge-dev']
}, {
	wsl: '/mnt/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
}));

open.apps = apps;
open.openApp = openApp;

var open_1 = open;

async function openInBrowser(opts) {
    // await open(opts.url, { app: ['google chrome', '--auto-open-devtools-for-tabs'] });
    await open_1(opts.url);
}

function createServerContext(sys, sendMsg, devServerConfig, buildResultsResolves, compilerRequestResolves) {
    const logRequest = (req, status) => {
        if (devServerConfig) {
            sendMsg({
                requestLog: {
                    method: req.method || '?',
                    url: req.pathname || '?',
                    status,
                },
            });
        }
    };
    const serve500 = (req, res, error, xSource) => {
        try {
            res.writeHead(500, responseHeaders({
                'content-type': 'text/plain; charset=utf-8',
                'x-source': xSource,
            }));
            res.write(util__default['default'].inspect(error));
            res.end();
            logRequest(req, 500);
        }
        catch (e) {
            sendMsg({ error: { message: 'serve500: ' + e } });
        }
    };
    const serve404 = (req, res, xSource, content = null) => {
        try {
            if (req.pathname === '/favicon.ico') {
                const defaultFavicon = path__default['default'].join(devServerConfig.devServerDir, 'static', 'favicon.ico');
                res.writeHead(200, responseHeaders({
                    'content-type': 'image/x-icon',
                    'x-source': `favicon: ${xSource}`,
                }));
                const rs = fs__default$1['default'].createReadStream(defaultFavicon);
                rs.on('error', (err) => {
                    res.writeHead(404, responseHeaders({
                        'content-type': 'text/plain; charset=utf-8',
                        'x-source': `createReadStream error: ${err}, ${xSource}`,
                    }));
                    res.write(util__default['default'].inspect(err));
                    res.end();
                });
                rs.pipe(res);
                return;
            }
            if (content == null) {
                content = ['404 File Not Found', 'Url: ' + req.pathname, 'File: ' + req.filePath].join('\n');
            }
            res.writeHead(404, responseHeaders({
                'content-type': 'text/plain; charset=utf-8',
                'x-source': xSource,
            }));
            res.write(content);
            res.end();
            logRequest(req, 400);
        }
        catch (e) {
            serve500(req, res, e, xSource);
        }
    };
    const serve302 = (req, res, pathname = null) => {
        logRequest(req, 302);
        res.writeHead(302, { location: pathname || devServerConfig.basePath || '/' });
        res.end();
    };
    const getBuildResults = () => new Promise((resolve, reject) => {
        if (serverCtx.isServerListening) {
            buildResultsResolves.push({ resolve, reject });
            sendMsg({ requestBuildResults: true });
        }
        else {
            reject('dev server closed');
        }
    });
    const getCompilerRequest = (compilerRequestPath) => new Promise((resolve, reject) => {
        if (serverCtx.isServerListening) {
            compilerRequestResolves.push({
                path: compilerRequestPath,
                resolve,
                reject,
            });
            sendMsg({ compilerRequestPath });
        }
        else {
            reject('dev server closed');
        }
    });
    const serverCtx = {
        connectorHtml: null,
        dirTemplate: null,
        getBuildResults,
        getCompilerRequest,
        isServerListening: false,
        logRequest,
        prerenderConfig: null,
        serve302,
        serve404,
        serve500,
        sys,
    };
    return serverCtx;
}

async function serveOpenInEditor(serverCtx, req, res) {
    let status = 200;
    const data = {};
    try {
        const editors = await getEditors();
        if (editors.length > 0) {
            await parseData(editors, serverCtx.sys, req, data);
            await openDataInEditor(data);
        }
        else {
            data.error = `no editors available`;
        }
    }
    catch (e) {
        data.error = e + '';
        status = 500;
    }
    serverCtx.logRequest(req, status);
    res.writeHead(status, responseHeaders({
        'content-type': 'application/json; charset=utf-8',
    }));
    res.write(JSON.stringify(data, null, 2));
    res.end();
}
async function parseData(editors, sys, req, data) {
    const qs = req.searchParams;
    if (!qs.has('file')) {
        data.error = `missing file`;
        return;
    }
    data.file = qs.get('file');
    if (qs.has('line') && !isNaN(qs.get('line'))) {
        data.line = parseInt(qs.get('line'), 10);
    }
    if (typeof data.line !== 'number' || data.line < 1) {
        data.line = 1;
    }
    if (qs.has('column') && !isNaN(qs.get('column'))) {
        data.column = parseInt(qs.get('column'), 10);
    }
    if (typeof data.column !== 'number' || data.column < 1) {
        data.column = 1;
    }
    let editor = qs.get('editor');
    if (typeof editor === 'string') {
        editor = editor.trim().toLowerCase();
        if (editors.some((e) => e.id === editor)) {
            data.editor = editor;
        }
        else {
            data.error = `invalid editor: ${editor}`;
            return;
        }
    }
    else {
        data.editor = editors[0].id;
    }
    const stat = await sys.stat(data.file);
    data.exists = stat.isFile;
}
async function openDataInEditor(data) {
    if (!data.exists || data.error) {
        return;
    }
    try {
        const opts = {
            editor: data.editor,
        };
        const editor = openInEditorApi__default['default'].configure(opts, (err) => (data.error = err + ''));
        if (data.error) {
            return;
        }
        data.open = `${data.file}:${data.line}:${data.column}`;
        await editor.open(data.open);
    }
    catch (e) {
        data.error = e + '';
    }
}
let editors = null;
function getEditors() {
    if (!editors) {
        editors = new Promise(async (resolve) => {
            const editors = [];
            try {
                await Promise.all(Object.keys(openInEditorApi__default['default'].editors).map(async (editorId) => {
                    const isSupported = await isEditorSupported(editorId);
                    editors.push({
                        id: editorId,
                        priority: EDITOR_PRIORITY[editorId],
                        supported: isSupported,
                    });
                }));
            }
            catch (e) { }
            resolve(editors
                .filter((e) => e.supported)
                .sort((a, b) => {
                if (a.priority < b.priority)
                    return -1;
                if (a.priority > b.priority)
                    return 1;
                return 0;
            })
                .map((e) => {
                return {
                    id: e.id,
                    name: EDITORS[e.id],
                };
            }));
        });
    }
    return editors;
}
async function isEditorSupported(editorId) {
    let isSupported = false;
    try {
        await openInEditorApi__default['default'].editors[editorId].detect();
        isSupported = true;
    }
    catch (e) { }
    return isSupported;
}
const EDITORS = {
    atom: 'Atom',
    code: 'Code',
    emacs: 'Emacs',
    idea14ce: 'IDEA 14 Community Edition',
    phpstorm: 'PhpStorm',
    sublime: 'Sublime',
    webstorm: 'WebStorm',
    vim: 'Vim',
    visualstudio: 'Visual Studio',
};
const EDITOR_PRIORITY = {
    code: 1,
    atom: 2,
    sublime: 3,
    visualstudio: 4,
    idea14ce: 5,
    webstorm: 6,
    phpstorm: 7,
    vim: 8,
    emacs: 9,
};

async function serveFile(devServerConfig, serverCtx, req, res) {
    try {
        if (isSimpleText(req.filePath)) {
            // easy text file, use the internal cache
            let content = await serverCtx.sys.readFile(req.filePath, 'utf8');
            if (devServerConfig.websocket && isHtmlFile(req.filePath) && !isDevServerClient(req.pathname)) {
                // auto inject our dev server script
                content = appendDevServerClientScript(devServerConfig, req, content);
            }
            else if (isCssFile(req.filePath)) {
                content = updateStyleUrls(req.url, content);
            }
            if (shouldCompress(devServerConfig, req)) {
                // let's gzip this well known web dev text file
                res.writeHead(200, responseHeaders({
                    'content-type': getContentType(req.filePath) + '; charset=utf-8',
                    'content-encoding': 'gzip',
                    vary: 'Accept-Encoding',
                }));
                zlib__namespace.gzip(content, { level: 9 }, (_, data) => {
                    res.end(data);
                });
            }
            else {
                // let's not gzip this file
                res.writeHead(200, responseHeaders({
                    'content-type': getContentType(req.filePath) + '; charset=utf-8',
                    'content-length': buffer.Buffer.byteLength(content, 'utf8'),
                }));
                res.write(content);
                res.end();
            }
        }
        else {
            // non-well-known text file or other file, probably best we use a stream
            // but don't bother trying to gzip this file for the dev server
            res.writeHead(200, responseHeaders({
                'content-type': getContentType(req.filePath),
                'content-length': req.stats.size,
            }));
            fs__default$1['default'].createReadStream(req.filePath).pipe(res);
        }
        serverCtx.logRequest(req, 200);
    }
    catch (e) {
        serverCtx.serve500(req, res, e, 'serveFile');
    }
}
function updateStyleUrls(url, oldCss) {
    const versionId = url.searchParams.get('s-hmr');
    const hmrUrls = url.searchParams.get('s-hmr-urls');
    if (versionId && hmrUrls) {
        hmrUrls.split(',').forEach((hmrUrl) => {
            urlVersionIds.set(hmrUrl, versionId);
        });
    }
    const reg = /url\((['"]?)(.*)\1\)/gi;
    let result;
    let newCss = oldCss;
    while ((result = reg.exec(oldCss)) !== null) {
        const oldUrl = result[2];
        const parsedUrl = new URL(oldUrl, url);
        const fileName = path__default['default'].basename(parsedUrl.pathname);
        const versionId = urlVersionIds.get(fileName);
        if (!versionId) {
            continue;
        }
        parsedUrl.searchParams.set('s-hmr', versionId);
        newCss = newCss.replace(oldUrl, parsedUrl.pathname);
    }
    return newCss;
}
const urlVersionIds = new Map();
function appendDevServerClientScript(devServerConfig, req, content) {
    var _a, _b, _c;
    const devServerClientUrl = getDevServerClientUrl(devServerConfig, (_b = (_a = req.headers) === null || _a === void 0 ? void 0 : _a['x-forwarded-host']) !== null && _b !== void 0 ? _b : req.host, (_c = req.headers) === null || _c === void 0 ? void 0 : _c['x-forwarded-proto']);
    const iframe = `<iframe title="Stencil Dev Server Connector ${version} &#9889;" src="${devServerClientUrl}" style="display:block;width:0;height:0;border:0;visibility:hidden" aria-hidden="true"></iframe>`;
    return appendDevServerClientIframe(content, iframe);
}
function appendDevServerClientIframe(content, iframe) {
    if (content.includes('</body>')) {
        return content.replace('</body>', `${iframe}</body>`);
    }
    if (content.includes('</html>')) {
        return content.replace('</html>', `${iframe}</html>`);
    }
    return `${content}${iframe}`;
}

async function serveDevClient(devServerConfig, serverCtx, req, res) {
    try {
        if (isOpenInEditor(req.pathname)) {
            return serveOpenInEditor(serverCtx, req, res);
        }
        if (isDevServerClient(req.pathname)) {
            return serveDevClientScript(devServerConfig, serverCtx, req, res);
        }
        if (isInitialDevServerLoad(req.pathname)) {
            req.filePath = path__default['default'].join(devServerConfig.devServerDir, 'templates', 'initial-load.html');
        }
        else {
            const staticFile = req.pathname.replace(DEV_SERVER_URL + '/', '');
            req.filePath = path__default['default'].join(devServerConfig.devServerDir, 'static', staticFile);
        }
        try {
            req.stats = await serverCtx.sys.stat(req.filePath);
            if (req.stats.isFile) {
                return serveFile(devServerConfig, serverCtx, req, res);
            }
            return serverCtx.serve404(req, res, 'serveDevClient not file');
        }
        catch (e) {
            return serverCtx.serve404(req, res, `serveDevClient stats error ${e}`);
        }
    }
    catch (e) {
        return serverCtx.serve500(req, res, e, 'serveDevClient');
    }
}
async function serveDevClientScript(devServerConfig, serverCtx, req, res) {
    try {
        if (serverCtx.connectorHtml == null) {
            const filePath = path__default['default'].join(devServerConfig.devServerDir, 'connector.html');
            serverCtx.connectorHtml = serverCtx.sys.readFileSync(filePath, 'utf8');
            if (typeof serverCtx.connectorHtml !== 'string') {
                return serverCtx.serve404(req, res, `serveDevClientScript`);
            }
            const devClientConfig = {
                basePath: devServerConfig.basePath,
                editors: await getEditors(),
                reloadStrategy: devServerConfig.reloadStrategy,
            };
            serverCtx.connectorHtml = serverCtx.connectorHtml.replace('window.__DEV_CLIENT_CONFIG__', JSON.stringify(devClientConfig));
        }
        res.writeHead(200, responseHeaders({
            'content-type': 'text/html; charset=utf-8',
        }));
        res.write(serverCtx.connectorHtml);
        res.end();
    }
    catch (e) {
        return serverCtx.serve500(req, res, e, `serveDevClientScript`);
    }
}

async function serveDevNodeModule(serverCtx, req, res) {
    try {
        const results = await serverCtx.getCompilerRequest(req.pathname);
        const headers = {
            'content-type': 'application/javascript; charset=utf-8',
            'content-length': Buffer.byteLength(results.content, 'utf8'),
            'x-dev-node-module-id': results.nodeModuleId,
            'x-dev-node-module-version': results.nodeModuleVersion,
            'x-dev-node-module-resolved-path': results.nodeResolvedPath,
            'x-dev-node-module-cache-path': results.cachePath,
            'x-dev-node-module-cache-hit': results.cacheHit,
        };
        res.writeHead(results.status, responseHeaders(headers));
        res.write(results.content);
        res.end();
    }
    catch (e) {
        serverCtx.serve500(req, res, e, `serveDevNodeModule`);
    }
}

async function serveDirectoryIndex(devServerConfig, serverCtx, req, res) {
    const indexFilePath = path__default['default'].join(req.filePath, 'index.html');
    req.stats = await serverCtx.sys.stat(indexFilePath);
    if (req.stats.isFile) {
        req.filePath = indexFilePath;
        return serveFile(devServerConfig, serverCtx, req, res);
    }
    if (!req.pathname.endsWith('/')) {
        return serverCtx.serve302(req, res, req.pathname + '/');
    }
    try {
        const dirFilePaths = await serverCtx.sys.readDir(req.filePath);
        try {
            if (serverCtx.dirTemplate == null) {
                const dirTemplatePath = path__default['default'].join(devServerConfig.devServerDir, 'templates', 'directory-index.html');
                serverCtx.dirTemplate = serverCtx.sys.readFileSync(dirTemplatePath);
            }
            const files = await getFiles(serverCtx.sys, req.url, dirFilePaths);
            const templateHtml = serverCtx.dirTemplate
                .replace('{{title}}', getTitle(req.pathname))
                .replace('{{nav}}', getName(req.pathname))
                .replace('{{files}}', files);
            serverCtx.logRequest(req, 200);
            res.writeHead(200, responseHeaders({
                'content-type': 'text/html; charset=utf-8',
                'x-directory-index': req.pathname,
            }));
            res.write(templateHtml);
            res.end();
        }
        catch (e) {
            return serverCtx.serve500(req, res, e, 'serveDirectoryIndex');
        }
    }
    catch (e) {
        return serverCtx.serve404(req, res, 'serveDirectoryIndex');
    }
}
async function getFiles(sys, baseUrl, dirItemNames) {
    const items = await getDirectoryItems(sys, baseUrl, dirItemNames);
    if (baseUrl.pathname !== '/') {
        items.unshift({
            isDirectory: true,
            pathname: '../',
            name: '..',
        });
    }
    return items
        .map((item) => {
        return `
        <li class="${item.isDirectory ? 'directory' : 'file'}">
          <a href="${item.pathname}">
            <span class="icon"></span>
            <span>${item.name}</span>
          </a>
        </li>`;
    })
        .join('');
}
async function getDirectoryItems(sys, baseUrl, dirFilePaths) {
    const items = await Promise.all(dirFilePaths.map(async (dirFilePath) => {
        const fileName = path__default['default'].basename(dirFilePath);
        const url = new URL(fileName, baseUrl);
        const stats = await sys.stat(dirFilePath);
        const item = {
            name: fileName,
            pathname: url.pathname,
            isDirectory: stats.isDirectory,
        };
        return item;
    }));
    return items;
}
function getTitle(pathName) {
    return pathName;
}
function getName(pathName) {
    const dirs = pathName.split('/');
    dirs.pop();
    let url = '';
    return (dirs
        .map((dir, index) => {
        url += dir + '/';
        const text = index === 0 ? `~` : dir;
        return `<a href="${url}">${text}</a>`;
    })
        .join('<span>/</span>') + '<span>/</span>');
}

async function ssrPageRequest(devServerConfig, serverCtx, req, res) {
    try {
        let status = 500;
        let content = '';
        const { hydrateApp, srcIndexHtml, diagnostics } = await setupHydrateApp(devServerConfig, serverCtx);
        if (!diagnostics.some((diagnostic) => diagnostic.level === 'error')) {
            try {
                const opts = getSsrHydrateOptions(devServerConfig, serverCtx, req.url);
                const ssrResults = await hydrateApp.renderToString(srcIndexHtml, opts);
                diagnostics.push(...ssrResults.diagnostics);
                status = ssrResults.httpStatus;
                content = ssrResults.html;
            }
            catch (e) {
                catchError(diagnostics, e);
            }
        }
        if (diagnostics.some((diagnostic) => diagnostic.level === 'error')) {
            content = getSsrErrorContent(diagnostics);
            status = 500;
        }
        if (devServerConfig.websocket) {
            content = appendDevServerClientScript(devServerConfig, req, content);
        }
        serverCtx.logRequest(req, status);
        res.writeHead(status, responseHeaders({
            'content-type': 'text/html; charset=utf-8',
            'content-length': Buffer.byteLength(content, 'utf8'),
        }));
        res.write(content);
        res.end();
    }
    catch (e) {
        serverCtx.serve500(req, res, e, `ssrPageRequest`);
    }
}
async function ssrStaticDataRequest(devServerConfig, serverCtx, req, res) {
    try {
        const data = {};
        let httpCache = false;
        const { hydrateApp, srcIndexHtml, diagnostics } = await setupHydrateApp(devServerConfig, serverCtx);
        if (!diagnostics.some((diagnostic) => diagnostic.level === 'error')) {
            try {
                const { ssrPath, hasQueryString } = getSsrStaticDataPath(req);
                const url = new URL(ssrPath, req.url);
                const opts = getSsrHydrateOptions(devServerConfig, serverCtx, url);
                const ssrResults = await hydrateApp.renderToString(srcIndexHtml, opts);
                diagnostics.push(...ssrResults.diagnostics);
                ssrResults.staticData.forEach((s) => {
                    if (s.type === 'application/json') {
                        data[s.id] = JSON.parse(s.content);
                    }
                    else {
                        data[s.id] = s.content;
                    }
                });
                data.components = ssrResults.components.map((c) => c.tag).sort();
                httpCache = hasQueryString;
            }
            catch (e) {
                catchError(diagnostics, e);
            }
        }
        if (diagnostics.length > 0) {
            data.diagnostics = diagnostics;
        }
        const status = diagnostics.some((diagnostic) => diagnostic.level === 'error') ? 500 : 200;
        const content = JSON.stringify(data);
        serverCtx.logRequest(req, status);
        res.writeHead(status, responseHeaders({
            'content-type': 'application/json; charset=utf-8',
            'content-length': Buffer.byteLength(content, 'utf8'),
        }, httpCache && status === 200));
        res.write(content);
        res.end();
    }
    catch (e) {
        serverCtx.serve500(req, res, e, `ssrStaticDataRequest`);
    }
}
async function setupHydrateApp(devServerConfig, serverCtx) {
    let srcIndexHtml = null;
    let hydrateApp = null;
    const buildResults = await serverCtx.getBuildResults();
    const diagnostics = [];
    if (serverCtx.prerenderConfig == null && isString(devServerConfig.prerenderConfig)) {
        const compilerPath = path__default['default'].join(devServerConfig.devServerDir, '..', 'compiler', 'stencil.js');
        const compiler = require(compilerPath);
        const prerenderConfigResults = compiler.nodeRequire(devServerConfig.prerenderConfig);
        diagnostics.push(...prerenderConfigResults.diagnostics);
        if (prerenderConfigResults.module && prerenderConfigResults.module.config) {
            serverCtx.prerenderConfig = prerenderConfigResults.module.config;
        }
    }
    if (!isString(buildResults.hydrateAppFilePath)) {
        diagnostics.push({ messageText: `Missing hydrateAppFilePath`, level: `error`, type: `ssr` });
    }
    else if (!isString(devServerConfig.srcIndexHtml)) {
        diagnostics.push({ messageText: `Missing srcIndexHtml`, level: `error`, type: `ssr` });
    }
    else {
        srcIndexHtml = await serverCtx.sys.readFile(devServerConfig.srcIndexHtml);
        if (!isString(srcIndexHtml)) {
            diagnostics.push({
                messageText: `Unable to load src index html: ${devServerConfig.srcIndexHtml}`,
                level: `error`,
                type: `ssr`,
            });
        }
        else {
            // ensure we cleared out node's internal require() cache for this file
            const hydrateAppFilePath = path__default['default'].resolve(buildResults.hydrateAppFilePath);
            // brute force way of clearning node's module cache
            // not using `delete require.cache[id]` since it'll cause memory leaks
            require.cache = {};
            const Module = require('module');
            Module._cache[hydrateAppFilePath] = undefined;
            hydrateApp = require(hydrateAppFilePath);
        }
    }
    return {
        hydrateApp,
        srcIndexHtml,
        diagnostics,
    };
}
function getSsrHydrateOptions(devServerConfig, serverCtx, url) {
    const opts = {
        url: url.href,
        addModulePreloads: false,
        approximateLineWidth: 120,
        inlineExternalStyleSheets: false,
        minifyScriptElements: false,
        minifyStyleElements: false,
        removeAttributeQuotes: false,
        removeBooleanAttributeQuotes: false,
        removeEmptyAttributes: false,
        removeHtmlComments: false,
        prettyHtml: true,
    };
    const prerenderConfig = serverCtx === null || serverCtx === void 0 ? void 0 : serverCtx.prerenderConfig;
    if (isFunction(prerenderConfig === null || prerenderConfig === void 0 ? void 0 : prerenderConfig.hydrateOptions)) {
        const userOpts = prerenderConfig.hydrateOptions(url);
        if (userOpts) {
            Object.assign(opts, userOpts);
        }
    }
    if (isFunction(serverCtx.sys.applyPrerenderGlobalPatch)) {
        const orgBeforeHydrate = opts.beforeHydrate;
        opts.beforeHydrate = (document) => {
            // patch this new window with the fetch global from node-fetch
            const devServerBaseUrl = new URL(devServerConfig.browserUrl);
            const devServerHostUrl = devServerBaseUrl.origin;
            serverCtx.sys.applyPrerenderGlobalPatch({
                devServerHostUrl: devServerHostUrl,
                window: document.defaultView,
            });
            if (typeof orgBeforeHydrate === 'function') {
                return orgBeforeHydrate(document);
            }
        };
    }
    return opts;
}
function getSsrErrorContent(diagnostics) {
    return `<!doctype html>
<html>
<head>
  <title>SSR Error</title>
  <style>
    body {
      font-family: Consolas, 'Liberation Mono', Menlo, Courier, monospace !important;
    }
  </style>
</head>
<body>
  <h1>SSR Dev Error</h1>
  ${diagnostics.map((diagnostic) => `
  <p>
    ${diagnostic.messageText}
  </p>
  `)}
</body>
</html>`;
}

function createRequestHandler(devServerConfig, serverCtx) {
    let userRequestHandler = null;
    if (typeof devServerConfig.requestListenerPath === 'string') {
        userRequestHandler = require(devServerConfig.requestListenerPath);
    }
    return async function (incomingReq, res) {
        async function defaultHandler() {
            try {
                const req = normalizeHttpRequest(devServerConfig, incomingReq);
                if (!req.url) {
                    return serverCtx.serve302(req, res);
                }
                if (isDevClient(req.pathname) && devServerConfig.websocket) {
                    return serveDevClient(devServerConfig, serverCtx, req, res);
                }
                if (isDevModule(req.pathname)) {
                    return serveDevNodeModule(serverCtx, req, res);
                }
                if (!isValidUrlBasePath(devServerConfig.basePath, req.url)) {
                    return serverCtx.serve404(req, res, `invalid basePath`, `404 File Not Found, base path: ${devServerConfig.basePath}`);
                }
                if (devServerConfig.ssr) {
                    if (isExtensionLessPath(req.url.pathname)) {
                        return ssrPageRequest(devServerConfig, serverCtx, req, res);
                    }
                    if (isSsrStaticDataPath(req.url.pathname)) {
                        return ssrStaticDataRequest(devServerConfig, serverCtx, req, res);
                    }
                }
                req.stats = await serverCtx.sys.stat(req.filePath);
                if (req.stats.isFile) {
                    return serveFile(devServerConfig, serverCtx, req, res);
                }
                if (req.stats.isDirectory) {
                    return serveDirectoryIndex(devServerConfig, serverCtx, req, res);
                }
                const xSource = ['notfound'];
                const validHistoryApi = isValidHistoryApi(devServerConfig, req);
                xSource.push(`validHistoryApi: ${validHistoryApi}`);
                if (validHistoryApi) {
                    try {
                        const indexFilePath = path__default['default'].join(devServerConfig.root, devServerConfig.historyApiFallback.index);
                        xSource.push(`indexFilePath: ${indexFilePath}`);
                        req.stats = await serverCtx.sys.stat(indexFilePath);
                        if (req.stats.isFile) {
                            req.filePath = indexFilePath;
                            return serveFile(devServerConfig, serverCtx, req, res);
                        }
                    }
                    catch (e) {
                        xSource.push(`notfound error: ${e}`);
                    }
                }
                return serverCtx.serve404(req, res, xSource.join(', '));
            }
            catch (e) {
                return serverCtx.serve500(incomingReq, res, e, `not found error`);
            }
        }
        if (typeof userRequestHandler === 'function') {
            await userRequestHandler(incomingReq, res, defaultHandler);
        }
        else {
            await defaultHandler();
        }
    };
}
function isValidUrlBasePath(basePath, url) {
    // normalize the paths to always end with a slash for the check
    let pathname = url.pathname;
    if (!pathname.endsWith('/')) {
        pathname += '/';
    }
    if (!basePath.endsWith('/')) {
        basePath += '/';
    }
    return pathname.startsWith(basePath);
}
function normalizeHttpRequest(devServerConfig, incomingReq) {
    const req = {
        method: (incomingReq.method || 'GET').toUpperCase(),
        headers: incomingReq.headers,
        acceptHeader: (incomingReq.headers && typeof incomingReq.headers.accept === 'string' && incomingReq.headers.accept) || '',
        host: (incomingReq.headers && typeof incomingReq.headers.host === 'string' && incomingReq.headers.host) || null,
        url: null,
        searchParams: null,
    };
    const incomingUrl = (incomingReq.url || '').trim() || null;
    if (incomingUrl) {
        if (req.host) {
            req.url = new URL(incomingReq.url, `http://${req.host}`);
        }
        else {
            req.url = new URL(incomingReq.url, `http://dev.stenciljs.com`);
        }
        req.searchParams = req.url.searchParams;
    }
    if (req.url) {
        const parts = req.url.pathname.replace(/\\/g, '/').split('/');
        req.pathname = parts.map((part) => decodeURIComponent(part)).join('/');
        if (req.pathname.length > 0 && !isDevClient(req.pathname)) {
            req.pathname = '/' + req.pathname.substring(devServerConfig.basePath.length);
        }
        req.filePath = normalizePath(path__default['default'].normalize(path__default['default'].join(devServerConfig.root, path__default['default'].relative('/', req.pathname))));
    }
    return req;
}
function isValidHistoryApi(devServerConfig, req) {
    if (!devServerConfig.historyApiFallback) {
        return false;
    }
    if (req.method !== 'GET') {
        return false;
    }
    if (!req.acceptHeader.includes('text/html')) {
        return false;
    }
    if (!devServerConfig.historyApiFallback.disableDotRule && req.pathname.includes('.')) {
        return false;
    }
    return true;
}

function createHttpServer(devServerConfig, serverCtx) {
    // create our request handler
    const reqHandler = createRequestHandler(devServerConfig, serverCtx);
    const credentials = devServerConfig.https;
    return credentials ? https__namespace.createServer(credentials, reqHandler) : http__namespace.createServer(reqHandler);
}
async function findClosestOpenPort(host, port) {
    async function t(portToCheck) {
        const isTaken = await isPortTaken(host, portToCheck);
        if (!isTaken) {
            return portToCheck;
        }
        return t(portToCheck + 1);
    }
    return t(port);
}
function isPortTaken(host, port) {
    return new Promise((resolve, reject) => {
        const tester = net__namespace
            .createServer()
            .once('error', () => {
            resolve(true);
        })
            .once('listening', () => {
            tester
                .once('close', () => {
                resolve(false);
            })
                .close();
        })
            .on('error', (err) => {
            reject(err);
        })
            .listen(port, host);
    });
}

function createWebSocket(httpServer, onMessageFromClient) {
    const wsConfig = {
        server: httpServer,
    };
    const wsServer = new ws__namespace.Server(wsConfig);
    function heartbeat() {
        // we need to coerce the `ws` type to our custom `DevWS` type here, since
        // this function is going to be passed in to `ws.on('pong'` which expects
        // to be passed a functon where `this` is bound to `ws`.
        this.isAlive = true;
    }
    wsServer.on('connection', (ws) => {
        ws.on('message', (data) => {
            // the server process has received a message from the browser
            // pass the message received from the browser to the main cli process
            try {
                onMessageFromClient(JSON.parse(data.toString()));
            }
            catch (e) {
                console.error(e);
            }
        });
        ws.isAlive = true;
        ws.on('pong', heartbeat);
        // ignore invalid close frames sent by Safari 15
        ws.on('error', console.error);
    });
    const pingInternval = setInterval(() => {
        wsServer.clients.forEach((ws) => {
            if (!ws.isAlive) {
                return ws.close(1000);
            }
            ws.isAlive = false;
            ws.ping(noop);
        });
    }, 10000);
    return {
        sendToBrowser: (msg) => {
            if (msg && wsServer && wsServer.clients) {
                const data = JSON.stringify(msg);
                wsServer.clients.forEach((ws) => {
                    if (ws.readyState === ws.OPEN) {
                        ws.send(data);
                    }
                });
            }
        },
        close: () => {
            return new Promise((resolve, reject) => {
                clearInterval(pingInternval);
                wsServer.clients.forEach((ws) => {
                    ws.close(1000);
                });
                wsServer.close((err) => {
                    if (err) {
                        reject(err);
                    }
                    else {
                        resolve();
                    }
                });
            });
        },
    };
}

function initServerProcess(sendMsg) {
    let server = null;
    let webSocket = null;
    let serverCtx = null;
    const buildResultsResolves = [];
    const compilerRequestResolves = [];
    const startServer = async (msg) => {
        const devServerConfig = msg.startServer;
        devServerConfig.port = await findClosestOpenPort(devServerConfig.address, devServerConfig.port);
        devServerConfig.browserUrl = getBrowserUrl(devServerConfig.protocol, devServerConfig.address, devServerConfig.port, devServerConfig.basePath, '/');
        devServerConfig.root = normalizePath(devServerConfig.root);
        const sys = index_js.createNodeSys({ process });
        serverCtx = createServerContext(sys, sendMsg, devServerConfig, buildResultsResolves, compilerRequestResolves);
        server = createHttpServer(devServerConfig, serverCtx);
        webSocket = devServerConfig.websocket ? createWebSocket(server, sendMsg) : null;
        server.listen(devServerConfig.port, devServerConfig.address);
        serverCtx.isServerListening = true;
        if (devServerConfig.openBrowser) {
            const initialLoadUrl = getBrowserUrl(devServerConfig.protocol, devServerConfig.address, devServerConfig.port, devServerConfig.basePath, devServerConfig.initialLoadUrl || DEV_SERVER_INIT_URL);
            openInBrowser({ url: initialLoadUrl });
        }
        sendMsg({ serverStarted: devServerConfig });
    };
    const closeServer = () => {
        const promises = [];
        buildResultsResolves.forEach((r) => r.reject('dev server closed'));
        buildResultsResolves.length = 0;
        compilerRequestResolves.forEach((r) => r.reject('dev server closed'));
        compilerRequestResolves.length = 0;
        if (serverCtx) {
            if (serverCtx.sys) {
                promises.push(serverCtx.sys.destroy());
            }
        }
        if (webSocket) {
            promises.push(webSocket.close());
            webSocket = null;
        }
        if (server) {
            promises.push(new Promise((resolve) => {
                server.close((err) => {
                    if (err) {
                        console.error(`close error: ${err}`);
                    }
                    resolve();
                });
            }));
        }
        Promise.all(promises).finally(() => {
            sendMsg({
                serverClosed: true,
            });
        });
    };
    const receiveMessageFromMain = (msg) => {
        // the server process received a message from main thread
        try {
            if (msg) {
                if (msg.startServer) {
                    startServer(msg);
                }
                else if (msg.closeServer) {
                    closeServer();
                }
                else if (msg.compilerRequestResults) {
                    for (let i = compilerRequestResolves.length - 1; i >= 0; i--) {
                        const r = compilerRequestResolves[i];
                        if (r.path === msg.compilerRequestResults.path) {
                            r.resolve(msg.compilerRequestResults);
                            compilerRequestResolves.splice(i, 1);
                        }
                    }
                }
                else if (serverCtx) {
                    if (msg.buildResults && !msg.isActivelyBuilding) {
                        buildResultsResolves.forEach((r) => r.resolve(msg.buildResults));
                        buildResultsResolves.length = 0;
                    }
                    if (webSocket) {
                        webSocket.sendToBrowser(msg);
                    }
                }
            }
        }
        catch (e) {
            let stack = null;
            if (e instanceof Error) {
                stack = e.stack;
            }
            sendMsg({
                error: { message: e + '', stack },
            });
        }
    };
    return receiveMessageFromMain;
}

exports.initServerProcess = initServerProcess;
