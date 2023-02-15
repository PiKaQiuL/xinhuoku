--- lua_plus ---
function base.unit_set_loot(unit:unit, link:loot_id)
    ---@ui 设置~1~的击杀奖励列表为~2~
    ---@belong unit
    ---@description 设置单位击杀奖励列表
    ---@applicable action
    if unit_check(unit) then
        unit:set_loot(link)
    end
end

function base.get_last_created_unit()unit
    ---@ui 触发器最后创建的单位
    ---@belong unit
    ---@description 触发器最后创建的单位
    ---@applicable value
    return base.last_created_unit
end

function base.get_all_units_id()table<unit_id>
    ---@ui 获取所有单位ID
    ---@belong unit
    ---@description 获取所有单位ID
    ---@applicable value
    local result:unknown = {}
    for id:unknown, _:unknown in pairs(base.table.unit) do
        table.insert(result, id)
    end
    return result
end

function base.player_create_unit(player:player, id:unit_id, where:point, face:angle)unit
    ---@ui 在~3~创建一个~2~单位，朝向为~4~，所属玩家为~1~
    ---@belong unit
    ---@description 创建单位
    ---@applicable both
    ---@selectable false
    ---@name1 所属玩家
    ---@name2 单位Id
    ---@name3 创建位置
    ---@name4 朝向
    ---@arg1 base.player(1)
    if and(player_check(player), point_check(where)) then
        local unit:unknown = player:create_unit(id, where, face, nil, where:get_scene())
        base.last_created_unit = unit
        if not(unit) then
            log.debug'单位创建失败，请检查创建点是否可用且单位Id是否正确'
        end
        return unit
    end
    base.last_created_unit = nil
end
 ---@keyword 创建 单位
function base.player_create_unit_ai(player:player, id:unit_id, where:point, face:angle, default_ai:是否)unit
    ---@ui 在~3~创建一个~2~单位，朝向为~4~，所属玩家为~1~ (带上默认AI：~5~)
    ---@belong unit
    ---@description 创建单位
    ---@applicable both
    ---@name1 所属玩家
    ---@name2 单位Id
    ---@name3 创建位置
    ---@name4 朝向
    ---@arg1 是否[否]
    ---@arg2 base.player(1)
    local unit:unknown = base.player_create_unit(player, id, where, face)
    if (default_ai) then
        base.unit_add_ai(unit, 'default_ai', base.table_new())
    end
    return unit
end
 ---@keyword 创建 单位
function base.player_create_unit_on_scene(player:player, id:unit_id, where:point, face:angle, scene:场景)unit
    ---@ui 在~5~的~3~创建一个~2~单位，朝向为~4~，所属玩家为~1~
    ---@belong unit
    ---@description 创建单位（指定所属玩家和场景）
    ---@applicable both
    ---@selectable false
    ---@name1 所属玩家
    ---@name2 单位Id
    ---@name3 创建位置
    ---@name4 朝向
    ---@name5 场景
    ---@arg1 base.player(1)
    if player_check(player) then
        local unit:unknown = player:create_unit(id, where, face, nil, scene)
        base.last_created_unit = unit
        if not(unit) then
            log.debug'单位创建失败，请检查创建点是否可用且单位Id是否正确'
        end
        return unit
    end
    base.last_created_unit = nil
end
 ---@keyword 创建 单位
function base.player_create_unit_illusion(player:player, unit:unit, where:point, face:angle)unit
    ---@ui 在~3~创建一个~2~的镜像，朝向为~4~，所属玩家为~1~
    ---@belong unit
    ---@description 创建镜像单位（指定所属玩家）
    ---@applicable both
    ---@name1 所属玩家
    ---@name2 镜像对象
    ---@name3 创建位置
    ---@name4 朝向
    ---@arg1 base.player(1)
    if and(player_check(player), unit_check(unit), point_check(where)) then
        local new_unit:unknown = player:create_illusion(where, face, unit, nil, where:get_scene())
        base.last_created_unit = new_unit
        if not(new_unit) then
            log.debug'单位镜像创建失败，请检查创建点是否可用且单位Id是否正确'
        end
        return new_unit
    end
    base.last_created_unit = nil
end
 ---@keyword 创建 镜像
function base.player_create_unit_illusion_on_scene(player:player, unit:unit, where:point, face:angle, scene:场景)unit
    ---@ui 在~5~的~3~创建一个~2~的镜像，朝向为~4~，所属玩家为~1~
    ---@belong unit
    ---@description 创建镜像单位（指定所属玩家和场景）
    ---@applicable both
    ---@selectable false
    ---@name1 所属玩家
    ---@name2 镜像对象
    ---@name3 创建位置
    ---@name4 朝向
    ---@name5 场景
    ---@arg1 base.player(1)
    if player_check(player) then
        local new_unit:unknown = player:create_illusion(where, face, unit)
        if not(new_unit) then
            log.debug'单位镜像创建失败，请检查创建点是否可用且单位Id是否正确'
            base.last_created_unit = nil
            return
        end
        new_unit:jump_scene(scene)
        base.last_created_unit = new_unit
        return new_unit
    end
    base.last_created_unit = nil
end
 ---@keyword 创建 镜像
