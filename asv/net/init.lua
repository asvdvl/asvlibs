local event = require("event")
local asv = require("asv")
local net = {}
net.Layers = {}

net.phys = asv("net.drivers")
net.Layers.LL = asv("net.Layers.LinkLayer")
net.Layers.INet = asv("net.Layers.Internet")

-- Post initialization
function net.Layers.postInitialization()    --kluge for init layers
    for _, submodule in pairs(net.Layers) do
        submodule.postInitialization(net)
    end
end

for _, submodule in pairs(net) do
    submodule.postInitialization(net)
end

return net