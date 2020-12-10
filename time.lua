local time = {}
local fs = require("filesystem")
local filePath = "/tmp/.time"

local function getTimeZoneOffset(timeZone)
	timeZone = timeZone or 0
	return timeZone * 3600
end

function time.getRaw()
	io.open(filePath, "w"):write(""):close()
	return fs.lastModified(filePath)
end

function time.getUNIX(timeZone)
	return tonumber(string.sub(time.getRaw(), 1, -6)) + getTimeZoneOffset(timeZone)
end

function time.getBySpecificFormat(format, timeZone)
	return os.date(format, time.getUNIX(timeZone))
end

function time.getTime(timeZone)
	return time.getBySpecificFormat("%H:%M:%S", timeZone)
end

function time.getDate(timeZone)
	return time.getBySpecificFormat("%Y.%m.%d", timeZone)
end

function time.getDateTime(timeZone)
	return time.getBySpecificFormat("%Y.%m.%d %H:%M:%S", timeZone)
end

return time
