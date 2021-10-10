local ANE = {}  --ANE - asvNetEthernet
local net
local myname

function ANE.broadcast(srcAddr, data)
    return net.Layers.Link.broadcast(srcAddr, myname, data)
end

function ANE.send(srcAddr, dstAddr, data)
    return net.Layers.Link.send(srcAddr, dstAddr, myname, data)
end

function ANE.onMessageReceived(dstAddr, data, srcAddr, port, distance)
    net.Layers.Internet.onEhternetReceive(dstAddr, data, srcAddr)
end

function ANE.postInitialization(newnet, mynewname)
    net = newnet
    myname = mynewname

    ANE.postInitialization = nil
end

return ANE