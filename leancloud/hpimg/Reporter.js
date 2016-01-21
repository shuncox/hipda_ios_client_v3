var AV = require('leanengine');
var PUSH_URL = 'http://sc.'+'ft'+'qq'+'.com/SCU898Tec0e33d62f0fc6d2da4813732f4726ca569da35b97d4c.send';

exports.report = function(text, desp) {
	var url = PUSH_URL + '?text='+text+'&desp='+desp;
	AV.Cloud.httpRequest({
		url: url,
		success: function(httpResponse) {
			console.log('send report success: ' + url);
		},
		error: function(httpResponse) {
			console.log('send report error: ' + url);
		}
	});	
}