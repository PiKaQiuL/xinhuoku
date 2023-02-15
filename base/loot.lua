local base = base
local log = log
local eff = base.eff

local failed_code = {
    Not_enough = 1,
    Fail_validate = 2,
    Inventory_full = 3,
    Max_hold = 4,
    Max_times = 5,
}
-- 检查最大购买次数
local function check_loot_times(ref_param)
    local killer = ref_param:main_target()
    local cache = ref_param.cache

    local maxtimes = cache.MaxTimes and cache.MaxTimes(ref_param) or -1
    local player = killer:get_owner()
    if maxtimes > 0 then
        local already_times = player.__loot_times and player.__loot_times[cache.Link] or 0
        if already_times >= maxtimes then
            return false
        end
    end
    return true
end

-- 记录购买次数
local function add_loot_times(ref_param)
    local killer = ref_param:main_target()
    local cache = ref_param.cache
    local player = killer:get_owner()

    if not (player.__loot_times and player.__loot_times[cache.Link])then
        player.__loot_times = player.__loot_times or {}
        player.__loot_times[cache.Link] = 1
    else
        player.__loot_times[cache.Link] = player.__loot_times[cache.Link] + 1
    end
end

-- 检查花费
local function check_cost(ref_param)
    local cache = ref_param.cache

    local killer = ref_param:main_target()
    if not killer then
        return
    end

    -- 对比玩家属性
    local player = killer:get_owner()
    local player_attr_need = cache.PlayerAttributeCost
    if player_attr_need then
        for k,v in pairs(player_attr_need) do
            local need = v(ref_param)
            if need ~= 0 then
                local num = player:get(k)
                if type(num) ~= 'number' or num < need then
                    return false
                end
            end
        end
    end


    -- 对比所需物品
    local item_cost = cache.ItemCost
    if item_cost and #item_cost > 0 then
        local items = killer:all_items()
        for _,data in pairs(item_cost) do
            local link = data.Item
            local need_count = data.Count(ref_param)
            if need_count > 0 then
                local count = 0
                for _,item in pairs(items) do
                    if item.link == link then
                        count = count + (item.stack and item.stack or 1)
                    end
                end
                if count < need_count then
                    return false
                end
            end
        end
    end

    return true
end

-- 花费资源
local function cost_resources(ref_param)
    local cache = ref_param.cache

    local killer = ref_param:main_target()
    if not killer then
        return
    end

    -- 消耗玩家属性
    local player = killer:get_owner()
    local player_attr_need = cache.PlayerAttributeCost
    if player_attr_need then
        for k,v in pairs(player_attr_need) do
            local need = v(ref_param)
            if need ~= 0 then
                player:add(k,-need)
            end
        end
    end


    -- 对比所需物品
    local item_cost = cache.ItemCost
    if item_cost and #item_cost > 0 then
        local items = killer:all_items()
        for _,data in pairs(item_cost) do
            local link = data.Item
            local need_count = data.Count(ref_param)
            if need_count > 0 then
                for _,item in pairs(items) do
                    if need_count <= 0 then
                        break
                    end
                    if item.link == link then
                        local stack = item.stack and item.stack or 1
                        if stack <= need_count then
                            item:remove()
                            need_count = need_count - stack
                        else
                            item:set_stack(item.stack - need_count)
                            need_count = 0
                        end
                    end
                end
            end
        end
    end
end


eff.LootSet = {}

---comment
---@param ref_param EffectParam
function eff.LootSet.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end
    
    -- 验证结束 开始执行
    for _, effect in ipairs(cache.Set) do
        ref_param:execute_child_on(effect) 
    end
end


eff.LootSingle = {}

---comment
---@param ref_param EffectParam
---@return table, integer
function eff.LootSingle.create_table(ref_param)
    local cache = ref_param.cache

    local table_effect = cache.Set
    local table_weight = cache.Weights
    local result = {}
    local total_weight = 0
    for index, effect in ipairs(table_effect) do
        local item = {effect = effect, weight = 1}
        local child_cache = eff.cache(effect)
        if child_cache and child_cache.Weight then
            item.weight = child_cache.Weight
        end
        table.insert(result,item)
        total_weight =  total_weight + item.weight
    end
    return result, total_weight
end

---comment
---@param effects table
---@param total_weight number
---@return string
function eff.LootSingle.pick_from_table(effects, total_weight)
    local index = 1
    if total_weight > 0 then
        local start = 0
        local rnd = math.random() * total_weight
        for i, value in ipairs(effects) do
            start = start + value.weight
            if start >= rnd then
                index = i
                break
            end
        end
    end
    local effect = effects[index].effect
    return effect
end

