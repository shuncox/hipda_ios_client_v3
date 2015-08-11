//_OC_log("test");

// fix ip change
defineClass("HPURLMappingProvider", {
    apiToolsHostForOriginalURLHost: function(originalURLHost) {
        var d = {"www.hi-pda.com": "58.215.45.20", "cnc.hi-pda.com": "58.215.45.20"};
        return d[originalURLHost.toJS()];
    },
})

// fix image format change
defineClass("HPNewPost", {
    processContentHTML: function() {
        self.ORIGprocessContentHTML();
        
        if (!self.images()) return;
        
        // fix imges
        var a = self.images();
        var b = require('NSMutableArray').alloc().init();
        for (var i=0; i < a.count(); i++) {
            if (a.objectAtIndex(i).rangeOfString("attachments/day_").length > 0) {
              b.addObject(a.objectAtIndex(i));
            }
        }
        
        self.setImages(b);
        
        // fix body_html
        var html = self.body__html();
        for (var i=0; i < b.count(); i++) {
        
            var s = b.objectAtIndex(i);
            s = s.stringByReplacingOccurrencesOfString_withString("http://www.hi-pda.com/forum/", "");
            s = s.stringByReplacingOccurrencesOfString_withString("http://cnc.hi-pda.com/forum/", "");
        
            html = html.stringByReplacingOccurrencesOfString_withString('<img class="attach_image" src="'+s.toJS()+'" />', "");
        }
    
        self.setBody__html(html);
    },
})

