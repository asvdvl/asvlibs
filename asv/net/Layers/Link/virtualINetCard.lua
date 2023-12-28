--[[
    Notification! this module is temporary until the normal L3 variant is ready.
    in the future, it is planned to implement a network with routing, 
    i.e. the ability to have several L3 routers on the way and not "works while in the access zone"
]]

local vic = {service = {}}
local event = require("event")
local net
local myname
local stats, arp, link

vic.service.stats = {
    onMessageReceivedCalls = 0,
    sendCalls = 0,
}
stats = vic.service.stats
vic.service.gatewayWord = "gateway"
vic.service.status = "client"

local dprint = print

function vic.onMessageReceived(dstAddr, frame, srcAddr)
    dprint("onMessageReceived", dstAddr, frame, srcAddr)
    stats.onMessageReceivedCalls = stats.onMessageReceivedCalls + 1
end

function vic.service.send()
    dprint("send")
    stats.sendCalls = stats.sendCalls + 1
end

local function onComponentAdded(_, _, component)
    dprint("onComponentAdded", component)
    if component == "internet" and vic.service.status == "client" then
        vic.service.status = "server"
        arp.add(vic.service.gatewayWord, myname, nil, math.maxinteger, net.phys.getModemFromAddress().address, true)
    end
end

local function onComponentRemove(_, _, component)
    dprint("onComponentRemove", component)
    if component == "internet" and not require("component").isAvailable("internet") then
        vic.service.status = "client"
        arp.remove(vic.service.gatewayWord, myname)
    end
end

function vic.postInitialization(newnet, mynewname)
    dprint("postInitialization", newnet, mynewname)
    net = newnet
    myname = mynewname
    link = net.Layers.Link
    arp = link.protocols["arp"]

    if require("component").isAvailable("internet") then
        onComponentAdded(nil, nil, "internet")
    end

    event.listen("component_added", onComponentAdded)
    event.listen("component_remove", onComponentRemove)
    vic.postInitialization = nil
end

return vic