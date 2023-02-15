--- lua_plus ---
function base.point_angle(point:point, target:point)angle
    ---@ui ~1~到~2~的连线的角度
    ---@belong point
    ---@description 两点连线的角度
    ---@applicable value
    ---@name1 点1
    ---@name2 点2
    if point_check(point) then
        return point:angle(target)
    end
end
 ---@keyword 角度
function base.point_copy(point:point)point
    ---@ui 复制点~1~
    ---@belong point
    ---@description 复制点
    ---@applicable value
    ---@name1 点
    if point_check(point) then
        return point:copy()
    end
end
 ---@keyword 复制
function base.point_distance(point:point, target:point)number
    ---@ui ~1~到~2~的距离
    ---@belong point
    ---@description 两点间的距离
    ---@applicable value
    ---@name1 点1
    ---@name2 点2
    if point_check(point) then
        return point:distance(target)
    end
end
 ---@keyword 距离
function base.point_get_x(point:point)number
    ---@ui ~1~的X坐标
    ---@belong point
    ---@description 点的X坐标
    ---@applicable value
    ---@name1 点
    if point_check(point) then
        return point[1]
    end
end
 ---@keyword X 坐标
function base.point_get_y(point:point)number
    ---@ui ~1~的Y坐标
    ---@belong point
    ---@description 点的Y坐标
    ---@applicable value
    ---@name1 点
    if point_check(point) then
        return point[2]
    end
end
 ---@keyword Y 坐标
function base.point_is_block(point:point, scene_name:场景, prevent_bits:碰撞类型, required_bits:碰撞类型)boolean
    ---@ui 场景~2~的点~1~是否符合条件：(有标记~3~，没有标记~4~)的碰撞
    ---@belong point
    ---@description 点的某类碰撞类型检测
    ---@applicable value
    ---@selectable false
    ---@name1 点
    ---@name2 场景名
    ---@name3 碰撞类型1
    ---@name4 碰撞类型2
    if point_check(point) then
        return point:is_block(scene_name, prevent_bits, required_bits)
    end
end
 ---@keyword 碰撞 阻挡
function base.point_is_block2(point:point, prevent_bits:碰撞类型, required_bits:碰撞类型)boolean
    ---@ui 点~1~是否符合条件：(有标记~2~，没有标记~3~)的碰撞
    ---@belong point
    ---@description 点的某类碰撞类型检测
    ---@applicable value
    ---@name1 点
    ---@name2 碰撞类型1
    ---@name3 碰撞类型2
    if point_check(point) then
        return point:is_block(point:get_scene(), prevent_bits, required_bits)
    end
end
 ---@keyword 碰撞 阻挡
function base.point_is_block_all(point:point, scene_name:场景)boolean
    ---@ui 场景~2~的点~1~是否有任何碰撞类型
    ---@belong point
    ---@description 点的碰撞类型检测
    ---@applicable value
    ---@selectable false
    ---@name1 点
    ---@name2 场景名
    if point_check(point) then
        return point:is_block(scene_name)
    end
end
 ---@keyword 碰撞 阻挡
function base.point_is_block_all2(point:point)boolean
    ---@ui 点~1~是否有任何碰撞类型
    ---@belong point
    ---@description 点的碰撞类型检测
    ---@applicable value
    ---@name1 点
    if point_check(point) then
        return point:is_block(point:get_scene())
    end
end
 ---@keyword 碰撞 阻挡
function base.point_is_visible_to_unit(point:point, dest:unit, scene_name:场景)boolean
    ---@ui 场景~3~的点~1~是否对~2~可见
    ---@belong point
    ---@description 点对单位的可见性
    ---@applicable value
    ---@selectable false
    ---@name1 点
    ---@name2 单位
    ---@name3 场景名
    if point_check(point) then
        return point:is_visible(dest, scene_name)
    end
end
 ---@keyword 视野 单位
