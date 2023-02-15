--- lua_plus ---
--[[function base.damage_get_angle(damage:damage) number
    ---@ui 获取伤害~1~的角度
    if damage ~= nil then
        return damage:get_angle()
    end
end]]
--

function base.damage_get_damage(damage:damage)number
    ---@ui ~1~的原始伤害值
    ---@belong unit
    ---@description 伤害实例的原始伤害值
    ---@applicable value
    ---@name1 伤害
    if damage ~= nil then
        return damage:get_damage()
    end
end
 ---@keyword 伤害
function base.damage_get_current_damage(damage:damage)number
    ---@ui ~1~的当前伤害值
    ---@belong unit
    ---@description 伤害实例的当前伤害值
    ---@applicable value
    ---@name1 伤害
    if damage ~= nil then
        return damage:get_current_damage()
    end
end
 ---@keyword 伤害
function base.damage_set_current_damage(damage:damage, amount:number)
    ---@ui 设置~1~的当前伤害值为~2~
    ---@belong unit
    ---@description 修改伤害实例的当前伤害值
    ---@applicable action
    ---@name1 伤害
    if damage ~= nil then
        return damage:set_current_damage(amount)
    end
end
 ---@keyword 伤害
function base.do_trigger_damage(source:unit, target:unit, amount:number, damage_type:伤害类型)
    ---@ui 令~1~对~2~造成~3~点伤害，类型为~4~
    ---@belong unit
    ---@description 令单位对单位造成伤害
    ---@applicable action
    ---@name1 伤害来源
    ---@name2 承受单位
    ---@name3 数值
    ---@name4 伤害类型
    ---@arg1 伤害类型["物理"]
    if and(unit_check(source), unit_check(target)) then
        source:do_trigger_damage(target, amount, damage_type)
    end
end ---@keyword 伤害