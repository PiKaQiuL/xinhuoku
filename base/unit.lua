local table = table
local base  = base
local eff = base.eff
local type = type
local math = math
local ipairs = ipairs
local tostring = tostring
local instance_of = base.tsc.__TS__InstanceOf

Unit = Unit or base.tsc.__TS__Class()
Unit.name = 'Unit'

base.tsc.__TS__ClassExtends(Unit, Target)

---@class Unit:Target
---@field add_restriction fun(self:Unit, att:string)
---@field remove_restriction fun(self:Unit, att:string)
---@field get_restriction fun(self:Unit, att:string):number
---@field restriction_counts table<string, number>
---@field get_id fun():integer
---@field item Item
---@field get fun(self:Unit, att:string)
---@field set fun(self:Unit, att:string, value:number)
---@field add fun(self:Unit, att:string, value:number)
---@field add_skill fun(self:Unit, id:string,type:string):Skill
---@field add_buff fun(self:Unit, id:string,delay:number?):fun(data:table):Buff
---@field add_exp fun(self:Unit, amount:number)
---@field blink fun(self:Unit, dest:Point, sync:boolean?)
---@field clear_command fun(self:Unit)
---@field remove fun()
---@field stop fun()
---@field walk fun(self:Unit, dest:Point)
---@field cast fun(self:Unit, name:string, target:any, data:table):boolean
---@field current_skill fun():Skill
---@field set_facing fun(self:Unit, angle:number, time:number):Skill
---@field set_owner fun(self:Unit, player:Player)
---@field replace_skill fun(self:Unit, link_old:string, link_new:string)
---@field reborn fun(self:Unit, point:Point)
---@field each_buff fun(self:Unit, id:string):Buff[]
---@field find_buff fun(id:string):Buff
---@field each_mover fun(self:Unit)
---@field is_joystick_moving fun(self:Unit):boolean
---@field joystick_moving_time fun(self:Unit):number
---@field error_info fun(self:Unit, msg:string)
---@field add_ai fun(self:Unit, ai:string):fun(data:table)
---@field unit_buff_instances UnitBuff[]
---@field is_unit_buff_enabled fun(id:string):boolean
---@field disabled_counts_buff integer[]
---@field disabled_counts_buff_category integer[]
---@field immunity_counts_restriction table<string, number>
---@field response table
---@field inventorys Inventory[]
---@field ref_param EffectParam
---@field _parent_param EffectParam
---@field inv_item_ids integer[]
local mt = Unit.prototype

base.runtime.unit = mt

mt.add_restruction_internal = mt.add_restriction
mt.remove_restruction_internal = mt.remove_restriction
mt.get_restriction_internal = mt.get_restriction

---comment
---@param att string
---@param count number
function mt:set_restruction_internal(att, count)
    local count_curr = self:get_restriction_internal(att)

    local func
    if count == count_curr then
        return
    elseif count > count_curr then
        func = self.add_restruction_internal
    else
        func = self.remove_restruction_internal
    end

    if not func then
        return
    end

    for i = 1, base.math.abs(count - count_curr), 1 do
        func(self, att)
    end
end

---comment
---@param att string
function mt:has_immunity(att)
    if not self.immunity_counts_restriction then
        return false
    end

    if not self.immunity_counts_restriction[att] then
        return false
    end

    return self.immunity_counts_restriction[att] > 0
end

function mt:update_restriction_internal(att)
    local count = self:has_immunity(att) and 0
    or
    (self.restriction_counts and self.restriction_counts and self.restriction_counts[att])
    or 0
    self:set_restruction_internal(att, count)
end

function mt:add_immunity(att)
    self.immunity_counts_restriction = self.immunity_counts_restriction or {}
    self.immunity_counts_restriction[att] = (self.immunity_counts_restriction[att] or 0) + 1
    self:update_restriction_internal(att)
end

function mt:remove_immunity(att)
    if not self.immunity_counts_restriction or not self.immunity_counts_restriction[att] then
        log.info('Tried to remove immunity from an unit with no such immunity')
        return
    end
    self.immunity_counts_restriction[att] = self.immunity_counts_restriction[att] - 1
    self:update_restriction_internal(att)
end

---comment
---@param att string
function mt:add_restriction(att)
    self.restriction_counts = self.restriction_counts or {}
    self.restriction_counts[att] = (self.restriction_counts[att] or 0) + 1
    self:update_restriction_internal(att)
end

---comment
---@param att string
function mt:remove_restriction(att)
    self.restriction_counts = self.restriction_counts or {}
    self.restriction_counts[att] = (self.restriction_counts[att] or 0) - 1
    self:update_restriction_internal(att)
end

