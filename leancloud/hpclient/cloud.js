var AV = require('leanengine');

var headers =  {
	'Cookie': 'cdb_auth=0a32%2FQ%2Fd8iZY8aW5qHtZVl6ebS%2Bpnj2FwidXgpu%2B4RSJ1EL1BEZGQRln8QWLsbeOCOkfFpdP%2FPclrjhzUz9CblTDX8mt;',
	'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.71 Safari/537.36',
};

var Forum = AV.Object.extend('Forum');
var Thread = AV.Object.extend('Thread');
var Image = AV.Object.extend('Image');

// v2 for decrease request count of api
AV.Cloud.define('helloV2', function(request, response) {
	response.success('Hello world!');

	// Plan A 拿到D版BS,E版的新帖hot贴 then 拿到所有的tids 做一次查询 然后取新的去拿图片, 不去重图片, (tid已去重, image再去重没必要)
	// 每秒一次请求 每天8w 每月30w
	// 记录一个上次update的值来减少请求不可取, 因为记录也要api请求一次, 也是每秒一次
	
	// Plan B 拿到tids 在拿到所有的 images 再去重, 这样就600个get html请求出去了擦 600*200ms 12s?

	// 先实现Plan A
	fire(); 

	//  可以考虑tids按天组织成数个array

	//1.5秒后再搞一次, leancloud允许每次超时15s, 但是定时刷新却可能不是每秒一次
	// 但是这样会不会重叠啊
	//setInterval(fire, 1500); 
});

function fire() {
	AV.Promise.all([
		getTidsForForum({fid:'2', orderby:'dateline', page:1}),
		getTidsForForum({fid:'2', orderby:'lastpost', page:1}),
		getTidsForForum({fid:'2', orderby:'lastpost', page:2}),
		getTidsForForum({fid:'2', orderby:'lastpost', page:3})/*,

		getTidsForForum({fid:'6', orderby:'dateline', page:1}),
		getTidsForForum({fid:'6', orderby:'lastpost', page:1}),
		getTidsForForum({fid:'6', orderby:'lastpost', page:2}),
		getTidsForForum({fid:'6', orderby:'lastpost', page:3}),

		getTidsForForum({fid:'59', orderby:'dateline', page:1}),
		getTidsForForum({fid:'59', orderby:'lastpost', page:1}),
		getTidsForForum({fid:'59', orderby:'lastpost', page:2}),
		getTidsForForum({fid:'59', orderby:'lastpost', page:3})*/
	]).then(function (values) {
		var tids = [].concat.apply([], values);

		var query = new AV.Query(Thread);
		query.containedIn('tid', tids);
		query.find({
			success: function(results) {
				var newTids = filterTids(tids, results);
				console.log('tids ' + tids.length + ', new ' + newTids.length + ', old ' + (tids.length - newTids.length));
				if (results.length !== (tids.length - newTids.length)) {
					console.log('error ' + results.length);
				}

				var threads = [];
				for (var i = 0; i < newTids.length; i++) {
					var tid = newTids[i];
					var thread = Thread.new({tid: tid});
					thread.save();
					threads.push(thread);
				}

				(function loop(i, threads) {     
					var thread = threads[i]; 

					(function(thread) {
						setTimeout(function () {   
							getImagesForThread(thread.get('tid')).then(function(images) {
								if (images.length) {
									console.log('get imageNames :');
									console.log(images);
									pingImages(images);
								} else {
									console.log('get imageName - empty, tid ' + thread.get('tid'));
								}
							}, function(error) {
								console.error('getImagesForThread error ' + error + ', tid ' + thread.get('tid'));
								thread.destroy({
									success: function(myObject) {
									},
									error: function(myObject, error) {
										console.log('delete error ' + myObject + error);
									}
								});
							});

							if (--i) loop(i, threads);
						}, 10);
					})(thread);
					
				})(threads.length-1, threads);
			},
			error: function(error) {
				console.log('query old tids Error: ' + error.code + ' ' + error.message);
			}
		});

	}, function(error){
		console.log('get tids error :');
		console.log(error);
	});
}

