local cmp = require("component")

local this = {}
this.l2 = {}
local port = 1 --constant


function this.l2.broadcastViaAll(...)
    for addr in pairs(cmp.list("modem")) do
        cmp.proxy(addr).broadcast(port, ...)
    end
end

function this.l2.broadcast(srcAddr, ...)
    checkArg(1, srcAddr, "string")
    cmp.proxy(cmp.get(srcAddr)).broadcast(port, ...)
end

function this.l2.send(srcAddr, dctAddr, ...)
    checkArg(1, srcAddr, "string")
    cmp.proxy(cmp.get(srcAddr)).send(dctAddr, port, ...)
end

return this