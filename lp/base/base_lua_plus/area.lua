--- lua_plus ---
function base.get_scene_circle(scene:场景, area_name:string, present:global_present)circle
    ---@ui 场景~1~的圆~2~
    ---@description 获取地编中的圆形区域
    ---@applicable value
    ---@selectable false
    ---@name1 场景
    ---@name2 区域名
    ---@name3 全局表
    local circle:unknown = and(present[scene], present[scene]['circle'][area_name])
    if circle then
        circle.scene = or(circle.scene, scene)
    end
    return circle
end

function base.get_scene_rect(scene:场景, area_name:string, present:global_present)rect
    ---@ui 场景~1~的矩形~2~
    ---@description 获取地编中的矩形区域
    ---@applicable value
    ---@selectable false
    ---@name1 场景
    ---@name2 区域名
    ---@name3 全局表
    local rect:unknown = and(present[scene], present[scene]['rect'][area_name])
    if rect then
        rect.scene = or(rect.scene, scene)
    end
    return rect
end

function base.get_scene_area(scene:场景, area_type:string, area_name:string, present:global_present)area
    ---@ui 场景~1~的区域~3~
    ---@description 获取地编区域
    ---@applicable value
    ---@name1 场景
    ---@name2 区域名
    ---@name3 全局表
    local area:unknown = and(present, present[scene], present[scene][area_type], present[scene][area_type][area_name])
    if area then
        area.scene = or(area.scene, scene)
    end
    return area
end

function base.circle_get_point(circle:circle)point
    ---@ui ~1~的圆心
    ---@belong area
    ---@description 圆心
    ---@applicable value
    ---@selectable false
    ---@name1 圆
    if circle_check(circle) then
        return circle:get_scene_point()
    end
end

function base.circle_get_range(circle:circle)number
    ---@ui ~1~的半径
    ---@belong area
    ---@description 圆的半径
    ---@applicable value
    ---@selectable false
    ---@name1 圆
    if circle_check(circle) then
        return circle:get_range()
    end
end

function base.circle_random_point(circle:circle)point
    ---@ui ~1~内的随机点
    ---@belong area
    ---@description 圆内的随机点
    ---@applicable value
    ---@selectable false
    ---@name1 圆
    if circle_check(circle) then
        return circle:scene_random_point()
    end
end

function base.rect_get_point(rect:rect)point
    ---@ui ~1~的中心点
    ---@belong area
    ---@description 矩形的中心点
    ---@applicable value
    ---@selectable false
    ---@name1 矩形
    if rect_check(rect) then
        return rect:get_scene_point()
    end
end

function base.rect_get_width(rect:rect)number
    ---@ui ~1~的宽度
    ---@belong area
    ---@description 矩形的宽度（X轴）
    ---@applicable value
    ---@selectable false
    ---@name1 矩形
    if rect_check(rect) then
        return rect:get_width()
    end
end

function base.rect_get_height(rect:rect)number
    ---@ui 矩形~1~的高度
    ---@belong area
    ---@description 矩形的高度（Y轴）
    ---@applicable value
    ---@selectable false
    ---@name1 矩形
    if rect_check(rect) then
        return rect:get_height()
    end
end

function base.rect_random_point(rect:rect)point
    ---@ui ~1~内的随机点
    ---@belong area
    ---@description 矩形内的随机点
    ---@applicable value
    ---@selectable false
    ---@name1 矩形
    if rect_check(rect) then
        return rect:scene_random_point()
    end
end

function base.get_random_point(area:area)point
    ---@ui ~1~内的随机点
    ---@belong area
    ---@description 区域内的随机点
    ---@applicable value
    ---@name1 矩形
    if area_check(area) then
        return area:scene_random_point()
    end
end

function base.get_area_point(area:area)point
    ---@ui ~1~的中心点
    ---@belong area
    ---@description 区域的中心点
    ---@applicable value
    ---@name1 矩形
    if or(area_check(area, true)) then
        return area:get_scene_point()
    end
