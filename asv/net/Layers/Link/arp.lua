local arp = {service = {}}  --arp - address resolution protocol
local net
local myname
local asv = require("asv")
local utils = asv.utils
local time = asv.time
local event = require("event")
local requetTimeout, cache, listItem, requestTable, requestAddress, stats, inPending
arp.service.stats = {
    getCalls = 0,
    addCalls = 0,
    removeCalls = 0,
    onMessageReceivedCalls = 0,
    droppedWithWrongDataTable = 0,
    receivedRequests = 0,
    sendResponses = 0,
    requestAddressCalls = 0,
    avgResponseTime = 0,
    acceptedResolutions = 0,
}
arp.service.requetTimeout = 2000 --timeout for canceling an attempt to obtain an address
arp.service.cacheItemDefaultTimeout = 30000 --timeout for remove field from cache
arp.service.cache = {
    --contain sub-tables with a name that matches the protocol e.g. IPv4 = {...items...}
    --this subtables contain items with name that matches search address e.g. c0a80001 = {...listItem table...}. (c0a80001 here is 192.168.0.1 IPv4 address)
}

arp.service.listItem = {
    timeout = 0,    --time in UNIX format, 0 - without timeout
    devAddr = "",   --matching network card. if empty - match with all adapters
    data = "",      --payload
    canBeUsedToAnswer = false   --allow reply with this address
}

arp.service.requestTable = {
    type = "request",       --"request" or "response"
    address = "",           --search address
    protocol = "",
    data = ""               --optional field
}
arp.service.requestWord = "request"
arp.service.responseWord = "response"

arp.service.inPending = {}

function arp.service.requestAddress(address, protocol, devAddr)
    stats.requestAddressCalls = stats.requestAddressCalls + 1
    local dataTable = utils.deepcopy(requestTable)
    dataTable.address = address
    dataTable.protocol = protocol

    local success, message = net.Layers.Link.broadcast(devAddr, myname, dataTable)
    assert(success, message)

    if not inPending[protocol] then
        inPending[protocol] = {}
    end
    inPending[protocol][address] = true     --filler(key used for quick search)

    local startTime = time.getRaw()
    while startTime+requetTimeout > time.getRaw() do
        event.pull(1)
        if cache[protocol][address] then
            stats.avgResponseTime = (stats.avgResponseTime + time.getRaw() - startTime) / stats.requestAddressCalls

            inPending[protocol][address] = nil
            if not pairs(inPending[protocol])(inPending[protocol]) then     --purge protocol table if empty
                inPending[protocol] = nil
            end
            return true, cache[protocol][address]
        end
    end
    return false
end

function arp.service.buildLinks() --create short links for simplify code
    local service = arp.service
    requetTimeout = service.requetTimeout
    cache = service.cache
    listItem = service.listItem
    requestTable = service.requestTable
    requestAddress = service.requestAddress
    stats = service.stats
    inPending = service.inPending
end

function arp.get(address, protocol, devAddr, forResponsible)
    stats.getCalls = stats.getCalls + 1
    checkArg(1, address, "string", "number")
    checkArg(2, protocol, "string")
    checkArg(3, devAddr, "string", "nil")
    checkArg(4, forResponsible, "boolean", "nil")

    if not cache[protocol] then
        cache[protocol] = {}
    end

    if not cache[protocol][address] and not forResponsible then
        return requestAddress(address, protocol, devAddr)
    elseif cache[protocol][address] then
        if cache[protocol][address].timeout < time.getRaw() and cache[protocol][address].timeout ~= 0 then
            arp.remove(address, protocol, true)
            return requestAddress(address, protocol, devAddr)
        end

        if not cache[protocol][address].canBeUsedToAnswer and forResponsible then
            return false
        end

        return true, cache[protocol][address]
    else
        return false
    end
end

function arp.add(address, protocol, devAddr, timeout, data, canBeUsedToAnswer)
    stats.addCalls = stats.addCalls + 1
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
    dataTable.timeout = timeout or time.getRaw() + arp.service.cacheItemDefaultTimeout
    dataTable.devAddr = devAddr
    dataTable.data = data
    dataTable.canBeUsedToAnswer = canBeUsedToAnswer

    cache[protocol][address] = dataTable
end

function arp.remove(address, protocol, keepProtocolTable)
    stats.removeCalls = stats.removeCalls + 1
    checkArg(1, address, "string", "number")
    checkArg(2, protocol, "string")
    checkArg(3, keepProtocolTable, "boolean", "nil")

    if cache[protocol] then
        cache[protocol][address] = nil
        if not keepProtocolTable and not pairs(cache[protocol])(cache[protocol]) then     --delete subtable for protocol if empty
            cache[protocol] = nil
        end
    end
end

function arp.onMessageReceived(dstAddr, frame, srcAddr)
    stats.onMessageReceivedCalls = stats.onMessageReceivedCalls + 1

    local fieldDataIsNil                        --kludge for support empty field
    if type(frame.data.data) == "nil" then
        fieldDataIsNil = true
        frame.data.data = ""
    end

    local data, bagRequest = utils.correctTableStructure(frame.data, requestTable)

    if fieldDataIsNil then
        data.data = nil
    end

    if bagRequest then
        stats.droppedWithWrongDataTable = stats.droppedWithWrongDataTable + 1
        return
    end

    if data.type == arp.service.requestWord then
        stats.receivedRequests = stats.receivedRequests + 1
        local success, item = arp.get(data.address, data.protocol, nil, true)
        if success then
            local sendData = utils.deepcopy(requestTable)
            sendData.type = "response"
            sendData.address = data.address
            sendData.protocol = data.protocol
            sendData.data = item.data
            net.Layers.Link.send(dstAddr, srcAddr, myname, sendData)
        end
    elseif data.type == arp.service.responseWord then
        if inPending[data.protocol] then
            if inPending[data.protocol][data.address] then
                stats.acceptedResolutions = stats.acceptedResolutions + 1
                arp.add(data.address, data.protocol, dstAddr, nil, data.data)
            end
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