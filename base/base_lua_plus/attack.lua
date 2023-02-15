--[[function base.attack_active_cd(attack:attack, max_cd:number)
    ---@ui 普攻~1~激活上限为~2~的冷却
    ---@description 激活普攻冷却
    ---@applicable action
    ---@belong skill
    if attack ~= nil then
        attack:active_cd(max_cd)
    end
end

function base.attack_add_damage(attack:attack, source:unit, target:unit, damage:number) boolean
    ---@ui 普攻~1~以~2~为来源、以单位~3~为目标造成~4~点伤害
    ---@description 激活普攻冷却
    ---@applicable action
    ---@belong skill
    if attack ~= nil then
        return attack:add_damage{source = source, target = target, damage = damage}
    end
end

function base.attack_get_cd(attack:attack) number
    ---@ui 获取attack~1~的冷却
    ---@description 获取普攻冷却
    ---@applicable action
    ---@belong skill
    if attack ~= nil then
        return attack:get_cd()
    end
end

function base.attack_get_name(attack:attack) name
    ---@ui 获取普攻~1~的名称
    ---@description 获取普攻技能Id
    ---@applicable action
    ---@belong skill
    if attack ~= nil then
        return attack:get_name()
    end
end

function base.attack_is_common_attack(attack:attack) boolean
    ---@ui 普攻~1~是否是普通攻击
    ---@description 攻击技能是否为普通攻击
    ---@applicable action
    ---@belong skill
    if attack ~= nil then
        return attack:is_common_attack()
    end
end

function base.attack_is_skill(attack:attack) boolean
    ---@ui 普攻~1~是否是技能
    if attack ~= nil then
        return attack:is_skill()
    end
end

function base.attack_set_cd(attack:attack, cd:number)
    ---@ui 设置普攻~1~的冷却为~2~
    if attack ~= nil then
        attack:set_cd(cd)
    end
end

function base.attack_stop(attack:attack)
    ---@ui 打断普攻~1~
    if attack ~= nil then
        attack:set_stop()
    end
end]]
--