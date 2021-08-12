local ANE = {}  --ANE - asvNetEthernet
local net



function ANE.postInitialization(newnet)
    net = newnet
    ANE.postInitialization = nil
end

return ANE