--wget instance
local wget = loadfile("/bin/wget.lua")
local fs = require("filesystem")
local URL = "https://raw.githubusercontent.com/asvdvl/asvlibs/master/asv/init.lua"
--local URL = "http://l.l/init.lua"    --tests

require("shell").execute("rm -rf /lib/asv/")

fs.makeDirectory("/lib/asv/")
local success, message = wget("-f", URL, "/lib/asv/init.lua")
if not success then
    io.stderr:write("Download error: "..URL.." by reason: "..message)
end

print("Setup complete!")
os.sleep(2)

require("computer").shutdown(true)