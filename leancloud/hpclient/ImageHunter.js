// constants
var AV = require('leanengine');
var Util = require('./Util');
var LOG = AV.Object.extend('ScheduleLog');
var headers =  {
	'Cookie': 'cdb_auth=0a32%2FQ%2Fd8iZY8aW5qHtZVl6ebS%2Bpnj2FwidXgpu%2B4RSJ1EL1BEZGQRln8QWLsbeOCOkfFpdP%2FPclrjhzUz9CblTDX8mt;',
	'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.71 Safari/537.36',
};
var PAGE_LIMIT = 200;  // 每页的限额


var method = ImageHunter.prototype;
function ImageHunter(paramsArray, name) {
	this._paramsArray = paramsArray;
    this._name = name;
    this._bucket = [];
    this._report = {
    	day:'',
		newTidsCount: 0,
		newImagesCount: 0,
		newImagesSizeCount: 0,
		getTidsErrorCount: 0,
		errors: [],
    };
    this._limit = PAGE_LIMIT * paramsArray.length;
}

method.schedule = function() {

	var that = this;

	var query = new AV.Query(LOG);
	query.equalTo('name', that._name);
	query.first()
	.then(function(object) {
		if (!object) {
			object = LOG.new({name:that._name, bucket: that._bucket, report: that._report});
			object.save();
			console.log('create a new LOG');
			console.log(object);
		}
		return object;
	})
	.then(function(log){

		that._bucket = log.get('bucket');
		that._report = log.get('report');

		var SEC = 1000;
		var limit = 10 * 60 * SEC;
		var timer = setInterval(function(){
			console.log(that._name + ', limit: ' + limit/SEC);
			var promises = [];
			for (var i = 0; i < that._paramsArray.length; i++) {
				promises.push(that.getTidsForForum(that._paramsArray[i]));
			}
			that.fire(promises);

			limit -= SEC;
			if (limit % (60 * SEC) == 0) {
				log.save({bucket: that._bucket, report: that._report});
				console.log('save log');
			}
			if (limit <= 0) {
				console.log('cencel');
				clearInterval(timer);
			}
		}, SEC); 
	});
}

method.fire = function(promises) {
	var that = this;
	AV.Promise.all(promises).then(function (values) {
		var tids = [].concat.apply([], values);
		tids = Util.uniq(tids);

		var newTids = that.filterTids(tids, that._bucket);

		that._report.newTidsCount += newTids.length;

		console.log(that._name + ', bucket ' + that._bucket.length + ', current ' + tids.length + ', new ' + newTids.length);
		if (tids.length == 0) {
			console.log('get tids 0');
			that._report.getTidsErrorCount += 1;
		} 
		if (newTids.length <= 0) {
			return;
		}

		that._bucket = that._bucket.concat(newTids);
		while (that._bucket.length > that._limit) {
			that._bucket.shift();
		}

		(function loop(i, newTids) {     
			var tid = newTids[i]; 

			(function(tid) {
				setTimeout(function () {   
					that.getImagesForThread(tid).then(function(images) {
						if (images.length) {
							console.log('get imageNames :');
							console.log(images);

							that._report.newImagesCount += images.length;

							that.pingImages(images);
						} else {
							console.log('get imageName - empty, tid ' + tid);
						}
					}, function(error) {
						console.error('getImagesForThread error ' + error + ', tid ' + tid);

						// remove tid for that._bucket
						var index = that._bucket.indexOf(tid);
						if (index > -1) {
							that._bucket.splice(index, 1);
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
method.getForumHTMLParames = function(params, success, error) {
	var p = Util.serialize(params);
	var url = 'http://www.hi-pda.com/forum/forumdisplay.php?'+p;
	var that = this;
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
			that._report.errors.push({url: url, errMsg: httpResponse});

			error(httpResponse);
		}
	});
}

/// global functions

method.findThreads = function(html) {
	
	var input = html;
	var regex = /normalthread_(\d+)/g;

	var matches, output = [];
	while (matches = regex.exec(input)) {
		output.push(matches[1]);
	}

	var tids = output;
	return tids;
}

method.getTidsForForum = function(params) {
	var that = this;
	var promise = new AV.Promise(function(resolve, reject){
		that.getForumHTMLParames(params, function(httpResponse) {
			var tids = that.findThreads(httpResponse.text);
			resolve(tids);
		}, function(httpResponse) {
			reject(httpResponse.status);
		});
	});
	return promise;
}

method.getThreadHTML = function(tid, success, error) {
	var url = 'http://www.hi-pda.com/forum/viewthread.php?tid='+tid;
	var that = this;
	AV.Cloud.httpRequest({
		url: url,
		headers: headers,
		success: function(httpResponse) {
			success(httpResponse);
		},
		error: function(httpResponse) {
			that._report.errors.push({url: url, errMsg: httpResponse});
			error(httpResponse);
		}
	});
}

method.filterTids = function(tids, oldTids) {
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

method.findImages = function(html) {
	
	var input = html;
	var regex = /"attachments\/(.*?)"/g;

	var matches, output = [];
	while (matches = regex.exec(input)) {
		output.push(matches[1]);
	}

	var images = Util.uniq(output);
	return images;
}

method.getImagesForThread = function(tid) {
	var that = this;
	var promise = new AV.Promise(function(resolve, reject){
		//resolve([]);return;

		that.getThreadHTML(tid, function(httpResponse) {
			var images = that.findImages(httpResponse.text);
			resolve(images);
		}, function(httpResponse) {
			reject(httpResponse.status);
		});
	});
	return promise;
}

method.pingImages = function(imageNames) {
	var that = this;

	for (var i = 0; i < imageNames.length; i++) {
		var imageName = imageNames[i];

		var url = 'http://7xq2vp.com1.z0.glb.clouddn.com/forum/attachments/'+ imageName + '-test';
		console.log('ping image ' + url);
//return;
		(function(url) {
			AV.Cloud.httpRequest({
				url: url,
				success: function(httpResponse) {
					console.log('ping image success ' + url);
				},
				error: function(httpResponse) {
					console.log('ping image error ' + url);
					that._report.errors.push({url: url, errMsg: httpResponse});
				}
			});
		})(url);
	}
}

module.exports = ImageHunter;