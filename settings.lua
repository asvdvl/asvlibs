local settings = {}
local srl = require("serialization")
local fs = require("filesystem")
local defaultFileLocation = "/etc/settings/"
local defaultFileExtension = ".set"

local function checkPath(settingsFileName)
	--check on absolute path
	if string.sub(settingsFileName, 1, 1) ~= "/" then
		settingsFileName = fs.concat(defaultFileLocation, settingsFileName)
	end

	--check file extention
	if string.sub(settingsFileName, -#defaultFileExtension) ~= defaultFileExtension then
		settingsFileName = settingsFileName..defaultFileExtension
	end

	--check and create path to file (no create file)
	if not fs.exists(fs.path(settingsFileName)) then
		local status, reason = fs.makeDirectory(fs.path(settingsFileName))
		if not status then
			return status, reason
		end
	end

	return settingsFileName
end

local function verifyAndCorrectStructure(fileTab, defTab)
	fileTab = setmetatable(fileTab, {__index = defTab})
	local fileTabNew = {}
	local needRewrite
	for key, val in pairs(defTab) do 
		if not rawget(fileTab, key) then
			needRewrite = true
		end
		fileTabNew[key] = fileTab[key] 
	end
	return fileTabNew, needRewrite
end

function settings.getSettings(settingsFileName, defaultSettings, dontCorrectStructure)
	checkArg(1, settingsFileName, "string")
	local settingsFileName, reason = checkPath(settingsFileName)

	--check if checkPath return error
	if reason then
		return false, reason
	end

	--creck file and create if exist defaultSettings
	if not fs.exists(settingsFileName) and defaultSettings then
		local status, reason = settings.setSettings(settingsFileName, defaultSettings)
		if not status then
			return false, reason
		end
	end

	--open file
	local file, reason = io.open(settingsFileName)
	if type(file) ~= "table" then
		return false, reason
	end

	--read and unserialize file
	local serialized = file:read("*a")
	file:close()
	local var, reason = srl.unserialize(serialized)

	--correct structure with defaultSettings
	if not reason and type(defaultSettings) == "table" and not dontCorrectStructure then
		local needRewrite = false
		if type(var) == "table" then
			var, needRewrite = verifyAndCorrectStructure(var, defaultSettings)
		else
			local status, reason = settings.setSettings(settingsFileName, defaultSettings)
			if not status then
				return false, reason
			end
			var = defaultSettings
			needRewrite = true
		end

		if needRewrite then
			local status, reason = settings.setSettings(settingsFileName, var)
			if not status then
				return false, reason
			end
		end
	end

	if reason then
		return false, reason
	else
		return true, var
	end
end

function settings.setSettings(settingsFileName, newSettings)
	checkArg(2, newSettings, "nil", "boolean", "number", "string", "table")

	--check if checkPath return error
	local settingsFileName, reason = checkPath(settingsFileName)
	if reason then
		return false, reason
	end

	--open file
	local file, reason = io.open(settingsFileName, "w")
	if type(file) ~= "table" then
		return false, reason
	end

	--write to file
	file:write(srl.serialize(newSettings))  --DATA
	file:close()

	return true
end

return settings
