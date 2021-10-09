local LL = {service = {}}   -- LL - LinkLayer
local net       --main table
local asv = require("asv")
local srl = require("serialization")
local event = require("event")
local utils = asv.utils
LL.service.magicWordForChoicePrimary = "primary" --perhaps the keyword needs to be changed or delete
LL.service.stats = {
    broadcastedFrames = 0,
    sendedFrames = 0,
    receiveEventCalls = 0,
    droppedWithWrongPort = 0,
    droppedWithWrongDataType = 0,
    droppedWithInvalidData = 0,
    acceptedFrames = 0,
    transmittedBytes = 0,
}

LL.protocols = {
    asvNetEthernet = asv("net.Layers.Link.asvNetEthernet"),
    arp = asv("net.Layers.Link.arp")
}

local frameItem = {
    protocol = "",
    data = ""
}

function LL.service.framingData(protocol, data)
    local frame = utils.deepcopy(frameItem)
    frame.protocol = protocol
    frame.data = data
    return srl.serialize(frame)
end

--wrapper over drivers
function LL.broadcast(srcAddr, protocol, data)
    checkArg(1, srcAddr, "string", "nil")
    checkArg(2, protocol, "string")
    assert(LL.protocols[protocol], "No such protocol!")
    checkArg(3, data, "boolean", "number", "string", "table")

    local toSend = LL.service.framingData(protocol, data)
    LL.service.stats.broadcastedFrames = LL.service.stats.broadcastedFrames + 1
    LL.service.stats.transmittedBytes = LL.service.stats.transmittedBytes + #toSend
    if srcAddr then
        if srcAddr == LL.service.magicWordForChoicePrimary then
            return net.phys.broadcast(nil, toSend)
        else
            return net.phys.broadcast(srcAddr, toSend)
        end
    else
        return net.phys.broadcastViaAll(toSend)
    end
end

function LL.send(srcAddr, dstAddr, protocol, data)
    checkArg(1, srcAddr, "string", "nil")
    checkArg(2, dstAddr, "string")
    checkArg(3, protocol, "string")
    assert(LL.protocols[protocol], "No such protocol!")
    checkArg(4, data, "boolean", "number", "string", "table")

    local toSend = LL.service.framingData(protocol, data)
    if srcAddr == LL.service.magicWordForChoicePrimary then
        srcAddr = nil
    end
    LL.service.stats.sendedFrames = LL.service.stats.sendedFrames + 1
    LL.service.stats.transmittedBytes = LL.service.stats.transmittedBytes + #toSend
    return net.phys.send(srcAddr, dstAddr, toSend)
end

--receive part
local function receiveData(_, dstAddr, srcAddr, port, distance, data)
    LL.service.stats.receiveEventCalls = LL.service.stats.receiveEventCalls + 1
    if port ~= net.phys.service.port then       --just drop before processing
        LL.service.stats.droppedWithWrongPort = LL.service.stats.droppedWithWrongPort + 1
        return
    end

    if type(data) ~= "string" then              --invalid packet, unsupported data
        LL.service.stats.droppedWithWrongDataType = LL.service.stats.droppedWithWrongDataType + 1
        return
    end

    data = srl.unserialize(data)
    local badPacket
    data, badPacket = utils.correctTableStructure(data, frameItem)
    if badPacket then                           --invalid packet, some parameters is missing
        LL.service.stats.droppedWithInvalidData = LL.service.stats.droppedWithInvalidData + 1
        return
    end

    if LL.protocols[data.protocol].onMessageReceived then       --Сhecking the existence of the protocol and the protocol can receive data
        LL.service.stats.acceptedFrames = LL.service.stats.acceptedFrames + 1
        LL.protocols[data.protocol].onMessageReceived(dstAddr, data, srcAddr, port, distance)
    end
end

function LL.postInitialization(newnet)
    net = newnet
    for name, submodule in pairs(LL.protocols) do
        submodule.postInitialization(newnet, name)
    end
    event.listen("modem_message", receiveData)
    LL.postInitialization = nil
end

return LL