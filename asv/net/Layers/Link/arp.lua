local arp = {}  --arp - address resolution protocol
local net
local myname



function arp.postInitialization(newnet, mynewname)
    net = newnet
    myname = mynewname

    arp.postInitialization = nil
end

return arp