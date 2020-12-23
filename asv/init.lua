--vars
local var = {...}
local this = {}

--set metatable
local function mtIndex(table, key)
    table[key] = require(var[1].."."..key)
    return table[key]
end
this = setmetatable({}, {__index = mtIndex})

return this