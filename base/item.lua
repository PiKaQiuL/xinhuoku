local base = base
local eff = base.eff

Item = Item or base.tsc.__TS__Class()
Item.name = 'Item'

base.item = Item.prototype

base.item.type = 'item'

---@class Item
---@field link string
---@field slot Slot
---@field last_active_equip_state boolean --nil = 之前没有被携带，false = 之前被放在背包里， true = 之前被装备了
---@field last_active_carrier Unit
---@field cache table
---@field active_skill Skill
---@field active_mods Buff[]
---@field unit_hidden boolean
---@field unit Unit --物品在地上时对应的单位，不是物品的持有者
---@field stack number --层数
---@field removed boolean --物品是否已经被移除
---@field powerup_carrier Unit --ItemPowerUp的所有者单位
local item  = base.item

local e_base_data = {
    link = 'sys_item_link',
    mods = 'sys_item_mods',
    rnds = 'sys_item_rnds',
    stack = 'sys_item_stack',
    quality = 'sys_item_quality',
    unpowered = 'sys_item_unpowered',
    locked = 'sys_item_locked',
}
item.type = 'item'
---comment
---@param prop_name string
---@param value number
---@param force boolean?
function item:sync_base_data(prop_name, value, force)
    local unit = self.unit
    if unit and (force or unit:get(prop_name) ~= value) then
        unit:set_attribute_sync(prop_name, 'self|sight')
        unit:set(prop_name, value)
    end
end

local e_slot_data  = {
    owner_id = 'sys_item_owner_id',
    active_skill_id = 'sys_item_active_skill_id',
    inv_index = 'sys_item_inv_index',
    slot_index = 'sys_item_slot_index',
}

---在以下情况下发送事件：客户端所属的主控单位的物品发生变化：品质变化、层数变化、获得、丢失、在物品栏间移动、在物品栏内部移动
---如果单位不是主控单位，此事件不会发送。
---@param hero Unit
function item:event_player_hero_item_change(hero)
    local item_unit = self.unit
    if not item_unit then
        return
    end
    if not hero then
        hero = item:carrier()
    end
    if not hero then
        return
    end
    local player  = hero:get_owner()
    if player:get_hero() ~= hero then
        return
    end
    base.wait(33, function ()
        player:ui 'sys_hero_inv_item_change' {
            item_id = item_unit:get_id(),
        }
    end)
end

---comment
---@param locked boolean
function item:lock(locked)
    if locked then
        self:sync_base_data(e_base_data.locked, 0)
    else
        self:sync_base_data(e_base_data.locked, 1)
    end
end

---目前可以假定物品栏不会变化，不会增加或者减少。但之后可以支持动态添加物品栏

function item:sync_slot_data()
    local unit = self.unit
    if not unit then
        return
    end

    local carrier = self:carrier()
    local owner_id, active_skill_id, inv_index, slot_index
    if carrier then
        owner_id = carrier:get_id()
        if self.active_skill then
            active_skill_id = self.active_skill:get_id()
        else
            active_skill_id = 0
        end
        slot_index = self.slot and self.slot.index
        inv_index = self.slot and self.slot.inventory.index
    else
        owner_id = 0
        active_skill_id = 0
        slot_index = 0
        inv_index = 0
    end

    local old_owner_id = unit:get(e_slot_data.owner_id)
    local old_active_skill_id = unit:get(e_slot_data.active_skill_id)
    local old_inv_index = unit:get(e_slot_data.inv_index)
    local old_slot_index = unit:get(e_slot_data.slot_index)

    local function set(prop_name, value, old_value)
        if value ~= old_value then
            unit:set_attribute_sync(prop_name, 'self|sight')
            unit:set(prop_name, value)
            return true
        end
        return false
    end

    local owner_change = owner_id ~= old_owner_id

    if owner_change then
        if carrier then
            if self.cache and self.cache.NodeType ~= 'ItemPowerUp' then
                carrier.inv_item_ids = carrier.inv_item_ids or {}
                table.insert(carrier.inv_item_ids, unit:get_id())
                carrier:sync_inv_items()
            end
            local player = carrier:get_owner()
            if unit:get_owner() ~= player then
                unit:set_owner(player)
            end
            carrier:event_notify('单位-获得物品', carrier, self)
        end
        ---@type Unit
        local old_carrier = base.unit(old_owner_id)
        local item_id = unit:get_id()
        if old_carrier and old_carrier.inv_item_ids then
            if self.cache and self.cache.NodeType ~= 'ItemPowerUp' then
                for index, value in ipairs(old_carrier.inv_item_ids) do
                    if value == item_id then
                        table.remove(old_carrier.inv_item_ids, index)
                        break
                    end
                end
            end
            old_carrier:sync_inv_items()
            old_carrier:event_notify('单位-失去物品', old_carrier, self)
        end
    end

    set(e_slot_data.owner_id, owner_id, old_owner_id)
    set(e_slot_data.active_skill_id, active_skill_id, old_active_skill_id)
    set(e_slot_data.inv_index, inv_index, old_inv_index)
    set(e_slot_data.slot_index, slot_index, old_slot_index)
