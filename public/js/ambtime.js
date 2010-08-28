//#!js
//
//function log (o) { print(uneval(o)) }
//log(ambtime(new Date().getTime() + duration("1 min")));
//log(ambtime(new Date().getTime() + duration("2 mins")));
//log(ambtime(new Date().getTime() + duration("2 hours")));
//log(ambtime(new Date().getTime() + duration("1 day")));
//log(ambtime(new Date().getTime() + duration("2 days")));
//log(ambtime(new Date().getTime() + duration("1 month")));
//log(ambtime(new Date().getTime() + duration("3 months")));
//log(ambtime(new Date().getTime() + duration("4 months")));
//log(ambtime(new Date().getTime() + duration("6 months")));
//log(ambtime(new Date().getTime() + duration("7 months")));
//log(ambtime(new Date().getTime() + duration("10 months")));
//
//function duration (str) {
//	var ret = 0, map = {
//		sec : 1, min : 60, hour : 3600, day : 86400, week : 604800, month : 2592000, year : 31536000
//	};
//	str.replace(/(\d+)\s*(msec|sec|min|hour|day|week|month|year)s?/g, function (_, num, unit) {
//		ret += +num * map[unit];
//	});
//	return ret * 1000;
//}

function ambtime (date) {
	var delta  = date.valueOf() - new Date().getTime();
	var period = (function (delta) { with (Math) switch (true) {
		case (delta < duration("1 hour")):   return [floor(delta / duration("1 min")),   "min"];
		case (delta < duration("1 day")):    return [floor(delta / duration("1 hour")),  "hour"];
		case (delta < duration("1 month")):  return [floor(delta / duration("1 day")),   "day"];
		case (delta < duration("6 months")): return [floor(delta / duration("1 month")), "month"];
		default:                             return null;
	} })(delta < 0 ? -delta : delta);

	if (period) {
		var n = period[0], unit = period[1];
		var sign = delta < 0 ? "ago" : "later";
		if (n > 1) unit += "s";
		return [n, unit, sign].join(" ");
	} else {
		date = new Date(date.valueOf());
		return [
			date.getFullYear(), "-",
			(100 + date.getMonth() + 1).toString().slice(1), "-",
			(100 + date.getDate()).toString().slice(1),
			" ",
			(100 + date.getHours()).toString().slice(1), ":",
			(100 + date.getMinutes()).toString().slice(1), ":",
			(100 + date.getSeconds()).toString().slice(1)
		].join("");
	}
}

