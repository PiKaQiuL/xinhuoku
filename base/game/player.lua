local is_disconnect = {}
local is_abort = {}

base.game:event('玩家-断线', function (_, player)
    is_disconnect[player] = true
end)

base.game:event('玩家-重连', function (_, player)
    is_disconnect[player] = nil
end)

base.game:event('玩家-放弃重连', function (_, player)
    is_abort[player] = true
end)

function base.runtime.player:game_state()
    if self:controller() == 'none' then
        return 'none'
    end
    if is_disconnect[self] then
        return 'offline'
    else
        return 'online'
    end
end

function base.runtime.player:is_abort()
    return not not is_abort[self]
end
