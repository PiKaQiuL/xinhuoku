local base = base
local eff = base.eff

Inventory = Inventory or base.tsc.__TS__Class()
Inventory.name = 'Inventory'

Slot = Slot or base.tsc.__TS__Class()
Slot.name = 'Slot'

base.inventory = Inventory.prototype

base.inventory.type = 'inventory'

base.slot = Slot.prototype

base.slot.type = 'slot'

---@class Slot
---@field item Item
---@field inventory Inventory
---@field cache table
---@field index number --unreliable
local slot  = base.slot

---@class Inventory
---@field link string
---@field carrier Unit
---@field slots Slot[]
---@field cache table
---@field index number --unreliable
local inventory  = base.inventory


function inventory:debuginfo()
    return ('{inventory|%s}'):format(self.link)
end

---comment
---@param unit Unit
---@return Inventory?
function inventory:new(link, unit)
    local cache = eff.cache(link)
    if not cache then
        return nil
    end
    local new_inventory={ unit = unit, link = link, cache = cache, slots = {}}
    if cache.Slots then
        for index, slot_cache in ipairs(cache.Slots) do
            local new_slot = slot:new()
            new_slot.cache = slot_cache
            new_slot.inventory = new_inventory
            new_slot.index = index
            table.insert(new_inventory.slots, new_slot)
            new_slot.index = #new_inventory.slots
        end
    end
    setmetatable(new_inventory, self.__index)

    if unit then
        if not unit.inventorys then
            unit.inventorys = {}
        end
        table.insert(unit.inventorys, new_inventory)
        new_inventory.carrier = unit
        new_inventory.index = #unit.inventorys
    end
    return new_inventory
end

---comment
---@param item Item Description
---@return boolean can_do
---@return Slot? slot
---@return number? remaining
function inventory:can_hold(item)
    if item.removed then
        return false
    end

    for _, it_slot in ipairs(self.slots) do
        local can_do, remaining = it_slot:can_hold(item)
        if can_do then
            return true, it_slot, remaining
        end
    end
    return false
end

---comment
---@param item Item
function inventory:add_item(item)
    if item.removed then
        return false
    end

    if item.slot and self == item.slot.inventory then
        return true
    end

    local result, res_slot, _ = self:can_hold(item)

    if not result then
        return false
    end

    if res_slot == nil then
        return true
    end

    if res_slot.item then
        res_slot:absorb(item)
        if not item.removed then
            repeat
                local result_2nd, _, slot_2nd = self:can_hold(item)
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
            until item.removed
        end
     else
        res_slot:assign(item)
     end

    return true
end

---comment
---@param item Item
---@param swap boolean?
---@param check boolean?
---@return boolean
function slot:assign(item, swap, check)
    if item.removed then
        return false
    end

    if self.item == item and item.slot ==self then
        return true
    end

    if check and not self:can_hold(item, swap) then
        return false
    end
    local old_carrier = item:carrier()

    local old_slot = item.slot
    local old_item = self.item
    if old_slot then
        item.slot.item = nil
    end
    if old_item then
        self.item.slot = nil
    end

    if self.cache then
        item.granted_tag = self.cache.GrantTag or ''
    else
        item.granted_tag = ''
    end

    self.item = item
    item.slot = self
    if item.unit and not item.unit_hidden then
        item.unit_hidden = true       
        if item.unit.actors then
            for _, actor in ipairs(item.unit.actors) do
                actor:show(false)
            end
        end
        item.unit:add_restriction('逻辑隐藏')
        item.unit:add_restriction('模型隐藏')
    end
    local mark = true
    if old_carrier then
        mark = false
    end
    item:update_modification(mark,false)
    if old_item then
        if not old_slot or not swap then
            old_item:drop()
        elseif not old_slot:assign(old_item) then
            old_item:drop()
        end
    end
    item:sync_slot_data()
    return true
end

---comment
---@return Item
function slot:new()
    local new_slot = {}
    setmetatable(new_slot, self.__index)
    return new_slot
end

---comment
---@param item Item
---@return boolean can_do
---@return number remaining
function slot:can_absorb(item)
    if self.item then
        if self.item.link == item.link then
            local item_cache = self.item.cache
            if not self.item.stack then
                return false
            end
            if self.item.stack >= item_cache.StackMax then
                return false
            end
            local remaining = 0
            if item_cache.StackMax > 0 then
                remaining = (self.item.stack or 0) + (item.stack or 0) - item_cache.StackMax
            end
            return true, remaining
        else
            return false
        end
    end
end

function slot:absorb(item)
    if self.item and self.item.link == item.link then
        local carrier = self.item:carrier()
        local item_cache = self.item.cache
        if item_cache.StackMax > 0 then
            local stack = (self.item.stack or 0) + (item.stack or 0)
            if stack <= item_cache.StackMax then
                self.item:set_stack(stack)
                if item.unit and self.item.unit then
                    item.unit:set_owner(self.item.unit:get_owner())
                end
                self.item:event_notify('物品-合并', self.item, item, item.stack)
                if carrier then
                    carrier:event_notify('单位-合并物品', carrier, self.item, item, item.stack)
                end
                item:remove()
            else
                local offset = item_cache.StackMax - (self.item.stack or 0)
                self.item:set_stack(item_cache.StackMax)
                item:set_stack(stack - item_cache.StackMax)
                self.item:event_notify('物品-合并', self.item, item, offset)
                if carrier then
                    carrier:event_notify('单位-合并物品', carrier, self.item, item, offset)
                end
            end
        else
            if self.item.stack then
                self.item:set_stack(self.item.stack + (item.stack or 0))
                self.item:event_notify('物品-合并', self.item, item, item.stack)
                if carrier then
                    carrier:event_notify('单位-合并物品', carrier, self.item, item, item.stack)
                end
            end
            if item.unit and self.item.unit then
                item.unit:set_owner(self.item.unit:get_owner())
            end
            item:remove()
        end
    end
end

---comment
---@param item Item
---@return boolean can_do
---@return number remaining
function slot:can_hold(item ,swap)
    if item.removed then
        return false
    end

    local cache = self.cache
    if not item or not cache then
        return false
    end

    if self.item == item then
        return true
    end
    if cache.Excluded then
        for _, exclude in ipairs(cache.Excluded) do
            if #exclude > 0 and item:has_label(exclude) then
                return false
            end
        end
    end
    if cache.Required then
        for _, require in ipairs(cache.Required) do
            if #require > 0 and not item:has_label(require)then
                return false
            end
        end
    end

    -- 如果都不是，判断能否叠加
    if self.item and (not swap) then
        local can_do, remaining = self:can_absorb(item)
        return can_do,remaining
    end

    return true
end

function slot:met_requirement(item)
    if item.removed then
        return false
    end

    local cache = item.cache

    if not cache then
        return false
    end

    local carrier = item:carrier()
    if not carrier then
        return false
    end

    local mod_cache
    local equip_state = self.cache.Equip
    if equip_state then
        mod_cache = cache.EquipMod
    else
        mod_cache = cache.CarryMod
    end

    if mod_cache then
        local requirement = mod_cache.Validator

        if requirement then
            local ref_param = carrier:create_item_param(item)
            return eff.execute_validators(requirement, ref_param) == eff.e_cmd.OK
        end
    end

    return true
end

return {
    Inventory = Inventory,
    Slot = Slot
}