do
    local addr, invoke = computer.getBootAddress(), component.invoke
    local function loadfile(file)
        local handle = assert(invoke(addr, "open", file))
        local buffer = ""
        repeat
            local data = invoke(addr, "read", handle, math.huge)
            buffer = buffer .. (data or "")
        until not data
        invoke(addr, "close", handle)
        return load(buffer, "=" .. file, "bt", _G)
    end
    loadfile("/lib/core.lua")(loadfile)
end

computer.shutdown()