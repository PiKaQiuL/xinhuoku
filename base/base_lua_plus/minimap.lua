function base.create_icon(player, name, point)
    ---@ui 为玩家~1~在~3~处创建~2~的小地图图标
    ---@belong minimap
    ---@description 创建小地图图标
    ---@applicable both
    ---@arg1 1
    if player:get_scene_name() ~= point:get_scene() then
        log.info(stirng.format('点[%s]与玩家[%s]所处场景不同，不能创建图标', point, player))
        return nil
    else
        local icon = base.minimap.icon(player, name, point)
        if icon then
            icon.type = "icon"
            return icon
        end
    end
end
 ---@keyword 地图 图标
function base.icon_set_sync(icon, sync)
    ---@ui 设置~1~的同步方式为~2~
    ---@belong minimap
    ---@description 设置小地图图标同步方式
    ---@applicable action
    if icon_check(icon) then
        icon:set_sync(sync)
    end
end
 ---@keyword 图标 同步
function base.icon_hide(icon)
    ---@ui 隐藏~1~
    ---@belong minimap
    ---@description 隐藏小地图图标
    ---@applicable action
    if icon_check(icon) then
        icon:hide()
    end
end
 ---@keyword 图标 隐藏
function base.icon_hide_team(icon, team)
    ---@ui 隐藏~1~并且立即对队伍~2~不可见
    ---@belong minimap
    ---@description 隐藏小地图图标（立即对一个队伍不可见）
    ---@applicable action
    if icon_check(icon) then
        icon:hide(team)
    end
end
 ---@keyword 图标 隐藏
function base.icon_show(icon)
    ---@ui 显示~1~
    ---@belong minimap
    ---@description 显示小地图图标
    ---@applicable action
    if icon_check(icon) then
        icon:show()
    end
end
 ---@keyword 图标 显示
function base.icon_set_time(icon, time)
    ---@ui 设置~1~的持续时间为~2~秒
    ---@belong minimap
    ---@description 设置小地图图标持续时间
    ---@applicable action
    if icon_check(icon) then
        icon:set_time(time * 1000)
    end
end
 ---@keyword 图标 时间
function base.minimap_signal(player, name, point)
    ---@ui 向玩家~1~发送名称为~2~的信号，位置在~3~
    ---@belong minimap
    ---@description 发送小地图信号
    ---@applicable action
    if player:get_scene_name() ~= point:get_scene() then
        log.info(string.format('点[%s]与玩家[%s]所处场景不同，不能发送小地图信号', point, player))
        return nil
    else
        return base.minimap.signal(player, name, point)
    end
end ---@keyword 地图 信号