mt.add_mark = mt.add_restriction
mt.remove_mark = mt.remove_restriction

--调试器
function mt:__debugger_extand()
    local u = self
    -- 属性部分
    local attr = {}
    local sort = {}
    for key, id in pairs(base.table.constant['单位属性']) do
        sort[key] = id
        table.insert(attr, key)
    end
    table.sort(attr, function(key1, key2)
        return sort[key1] < sort[key2]
    end)
    table.insert(attr, 1, '[name]')
    attr['[name]'] = tostring(u)
    local proxy = {}
    function proxy:__index(key)
        return u:get(key)
    end
    function proxy:__newindex(key, value)
        u:set(key, value)
    end
    return setmetatable(attr, proxy)
end

--类型
mt.type = 'unit'

--单位计时器
mt._timers = nil

-- 获取单位带场景的坐标
function mt:get_scene_point()
    return self:get_point():copy_to_scene_point(self:get_scene_name())
end

-- 单位是否存活并在场
function mt:is_alive_ex()
    if self.removed then
        return false
    end
    return self:is_alive()
end

-- 单位是否存活并在场
function mt:is_alive_ex()
    if self.removed then
        return false
    end
    return self:is_alive()
end

function mt:blink_ex(position)
    local success = self:jump_scene(position:get_scene())
    if success then
        self:blink(position)
    end
    return success
end

--加判场景
local function scene_check_wrapper(func, unit, target, ...)
    if not instance_of(target, ScenePoint) or (instance_of(target, ScenePoint) and not target:get_scene_name()) then
        -- 兼容老地图，如果不是ScenePoint或者没有场景就按原本的逻辑
        return func(unit, target, ...);
    end
    if unit:get_scene_name() ~= target:get_scene_name() then
        log.info(unit, '与', target, '场景不匹配！')
        return nil
    end
    return func(unit, target, ...);
end

local unit_walk = mt.walk
function mt:walk(target, ...)
    return scene_check_wrapper(unit_walk, self, target, ...)
end

local unit_reborn = mt.reborn
function mt:reborn(target, ...)
    return scene_check_wrapper(unit_reborn, self, target, ...)
end

local unit_blink = mt.blink
function mt:blink(target, ...)
    return scene_check_wrapper(unit_blink, self, target, ...)
end

--是否在范围内
--	参考目标
--	半径
function mt:is_in_range(p, radius)
    return (self:get_point():distance(p:get_point()) - self:get_attackable_radius() <= radius) and (p:get_scene_name() == self:get_scene_name())
end

-- 技能
function mt:simple_cast(name, callback)
    local skill = self:find_skill(name)
    if skill then
        skill:simple_cast(callback)
    end
end


function find_max_id_in_constant()
    local max_id = 0
    for key, id in pairs(base.table.constant['单位属性']) do
        max_id = math.max(max_id, id);
    end
    return max_id
end

function add_attribute_and_sync_client(name)
    local max_id = find_max_id_in_constant() + 1
    base.table.constant['单位属性'][name] = max_id
    base.game:unit_attribute_add(name,max_id);
    log.info('attribute add',name, max_id);
    -- 同步给客户端
    base.game:ui'__add_attribute_and_sync_client'{
        struct_name = name,
        struct_id = max_id,
    }
end

local unit_set = mt.set
function mt:set(name, value, ...)
    if base.table.constant['单位属性'] == nil then
        log.info('table.constant is nil')
        return 
    end
    if base.table.constant['单位属性'][name] == nil then
        add_attribute_and_sync_client(name);
    end
    unit_set(self,name,value,...);
end

local unit_get = mt.get
function mt:get(name,...)
    if base.table.constant['单位属性'][name] == nil then
        log.info('table.constant is nil')
        return 0
    end
    return unit_get(self,name,...);
end

local unit_add = mt.add
function mt:add(name, value, ...)
    if base.table.constant['单位属性'] == nil then
        log.info('table.constant is nil')
        return
    end
    if string.sub(name,-1) == '%' then
        local name_tmp = string.sub(name,1, string.len(name) - 1)
        if base.table.constant['单位属性'][name_tmp] == nil then
            add_attribute_and_sync_client(name_tmp);
        end
    else
        if base.table.constant['单位属性'][name] == nil then
            add_attribute_and_sync_client(name);
        end
    end
    unit_add(self,name,value,...);
end

local unit_add_ex = mt.add_ex
function mt:add_ex(name,value,...)
    if base.table.constant['单位属性'] == nil then
        log.info('table.constant is nil')
        return
    end
    if base.table.constant['单位属性'][name] == nil then
        add_attribute_and_sync_client(name);
    end
    unit_add_ex(self,name,value,...);
end

