--vars
local var = {...}
local loading = {}
local cmp = require("component")
local this = {_NOTE = "This table not empty! libraries are loading by accessing their name, via table.library"}
--wget instance
local wget = loadfile("/bin/wget.lua")
local fs = require("filesystem")

--settings
local st = {
	mainDirUrl = "https://raw.githubusercontent.com/asvdvl/asvlibs/", --for git
	branch = "master",
	--[[tests
	mainDirUrl = "http://l.l/",
	branch = "",
	mainFolder = "",	--if nil of false fallback into asv(folder with library)
	]]
	filePrefix = ".lua",
	downloadIfNotExist = true,
	startupMessage = true,
	log = true,
	debug = {
		log = false,
		redownloadOnEachRequire = false --work when you try get module via call main(this) file
	}
}

if st.startupMessage then
	io.stdout:write("asv libs init for automatic download and update libs\n")
	io.stdout:write("if you want to disable this message, change the startupMessage variable in the settings table of the asv/init.lua file\n")
end

local function dbgLog(message)
	if st.debug.log then
		io.stdout:write("[dbg]"..message.."\n")
	end
end

local function log(message, error)
	if st.log then
		if error then
			io.stderr:write(message.."\n")
		else
			io.stdout:write(message.."\n")
		end
	end
end

if not cmp.isAvailable("internet") then
	log("Warning: The Internet card is not detected. Some functions may not work", true)
end

local function downloadFile(module)
	local success, message
	--find and download file
	module:gsub("%.", "/")	  --replase all . on /
	local path = fs.path(package.searchpath(var[1], package.path))		--some kludge for get current library path
	if not fs.exists(path) then
		fs.makeDirectory(path)
	end
	path = path..module..st.filePrefix
	local libUrlPath = st.mainDirUrl..st.branch.."/"..(st.mainFolder or var[1].."/")..module..st.filePrefix
	success, message = wget("-f", libUrlPath, path)
	if not success then
		fs.remove(path)
		error("Error while download file by URL: "..libUrlPath..". "..message)
	end
end

local function getLibrary(table, key)
	local path = package.searchpath(var[1].."."..key, package.path)

	if cmp.isAvailable("internet") then
		if st.debug.redownloadOnEachRequire or (not path and st.downloadIfNotExist) then
			dbgLog("package \""..key.."\" is not found. trying to get it from the repository.")
			downloadFile(key)
		end
	else
		log("Internet card not found, download skipped", true)
	end

	table[key] = require(var[1].."."..key)
	return rawget(table, key)
end

--set metatable
this = setmetatable(this, {__index = getLibrary, __call = getLibrary})

return this
