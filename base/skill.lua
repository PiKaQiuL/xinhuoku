local e_stage = base.eff.e_stage

local e_cmd = base.eff.e_cmd

local mt = getmetatable(base.skill)
mt.__skill_finder = mt.__index

Skill = Skill or base.tsc.__TS__Class()
Skill.name = 'Skill'

Cast = Cast or base.tsc.__TS__Class()
Cast.name = 'Cast'
base.tsc.__TS__ClassExtends(Cast, Skill)

---@class Skill
---@field get_name fun(self):string
---@field get_target fun(self):Target|number|nil
---@field get_level fun(self):integer
---@field get_stage fun(self):integer
---@field stage_finish fun(self)
---@field get_stack fun(self):number
---@field add_stack fun(self, stack:number)
---@field stop fun()
---@field remove fun()
---@field is_skill fun():boolean
---@field is_cast fun(self):boolean
---@field set_option fun(self, key:string, value:number)
---@field get fun(self, key:string):number
---@field cool number C++
---@field charge_cool number C++
---@field cost number C++
---@field owner Unit C++
---@field cast_shot_time number C++
---@field Effect string C++
---@field CancelEffect string C++
---@field range number C++
---@field __name string C++
---@field charge_max_stack number C++
---@field cooldown_mode integer C++
---@field responses Response[]
---@field actors Actor[]
---@field self_param EffectParam
---@field smart_target Unit?
---@field filter TargetFilters?
---@field cache table?
---@field use_charge boolean?
---@field channeler Channeler?
---@field is_activated boolean
---@field source_item Item?
local skill = Skill.prototype
skill.type = 'skill'

---comment
---@return EffectParam
function skill:create_default_param()
    local ref_param = base.eff_param:new(true)
    local target = self.owner
    local caster = self.owner

    ref_param.shared:set_skill(self)
    ref_param.shared:set_level(self:get_level())
    ref_param.shared:set_item(self.source_item)
    ref_param:init(caster,target)
    return ref_param
end

---comment
---@param link string
---@return CmdResult
function skill:execute_self_effect(link)
    return self.self_param:execute_child_on(link)
end

---@class Cast:Skill
---@field get_skill fun(self):Skill
---@field on_can_cast fun(self):boolean
---@field on_can_break fun(self, new_skill:Skill):boolean
---@field on_cast_shot fun(self)
---@field ref_param EffectParam?
---@field main_target Target
---@field CmdIndex integer?
local cast = skill --[[@as Cast]]---

---comment
---@param target Target
---@param link string
---@return EffectParam
function cast:init_root_effect(target, link)
    local ref_param = base.eff_param:new(true)
    local caster= self.owner
    ref_param.shared:set_skill(self)
    ref_param.shared:set_level(self:get_level())
    ref_param.shared:set_item(self.source_item)
    ref_param:init(caster,target)
    ref_param:set_cache(link)
    return ref_param
end

---comment
---@param target Target
---@param link string
---@return CmdResult
function cast:execute_cast_effect(target, link)
    if not self:is_cast() then
        return e_cmd.NotSupported
    end
    self.ref_param = self:init_root_effect(target, link)
    return base.eff.execute(self.ref_param)
end

---comment
---@param event string
---@param alt_link string?
---@return CmdResult
function skill:execute_self_event(event, alt_link)
    if self[event] then
        self[event](self)
    end

    if not self.cache then
        self.cache = base.eff.cache(self.__name)
    end

    local spell_response_location = base.response.e_location.Attacker

    if self.owner and self.is_activated then
        self.owner:on_response('ResponseSpell', spell_response_location, self.self_param, event, self)
    end

    local link
    if alt_link and #alt_link ~= 0 then
        link = alt_link
    elseif not self.cache.SpellEventEffects
    or not self.cache.SpellEventEffects[event]
    or #self.cache.SpellEventEffects[event] == 0
    then
        return e_cmd.NotSupported
    else
        link = self.cache.SpellEventEffects[event]
    end
    return self:execute_self_effect(link)
end

