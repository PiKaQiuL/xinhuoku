ScreenPos = base.tsc.__TS__Class()
ScreenPos.name = 'ScreenPos'

local mt = ScreenPos.prototype
mt.type = 'screen_pos'

mt[1] = 0
mt[2] = 0

if base.test then
    function mt:__tostring()
        return ('{screen_pos|%08X|(%s, %s)}'):format(base.test.topointer(self), self[1], self[2])
    end
else
    function mt:__tostring()
        return ('{screen_pos|(%s, %s)}'):format(self[1], self[2])
    end
end

function mt:get_xy()
    return self[1], self[2]
end

function base.position(x, y)
    return setmetatable({x, y}, mt)
end

-- 用下面这个不容易误解
function base.screen_pos(x, y)
    return setmetatable({x, y}, mt)
end

return {
    ScreenPos = ScreenPos
}
