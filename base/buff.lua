local base = base
local eff = base.eff

UnitBuff = UnitBuff or base.tsc.__TS__Class()
UnitBuff.name = 'UnitBuff'

base.unit_buff = UnitBuff.prototype
base.unit_buff.type = 'unit_buff'

---用于管理一个单位身上的同名buff。更符合传统意义上的buff概念。
---@class UnitBuff
---@field get_instances fun():Buff[]
---@field link string
---@field cache table
---@field get_stack_count fun(include_disabled:boolean):integer
---@field is_enabled fun():boolean
---@field unit Unit
---@field cleared boolean
---@field trigs Trigger[]
---@field responses Response[]
---@field tracked_units Unit[]
local ref_ubuff = base.unit_buff

---comment
---@param buff Buff
---@return UnitBuff
function ref_ubuff:setup(buff)
    if not buff.target.unit_buff_instances then
        buff.target.unit_buff_instances = {}
    end
    local unit_buff = buff.target.unit_buff_instances[buff.link]
    if not unit_buff then
        unit_buff = self:new(buff)
    end

    unit_buff.responses = {}
    for _, value in ipairs(unit_buff.cache.Responses) do
        ---@type Response Description
        local it_response = base.response:new(value)
        if it_response then
            it_response:add(unit_buff.unit, unit_buff.default_param)
            table.insert(unit_buff.responses, it_response)
        end
    end
    unit_buff:setup_height_update()


    unit_buff:apply_buff_states()

    buff.unit_buff = unit_buff
    unit_buff:update_state()
    unit_buff:start_by_frame_height_update(true)
    return unit_buff
end

---comment
---@param unit Unit
---@param buff_link string
---@return UnitBuff
function ref_ubuff:get(unit, buff_link)
    if not unit.unit_buff_instances then
        return nil
    end
    return unit.unit_buff_instances[buff_link]
end

---comment
---@param buff Buff
---@return UnitBuff?
function ref_ubuff:new(buff)
    if not buff then
        return
    end
    ---@type UnitBuff Description
    local unit_buff={
        link = buff.link,
        cache = eff.cache(buff.link),
        unit = buff.target,
        default_param = buff.stack_param,
        trigs = {},
        actors = {},
        was_enabled = false,
        state_applied = false,
    }
    buff.unit_buff = unit_buff
    local unit = buff.target
    if not unit.unit_buff_instances then
        unit.unit_buff_instances = {}
    end

    if not unit.disabled_counts_buff then
        unit.disabled_counts_buff = {}
    end

    if not unit.disabled_counts_buff_category then
        unit.disabled_counts_buff_category = {}
    end
    setmetatable(unit_buff, self.__index)
    local cache = buff.cache
    unit.unit_buff_instances[buff.link] = unit_buff
    if cache.BuffFlags.DisableWhenDead then
        ---comment
        unit_buff.trigs.death = buff.target:event('单位-死亡', function (trig, _, _)
            if unit_buff then
                unit_buff:disable_buff(buff.link)
                unit_buff:update_state()
            elseif trig then
                trig:remove()
            end
        end)

        unit_buff.trigs.revive = buff.target:event('单位-复活', function (trig, _)
            if unit_buff then
                unit_buff:enable_buff(buff.link)
                unit_buff:update_state()
            elseif trig then
                trig:remove()
            end
        end)
    end
    buff.stack_param:execute_child_on(cache.InitialEffect)

    if cache.ActorArray and #cache.ActorArray then
        self.actors = self.actors or {}
        for _, value in ipairs(cache.ActorArray) do
            unit_buff:create_actor(value)
        end
    end

    return unit_buff
end


function ref_ubuff:setup_height_update()
    local cache = self.cache
    if cache.TimedHeightChange and cache.TimedHeightChange.HeightDelta and cache.TimedHeightChange.HeightDelta ~= 0 then
        self.height_update_info = self.height_update_info or {}
        self.height_update_info.accumulated = self.height_update_info.accumulated or 0
        self.height_update_info.update = self.height_update_info.update or { [true] = cache.TimedHeightChange.HeightDelta, [false] = - (cache.TimedHeightChange.HeightDelta) }
        if cache.TimedHeightChange.TimeStart and cache.TimedHeightChange.TimeStart > 0 then
            self.height_update_info.update[true] = cache.TimedHeightChange.HeightDelta / cache.TimedHeightChange.TimeStart / 33
        end
        if cache.TimedHeightChange.TimeEnd and cache.TimedHeightChange.TimeEnd > 0 then
            self.height_update_info.update[false] = - (cache.TimedHeightChange.HeightDelta / cache.TimedHeightChange.TimeEnd / 33)
        end
        self.height_update_info.target = cache.TimedHeightChange.HeightDelta
    end