local unit_set_ex = mt.set_ex
function mt:set_ex(name, value, ...)
    if base.table.constant['单位属性'] == nil then
        log.info('table.constant is nil')
        return
    end
    if base.table.constant['单位属性'][name] == nil then
        add_attribute_and_sync_client(name);
    end
    unit_set_ex(self,name,value,...);
end

local unit_set_attribute_sync = mt.set_attribute_sync
function mt:set_attribute_sync(name, sync, ...)
    if base.table.constant['单位属性'] == nil then
        log.info('table.constant is nil')
        return
    end
    if base.table.constant['单位属性'][name] == nil then
        add_attribute_and_sync_client(name);
    end
    unit_set_attribute_sync(self,name,sync,...);
end

function mt:remove_skill(name)
    for skill in self:each_skill() do
        if skill:get_name() == name then
            skill:remove()
        end
    end
end

function mt:find_movable_distance(target, max_distance)
	local p = self:get_point()
	local distance = p:distance(target)
	local angle = p:angle(target)
	if not target:is_block() then
		return distance
	end
	if max_distance then
		for distance = distance, max_distance, 64 do
			if not (p:polar_to({angle, distance})):is_block() then
				return distance
			end
		end
		if not (p:polar_to({angle, max_distance})):is_block() then
			return max_distance
		end
	end
	for distance = distance, 0, -64 do
		if not (p:polar_to({angle, distance})):is_block() then
			return distance
		end
	end
	return 0
end

--移除Buff
--	buff名称
function mt:remove_buff(name)
    for buff in self:each_buff(name) do
        buff:remove()
    end
end

-- 是否拥有指定名称的buff
function mt:has_buff(name)
    local buff=self:find_buff(name)
    if (buff) then
        return true
    end
    return false
end

function mt:get_buff_stack_all(link)
    local c = 0
    for buff in self:each_buff(link) do
        c = c + (buff:get_stack() or 0)
    end
    return c
end

--注册单位事件
function mt:event(name, f)
    return base.event_register(self, name, f)
end

--是否是友方
--	对方单位(玩家)
---comment
---@param dest Unit|Player
---@return boolean
function mt:is_ally(dest)
    return self:get_team_id() == dest:get_team_id()
end

-- 获取队伍
function mt:get_team()
    local id = self:get_team_id()
    return base.team(id)
end

--是否是敌人
--	对方单位(玩家)
function mt:is_enemy(dest)
    return not self:is_ally(dest)
end

local ac_game = base.game
local ac_event_dispatch = base.event_dispatch
local ac_event_notify = base.event_notify

--发起事件
function mt:event_dispatch(name, ...)
    local res, arg = ac_event_dispatch(self, name, ...)
    if res ~= nil then
        return res, arg
    end
    local player = self:get_owner()
    if player then
        local res, arg = ac_event_dispatch(player, name, ...)
        if res ~= nil then
            return res, arg
        end
    end
    local res, arg = ac_event_dispatch(ac_game, name, ...)
    if res ~= nil then
        return res, arg
    end
    return nil
end

function mt:event_notify(name, ...)
    ac_event_notify(self, name, ...)
    local player = self:get_owner()
    if player then
        ac_event_notify(player, name, ...)
    end
    local cache = base.eff.cache(self:get_name())
    if cache then
        ac_event_notify(cache, name, ...)
    -- else
    --     print('获取不到单位的cache')
    end
    ac_event_notify(ac_game, name, ...)
end

--资源类型
local resource_attribute_cache = setmetatable({}, {__index = function(self, type)
    local tbl = {type}
    for attribute in pairs(base.table.constant['单位属性']) do
        local r_attribute, n = attribute:gsub('魔法', type)
        if n > 0 then
            tbl[r_attribute] = attribute
            tbl[r_attribute .. '%'] = attribute .. '%'
        end
    end
    self[type] = tbl
    return tbl
end})

local function resource_attribute(self)
    if not self._resource_attribute then
        self._resource_attribute = resource_attribute_cache[self:get_data().ResourceType]
    end
    return self._resource_attribute
end

function mt:get_resource_type()
    return resource_attribute(self)[1]
end

--资源相关
function mt:add_resource(in_type, value)
    local type = resource_attribute(self)[in_type]
    if type then
        self:add(type, value)
    end
end

function mt:get_resource(in_type)
    local type = resource_attribute(self)[in_type]
    if type then
        return self:get(type)
    else
        return 0
    end
end

function mt:set_resource(type, value)
    local type = resource_attribute(self)[type]
    if type then
        self:set(type, value)
    end
end

--获取数据表
function mt:get_data()
    return base.table.unit[self:get_name()]
end