function base.point_is_visible_to_unit2(point:point, dest:unit)boolean
    ---@ui 点~1~是否对~2~可见
    ---@belong point
    ---@description 点对单位的可见性
    ---@applicable value
    ---@name1 点
    ---@name2 单位
    if point_check(point) then
        return point:is_visible(dest, point:get_scene())
    end
end
 ---@keyword 视野 单位
function base.point_is_visible_to_player(point:point, dest:player, scene_name:场景)boolean
    ---@ui 场景~3~的点~1~是否对~2~可见
    ---@belong point
    ---@description 点对玩家的可见性
    ---@applicable value
    ---@selectable false
    ---@name1 点
    ---@name2 顽疾
    ---@name3 场景名
    if point_check(point) then
        return point:is_visible(dest, scene_name)
    end
end
 ---@keyword 视野 玩家
function base.point_is_visible_to_player(point:point, dest:player)boolean
    ---@ui 点~1~是否对~2~可见
    ---@belong point
    ---@description 点对玩家的可见性
    ---@applicable value
    ---@name1 点
    ---@name2 顽疾
    if point_check(point) then
        return point:is_visible(dest, point:get_scene())
    end
end
 ---@keyword 视野 玩家
function base.point_move(point:point, angle:angle, distance:number)point
    ---@ui ~1~向角度~2~移动距离~3~后的点
    ---@belong point
    ---@description 点的极坐标偏移
    ---@applicable value
    ---@name1 点
    ---@name2 角度
    ---@name3 距离
    if point_check(point) then
        return point:polar_to{
            angle,
            distance
        }
    end
end
 ---@keyword 角度 距离
function base.get_scene_point(scene:场景, area_name:string, present:global_present)point
    ---@ui 场景~1~的点~2~
    ---@description 获取地编点
    ---@applicable value
    if and(present[scene], present[scene]['point'][area_name]) then
        if not(present[scene]['point'][area_name]:get_scene()) then
            present[scene]['point'][area_name] = present[scene]['point'][area_name]:copy_to_scene_point(scene)
        end
    end
    return and(present[scene], present[scene]['point'][area_name])
end

function base.get_scene_line(scene:场景, area_name:string, present:global_present)line
    ---@ui 场景~1~的线~2~
    ---@description 获取地编线
    ---@applicable value
    if and(present[scene], present[scene]['line'][area_name]) then
        for i:unknown = 1, # present[scene]['line'][area_name] do
            if not(present[scene]['line'][area_name][i]:get_scene()) then
                present[scene]['line'][area_name][i] = present[scene]['line'][area_name][i]:copy_to_scene_point(scene)
            end
        end
        present[scene]['line'][area_name].scene = scene
    end
    return and(present[scene], present[scene]['line'][area_name])
end

function base.get_point_scene(point:point)场景
    ---@ui 点~1~的所属场景
    ---@description 点的所属场景
    ---@applicable value
    if point_check(point) then
        return point:get_scene()
    end
end

function base.line_get(line:line, index:integer)point
    ---@ui 线~1~上的第~2~个点
    ---@belong point
    ---@description 线上的点
    ---@applicable value
    ---@name1 线
    ---@name2 位置
    if line_check(line) then
        return line:get(index)
    end
end

function base.pathing_way_points(st:point, ed:point)line
    ---@ui 点~1~到点~2~的通行路径
    ---@belong point
    ---@description 两点间的通行路径
    ---@applicable value
    ---@name1 起点
    ---@name2 终点
    if and(point_check(st), point_check(ed)) then
        if and(st:get_scene(), st:get_scene() == ed:get_scene()) then
            local current_scene:unknown = st:get_scene()
            local _:unknown, points:unknown = base.game.pathing_way_points(st, ed, 0, st:get_scene())
            if points then
                local ret:unknown = {}
                for i:unknown = 1, # points do
                    table.insert(ret, base.scene_point(points[i].x, points[i].y, nil, current_scene))
                end
                return base.line(ret)
            else
                log.info(string.format('无法获取点[%s]到点[%s]的路径', st, ed))
            end
        else
            log.info(string.format('无法获取点[%s]到点[%s]的路径', st, ed))
        end
    end
end ---@keyword 点 线