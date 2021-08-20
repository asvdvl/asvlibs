local LL = {}   -- LL - LinkLayer
local net       --main table
local asv = require("asv")
local srl = require("serialization")
local utils = asv.utils
local magicWordForChoicePrimary = "primary" --perhaps the keyword needs to be changed or delete

local protocols = {
    asvNetEthernet = asv("net.LinkLayer.asvNetEthernet"),
    --arp = {}
}

local frameItem = {
    protocol = "",
    data = ""
}

--wrapper over drivers
--[[mini TODO: make getting proto name from table]]
function LL.broadcast(srcAddr, protocol, data)
    checkArg(1, srcAddr, "string", "nil")
    checkArg(2, protocol, "string")
    checkArg(3, data, "nil", "boolean", "number", "string", "table")
    local frame = utils.deepcopy(frameItem)
    frame.protocol = protocol
    frame.data = data

    local toSend = srl.serialize(frame)
    if srcAddr then
        if srcAddr == magicWordForChoicePrimary then
            net.phys.broadcast(nil, toSend)
        else
            net.phys.broadcast(srcAddr, toSend)
        end
    else
        net.phys.broadcastViaAll(toSend)
    end
end

function LL.send(srcAddr, dstAddr, protocol, data)
    checkArg(1, srcAddr, "string", "nil")
    checkArg(2, dstAddr, "string")
    checkArg(3, protocol, "string")
    checkArg(4, data, "nil", "boolean", "number", "string", "table")
    local frame = utils.deepcopy(frameItem)
    frame.protocol = protocol
    frame.data = data

    local toSend = srl.serialize(frame)
    if srcAddr == magicWordForChoicePrimary then
        srcAddr = nil
    end
    net.phys.send(srcAddr, dstAddr, toSend)
end

function LL.postInitialization(newnet)
    net = newnet
    for _, submodule in pairs(protocols) do
        submodule.postInitialization()
    end
    LL.postInitialization = nil
end

return LL