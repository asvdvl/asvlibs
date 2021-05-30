--TODO
--[]download libs
--[]update libs
--[]can store the file until the reboot
--[v]no load all
--vars
local var = {...}
local this = {_NOTE = "This table not empty! libraries are loading by accessing their name, via table.library"}
local internet = require("internet")

--settings
local st = {
    shortUrl = "https://raw.githubusercontent.com/asvdvl/asvlibs/master/asv/",
    listURL = "https://raw.githubusercontent.com/asvdvl/asvlibs/master/downloadList.txt",
    downloadIfNotExist = true,
    startupMessage = true
}

if st.startupMessage then
    io.stdout:write("asv libs init for automatic download and update libs\n")
    io.stdout:write("if you want to disable this message, change the startupMessage variable in the settings table of the asv/init.lua file\n")
end

local function downloadFile(package)
    local handle = internet.request(st.listURL)
    local result = ""
    for chunk in handle do
        result = result..chunk
    end

end

local function getLibrary(table, key)
    local path = package.searchpath(var[1].."."..key, package.path)
    if not path then
        downloadFile(var[1])
    end

    table[key] = require(var[1].."."..key)
    return table[key]
end

--set metatable
this = setmetatable({}, {__index = getLibrary, __call = getLibrary})

return this