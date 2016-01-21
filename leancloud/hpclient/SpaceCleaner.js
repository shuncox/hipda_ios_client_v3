var AV = require('leanengine');
var Qiniu = require('node-qiniu');
var QiniuUtil = require('leanengine/node_modules/avoscloud-sdk/node_modules/qiniu');
var Reporter = require('./Reporter');
var Util = require('./Util');

/*
./qiniuKey.js
	exports.Qiniu_ACCESS_KEY = 'xx';
	exports.Qiniu_SECRET_KEY = 'xx';
*/
var ACCESS_KEY = require('./qiniuKey').Qiniu_ACCESS_KEY;
var SECRET_KEY = require('./qiniuKey').Qiniu_SECRET_KEY;
Qiniu.config({
	access_key: ACCESS_KEY,
	secret_key: SECRET_KEY,
});
QiniuUtil.conf.ACCESS_KEY = ACCESS_KEY;
QiniuUtil.conf.SECRET_KEY = SECRET_KEY;

var SPACE_LIMIT = 8000000000; // 8G

exports.clean = function() {

	var host = 'http://api.qiniu.com';
	var path = '/stat/info?bucket=hpimg&month='+Util.getMonthKey();
	var policy = new Qiniu.Token.AccessToken();
	var token = policy.token(path);
	console.log('token ' + token);

	var reportDesp = '';

	AV.Cloud.httpRequest({
		url: host+path,
		headers: {'Authorization': token},
		success: function(httpResponse) {
			
			console.log('space ' + httpResponse.data.space);
			console.log('transfer ' + httpResponse.data.transfer);
			reportDesp += 'space: ' + (+httpResponse.data.space/1000000000).toFixed(2) + 'g\n';
			reportDesp += 'transfer: ' + (+httpResponse.data.transfer/1000000000).toFixed(2) + 'g\n';

			getAllFiles().then(function(files) {
				console.log('files count ' + files.length);
				
				files = files.sort(function (a, b) { return a.putTime - b.putTime; });
				var paths = [];
				var currentSize = httpResponse.data.space;
				var sum = currentSize - SPACE_LIMIT;
				for (var i = 0; i < files.length; i++) {

					if (sum <= 0) {
						console.log('finish collect files to delete');
						reportDesp += 'will delete ' + paths.length + ' files\n';
						break;
					} else {
						console.log('continue sum ' + sum);
					}

					/*
						fsize: 84115
						hash: "FmUrEpxvfxWGPfiRmNgCO9vuONM3"
						key: "forum/attachments/day_130416/1304161401c921ac56a22d5941.jpg
						"mimeType: "image/jpeg"
						putTime: 14529251800962786
					*/

					var file = files[i];
					var fsize = file.fsize;
					var putTime = file.putTime;

					console.log('fsize ' + fsize);
					console.log('putTime ' + new Date(putTime/10000));

					paths.push(new QiniuUtil.rs.EntryPath('hpimg', file.key));

					sum -= fsize;
				}

				if (paths.length == 0) {
					console.log('no need clean');
					Reporter.report('cut space, no need clean', reportDesp);
					return;
				}
				var client = new QiniuUtil.rs.Client();
				client.batchDelete(paths, function(err, ret) {
					if (!err) {
						for (i in ret) {
							if (ret[i].code !== 200) {
								console.log(ret[i].code, ret[i].data);
								reportDesp += 'batchDelete item error: ' + ret + '\n'
							}
						}
						reportDesp += 'done';
						Reporter.report('cut space', reportDesp);
					} else {
						console.log(err);
						
						reportDesp += 'error: ' + err + '\n'
						Reporter.report('cut space error batchDelete', reportDesp);
					}
				});

			}, function(error) {
				console.log(error);
				Reporter.report('cut space error', {url: 'getAllFiles', errMsg: error});
			});
		},
		error: function(httpResponse) {
			console.log('load url error: ' + url + ', ' + httpResponse);
			Reporter.report('cut space error', {url: url, errMsg: httpResponse});
		}
	});
}

function getAllFiles() {
	var promise = new AV.Promise(function(resolve, reject){
		_getAllFiles(null, [], function(items) {
			resolve(items);
		}, function(error) {
			reject(error);
		});
	});
	return promise;
}

function _getAllFiles(marker, items, success, error) {
	QiniuUtil.rsf.listPrefix('hpimg', '', marker, 1000, function(err, ret) {
		console.log('items count ' + ret.items.length);
		console.log('maker ' + ret.marker);
		if (!err) {
			items = items.concat(ret.items);

			if (!ret.marker) {
				success(items);
			} else {
				_getAllFiles(ret.marker, items, success, error);
			}
		} else {
			error(err);
		}
	});
}