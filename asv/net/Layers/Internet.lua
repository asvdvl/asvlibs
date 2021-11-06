local INet = {service = {}}   -- INet - Internet layer(TCP/IP)
local net       --main table
local asv = require("asv")
local srl = require("serialization")
local utils = asv.utils
INet.service.stats = {

}

INet.protocols = {
    IPv4 = asv("net.Layers.Internet.IPv4")
}

local packetItem = {
    protocol = "",
    header = {},
    data = ""
}

function INet.service.makePacket(protocol, header, data)
    local packet = utils.deepcopy(packetItem)
    packet.protocol = protocol
    packet.header = header
    packet.data = data
    return srl.serialize(packet)
end

--wrapper over link
function INet.broadcast()

end

function INet.send()

end

function INet.onEhternetReceive(dstAddr, data, srcAddr)

end

function INet.postInitialization(newnet)
    --net = newnet
    INet.postInitialization = nil
end

return INet