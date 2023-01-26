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
	mainDirUrl = "http://www.asv.l/",
	branch = "",
	mainFolder = "",	--if nil of false fallback into asv(folder with library)
	]]
	urlLibSubPaths = {"?.lua", "?/init.lua", "?/?.lua"},	--"?" - will be replaced with the required module
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
	io.stdout:write("if you want to disable this message, change the startupMessage variable in the settings table of the /lib/asv/init.lua file\n")
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
	local mainLibraryPath = fs.path(package.searchpath(var[1], package.path))		--some kludge for get main init.lua location(this file)
	local success, message
	--find and download file
	module = module:gsub("%.", "/")	  --replase all . on /

	for _, subPath in pairs(st.urlLibSubPaths) do
		subPath = subPath:gsub("?", module)
		local searchedModulePath = mainLibraryPath..subPath
		if not fs.exists(fs.path(searchedModulePath)) then
			fs.makeDirectory(fs.path(searchedModulePath))
		end

		local libUrlPath = st.mainDirUrl..st.branch.."/"..(st.mainFolder or var[1]).."/"..subPath

		dbgLog("try to download \""..searchedModulePath.."\" by address \""..libUrlPath.."\" ")
		success = wget("-f", libUrlPath, searchedModulePath)
		if not success then
			fs.remove(searchedModulePath)
		else
			return
		end
	end
	error("failed get \""..module.."\" module")
end

local function getLibrary(table, key)
	local path = package.searchpath(var[1].."."..key, package.path)
	dbgLog("try to load "..key)

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
