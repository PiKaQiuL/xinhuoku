base.game.unit = setmetatable({}, {
    __index = function (self, name)
        rawset(self, name, {})
        return self[name]
    end,
})

base.game.unit_map = { __mode = 'v' }

local unit_bind = setmetatable({}, { __mode = 'kv' })


local function set_bind(unit)
    local name = unit:get_name()
    unit_bind[unit] = base.game.unit[name]
end

local unit_response_location = base.response.e_location.Attacker
---comment
---@param unit Unit
---@param event_name string
---@param ... unknown
---@return unknown
local function call_event(unit, event_name, ...)
    local bind = unit_bind[unit]
    if bind and bind[event_name] then
        return bind[event_name](unit, ...)
    end
    if unit and unit.ref_param then
        unit:on_response('ResponseUnit', unit_response_location, unit.ref_param, event_name)
    end
    return nil
end

base.game:event('单位-初始化', function (_, unit)
    set_bind(unit)
    unit:create_restrictions()
    call_event(unit, 'on_init')
end)

local eff = base.eff

---comment
---@param _ any
---@param unit Unit
base.game:event('单位-创建', function (_, unit)
    base.game.unit_map[unit:get_id()] = unit
    call_event(unit, 'on_create')
    unit:create_inventorys()
    unit:create_responses()
    -- unit:create_ai()
    unit:create_actors()
end)

base.game:event('弹道-创建', function (_, unit)
    base.game.unit_map[unit:get_id()] = unit
    unit:create_responses()
    unit:create_actors()
end)


--[[ base.game:event('单位-即将死亡', function (_, damage)
    return call_event(damage.target, 'on_dying', damage)
end) ]]

base.game:event('单位-死亡', function (_, unit, killer)
    call_event(unit, 'on_dead', killer)
end)

---comment
---@param _ any
---@param unit any
base.game:event('单位-移除', function (_, unit)
    call_event(unit, 'on_removed')
    unit.removed = true
    unit._scaling_labels = nil
    unit:destroy_actors(true)
    unit:destroy_responses(true)
    unit:destroy_inventorys(true)
    unit:remove_item()

    base.game:ui'__update_collision_info'{
        point = unit:get_point(),
        link = unit:get_name(),
        isRemove = true,
    }
end)

---comment
---@param _ any
---@param unit any
base.game:event('弹道-移除', function (_, unit)
    unit.removed = true
    unit:destroy_actors(true)
    unit:destroy_responses(true)
end)

base.game:event('单位-复活', function (_, unit)
    call_event(unit, 'on_reborn')
end)

base.game:event('单位-升级', function (_, unit)
    call_event(unit, 'on_upgrade')
end)

base.game:event('单位-即将获得状态', function (_, unit, buff)
    return call_event(unit, 'on_buff_adding', buff)
end)

base.game:event('运动-即将获得', function (_, unit, mover)
    return call_event(unit, 'on_mover_adding', mover)
end)

base.game:event('运动-即将击中', function (_, unit, mover)
    return call_event(unit, 'on_mover_hitting', mover)
end)

--[[
    临时方案
    服务器目前没有某种类型单位的事件，如果只注册类型单位事件，服务器不会抛出对应的事件。
    临时解决方法是把所有单位事件注册一个空的全局触发器
]]
local unit_event = {
    '单位-初始化',
    '单位-创建',
    '单位-复活',
    '单位-升级',
    '单位-死亡',
    '单位-移除',
    '单位-获得状态',
    '单位-失去状态',
    '单位-购买物品',
    '单位-出售物品',
    '单位-撤销物品',
    '单位-获得物品',
    '单位-失去物品',
    '单位-丢弃物品',
    '单位-发布命令',
    '单位-执行命令',
    '单位-移动',
    '移动-开始',
    '移动-结束',
    '单位-攻击开始',
    '单位-攻击出手',
    '受到伤害',
    '造成伤害',
    --['单位-着陆'] = 'event_unit_landed', 这个是3D版本的，没做完，现在先不管了吧。
    '单位-学习技能完成',
    '单位-获得经验',
    '单位-切换场景',
    '单位-装备物品',
    '单位-取消装备',
    '单位-获得奖励',
}

local unit_global_trigger = base.trig:new(function() end, true)
for _, v in ipairs(unit_event) do
    unit_global_trigger:add_event(base.game, v)
end


local ac_event_notify = base.event_notify

base.game:event('技能-施法接近', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-施法接近', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-施法接近', unit, cast)
    end
end)


base.game:event('技能-施法开始', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-施法开始', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-施法开始', unit, cast)
    end
end)

base.game:event('技能-施法引导', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-施法引导', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-施法引导', unit, cast)
    end
end)

base.game:event('技能-施法出手', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-施法出手', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-施法出手', unit, cast)
    end
end)

base.game:event('技能-施法完成', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-施法完成', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-施法完成', unit, cast)
    end
end)

base.game:event('技能-施法停止', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-施法停止', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-施法停止', unit, cast)
    end
end)


base.game:event('技能-冷却完成', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-冷却完成', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-冷却完成', unit, cast)
    end
end)

base.game:event('技能-获得', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-获得', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-获得', unit, cast)
    end
end)

base.game:event('技能-失去', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-失去', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-失去', unit, cast)
    end
end)

base.game:event('技能-施法打断', function (_, unit, cast)
    if not cast then
        return
    end
    local cache = cast.cache or base.eff.cache(cast.__name)
    if cache then
        ac_event_notify(cache, '技能-施法打断', unit, cast)
    else
        print('获取不到技能的cache')
    end
    local skill = cast:get_skill()
    if skill then
        ac_event_notify(skill, '技能-施法打断', unit, cast)
    end
end)