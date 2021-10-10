local arp = {service = {}}  --arp - address resolution protocol
local net
local myname
local asv = require("asv")
local utils = asv.utils
local cache = {
    --contain sub-tables with a name that matches the protocol e.g. IPv4 = {...items...}
    --this subtables contain items with name that matches search address e.g. c0a80001 = {...listItem table...}. (c0a80001 here is 192.168.0.1 IPv4 address)
}
local listItem = {
    timeout = 0,    --time in UNIX format
    devAddr = "",   --matching network card. if empty - match with all adapters
    data = "",      --payload
    canBeUsedToAnswer = false   --allow reply with this address
}
local requestTable = {
    address = "",   --search address
    protocol = "",
}

function arp.service.requestAddress(address, protocol, devAddr)
    local dataTable = utils.deepcopy(requestTable)
    dataTable.address = address
    dataTable.protocol = protocol

    net.Layers.Link.broadcast(devAddr, myname, dataTable)
end

function arp.get(address, protocol, devAddr)
    checkArg(1, address, "string", "number")
    checkArg(2, protocol, "string")
    checkArg(3, devAddr, "string", "nil")

    if not cache[protocol] then
        cache[protocol] = {}
    end

    arp.service.requestAddress(address, protocol, devAddr)
    return
end

function arp.add(address, protocol, devAddr)

end

function arp.remove(address, protocol, devAddr)

end

function arp.postInitialization(newnet, mynewname)
    net = newnet
    myname = mynewname

    arp.postInitialization = nil
end

return arp