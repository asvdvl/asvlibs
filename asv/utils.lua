local utils = {}

utils.tables = {}
utils.strings = {}
utils.math = {}
utils.other = {}

---@param table table
---return reverse table
function utils.tables.reverseTable(table)
    checkArg(1, table, "table")
    local newTable = {}
    for k, v in ipairs(table) do
        newTable[#table + 1 - k] = v
    end
    return newTable
end

---@param bytes table
---return number
function utils.math.concatinateBytes(bytes)
    checkArg(1, bytes, "table")
    local concatNum = 0
    for _, val in pairs(bytes) do
        concatNum = val|(concatNum<<(8))
    end
    return concatNum
end

---@param strings table
---return string
function utils.strings.concatinateStrings(strings)
    checkArg(1, strings, "table")
    local concatStr = ""
    for _, val in pairs(strings) do
        concatStr = concatStr..val
    end
    return concatStr
end

---@param num number
---@param length number
---return table of bytes
function utils.math.splitIntoBytes(num, length)
    checkArg(1, num, "number")
    checkArg(2, length, "number")
    --Counting bytes
    local bytesCount = 0
    if not length then
        local numCount = num
        while numCount ~= 0 do
            numCount = numCount >> 8
            bytesCount = bytesCount + 1;
        end
    else
        bytesCount = length
    end

    --Splitting
    local bytes = {}
    for i = 1, bytesCount do
        bytes[i] = num & 0xFF
        num = num >> 8
    end

    return utils.reverseTable(bytes)
end

---@param text string
---@param chunkSize number
---return table of chunks
function utils.strings.splitByChunk(text, chunkSize)
    checkArg(1, text, "string")
    checkArg(2, chunkSize, "number")
    local chunks = {}
    for i = 1, math.ceil(text:len() / chunkSize) do
        chunks[i] = text:sub(1, chunkSize)
        text = text:sub(chunkSize + 1, #text)
    end
    return chunks
end

---@param verifiableTable table
---@param templateTable table
---return table new table and boolean
function utils.tables.correctTableStructure(verifiableTable, templateTable)
    checkArg(1, verifiableTable, "table")
    checkArg(2, templateTable, "table")
    verifiableTable = setmetatable(verifiableTable, {__index = templateTable})
    local virTabNew = {}
    local wasChanged = false
    for key, val in pairs(templateTable) do
        if not rawget(verifiableTable, key) then
            wasChanged = true
        end
        virTabNew[key] = verifiableTable[key]
    end
    return virTabNew, wasChanged
end

---@param msg string
---@param yes boolean
function utils.other.confirmAction(msg, yes)
    checkArg(1, msg, "string", "nil")
    checkArg(2, yes, "boolean")
    if not yes then
        if not msg then
            msg = "Do you confirm this action?"
        end
        msg = msg.."\n"

        io.stdout:write(msg)
        io.stderr:write("[y/N]?")
        if io.stdin:read():lower() ~= "y" then
            io.stdout:write("Canceling.\n")
            return false
        end
    end
    return true
end

---@param orig table
function utils.tables.deepcopy(orig)	--copied from http://lua-users.org/wiki/CopyTable
    local copy
    if type(orig) == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[utils.deepcopy(orig_key)] = utils.deepcopy(orig_value)
        end
        setmetatable(copy, utils.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

---@param table1 table
---@param table2 table
function utils.tables.concatTables(table1, table2)
    checkArg(1, table1, "table")
    checkArg(2, table2, "table")
    for key, value in pairs(table2) do
        table1[key] = value
    end
    return table1
end

---@param x number
---@param precision number
function utils.math.ceilWithPrecision(x, precision)
    checkArg(1, x, "number")
    checkArg(2, precision, "number")
    local pr = precision
    x = math.ceil((x*(10^precision)))/(10^precision)
    return x
end

--for legacy compatible
utils.reverseTable = utils.tables.reverseTable
utils.concatinateBytes = utils.math.concatinateBytes
utils.concatinateStrings = utils.strings.concatinateStrings
utils.splitIntoBytes = utils.math.splitIntoBytes
utils.splitByChunk = utils.strings.splitByChunk
utils.correctTableStructure = utils.tables.correctTableStructure
utils.confirmAction = utils.other.confirmAction
utils.deepcopy = utils.tables.deepcopy
utils.concatTables = utils.tables.concatTables

return utils
