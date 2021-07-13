local cmp = require("component")
local event = require("event")

local this = {}
this.l2 = {
    phys = {
        frameItem = {
            protocol = "",
            data = ""
        },
    },
    protocols = {
        asvnetl2 = {},
        arp = {}
    }
}
local port = 1 --constant

--Init modem and tunnel, universalize apis
local function modemInit(modem)
    if not modem.open(port) then
        print("Failed to open port on modem "..addr)
    end
    modem.asvnet = {}
    modem.asvnet.send = function (dstAddr, ...)
        return modem.send(dstAddr, port, ...)
    end
    modem.asvnet.broadcast = function (...)
        return modem.broadcast(port, ...)
    end
end

local function tunnelInit(tunnel)
    tunnel.asvnet = {}
    tunnel.asvnet.send = function (dstAddr, ...)    --dstAddr not using for send via linked card(need for universalize api)
        return tunnel.send(...)
    end
    tunnel.asvnet.broadcast = function (...)
        return tunnel.send(...)
    end
end

for addr in pairs(cmp.list("modem")) do
    local modem = cmp.proxy(addr)
    modemInit(modem)
end

for addr in pairs(cmp.list("tunnel")) do
    local tunnel = cmp.proxy(addr)
    tunnelInit(tunnel)
end

--event handler for initializing modems after startup
local function eventComponentAddedProcessing(_, addr, componentType)
    local device = cmp.proxy(addr)
    if componentType == "modem" then
        modemInit(device)
    elseif componentType == "tunnel" then
        tunnelInit(device)
    end
end

event.listen("component_added", eventComponentAddedProcessing)

--L2
this.l2.phys = {
    getModemFromAddress = function (addr, doNotTakeByDefault)    --doNotTakeByDefault was left experimentally, may be removed in the future 
        if addr then
            return cmp.proxy(cmp.get(addr))
        end
        if not dontTakeByDefault then
            if cmp.isAvailable("modem") then
                return cmp.modem
            elseif cmp.isAvailable("tunnel") then
                return cmp.tunnel
            else
                error("this library needs a modem or tunnel component to work.")
            end
        else
            error("component not found")
        end
    end,

    broadcastViaAll = function (...)
        for addr in pairs(cmp.list("modem")) do
            this.l2.phys.broadcast(addr, ...)
        end
        for addr in pairs(cmp.list("tunnel")) do
            this.l2.phys.broadcast(addr, ...)
        end
    end,

    broadcast = function (srcAddr, ...)
        checkArg(1, srcAddr, "string", "nil")
        return this.l2.phys.getModemFromAddress(srcAddr).asvnet.broadcast(...)
    end,

    send = function (srcAddr, dstAddr, ...)
        checkArg(1, srcAddr, "string", "nil")
        checkArg(2, dstAddr, "string")
        return this.l2.phys.getModemFromAddress(srcAddr).asvnet.send(dstAddr, ...)
    end
}

return this