AV.Cloud.define('hello', function(request, response) {
	response.success('Hello world!');

	var fid = '2';

	var forum = null;
	var query = new AV.Query(Forum);
	query.equalTo('fid', fid);
	query.find({
		success: function(results) {
			if (results.length > 0) {
				forum = results[0];
			} else {
				forum = Forum.new({fid:fid, newCount:999, scanCount:0});
				forum.save();
			}

			// 每次估计能拿70个帖子
			// 上次有多少个新帖  forum.get('newCount')
			// 每秒刷新一次的话
			var lastNewCount = forum.get('newCount');
			console.log('lastNewCount: ' + lastNewCount);
			var now = +new Date();
			var interval = (now - forum.updatedAt)/1000;
			forum.add('log', {t: toJSONLocal(new Date()), lastNewCount: lastNewCount, interval: interval});
			// 70 new -> 直接刷 1s
			// 1 new -> 60s 之后
			// {0 ... 100个} <-> {1s ... 100s}
			var refreshInterval = Math.max(1, -lastNewCount + 100);
			if (interval < refreshInterval) {
				console.log('waiting next, interval ' + interval + ', refreshInterval ' + refreshInterval);
				return;
			}
			console.log('do refresh, interval ' + interval + ', refreshInterval ' + refreshInterval);


			getForumHTML(fid, function(httpResponse) {
				//console.log(httpResponse.text);
				console.log('get fid html ' + fid);
				var tids = findThreads(httpResponse.text);
				console.log(tids);

				// filter tid
				var query = new AV.Query(Thread);
				query.containedIn('tid', tids);
				query.find({
					success: function(results) {
						var newTids = [];
						console.log('Successfully retrieved ' + results.length + ' old tids.');

						for (var i = 0; i < tids.length; i++) {
							var tid = tids[i];

							var exist = false;
							for (var j = 0; j < results.length; j++) {
								var object = results[j];

								if (tid === object.get('tid')) {
									exist = true;
									break;
								}
							}

							if (exist) {
								console.log('old tid ' + object.get('tid') + ', scanCount ' + object.get('scanCount'));
								object.increment('scanCount');
								object.save();
							} else {
								console.log('new tid ' + tid);
								newTids.push(tid);
							}
						}

						forum.set('newCount', newTids.length);
						console.log('forum newCount ' + newTids.length);
						forum.save();

						for (var i = 0; i < newTids.length; i++) {
							var tid = newTids[i];
							var thread = Thread.new({tid: tid, fid: fid, scanCount:1});
							thread.save();

							(function(tid){
								getThreadHTML(tid, function(httpResponse) {
									var images = findImages(httpResponse.text);
									console.log('get imageNames :');
									console.log(images);

									pingImagesIfNeed(images, tid);

								}, function(httpResponse) {
									console.error('getThreadHTML error ' + httpResponse.status);
								});
							})(tid);
						}
					},
					error: function(error) {
						console.log('query old tids Error: ' + error.code + ' ' + error.message);
					}
				});

				
			}, function(httpResponse) {
				console.error('getForumHTML error ' + httpResponse.status);
			});

		},
		error: function(error) {
			console.log('query fid Error: ' + error.code + ' ' + error.message);
		}
	});
});

function getForumHTML(fid, success, error) {
	getForumHTMLParames({fid:fid, orderBy:'dateline'}, success, error);
}

// {fid:'2', orderby:'dateline|lastpost', page:1}
function getForumHTMLParames(params, success, error) {
	var p = serialize(params);
	var url = 'http://www.hi-pda.com/forum/forumdisplay.php?'+p;
	console.log('load url: ' + url);
	AV.Cloud.httpRequest({
		url: url,
		headers: headers,
		success: function(httpResponse) {
			success(httpResponse);
		},
		error: function(httpResponse) {
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
	AV.Cloud.httpRequest({
		url: 'http://www.hi-pda.com/forum/viewthread.php?tid='+tid,
		headers: headers,
		success: function(httpResponse) {
			success(httpResponse);
		},
		error: function(httpResponse) {
			error(httpResponse);
		}
	});
}

function filterTids(tids, results) {
	var newTids = [];
	for (var i = 0; i < tids.length; i++) {
		var tid = tids[i];

		var exist = false;
		for (var j = 0; j < results.length; j++) {
			var object = results[j];

			if (tid === object.get('tid')) {
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
		//name(半截), bucket(1)是hpimg, tid ,time自动有
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
				}
			});
		})(url);
	}
}

function pingImagesIfNeed(imageNames, tid) {

	if (imageNames.length == 0) {
		return;
	}

	var query = new AV.Query(Image);
	query.containedIn('name', imageNames);
	query.find({
		success: function(results) {
			var newImageNames = [];
			console.log('Successfully retrieved ' + results.length + ' images.');

			for (var i = 0; i < imageNames.length; i++) {
				var imageName = imageNames[i];

				var exist = false;
				for (var j = 0; j < results.length; j++) {
					var object = results[j];

					if (imageName === object.get('name')) {
						exist = true;
						break;
					}
				}
				if (exist) {
					console.log('old imageName ' + object.get('name') + ', scanCount ' + object.get('scanCount'));
					object.increment('scanCount');
					object.save();
				} else {
					console.log('new imageName ' + imageName);
					newImageNames.push(imageName);
				}
			}

			for (var i = 0; i < newImageNames.length; i++) {
				var imageName = newImageNames[i];
				//name(半截), bucket(1)是hpimg, tid ,time自动有
				var image = Image.new({name: imageName, bucket:1, tid:tid, scanCount:1});
				image.save();

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
						}
					});
				})(url);
			}
		},
		error: function(error) {
			console.log('query old image Error: ' + error.code + ' ' + error.message);
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

function toJSONLocal (date) {
    var local = new Date(date);
    local.setMinutes(date.getMinutes() - date.getTimezoneOffset());
    return local.toJSON().slice(5, 19);
}

function serialize(obj) {
  var str = [];
  for(var p in obj)
     str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
  return str.join("&");
}

module.exports = AV.Cloud;
