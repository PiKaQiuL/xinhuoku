function base.get_last_created_skill()
    ---@ui 触发器最后添加的技能
    ---@belong skill
    ---@description 触发器最后添加的技能
    ---@applicable value
    return base.last_created_skill
end

-- function base.get_table_skill(id:skill_id) skill_cache
--     ---@ui 获取技能类型~1~的数据表
--     ---@belong skill
--     ---@description 获取技能类型的数据表
--     ---@applicable value
--     return base.eff.cache(id)
-- end

function base.unit_add_skill(unit, id, skill_type, slot)
    ---@ui 为~1~添加技能~2~，存在形式为~3~，格子为~4~
    ---@belong skill
    ---@description 为单位添加技能
    ---@selectable false
    if unit_check(unit) then
        local skill = unit:add_skill(id, skill_type, slot)
        base.last_created_skill = skill
        return skill
    end
    base.last_created_skill = nil
end
 ---@keyword 添加
function base.add_skill_to_slot(unit, id, slot)
    ---@ui 为~1~添加技能~2~，格子为~3~
    ---@belong skill
    ---@description 为单位添加技能（并指定位置）
    if unit_check(unit) then
        local skill = unit:add_skill(id, '英雄', slot)
        base.last_created_skill = skill
        return skill
    end
    base.last_created_skill = nil
end
 ---@keyword 添加
function base.add_skill(unit, id, slot)
    ---@ui 为~1~添加技能~2~，格子为~3~
    ---@belong skill
    ---@description 为单位添加技能（并指定位置）
    ---@selectable false
    if unit_check(unit) then
        local skill = unit:add_skill(id, '英雄', slot)
        base.last_created_skill = skill
        return skill
    end
    base.last_created_skill = nil
end
 ---@keyword 添加
function base.add_skill(unit, id)
    ---@ui 为~1~添加技能~2~
    ---@belong skill
    ---@description 为单位添加技能（不指定位置）
    if unit_check(unit) then
        local skill = unit:add_skill(id, '英雄')
        base.last_created_skill = skill
        return skill
    end
    base.last_created_skill = nil
end
 ---@keyword 添加
function base.skill_active_cd(skill, max_cd, ignore_cooldown_reduce)
    ---@ui 激活技能~1~的冷却，上限为~2~秒，无视缩减：~3~
    ---@belong skill
    ---@description 激活技能冷却
    ---@applicable action
    if skill_check(skill) then
        skill:active_cd(max_cd, ignore_cooldown_reduce)
    end
end
 ---@keyword 激活 冷却
function base.skill_active_custom_cd(skill, max_cd, cd)
    ---@ui 激活技能~1~的自定义冷却，上限为~2~秒，当前剩余~3~秒
    ---@belong skill
    ---@description 激活技能自定义冷却
    ---@applicable action
    if skill_check(skill) then
        skill:active_cd(max_cd, true)
        skill:set_cd(cd)
    end
end
 ---@keyword 激活 设置 冷却
function base.skill_add_level(skill, level)
    ---@ui 为技能~1~增加~2~个等级
    ---@belong skill
    ---@description 增加技能等级
    ---@applicable action
    if skill_check(skill) then
        skill:add_level(level)
    end
end
 ---@keyword 增加 等级
function base.skill_add_stack(skill, stack)
    ---@ui 技能~1~增加层数~2~
    ---@belong skill
    ---@description 增加技能层数
    ---@applicable action
    if skill_check(skill) then
        skill:add_stack(stack)
    end
end
 ---@keyword 增加 层数
--[[function base.skill_channel_finish(skill:skill)
    ---@ui 令技能~1~完成引导并进入下一阶段
    ---@belong skill
    ---@description 完成技能引导阶段
    ---@applicable action
    if skill_check(skill) then
        skill:channel_finish()
    end
end]]
--

function base.skill_get_attribute(skill, attr)
    ---@ui 技能~1~的~2~属性值
    ---@belong skill
    ---@description 技能的自定义属性值
    ---@applicable value
    if skill_check(skill) then
        return skill:get(attr)
    end
