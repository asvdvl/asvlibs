local cmp = require("component")

local this = {}
this.l2 = {}
local port = 1 --constant

for addr in pairs(cmp.list("modem")) do
    cmp.proxy(addr).open(port)
end

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
    checkArg(1, srcAddr, "string", "nil")
    local modem
    if srcAddr then
        modem = cmp.proxy(cmp.get(srcAddr))
    else
        modem = cmp.modem
    end
    modem.send(dctAddr, port, ...)
end

return this