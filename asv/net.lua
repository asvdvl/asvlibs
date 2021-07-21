local cmp = require("component")
local event = require("event")
local utils = require("asv").utils
local srl = require("serialization")

local net = {}
net.l2 = {
    phys = {},
    protocols = {
        asvnetl2 = {},
        arp = {}
    },
    frameItem = {
        protocol = "",
        data = ""
    }
}
local port = 1 --constant

--Init modem
local function modemInit(modem)
    if not modem.open(port) then
        print("Failed to open port on modem "..addr)
    end
end

for addr in pairs(cmp.list("modem")) do
    local modem = cmp.proxy(addr)
    modemInit(modem)
end

--event handler for initializing modems after startup
local function eventComponentAddedProcessing(_, addr, componentType)
    if componentType == "modem" then
        local device = cmp.proxy(addr)
        modemInit(device)
    end
end

event.listen("component_added", eventComponentAddedProcessing)

--L2 modem wrapper
net.l2.phys = {
    getModemFromAddress = function (addr, dontTakeByDefault)    --dontTakeByDefault was left experimentally, may be removed in the future 
        local modem
        if addr then
            modem = cmp.proxy(cmp.get(addr))
        elseif not dontTakeByDefault then
            if cmp.isAvailable("modem") then
                modem = cmp.modem
            elseif cmp.isAvailable("tunnel") then
                modem = cmp.tunnel
            else
                error("net library needs a modem or tunnel component to work.")
            end
        else
            error("component not found")
        end
        --universalize api(component library dont save non primary components in RAM)
        if modem.asvnet then
            --component ready to use
            return modem 
        end
        --preparing for use
        modem.asvnet = {}
        if cmp.type(modem.address) == "modem" then
            modem.asvnet.send = function (dstAddr, ...)
                return modem.send(dstAddr, port, ...)
            end
            modem.asvnet.broadcast = function (...)
                return modem.broadcast(port, ...)
            end
        elseif cmp.type(modem.address) == "tunnel" then
            modem.asvnet.send = function (dstAddr, ...)    --dstAddr not using for send via linked card(need for universalize api)
                return modem.send(...)
            end
            modem.asvnet.broadcast = function (...)
                return modem.send(...)
            end
        end

        return modem
    end,

    broadcastViaAll = function (...)
        local errors = {n=0}
        for addr in pairs(cmp.list("modem")) do
            local success, reason = net.l2.phys.broadcast(addr, ...)
            if not success then
                errors[addr] = reason
                errors.n = errors.n + 1
            end
        end
        for addr in pairs(cmp.list("tunnel")) do
            local success, reason = net.l2.phys.broadcast(addr, ...)
            if not success then
                errors[addr] = reason
                errors.n = errors.n + 1
            end
        end
        if errors.n ~= 0 then
            return false, errors
        end
        return true
    end,

    broadcast = function (srcAddr, ...)
        checkArg(1, srcAddr, "string", "nil")
        return pcall(function (srcAddr, ...) net.l2.phys.getModemFromAddress(srcAddr).asvnet.broadcast(...) end, srcAddr, ...)
    end,

    send = function (srcAddr, dstAddr, ...)
        checkArg(1, srcAddr, "string", "nil")
        checkArg(2, dstAddr, "string")
        return pcall(function (srcAddr, dstAddr, ...) net.l2.phys.getModemFromAddress(srcAddr).asvnet.send(dstAddr, ...) end, srcAddr, dstAddr, ...)
    end
}

--L2 main functions
function net.l2.broadcastViaAll(protocol, data)
    checkArg(1, protocol, "string")
    checkArg(2, data, "string")
    local frame = utils.deepcopy(net.l2.frameItem)
    frame.protocol = protocol
    frame.data = data
    local success, reason = net.l2.phys.broadcastViaAll(srl.serialize(frame))
    assert(success, srl.serialize(reason, math.maxinteger))
end

function net.l2.broadcast(protocol, data, srcAddr)
    checkArg(1, protocol, "string")
    checkArg(2, data, "string")
    checkArg(3, srcAddr, "string", "nil")
    local frame = utils.deepcopy(net.l2.frameItem)
    frame.protocol = protocol
    frame.data = data
    local success, reason = net.l2.phys.broadcast(srcAddr, srl.serialize(frame))
    assert(success, reason)
end

function net.l2.send(protocol, data, srcAddr, dstAddr)
    checkArg(1, protocol, "string")
    checkArg(2, data, "string")
    checkArg(3, srcAddr, "string", "nil")
    checkArg(4, dstAddr, "string")
    local frame = utils.deepcopy(net.l2.frameItem)
    frame.protocol = protocol
    frame.data = data
    local success, reason = net.l2.phys.send(srcAddr, dstAddr, srl.serialize(frame))
    assert(success, reason)
end

return net