end
 ---@keyword 属性
function base.skill_set_attribute(skill, attr, val)
    ---@ui 设置技能~1~的~2~属性值为~3~
    ---@belong skill
    ---@description 设置技能的自定义属性
    ---@applicable action
    if skill_check(skill) then
        return skill:set_option(attr, val)
    end
end
 ---@keyword 属性
function base.skill_get_stage(skill)
    ---@ui 技能~1~的当前阶段
    ---@belong skill
    ---@description 技能的当前阶段
    ---@applicable value
    if skill_check(skill) then
        return skill:get_stage()
    end
end
 ---@keyword 阶段
function base.skill_stage_finish(skill)
    ---@ui 令技能~1~完成当前阶段
    ---@belong skill
    ---@description 完成技能当前阶段
    ---@applicable action
    if skill_check(skill) then
        skill:stage_finish()
    end
end
 ---@keyword 阶段 完成
--[[function base.skill_add_damage(skill:skill, source:unit, target:unit, damage:number) boolean
    ---@ui 技能~1~以~2~为来源、以单位~3~为目标造成~4~点伤害
    if skill ~= nil then
        return skill:add_damage{source = source, target = target, damage = damage}
    end
end]]
--

function base.skill_disable(skill)
    ---@ui 禁用技能~1~
    ---@belong skill
    ---@description 禁用技能
    ---@applicable action
    if skill_check(skill) then
        skill:disable()
    end
end
 ---@keyword 禁用
function base.skill_enable(skill)
    ---@ui 启用技能~1~
    ---@belong skill
    ---@description 启用技能
    ---@applicable action
    if skill_check(skill) then
        skill:enable()
    end
end
 ---@keyword 启用
function base.skill_enable_hidden(skill)
    ---@ui 隐藏技能~1~
    ---@belong skill
    ---@description 隐藏技能
    ---@applicable action
    if skill_check(skill) then
        return skill:set_option("sys_state_hidden", 1)
    end
end
 ---@keyword 隐藏
function base.skill_disable_hidden(skill)
    ---@ui 取消隐藏技能~1~
    ---@belong skill
    ---@description 取消隐藏技能
    ---@applicable action
    if skill_check(skill) then
        return skill:set_option("sys_state_hidden", 0)
    end
end
 ---@keyword 隐藏
-- TODO 多类型返回值
--[[function base.skill_get(skill:skill, key:string) unknown
    ---@ui 获取技能~1~的~2~数据
    if skill ~= nil then
        return skill:get(key)
    end
end]]
--

function base.skill_get_cd(skill)
    ---@ui 技能~1~的冷却时间（秒）
    ---@belong skill
    ---@description 技能的冷却时间
    ---@applicable value
    if skill_check(skill) then
        return skill:get_cd()
    end
end
 ---@keyword 冷却 时间
function base.skill_get_level(skill)
    ---@ui 技能~1~的等级
    ---@belong skill
    ---@description 技能的等级
    ---@applicable value
    if skill_check(skill) then
        return skill:get_level()
    end
end
 ---@keyword 等级
function base.skill_get_name(skill)
    ---@ui 技能~1~的Id
    ---@belong skill
    ---@description 技能的Id
    ---@applicable value
    if skill_check(skill) then
        return skill:get_name()
    end
end
 ---@keyword Id
function base.skill_get_slot_id(skill)
    ---@ui 技能~1~的槽位编号
    ---@belong skill
    ---@description 技能的槽位编号
    ---@applicable value
    if skill_check(skill) then
        return skill:get_slot_id()
    end
end
 ---@keyword 槽位
function base.skill_get_owner(skill)
    ---@ui 技能~1~的拥有者
    ---@belong skill
    ---@description 技能的拥有者
    ---@applicable value
    if skill_check(skill) then
        return skill.owner
    end
end
 ---@keyword 拥有者
--[[function base.skill_get_stack(skill:skill) stack
    ---@ui 获取技能~1~的层数
    if skill_check(skill) then
        return skill:get_stack()
    end
end]]
--

