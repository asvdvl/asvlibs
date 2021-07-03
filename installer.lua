--wget instance
local wget = loadfile("/bin/wget.lua")
local URL = "https://raw.githubusercontent.com/asvdvl/asvlibs/master/asv/init.lua"

require("filesystem").makeDirectory("/lib/asv/")
local success, message = wget("-f", URL, "/lib/asv/init.lua")
if not success then
    io.stderr:write("Download error: "..URL.." by reason: "..message)
end

print("Setup complete!")