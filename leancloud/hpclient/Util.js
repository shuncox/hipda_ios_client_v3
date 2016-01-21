
//http://stackoverflow.com/questions/9229645/remove-duplicates-from-javascript-array
exports.uniq = function(a) {
    var seen = {};
    return a.filter(function(item) {
        return seen.hasOwnProperty(item) ? false : (seen[item] = true);
    });
}

exports.serialize = function(obj) {
  var str = [];
  for(var p in obj)
     str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]));
  return str.join("&");
}

exports.dayString = function(date) {
    var local = new Date(date);
    local.setMinutes(date.getMinutes() - date.getTimezoneOffset());
    //return local.toJSON().slice(0, 10);
    return local.toJSON().slice(0, 14); // for debug, hour report
}

exports.shortDateString = function(date) {
    var local = new Date(date);
    local.setMinutes(date.getMinutes() - date.getTimezoneOffset());
    return local.toJSON().slice(5, 19);
}

exports.getTodayDateKey =function() {
	var date = new Date();
	date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
	return date.toJSON().slice(0, 10);
}

exports.getMonthKey = function() {
	// 201601
	var date = new Date();
	date.setMinutes(date.getMinutes() - date.getTimezoneOffset());
	return date.toJSON().slice(0, 7).replace('-', '');
};