function base.skill_get_last_target_unit(skill)
    ---@ui 技能~1~上次施法的目标单位
    ---@belong skill
    ---@description 技能的上次施法的目标单位
    ---@applicable value
    if not(skill_check(skill)) then
        return nil
    end
    local target = skill:get_last_target_unit()
    return target
end
 ---@keyword 目标 单位
function base.skill_get_target_unit(skill)
    ---@ui 技能~1~的目标单位
    ---@belong skill
    ---@description 技能的目标单位
    ---@applicable value
    if not(skill_check(skill)) then
        return nil
    end
    local target = skill:get_target()
    if (skill_check(skill) and target and target.type == 'unit') then
        return target
    end
end
 ---@keyword 目标 单位
function base.skill_get_target_point(skill)
    ---@ui 技能~1~的目标点
    ---@belong skill
    ---@description 技能的目标点
    ---@applicable value
    if not(skill_check(skill)) then
        return nil
    end
    local target = skill:get_target()
    if (target and (target.type == 'unit' or target.type == 'point')) then
        local owner = skill.owner
        local scene = (owner and owner:get_scene_name())
        return target:get_point():copy_to_scene_point(scene)
    end
end
 ---@keyword 目标 点
function base.skill_get_target_angle(skill)
    ---@ui 技能~1~的目标角度
    ---@belong skill
    ---@description 技能的目标角度（向量技能）
    ---@applicable value
    if not(skill_check(skill)) then
        return 0
    end
    local target = skill:get_target()
    if (target and type(target) == 'number') then
        return target
    end

    return 0
end
 ---@keyword 目标 角度
function base.skill_get_type(skill)
    ---@ui 技能~1~的存在形式
    ---@belong skill
    ---@description 技能的存在形式
    ---@applicable value
    if skill_check(skill) then
        return skill:get_type()
    end
end
 ---@keyword 存在形式
--[[function base.skill_is(skill:skill, dest:skill) boolean
    ---@ui 技能~1~是否与~2~是同技能
    if skill ~= nil then
        return skill:is(dest)
    end
end]]
--

function base.skill_is_cast(skill)
    ---@ui 技能~1~是否为施法实例
    ---@belong skill
    ---@description 技能是否为施法实例
    ---@applicable value
    if skill_check(skill) then
        return skill:is_cast()
    end
end
 ---@keyword 施法 实例
function base.skill_is_enable(skill)
    ---@ui 技能~1~是否被启用
    ---@belong skill
    ---@description 技能是否被启用
    ---@applicable value
    if skill_check(skill) then
        return skill:is_enable()
    end
end
 ---@keyword 启用
function base.skill_is_skill(skill)
    ---@ui 技能~1~是否是非普攻技能
    ---@belong skill
    ---@description 技能是否是非普攻技能
    ---@applicable value
    if skill_check(skill) then
        return skill:is_skill()
    end
end
 ---@keyword 普攻
function base.skill_notify_damage(skill, damage)
    ---@ui 用技能~1~通知伤害~2~
    ---@belong skill
    ---@description 通知伤害
    ---@applicable action
    if skill_check(skill) then
        skill:notify_damage(damage)
    end
end
 ---@keyword 伤害
function base.skill_reload(skill)
    ---@ui 重新加载技能~1~的脚本
    ---@belong skill
    ---@description 重新加载技能脚本
    ---@applicable action
    if skill_check(skill) then
        skill:reload()
    end
end
 ---@keyword 加载 脚本
function base.skill_remove(skill)
    ---@ui 移除技能~1~
    ---@belong skill
    ---@description 移除技能
    ---@applicable action
    if skill_check(skill) then
        skill:remove()
    end
end
 ---@keyword 移除
function base.skill_set(skill, key, value)
    ---@ui 设置技能~1~的自定义数据~2~为~3~
    ---@belong skill
    ---@description 设置技能自定义数据
    ---@applicable action
    if skill_check(skill) then
        skill:set(key, value)
    end
end
 ---@keyword 设置 数据
