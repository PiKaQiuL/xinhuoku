local co = include 'base.co'

local callbacks = {}
local session = 20000

local timers = {}
base.ui.proto.__shell = function(player, info)
    local session = info.session
    if timers[session] then 
        timers[session]:remove() 
    end
    if callbacks[session] then 
        callbacks[session](info.ret) 
    end
end

local function shell_impl(player, code, cb)
    session = session + 1
    callbacks[session] = cb
    timers[session] = base.wait(5000, function() 
        if callbacks[session] then
            callbacks[session]()
        end
    end)
    player:ui('__shell'){ code = code, session = session }
end

local function shell(player, code)
    return co.wrap(shell_impl)(player, code)
end

return shell