---comment
---@param event string
---@param alt_link string?
---@return CmdResult
function cast:execute_cast_event(event, alt_link)
    if not self:is_cast() then
        return e_cmd.NotSupported
    end

    if not base.tsc.__TS__InstanceOf(self, Cast) then
        self.constructor = Cast
    end

    if self[event] then
        self[event](self)
    end

    if not self.cache then
        self.cache = base.eff.cache(self.__name)
    end

    local target = self:data_driven_target()
    if self.owner and self.is_activated then
        self.owner:on_response_simple('ResponseSpell', target, event, self)
    end

    self:create_actors(event)
    self:destroy_actors(event)

    local link
    if alt_link and #alt_link ~= 0 then
        link = alt_link
    elseif not self.cache.SpellEventEffects
    or not self.cache.SpellEventEffects[event]
    or #self.cache.SpellEventEffects[event] == 0
    then
        return e_cmd.NotSupported
    else
        link = self.cache.SpellEventEffects[event]
    end
    return self:execute_cast_effect(target, link)
end


---comment
---@return Target
function cast:data_driven_target()
    ---@type Target Description
    local target = self.owner
    local caster = self.owner
    if self:is_cast() then
        if self.main_target then
            return self.main_target
        end
        local raw_target = self:get_target()
        if raw_target == nil then
            target = caster
        elseif type(raw_target) == 'number' then
            local distance = self.range
            target = caster:get_point():polar_to({raw_target, distance})
        else
            target = raw_target
        end
    end
    return target
end


function skill:is_init_on()
    ---@type boolean?
    local result = self.cache and self.cache.SpellFlags and self.cache.SpellFlags.InitOn
    if result == nil then
        result = true
    end
    return result
end
function skill:_on_add()
    if not self then
        return
    end

    local spell_link = self.__name
    local spell_cache = base.eff.cache(spell_link)
    self.cache = spell_cache
    self.is_activated = self:is_init_on()
    self:set_option("sys_state_toggled_on", self.is_activated and 1 or 0)

    self.self_param = self:create_default_param()

    self:update_attribute_change()

    if not spell_cache then
        return
    end

    self.cache = spell_cache

    if spell_cache.SpellAttribute and #spell_cache.SpellAttribute then
        for key, value in pairs(spell_cache.SpellAttribute) do
            self:set_option(key, value)
        end
    end

    if spell_cache.SpellFlags and spell_cache.SpellFlags.Hidden then
        self:set_option("sys_state_hidden", 1)
    end

    if spell_cache.target_type == 1 and spell_cache.AcquireSettings.TargetUnitFilter then
        self.filter = base.target_filters:new(spell_cache.AcquireSettings.TargetUnitFilter)
    end

    if self.Effect and self.charge_max_stack and self.charge_max_stack > 0 and (self.cooldown_mode == 1) then
        self:set_stack(self.charge_max_stack)
        self.use_charge = true
    end

    if spell_cache.Responses then
        self.responses = {}
        for _, value in ipairs(spell_cache.Responses) do
            local it_response = base.response:new(value)
            if it_response then
                it_response:add(self.owner, self.self_param)
                table.insert(self.responses, it_response)
            end
        end
    end

    self:execute_self_event('on_add', self.cache and self.cache.CreationEffect)
end

function skill:_on_remove()
    if not self then
        return
    end

    self:execute_self_event('on_remove')

    self.is_activated = false
    self:unapply_attribute_change()

    if self.responses then
        for _, response in ipairs(self.responses) do
            response:remove()
        end
        self.responses = nil
    end
end

function skill:_on_upgrade ()
    if not self then
        return
    end

    self.self_param.shared:set_level(self:get_level())

    self:update_attribute_change(true)

    self:execute_self_event('on_upgrade')
end

function skill:_on_enable ()
    if not self then
        return
    end

    self:execute_self_event('on_enable')
end

function skill:_on_disable ()
    if not self then
        return
    end

    self:execute_self_event('on_disable')
end

function skill:_on_cooldown ()
    if not self then
        return
    end

    self:execute_self_event('on_cooldown')
end

