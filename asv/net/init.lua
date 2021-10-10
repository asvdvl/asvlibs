local event = require("event")
local asv = require("asv")
local net = {}
net.Layers = {}

net.phys = asv("net.drivers")
net.Layers.Link = asv("net.Layers.Link")
net.Layers.Internet = asv("net.Layers.Internet")

-- Post initialization
function net.Layers.postInitialization()    --kluge for init layers
    net.Layers.postInitialization = nil     --exclude from reinitialization(causes errors)
    for _, submodule in pairs(net.Layers) do
        submodule.postInitialization(net)
    end
end

for _, submodule in pairs(net) do
    submodule.postInitialization(net)
end

return net