function base.skill_set_animation(skill, animation)
    ---@ui 设置技能~1~的动画为~2~
    ---@belong skill
    ---@description 设置施法动画
    ---@applicable action
    if skill_check(skill) then
        skill:set_animation(animation)
    end
end
 ---@keyword 设置 动画
function base.skill_set_cd(skill, cd, force)
    ---@ui 设置技能~1~的当前剩余冷却为~2~秒（是否强制延长冷却：~3~）
    ---@belong skill
    ---@description 设置技能当前剩余冷却
    ---@applicable action
    ---@arg1 false
    if skill_check(skill) then
        if force then
            local current_cd = skill:get_cd()
            if cd > current_cd then
                base.skill_active_cd(skill, cd, true)
            else
                skill:set_cd(cd)
            end
        else
            skill:set_cd(cd)
        end
    end
end
 ---@keyword 设置 冷却
function base.skill_set_level(skill, level)
    ---@ui 设置技能~1~的等级为~2~
    ---@belong skill
    ---@description 设置技能等级
    ---@applicable action
    if skill_check(skill) then
        skill:set_level(level)
    end
end
 ---@keyword 设置 等级
function base.skill_set_option(skill, key, value)
    ---@ui 设置技能~1~的属性~2~为~3~
    ---@belong skill
    ---@description 设置技能属性
    ---@applicable action
    ---@selectable false
    if skill_check(skill) then
        skill:set_option(key, value)
    end
end
 ---@keyword 设置 属性
local function dummy()
    -- body
end

function base.skill_simple_cast(skill)
    ---@ui 施放技能~1~
    ---@belong skill
    ---@description 施放技能
    ---@applicable action
    ---@selectable false
    if skill_check(skill) then
        skill:simple_cast(dummy)
    end
end
 ---@keyword 施放
function base.skill_stop(skill)
    ---@ui 使技能~1~停止施法
    ---@belong skill
    ---@description 停止施法
    ---@applicable action
    if skill_check(skill) then
        skill:stop()
    end
end
 ---@keyword 停止
function base.unit_blink(unit, target)
    ---@ui 将~1~瞬移到点~2~
    ---@belong unit
    ---@description 瞬移单位
    ---@applicable action
    ---@name1 单位
    ---@name2 目标位置
    if (unit_check(unit) and point_check(target)) then
        if unit:get_scene_name() == target:get_scene() then
            return unit:blink(target, false)
        else
            log.info(string.format('单位[%s]无法瞬移到点[%s]', unit, target))
        end
    end
end
 ---@keyword 移动 瞬移
function base.unit_can_attack(unit, target)
    ---@ui ~1~能否攻击目标~2~
    ---@belong unit
    ---@description 单位能否攻击目标
    ---@applicable value
    ---@name1 单位
    ---@name2 目标单位
    if (unit_check(unit) and unit_check(target)) then
        return unit:can_attack(target)
    end
end
 ---@keyword 攻击
function base.same_skill(skill_a, skill_b)
    ---@ui ~1~和~2~是同一个技能的施法实例
    ---@belong skill
    ---@description 判断两个施法实例是否同源
    ---@applicable value
    ---@name1 技能A
    ---@name2 技能B
    if (skill_check(skill_a) and skill_check(skill_b)) then
        return skill_a:is(skill_b)
    end
    return false
end
 ---@keyword 施法
function base.unit_cast_smart(unit, id)
    ---@ui 命令~1~尝试智能施法技能~2~
    ---@belong unit
    ---@description 命令单位尝试智能施法一个技能
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    if (unit_check(unit)) then
        unit:cast_request(id)
    end
end
 ---@keyword 施放
function base.unit_cast(unit, id)
    ---@ui 命令~1~施放立即技能~2~
    ---@belong unit
    ---@description 命令单位施放立即技能
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    if (unit_check(unit)) then
        return unit:cast(id)
    end
end
 ---@keyword 施放
---@keyword 施法
function base.unit_cast_on_angel(unit, id, target)
    ---@ui 命令~1~施放向量技能~2~，朝向为~3~度
    ---@belong unit
    ---@description 命令单位施放向量技能
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    if (unit_check(unit)) then
        return unit:cast(id, target)
    end
