local LL = {}   -- LL - LinkLayer
local net       --main table
local asv = require("asv")
local srl = require("serialization")

local protocols = {
    asvNetEthernet = asv("net.LinkLayer.asvNetEthernet"),
    --arp = {}
}

local frameItem = {
    protocol = "",
    data = ""
}

function LL.postInitialization(newnet)
    net = newnet
    for _, submodule in pairs(protocols) do
        submodule.postInitialization()
    end
    LL.postInitialization = nil
end

return LL