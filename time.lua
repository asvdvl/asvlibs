local time = {}
local fs = require("filesystem")
local filePath = "/tmp/.time"

local function getTimeZoneOffset(timeZone)
	timeZone = timeZone or 0
	return timeZone * 3600
end

local function getCurrent(timeZone)
	io.open(filePath, "w"):write(""):close()
	return tonumber(string.sub(fs.lastModified(filePath), 1, -6)) + getTimeZoneOffset(timeZone)
end

function time.getUNIX(timeZone)
	return getCurrent(timeZone)
end

function time.getBySpecificFormat(format, timeZone)
	return os.date(format, getCurrent(timeZone))
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