function skill:_on_select_target ()
    if not self then
        return
    end

    self:execute_self_event('on_select_target')
end

---comment
---@param category string
function skill:has_category(category)
    local cache = self.cache
    if not cache then
        return false
    end
    local categories = self.cache.Categories
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
---@param category_filters TargetFilters
---@return boolean
function skill:filter_categories(category_filters)
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

function skill:is_attack()
    if self.cache and self.cache.SpellFlags and self.cache.SpellFlags.IsAttack then
        return true
    end

    return false
end

function skill:get_num(name, ...)
    local ret = self:get(name, ...)
    if type(ret) ~= "number" then
        log.warn("尝试用数字方法获取技能的非数字属性"..name)
    end
    return ret;
end

function skill:set_num(name, value, ...)
    if type(value) ~= "number" then
        log.warn("尝试用数字方法获取技能的非数字属性"..name)
    end
    return self:set_option(name, value, ...);
end

function skill:active_custom_cd(max_cd, cd)
    self:active_cd(max_cd, true)
    self:set_cd(cd)
end

function skill:enable_hidden()
    skill:set_option("sys_state_hidden", 1)
end

function skill:disable_hidden()
    skill:set_option("sys_state_hidden", 0)
end

function skill:is_hidden()
    if skill:get("sys_state_hidden") == 1 then
        return true
    end
    return false
end

---comment
function skill:apply_attribute_change()
    if (not self.owner) or (not self.is_activated) or self.is_attribute_applied then
        return
    end
    local cache = self.cache or base.eff.cache(self.__name)

    if cache.KeyValuePairs and #cache.KeyValuePairs then

        local ref_param = self.self_param

        self.attributes = ref_param:snap_shot_values(cache.KeyValuePairs)

        for _, pair in ipairs(self.attributes) do
            self.owner:add_property(pair.Key, pair.Value, pair.Percentage)
        end
    end

    if cache.ImmuneRestrictions then
        for _, value in ipairs(cache.ImmuneRestrictions) do
            self.owner:add_immunity(value)
        end
    end

    self.is_attribute_applied = true
end

---comment
function skill:unapply_attribute_change()
    if not self.is_attribute_applied or not self.owner then
        return
    end

    if self.attributes then
        for _, pair in ipairs(self.attributes) do
            self.owner:add_property(pair.Key, - pair.Value, pair.Percentage)
        end
    end

    if self.cache and self.cache.ImmuneRestrictions then
        for _, value in ipairs(self.cache.ImmuneRestrictions) do
            self.owner:remove_immunity(value)
        end
    end

    self.is_attribute_applied = false
end

---comment
---@param forced boolean?
function skill:update_attribute_change(forced)
    if forced then
        self:unapply_attribute_change()
        if self.is_activated then
            self:apply_attribute_change()
        end
    else
        if self.is_attribute_applied ~= self.is_activated then
            if self.is_activated then
                self:apply_attribute_change()
            else
                self:unapply_attribute_change()
            end
        end
    end
end

function skill:_get_formula_flag()
    local cache = self.cache
    if not cache then
        return false
    end
    if cache.SpellFlags and cache.SpellFlags.UseFormula then
        return true
    else
        return false
    end
end

function skill:_get_cost()
    local cache = self.cache
    if cache and cache.Formulas and cache.Formulas.Mana then
        return cache.Formulas.Mana(self.self_param) or 0
    end
    return self.cost or 0
end

function skill:_get_cool()
    local cache = self.cache
    if cache and cache.Formulas and cache.Formulas.Cooldown then
        return cache.Formulas.Cooldown(self.self_param) * 1000 or 0
    end
    return self.cool or 0
end

function skill:_get_charge_max_stack()
    local cache = self.cache
    if cache and cache.Formulas and cache.Formulas.ChargeMax then
        return cache.Formulas.ChargeMax(self.self_param) or 0
    end
    return self.charge_max_stack or 0
end

function skill:_get_charge_cool()
    local cache = self.cache
    if cache and cache.Formulas and cache.Formulas.ChargeCooldown then
        return cache.Formulas.ChargeCooldown(self.self_param) * 1000 or 0
    end
    return self.charge_cool or 0
