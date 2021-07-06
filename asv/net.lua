local cmp = require("component")
local event = require("event")

local this = {}
this.l2 = {
    frameItem = {
        protocol = "",
        data = ""
    },
    phys = {},
    protocols = {
        asvnetl2 = {},
        arp = {}
    }
}
local port = 1 --constant

--Init
for addr in pairs(cmp.list("modem")) do
    cmp.proxy(addr).open(port)
end

local function eventComponentAddedProcessing(_, addr, componentType)
    if componentType == "modem" then
        if not cmp.proxy(addr).open(port) then
            print("Failed to open port on modem "..addr)
        end
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

function this.l2.phys.broadcastViaAll(...)
    for addr in pairs(cmp.list("modem")) do
        cmp.proxy(addr).broadcast(port, ...)
    end
end

function this.l2.phys.broadcast(srcAddr, ...)
    checkArg(1, srcAddr, "string", "nil")
    return getModemFromAddress(srcAddr).broadcast(port, ...)
end

function this.l2.phys.send(srcAddr, dstAddr, ...)
    checkArg(1, srcAddr, "string", "nil")
    checkArg(2, dstAddr, "string")
    return getModemFromAddress(srcAddr).send(dctAddr, port, ...)
end

return this