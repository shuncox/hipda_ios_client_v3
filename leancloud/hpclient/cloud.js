var AV = require('leanengine');
var ImageHunter = require('./ImageHunter');
var SpaceCleaner = require('./SpaceCleaner');
var LOG = AV.Object.extend('ScheduleLog');
var Reporter = require('./Reporter');

var tasks = [
{
	name: 'D-new-topic',
	params: [{fid:'2', orderby:'dateline', page:1}],
},
{
	name: 'D-hot-topic',
	params: [
		{fid:'2', orderby:'lastpost', page:1},
		{fid:'2', orderby:'lastpost', page:2},
		{fid:'2', orderby:'lastpost', page:3},
	],
},
{
	name: 'BS-new-topic',
	params: [{fid:'6', orderby:'dateline', page:1}],
},
{
	name: 'BS-hot-topic',
	params: [
		{fid:'6', orderby:'lastpost', page:1},
		{fid:'6', orderby:'lastpost', page:2},
		{fid:'6', orderby:'lastpost', page:3},
	],
},
{
	name: 'EINK-new-topic',
	params: [{fid:'59', orderby:'dateline', page:1}],
},
{
	name: 'EINK-hot-topic',
	params: [
		{fid:'59', orderby:'lastpost', page:1},
		{fid:'59', orderby:'lastpost', page:2},
		{fid:'59', orderby:'lastpost', page:3},
	],
},
];

for (i in tasks) {
	var task = tasks[i];
	AV.Cloud.define(task.name, function(request, response) {
		response.success('Hello world!');
		var hunter = new ImageHunter(task.params, task.name);
		hunter.schedule();
	});
}

AV.Cloud.define('send-report', function(request, response) {
	response.success('Hello world!');
	
	// query log and send report
	var desp = '';
	var query = new AV.Query(LOG);
	query.find({
		success: function(logs) {
			for (var i = 0; i < logs.length; i++) {
				var log = logs[i].attributes;
				log.bucket = log.bucket.length;
				desp += JSON.stringify(log);
				desp += '\n';
			}
			console.log(desp);
			Reporter.report('Daily Report', desp);
		},
		error: function(error) {
			console.log('Error: ' + error.code + ' ' + error.message);
		}
	});
});

AV.Cloud.define('CutSpaceToLimit', function(request, response) {
	response.success('Hello world!');
	SpaceCleaner.clean();
});

module.exports = AV.Cloud;