end

function skill:_get_range()
    local cache = self.cache
    if cache and cache.Formulas and cache.Formulas.Range then
        return cache.Formulas.Range(self.self_param) or 0
    end
    return self.range or 0
end

---comment
---@param stage number
function skill:_get_time(stage)
    local cache = self.cache
    if cache and cache.Formulas and cache.Formulas.Time then
        return cache.Formulas.Time(self.self_param, stage) * 1000 or 0
    end
    return 0
end



local e_cmdIndex = {
    execute = 0,
    toggle_on = 1,
    toggle_off = 2,
}
---comment
---@return boolean
function cast:_on_can_cast()
    if not self then
        return false
    end
    if self.on_can_cast then
        if not self:on_can_cast() then
            return false
        end
    end

    if not self.CmdIndex and self.cache and self.cache.NodeType == 'SpellToggle' then
        return false
    end

    if self.CmdIndex == e_cmdIndex.toggle_off then
        ---关闭技能没有别的条件，只需要判定技能处于开启状态
        return self.is_activated
    end

    if self.CmdIndex == e_cmdIndex.toggle_on and self.is_activated then
        ---开启技能至少需要技能处于关闭状态
        return false
    end

    ---如果技能来自物品，则物品层数为0时无法使用
    if self.source_item and self.source_item.stack and self.source_item.stack <= 0 then
        self.owner:error_info(base.eff.e_cmd_str[base.eff.e_cmd.NotEnoughCharges])
        ---至少在bug的时候再用就删掉
        if self.source_item.cache and self.source_item.cache.KillOnDepleted then
            self.source_item:remove()
        end
        return false
    end

    if self.use_charge and self:get_stack() <= 0 then
        self.owner:error_info(base.eff.e_cmd_str[base.eff.e_cmd.NotEnoughCharges])
        return false
    end

    if self.owner and ((self.cache and self.cache.Unit) or (self.unit_cache)) then
        self.unit_cache = self.unit_cache or base.eff.cache(self.cache.Unit)
        if self.unit_cache and self.unit_cache.Resources and #self.unit_cache.Resources then
            local player = self.owner:get_owner()
            for key, value in pairs(self.unit_cache.Resources) do
                if type(value)=="number" and value ~= 0 then
                    if not player then
                        log.error('Spell:', self, 'Try cast an ability that cost player resource while there is no player Environment')
                        return false
                    end
                    if value > 0 then
                        local value_l = player:get(key)
                        if type(value_l) ~= "number" then
                            log.error('Spell:', self, 'Try cost player resource which is not a number type: ', key)
                            return false
                        end
                        if value_l < value then
                            self.owner:error_info(base.eff.e_cmd_str[base.eff.e_cmd.NotEnoughResource]..': '..key)
                            return false
                        end
                    end
                end
            end 
        end
    end

    self.main_target = self:data_driven_target()

    if self.unit_cache and self.main_target then
        local target = self:data_driven_target()
        if target then
            local placement = base.game.get_placement_point(self.main_target:get_point(), self.unit_cache , 0, false)
            if not placement or (placement[1] == -1 and placement[2] == -1) then
                if self.owner then
                    self.owner:error_info(base.eff.e_cmd_str[base.eff.e_cmd.CannotPlaceThere])
                end
                return false
            end
        end
    end
            
    local effect_link = self:get_effect_link()
    if not effect_link or #effect_link== 0 then
        return true
    end

    self.ref_param = self:init_root_effect(self.main_target, effect_link)


    ---计算技能目标
    local result, errorInfo
    if self.main_target and self.main_target:get_unit() and self.filter then
        result, errorInfo = self.filter:validate(self.owner, self.main_target:get_unit())
    end

    if not result or result == e_cmd.OK then
        ---计算节点目标
        self.ref_param:calc_target()
        result, errorInfo = base.eff.validate(self.ref_param)
    end

    local success = result == e_cmd.OK
    if not success and self.owner.error_info then
        errorInfo = errorInfo or base.eff.e_cmd_str[result]
        self.owner:error_info(errorInfo)
    end

    return success
