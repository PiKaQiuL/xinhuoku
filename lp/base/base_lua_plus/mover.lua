--- lua_plus ---
function base.get_last_created_mover()mover
    ---@ui 触发器最后创建的移动器
    ---@belong mover
    ---@description 触发器最后创建的移动器
    ---@applicable value
    return base.last_created_mover
end

function base.skill_mover_line(mover:unit, target:point, speed:number, mover_id_name:mover_id, on_block:function, on_finish:function, on_hit:function, on_remove:function)mover
    ---@ui 使~1~向目标点~2~进行速度为~3~的直线运动，参数为~4~~5~~6~~7~~8~
    ---@belong mover
    ---@description 使单位向目标点进行直线运动
    ---@arg1 1000
    ---@arg2 e.unit
    local ori_mover_table:unknown = base.eff.cache(mover_id_name)
    local min_speed:unknown = ori_mover_table.min_speed

    if and(min_speed, min_speed > speed) then
        min_speed = speed
    end
    if and(unit_check(mover), point_check(target), or(ori_mover_table == nil, ori_mover_table.NodeType == 'MoverTo')) then
        if mover:get_scene_name() ~= target:get_scene() then
            log.info(string.format('点[%s]与单位[%s]所处场景不同，不能创建直线移动器', target, mover))
            base.last_created_mover = nil
            return nil
        else
            local mover_table:unknown = {}
            if ori_mover_table then
                for k:unknown, v:unknown in pairs(ori_mover_table) do
                    mover_table[k] = v
                end
            end
            mover_table.source = mover
            mover_table.speed = speed
            mover_table.target = target
            mover_table.mover = mover
            mover_table.on_block = on_block
            mover_table.on_finish = on_finish
            mover_table.on_hit = on_hit
            mover_table.on_remove = on_remove
            mover_table.hit_type = '全部'
            mover_table.min_speed = min_speed
            local new_mover:unknown = base.game:mover_line(mover_table)
            base.last_created_mover = new_mover
            return new_mover
        end
    end
    base.last_created_mover = nil
end
 ---@keyword 单位 直线
local function follow_or_move_to(moving_unit:unknown, target:unknown, speed:unknown, mover_id_name:unknown, on_block:unknown, on_finish:unknown, on_hit:unknown, on_remove:unknown)
    local ori_mover_table:unknown = base.eff.cache(mover_id_name)
    local min_speed:unknown = ori_mover_table.min_speed

    if and(min_speed, min_speed > speed) then
        min_speed = speed
    end

    if and(unit_check(moving_unit), unit_check(target)) then
        if moving_unit:get_scene_name() ~= target:get_scene() then
            log.info(string.format('目标[%s]与单位[%s]所处场景不同，不能创建移动器', target, moving_unit))
            base.last_created_mover = nil
            return nil
        else
            local mover_table:unknown = {}
            if ori_mover_table then
                for k:unknown, v:unknown in pairs(ori_mover_table) do
                    mover_table[k] = v
                end
            end
            mover_table.source = moving_unit
            mover_table.speed = speed
            mover_table.target = target
            mover_table.mover = moving_unit
            mover_table.on_block = on_block
            mover_table.on_finish = on_finish
            mover_table.on_hit = on_hit
            mover_table.on_remove = on_remove
            mover_table.hit_type = '全部'
            mover_table.min_speed = min_speed
            local mover:unknown

            if and(ori_mover_table, ori_mover_table.NodeType == 'MoverFollow') then
                mover = target:follow(mover_table)
            else
                mover = base.game:mover_target(mover_table)
            end

            base.last_created_mover = mover
            return mover
        end
    end
    base.last_created_mover = nil
end

function base.skill_mover_target(moving_unit:unit, target:unit, speed:number, mover_id_name:mover_id, on_block:function, on_finish:function, on_hit:function, on_remove:function)moving_unit
    ---@ui 使~1~向目标~2~进行速度为~3~的追踪运动，使用的运动参数为~4~~5~~6~~7~~8~
    ---@belong mover
    ---@description 使单位向目标单位进行追踪运动
    ---@arg1 1000
    ---@arg2 e.unit
    return follow_or_move_to(moving_unit, target, speed, mover_id_name, on_block, on_finish, on_hit, on_remove)
end
 ---@keyword 单位 追踪
function base.mover_batch_update(mover:mover)
    ---@ui 批量更新移动器~1~
    ---@belong mover
    ---@description 批量更新移动器
    ---@applicable action
    if mover ~= nil then
        mover:batch_update()
    end
end
 ---@keyword 更新
function base.mover_remove(mover:mover)
    ---@ui 移除移动器~1~
    ---@belong mover
    ---@description 移除移动器
    ---@applicable action
    if mover ~= nil then
        mover:remove()
    end
end
 ---@keyword 移除
function base.unit_each_mover(unit:unit)table<mover>
    ---@ui ~1~身上的所有移动器
    ---@belong mover
    ---@description 单位身上的所有移动器
    ---@applicable value
    if unit_check(unit) then
        return unit:each_mover()
    end
end
 ---@keyword 单位 获取
function base.unit_follow(mover:unit, target:unit, speed:number, mover_id_name:mover_id, on_block:function, on_finish:function, on_hit:function, on_remove:function)mover
    ---@ui 使~1~跟随目标~2~并忽视寻路，使用的跟随参数为~4~~5~~6~~7~~8~
    ---@belong mover
    ---@description 使单位跟随单位（忽视寻路）
    ---@arg1 e.unit
    return follow_or_move_to(mover, target, speed, mover_id_name, on_block, on_finish, on_hit, on_remove)
end ---@keyword 单位 跟随