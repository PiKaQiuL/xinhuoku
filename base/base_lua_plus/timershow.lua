local idx = 0
local timershow_map = {} --[[- key: name  value: timer]]
function base.create_timershow(x, y, time)
    ---@ui 在坐标X~1~,坐标Y~2~创建一个~3~秒的计时器控件
    ---@belong timer
    ---@description 在指定位置创建计时器控件
    ---@applicable both
    ---@name1 位置
    ---@arg1 0
    ---@arg2 0
    idx = idx + 1
    local name = tostring(idx)
    if timershow_map[name] ~= nil then
        return
    end
    local msg = {
        x = x,
        y = y,
        name = name,
        time = time
    }
    base.game:ui'create_timershow'(msg)
    timershow_map[name] = base.wait(math.floor(time * 1000), function()
        base.game:ui'remove_timershow'(msg)
        timershow_map[name] = nil
    end)
    return name
end
 ---@keyword 创建 计时器控件
function base.remove_timershow(name)
    ---@ui 移除~1~计时器控件
    ---@belong timer
    ---@description 移除指定计时器控件
    ---@applicable both
    if timershow_map[name] == nil then
        return
    end
    local msg = {
        name = name
    }
    timershow_map[name]:remove()
    base.game:ui'remove_timershow'(msg)
    timershow_map[name] = nil
end
 ---@keyword 移除 计时器控件
function base.pause_timershow(name)
    ---@ui 暂停~1~计时器控件
    ---@belong timer
    ---@description 暂停指定计时器控件
    ---@applicable both
    if timershow_map[name] == nil then
        return
    end
    local msg = {
        name = name,
        time = base.remaining(timershow_map[name])
    }
    timershow_map[name]:pause()
    base.game:ui'pause_timershow'(msg)
    return name
end
 ---@keyword 暂停 计时器控件
function base.resume_timershow(name)
    ---@ui 恢复~1~计时器控件
    ---@belong timer
    ---@description 恢复指定计时器控件
    ---@applicable both
    if timershow_map[name] == nil then
        return
    end
    local msg = {
        name = name,
        time = base.remaining(timershow_map[name])
    }
    timershow_map[name]:resume()
    base.game:ui'resume_timershow'(msg)
    return name
end
 ---@keyword 恢复 计时器控件
function base.add_player_timershow_visible(name, player)
    ---@ui 设置~1~计时器控件对~2~显示
    ---@belong timer
    ---@description 设置计时器控件对玩家显示
    ---@applicable both
    if timershow_map[name] == nil then
        return
    end

    local msg = {
        name = name,
        time = base.remaining(timershow_map[name])
    }
    player:ui'add_player_visible'(msg)
    return name
end
 ---@keyword 显示 计时器控件 
function base.del_player_timershow_visible(name, player)
    ---@ui 设置~1~计时器控件对~2~隐藏
    ---@belong timer
    ---@description 设置计时器控件对玩家隐藏
    ---@applicable both
    if timershow_map[name] == nil then
        return
    end

    local msg = {
        name = name,
        time = base.remaining(timershow_map[name])
    }
    player:ui'del_player_visible'(msg)
    return name
end
 ---@keyword 隐藏 计时器控件 
function base.assign_timershow(name, timer)
    ---@ui 设置~1~计时器控件的计时器为~2~
    ---@belong timer
    ---@description 将指定计时器设置给计时器控件
    ---@applicable both
    if timer == nil then
        return
    end

    base.timer_remove(timershow_map[name])
    timershow_map[name] = timer

    local msg = {
        name = name,
        time = base.remaining(timer)
    }
    base.game:ui'assign_timershow'(msg)
    return name
end ---@keyword 设置 计时器控件 