--[[     if any_change and carrier then
        self:event_player_hero_item_change(carrier)
    end ]]
end

function item:debuginfo()
    return ('{item|%s}'):format(self.link)
end

function item:init_pick_region()
    if self.pick_region then
        self.pick_region:remove()
    end
    if self.removed then
        return
    end
    local unit = self.unit
    if not unit or unit.removed then
        return
    end
    local item = self
    if self.cache.NodeType == 'ItemPowerUp' and self.cache.AutoPickUp then
        local range = self.cache.PickUpRadius
        local filter = self.cache.Filter
        local region = base.region.circle {point = self.unit:get_point(), radius = range}
        self.pick_region = region
        local target_filter = filter and base.target_filters:new(filter)
        function region:on_enter(pick_unit)
            if unit.removed or item:carrier() then
                return
            end
            if unit:get_scene_name() == pick_unit:get_scene_name() then
                if not target_filter or target_filter:validate(unit, pick_unit) == eff.e_cmd.OK then
                    local result, _, slot, _ = pick_unit:can_hold(item)
                    if result then
                        item:pick_by(pick_unit)
                    end
                end
            end
        end
    end
end

function item:remove_pick_region()
    if self.pick_region then
        self.pick_region:remove()
    end
end

---comment
---@param unit Unit
---@return Item
function item:new(link, unit, no_init_event)
    local cache = eff.cache(link)
    local stack = nil
    if cache.StackMax ~= 0 then
        stack = cache.StackStart
        if cache.StackMax and cache.StackMax < stack then
            stack = cache.StackMax
        end
    end
    local new_item={ unit = unit, link = link, cache = cache, active_mods = {}, stack = stack }
    setmetatable(new_item, self.__index)
    if unit then
        unit.item = new_item
        new_item:sync_base_data(e_base_data.link, link)
        if stack then
            new_item:sync_base_data(e_base_data.stack, stack)
        end
        new_item:init_pick_region()
    end
    if not no_init_event then
        base.game:event_notify('物品-创建', new_item)
    end
    return new_item
end

---comment
---@param link string
---@param point Point
---@return Item
function item.create_to_point(link, point, scene, no_init_event)
    local cache = eff.cache(link)
    if not cache then
        return nil
    end
    local unit_link = cache.Unit
    if not unit_link or #unit_link == 0 then
        log.error('该物品没有对应的单位，请核对数据编辑器里指定物品是否有连接对应的单位')
        return nil
    end
    local unit = base.player(0):create_unit(unit_link, point, 0, nil, scene)
    if not unit then
        log.error('创建物品对应的单位失败')
        return nil
    end
    return item:new(link, unit, no_init_event)
end