end

function base.get_scene_scale_area(scene_name:场景)area
    ---@ui 场景~1~的整个区域
    ---@belong area
    ---@description 场景的整个区域
    ---@applicable value
    ---@name1 场景名
    local x:unknown, y:unknown = base.game.get_scene_scale(scene_name)
    return base.rect(base.point(0, 0), base.point(x, y), scene_name)
end

local unit_tags:table<单位标签> = {
    '英雄',
    '物品',
    '小兵',
    '野怪',
    '生物'
}
unit_tags = 'all'

function base.get_circle_area_unit(circle:circle)table<unit>
    ---@ui ~1~内的所有单位
    ---@belong area
    ---@description 圆形区域内的所有单位
    ---@applicable value
    ---@selectable false
    if circle_check(circle) then
        return base.selector():allow_god():in_circle(circle):of_scene(circle.scene):of_type(unit_tags):enable_death(true):get()
    else
        return {}
    end
end

function base.get_rect_area_unit(rect:rect)table<unit>
    ---@ui ~1~内所有的单位
    ---@belong area
    ---@description 矩形区域内的所有单位
    ---@applicable value
    ---@selectable false
    ---@name1 矩形
    if rect_check(rect) then
        return base.selector():allow_god():in_rect(rect):of_scene(rect.scene):of_type(unit_tags):enable_death(true):get()
    else
        return {}
    end
end

function base.get_area_unit(area:area)table<unit>
    ---@ui ~1~内所有的单位
    ---@belong area
    ---@description 区域内的所有单位
    ---@applicable value
    ---@selectable false
    ---@name1 区域
    if circle_check(area, true) then
        return base.get_circle_area_unit(area)
    elseif rect_check(area, true) then
        return base.get_rect_area_unit(area)
    else
        area_check(area)
    end
end

function base.get_area_unit_group(area:area, 过滤条件:target_filter_string)单位组
    ---@ui ~1~内符合条件~2~的单位组成的单位组
    ---@belong area
    ---@description 区域内的所有单位组成的单位组
    ---@applicable value
    ---@selectable false
    ---@name1 区域
    ---@arg1 target_filter_string_root[';,死亡']
    local ret:unknown = base.单位组{}
    if circle_check(area, true) then
        ret = base.单位组(base.get_circle_area_unit(area))
    elseif rect_check(area, true) then
        ret = base.单位组(base.get_rect_area_unit(area))
    end
    return base.unit_group_filter_group(ret, base.target_filters:new(过滤条件))
end

