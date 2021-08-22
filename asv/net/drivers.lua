local nd = {service = {}}   --"nd" is network drivers
local cmp = require("component")
local event = require("event")
nd.service.port = 1 --constant

--Init modem
local function modemInit(modem)
    if not modem.open(nd.service.port) then
        print("Failed to open port on modem "..modem.address)
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

--modem wrapper
--nd
function nd.getModemFromAddress(addr, dontTakeByDefault)    --dontTakeByDefault was left experimentally, may be removed in the future
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
            return modem.send(dstAddr, nd.service.port, ...)
        end
        modem.asvnet.broadcast = function (...)
            return modem.broadcast(nd.service.port, ...)
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
end

function nd.broadcastViaAll(...)
    local errors = {n=0}
    for addr in pairs(cmp.list("modem")) do
        local success, reason = nd.broadcast(addr, ...)
        if not success then
            errors[addr] = reason
            errors.n = errors.n + 1
        end
    end
    for addr in pairs(cmp.list("tunnel")) do
        local success, reason = nd.broadcast(addr, ...)
        if not success then
            errors[addr] = reason
            errors.n = errors.n + 1
        end
    end
    if errors.n ~= 0 then
        return false, errors
    end
    return true
end

function nd.broadcast(srcAddr, ...)
    checkArg(1, srcAddr, "string", "nil")
    return pcall(function (...) nd.getModemFromAddress(srcAddr).asvnet.broadcast(...) end, ...)
end

function nd.send(srcAddr, dstAddr, ...)
    checkArg(1, srcAddr, "string", "nil")
    checkArg(2, dstAddr, "string")
    return pcall(function (...) nd.getModemFromAddress(srcAddr).asvnet.send(dstAddr, ...) end, ...)
end

function nd.postInitialization(_)
    nd.postInitialization = nil
end

return nd