function item.create_to_unit(link, unit, no_init_event)
    if not unit then
        return
    end
    local new_item = item.create_to_point(link, unit:get_point(), unit:get_scene_name(), no_init_event)
    new_item:add_to(unit)
    return new_item
end

---comment
---@param stack number
function item:set_stack(stack)
    self.stack = stack
    self:sync_base_data(e_base_data.stack, stack)
    -- self:event_player_hero_item_change()
end

---comment
---@param quality number
function item:set_quality(quality)
    self:sync_base_data(e_base_data.quality, quality)
    -- self:event_player_hero_item_change()
end

---comment
---@param label string
function item:has_label(label)
    if self.removed then
        return false
    end

    local cache = self.cache
    if not cache or not cache.Classes then
        return false
    end
    for _, value in ipairs(cache.Classes) do
        if value == label then
            return true
        end
    end
    return false
end

---comment
---@return Unit
function item:carrier()
    if self.removed then
        return nil
    end

    if self.cache.NodeType == 'ItemPowerUp' then
        return self.powerup_carrier
    end

    if not self.slot or not self.slot.inventory then
        return nil
    end
    return self.slot.inventory.carrier
end

function item:update_modification(is_pick,drop_equip_carrier)
    if self.removed then
        return
    end
    ---@type Unit
    local carrier = self:carrier()
    if not carrier then
        if self.active_mods then
            for _, mod in ipairs(self.active_mods) do
                mod:remove()
            end
        end
        if self.active_skill then
            self.active_skill:remove()
            self.active_skill = nil
        end
        self.last_active_carrier = nil
        self.last_active_equip_state = nil
        if drop_equip_carrier then
            drop_equip_carrier:event_notify('单位-取消装备', drop_equip_carrier, self)
        end
        return
    end
    local cache = self.cache
    if not cache then
        return
    end
    local slot_cache = self.slot and self.slot.cache
    if not slot_cache then
        return
    end
    local equip_state = slot_cache.Equip
    --如果物品由同一个人携带，而且物品栏状态不变，无需修改
    if self.last_active_equip_state == equip_state and self.last_active_carrier == carrier then
        return
    end

    local mod_cache
    if equip_state then
        mod_cache = cache.EquipMod
    else
        mod_cache = cache.CarryMod
    end

    local powered  = self.slot:met_requirement(self)

    local apply = powered and mod_cache

    ---先加buff，再删除buff和技能，再添加技能，顺序不能错
    local new_active_mods = {}
    if apply then
        if mod_cache.Buffs then
            for stack_index, buff_link in ipairs(mod_cache.Buffs) do
                local buff = carrier:add_buff_new(buff_link, 1, self, {rnd_index = stack_index})
                if buff then
                    buff.source_item = self
                    table.insert(new_active_mods,buff)
                end
            end
        end
        if self.extra_mod and self.extra_mod[equip_state] then
            for stack_index, buff_link in ipairs(self.extra_mod[equip_state]) do
                local buff = carrier:add_buff_new(buff_link, 1, self, {rnd_index = stack_index})
                if buff then
                    buff.source_item = self
                    table.insert(new_active_mods,buff) 
                end
            end
        end
    end

    for _, mod in ipairs(self.active_mods) do
        mod:remove()
    end

    if self.active_skill then
        self.active_skill:remove()
        self.active_skill = nil
    end

    if apply then
        self.active_skill = nil
        if mod_cache.Skill and mod_cache.Skill ~= '' then
            local skill = carrier:add_skill(mod_cache.Skill, '物品')
            if skill then
                skill.source_item = self
                self.active_skill = skill
            end
        end

        --更新特征数据，用于下一次更新时的比对
        self.last_active_carrier = carrier
        self.last_active_equip_state = equip_state
    else
        self.last_active_carrier = nil
        self.last_active_equip_state = nil
    end
    self.active_mods = new_active_mods

    if powered then
        self:sync_base_data(e_base_data.unpowered, 0)
    else
        self:sync_base_data(e_base_data.unpowered, 1)
    end

    if equip_state then
        carrier:event_notify('单位-装备物品', carrier, self)
    else
        if not is_pick then
            carrier:event_notify('单位-取消装备', carrier, self)
        end
    end