function base.unit_create_unit_illusion(unit:unit, dest:unit, where:point, face:angle)unit
    ---@ui 在~3~创建一个~2~的镜像，朝向为~4~，所属单位为~1~
    ---@belong unit
    ---@description 创建镜像单位（指定所属单位）
    ---@applicable both
    ---@name1 所属单位
    ---@name2 镜像对象
    ---@name3 创建位置
    ---@name4 朝向
    if and(unit_check(unit), unit_check(dest), point_check(where)) then
        local result:unknown = unit:create_illusion(where, face, dest, nil, where:get_scene())
        base.last_created_unit = result
        return result
    end
    base.last_created_unit = nil
end
 ---@keyword 创建 镜像
function base.create_unit_illusion(unit:unit, where:point, face:angle)unit
    ---@ui 在~2~创建一个单位~1~的镜像，朝向为~3~
    ---@belong unit
    ---@description 创建镜像单位
    ---@applicable both
    ---@name1 镜像对象
    ---@name2 创建位置
    ---@name3 朝向
    if unit_check(unit) then
        local result:unknown = unit:create_illusion(where, face, nil)
        base.last_created_unit = result
        return result
    end
    base.last_created_unit = nil
end
 ---@keyword 创建 镜像
function base.unit_get_id(unit:unit)integer
    ---@ui ~1~的编号
    ---@belong unit
    ---@description 单位的编号
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_id()
    end
end
 ---@keyword 编号
function base.unit_add_attribute(unit:unit, state:单位属性, value:number)
    ---@ui 修改~1~的~2~属性，使其在原有基础上改变~3~
    ---@belong unit
    ---@description 修改单位属性的基础值
    ---@applicable action
    ---@selectable false
    ---@name1 单位
    ---@name2 单位属性
    ---@name3 改变的值
    ---@arg1 0
    ---@arg2 单位属性["生命"]
    ---@arg3 e.unit
    if unit_check(unit) then
        unit:add(state, value)
    end
end
 ---@keyword 修改 属性
function base.unit_add_attribute_ex(unit:unit, state:单位属性, value:number, value_type:单位数值属性类型)
    ---@ui 修改~1~的~2~属性的~4~值，使其在原有基础上改变~3~
    ---@belong unit
    ---@description 修改单位属性
    ---@applicable action
    ---@name1 单位
    ---@name2 单位属性
    ---@name3 改变的值
    ---@name4 单位数值属性类型
    ---@arg1 单位数值属性类型[0]
    ---@arg2 0
    ---@arg3 单位属性["生命"]
    ---@arg4 e.unit
    if unit_check(unit) then
        unit:add_ex(state, value, value_type)
    end
end
 ---@keyword 修改 属性
function base.unit_add_ai(unit:unit, name:string, data:table)
    ---@ui ~1~添加ai，名称为~2~参数为~3~
    ---@belong unit
    ---@description 添加单位AI
    ---@applicable action
    ---@name1 单位
    ---@name2 AI名称
    ---@name3 参数
    ---@arg1 base.table_new()
    ---@arg2 'default_ai'
    ---@arg3 e.unit
    if unit_check(unit) then
        unit:add_ai(name)(data)
    end
end
 ---@keyword 添加 AI
-- cover play_animation
function base.unit_play_animation(unit:unit, name:string, speed:number, loop:是否, part:动画部位)
    ---@ui 使~1~播放动画~2~，播放速度为~3~，播放部位为~5~，循环播放：~4~
    ---@belong unit
    ---@description 播放单位动画
    ---@applicable action
    ---@name1 单位
    ---@name2 动画名称
    ---@name3 播放速度
    ---@name4 是否循环
    ---@name5 动画部位
    ---@arg1 动画部位["全身"]
    ---@arg2 是否[false]
    ---@arg3 1
    ---@arg4 e.unit
    if unit_check(unit) then
        unit:play_animation(name){
            speed = speed,
            loop = loop,
            part = part
        }
    end
end
 ---@keyword 播放 动画
function base.unit_add_height(unit:unit, height:number)
    ---@ui 提高~1~的高度~2~
    ---@belong unit
    ---@description 增加单位高度
    ---@applicable action
    ---@name1 单位
    ---@name2 高度
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:add_height(height)
    end
end
 ---@keyword 增加 高度
function base.unit_add_provide_sight(unit:unit, team:integer)
    ---@ui 使~1~提供视野给队伍~2~
    ---@belong unit
    ---@description 共享单位视野
    ---@applicable action
    ---@name1 单位
    ---@name2 队伍编号
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:add_provide_sight(team)
    end
end
 ---@keyword 队伍 视野
function base.unit_add_resource(unit:unit, energy_type:能量类型, value:number)
    ---@ui 使~1~的能量-~2~增加~3~
    ---@belong unit
    ---@description 增加单位能量
    ---@applicable action
    ---@name1 单位
    ---@name2 能量类型
    ---@name3 能量增幅
    ---@arg1 100
    ---@arg2 能量类型["法力值"]
    ---@arg3 e.unit
    if unit_check(unit) then
        unit:add_resource(energy_type, value)
    end
end
 ---@keyword 增加 能量
--cover add_restriction
function base.unit_add_mark(unit:unit, unit_type:单位标记)
    ---@ui 为~1~添加标记~2~
    ---@belong unit
    ---@description 为单位添加标记
    ---@applicable action
    ---@name1 单位
    ---@name2 单位标记
    ---@arg1 单位标记["定身"]
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:add_mark(unit_type)
    end
end
 ---@keyword 添加 标记
function base.unit_add_sight(unit:unit, sight:sight)sight_handle
    ---@ui 为~1~添加可见形状~2~
    ---@belong unit
    ---@description 为单位添加可见形状
    ---@applicable action
    ---@name1 单位
    ---@name2 可见形状
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:add_sight(sight)
    end
