//_OC_log("test");
/*
//修复gb2312Data2String的溢出
defineClass('HPHttpClient', {}, {
    gb2312Data2String: function(data) {
        _OC_log("here");
        var dd = require('NSMutableData').dataWithData(data);
        // NSMakeRange(i, 10)(潜在的溢出) 只会在第二个分支
        // " " < 0x7f 应进入第一个分支
        var aaa = require('NSString').stringWithString("          ");
        dd.appendData(aaa.dataUsingEncoding(1));
        
        return self.ORIGgb2312Data2String(dd);
    },
});
*/
/* //gb2312Data2String里有溢出
//static NSDictionary *defineClass(NSString *classDeclaration, JSValue *instanceMethods, JSValue *classMethods)
defineClass('HPHttpClient', {}, {
    gb2312Data2String: function(data) {
        //_OC_log("here");
        return null;
    },
});
*/
/*
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
    processFuckContentHTML: function() {
        var html = self.body__html();
        html = html.stringByAppendingString("@@@attachments/day_@@@");
        self.setBody__html(html);
        
        self.ORIGprocessFuckContentHTML();
        
        var html = self.body__html();
        html = html.stringByReplacingOccurrencesOfString_withString("@@@attachments/day_@@@", "");
        self.setBody__html(html);
    },
})
*/