end

function base.on_frame_update_unit_height(on, unit, info)
    if not info or not unit then
        return
    end
    local target = on and info.target or 0
    target = target - info.accumulated
    local delta = info.update[on]
    if math.abs(target) < math.abs(delta) then
        delta = target
    end
    if delta ~= 0 then
        info.accumulated = info.accumulated + delta
        unit:add_height(delta)
    end
end

function ref_ubuff:start_by_frame_height_update(on)
    local info = self.height_update_info
    if not info then
        return
    end
    if on then
        if not self.trigs.height_start then
            self.trigs.height_start = base.game:event('游戏-帧', function (trig, _, _)
                if self.trigs and self.unit then
                    base.on_frame_update_unit_height(true, self.unit, info)
                    if info.target == info.accumulated then
                        trig:remove()
                        self.trigs.height_start = nil
                    end
                elseif trig then
                    trig:remove()
                    if self.trigs then
                        self.trigs.height_start = nil
                    end
                end
            end)
        end
    else
        --- stop accumulat
        if self.trigs.height_start then
            self.trigs.height_start:remove()
            self.trigs.height_start = nil
        end
        --- don't add to self.trig, as I want it to live on after buff removal
        if self.unit and not info.height_end_started then
            info.height_end_started = true
            local unit = self.unit
            base.game:event('游戏-帧', function (trig, _, _)
                if unit then
                    base.on_frame_update_unit_height(false, unit, info)
                    if 0 == info.accumulated then
                        trig:remove()
                        ---todo: else: when a new u_buff with the same link applied, stop resume height.
                    end
                end
            end)
        end
    end
end

---comment
---@param link string
function ref_ubuff:create_actor(link)
    ---@type Unit Description
    local target = self.unit
    local actor = target:create_actor(link, true)
    if actor then
        table.insert(self.actors, actor)
    end
    return actor
end

function ref_ubuff:update_state()
    local new_state = self:is_enabled()
    if new_state == self.was_enabled then
        return
    end
    if new_state then
        self:on_become_enabled()
    else
        self:on_become_disabled()
    end
    self.was_enabled = new_state
end

function ref_ubuff:on_become_enabled()
    self:apply_unit_states()
    self:apply_attribute_change()
    for _, response in ipairs(self.responses) do
        response:enabled()
    end
end

function ref_ubuff:on_become_disabled()
    self:unapply_attribute_change()
    self:unapply_unit_states()
    for _, response in ipairs(self.responses) do
        response:disabled()
    end
end

function ref_ubuff:apply_unit_states()
    local cache = self.cache
    for index, value in ipairs(cache.AddRestrictions) do
        self.unit:add_restriction(value)
    end
    for index, value in ipairs(cache.RemoveRestrictions) do
        self.unit:remove_restriction(value)
    end
end

function ref_ubuff:unapply_unit_states()
    local cache = self.cache
    for index, value in ipairs(cache.RemoveRestrictions) do
        self.unit:add_restriction(value)
    end
    for index, value in ipairs(cache.AddRestrictions) do
        self.unit:remove_restriction(value)
    end
end

function ref_ubuff:apply_buff_states()
    local cache = self.cache
    for _, value in ipairs(cache.BuffsEnable) do
        self:enable_buff(value)
    end

    for _, value in ipairs(cache.BuffsDisable) do
        self:disable_buff(value)
    end

    for _, value in ipairs(cache.BuffCategoriesEnable) do
        self:enable_buff_category(value)
    end

    for _, value in ipairs(cache.BuffCategoriesDisable) do
        self:disable_buff_category(value)
    end

    for _, value in ipairs(cache.ImmuneRestrictions) do
        self.unit:add_immunity(value)
    end

    self.unit:update_unit_buffs()
end

