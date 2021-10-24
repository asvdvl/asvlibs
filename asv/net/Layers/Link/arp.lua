local arp = {service = {}}  --arp - address resolution protocol
local net
local myname
local asv = require("asv")
local utils = asv.utils
local time = asv.time
local event = require("event")
local requetTimeout, cache, listItem, requestTable, pendingAddreses, requestAddress
arp.service.requetTimeout = 5000 --timeout for canceling an attempt to obtain an address
arp.service.cache = {
    --contain sub-tables with a name that matches the protocol e.g. IPv4 = {...items...}
    --this subtables contain items with name that matches search address e.g. c0a80001 = {...listItem table...}. (c0a80001 here is 192.168.0.1 IPv4 address)
}

arp.service.listItem = {
    timeout = 0,    --time in UNIX format
    devAddr = "",   --matching network card. if empty - match with all adapters
    data = "",      --payload
    canBeUsedToAnswer = false   --allow reply with this address
}

arp.service.requestTable = {
    address = "",   --search address
    protocol = "",
}

arp.service.pendingAddreses = {}  --like cache

function arp.service.requestAddress(address, protocol, devAddr)
    local dataTable = utils.deepcopy(requestTable)
    dataTable.address = address
    dataTable.protocol = protocol

    net.Layers.Link.broadcast(devAddr, myname, dataTable)
    local startTime = time.getRaw()
    while startTime+arp.service.requetTimeout > time.getRaw() do
        event.pull(1)
        if cache[protocol][address] then
            return cache[protocol][address]
        end
    end
end

function arp.service.buildLinks() --create short links for simplify code
    local service = arp.service
    requetTimeout = service.requetTimeout
    cache = service.cache
    listItem = service.listItem
    requestTable = service.requestTable
    pendingAddreses = service.pendingAddreses
    requestAddress = service.requestAddress
end

function arp.get(address, protocol, devAddr)
    checkArg(1, address, "string", "number")
    checkArg(2, protocol, "string")
    checkArg(3, devAddr, "string", "nil")

    if not cache[protocol] then
        cache[protocol] = {}
    end

    if not cache[protocol][address] then
        return requestAddress(address, protocol, devAddr)
    end

    return cache[protocol][address]
end

function arp.add(address, protocol, devAddr, timeout, data, canBeUsedToAnswer)
    checkArg(1, address, "string", "number")
    checkArg(2, protocol, "string")
    checkArg(3, devAddr, "string", "nil")
    checkArg(4, timeout, "number", "nil")
    checkArg(6, canBeUsedToAnswer, "boolean", "nil")

    if not cache[protocol] then
        cache[protocol] = {}
        cache[protocol][address] = {}
    end

    local dataTable = utils.deepcopy(listItem)
    dataTable.timeout = timeout
    dataTable.devAddr = devAddr
    dataTable.data = data
    dataTable.canBeUsedToAnswer = canBeUsedToAnswer

    cache[protocol][address] = dataTable
end

function arp.remove(address, protocol)
    checkArg(1, address, "string", "number")
    checkArg(2, protocol, "string")

    if cache[protocol] then
        cache[protocol][address] = nil
        if not pairs(cache[protocol])(cache[protocol]) then     --delete subtable for protocol if empty
            cache[protocol] = nil
        end
    end
end

function arp.postInitialization(newnet, mynewname)
    net = newnet
    myname = mynewname

    arp.postInitialization = nil
end
arp.service.buildLinks()

return arp