local event = require("event")
local asv = require("asv")
local net = {}
net.phys = asv("net.drivers")
net.l2 = asv("net.LinkLayer")

-- Post initialization
for _, submodule in pairs(net) do
    submodule.postInitialization(net)
end

return net