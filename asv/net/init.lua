local event = require("event")
local asv = require("asv")
local net = {}
net.phys = asv("net.drivers")
net.l2 = asv("net.LinkLayer")

return net