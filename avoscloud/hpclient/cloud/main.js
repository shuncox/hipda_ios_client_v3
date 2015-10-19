// Use AV.Cloud.define to define as many cloud functions as you want.
// For example:
AV.Cloud.define("hello", function(request, response) {
	response.success("Hello world!");
});

AV.Cloud.define("getBlockList", function(request, response) {

	// request
	var user = request["user"];
	var parameters = request["params"];
	var lastModifiedTime = parameters["lastModifiedTime"];
    
    if (!user) {
    	response.error("!user");
    	return;
    }

	var blockListId = user.get("BlockListObjectId");
    var query = new AV.Query(AV.Object.extend("BlockList"));
	query.get(blockListId, {
  		success: function(blockList) {

			var changeLogs = blockList.get("changeLogs");
			var t = blockList.get("lastModifiedTime");
			if (t && t === lastModifiedTime) {
				response.success({
					"isChange": 0
				});
				return;
			}

			// calc new list
			var list = [];
			var hash = {};
			for (var i=changeLogs.length-1; i >= 0; i--) {
				var log = changeLogs[i];

				var key = log["username"];
				if (!(key in hash)) {
					hash[key] = 1;
					if (log["type"] == "add") {
						list.push(log);
					}
				}
			}

			t = new Date().getTime();
			//save list & time
			blockList.set('list', list);
			blockList.set('lastModifiedTime', t);
      		blockList.save();

			response.success({
				"isChange": 1,
				"list":list,
				"lastModifiedTime": t
			});
  		},
  		error: function(object, error) {
    		response.error(error);
  		}
	});
});