end

---comment
---@param self Skill
function cast:_on_cast_approach()
    if not self then
        return
    end
    local caster=self.owner
    self.cache = self.cache or base.eff.cache(self.__name)
    local spell_cache = self.cache
    if caster and spell_cache and spell_cache.AttributeHaste and #spell_cache.AttributeHaste > 0 then
        if caster:get(spell_cache.AttributeHaste) <= 0 then
            log.debug('施法者'..tostring(caster)..'的技能['..spell_cache.Name..']使用['..spell_cache.AttributeHaste..']属性作为施法速度，但该属性值为0，请确认是否配置正确')
        end
    end

    self:execute_cast_event("on_cast_approach", self.cache and self.cache.StartEffect)
end

---comment
---@param new_skill Skill
---@param is_walk boolean
---@return boolean
function cast:_on_can_break(new_skill, is_walk) -- 不确定这里写得对不对
    if not self then
        return false
    end
    if self.on_can_break then
        return self:on_can_break(new_skill)
    end
    
    local cache_self = self.cache or base.eff.cache(self.__name)
    local config_self = cache_self.SpellInterruptConfig
    if not config_self then
        return true
    end

    if is_walk then
        if not config_self.InterruptedByWalk then
            return false
        end
        if self:get_stage() <= 1 and self.owner and self.owner:is_joystick_moving() and cache_self.SpellFlags.StopWalk then
            if self:get_stage() <= 1 and self.owner:joystick_moving_time() > 33 then
                return false
            end
        end
    else
        if not new_skill then
            return false
        end

        local cache_othter = new_skill.cache or base.eff.cache(new_skill.__name)
        local config_other = cache_othter.SpellInterruptConfig

        local in_Priority = 0

        if config_other then
            in_Priority = config_other.InterruptingPriority or 0
        end

        local required_Priority = config_self.InterruptedRequiredPriority or 0

        if in_Priority < required_Priority then
            return false
        end
    end

    return true
end

function cast:_on_cast_channel()
    if not self then
        return
    end

    self:execute_cast_event("on_cast_channel")
end

---comment
---@param on boolean
function cast:toggle(on)
    local skill_instance = self:get_skill()
    skill_instance.is_activated = on
    self:set_option("sys_state_toggled_on", on and 1 or 0)
    skill_instance:update_attribute_change()
end