function base.get_area_type_unit(area:area, unit_id_name:unit_id)table<unit>
    ---@ui ~1~内Id为~2~的单位
    ---@belong area
    ---@description 区域内指定Id的单位
    ---@applicable value
    ---@selectable false
    ---@name1 区域
    ---@name2 单位Id
    local units:unknown = base.get_area_unit(area)
    local ret:unknown = {}
    for i:unknown = 1, # units do
        local unit:unknown = units[i]
        if unit:get_name() == unit_id_name then
            ret[# ret + 1] = unit
        end
    end
    return ret
end

function base.get_area_type_unit_group(area:area, unit_id_name:unit_id, 过滤条件:target_filter_string)单位组
    ---@ui ~1~内Id为~2~符合条件~3~的单位组成的单位组
    ---@belong area
    ---@description 区域内指定Id的单位组成的单位组
    ---@applicable value
    ---@selectable false
    ---@name1 区域
    ---@name2 单位Id
    ---@arg1 target_filter_string_root[';,死亡']
    local units:unknown = base.get_area_unit(area)
    local ret:unknown = {}
    for i:unknown = 1, # units do
        local unit:unknown = units[i]
        if unit:get_name() == unit_id_name then
            ret[# ret + 1] = unit
        end
    end
    return base.unit_group_filter_group(base.单位组(ret), base.target_filters:new(过滤条件))
end

function base.get_area_player_type_unit(area:area, player:player, unit_id_name:unit_id)table<unit>
    ---@ui ~1~内所有属于~2~的Id为~3~的单位
    ---@belong area
    ---@description 区域内属于某个玩家的指定Id的单位
    ---@applicable value
    ---@selectable false
    ---@name1 区域
    ---@name2 玩家
    ---@name3 单位Id
    local units:unknown = base.get_area_unit(area)
    local ret:unknown = {}
    for i:unknown = 1, # units do
        local unit:unknown = units[i]
        if and(or(unit_id_name == base.any_unit_id, unit:get_name() == unit_id_name), or(player == base.any_unit, unit:get_owner() == player)) then
            ret[# ret + 1] = unit
        end
    end
    return ret
end

function base.get_area_player_type_unit_group(area:area, player:player, unit_id_name:unit_id, 过滤条件:target_filter_string)单位组
    ---@ui ~1~内属于~2~的Id为~3~符合条件~4~的单位组成的单位组
    ---@belong area
    ---@description 区域内属于某个玩家的指定Id的单位组成的单位组
    ---@applicable value
    ---@name1 区域
    ---@name2 玩家
    ---@name3 单位Id
    ---@arg1 target_filter_string_root[';,死亡']
    local units:unknown = base.get_area_unit(area)
    local ret:unknown = {}
    for i:unknown = 1, # units do
        local unit:unknown = units[i]
        if and(or(unit_id_name == base.any_unit_id, unit:get_name() == unit_id_name), or(player == base.any_unit, unit:get_owner() == player)) then
            ret[# ret + 1] = unit
        end
    end
    return base.unit_group_filter_group(base.单位组(ret), base.target_filters:new(过滤条件))
end

function base.is_point_in_circle(point:point, circle:circle)boolean
    ---@ui ~1~是否在圆形区域~2~内
    ---@belong area
    ---@description 点是否在圆形区域内
    ---@applicable value
    ---@selectable false
    if circle_check(circle) then
        local dist:unknown, err:unknown = circle:get_scene_point():distance(point)
        if err then
            log.info(string.format('点[%s]不在园所处场景内', point))
            return false
        else
            return (circle:get_scene_point():distance(point)) <= circle:get_range()
        end
    else
        return false
    end
end

function base.is_point_in_rect(point:point, rect:rect)boolean
    ---@ui ~1~是否在矩形区域~2~内
    ---@belong area
    ---@description 点是否在矩形区域内
    ---@applicable value
    ---@selectable false
    if rect_check(rect) then
        if rect:get_scene_point():get_scene() ~= point:get_scene() then
            log.info(string.format('点[%s]不在矩形所处场景内', point))
            return false
        end
        local dx:unknown, dy:unknown = rect:get_width() / 2, rect:get_height() / 2
        local rx:unknown, ry:unknown = rect:get_scene_point():get_xy()
        local px:unknown, py:unknown = point:get_xy()
        return and(math.abs(rx - px) <= dx, math.abs(ry - py) <= dy)
    else
        return false
    end
end

function base.is_point_in_area(point:point, area:area)boolean
    ---@ui ~1~是否在区域~2~内
    ---@belong area
    ---@description 点是否在区域内
    ---@applicable value
    ---@name1 点
    ---@name2 区域
    if area_check(area) then
        if circle_check(area, true) then
            return base.is_point_in_circle(point, area)
        elseif rect_check(area, true) then
            return base.is_point_in_rect(point, area)
        end
        return false
    end
end

function base.is_unit_in_area(unit:unit, area:area)boolean
    ---@ui ~1~是否在区域~2~内
    ---@belong area
    ---@description 单位是否在区域内
    ---@applicable value
    ---@name1 单位
    ---@name2 区域
    if unit_check(unit) then
        if area then
            return base.is_point_in_area(base.unit_get_point(unit), area)
        else
            log.error"区域参数无效，请检测函数传入值"
            return false
        end
    else
        log.error"单位参数无效，请检测函数传入值"
        return false
    end
end