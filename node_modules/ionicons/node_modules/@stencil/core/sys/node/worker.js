/*!
 Stencil Node System Worker v2.22.3 | MIT Licensed | https://stenciljs.com
 */
function _interopNamespace(e) {
 if (e && e.__esModule) return e;
 var n = Object.create(null);
 return e && Object.keys(e).forEach((function(r) {
  if ("default" !== r) {
   var t = Object.getOwnPropertyDescriptor(e, r);
   Object.defineProperty(n, r, t.get ? t : {
    enumerable: !0,
    get: function() {
     return e[r];
    }
   });
  }
 })), n.default = e, n;
}

require("../../compiler/stencil.js");

const nodeApi__namespace = _interopNamespace(require("./index.js")), coreCompiler = global.stencil, nodeSys = nodeApi__namespace.createNodeSys({
 process
}), msgHandler = coreCompiler.createWorkerMessageHandler(nodeSys);

((e, n) => {
 const r = n => {
  n && "ERR_IPC_CHANNEL_CLOSED" === n.code && e.exit(0);
 }, t = (n, t) => {
  const s = {
   stencilId: n,
   stencilRtnValue: null,
   stencilRtnError: "Error"
  };
  "string" == typeof t ? s.stencilRtnError += ": " + t : t && (t.stack ? s.stencilRtnError += ": " + t.stack : t.message && (s.stencilRtnError += ":" + t.message)), 
  e.send(s, r);
 };
 e.on("message", (async s => {
  if (s && "number" == typeof s.stencilId) try {
   const t = {
    stencilId: s.stencilId,
    stencilRtnValue: await n(s),
    stencilRtnError: null
   };
   e.send(t, r);
  } catch (e) {
   t(s.stencilId, e);
  }
 })), e.on("unhandledRejection", (e => {
  t(-1, e);
 }));
})(process, msgHandler);