end

---comment
---@param buff_link string
---@param is_equip boolean
function item:add_extra_mod(buff_link,is_equip)
    is_equip = is_equip or false
    self.extra_mod = self.extra_mod or {}
    self.extra_mod[is_equip] = self.extra_mod[is_equip] or {}
    table.insert(self.extra_mod[is_equip], buff_link)
    self:sync_base_data(e_base_data.mods, self.extra_mod, true)
end

---comment
---@param buff_link string
function item:remove_extra_mod(buff_link,is_equip)
    is_equip = is_equip or false
    if not self.extra_mod or not self.extra_mod[is_equip] then
        return
    end
    for index, value in ipairs(self.extra_mod[is_equip]) do
        if value == buff_link then
            table.remove(self.extra_mod[is_equip],index)
            return
        end
    end
    self:sync_base_data(e_base_data.mods, self.extra_mod, true)
end

function item:generate_rand_mod()
    local unit = self.unit
    if not unit then
        return
    end

    local rnds = unit:get(e_base_data.rnds)

    if not rnds or rnds == 0 then
        rnds = {}
    end

    local cache = self.cache
    if not cache then
        return
    end

    local ref_param = unit:get_creation_param()

    if not ref_param then
        return
    end

    local changed = false

    ---comment
    ---@param buffs string[]
    local function gen(buffs)
        if not buffs then
            return
        end

        for stack_index, buff_link in ipairs(buffs) do
            local buff_cache = base.eff.cache(buff_link)
            if buff_cache and buff_cache.KeyValuePairs then
                for _, pair in ipairs(buff_cache.KeyValuePairs) do
                    if pair.Random and pair.Random ~= 0 then
                        local base_value = pair.Value(ref_param)
                        local indexed_link = buff_link..'@'..stack_index
                        if not rnds[indexed_link] then
                            rnds[indexed_link] = {}
                        end
                        if not rnds[indexed_link][pair.Key] then
                            local new_value = base.math.random_smart(base_value, base_value + pair.Random)
                            rnds[indexed_link][pair.Key] = new_value
                            changed = true
                        end
                    end
                end
            end
        end
    end

    gen(cache.EquipMod.Buffs)
    gen(cache.CarryMod.Buffs)
    if self.extra_mod then
        gen(self.extra_mod[true])
        gen(self.extra_mod[false])
    end
    if changed then
        self:sync_base_data(e_base_data.rnds, rnds)
    end
end

---comment
---@param buff_link string
---@param prop_name string
---@param is_percentage boolean
---@param stack_index integer
---@return number?
function item:randomized_value(buff_link, prop_name, is_percentage, stack_index)
    local unit = self.unit
    if not unit then
        return nil
    end

    local rnds = unit:get(e_base_data.rnds)

    if not rnds or rnds == 0 then
        return nil
    end

    prop_name = is_percentage and prop_name..'%' or prop_name

    local indexed_link = buff_link..'@'..stack_index

    return rnds and rnds[indexed_link] and rnds[indexed_link][prop_name]
end

---comment
---@param buff_link string
---@param prop_name string
---@param value number
---@param stack_index integer
---@param is_percentage boolean
function item:set_randomized_value(buff_link, prop_name, value, is_percentage, stack_index)
    local unit = self.unit
    if not unit then
        return nil
    end

    local rnds = unit:get(e_base_data.rnds)

    if not rnds or rnds == 0 then
        rnds = {}
    end

    local indexed_link = buff_link..'@'..stack_index

    if not rnds[indexed_link] then
        rnds[indexed_link] = {}
    end

    prop_name = is_percentage and prop_name..'%' or prop_name

    rnds[indexed_link][prop_name] = value
    self:sync_base_data(e_base_data.rnds, rnds)