function ref_ubuff:unapply_buff_states()
    local cache = self.cache
    if not cache then
        return
    end
    for _, value in ipairs(cache.BuffsEnable) do
        self:disable_buff(value)
    end

    for _, value in ipairs(cache.BuffsDisable) do
        self:enable_buff(value)
    end

    for _, value in ipairs(cache.BuffCategoriesEnable) do
        self:disable_buff_category(value)
    end

    for _, value in ipairs(cache.BuffCategoriesDisable) do
        self:enable_buff_category(value)
    end

    for _, value in ipairs(cache.ImmuneRestrictions) do
        self.unit:remove_immunity(value)
    end

    self.unit:update_unit_buffs()
end

function ref_ubuff:apply_attribute_change()
    for buff in self.unit:each_buff(self.link) do
        buff:apply_attribute_change()
    end
end

function ref_ubuff:unapply_attribute_change()
    for buff in self.unit:each_buff(self.link) do
        buff:unapply_attribute_change()
    end
end

---comment
---@param buff_link string
function ref_ubuff:disable_buff(buff_link)
    if self.unit then
       self.unit.disabled_counts_buff[buff_link] = (self.unit.disabled_counts_buff[buff_link] or 0) + 1
    end
end

---comment
---@param buff_link string
function ref_ubuff:enable_buff(buff_link)
    if self.unit then
        self.unit.disabled_counts_buff[buff_link] = (self.unit.disabled_counts_buff[buff_link] or 0) - 1
    end
end

---comment
---@param buff_cate string
function ref_ubuff:disable_buff_category(buff_cate)
    if self.unit then
        self.unit.disabled_counts_buff_category[buff_cate] = (self.unit.disabled_counts_buff_category[buff_cate] or 0) + 1
    end
end

---comment
---@param buff_cate string
function ref_ubuff:enable_buff_category(buff_cate)
    if self.unit then
        self.unit.disabled_counts_buff_category[buff_cate] = (self.unit.disabled_counts_buff_category[buff_cate] or 0) - 1
    end
end


---comment
---@return Buff[]
function ref_ubuff:get_instances()
    if self.cleared then
        return nil
    end
    return self.unit:each_buff(self.link);
end

---comment
---@return integer
function ref_ubuff:get_stack_count(include_disabled)
    if self.cleared then
        return nil
    end
    local count = 0
    for buff in self.unit:each_buff(self.link) do
        if (not buff.stack_disabled) or include_disabled then
            count = count + buff.stack
        end
    end
    return count
end

function ref_ubuff:clear()
    self:unapply_buff_states()
    self:start_by_frame_height_update(false)
    if self.actors then
        for _, actor in ipairs(self.actors) do
            actor:destroy(false);
        end
    end
    if self.responses then
        for _, response in ipairs(self.responses) do
            response:remove()
        end
    end
    if self.trigs then
        for _, value in pairs(self.trigs) do
            value:remove()
        end
    end
    self.cleared = true
    self:update_state()
    if self.unit then
        if self.unit.unit_buff_instances then
            self.unit.unit_buff_instances[self.link] = nil
        end
        self.unit = nil
    end
    self.link = nil
    self.trigs = nil
    self.cache = nil
    self.height_update_info = nil
end

---comment
---@return boolean
function ref_ubuff:is_valid()
    if self.cleared then
        return false
    end
    local buff = self.unit:find_buff(self.link)
    if not buff then
        return false
    end
    return true
end

---comment
---@return boolean
function ref_ubuff:is_enabled()
    if not self:is_valid() then
        return false
    end
    return self.unit:is_unit_buff_enabled(self.link)
end

---@class StringNumPair
---@field Key string
---@field Value number
---@field Percentage number

---Buff的实例，一个单位上有可能有多个同名的Buff实例。比如说分别由不同施法者所施加的减速buff，等等。
---@class Buff
---@field name string
---@field skill Skill
---@field get_target fun(self:Buff):Unit
---@field remove fun(self:Buff)
---@field link string
---@field cache table
---@field target Unit
---@field stack integer
---@field stack_param EffectParam
---@field stack_disabled boolean
---@field unit_buff UnitBuff
---@field attributes StringNumPair[]
---@field instance_enabled boolean
---@field set_stack_ fun(self:Buff, stack:integer)
local mt = getmetatable(base.buff)
mt.__buff_finder = mt.__index


