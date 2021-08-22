local LL = {service = {}}   -- LL - LinkLayer
local net       --main table
local asv = require("asv")
local srl = require("serialization")
local event = require("event")
local utils = asv.utils
LL.service.magicWordForChoicePrimary = "primary" --perhaps the keyword needs to be changed or delete

LL.protocols = {
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
        if srcAddr == LL.service.magicWordForChoicePrimary then
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
    if srcAddr == LL.service.magicWordForChoicePrimary then
        srcAddr = nil
    end
    net.phys.send(srcAddr, dstAddr, toSend)
end

--receive part
local function receiveData(_, dstAddr, srcAddr, port, distance, data)
    if port ~= net.phys.service.port then       --just drop before processing
        return
    end

    if type(data) ~= "string" then              --invalid packet, unsupported data
        return
    end

    data = srl.unserialize(data)
    local badPacket
    data, badPacket = utils.correctTableStructure(data, frameItem)
    if badPacket then                           --invalid packet, some parameters is missing
        return
    end

    if LL.protocols[data.protocol].onMessageReceived then
        LL.protocols[data.protocol].onMessageReceived(dstAddr, srcAddr, data, port, distance)
    end
end

function LL.postInitialization(newnet)
    net = newnet
    for _, submodule in pairs(LL.protocols) do
        submodule.postInitialization()
    end
    event.listen("modem_message", receiveData)
    LL.postInitialization = nil
end

return LL