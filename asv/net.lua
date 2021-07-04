local cmp = require("component")
local event = require("event")

local this = {}
this.l2 = {}
local port = 1 --constant

--Init
for addr in pairs(cmp.list("modem")) do
    cmp.proxy(addr).open(port)
end

local function eventComponentAddedProcessing(_, addr, componentType)
    if componentType == "modem" then
        cmp.proxy(addr).open(port)
    end
end

event.listen("component_added", eventComponentAddedProcessing)

--L2
local function getModemFromAddress(addr)
    if addr then
        return cmp.proxy(cmp.get(addr))
    end
    return cmp.modem
end

function this.l2.broadcastViaAll(...)
    for addr in pairs(cmp.list("modem")) do
        cmp.proxy(addr).broadcast(port, ...)
    end
end

function this.l2.broadcast(srcAddr, ...)
    checkArg(1, srcAddr, "string", "nil")
    getModemFromAddress(srcAddr).broadcast(port, ...)
end

function this.l2.send(srcAddr, dctAddr, ...)
    checkArg(1, srcAddr, "string", "nil")
    getModemFromAddress(srcAddr).send(dctAddr, port, ...)
end

return this