end

---comment
---@param unit Unit
---@return boolean
function item:add_to(unit)
    if self.removed then
        return false
    end

    local last_active_carrier = self:carrier()
    if unit == last_active_carrier then
        return true
    end

    if not unit then
        return false
    end

    local result, _, slot, _ = unit:can_hold(self)

    if not result then
        return false
    end

    if self.cache and self.cache.NodeType == 'ItemPowerUp' then
        self:remove_pick_region()
        self.powerup_carrier = unit
        self:sync_slot_data()
        unit:execute_on(self.unit, self.cache.Effect)
        if self.cache.KillOnExecute then
            self.powerup_carrier = nil
            self:remove()
        end
        return true
    end
    
    if slot == nil then
        return true
    end

    if slot.item then
       slot:absorb(self)
       if not self.removed then
        repeat
            local result_2nd, _, slot_2nd = unit:can_hold(self)
            if result_2nd and slot_2nd then
                if slot_2nd.item then
                    slot_2nd:absorb(self)
                else
                    slot_2nd:assign(self)
                    break
                end
            else
                break
            end
        until self.removed
       end
    else
        slot:assign(self)
    end

    return true
end

---comment 物品被拾取的逻辑，暂时使用add_to
---@param unit Unit
---@return boolean
function item:pick_by(unit)
    return self:add_to(unit)
end

---如果物品在任何单位身上，则将其卸下，并置于该单位脚下
---@param do_place_unit? boolean
---@return boolean
function item:drop(do_place_unit)
    if self.removed then
        return false
    end

    do_place_unit = (do_place_unit == nil)
    and (self.unit and self.unit_hidden and not self.unit.removed)
    or do_place_unit
    if do_place_unit then
        self.unit:remove_restriction('模型隐藏')
        self.unit:remove_restriction('逻辑隐藏')
        if self.unit.actors then
            for _, actor in ipairs(self.unit.actors) do
                actor:show(true)
            end
        end

        self.unit_hidden = false
    end

    local carrier = self:carrier()
    if not carrier then
        return false
    end

    local slot_cache = self.slot and self.slot.cache
    local equip_carrier = nil
    if slot_cache and slot_cache.Equip then
        equip_carrier = carrier
    end

    if self.slot then
        self.slot.item = nil
        self.slot = nil
    end
    if self.powerup_carrier then
        self.powerup_carrier = nil
    end
    self:update_modification(false,equip_carrier)
    -- 仅在物品单位在掉落前不在场时，将其置于该单位脚下
    if self.unit and not self.unit.removed and do_place_unit then
        self.unit:jump_scene(carrier:get_scene_name())
        self.unit:blink(carrier:get_point())
        self:init_pick_region()
    end
    self:sync_slot_data()
    return true
end

---comment
---@param target Point
function item:move(target)
    if self.removed then
        return
    end

    self:drop()
    if self.unit and not self.unit.removed then
        self.unit:blink(target)
        self:init_pick_region()
    end
end

function item:remove()
    if self.removed then
        return
    end

    local carrier = self:carrier()

    self:drop()
    if self.unit and not self.unit.removed then
        self.unit:remove()
    end
    self:remove_pick_region()
    self.removed = true

    base.game:event_notify('物品-移除', self, carrier)
end

function item:is_valid()
    return not self.removed
end

function item:event_notify(name, ...)
    local cache = base.eff.cache(self.link)
    base.event_notify(self, name, ...)
    if cache then
        base.event_notify(cache, name, ...)
    end
    base.event_notify(base.game, name, ...)
end

function base.init_item(unit, item_link)
    ---log.info('-----------------------init_item:', unit:get_name(), item_link)
    item:new(item_link, unit)
end

function base.game.get_default_item(node_mark)
    local unit = base.game.get_default_unit(node_mark)
    if type(unit) == 'userdata' then
        return unit.item
    end
end

base.get_default_item = base.game.get_default_item

return {
    Item = Item
}