mt.wait = base.uwait
mt.loop = base.uloop
mt.timer = base.utimer

function mt:stop_cast()
    local skill = self:current_skill()
    if skill then
        skill:stop()
    end
end

function mt:stop_skill()
    local skill = self:current_skill()
    if skill and skill:is_skill() then
        skill:stop()
    end
end

function mt:stop_attack()
    local skill = self:current_skill()
    if skill and not skill:is_attack() then
        skill:stop()
    end
end

function mt:get_walk_target()
    local _, target = self:get_walk_command()
    return target
end

---comment
---@param target Unit|Point
---@param link string
---@param cache_override table?
---@return CmdResult
function mt:execute_on(target,link, cache_override)
    local ref_param=base.eff_param:new(true)
    ref_param:init(self,target)
    ref_param:set_cache(link)
    if ref_param.cache and cache_override then
        for key, value in pairs(ref_param.cache) do
            if not cache_override[key] then
                cache_override[key] = value
            end
        end
        ref_param.cache = cache_override
    end
    if not ref_param.cache then
        return base.eff.e_cmd.OK
    end
    return base.eff.execute(ref_param)
end

---comment
---@param target Point
---@param link string
---@param cache_override table?
---@return CmdResult
function mt:execute_on_point(target,link, cache_override)
    return self:execute_on(target, link, cache_override)
end

function mt:get_unit()
    return self
end

---comment
---@param dest Player
---@return boolean
function mt:is_visible_to(dest)
    return self:is_visible(dest)
end

function mt:get_snapshot()
	local snapshot=base.snapshot:new()
	snapshot.origin_type='unit'
	snapshot.name=self:get_name()
	snapshot.player=self:get_owner()
	snapshot.point=self:get_point():copy_to_scene_point(self:get_scene_name())
	snapshot.facing=self:get_facing()
    return snapshot
end

---comment
---@param label string
function mt:has_label(label)
    local unit_cache = base.eff.cache(self:get_name()) or base.table.UnitData[self:get_name()]
    local t = unit_cache.Filter
    if not t then
        return false
    end
    for _, value in pairs(t) do
        if value == label then
            return true
        end
    end
    return false
end

---comment
function mt:get_radius()
    return mt:get_attackable_radius()
end