---comment
---@param ref_param EffectParam
function eff.LootSingle.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end
    
    -- 验证结束 开始执行
    local effects, total_weight = eff.LootSingle.create_table(ref_param)
    local child_link = eff.LootSingle.pick_from_table(effects, total_weight)
    ref_param:execute_child_on(child_link) 
end


eff.LootItem = {}

---comment
---@param ref_param EffectParam
function eff.LootItem.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end
    
    -- 验证结束 开始执行
    local victim = ref_param:caster()
    if not victim then
        return
    end
    local count = 1
    if cache.Amount then
        count = cache.Amount(ref_param)
    end

    local item_cache = eff.cache(cache.ItemType)
    if not item_cache then
        return
    end

    local scene = killer:get_scene_name() or ref_param:get_scene()

    local max_stack = item_cache.StackMax

    if count then
        for _ = 1, count, 1 do
            local rnd_offset = base.point(math.random() * 200 - 100, math.random() * 200 - 100)
            local item = base.item.create_to_point(cache.ItemType, victim:get_point() + rnd_offset, scene)
            if cache.Stack and max_stack > 0 then
                local stack = cache.Stack(ref_param)
                if stack and stack >= 0 then
                    stack = math.min(stack, max_stack)
                    item:set_stack(stack)
                end
            end
            local give_source = cache.GiveSource
            if give_source then
                item:move(killer:get_point())
                item:pick_by(killer)
            end
        end
    end

    add_loot_times(ref_param)

    killer:event_notify('奖励-成功',killer,ref_param)
end


eff.LootUnit = {}
---comment
---@param ref_param EffectParam
function eff.LootUnit.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end

    -- 验证结束 开始执行
    local victim = ref_param:caster()
    if not victim then
        return
    end
    local player = killer:get_owner()
    if not player then
        return
    end

    local scene = killer:get_scene_name() or ref_param:get_scene()

    local count = 1
    if cache.Amount then
        count = cache.Amount(ref_param)
    end

    local name = cache.UnitType
    if name and name ~= '' then
        if count then
            for _ = 1, count, 1 do
                local rnd_offset = base.point(math.random() * 200 - 100, math.random() * 200 - 100)
                player:create_unit(name, victim:get_point() + rnd_offset, victim:get_facing(), nil, scene)
            end
        end
    end

    killer:event_notify('奖励-成功',killer,ref_param)
end


eff.LootEffect = {}

---comment
---@param ref_param EffectParam
function eff.LootEffect.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end

    -- 验证结束 开始执行
    ref_param:execute_child_on(cache.Effect)
    
    killer:event_notify('奖励-成功',killer,ref_param)
end

eff.LootBuff = {}

---comment
---@param ref_param EffectParam
function eff.LootBuff.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end

    -- 验证结束 开始执行
    local buff = cache.BuffType
    local count = cache.Count(ref_param)

    if buff and buff ~= '' then
        for i = 1,count do
            killer:add_buff_new(buff)
        end
    end
    
    killer:event_notify('奖励-成功',killer,ref_param)
end

eff.LootSpell = {}

---comment
---@param ref_param EffectParam
function eff.LootSpell.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end

    -- 验证结束 开始执行
    local SpellType = cache.SpellType
    local count = cache.Count(ref_param)
    local add_level = cache.SameAddLevel

    if SpellType and SpellType ~= '' then
        for i = 1,count do
            if add_level then
                local skill = killer:find_skill(SpellType)
                if not skill then
                    killer:add_skill(SpellType,'英雄')
                else
                    local current_skill = killer:current_skill()
                    if current_skill and (current_skill:get_skill() == skill:get_skill()) then
                        -- 不然会提示 不能在技能的施法事件中改变技能等级
                        base.wait(35, function()
                            skill:add_level(1)
                        end)
                    else
                        skill:add_level(1)
                    end
                end
            else
                killer:add_skill(SpellType,'英雄')
            end
        end
    end

    killer:event_notify('奖励-成功',killer,ref_param)
end


eff.LootNone = {}

---comment
---@param ref_param EffectParam
function eff.LootNone.execute(ref_param)
    local killer = ref_param:main_target()
    if not killer then
        return
    end
    local cache = ref_param.cache
    -- 开始验证
    if not check_loot_times(ref_param) then
        base.game:event_notify('奖励-失败',killer,failed_code.Max_times,ref_param)
        return
    end
    local result = eff.execute_validators(cache.Validators, ref_param)
    if result ~= eff.e_cmd.OK then
        base.game:event_notify('奖励-失败',killer,failed_code.Fail_validate,ref_param)
        return
    end
    if check_cost(ref_param) then
        cost_resources(ref_param)
    else
        base.game:event_notify('奖励-失败',killer,failed_code.Not_enough,ref_param)
        return 
    end
    
    -- 验证结束 开始执行
    
    killer:event_notify('奖励-成功',killer,ref_param)
end