end

function base.unit_cast_on_unit(unit, id, target)
    ---@ui 命令~1~对~3~施放技能~2~
    ---@belong unit
    ---@description 命令单位对单位施放技能
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    ---@name3 目标单位
    if (unit_check(unit) and unit_check(target)) then
        return unit:cast(id, target)
    end
end
 ---@keyword 施放
function base.unit_cast_on_point(unit, id, point)
    ---@ui 命令~1~对点~3~施放技能~2~
    ---@belong unit
    ---@description 命令单位对点施放技能
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    ---@name3 目标点
    if (unit_check(unit) and point_check(point)) then
        if unit:get_scene_name() == point:get_scene() then
            return unit:cast(id, point)
        else
            log.info(string.format('单位[%s]无法对点[%s]释放技能', unit, point))
        end
    end
end

 ---@keyword 施放
function base.unit_cast_skill(unit, id)
    ---@ui 命令~1~施放立即技能~2~
    ---@belong unit
    ---@description 命令单位施放立即技能（指定技能）
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    if (unit_check(unit)) then
        return unit:cast(id)
    end
end
 ---@keyword 施放
function base.unit_cast_skill_on_unit(unit, id, target)
    ---@ui 命令~1~对~3~施放技能~2~
    ---@belong unit
    ---@description 命令单位对单位施放技能（指定技能）
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    ---@name3 目标单位
    if (unit_check(unit) and unit_check(target)) then
        return unit:cast(id, target)
    end
end
 ---@keyword 施放
function base.unit_cast_skill_on_point(unit, id, point)
    ---@ui 命令~1~对点~3~施放技能~2~
    ---@belong unit
    ---@description 命令单位对点施放技能（指定技能）
    ---@applicable action
    ---@name1 单位
    ---@name2 技能Id
    ---@name3 目标点
    if (unit_check(unit) and point_check(point)) then
        if unit:get_scene_name() == point:get_scene() then
            return unit:cast(id, point)
        else
            log.info(string.format('单位[%s]无法对点[%s]释放技能', unit, point))
        end
    end
end

 ---@keyword 施放
function base.unit_clean_command(unit)
    ---@ui ~1~清空命令队列
    ---@belong unit
    ---@description 清空单位命令队列
    ---@applicable action
    ---@name1 单位
    if unit_check(unit) then
        unit:clean_command()
    end
end
 ---@keyword 清空 命令
function base.unit_current_skill(unit)
    ---@ui ~1~正在施放的技能实例
    ---@belong unit
    ---@description 单位正在施放的技能
    ---@applicable value
    ---@name1 单位
    if unit_check(unit) then
        return unit:current_skill()
    end
end
 ---@keyword 获取
function base.unit_each_skill(unit, skill_type)
    ---@ui ~1~身上所有存在形式为~2~的技能
    ---@belong unit
    ---@description 单位身上所有指定存在形式的技能数组
    ---@applicable value
    ---@name1 单位
    ---@name2 技能存在形式
    local result = {}
    if unit_check(unit) then
        for skill in unit:each_skill(skill_type) do
            table.insert(result, skill)
        end
    end
    return result
end
 ---@keyword 获取 存在形式
function base.unit_find_skill_by_name(unit, id, include_level_zero)
    ---@ui ~1~的一个~2~技能（包含等级为0的技能：~3~）
    ---@belong unit
    ---@description 单位身上一个指定Id的技能
    ---@applicable value
    ---@name1 单位
    ---@name2 技能Id
    ---@name3 是否
    ---@arg1 false
    ---@arg2 e.unit
    if unit_check(unit) then
        return unit:find_skill(id, include_level_zero)
    end
end
 ---@keyword 获取 Id
function base.get_all_skills_id()
    ---@ui 获取所有技能ID
    ---@belong skill
    ---@description 获取所有技能ID
    ---@applicable value
    local result = {}
    for id, _ in pairs(base.table.skill) do
        table.insert(result, id)
    end
    return result
end