Buff = Buff or base.tsc.__TS__Class()
Buff.name = 'Buff'

local buff = Buff.prototype
buff.type = 'buff'

---comment
---@param self Buff
---@param target Unit
---@param link string
---@return EffectParam
function buff:init_root_effect(target, link)
    local ref_param=base.eff_param:new(true)
    local caster
    if(self.skill) then
        caster=self.skill.owner
        ref_param.shared:set_skill(self.skill)
        ref_param:set_buff(self)
    else
        caster=self:get_target()
    end
    ref_param:init(caster,target)
    ref_param:set_cache(link)
    return ref_param
end

---comment
---@param self Buff
---@return boolean
function buff:is_enabled()
    if self.stack_disabled then
        return false
    end

    if not self.unit_buff then
        log.error 'Buff配置错误，拥有Buff却没有UnitBuff。当前Buff或许没有通过正确渠道来添加'
        return true
    end

    return self.unit_buff:is_enabled()
end

---comment
---@param self Buff
function buff:_on_pulse()
    if self.on_pulse then
        self:on_pulse()
    end

    if not self.link then
        return
    end

    if not self.stack_param then
        return
    end

    if not self:is_enabled() then
        return
    end

    local cache = self.cache
    self.stack_param:execute_child_on(cache.PeriodicEffect)
end

---comment
---@param self Buff
function buff:_on_add()
    if self.on_add then
        self:on_add()
    end

    if not self.link then
        local cache = base.eff.cache(self.name)
        if cache then
            self.link = self.name
            self.cache = cache
        else
            return
        end
    end

    if not self.stack_param then
        self.stack_param = self.target:get_creation_param()
    end

    if not self.stack then
        self.stack = self:get_stack() or 1
    end

    self.instance_enabled = true

    ref_ubuff:setup(self)

    self:on_become_instance_enabled()

    if self.cache then
        local cache = self.cache
        if self.stack_param and cache.BuffFlags.Channeling then
            self.stack_param:get_channeler():register(self.stack_param)
            self.stack_param.buff_data = self.stack_param.buff_data or {}
            self.stack_param.buff_data.buff = self
            self.stack_param.buff_data.is_channeling = true
        end

        if self.cache.PersistValidator or self.cache.EnableValidator then
            self.trig = base.game:event('游戏-帧', function()
                    local result_remove = eff.execute_validators(self.cache.PersistValidator,self.stack_param)
                    if result_remove ~= eff.e_cmd.OK then
                        self:remove()
                        return
                    end
                    local result_enable = eff.execute_validators(self.cache.EnableValidator,self.stack_param)
                    local new_state = result_enable == eff.e_cmd.OK
                    if new_state ~= self.instance_enabled then
                        self.instance_enabled = new_state
                        if new_state then
                            self:on_become_instance_enabled()
                        else
                            self:on_become_instance_disabled()
                        end
                    end
                end
            )
        end
    end
end

---comment
---@param self Buff
function buff:_on_finish()
    if self.on_finish then
        self:on_finish()
    end

    if not self.link then
        return
    end

    local cache = self.cache
    self.stack_param:execute_child_on(cache.ExpireEffect)
end

---comment
---@param self Buff
---@param new Buff
function buff:_on_remove(new)
    if self.on_remove then
        self:on_remove()
    end

    local cache = self.cache

    if not self.link then
        return
    end

    if self.instance_enabled then
        self.instance_enabled = false
        self:on_become_instance_disabled()
    end

    if self.trig then
        self.trig:remove()
        self.trig = nil
    end

    if new then
        if new.stack_param then
            new.stack_param:execute_child_on(new.cache.RefreshEffect)
        end
        return
    end

    if not self.target:find_buff(self.link) then
        if self.stack_param then
            self.stack_param:execute_child_on(cache.FinalEffect)
        end
        local unit_buff = self.unit_buff
        if unit_buff then
            unit_buff:clear()
        end
        return
    end
end

function buff:_on_cover(new)
    if self.on_cover then
        return self:on_cover(self, new)
    end
    return true
end

