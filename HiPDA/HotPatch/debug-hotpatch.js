//_OC_log("test");
// fix ip change
defineClass("HPURLMappingProvider", {
    apiToolsHostForOriginalURLHost: function(originalURLHost) {
        var d = {"www.hi-pda.com": "58.215.45.20", "cnc.hi-pda.com": "58.215.45.20"};
        return d[originalURLHost.toJS()];
    },
})