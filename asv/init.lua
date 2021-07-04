--TODO
--[]update libs
--[v]redownload on each require
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
    mainDirUrl = "https://raw.githubusercontent.com/asvdvl/asvlibs/master/asv/", --for git
    listURL = "https://raw.githubusercontent.com/asvdvl/asvlibs/master/downloadList.txt", --for git
    --mainDirUrl = "http://l.l/",   --tests
    --listURL = "http://l.l/downloadList.txt",   --tests
    listTempLocation = "/tmp/downloadList.txt",
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

local function log(message)
    if st.log then
        io.stdout:write(message.."\n")
    end
end

if not cmp.isAvailable("internet") then
    log("Warning: The Internet card is not detected. Some functions may not work")
end

local function downloadFile(module)
    local success, message

    --download repository list
    dbgLog("try to get repository list")
    success, message = wget("-fq", st.listURL, st.listTempLocation)
    assert(success, message)

    --try to find the necessary package in the repository
    dbgLog("try to parse data")
    local _, _, libname, updateTime = string.find(io.open(st.listTempLocation):read("*a"), module..";([A-Za-z0-9.]+);(%d+)")
    assert(libname, "package not found in the repository index file")

    --download file
    local path = fs.path(package.searchpath(var[1], package.path))       --some kludge for get current library path
    success, message = wget("-f", st.mainDirUrl..libname, path..module..".lua")
    if not success then
        fs.remove(path..module..".lua")
        error("Error while download file by URL: "..st.mainDirUrl..libname..". "..message)
    end

    dbgLog("Last update: "..updateTime)
end

local function getLibrary(table, key)
    local path = package.searchpath(var[1].."."..key, package.path)

    if cmp.isAvailable("internet") then
        if st.debug.redownloadOnEachRequire or (not path and st.downloadIfNotExist) then
            dbgLog("package \""..key.."\" is not found. trying to get it from the repository.")
            downloadFile(key)
        end
    else
        log("Internet card not found, download skipped")
    end

    package.loaded[var[1]][key] = nil   --reset loaded module
    table[key] = require(var[1].."."..key)
    return rawget(table, key)
end

--set metatable
this = setmetatable(this, {__index = getLibrary, __call = getLibrary})

return this