local LL = {}   -- LL - LinkLayer
local utils = require("asv").utils
local srl = require("serialization")

local rotocols = {
    asvnetl2 = {},
    arp = {}
}

local frameItem = {
    protocol = "",
    data = ""
}

return LL