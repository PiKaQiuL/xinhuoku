--- lua_plus ---
--[[function base.get_buff(name:string) skill
    ---@ui 获取名为~1~的效果
    ---@belong buff
    return base.buff[name]
end]]
--

function base.get_last_created_buff()buff
    ---@ui 触发器最后创建的Buff
    ---@belong buff
    ---@description 触发器最后创建的Buff
    ---@applicable value
    return base.last_created_buff
end

function base.unit_add_buff(unit:unit, buff_id_name:buff_id, stack:integer)buff
    ---@ui 为~1~添加名为~2~的Buff，层数为~3~
    ---@belong buff
    ---@description 为单位添加Buff
    ---@applicable both
    ---@name1 单位
    ---@name2 Buff表Id
    ---@name3 层数
    ---@arg1 1
    ---@arg2 base.get_last_created_unit()
    if unit_check(unit) then
        local buff:unknown = unit:add_buff_new(buff_id_name, stack)
        base.last_created_buff = buff
        return buff
    end
    base.last_created_buff = nil
end
 ---@keyword 添加
-- function base.get_table_buff(id:buff_id) buff_cache
--     ---@ui 获取Buff类型~1~的数据表
--     ---@belong buff
--     ---@description 获取Buff类型数据表
--     ---@applicable value
--     return base.eff.cache(name)
-- end

-- function base.get_table_data(id:string) table
--     ---@ui 获取Id为~1~的物体编辑器表
--     ---@belong buff
--     ---@description 获取物体编辑器数据表
--     ---@applicable value
--     return base.eff.cache(name)
-- end

function base.buff_set_stack(buff:buff, count:integer)
    ---@ui 设置Buff~1~的层数为~2~
    ---@belong buff
    ---@description 设置Buff层数
    ---@applicable action
    ---@name1 Buff
    ---@name2 层数
    ---@arg1 1
    ---@arg2 base.get_last_created_buff()
    if buff_check(buff) then
        buff:set_stack_(count) --注意：这里是有意加了一个_，是set_stack_而不是set_stack
    end
end
 ---@keyword 设置 层数
function base.buff_get_pulse(buff:buff)number
    ---@ui ~1~的周期
    ---@belong buff
    ---@description Buff周期
    ---@applicable value
    ---@arg1 base.get_last_created_buff()
    if buff_check(buff) then
        return buff:get_pulse()
    end
end
 ---@keyword 周期
function base.buff_get_remaining(buff:buff)number
    ---@ui Buff~1~的剩余时间
    ---@belong buff
    ---@description Buff剩余时间
    ---@applicable value
    ---@arg1 base.get_last_created_buff()
    if buff_check(buff) then
        return buff:get_remaining()
    end
end
 ---@keyword 时间
function base.buff_get_stack_all(unit:unit, link:buff_id)integer
    ---@ui 单位~1~身上Buff~2~的总层数（计算所有实例）
    ---@belong buff
    ---@description 指定Id的buff的总层数（计算所有实例）
    ---@applicable value
    local c:unknown = 0
    for buff:unknown in unit:each_buff(link) do
        c = c + or(buff:get_stack(), 0)
    end
    return c
end
 ---@keyword 层数
function base.buff_get_stack(buff:buff)integer
    ---@ui Buff~1~的层数
    ---@belong buff
    ---@description Buff层数
    ---@applicable value
    ---@arg1 base.get_last_created_buff()
    if buff_check(buff) then
        return or(buff:get_stack(), 0)
    else
        return 0
    end
end
 ---@keyword 层数
function base.buff_remove(buff:buff)
    ---@ui 移除Buff~1~
    ---@belong buff
    ---@description 移除Buff
    ---@applicable action
    ---@arg1 base.get_last_created_buff()
    if buff_check(buff) then
        buff:remove()
    end
end
 ---@keyword 移除
function base.buff_set_pulse(buff:buff, pulse:number)
    ---@ui 设置Buff~1~的心跳周期为~2~秒
    ---@belong buff
    ---@description 设置Buff周期
    ---@applicable action
    ---@arg1 1
    ---@arg2 base.get_last_created_buff()
    if buff_check(buff) then
        buff:set_pulse(pulse)
    end
end
 ---@keyword 设置 周期
function base.buff_set_remaining(buff:buff, remaining:number)
    ---@ui 设置Buff~1~的剩余时间为~2~秒
    ---@belong buff
    ---@description 设置Buff剩余时间
    ---@applicable action
    ---@arg1 10
    ---@arg2 base.get_last_created_buff()
    if buff_check(buff) then
        buff:set_remaining(remaining)
    end
end
 ---@keyword 设置 时间
function base.unit_each_buff(unit:unit, id:buff_id)table<buff>
    ---@ui 获得~1~身上所有Buff~2~的实例
    ---@belong buff
    ---@description 单位身上所有指定Id的Buff
    ---@applicable value
    ---@name1 单位
    ---@name2 Buff表Id
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:each_buff(id)
    end
end
 ---@keyword 获取 Id
function base.unit_find_buff(unit:unit, id:buff_id)buff
    ---@ui 获得~1~身上一个Buff~2~的实例
    ---@belong buff
    ---@description 单位身上一个指定Id的Buff
    ---@applicable value
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:find_buff(id)
    end
end
 ---@keyword 获取 Id
function base.unit_has_buff(unit:unit, id:buff_id)boolean
    ---@ui ~1~身上拥有Id为~2~的Buff实例
    ---@belong buff
    ---@description 单位是否拥有指定Id的Buff
    ---@applicable value
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:find_buff(id) ~= nil
    end
end
 ---@keyword 获取 类型
function base.buff_get_id(buff:buff)buff_id
    ---@ui Buff~1~的Id
    ---@belong buff
    ---@description Buff的Id
    ---@applicable value
    if buff_check(buff) then
        return buff.name
    end
end
 ---@keyword Id
function base.buff_get_level(buff:buff)integer
    ---@ui Buff~1~的等级
    ---@belong buff
    ---@description Buff的等级
    ---@applicable value
    if buff_check(buff) then
        return buff:get_level()
    end
end
 ---@keyword 等级
function base.buff_set_level(buff:buff, level:integer)
    ---@ui 设置Buff~1~的等级为~2~
    ---@belong buff
    ---@description 设置Buff的等级
    ---@applicable action
    if buff_check(buff) then
        return buff:set_level(level)
    end
end
 ---@keyword 等级
function base.buff_get_tracked_units(buff:buff)table<unit>
    ---@ui 获取Buff~1~追踪的所有单位
    ---@belong buff
    ---@description 获取Buff追踪的所有单位
    ---@applicable value
    if buff_check(buff) then
        return buff.tracked_units
    end
end
 ---@keyword 单位
function base.get_all_buffs_id()table<buff_id>
    ---@ui 获取所有Buff表ID
    ---@belong buff
    ---@description 获取所有Buff表ID
    ---@applicable value
    local result:unknown = {}
    for id:unknown, _:unknown in pairs(base.table.buff) do
        table.insert(result, id)
    end
    return result
end