local settings = {}
local srl = require("serialization")
local fs = require("filesystem")
local defaultFileLocation = "/etc/settings/"

function checkPath(pathToFile)
	checkArg(1, pathToFile, "string")
	
	if string.sub(pathToFile, 1, 1) ~= "/" then
		pathToFile = fs.concat(defaultFileLocation, pathToFile)
	end
	
	if not fs.exists(fs.path(pathToFile)) then
		local status, reason = fs.makeDirectory(fs.path(pathToFile))
		if not status then
			return status, reason
		end
	end
	
	return pathToFile
end

function settings.getSettings(pathToFile, defaultSettings)
	pathToFile, reason = checkPath(pathToFile)

	if reason ~=nil then
		return false, reason
	end
	
	if not fs.exists(pathToFile) then
		local status, reason = settings.setSettings(pathToFile, defaultSettings)
		if not status then
			return false, reason
		end
	end
	
	local file, reason = io.open(pathToFile)
	if type(file) ~= "table" then
		return false, reason
	end
	
	local serialized = file:read("*a")
	file:close()
	local var, reason = srl.unserialize(serialized)
	
	if reason ~=nil then
		return false, reason
	else
		return true, var
	end
end

function settings.setSettings(pathToFile, newSettings)
	checkArg(2, newSettings, "nil", "boolean", "number", "string", "table")
	pathToFile, reason = checkPath(pathToFile)
	if reason ~=nil then
		return false, reason
	end
	local file, reason = io.open(pathToFile, "w")
	if type(file) ~= "table" then
		return false, reason
	end
	file:write(srl.serialize(newSettings))  --DATA
	file:close()
	
	return true
end

return settings