end
 ---@keyword 添加 可见
-- TODO：等触发器设计
-- function base.unit_event(unit:unit, name:string, callback:function<trigger>) trigger
--     ---@ui ~1~注册名为~2~的事件，调用函数~3~
--     if unit ~= nil then
--         unit:event(name, callback)
--     end
-- end

--[[function base.unit_event_dispatch(unit:unit, name:string, ...) boolean
    ---@ui 触发~1~的名为~2~的关心返回值的事件参数为~3~
    if unit ~= nil then
        return unit:event_dispatch(unit, name, ...)
    end
end

function base.unit_event_notify(unit:unit, name:string, ...)
    ---@ui 触发~1~的名为~2~的事件参数为~3~
    if unit ~= nil then
        unit:event_notify(unit, name, ...)
    end
end

function base.unit_event_has(unit:unit, name:string) boolean
    ---@ui ~1~是否订阅事件~2~
    if unit ~= nil then
        return unit:event_has(unit, name)
    end
end

function base.unit_event_subscribe(unit:unit, name:string)
    ---@ui ~1~订阅事件~2~
    if unit ~= nil then
        unit:event_subscribe(unit, name)
    end
end

function base.unit_event_unsubscribe(unit:unit, name:string)
    ---@ui ~1~取消订阅事件~2~
    if unit ~= nil then
        unit:event_unsubscribe(unit, name)
    end
end]]
--

