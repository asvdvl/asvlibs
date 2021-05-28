-- This file was forked from here https://gist.github.com/Fingercomp/58388304f45bf6b2b8108e3b7a555315
-- To use this library, you must unlock the lua debugging interface.
-- The instructions are here https://computercraft.ru/blogs/entry/654-uluchshennyy-debugdebug/
local c;

local function insertNonNil(t, v)
    if v then
        v = tostring(v)
        if #v > 0 then
            table.insert(t, v)
        end
    end
end

local function backtrace(levelStart, shift)
    c = c or coroutine.running()

    for level = levelStart, math.huge do
        local info = debug.getinfo(c, level, "ufnSl")

        if not info then
            break
        end

        local funcType, name, args, exec, defined = {}, nil, {}, "", {}

        insertNonNil(funcType, info.what)
        insertNonNil(funcType, info.namewhat)
        table.insert(funcType, "function")

        name = info.name or "<anon>"

        if info.nparams then
            for an = 1, info.nparams do
                local argName, argValue = debug.getlocal(c, level, an)

                if argValue ~= nil then
                    argName = argName .. "=" .. tostring(argValue)
                end

                table.insert(args, argName)
            end
        end

        if info.isvararg then
            table.insert(args, "...")
        end

        if info.currentline and info.currentline ~= -1 then
            exec = ":" .. tostring(info.currentline)
        end

        insertNonNil(defined, info.short_src)

        if info.linedefined and info.linedefined ~= -1 then
            table.insert(defined, info.linedefined)
        end

        funcType = table.concat(funcType, " ")
        args = table.concat(args, ", ")
        defined = (defined[1] and (" in " .. defined[1] .. "") or "") ..
                      (defined[2] and (" at L" .. defined[2]) or "")

        -- local Lua function <anon>(a, b, c, ...):33 (defined in blah.lua at 33)

        local line = ("#%2d: %s %s%s%s%s"):format(level - levelStart + shift,
            funcType, name,
            #args > 0 and ("(" .. args .. ")") or "", exec,
            #defined > 0 and (" (defined" .. defined ..")") or "")

        print(line)
    end
end

local function getLevel(f)
    for i = 0, math.huge, 1 do
        local frame = debug.getinfo(i, "f")

        if not frame then
            break
        end

        if frame.func == f then
            return i
        end
    end
end

local function dbg(...)
    if select("#", ...) > 0 and not (...) then
        return
    end

    if os.getenv("DEBUG") == "off" then
        return
    end

    local level = 0

    local environment = setmetatable({}, {
        __index = function(_, var)
            local dbgLevel = getLevel(dbg)

            -- locals
            for i = 1, math.huge, 1 do
                local name, value = debug.getlocal(level + dbgLevel, i)

                if not name then
                    break
                end

                if name == var then
                    return value
                end
            end

            -- arguments
            for i = -1, -math.huge, -1 do
                local name, value = debug.getlocal(level + dbgLevel, i)

                if not name then
                    break
                end

                if name == var then
                    return value
                end
            end

            -- upvalues
            local frame = debug.getinfo(level + dbgLevel, "f")

            if not frame then
                return
            end

            local env

            for i = 1, math.huge do
                local name, value = debug.getupvalue(frame.func, i)

                if not name then
                    break
                end

                if name == var then
                    return value
                end

                if name == "_ENV" then
                    env = value
                end
            end

            if env then
                return env[var]
            end
        end,

        __newindex = function(_, var, value)
            local dbgLevel = getLevel(dbg)

            -- locals
            for i = 1, math.huge, 1 do
                local name = debug.getlocal(level + dbgLevel, i)

                if not name then
                    break
                end

                if name == var then
                    debug.setlocal(level + dbgLevel, i, value)
                    return
                end
            end

            -- arguments
            for i = -1, -math.huge, -1 do
                local name = debug.getlocal(level + dbgLevel, i)

                if not name then
                    break
                end

                if name == var then
                    debug.setlocal(level + dbgLevel, i, value)
                    return
                end
            end

            -- environment
            local frame = debug.getinfo(level + dbgLevel, "f")

            if not frame then
                return
            end

            local env

            for i = 1, math.huge, 1 do
                local name, upvalue = debug.getupvalue(frame.func, i)

                if not name then
                    break
                end

                if name == var then
                    debug.setupvalue(frame.func, i, value)
                    return
                end

                if name == "_ENV" then
                    env = upvalue
                end
            end

            if env then
                env[value] = value
            end
        end
    })

    while true do
        local frameInfo = debug.getinfo(getLevel(dbg) + level, "nSl")
        local name = frameInfo.name or ""
        io.write(("dbg(%d: %s:%d)> "):format(level, name, frameInfo.currentline))

        local input = io.read("*l")

        if not input then
            print()
            break
        end

        if input:sub(1, 1) == ":" then
            local params = {}

            for param in input:sub(2):gmatch("%S+") do
                table.insert(params, param)
            end

            if params[1] == "up" then
                if debug.getinfo(level + getLevel(dbg) + 1, "") then
                    level = level + 1
                else
                    print("Reached the top of the stack")
                end
            elseif params[1] == "down" then
                if debug.getinfo(level + getLevel(dbg) - 1, "") then
                    level = level - 1
                else
                    print("Reached the bottom of the stack")
                end
            elseif params[1] == "frame" and tonumber(params[2]) then
                if debug.getinfo(getLevel(dbg) + tonumber(params[2]), "") then
                    level = tonumber(params[2])
                else
                    print("No such frame")
                end
            elseif params[1] == "bt" then
                backtrace(level + getLevel(dbg) + 1, level)
            elseif params[1] == "print" then
                --print table
                local printTable = environment[params[2]]
                if type(printTable) == "table" then
                    print("key:value, "..#printTable.." rows detected")
                    local rowCounter = 0
                    for key, value in pairs(printTable) do
                        print(rowCounter .."\t".. tostring(key) .. "\t:\t" .. tostring(value))
                        rowCounter = rowCounter + 1
                    end
                    --#printTable may return a number of lines that is not true (e.g., try to output _G or _ENV).
                    print("Contain "..rowCounter.." rows")
                else
                    print("Usage: \":print table\"")
                end
            end
        else
            local ok, err = load("return " .. input, "=debug", "t", environment)

            if not ok then
                ok, err = load(input, "=debug", "t", environment)
            end

            local values

            if ok then
                values = table.pack(xpcall(ok, debug.traceback))
                ok = table.remove(values, 1)
                values.n = values.n - 1
                err = values[1]
            end

            if not ok then
                io.stderr:write(("%s\n"):format(err))
            else
                for i = 1, values.n, 1 do
                    if type(values[i]) == "string" then
                        values[i] = ("%q"):format(values[i]):gsub("\\\n", "\\n")
                    else
                        values[i] = ("%s"):format(values[i])
                    end
                end

                if values.n > 0 then
                    print(table.concat(values, "\t", 1, values.n))
                end
            end
        end
    end
end

return dbg