var AV = require('leanengine');
var Qiniu = require('node-qiniu');
var QiniuUtil = require('leanengine/node_modules/avoscloud-sdk/node_modules/qiniu');

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

var LOG = AV.Object.extend('ScheduleLog');

/*
整个文件在云引擎上是以单例形式活着的, 也就是说, 不同云函数可以访问到同一个全局变量
*/

var headers =  {
	'Cookie': 'cdb_auth=0a32%2FQ%2Fd8iZY8aW5qHtZVl6ebS%2Bpnj2FwidXgpu%2B4RSJ1EL1BEZGQRln8QWLsbeOCOkfFpdP%2FPclrjhzUz9CblTDX8mt;',
	'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.71 Safari/537.36',
};

var PUSH_URL = 'http://sc.'+'ft'+'qq'+'.com/SCU898Tec0e33d62f0fc6d2da4813732f4726ca569da35b97d4c.send';

var TIDS_BUCKET = [];
var LIMIT = 2222;  //之前三个板块每天总共能收集2000个帖子, 现在限制limit的目的是避免频繁访问一个tid

var SPACE_LIMIT = 8000000000; // 8G

var TODAY_REPORT_DEFAULT = {
	day:'',
	newTidsCount: 0,
	newImagesCount: 0,
	newImagesSizeCount: 0,
	errors: [], // {url: errMsg}
};
var TODAY_REPORT = JSON.parse(JSON.stringify(TODAY_REPORT_DEFAULT));

AV.Cloud.define('D-new-topic', function(request, response) {
	response.success('Hello world!');
	schedule([
		{fid:'2', orderby:'dateline', page:1},
	], 'D-new-topic');
});

AV.Cloud.define('D-hot-topic', function(request, response) {
	response.success('Hello world!');
	schedule([
		{fid:'2', orderby:'lastpost', page:1},
		{fid:'2', orderby:'lastpost', page:2},
		{fid:'2', orderby:'lastpost', page:3},
	], 'D-hot-topic');
});

AV.Cloud.define('BS-new-topic', function(request, response) {
	response.success('Hello world!');
	schedule([
		{fid:'6', orderby:'dateline', page:1},
	], 'BS-new-topic');
});

AV.Cloud.define('BS-hot-topic', function(request, response) {
	response.success('Hello world!');
	schedule([
		{fid:'6', orderby:'lastpost', page:1},
		{fid:'6', orderby:'lastpost', page:2},
		{fid:'6', orderby:'lastpost', page:3},
	], 'BS-hot-topic');
});

AV.Cloud.define('EINK-new-topic', function(request, response) {
	response.success('Hello world!');
	schedule([
		{fid:'59', orderby:'dateline', page:1},
	], 'EINK-new-topic');
});

AV.Cloud.define('EINK-hot-topic', function(request, response) {
	response.success('Hello world!');
	schedule([
		{fid:'59', orderby:'lastpost', page:1},
		{fid:'59', orderby:'lastpost', page:2},
		{fid:'59', orderby:'lastpost', page:3},
	], 'EINK-hot-topic');
});

AV.Cloud.define('send-report', function(request, response) {
	response.success('Hello world!');
	reportStatus();
});

function schedule(paramsArray, name) {

	var query = new AV.Query(LOG);
	query.equalTo('name', name); //这里的bucket其实是一个bucket, 但是六个函数都log下, 便于查看
	query.first()
	.then(function(object) {
		if (!object) {
			object = LOG.new({name:name, bucket: TIDS_BUCKET, report: TODAY_REPORT});
			object.save();
			console.log('create a new LOG ' + object);
		}
		return object;
	})
	.then(function(log){
		/*
		 leancloud 函数只能存活大概半小时
		 我们十分钟重启一次 600s 云引擎那里设成 630s
		*/

		TIDS_BUCKET = log.get('bucket');
		TODAY_REPORT = log.get('report');

		var SEC = 1000;
		var limit = 10 * 60 * SEC;
		var timer = setInterval(function(){
			console.log(name);
			var promises = [];
			for (var i = 0; i < paramsArray.length; i++) {
				promises.push(getTidsForForum(paramsArray[i]));
			}
			fire(promises);

			limit -= SEC;
			console.log(limit);
			if (limit <= 0) {
				console.log('cencel');
				clearInterval(timer);

				log.save({bucket: TIDS_BUCKET, report: TODAY_REPORT});

				// 不起作用 还是会被干掉
				/*
				AV.Cloud.run(name, {}, {
					success: function(data){
						console.log(data);
					},
					error: function(err){
						console.log(err);
					}
				});*/
			}
		}, SEC); 
	});
}