-- TODO 多返回值
function base.unit_get_attribute(unit:unit, state:单位属性)number
    ---@ui ~1~的属性~2~
    ---@belong unit
    ---@description 单位的属性最终值
    ---@applicable value
    ---@selectable false
    ---@name1 单位
    ---@name2 单位属性
    ---@arg1 单位属性["生命"]
    ---@arg2 e.unit
    if unit_check(unit) then
        if and(state, # state > 0) then
            return unit:get(state)
        end
        return 0
    end
end
 ---@keyword 属性
function base.unit_get_attribute_ex(unit:unit, state:单位属性, value_type:单位数值属性类型)number
    ---@ui ~1~的属性~2~的~3~值
    ---@belong unit
    ---@description 单位的属性
    ---@applicable value
    ---@name1 单位
    ---@name2 单位属性
    ---@name3 单位数值属性类型
    ---@arg1 单位数值属性类型[0]
    ---@arg2 单位属性["生命"]
    ---@arg3 e.unit
    if unit_check(unit) then
        if and(state, # state > 0) then
            return unit:get_ex(state, value_type)
        end
        return 0
    end
end
 ---@keyword 属性
function base.unit_get_attribute_max(unit:unit, state:单位属性)number
    ---@ui ~1~的属性~2~的上限
    ---@belong unit
    ---@description 单位的属性值上限
    ---@applicable value
    ---@name1 单位
    ---@name2 单位属性
    ---@arg1 单位属性["生命"]
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:get_attribute_max(state)
    end
end
 ---@keyword 属性 上限
function base.unit_get_attribute_min(unit:unit, state:单位属性)number
    ---@ui ~1~的属性~2~的下限
    ---@belong unit
    ---@description 单位的属性值下限
    ---@applicable value
    ---@name1 单位
    ---@name2 单位属性
    ---@arg1 单位属性["生命"]
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:get_attribute_min(state)
    end
end
 ---@keyword 属性 下限
function base.unit_get_class(unit:unit)单位类别
    ---@ui ~1~的类别
    ---@belong unit
    ---@description 单位的类别
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_class()
    end
end
 ---@keyword 类别
--[[function base.unit_get_data(unit:unit) table
    ---@ui 获取~1~的数据表
    ---@arg1 e.unit
    ---@description 单位的类别
    ---@applicable value
    ---@belong unit
    if unit_check(unit) then
    if unit ~= nil then
        return unit:get_data()
    end
end]]
--

function base.unit_get_facing(unit:unit)angle
    ---@ui ~1~的朝向
    ---@belong unit
    ---@description 单位的朝向
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_facing()
    end
end
 ---@keyword 角度 朝向
function base.unit_get_height(unit:unit)number
    ---@ui ~1~的离地高度
    ---@belong unit
    ---@description 单位的离地高度
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_height()
    end
end
 ---@keyword 高度
function base.unit_get_creation_param(unit:unit)eff_param
    ---@ui 创建了~1~的效果节点
    ---@belong unit
    ---@description 创建了指定单位的效果节点
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_creation_param()
    end
end
 ---@keyword 高度
function base.unit_get_name(unit:unit)unit_id
    ---@ui 获取~1~的Id
    ---@belong unit
    ---@description 单位的Id
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_name()
    end
end
 ---@keyword 名字
function base.unit_get_player(unit:unit)player
    ---@ui ~1~的所属玩家
    ---@belong unit
    ---@description 单位的所属玩家
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_owner() --[[实际是owner]]
    end
end
 ---@keyword 玩家
function base.unit_set_player(unit:unit, player:player)
    ---@ui 设置~1~的所属玩家为~2~
    ---@belong unit
    ---@description 设置单位的所属玩家
    ---@applicable action
    ---@name1 单位
    ---@arg1 base.player(1)
    ---@arg2 e.unit
    if and(unit_check(unit), player_check(player)) then
        unit:set_owner(player) --实际是owner
    end
end
 ---@keyword 玩家
function base.unit_get_point(unit:unit)point
    ---@ui ~1~的坐标
    ---@belong unit
    ---@description 单位的坐标
    ---@applicable value
    ---@name1 单位
    if unit_check(unit) then
        return unit:get_point():copy_to_scene_point(unit:get_scene_name())
    end
end
 ---@keyword 坐标
function base.unit_get_resource(unit:unit, resource_type:能量类型)number
    ---@ui ~1~的能量-~2~的值
    ---@belong unit
    ---@description 单位的某种能量的数值
    ---@applicable value
    ---@name1 单位
    ---@name2 能量类型
    ---@arg1 能量类型["法力值"]
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:get_resource(resource_type)
    end
end
 ---@keyword 能量
-- cover get_restriction
function base.unit_get_mark(unit:unit, unit_mark:单位标记)integer
    ---@ui ~1~的行为标记~2~的计数
    ---@belong unit
    ---@description 单位的行为标记计数
    ---@applicable value
    ---@name1 单位
    ---@name2 单位标记
    ---@arg1 单位标记["定身"]
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:get_mark(unit_mark)
    end
end
 ---@keyword 标记 层数
function base.unit_get_attackable_radius(unit:unit)number
    ---@ui ~1~的选取半径
    ---@belong unit
    ---@description 单位的选取半径
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_attackable_radius()
    end
end
 ---@keyword 选取半径
function base.unit_get_team_id(unit:unit)integer
    ---@ui ~1~的队伍Id
    ---@belong unit
    ---@description 单位的队伍Id
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_team_id()
    end
end
 ---@keyword 队伍 Id
function base.unit_get_tag(unit:unit)单位标签
    ---@ui ~1~的标签
    ---@belong unit
    ---@description 单位的标签
    ---@applicable value
    ---@selectable false
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_tag()
    end
end
 ---@keyword 标签
function base.unit_get_walk_command_a(unit:unit)string
    ---@ui ~1~的移动理由
    ---@belong unit
    ---@description 单位的移动理由
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_walk_command()
    end
end
 ---@keyword 移动 理由
function base.unit_get_walk_command_b_point(unit:unit)point
    ---@ui ~1~的移动目标点
    ---@belong unit
    ---@description 单位的移动目标点
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        local _:unknown, target:unknown = unit:get_walk_command()
        if target then
            return target:get_point():copy_to_scene_point(unit:get_scene_name())
        end
    end
end
 ---@keyword 移动 目标
function base.unit_get_walk_command_b_unit(unit:unit)unit
    ---@ui ~1~的移动目标单位
    ---@belong unit
    ---@description 单位的移动目标单位
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        local _:unknown, target:unknown = unit:get_walk_command()
        if target then
            return target:get_unit()
        end
    end
end
 ---@keyword 移动 目标
function base.unit_walk(unit:unit, target:point)
    ---@ui 令~1~向~2~移动
    ---@belong unit
    ---@description 令单位向点移动
    ---@applicable action
    ---@name1 单位
    ---@name2 目标点
    if and(unit_check(unit), point_check(target)) then
        if unit:get_scene_name() == target:get_scene() then
            unit:walk(target)
        else
            log.info(string.format('单位[%s]无法向点[%s]移动', unit, target))
            return nil
        end
    end
end
 ---@keyword 移动
--[[function base.unit_get_xy(unit:unit) number, number
    ---@ui 获取~1~的坐标
    if unit ~= nil then
        return unit:get_xy()
    end
end]]
--

-- cover has_restriction
function base.unit_has_mark(unit:unit, unit_mark:单位标记)boolean
    ---@ui ~1~是否存在标记~2~
    ---@belong unit
    ---@description 单位是否存在标记
    ---@applicable value
    ---@name1 单位
    ---@name2 单位标记
    ---@arg1 单位标记["定身"]
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:has_mark(unit_mark)
    end
end
 ---@keyword 标记
function base.unit_is_alive(unit:unit)boolean
    ---@ui ~1~是否存活
    ---@belong unit
    ---@description 单位是否存活
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if not(unit) then
        return false
    end

    if unit.removed then
        return false
    end
    if unit_check(unit) then
        return unit:is_alive()
    end
end
 ---@keyword 存活 死亡
function base.unit_is_ally_of_unit(unit:unit, dest:unit)boolean
    ---@ui ~1~是否是~2~的友方
    ---@belong unit
    ---@description 单位与单位的盟友关系
    ---@applicable value
    ---@name1 单位
    ---@name2 目标单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:is_ally(dest)
    end
end
 ---@keyword 盟友 友方
function base.unit_is_ally_of_player(unit:unit, dest:player)boolean
    ---@ui ~1~是否是~2~的友方
    ---@belong unit
    ---@description 单位与玩家的盟友关系
    ---@applicable value
    ---@name1 单位
    ---@name2 目标玩家
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:is_ally(dest)
    end
end
 ---@keyword 盟友 友方
function base.unit_is_enemy_of_unit(unit:unit, dest:unit)boolean
    ---@ui ~1~是否是~2~的敌人
    ---@belong unit
    ---@description 单位与单位的敌对关系
    ---@applicable value
    ---@name1 单位
    ---@name2 目标单位
    ---@arg1 e.unit
    if and(unit_check(unit), unit_check(dest)) then
        return unit:is_enemy(dest)
    end
end
 ---@keyword 敌对 敌人
function base.unit_is_enemy_of_player(unit:unit, dest:player)boolean
    ---@ui ~1~是否是~2~的敌人
    ---@belong unit
    ---@description 单位与玩家的敌对关系
    ---@applicable value
    ---@name1 单位
    ---@name2 目标玩家
    ---@arg1 e.unit
    if and(unit_check(unit), player_check(dest)) then
        return unit:is_enemy(dest)
    end
end
 ---@keyword 敌对 敌人
function base.unit_is_illusion(unit:unit)boolean
    ---@ui ~1~是否是镜像
    ---@belong unit
    ---@description 单位是否是镜像
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:is_illusion()
    end
end
 ---@keyword 镜像
function base.unit_is_in_range_of_unit(unit:unit, target:unit, radius:number)boolean
    ---@ui ~1~是否在~2~的~3~距离内
    ---@belong unit
    ---@description 单位是否在另一单位的指定距离内
    ---@applicable value
    ---@name1 单位
    ---@name2 目标单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:is_in_range(target, radius)
    end
end
 ---@keyword 单位 距离
function base.unit_is_in_range_of_point(unit:unit, target:point, radius:number)boolean
    ---@ui ~1~是否在点~2~的~3~距离内
    ---@belong unit
    ---@description 单位是否在点的指定距离内
    ---@applicable value
    ---@name1 单位
    ---@name2 目标点
    ---@arg1 e.unit
    if and(unit_check(unit), point_check(target)) then
        if unit:get_scene_name() == target:get_scene() then
            return unit:is_in_range(target, radius)
        else
            return false
        end
    end
end
 ---@keyword 点 距离
function base.unit_is_visible_to_unit(unit:unit, target:unit)boolean
    ---@ui ~1~是否对~2~可见
    ---@belong unit
    ---@description 单位对单位是否可见
    ---@applicable value
    ---@name1 单位
    ---@name2 目标单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:is_visible(target)
    end
end
 ---@keyword 可见 视野
function base.unit_is_visible_to_player(unit:unit, target:player)boolean
    ---@ui ~1~是否对~2~可见
    ---@belong unit
    ---@description 单位对玩家是否可见
    ---@applicable value
    ---@name1 单位
    ---@name2 目标玩家
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:is_visible(target)
    end
end
 ---@keyword 可见 视野
function base.unit_is_walking(unit:unit)boolean
    ---@ui ~1~是否在移动
    ---@belong unit
    ---@description 单位是否在移动
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:is_walking()
    end
end
 ---@keyword 移动
function base.unit_add_z_speed(unit:unit, speed:number)
    ---@ui 使~1~的Z轴速度值增加~2~
    ---@belong unit
    ---@description 增加单位的Z轴速度值
    ---@applicable action
    ---@name1 单位
    ---@arg1 100
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:add_z_speed(speed)
    end
end
 ---@keyword 增加 速度
function base.unit_set_z_speed(unit:unit, speed:number)
    ---@ui 设置~1~的Z轴速度值为~2~
    ---@belong unit
    ---@description 设置单位的Z轴速度值
    ---@applicable action
    ---@name1 单位
    ---@arg1 100
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_z_speed(speed)
    end
end
 ---@keyword 设置 速度
function base.unit_get_z_speed(unit:unit)number
    ---@ui ~1~的Z轴速度值
    ---@belong unit
    ---@description 单位的Z轴速度值
    ---@applicable value
    ---@name1 单位
    ---@arg1 100
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:get_z_speed()
    end
end
 ---@keyword Z 速度
function base.unit_kill(unit:unit, killer:unit)boolean
    ---@ui 杀死~1~，并设置凶手为~2~
    ---@belong unit
    ---@description 杀死单位
    ---@applicable action
    ---@name1 单位
    ---@name2 凶手
    ---@arg1 e.unit
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:kill(killer)
    end
end
 ---@keyword 杀死 凶手
function base.unit_learn_skill(unit:unit, skill_id_name:skill_id)
    ---@ui 令~1~学习技能：~2~
    ---@belong unit
    ---@description 令单位学习技能
    ---@applicable action
    ---@name1 单位
    ---@name2 技能
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:learn_skill(skill_id_name)
    end
end
 ---@keyword 学习 技能
--[[function base.unit_loop(unit:unit, timeout:number, on_timer:function<timer>) timer
    ---@ui ~1~启动周期为~2~秒的循环计时器,触发回调函数~3~
    if unit ~= nil then
        return unit:loop(math.ceil(timeout*1000), on_timer)
    end
end]]
--

function base.unit_reborn(unit:unit, where:point)
    ---@ui 使~1~在~2~处复活
    ---@belong unit
    ---@description 复活单位
    ---@applicable action
    ---@name1 单位
    ---@name2 复活位置
    ---@arg1 e.unit
    if and(unit_check(unit), point_check(where)) then
        if unit:get_scene_name() == where:get_scene() then
            unit:reborn(where)
        else
            log.info(string.format('单位[%s]与点[%s]场景不同，无法复活', unit, where))
        end
    end
end
 ---@keyword 复活
function base.unit_remove(unit:unit)
    ---@ui 移除~1~
    ---@belong unit
    ---@description 移除单位
    ---@applicable action
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:remove()
    end
end
 ---@keyword 移除
function base.unit_remove_animation(unit:unit, animation_name:string)
    ---@belong unit
    ---@description 移除单位的动画
    ---@applicable action
    ---@name1 单位
    ---@name2 移除的动画
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:remove_animation(animation_name)
    end
end
 ---@keyword 移除 动画
function base.unit_remove_buff(unit:unit, buff_name:buff_id)
    ---@ui 移除~1~身上的~2~Buff
    ---@belong unit
    ---@description 移除单位指定类型的Buff
    ---@applicable action
    ---@name1 单位
    ---@name2 移除的Buff
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:remove_buff(buff_name)
    end
end
 ---@keyword 移除 Buff
function base.unit_remove_privide_sight(unit:unit, team_id:number)
    ---@ui 移除~1~对队伍~2~的视野共享
    ---@belong unit
    ---@description 移除单位对队伍的视野共享
    ---@applicable action
    ---@name1 单位
    ---@name2 队伍
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:remove_privide_sight(team_id)
    end
end
 ---@keyword 移除 视野
-- cover:remove_restriction
function base.unit_remove_mark(unit:unit, unit_mark:单位标记)
    ---@ui 移除~1~身上的行为标记~2~
    ---@belong unit
    ---@description 移除单位的行为标记
    ---@applicable action
    ---@name1 单位
    ---@name2 单位标记
    ---@arg1 单位标记["定身"]
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:remove_mark(unit_mark)
    end
end
 ---@keyword 移除 标记
function base.unit_replace_skill(unit:unit, skill_id_old:skill_id, skill_id_new:skill_id)
    ---@ui 将~1~的技能~2~替换为技能~3~
    ---@belong unit
    ---@description 替换单位的技能
    ---@applicable action
    ---@name1 单位
    ---@name2 旧技能Id
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:replace_skill(skill_id_old, skill_id_new)
    end
end
 ---@keyword 替换 技能
-- 仅限内置属性
function base.unit_set(unit:unit, state:单位属性, value:number)
    ---@ui 设置~1~的属性~2~为~3~
    ---@belong unit
    ---@description 设置单位属性基础值并清空百分比（数值属性）
    ---@applicable action
    ---@selectable false
    ---@name1 单位
    ---@name2 单位属性
    ---@name3 值
    ---@arg1 0
    ---@arg2 单位属性["生命"]
    ---@arg3 e.unit
    if unit_check(unit) then
        unit:set(state, value)
    end
end
 ---@keyword 属性
function base.unit_set_ex(unit:unit, state:单位属性, value:number, value_type:单位数值属性类型)
    ---@ui 设置~1~的属性~2~的~4~值为~3~
    ---@belong unit
    ---@description 设置单位属性（数值属性）
    ---@applicable action
    ---@name1 单位
    ---@name2 单位属性
    ---@name3 值
    ---@name4 单位数值属性类型
    ---@arg1 单位数值属性类型[0]
    ---@arg2 0
    ---@arg3 单位属性["生命"]
    ---@arg4 e.unit
    if unit_check(unit) then
        unit:set_ex(state, value, value_type)
    end
end
 ---@keyword 属性
function base.unit_set_str(unit:unit, state:单位属性, value:string)
    ---@ui 设置~1~的字符串属性~2~为~3~
    ---@belong unit
    ---@description 设置单位属性（字符串属性）
    ---@applicable action
    ---@name1 单位
    ---@name2 单位属性
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:set(state, value)
    end
end
 ---@keyword 属性
function base.unit_set_attribute_max(unit:unit, state:单位属性, value:number)
    ---@ui 设置~1~的属性~2~的上限为~3~
    ---@belong unit
    ---@description 设置单位属性上限
    ---@applicable action
    ---@name1 单位
    ---@name2 单位属性
    ---@arg1 单位属性["生命"]
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_attribute_max(state, value)
    end
end
 ---@keyword 属性 上限
function base.unit_set_attribute_min(unit:unit, state:单位属性, value:number)
    ---@ui 设置~1~的属性~2~的最小值为~3~
    ---@belong unit
    ---@description 设置单位属性下限
    ---@applicable action
    ---@name1 单位
    ---@name2 单位属性
    ---@arg1 单位属性["生命"]
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_attribute_min(state, value)
    end
end
 ---@keyword 属性 下限
function base.unit_set_attribute_sync(unit:unit, state:单位属性, sync:同步方式)
    ---@ui 设置~1~的属性~2~的同步方式为~3~
    ---@belong unit
    ---@description 设置单位属性同步方式
    ---@applicable action
    ---@name1 单位
    ---@name2 单位属性
    ---@arg1 同步方式["全部"]
    ---@arg2 单位属性["生命"]
    ---@arg3 e.unit
    if unit_check(unit) then
        unit:set_attribute_sync(state, sync)
    end
end
 ---@keyword 属性 同步方式
function base.unit_set_facing(unit:unit, facing:angle)
    ---@ui 设置~1~的朝向为~2~度
    ---@belong unit
    ---@description 设置单位的朝向
    ---@applicable action
    ---@name1 单位
    ---@name2 方向
    ---@arg1 90
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_facing(facing, nil)
    end
end
 ---@keyword 朝向
function base.unit_set_height(unit:unit, height:number)
    ---@ui 设置~1~的高度为~2~
    ---@belong unit
    ---@description 设置单位高度
    ---@applicable action
    ---@name1 单位
    ---@name2 高度
    ---@arg1 0
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_height(height)
    end
end
 ---@keyword 高度
function base.unit_set_model(unit:unit, model:model_id)
    ---@ui 设置~1~的模型为~2~
    ---@belong unit
    ---@description 设置单位模型
    ---@applicable action
    ---@name1 单位
    ---@name2 模型
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:set_asset(model)
    end
end
 ---@keyword 模型
function base.unit_set_resource(unit:unit, energy_type:能量类型, value:number)
    ---@ui 设置~1~的能量-~2~为~3~
    ---@belong unit
    ---@description 设置单位能量
    ---@applicable action
    ---@name1 单位
    ---@name2 能量类型
    ---@arg1 100
    ---@arg2 能量类型["法力值"]
    ---@arg3 e.unit
    if unit_check(unit) then
        unit:set_resource(energy_type, value)
    end
end
 ---@keyword 能量
function base.unit_set_attackable_radius(unit:unit, radius:number)
    ---@ui 设置~1~的选取半径为~2~
    ---@belong unit
    ---@description 设置单位选取半径
    ---@applicable action
    ---@name1 单位
    ---@name2 选取半径
    ---@arg1 100
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_attackable_radius(radius)
    end
end
 ---@keyword 选取半径
-- function base.unit_stop(unit:unit)
--     ---@ui 停止~1~的行动
--     ---@arg1 e.unit
--     ---@description 令单位停止（打断攻击、施法和移动）
--     ---@keyword 停止
--     ---@applicable action
--     ---@belong unit
--     ---@name1 单位
--     if unit_check(unit) then
--         unit:stop()
--     end
-- end

-- function base.unit_stop_attack(unit:unit)
--     ---@ui 停止~1~的攻击
--     ---@arg1 e.unit
--     ---@description 令单位停止攻击
--     ---@keyword 停止 攻击
--     ---@applicable action
--     ---@belong unit
--     ---@name1 单位
--     if unit_check(unit) then
--         unit:stop_attack()
--     end
-- end

-- function base.unit_stop_cast(unit:unit)
--     ---@ui 停止~1~的攻击和施法
--     ---@arg1 e.unit
--     ---@description 令单位停止攻击和施法
--     ---@keyword 停止 攻击 施法
--     ---@applicable action
--     ---@belong unit
--     ---@name1 单位
--     if unit_check(unit) then
--         unit:stop_cast()
--     end
-- end

-- function base.unit_stop_skill(unit:unit)
--     ---@ui 停止~1~的施法
--     ---@arg1 e.unit
--     ---@description 令单位停止施法
--     ---@keyword 停止 施法
--     ---@applicable action
--     ---@belong unit
--     ---@name1 单位
--     if unit_check(unit) then
--         unit:stop_skill()
--     end
-- end

function base.unit_texttag(unit:unit, target:unit, text:string, text_type:漂浮文字类型, sync:同步方式, r:integer, g:integer, b:integer, size:integer)
    ---@ui 在~2~上创建内容为~3~，类型为~4~，同步方式为~5~，属性为(红:~6~绿:~7~蓝:~8~大小:~9~)的漂浮文字，将创建来源设为~1~
    ---@belong unit
    ---@description 创建漂浮文字
    ---@applicable action
    ---@name1 来源单位
    ---@name2 目标单位
    ---@name3 文字内容
    ---@name4 漂浮文字类型
    ---@name5 同步方式
    ---@name6 红
    ---@name7 绿
    ---@name8 蓝
    ---@name9 大小
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:texttag(target, text, text_type, sync, {
            r = r,
            g = g,
            b = b,
            size = size
        })
    end
end
 ---@keyword 文字 UI
function base.unit_get_scene_name(unit:unit)string
    ---@ui ~1~所在场景的名称
    ---@belong unit
    ---@description 单位所在场景的名称
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_scene_name()
    end
end
 ---@keyword 场景 名称
function base.unit_jump_scene(unit:unit, scene_name:场景, position:point)boolean
    ---@ui 将~1~转移到场景~2~的~3~处
    ---@belong unit
    ---@description 转移单位场景
    ---@applicable action
    ---@selectable false
    ---@name1 单位
    ---@name2 场景
    ---@name3 位置
    ---@arg1 e.unit
    if unit_check(unit) then
        local success:unknown = unit:jump_scene(scene_name)
        if success then
            unit:blink(position)
        end
        return success
    end
    return false
end
 ---@keyword 场景 移动
function base.unit_jump_scene2(unit:unit, position:point)boolean
    ---@ui 将~1~转移到~2~处
    ---@belong unit
    ---@description 转移单位场景
    ---@applicable action
    ---@name1 单位
    ---@name2 位置
    ---@arg1 e.unit
    if unit_check(unit) then
        local success:unknown = unit:jump_scene(position:get_scene())
        if success then
            unit:blink(position)
        end
        return success
    end
    return false
end
 ---@keyword 移动
function base.get_all_units()单位组
    ---@ui 所有单位
    ---@belong unit
    ---@description 所有单位
    ---@applicable value
    return base.单位组(base.test.unit())
end

function base.node_mark(node_mark:string, unit_name:string)node_mark
    return node_mark
end

function base.set_location_async(unit:unit, position:point)
    ---@ui 异步设置~1~单位的位置到~2~
    ---@belong unit
    ---@description 设置单位位置（异步）
    ---@applicable action
    ---@name1 单位
    ---@name2 位置
    if unit_check(unit) then
        unit:set_location_async(position)
    end
end
 ---@keyword 单位 移动
function base.set_facing_async(unit:unit, facing:angle)
    ---@ui 异步设置~1~单位的朝向为~2~
    ---@belong unit
    ---@description 设置单位朝向（异步）
    ---@applicable action
    ---@name1 单位
    ---@name2 方向
    if unit_check(unit) then
        unit:set_facing_async(facing)
    end
end
 ---@keyword 单位 朝向
function base.unit_get_exp(unit:unit)number
    ---@ui ~1~的经验值
    ---@belong unit
    ---@description 单位的经验值
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_exp()
    end
end
 ---@keyword 经验
function base.unit_add_exp(unit:unit, exp:number, ignore_fraction:boolean)
    ---@ui 为~1~增加~2~点经验值（是否忽略经验倍率：~3~）
    ---@belong unit
    ---@description 增加单位经验值
    ---@applicable action
    ---@name1 单位
    ---@name2 经验值
    ---@arg1 false
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:add_exp(exp, ignore_fraction)
    end
end
 ---@keyword 增加 经验
function base.unit_set_exp(unit:unit, exp:number)
    ---@ui 设置~1~的经验值为~2~
    ---@belong unit
    ---@description 设置单位经验值
    ---@applicable action
    ---@name1 单位
    ---@name2 经验值
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:set_exp(exp)
    end
end
 ---@keyword 设置 经验
function base.unit_get_level(unit:unit)integer
    ---@ui ~1~的等级
    ---@belong unit
    ---@description 单位的等级
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_level()
    end
end
 ---@keyword 等级
function base.unit_add_level(unit:unit, level:integer)
    ---@ui 使~1~的等级提高~2~级
    ---@belong unit
    ---@description 提高单位等级
    ---@applicable action
    ---@name1 单位
    ---@name2 等级
    ---@arg1 e.unit
    if unit_check(unit) then
        unit:add_level(level)
    end
end
 ---@keyword 增加 等级
function base.unit_set_level(unit:unit, level:integer)
    ---@ui 设置~1~的等级为~2~
    ---@belong unit
    ---@description 设置单位等级
    ---@applicable action
    ---@name1 单位
    ---@name2 等级
    ---@arg1 10
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_level(level)
    end
end
 ---@keyword 等级
function base.unit_get_max_level(unit:unit)integer
    ---@ui ~1~的等级上限
    ---@belong unit
    ---@description 单位的等级上限
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_max_level()
    end
end
 ---@keyword 等级上限
function base.unit_set_max_level(unit:unit, max_level:integer)
    ---@ui 设置~1~的等级上限为~2~
    ---@belong unit
    ---@description 设置单位等级上限
    ---@applicable action
    ---@name1 单位
    ---@name2 等级上限
    ---@arg1 10
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_max_level(max_level)
    end
end
 ---@keyword 等级上限
function base.unit_get_single_level_exp(unit:unit, level:integer)integer
    ---@ui ~1~的第~2~级所需的经验
    ---@belong unit
    ---@description 计算单位某一级所需经验
    ---@applicable value
    ---@name1 单位
    ---@name2 等级
    ---@arg1 1
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:get_single_level_exp(level)
    end
end
 ---@keyword 等级 经验
function base.unit_get_cumu_level_exp(unit:unit, level:integer)integer
    ---@ui ~1~升到~2~级总共所需的经验
    ---@belong unit
    ---@description 计算单位升到某一级所需的总经验
    ---@applicable value
    ---@name1 单位
    ---@name2 等级
    ---@arg1 1
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:get_cumu_level_exp(level)
    end
end
 ---@keyword 等级 经验
function base.unit_get_exp_fraction(unit:unit)number
    ---@ui ~1~的经验倍率
    ---@belong unit
    ---@description 单位的经验倍率
    ---@applicable value
    ---@name1 单位
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:get_exp_fraction()
    end
end
 ---@keyword 经验倍率
function base.unit_set_exp_fraction(unit:unit, fraction:number)
    ---@ui 设置~1~的经验倍率为~2~
    ---@belong unit
    ---@description 设置单位经验倍率
    ---@applicable action
    ---@name1 单位
    ---@name2 经验倍率
    ---@arg1 10
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_exp_fraction(fraction)
    end
end
 ---@keyword 经验倍率
function base.unit_set_prohibit_exp_distribute(unit:unit, value:boolean)
    ---@ui 设置~1~是否参与经验值分配为~2~
    ---@belong unit
    ---@description 设置单位是否参与经验值分配
    ---@applicable action
    ---@name1 单位
    ---@arg1 false
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_prohibit_exp_distribute(not(value))
    end
end
 ---@keyword 经验 分配
function base.unit_set_level_profile(unit:unit, profile_id:unit_level_profile_id)
    ---@ui 设置~1~的升级配置为~2~
    ---@belong unit
    ---@description 设置单位升级配置
    ---@applicable action
    ---@name1 单位
    ---@name2 单位升级配置Id
    ---@arg1 10
    ---@arg2 e.unit
    if unit_check(unit) then
        unit:set_level_profile(profile_id)
    end
end
 ---@keyword 升级配置
function base.unit_grant_loot(unit:unit, target:unit, link:loot_id)
    ---@ui 使~1~对~2~直接给予奖励~3~
    ---@belong unit
    ---@description 直接给予单位奖励
    ---@applicable action
    if and(unit_check(target), unit_check(unit)) then
        unit:grant_loot(link, target)
    end
end

-- function base.set_level_profile(unit:unit) number
--     ---@ui ~1~的经验上限
--     ---@arg1 e.unit
--     ---@description 单位的经验上限
--     ---@keyword 经验 上限
--     ---@applicable value
--     ---@belong unit
--     ---@name1 单位
--     if unit_check(unit) then
--         return unit:get_max_exp()
--     end
-- end

function base.get_unit_from_id(id:number)unit
    ---@ui 编号为~1~的单位
    ---@belong unit
    ---@description 从单位编号获取单位
    ---@applicable value
    ---@name1 单位编号
    return base.unit(id)
end ---@keyword 单位