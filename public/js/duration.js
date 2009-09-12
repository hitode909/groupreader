function duration (str) {
	var ret = 0, map = {
		sec : 1, min : 60, hour : 3600, day : 86400, week : 604800, month : 2592000, year : 31536000
	};
	str.replace(/(\d+)\s*(msec|sec|min|hour|day|week|month|year)s?/g, function (_, num, unit) {
		ret += +num * map[unit];
	});
	return ret * 1000;
}