function mt:is_unit_buff_enabled(buff_id)
    if (not buff_id) or (#buff_id == 0) then
        return nil
    end

    if not self.disabled_counts_buff then
        self.disabled_counts_buff = {}
    end

    if not self.disabled_counts_buff_category then
        self.disabled_counts_buff_category = {}
    end

    local cache  = base.eff.cache(buff_id)
    local disabled_count_total = 0
    local count = self.disabled_counts_buff[buff_id]
    if count then
        disabled_count_total = disabled_count_total + count
    end
    for _, category in ipairs(cache.Categories) do
        local it_count = self.disabled_counts_buff_category[category]
        if it_count then
            disabled_count_total = disabled_count_total + it_count
        end
    end
    return disabled_count_total <= 0
end

function mt:update_unit_buffs()
    for _, value in pairs(self.unit_buff_instances) do
        value:update_state()
    end
end

---comment
---@return EffectParam
function mt:get_creation_param()
    if not self.ref_param then
        if not self._parent_param then
            self.ref_param = base.eff_param:new(true)
            self.ref_param:init(self,self)
            self.ref_param.result = base.eff.e_cmd.OK
        else
            self.ref_param = self._parent_param:create_child()
            self.ref_param:init(self._parent_param.source,self)
            self.ref_param.result = base.eff.e_cmd.OK
        end
    end
    return self.ref_param
end

---comment
---@param target Target
---@return EffectParam
function mt:create_simple_param(target)
    local ref_param = base.eff_param:new(true)
    ref_param:init(self, target or self)
    ref_param.result = base.eff.e_cmd.OK
    return ref_param
end

---comment
---@param source_item Item
---@return EffectParam
function mt:create_item_param(source_item)
    local ref_param = base.eff_param:new(true)
    ref_param:init(self,self)
    ref_param.result = base.eff.e_cmd.OK
    if source_item then
        ref_param.shared:set_item(source_item)
    end
    return ref_param
end

function mt:on_response(response_type, location, in_param, ...)
    local creator = self:creator():get_unit()

    if creator ~= self then
        creator:on_response_creator(response_type, location, in_param, ...)
    end
    
    if not self.response or not self.response[response_type] or not self.response[response_type][location] then
        return
    end

    ---@type Response Description
    for _, response in ipairs(self.response[response_type][location]) do
        response:execute(in_param, ...)
    end
end

function mt:on_response_creator(response_type, location, in_param, ...)
    if not self.response or not self.response[response_type] or not self.response[response_type][location] then
        return
    end

    ---@type Response Description
    for _, response in ipairs(self.response[response_type][location]) do
        if response.cache.ApplyToSummoned then
            response:execute(in_param, ...)
        end
    end
end

function mt:on_response_simple(response_type, other, ...)
    local location = base.response.e_location.Attacker

    local creator = self:creator():get_unit()
    if creator ~= self then
        creator:on_response_creator(response_type, location, ref_param, ...)
    end

    if not self.response or not self.response[response_type] or not self.response[response_type][location] then
        return
    end
    local ref_param = self:create_simple_param(other)
    ---@type Response Description
    for _, response in ipairs(self.response[response_type][location]) do
        response:execute(ref_param, ...)
    end
end

---comment
---@param buff_link string
---@param stack integer
---@param source_item Item|nil
---@param params table|nil
---@return Buff
function mt:add_buff_new(buff_link, stack, source_item, params)
    local ref_param = self:create_item_param(source_item)
    if ref_param then
        local child_param = ref_param:add_buff(self, buff_link, stack, params)
        if child_param.buff_data then
            return child_param.buff_data.buff
        end
    end
end

---comment
---@param target Unit
---@param amount number
---@param params table?
---@param damage_type string
function mt:do_trigger_damage(target, amount, damage_type, params)
    local ref_param = self:get_creation_param()
    ref_param:damage(target,amount,damage_type, params)
end

function mt:attach_to(target, socket) -- 只允许unit attach_to unit
    if target.type == 'unit' then
        base.rpc.call_all({
            method = 'attach_to',
            cls = 'unit',
            args = {self:get_id(), target:get_id(), socket}
        })
    else
        log.warn('unit can only attach to unit.')
    end
end

function mt:create_inventorys()
    local link = self:get_name()
    local cache = base.eff.cache(link)
    if cache and cache.Inventorys then
        for _, value in ipairs(cache.Inventorys) do
            self:create_inventory(value)
        end
    end
end

---comment
---@param remove boolean
function mt:destroy_inventorys(remove)
    if remove then
        self.inventorys = nil
    else
        self.inventorys = {}
    end
end

function mt:create_responses()
    local link = self:get_name()
    local cache = base.eff.cache(link)
    if not cache or not cache.Responses then
        return
    end
    for _, response_link in ipairs(cache.Responses) do
        self:create_response(response_link)
    end
end

function mt:create_restrictions()
    local link = self:get_name()
    local cache = base.eff.cache(link)
    if not cache or not cache.Restrictions then
        return
    end
    for _, restriction in ipairs(cache.Restrictions) do
        self:add_restriction(restriction)
    end
end

--[[ function mt:create_ai()
    local link = self:get_name()
    local cache = base.eff.cache(link)
    if not cache or not cache.DefaultAI or #cache.DefaultAI==0 then
        return
    end
    if cache.DefaultAI == '召唤物' then
        local creator =  self:creator():get_unit()
        if creator and creator ~= self then
            self:add_ai(cache.DefaultAI){
                master = creator,
                stay_time = cache.stay_time,
                distance_random = cache.distance_random,
                follow_random = cache.follow_random,
            }
        end
    end
end ]]

function mt:creator()
    if not self._parent_param then
        return self
    end
    return self._parent_param:caster()
end

local target_type = {
    TARGET_TYPE_NONE			= 0,		--无目标
    TARGET_TYPE_UNIT			= 1,		--单位目标
    TARGET_TYPE_POINT			= 2,		--地面目标
    TARGET_TYPE_UNIT_OR_POINT	= 3,		--单位或地面目标
    TARGET_TYPE_VECTOR			= 4,		--向量目标
    TARGET_TYPE_DRAG			= 5,		--拖动施法
}

---comment
---@param link string|Skill
---@param target Unit|Point|number|nil
---@param data table?
function mt:cast_request(link, target, data)
    local is_skill = instance_of(link, Skill)
    local cache = (is_skill and base.eff.cache(link:get_name())) or (not is_skill and base.eff.cache(link))
    local unit = self
    if cache then
        if cache.target_type ~= target_type.TARGET_TYPE_NONE and target == nil then
            if cache.AcquireSettings.Enabled then
                data = data or {}
                data.is_smart_targeting = true
                local scene = unit:get_scene_name()
                if not scene then
                    log.debug('单位场景为空: '..tostring(unit))
                    return
                end
                local point = unit:get_point()
                local range = cache.Range
                range = cache.AcquireSettings.TargetUnitRange or range
                local group = point:get_point():group_range(range + unit:get_attackable_radius(), 'place_holder', scene, true)
                if #group == 0 then
                    if cache.target_type == target_type.TARGET_TYPE_VECTOR then
                        unit:cast_process(link, unit:get_facing(), data)
                    elseif cache.target_type == target_type.TARGET_TYPE_UNIT then
                        unit:error_info('附近没有有效的目标')
                        base.game:ui 'cancel_ignore_joy_stick' { id = self:get_id() }
                    else
                        unit:cast_process(link, unit:get_point(), data)
                    end
                    return
                end
                local group_out = {}
                local child_link = cache.Effect
                local target_filter = base.target_filters:new(cache.AcquireSettings.TargetUnitFilter)
                local validate_param = base.eff_param:new(true)
                validate_param:set_cache(child_link)
                local skill = (is_skill and link) or (not is_skill and unit:find_skill(link))
                if skill then
                    validate_param.shared:set_skill(skill)
                    validate_param.shared:set_level(skill:get_level())
                end
                for _, it_unit in ipairs(group) do
                    --先过滤
                    if target_filter:validate(unit,it_unit) == base.eff.e_cmd.OK then
                        --再验证
                        validate_param:init(unit, it_unit)
                        if base.eff.validate(validate_param, false) == base.eff.e_cmd.OK then
                            table.insert(group_out,it_unit)
                        end
                    end
                end

                if #group_out == 0 then
                    if cache.target_type == 4 then
                        unit:cast_process(link, unit:get_facing(), data)
                    elseif cache.target_type == 1 then
                        unit:error_info('附近没有有效的目标')
                        base.game:ui 'cancel_ignore_joy_stick' { id = self:get_id() }
                    else
                        unit:cast_process(link, unit:get_point(), data)
                    end
                    return
                end

                validate_param:unit_sorts(group_out, cache.AcquireSettings.TargetUnitSorts)
                target = group_out[1]
                local new_data = data or {}
                new_data.smart_target = target
                if cache.target_type == target_type.TARGET_TYPE_VECTOR then
                    local target_angle = unit:get_point():angle_to(target:get_point())
                    unit:cast_process(link, target_angle, new_data)
                elseif cache.target_type == target_type.TARGET_TYPE_UNIT or cache.target_type == target_type.TARGET_TYPE_UNIT_OR_POINT then
                    unit:cast_process(link, target, new_data)
                else
                    unit:cast_process(link, target:get_point(), new_data)
                end
            else
                if cache.target_type == target_type.TARGET_TYPE_VECTOR then
                    unit:cast_process(link, unit:get_facing(), data)
                elseif cache.target_type == target_type.TARGET_TYPE_UNIT then
                    unit:cast_process(link, unit, data)
                else
                    unit:cast_process(link, unit:get_point(), data)
                end
            end
            return
        end
        unit:cast_process(link, target, data)
        return
    end
    unit:cast_process(link, target, data)
end

function mt:cast_process(skill, target, data)
    local is_skill = instance_of(skill, Skill)
    if data then
        local cur = self:current_skill()
        local is_same_skill = cur and ((not is_skill and cur.__name == skill) or (is_skill and cur:is(skill)))
        if is_same_skill then
            local stage = cur:get_stage()
            ---对于用户发布的技能，同技能id、同目标，且在前三阶段的，视为重复指令，予以忽略
            if stage >= 1 and stage <= 2 then
                local cur_target = cur:get_target()
                if target == cur_target
                or (data.is_smart_targeting and cur.is_smart_targeting)
                or (type(target) == "number" and base.math.abs(cur_target - target) < 15)
                or (
                    type(target) == "table"
                    and target[1] and target[2]
                    and base.math.abs(target[1] - cur_target[1]) < 5
                    and base.math.abs(target[2] - cur_target[2]) < 5
                )
                then
                    return false
                end
            end
        end
    end
    return self:cast(skill, target, data)
end


---comment
---@param target Target
---@param tt integer
---@return Target|number|nil
function mt:get_effect_target(target, tt)
    if tt == target_type.TARGET_TYPE_NONE then
        return nil
    elseif tt == target_type.TARGET_TYPE_VECTOR then
        if not target or not target:get_point() then
            return self:get_facing()
        else
            return self:get_point():angle_to(target:get_point())
        end
    elseif target == nil then
        return nil
    elseif tt == target_type.TARGET_TYPE_UNIT then
        return target:get_unit()
    elseif tt == target_type.TARGET_TYPE_POINT then
        return target:get_point()
    else
        return target
    end
end

function mt:cast_effect_target(link, target, data)
    local success = false
    ---@type Skill
    for skill in self:each_skill() do
        if skill and skill.cache.Link == link then
            local target_real = self:get_effect_target(target,skill.target_type)
            if skill:can_cast(target_real) == 0 then
                self:cast(skill, target_real, data)
                success = true
                break
            end
        end
    end
    return success
end

function mt:attack_effect_target(target, data)
    local success = false
    ---@type Skill
    for skill in self:each_skill() do
        if skill:is_attack() then
            local target_real = self:get_effect_target(target,skill.target_type)
            if skill:can_cast(target_real) == 0 then
                self:cast(skill, target_real, data)
                success = true
                break
            end
        end
    end
    return success
end

---comment
---@param remove boolean
function mt:destroy_responses(remove)
    if remove then
        self.inventorys = nil
    else
        self.inventorys = {}
    end
end

---comment
---@param response_link string
function mt:create_response(response_link)
    local it_response = base.response:new(response_link)
    if it_response then
        it_response:add(self, self:get_creation_param())
    end
end

function mt:create_actors()
    local link = self:get_name()
    local cache = base.eff.cache(link)
    if cache and cache.ActorArray and #cache.ActorArray then
        self.actors = self.actors or {}
        for _, value in ipairs(cache.ActorArray) do
            self:create_actor(value)
        end
    end
end

---comment
---@param link string
---@param ignore_unit_list boolean
---@return Actor
function mt:create_actor(link, ignore_unit_list)

    local ref_param = self:get_creation_param()
    local actor = ref_param:create_actor(link)
    if actor and not ignore_unit_list then
        table.insert(self.actors, actor)
    end
    return actor
end

---comment
---@param remove boolean
function mt:destroy_actors(remove)
    if self.actors and type(self.actors) == "table" then
        for _, actor in ipairs(self.actors) do
            actor:destroy(false);
        end
        if remove then
            self.actors = nil
        else
            self.actors = {}
        end
    end
end

---@class ProvokeResponseFlag
---@field Acquire boolean
---@field Flee boolean

---使有AI的单位在被效果命中时做出反击或者逃跑反应的函数
---目前默认情况下数据编辑器里的发射弹道效果、伤害效果、添加buff效果都会call当前函数。其它效果可以通过勾选标志来call当前函数
---@param provoker any
---@param flags ProvokeResponseFlag
function mt:on_provoke(provoker, flags)
    --只有敌对关系时才作出反应。
    if not provoker or (not self:is_enemy(provoker)) then
        return
    end

    -- print('TODO: on_provoke')
    -- --TODO: 在此调用单位身上对应ai的反应函数。预期ai对此的的反应：
    -- --flags.Acquire == true 会尝试寻找并且攻击provoker单位，除非无法抵达provoker的位置或者没有可以用来攻击provoker单位的技能。
    -- --flags.Flee == true 会尝试跑往provoker单位的反方向一段距离。若同时有flag.Acquire，则会先尝试攻击provoker，若无法攻击provoker（比如目标无敌），则选择逃跑。
    -- --目前我们数据编辑器中所有效果默认都不勾上Flee。但用户可以手动勾上。
    -- --没有ai的单位不应该作出反应。
    -- --如果ai已经在战斗，也可以不作出反应（具体可以由AI自己决定）。

    if not self.ai then
        return
    end
    if self.ai.provoke then
        self.ai:provoke(provoker, flags.Acquire, flags.Flee)
    end
end

---comment
---@return boolean
function mt:is_item()
    local item = self.item
    if not item then
        return false
    end
    return item.type == 'item'
end

---comment
---@return boolean
function mt:has_item(id)
    if not self.inventorys then
        return false
    end
    for _, it_inventory in ipairs(self.inventorys) do
        for _, it_slot in ipairs(it_inventory.slots or {}) do
            if it_slot.item and it_slot.item.link == id then
                return true
            end
        end
    end
    return false
end

---comment
---@return table
function mt:all_items()
    local result = {}
    if not self.inventorys then
        return result
    end
    for _, it_inventory in ipairs(self.inventorys) do
        for _, it_slot in ipairs(it_inventory.slots or {}) do
            if it_slot.item then
                table.insert(result,it_slot.item)
            end
        end
    end
    return result
end

---comment
---@return table
function mt:get_inventory_items(index)
    local result = {}
    if not self.inventorys then
        return result
    end
    local inventory = self.inventorys[index]
    if not inventory then
        return result
    end
    for _, it_slot in ipairs(inventory.slots or {}) do
        if it_slot.item then
            table.insert(result,it_slot.item)
        end
    end
    return result
end

---comment
---@param link string
---@return Inventory
function mt:create_inventory(link)
    return base.inventory:new(link, self)
end

---comment
---@param item Item
---@return boolean can_do
---@return Inventory? inventory
---@return Slot? slot
---@return number? remaing
function mt:can_hold(item)
    if item.removed then
        return false
    end

    --直接吃掉的物品并且生效的物品，不在物品栏占据空间
    if item.cache and item.cache.NodeType == 'ItemPowerUp' then
        local target_filter = base.target_filters:new(item.cache.Filter)
        if target_filter:validate(self, self) ~= base.eff.e_cmd.OK then
            return false
        end
        if item.cache.Effect then
           local effect_cache = base.eff.cache(item.cache.Effect)
           if effect_cache then
            local ref_param = base.eff_param:new(true)
            ref_param:init(self, item.unit)
            ref_param:set_cache(item.cache.Effect)
            return base.eff.validate(ref_param) == base.eff.e_cmd.OK
           end
        end
        return true
    end
    if not self.inventorys then
        return false
    end
    ---@type Inventory Description
    for _, it_inventory in ipairs(self.inventorys) do
        local result, it_slot, remaining = it_inventory:can_hold(item)
        if result then
            return true, it_inventory, it_slot, remaining
        end
    end
    return false
end

local e_inv_prop_name = 'sys_inv_items'

function mt:sync_inv_items()
    if self.inv_item_ids then
        self:set(e_inv_prop_name, self.inv_item_ids)
    end
end


local  trig_loot = base.trig:new(function (_, e)
    if not e.unit then
        return
    end
    if e.type == 2 then
        return
    end
    e.unit:drop_loot(e.killer)
end, true)

---comment
---@param loot_link string
function mt:set_loot(loot_link)
    self.loot = loot_link

    if not loot_link or #loot_link == 0 then
        return
    end

    trig_loot:add_event(self, '单位-死亡')
end

---comment
---@param killer Unit
function mt:drop_loot(killer, loot_link)
    if not loot_link or #loot_link == 0 then
        loot_link = self.loot
    end
    if not loot_link or #loot_link == 0 then
        return
    end

    if not killer then
        killer = self
    end

    self:execute_on(killer, loot_link)
end

---comment
---@param target Unit
function mt:grant_loot(loot_link,target)
    if not loot_link or #loot_link == 0 then
        return
    end

    if not target then
        target = self
    end

    self:execute_on(target, loot_link)
end

function mt:remove_item()
    if self:is_item() then
        self.item:remove()
    end
end

local add_property = { }

---comment
---@param prop string
---@param value number
---@param is_percentage boolean
function mt:add_property(prop, value, is_percentage)
    local m_type = is_percentage and 2 or 1
    if add_property[prop] then
        add_property[prop](self, value, m_type)
    end
    self:add_ex(prop, value, m_type)
end

function mt:set_table_attr(key, value)
    if type(value) == 'table' then
        local sync_table = base.check_sync_table(value)
        local normal_table = base.sync_table_to_normal(value)
        self:set_table(key, normal_table, sync_table)
    else
        error("set_table_attr 参数value需要是一个表", 2)
    end
end

function mt:get_table_attr(key)
    local value = self:get_table(key)
    if type(value) == 'table' then
        value = base.modify_table_to_sync(value)
    end
    return value
end

---comment
---@param value number
---@param label string?
function mt:set_scale(value, label)
    self._scaling_labels = self._scaling_labels or {}
    label = label or ''
    if (value == 1) then
        self._scaling_labels[label] = nil
    else
        self._scaling_labels[label] = value
    end
    local amount = 1
    for _, val in pairs(self._scaling_labels) do
        amount = amount * val
    end
    self:set_model_attribute('缩放', amount)
end

function mt:clear_scale(label)
    if not self._scaling_labels then
        return
    end
    if not self._scaling_labels[label] then
        return
    end
    self._scaling_labels[label] = nil
    local amount = 1
    for _, val in pairs(self._scaling_labels) do
        amount = amount * val
    end
    self:set_model_attribute('缩放', amount)
end

function mt:clear_scale_all()
    if self._scaling_labels then
        self:set_model_attribute('缩放', 1) 
        self._scaling_labels = nil
    end
end

mt._statemachines = {}
function mt:get_or_create_state_machine(name, sync)
    if self._statemachines[name] then
        return self._statemachines[name], false
    end
    local sm = self:add_state_machine(name, sync or false)
    if sm then
        self._statemachines[name] = sm
    end
    return sm, true
end

--- 初始化单位属性和死亡掉落
---@param unit Unit
---@param node_mark string
---@param unit_attribute table
function base.init_unit(unit, node_mark, unit_attribute)
    for key, value in pairs(unit_attribute) do
        if key == '掉落' then
            unit:set_loot(value)
        else
            unit:set(key, tonumber(value))
        end
    end
end

base.get_default_unit = base.game.get_default_unit

return {
    Unit = Unit
}