---comment
function cast:_on_cast_shot()
    if not self then
        return
    end

    if self.owner and ((self.cache and self.cache.Unit) or (self.unit_cache)) then
        self.unit_cache = self.unit_cache or base.eff.cache(self.cache.Unit)
        if self.unit_cache and self.unit_cache.Resources and #self.unit_cache.Resources then
            local player = self.owner:get_owner()
            for key, value in pairs(self.unit_cache.Resources) do
                local value_l = player:get(key)
                player:set(key, value_l - value)
            end
        end
    end

    if self.CmdIndex == e_cmdIndex.toggle_off then
        self:toggle(false)
        self:execute_cast_event("on_cast_toggle_off", self.cache and self.cache.EffectOff)
        return
    elseif self.CmdIndex == e_cmdIndex.toggle_on then
        ---开启技能至少需要技能处于关闭状态
        self:toggle(true)
    end

    
    if self.on_cast_shot then
        self:on_cast_shot()
    end

    self:create_actors("on_cast_shot")
    self:destroy_actors("on_cast_shot")

    local committed = false

    if self.owner and self.main_target then
        self.owner:on_response_simple('ResponseSpell', self:data_driven_target(), "on_cast_shot", self)
        if self.unit_cache then
            local player = self.owner:get_owner()
            local scene = self.owner:get_scene_name()
            local unit = player:create_unit(self.unit_cache.Link, self.main_target:get_point(), 0, nil, scene)
            if unit then
                committed = true
                if self.cache.CreateUnitFlags and self.cache.CreateUnitFlags.DefaultAI then
                    local ai_link = 'default_ai'
                    if self.unit_cache and self.unit_cache.DefaultAI and #self.unit_cache.DefaultAI > 0 then
                        ai_link = self.unit_cache.DefaultAI
                    end
    
                    local creator =  unit:creator():get_unit()
                    unit:add_ai(ai_link){
                        master = creator,
                        stay_time = self.unit_cache.stay_time,
                        distance_random = self.unit_cache.distance_random,
                        follow_random = self.unit_cache.follow_random,
                    }
    
                    base.game:ui'__update_collision_info'{
                        point = unit:get_point(),
                        link = self.unit_cache.Link
                    }
                end
            end
        end
    end

    local effect = self:get_effect_link()

    if not committed and (not effect or #effect== 0) then
        return
    end
    
    self.channeler = base.channeler:new()
    if effect and #effect > 0 then
        local result = self:start_effect()
        if not committed and result ~= e_cmd.OK then
            self:stop_channeling()
            self:bail()
            return
        end
    end
    if self.source_item and self.source_item.stack and self.source_item.stack > 0 then
        self.source_item:set_stack(self.source_item.stack - 1)
        base.game:event_notify('物品-使用', self.owner, self.source_item)
    end

    -- 充能技能C++处理层数了 这里不需要额外处理层数

    local is_channeling=self.channeler:is_channeling()
    --TODO: 获得剩余引导时间
    if(is_channeling or self.cast_shot_time>0) then
        return
    end

    self:stop_channeling()
    self:stage_finish()
    --TODO:
end

---comment
function cast:_on_cast_finish()
    if not self then
        return
    end

    self:execute_cast_event("on_cast_finish")
    
    local effect_link = self:get_effect_link()
    if not effect_link or #effect_link== 0 then
        return
    end
    --发出停止引导的消息
    self:stop_channeling()
end

---comment
---@param stack number
function skill:set_stack(stack)
    self:add_stack(stack - self:get_stack())
end

---comment
---@return string
function cast:get_effect_link()
    local spell_cache = base.eff.cache(self.__name)
    self.cache = spell_cache
    if not spell_cache or not spell_cache.Effect or #spell_cache.Effect == 0 then
        return self.Effect
    end
    return spell_cache.Effect
end
---comment
---@return integer
function cast:start_effect()
    self.ref_param= base.eff_param:new(true)
    local target= self:get_target()
    local caster=self.owner
    if (target==nil) then
        target=caster
    end

    if (type(target)=='number') then
        target=caster:get_point():polar_to({target,self.range})
    end
    self.ref_param.shared:set_skill(self)
    self.ref_param.shared:set_level(self:get_level())
    self.ref_param.shared:set_item(self.source_item)
    if(self:get_stage()==e_stage.shot)then
        self.ref_param:set_channeler(self.channeler)
        local skill_instance = self:get_skill()
        if skill_instance then
            skill_instance.last_target = self.smart_target or target
        end
    end
    self.ref_param:init(caster,target)
    self.ref_param:set_cache(self:get_effect_link())
    return base.eff.execute(self.ref_param)
end

---comment
---@param event string
function cast:create_actors(event)
    local cache = self.cache or base.eff.cache(self.__name)
    if not cache then
        return
    end
    local it_actor_cache
    if cache.ActorArray and #cache.ActorArray then
        self.actors = self.actors or {}
        for _, value in ipairs(cache.ActorArray) do
            it_actor_cache = base.eff.cache(value)
            if it_actor_cache and it_actor_cache.EventCreation == event then
                self:create_actor(value)
            end
        end
    end
end

---comment
---@param event string
function cast:destroy_actors(event)
    if not self.actors then
        return
    end

    --只要填写了EventDestruction，那么在on_cast_stop时必定要销毁
    --bug: on_cast_break不一定触发on_cast_stop.现在暂时都判一下
    local stop = false
    if event == 'on_cast_stop' or event == 'on_cast_break' then
        stop = true
    end
    for _, actor in ipairs(self.actors) do
        local link = actor.name
        local actor_cache = base.eff.cache(link)
        self.actors = self.actors or {}
        if actor_cache and actor_cache.EventDestruction ~= '' then
            if stop or actor_cache.EventDestruction == event then
                actor:destroy(false);
            end
        end
    end
end

---comment
---@param link string
function cast:create_actor(link)
    ---@type Unit Description
    local target = self.owner
    local actor = target:create_actor(link, true)
    if actor then
    table.insert(self.actors, actor)
    end
    return actor
end

---comment
function cast:_on_cast_start()
    if not self then
        return
    end

    local caster=self.owner
    self.cache = self.cache or base.eff.cache(self.__name)
    local spell_cache = self.cache
    if caster and spell_cache and spell_cache.AttributeHaste and #spell_cache.AttributeHaste > 0 then
        if caster:get(spell_cache.AttributeHaste) <= 0 then
            log.debug('施法者'..tostring(caster)..'的技能['..spell_cache.Name..']使用['..spell_cache.AttributeHaste..']属性作为施法速度，但该属性值为0，请确认是否配置正确')
        end
    end

    self:execute_cast_event("on_cast_start", self.cache and self.cache.StartEffect)
end

function cast:_on_cast_break()
    if not self then
        return
    end

    self:execute_cast_event("on_cast_break")

    ---若物品被设置为耗尽使用次数后移除，则移除物品
    if self.source_item
    and self.source_item.stack
    and self.source_item.cache
    and self.source_item.cache.KillOnDepleted
    and self.source_item.stack <= 0 then
        self.source_item:remove()
            -- base.game:event_notify('物品-移除', self)
    end
end

---comment
function cast:_on_cast_stop()
    if not self then
        return
    end

    self:execute_cast_event("on_cast_stop")

    local effect_link = self:get_effect_link()

    if effect_link and #effect_link > 0 then
        --todo:移除占位器
        if(self:get_stage()==e_stage.shot)then
            self:stop_channeling()
        end
    end

    ---若物品被设置为耗尽使用次数后移除，则移除物品
    if self.source_item
    and self.source_item.stack
    and self.source_item.cache
    and self.source_item.cache.KillOnDepleted
    and self.source_item.stack <= 0 then
        self.source_item:remove()
            -- base.game:event_notify('物品-移除', self)
    end
end

-- self 现在传进来的是nil，暂时没搞明白，于是先注了（on_cast_failed暂时失效）

-- function cast:_on_cast_failed(failed_code)
--     print('on_cast_failed', type(self), failed_code)
--     if self.on_cast_failed then
--         self:on_cast_failed(failed_code)
--     end
-- end

---comment
function cast:bail()
    if self.CancelEffect then
        self.ref_param:execute_child_on(self.CancelEffect)
    end
    self:stop()
end

---comment
---@return number|Unit?
function cast:get_last_target()
    local origin_skll = self:get_skill()
    if origin_skll then
        return origin_skll.last_target
    end
    return nil
end

---comment
---@return Unit?
function cast:get_last_target_unit()
    local target = self:get_last_target()
    if target and type(target) ~= "number" and target.type == 'unit' then
        return target:get_unit()
    end
    return nil
end

---comment
---@return number?
function cast:get_last_target_angle()
    local target = self:get_last_target()
    if target then
        if type(target) == 'number' then
            return target
        elseif target.type == 'unit' then
            if not self.owner then
                return
            end
            return self.owner:get_unit():get_point():angle_to(target:get_point())
        end
    end
    return nil
end


---comment
function cast:stop_channeling()
    -- body
    if(self.channeler)then
        self.channeler:clear()
        self.channeler=nil
    end
end

---comment
---@return boolean
function cast:is_channeler_active()
    if not self.channeler then
        return false
    end
    return self.channeler:is_channeling()
end

---comment
---@return boolean
function cast:is_channeling()
    --TODO: 获得剩余引导时间 or
    return self:is_channeler_active() or (self:get_stage() == e_stage.shot)
end

mt.__index = function(t, k)
    ---@type Skill|nil Description
    local result = mt.__skill_finder(t, k)
    if not result then return end

    local meta = getmetatable(result)
    setmetatable(meta, skill)

    return result
end

return {
    Skill = Skill,
    Cast = Cast
}