function fire(promises) {
	AV.Promise.all(promises).then(function (values) {
		var tids = [].concat.apply([], values);
		tids = uniq(tids);

		var newTids = filterTids(tids, TIDS_BUCKET);

		TODAY_REPORT.newTidsCount += newTids.length;

		console.log('TIDS_BUCKET ' + TIDS_BUCKET.length + ', current ' + tids.length + ', new ' + newTids.length);
		if (newTids.length <= 0) {
			return;
		}

		TIDS_BUCKET = TIDS_BUCKET.concat(newTids);
		while (TIDS_BUCKET.length > LIMIT) {
			TIDS_BUCKET.shift();
		}

		(function loop(i, newTids) {     
			var tid = newTids[i]; 

			(function(tid) {
				setTimeout(function () {   
					getImagesForThread(tid).then(function(images) {
						if (images.length) {
							console.log('get imageNames :');
							console.log(images);

							TODAY_REPORT.newImagesCount += images.length;

							pingImages(images);
						} else {
							console.log('get imageName - empty, tid ' + tid);
						}
					}, function(error) {
						console.error('getImagesForThread error ' + error + ', tid ' + tid);

						// remove tid for TIDS_BUCKET
						var index = TIDS_BUCKET.indexOf(tid);
						if (index > -1) {
							TIDS_BUCKET.splice(index, 1);
						}
					});

					i--;
					if (i >= 0) loop(i, newTids);
				}, 10);
			})(tid);

		})(newTids.length-1, newTids);
	}, function(error){
		console.log('get tids error :');
		console.log(error);
	});
}

// {fid:'2', orderby:'dateline|lastpost', page:1}
function getForumHTMLParames(params, success, error) {
	var p = serialize(params);
	var url = 'http://www.hi-pda.com/forum/forumdisplay.php?'+p;
	//console.log('load url: ' + url);
	//如果你的日志输出过于频繁（超过 50 条/秒），我们会丢弃部分日志信息。
	AV.Cloud.httpRequest({
		url: url,
		headers: headers,
		success: function(httpResponse) {
			success(httpResponse);
		},
		error: function(httpResponse) {
			console.log('load url error: ' + url);
			TODAY_REPORT.errors.push({url: url, errMsg: httpResponse});

			error(httpResponse);
		}
	});
}

function findThreads(html) {
	
	var input = html;
	var regex = /normalthread_(\d+)/g;

	var matches, output = [];
	while (matches = regex.exec(input)) {
		output.push(matches[1]);
	}

	var tids = output;
	return tids;
}

function getTidsForForum(params) {
	var promise = new AV.Promise(function(resolve, reject){
		getForumHTMLParames(params, function(httpResponse) {
			var tids = findThreads(httpResponse.text);
			resolve(tids);
		}, function(httpResponse) {
			reject(httpResponse.status);
		});
	});
	return promise;
}

function getThreadHTML(tid, success, error) {
	var url = 'http://www.hi-pda.com/forum/viewthread.php?tid='+tid;
	AV.Cloud.httpRequest({
		url: url,
		headers: headers,
		success: function(httpResponse) {
			success(httpResponse);
		},
		error: function(httpResponse) {
			TODAY_REPORT.errors.push({url: url, errMsg: httpResponse});
			error(httpResponse);
		}
	});
}

function filterTids(tids, oldTids) {
	var newTids = [];
	for (var i = 0; i < tids.length; i++) {
		var tid = tids[i];

		var exist = false;
		for (var j = 0; j < oldTids.length; j++) {
			if (tid === oldTids[j]) {
				exist = true;
				break;
			}
		}

		if (!exist) {
			newTids.push(tid);
			console.log('new tid ' + tid);
		}
	}
	return newTids;
}

function findImages(html) {
	
	var input = html;
	var regex = /"attachments\/(.*?)"/g;

	var matches, output = [];
	while (matches = regex.exec(input)) {
		output.push(matches[1]);
	}

	var images = uniq(output);
	return images;
}

