local cmp = require("component")

local this = {}
this.l2 = {}
local port = 1 --constant


function this.l2.broadcast(...)
    for addr in pairs(cmp.list("modem")) do
        cmp.proxy(addr).broadcast(port, ...)
    end
end

return this