function buff:apply_attribute_change()
    if not self.unit_buff:is_enabled() then
        return
    end

    if not self.instance_enabled then
        return
    end

    local cache = self.cache

    if not self.stacks_applied then
        self.stacks_applied = 0
    end

    if not self.attributes then
        self.attributes = {}
    end

    if self.stacks_applied >= self.stack then
        return
    end

    local index_reversed = #cache.KeyValuePairs
    ---@param pair StringNumPair
    local extra_stacks = (self.stack - self.stacks_applied) or 0
    local it_delta = 0
    for index, pair in ipairs(cache.KeyValuePairs) do
        local value_accumulated = pair.Value(self.stack_param) or 0
        --- 如果buff来自物品，物品提供的属性随机值只会随机一次
        if pair.Random and pair.Random ~= 0 then
            value_accumulated = self.stack_param:item_random(self.link, pair.Key,value_accumulated, value_accumulated + pair.Random, pair.Percentage, self.rnd_index)
        end
        self.attributes[index_reversed - index + 1] = { Key = pair.Key, Value = value_accumulated, Percentage = pair.Percentage }
        it_delta = value_accumulated * extra_stacks
        if pair.Percentage then
            self.target:add(pair.Key..'%', it_delta)
        else
            self.target:add(pair.Key, it_delta)
        end
    end
    self.stacks_applied = self.stack
end

function buff:unapply_attribute_change(stacks)
    if not self.stacks_applied or self.stacks_applied <=0 then
        return
    end
    if not stacks then
        stacks = self.stacks_applied
    end

    stacks = math.min(stacks, self.stacks_applied)
    local it_delta = 0
    for _, pair in ipairs(self.attributes) do
        it_delta = 0 - (pair.Value * stacks)
        if pair.Percentage then
            self.target:add(pair.Key..'%', it_delta)
        else
            self.target:add(pair.Key, it_delta)
        end
    end

    self.stacks_applied = self.stacks_applied - stacks

    if self.stacks_applied == 0 then
        self.attributes = {}
    end
end

---仅仅是当前实例的启用与禁用。当UnitBuff禁用时，依然被视为禁用
---@param self Buff
function buff:on_become_instance_enabled()
    self:apply_attribute_change()
end

function buff:on_become_instance_disabled()
    self:unapply_attribute_change()
end

    ---comment
---@param self Buff
---@param category string
function buff:has_category(category)
    local categories = self.cache and self.cache.Categories
    if categories then
        for _, value in pairs(categories) do
            if value == category then
                return true
            end
        end
    end
    return false
end

---comment
---@param self Buff
---@param category_filters TargetFilters
---@return boolean
function buff:filter_categories(category_filters)
    if(category_filters.excluded)then
        for _, filter in ipairs(category_filters.excluded) do
            if(self:has_category(filter))then
                return false
            end
        end
    end
    if(category_filters.required)then
        for _, filter in ipairs(category_filters.required) do
            if(not self:has_category(filter))then
                return false
            end
        end
    end
    return true
end

function buff:set_stack_(stack)
    if stack <= 0 then
        self:remove()
        return
    end
    local delta = stack - (self.stack or 0)
    self.stack = stack
    self:set_stack(stack)
    if delta == 0 then
        return
    elseif delta > 0 then
        self:apply_attribute_change()
    else
        self:unapply_attribute_change(0 - delta)
    end
end

function buff:add_stack_(stack)
    stack = stack + (self.stack or 0)
    if self.cache.StackMax then
        local max_stack = self.cache.StackMax(self.stack_param)
        if max_stack > 0 then
            stack = math.min(max_stack, stack)
        end
    end
    self:set_stack_(stack)
end

function buff:get_level()
    if self.stack_param and self.stack_param:get_level() then
        return self.stack_param:get_level()
    end
    return -1
end

function buff:set_level(level)
    local old_level = self:get_level()
    if level~=old_level then
        if self.stack_param and self.stack_param.shared then
            self:on_become_instance_disabled()
            self.stack_param.shared:set_level(level)
            self.stack_param:execute_child_on(self.cache.RefreshEffect)
            self:on_become_instance_enabled()
        else
            log.error(tostring(buff)..'缺少效果树信息，无法设置等级！')
        end
    end
end

---comment
---@param t any
---@param k any
---@return Buff?
mt.__index = function(t, k)
    ---@type Buff? Description
    local result = mt.__buff_finder(t, k)
    if not result then
        return nil
    end

    setmetatable(result, buff)

    return result
end

return {
    Buff = Buff,
    UnitBuff = UnitBuff
}