function getImagesForThread(tid) {
	var promise = new AV.Promise(function(resolve, reject){
		getThreadHTML(tid, function(httpResponse) {
			var images = findImages(httpResponse.text);
			resolve(images);
		}, function(httpResponse) {
			reject(httpResponse.status);
		});
	});
	return promise;
}

function pingImages(imageNames) {
	for (var i = 0; i < imageNames.length; i++) {
		var imageName = imageNames[i];

		var url = 'http://7xq2vp.com1.z0.glb.clouddn.com/forum/attachments/'+ imageName + '-test';
		console.log('ping image ' + url);

		(function(url) {
			AV.Cloud.httpRequest({
				url: url,
				success: function(httpResponse) {
					console.log('ping image success ' + url);
				},
				error: function(httpResponse) {
					console.log('ping image error ' + url);
					TODAY_REPORT.errors.push({url: url, errMsg: httpResponse});
				}
			});
		})(url);
	}
}

function reportStatus() {
	
	var day = dayString(new Date());
	if (TODAY_REPORT.day === '') {
		TODAY_REPORT.day = day;
	}

	var text = day;
	var desp = JSON.stringify(TODAY_REPORT);
	report(text, desp);

	TODAY_REPORT = JSON.parse(JSON.stringify(TODAY_REPORT_DEFAULT));
}

function report(text, desp) {
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

//http://stackoverflow.com/questions/9229645/remove-duplicates-from-javascript-array
function uniq(a) {
    var seen = {};
    return a.filter(function(item) {
        return seen.hasOwnProperty(item) ? false : (seen[item] = true);
    });
}

function dayString (date) {
    var local = new Date(date);
    local.setMinutes(date.getMinutes() - date.getTimezoneOffset());
    //return local.toJSON().slice(0, 10);
    return local.toJSON().slice(0, 14); // for debug, hour report
}

function shortDateString (date) {
    var local = new Date(date);
    local.setMinutes(date.getMinutes() - date.getTimezoneOffset());
    return local.toJSON().slice(5, 19);
}

function getTodayDateKey () {
	var date = new Date();
	date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
	return date.toJSON().slice(0, 10);
}

function getMonthKey () {
	// 201601
	var date = new Date();
	date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
	return date.toJSON().slice(0, 7).replace('-', '');
};

function serialize(obj) {
  var str = [];
  for(var p in obj)
     str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
  return str.join("&");
}


//================ CutSpaceToLimit ==================//
AV.Cloud.define('CutSpaceToLimit', function(request, response) {
	response.success('Hello world!');

	var host = 'http://api.qiniu.com';
	var path = '/stat/info?bucket=hpimg&month='+getMonthKey();
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
						console.log('finish');
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

					console.log('fsize' + fsize);
					console.log('putTime' + putTime);

					paths.push(new QiniuUtil.rs.EntryPath('hpimg', file.key));

					sum -= fsize;
				}

				if (paths.length == 0) {
					console.log('no need clean');
					report('cut space, no need clean', reportDesp);
					return;
				}
				var client = new QiniuUtil.rs.Client();
				client.batchDelete(paths, function(err, ret) {
					if (!err) {
						for (i in ret) {
							if (ret[i].code !== 200) {
								console.log(ret[i].code, ret[i].data);
								TODAY_REPORT.errors.push({url: 'batchDelete - item', errMsg: ret});
								reportDesp += 'error: ' + ret + '\n'
							}
						}
						reportDesp += 'done';
						report('cut space', reportDesp);
					} else {
						console.log(err);
						TODAY_REPORT.errors.push({url: 'batchDelete', errMsg: err});
						
						reportDesp += 'error: ' + err + '\n'
						report('cut space error', reportDesp);
					}
				});

			}, function(error) {
				console.log(error);
				TODAY_REPORT.errors.push({url: 'getAllFiles', errMsg: error});
			});
		},
		error: function(httpResponse) {
			console.log('load url error: ' + url + ', ' + httpResponse);
			TODAY_REPORT.errors.push({url: url, errMsg: httpResponse});
		}
	});
});



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
		console.log(ret.items.length);
		console.log(ret.marker);
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


module.exports = AV.Cloud;
