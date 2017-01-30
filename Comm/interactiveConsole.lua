module("interactiveConsole", package.seeall)

setfenv(1, interactiveConsole);

require(GetScriptDirectory().."/Comm/dota2comm")

function makestring(o, f)
    if (not f) then f={} end
    
    if (type(o) == "number") then
        return ""..o
    end
    if (type(o) == "string") then
        return "\""..o.."\""
    end
    if (type(o) == "function") then
        return "Function";
    end
    if (type(o) == "boolean") then
        if (o) then
            return "true"
        else
            return "false"
        end
    end
    if (type(o) == "nil") then
        return "null";
    end
    if (type(o) == "userdata") then
        return "\"userdata\""
    end
    
    -- vv Table vv
    
    res = "{"
    f[o] = true
    for n in pairs(o) do
        res = res .. "\"" .. n .. "\""
    
        res = res .. ":"
    
        if (type(o[n]) == "table") then
            if (f[o[n]]) then
                res = res .. "\"recursion detected\""
            else
                res = res .. makestring(o[n], f)
            end
        else
            res = res .. makestring(o[n])
        end
    
        res = res .. ","
    end
    
    if (string.len(res) > 2) then
        res = string.sub(res, 0,string.len(res)-1)
    end
    
    return res .. "}"
end

function execute()
	local msg = comm.receive(); -- get a message
    
    if msg == nil then -- if there wasn't one
		return; -- don't do anything
	end
    
    local F = loadstring(msg) -- load function
    
    if (F == nil) then
        comm.send("Syntax Error")
        return
    end
    
    local status, result = pcall(F); -- execute it
    
    if (status) then -- call succeeded
        result = makestring(result); -- convert to string
    else
        result = "Error: " .. result; -- return the error
    end
    
    comm.send(result); -- send the result
end
