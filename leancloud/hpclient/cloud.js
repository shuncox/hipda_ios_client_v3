var AV = require('leanengine');

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

var TODAY_REPORT_DEFAULT = {
	day:'',
	errors: [], // {url: errMsg}
	newTidsCount: 0,
	newImagesCount: 0,
	newImagesSizeCount: 0,
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

function schedule(paramsArray, name) {
	setInterval(function(){
		console.log(name);
		var promises = [];
		for (var i = 0; i < paramsArray.length; i++) {
			promises.push(getTidsForForum(paramsArray[i]));
		}
		fire(promises);
		reportStatusIfNeeded();
	}, 1000); 
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

function reportStatusIfNeeded() {
	
	var day = dayString(new Date());
	if (TODAY_REPORT.day === '') {
		TODAY_REPORT.day = day;
	}

	if (TODAY_REPORT.day !== day) {
		var text = day;
		var desp = JSON.stringify(TODAY_REPORT);
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

		TODAY_REPORT = JSON.parse(JSON.stringify(TODAY_REPORT_DEFAULT));
	}
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

function serialize(obj) {
  var str = [];
  for(var p in obj)
     str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
  return str.join("&");
}

module.exports = AV.Cloud;
