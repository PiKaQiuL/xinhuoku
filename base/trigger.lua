---@class Trigger
---@field remove fun()
---@field events Event[]
---@field callback function

local setmetatable = setmetatable
local table = table
local trigger_map = setmetatable({}, { __mode = 'kv' })
local scene_manager = require 'base.game.scene'

Trigger = Trigger or base.tsc.__TS__Class()
Trigger.name = 'Trigger'

---@type Trigger
local mt = Trigger.prototype

---@type Trigger
base.trig = mt

--结构
mt.type = 'trigger'

--是否允许
mt.enable_flag = true

mt.sign_remove = false

--事件
mt.event = nil

if base.test then
    function mt:__tostring()
        return ('[table:trigger:%X]'):format(base.test.topointer(self))
    end
else
    function mt:__tostring()
        return '[table:trigger]'
    end
end

--禁用触发器
function mt:disable()
    self.enable_flag = false
end

function mt:enable()
    self.enable_flag = true
end

function mt:is_enable()
    return self.enable_flag
end

--运行触发器
function mt:__call(...)
    if self.sign_remove then
        return
    end
    if self.enable_flag then
        return self:callback(...)
    end
end

--摧毁触发器(移除全部事件)
function mt:remove()
    if not self.events then
        return
    end
    trigger_map[self] = nil
    local events = self.events
    self.events = nil
    base.wait(0, function()
        for _, event in ipairs(events) do
            for i, trg in ipairs(event) do
                if trg == self then
                    table.remove(event, i)
                    break
                end
            end
            if #event == 0 then
                if event.remove then
                    event:remove()
                end
            end
        end
    end)
    local scene_events = self.scene_events
    self.scene_events = nil
    if scene_events then
        base.wait(0, function()
            for _, event in ipairs(scene_events) do
                for i, trg in ipairs(event) do
                    if trg == self then
                        table.remove(event, i)
                        break
                    end
                end
                if #event == 0 then
                    if event.remove then
                        event:remove()
                    end
                end
            end
        end)
    end

    self.sign_remove = true
end

function base.each_trigger()
    return pairs(trigger_map)
end

--创建触发器
--旧方案，不要再使用
function base.trigger(event, callback)
    local trg = setmetatable({callback = callback, events={} }, mt)
    if event then
        table.insert(event, trg)
        table.insert(trg.events, event)
    end
    trigger_map[trg] = true
    return trg
end

---通过函数创建一个新的触发器
---@param action function
---@param combine_args boolean
---@return Trigger
function base.trig:new(action, combine_args, scene)
    local trg = setmetatable({callback = action, events = {}, combine_args = combine_args, scene = scene}, self.__index)
    trigger_map[trg] = true
    return trg
end

function mt:add_event(obj, name, custom_event)
    if not obj then
        log.error('event object is nil')
        return
    end
    if self.scene and self.combine_args then
        self:_add_scene_event(obj, name, custom_event)
    else
        if type(obj) == 'function' then
            obj = obj()
        end
        self:_add_event(obj, name, custom_event)
    end
end

function mt:_add_scene_event(obj, name, custom_event)
    -- if circle_check(obj) or rect_check(obj) then
    --     if obj.init_region and type(obj.init_region) == 'function' then
    --         obj:init_region()
    --     end
    -- end

    if not obj then
        log.error('event object is nil')
        return
    end
    local events_delegate = scene_manager.get_obj_scene_events(self.scene, obj)
    local event_delegate = events_delegate[name]

    if not event_delegate then
        event_delegate = {}
        events_delegate[name] = event_delegate
        -- local ac_event = base.event_subscribe_list[name] or name
        -- if obj.event_subscribe then
        --     obj:event_subscribe(ac_event)
        -- end
    end

    if event_delegate then
        table.insert(event_delegate, self)
        self.scene_events = self.scene_events or {}
        local existed = false
        for i = 1, #self.scene_events do
            if self.scene_events[i] == event_delegate then
                existed = true
            end
        end
        if not existed then
            table.insert(self.scene_events, event_delegate)
        end
        event_delegate.custom_event = custom_event
    end
    if scene_manager.is_scene_activated(self.scene) then
        self:_add_event(obj, name, custom_event)
    end
end

---comment
---@param obj table
---@param name string
function mt:_add_event(obj, name, custom_event)
    if not obj then
        log.error('event object is nil, can not add event')
        return
    end

    if circle_check(obj, true) or rect_check(obj, true) then
        if obj.init_region and type(obj.init_region) == 'function' then
            obj:init_region()
        end
    end

    local events_delegate = obj._events
    if not events_delegate then
        events_delegate = {}
        obj._events = events_delegate
    end

    local event_delegate = events_delegate[name]

    if not event_delegate then
        event_delegate = {}
        events_delegate[name] = event_delegate
        local ac_event = base.event_subscribe_list[name] or name
        if obj.event_subscribe then
            obj:event_subscribe(ac_event)
        end
    end

    if event_delegate then
        table.insert(event_delegate, self)
        --- 同一个触发有同一个obj的同一个事件（理论上应该不允许），这里可能会加重
        local existed = false
        for i = 1, #self.events do
            if self.events[i] == event_delegate then
                existed = true
            end
        end
        if not existed then
            table.insert(self.events, event_delegate)
        end
        event_delegate.custom_event = custom_event
    end
end

function mt:_remove_event(obj, name)
    if not obj then
        log.error('event object is nil, can not remove event')
        return
    end
    local events_delegate = obj._events
    if not events_delegate then
        return
    end

    local event_delegate = events_delegate[name]

    if not event_delegate then
        return
    end

    for i = #event_delegate, 1, -1 do
        if event_delegate[i] == self then
            table.remove(event_delegate, i)
        end
    end
    event_delegate.custom_event = custom_event
end

local event_game_timer = '计时器-游戏时间'

local is_playing = (base.game:status() >= 4 and base.game:status() <= 6)

local pending_game_timers = {}


base.game:event('游戏-加载场景', function(_, game, scene)
    scene_manager.set_scene_activated(scene)
end)

base.game:event('游戏-阶段切换', function()
	if not is_playing and (base.game:status() >= 4 and base.game:status() < 6) then
        is_playing = true
        for _, value in ipairs(pending_game_timers) do
            value.trg:add_event_game_time_internal(value.time, value.periodic)
        end
        -- for _, value in ipairs(pending_game_units) do
        --     local default_unit = base.game.get_default_unit(value.node_mark)
        --     if default_unit and type(default_unit) ~= 'string' then
        --         value.trg:add_event(default_unit, value.event_name)
        --     end
        -- end
	end
end)
base.game:event('游戏-属性变化', function(trigger, game, key, value)
    base.game:event_notify('游戏-字符串属性变化', game, key, value)
end)

base.game:event('玩家-属性变化', function(trigger, player, key, value, change_value)
    if base.table.constant['玩家属性'] then
        for k, id in pairs(base.table.constant['玩家属性']) do
            if id == key then
                if type(value) == 'number' then
                    base.game:event_notify('玩家-数值属性变化', player, k, value, change_value)
                elseif type(value) == 'string' then
                    base.game:event_notify('玩家-字符串属性变化', player, k, value)
                end
                break
            end
        end
    end
end)

base.game:event('单位-属性变化', function(trigger, unit, key, value, change_value)
    if not unit then
        return
    end
    if base.table.constant['单位属性'] then
        for k, id in pairs(base.table.constant['单位属性']) do
            if id == key then
                if type(value) == 'number' then
                    unit:event_notify('单位-数值属性变化', unit, k, value, change_value)
                elseif type(value) == 'string' then
                    unit:event_notify('单位-字符串属性变化', unit, k, value)
                end
                break
            end
        end
    end
end)
---comment
---@param periodic boolean
---@param time number
function mt:add_event_game_time(time, periodic)
    if is_playing then
        self:add_event_game_time_internal(time, periodic)
    else
        table.insert(pending_game_timers, {trg = self, time = time, periodic = periodic})
    end
end

---comment
---@param periodic boolean
---@param time number
function mt:add_event_game_time_internal(time, periodic)
    local count = 1
    if periodic then
        count = 0
    end
    local timer = base.timer(time * 1000, count, function (timer)
        -- log.info(self.time, self.scene, scene_manager.is_scene_activated(self.scene))
        if is_playing and check_event_scene(self) then
            base.event_notify(timer, event_game_timer)
            if not periodic then
                timer = nil
            end
        end
    end)
    self:_add_event(timer, event_game_timer)
end

---comment
---@param action function
function mt:set_action(action)
    self.callback = action
end

---@class Event
---@field remove fun()


base.trig.event = {}

---@type Event
local evt = base.trig.event
evt.evt_args = {}
local args = evt.evt_args


---TODO: 移除damage的概念，所有的伤害都应该通过伤害效果造成。
---@class Damage
---@field damage number
---@field fatal boolean
---@field current_damage number
---@field damage_type string
---@field source string
---@field target string


---通用事件参数类型
---@class EventArgs
---@field sender table
---@field trig Trigger

---comment
---@param obj table
---@param evt_name string
---@return EventArgs
function args.event(obj, evt_name)
    return { sender = obj, evt_name = evt_name }
end

---单位事件参数类型，大部分只有一个参数的单位事件可以共用
---@class UnitEventArgs:EventArgs
---@field unit Unit

---comment
---@param obj table
---@param evt_name string
---@param unit Unit
---@return UnitEventArgs
function args.event_unit(obj, evt_name, unit)
    ---@type UnitEventArgs Description
    local e = args.event(obj, evt_name)
    e.unit = unit
    return e
end

---@class UnitDieEventArgs:UnitEventArgs
---@field killer Unit

---comment
---@param obj table
---@param evt_name string
---@param unit Unit
---@param killer Unit
---@return UnitDieEventArgs
function args.event_unit_die(obj, evt_name, unit, killer, type)
    ---@type UnitDieEventArgs Description
    local e = args.event_unit(obj, evt_name, unit)
    e.killer = killer
    e.type = type
    return e
end

---@class UnitDamagedEventArgs:UnitEventArgs
---@field ref_param EffectParam
---@field damage Damage
---@field amount number
---@field damage_source Unit
---@field damage_target Unit

--伤害事件
function args.event_unit_damage_dealt(obj, evt_name, damage)
    ---@type UnitDamagedEventArgs Description
    local e = args.event(obj, evt_name)
    e.damage = damage
    e.amount = damage.damage

    e.unit = damage.source

    e.damage_source = damage.source
    e.damage_target = damage.target

    if damage.ref_param and damage.ref_param.type == 'eff_param' then
        e.ref_param = damage.ref_param
    end

    return e
end

--伤害事件
function args.event_unit_damage_taken(obj, evt_name, damage)
    ---@type UnitDamagedEventArgs Description
    local e = args.event(obj, evt_name)
    e.damage = damage
    e.amount = damage.damage

    e.unit = damage.target

    e.damage_source = damage.source
    e.damage_target = damage.target

    if damage.ref_param and damage.ref_param.type == 'eff_param' then
        e.ref_param = damage.ref_param
    end

    return e
end

---@class UnitBuffEventArgs:UnitEventArgs
---@field buff Buff

function args.event_unit_buff(obj, evt_name, unit, buff)
    ---@type UnitBuffEventArgs Description
    local e = args.event_unit(obj, evt_name, unit)
    e.buff = buff
    return e
end

---@class UnitPurchaseItemEventArgs:UnitEventArgs
---@field item_name string

function args.event_unit_purchase_item(obj, evt_name, unit, item_name)
    ---@type UnitPurchaseItemEventArgs Description
    local e = args.event_unit(obj, evt_name, unit)
    e.item_name = item_name
    return e
end

---@class UnitInventoryEventArgs:UnitEventArgs
---@field slot integer

function args.event_unit_inventory(obj, evt_name, unit, slot)
    ---@type UnitInventoryEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.slot = slot
    return e
end

---@class UnitInventoryTargetEventArgs:UnitInventoryEventArgs
---@field target Target

function args.event_unit_inventory_target(obj, evt_name, unit, slot, target)
    ---@type UnitInventoryTargetEventArgs
    local e = args.event_unit_inventory(obj, evt_name, unit, slot)
    e.target = target
    if target then
        e.target_unit = target:get_unit()
        e.target_point = target:get_point()
    end
    return e
end

---@class UnitItemEventArgs:UnitEventArgs
---@field item Item

function args.event_unit_item(obj, evt_name, unit, item)
    ---@type UnitItemEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.item = item
    return e
end


---@class UnitItemAbsorbEventArgs:UnitItemEventArgs
---@field item_source Item
---@field stack_offset integer

function args.event_unit_item_absorb(obj, evt_name, unit, item, item_source, stack_offset)
    ---@type UnitItemAbsorbEventArgs
    local e = args.event_unit_item(obj, evt_name, unit, item)
    e.item_source = item_source
    e.stack_offset = stack_offset
    return e
end

---@class UnitItemEventArgs:UnitEventArgs
---@field item Item

function args.event_unit_loot(obj, evt_name, unit, ref_param)
    ---@type UnitItemEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.ref_param = ref_param
    local cache = ref_param.cache
    local loot_id = cache and cache.Link or ''
    e.loot_id = loot_id
    return e
end

---@class UnitCmdRequestEventArgs:UnitEventArgs
---@field command string
---@field target Target
---@field key_modifier integer

function args.event_unit_cmd_request(obj, evt_name, unit, command, target, key_modifier)
    ---@type UnitCmdRequestEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.command = command
    e.target = target
    if target then
        e.target_unit = target:get_unit()
        e.target_point = target:get_point()
    end
    e.key_modifier = key_modifier
    return e
end

---@class UnitMovedEventArgs:UnitEventArgs
---@field pos_old Point
---@field pos_new Point

function args.event_unit_moved(obj, evt_name, unit, pos_old, pos_new)
    ---@type UnitMovedEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.pos_old = pos_old
    e.pos_new = pos_new
    return e
end

--[[
---@class UnitLanedEventArgs:UnitEventArgs
---@field vector_z number

function args.event_unit_laned(obj, evt_name, unit, vector_z)
    ---@type UnitLanedEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.vector_z = vector_z
    return e
end
]]--

---@class UnitSkillEventArgs:UnitEventArgs
---@field skill Skill

function args.event_unit_skill(obj, evt_name, unit, skill)
    ---@type UnitSkillEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.skill = skill
    return e
end

---@class UnitSkillCastEventArgs:UnitEventArgs
---@field skill_id string
---@field target_unit_cast Unit
---@field target_point_cast Point

---comment
---@param obj any
---@param unit Unit
---@param skill Cast
---@return UnitSkillCastEventArgs
function args.event_unit_skill_stage(obj, evt_name, unit, skill)
    ---@type UnitSkillCastEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    if skill then
        e.skill_id = skill.__name
        local target = skill:data_driven_target()
        e.target_point_cast = target:get_point()
        e.target_unit_cast = target:get_unit()
    end
    return e
end

---@class UnitSkillResultEventArgs:UnitSkillEventArgs
---@field result_code integer

function args.event_unit_skill_result(obj, evt_name, unit, skill, result_code)
    ---@type UnitSkillResultEventArgs
    local e = args.event_unit_skill(obj, evt_name, unit, skill)
    e.result_code = result_code
    return e
end


---TODO: 需要针对xp_data操作的特殊函数
---@class UnitXPEventArgs:UnitEventArgs
---@field xp table

function args.event_unit_xp(obj, evt_name, xp_data)
    ---@type UnitXPEventArgs
    local e = args.event(obj, evt_name)
    e.unit = xp_data.hero
    e.xp = xp_data.exp
    return e
end

---@class UnitMoverEventArgs:UnitEventArgs
---@field mover Mover

function args.event_unit_mover(obj, evt_name, unit, mover)
    ---@type UnitMoverEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.mover = mover
    return e
end

---@class UnitSceneEventArgs:UnitEventArgs
---@field scene_name string

function args.event_unit_scene(obj, evt_name, unit, scene_name)
    ---@type UnitSceneEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.scene_name = scene_name
    return e
end

---@class Area

---@class AreaEventArgs:UnitEventArgs
---@field area Area

function args.event_area(obj, evt_name, area, unit)
    ---@type AreaEventArgs
    local e = args.event_unit(obj, evt_name, unit)
    e.area = area
    return e
end

---@class PlayerEventArgs:EventArgs
---@field player Player

---@param player Player
function args.event_player(obj, evt_name, player)
    ---@type PlayerEventArgs
    local e = args.event(obj, evt_name)
    e.player = player
    return e
end

---@class PlayerUnitEventArgs:PlayerEventArgs
---@field unit Unit

---@param player Player
---@param unit Unit
function args.event_player_unit(obj, evt_name, player, unit)
    ---@type PlayerEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.unit = unit
    return e
end

---@class PlayerConnectEventArgs:PlayerEventArgs
---@field is_reconnect boolean

---@param player Player
function args.event_player_connect(obj, evt_name, player, is_reconnect)
    ---@type PlayerConnectEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.is_reconnect = is_reconnect
    return e
end


---@class PlayerChatEventArgs:PlayerEventArgs
---@field msg string

function args.event_player_chat(obj, evt_name, player, msg)
    ---@type PlayerChatEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.msg = msg
    return e
end


---@class PlayerPickHeroEventArgs:PlayerEventArgs
---@field hero_name string

function args.event_player_pick_hero(obj, evt_name, player, hero_name)
    ---@type PlayerPickHeroEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.hero_name = hero_name
    return e
end

---@class PlayerSceneEventArgs:PlayerEventArgs
---@field scene_name string

function args.event_player_scene(obj, evt_name, player, scene_name)
    ---@type PlayerSceneEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.scene_name = scene_name
    return e
end

---@class PlayerConfigEventArgs:PlayerEventArgs
---@field config string

function args.event_player_config(obj, evt_name, player, config)
    ---@type PlayerConfigEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.config = config
    return e
end

---@class PlayerPingEventArgs:PlayerEventArgs
---@field ping table

function args.event_player_ping(obj, evt_name, player, ping)
    ---@type PlayerPingEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.ping = ping
    return e
end

---@class PlayerKeyDownEventArgs:PlayerEventArgs
---@field key string

function args.event_player_key_down(obj, evt_name, player, key)
    ---@type PlayerKeyDownEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.key = key
    e.key_keyboard = key
    return e
end

---@class PlayerKeyUpEventArgs:PlayerEventArgs
---@field key string

function args.event_player_key_up(obj, evt_name, player, key)
    ---@type PlayerKeyUpEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.key = key
    e.key_keyboard = key
    return e
end

---@class PlayerMouseDownEventArgs:PlayerEventArgs
---@field mouse integer

function args.event_player_mouse_down(obj, evt_name, player, key)
    ---@type PlayerMouseDownEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.key = key
    return e
end

---@class PlayerMouseUpEventArgs:PlayerEventArgs
---@field mouse integer

function args.event_player_mouse_up(obj, evt_name, player, key)
    ---@type PlayerMouseUpEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.key = key
    return e
end

---@class PlayerWheelMoveEventArgs:PlayerEventArgs
---@field delta_whell number

function args.event_player_wheel_move(obj, evt_name, player, delta_wheel)
    ---@type PlayerWheelMoveEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.delta_wheel = delta_wheel
    return e
end

---@class PlayerClickComponentEventArgs:PlayerEventArgs
---@field component component

function args.event_player_click_component(obj, evt_name, player, component_label)
    ---@type PlayerWheelMoveEventArgs
    local e = args.event_player(obj, evt_name, player)
    e.component_label = component_label
    return e
end

---@class GameSceneEventArgs:EventArgs
---@field scene_name string

function args.event_game_scene(obj, evt_name, game, scene_name)
    ---@type GameSceneEventArgs
    local e = args.event(obj, evt_name)
    e.scene_name = scene_name
    return e
end

---@class EffectParamEventArgs:EventArgs
---@field ref_param EffectParam

function args.event_eff_param(obj, evt_name, ref_param)
    ---@type EffectParamEventArgs
    local e = args.event(obj, evt_name)
    e.ref_param = ref_param
    return e
end

---@class EffectParamImpactUnitEventArgs:EffectParamEventArgs
---@field ref_param EffectParam
---@field impacted_unit Unit

function args.event_eff_param_impact_unit(obj, evt_name, ref_param, impacted_unit)
    ---@type EffectParamImpactUnitEventArgs
    local e = args.event(obj, evt_name)
    e.ref_param = ref_param
    e.impacted_unit = impacted_unit
    return e
end

---@class CustomEventArgs:CustomEventArgs
---@field name string
function args.event_custom_event(obj, evt_name, custom_args)
    local e = args.event(obj, evt_name)
    e[evt_name] = custom_args
    return e
end

function args.game_string_attribute_change(obj, evt_name, game, key, value)
    local e = args.event(obj, evt_name)
    e.game_attribute_key = key
    e.game_attribute_string_value = value
    return e
end

function args.player_number_attribute_change(obj, evt_name, player, key, value, change_value)
    local e = args.event_player(obj, evt_name, player)
    e.player_attribute_key = key
    e.player_attribute_number_value = value
    e.player_attribute_number_value_change = change_value
    return e
end

function args.player_string_attribute_change(obj, evt_name, player, key, value)
    local e = args.event_player(obj, evt_name, player)
    e.player_attribute_key = key
    e.player_attribute_string_value = value
    return e
end

function args.unit_number_attribute_change(obj, evt_name, unit, key, value, change_value)
    local e = args.event_unit(obj, evt_name, unit)
    e.unit_attribute_key = key
    e.unit_attribute_number_value = value
    e.unit_attribute_number_value_change = change_value
    return e
end

function args.unit_string_attribute_change(obj, evt_name, unit, key, value)
    local e = args.event_unit(obj, evt_name, unit)
    e.unit_attribute_key = key
    e.unit_attribute_string_value = value
    return e
end

---todo:

evt.event_list = {
    ['单位-初始化'] = 'event_unit',
    ['单位-创建'] = 'event_unit',
    ['单位-复活'] = 'event_unit',
    ['单位-升级'] = 'event_unit',
    ['单位-死亡'] = 'event_unit_die',
    ['单位-移除'] = 'event_unit',
    ['单位-获得状态'] = 'event_unit_buff',
    ['单位-失去状态'] = 'event_unit_buff',
    ['单位-购买物品'] = 'event_unit_purchase_item',
    ['单位-出售物品'] = 'event_unit_inventory',
    ['单位-撤销物品'] = 'event_unit',
    ['单位-获得物品'] = 'event_unit_item',
    ['单位-失去物品'] = 'event_unit_item',
    ['单位-合并物品'] = 'event_unit_item_absorb',
    ['单位-丢弃物品'] = 'event_unit_inventory_target',
    ['单位-发布命令'] = 'event_unit_cmd_request',
    ['单位-执行命令'] = 'event_unit_cmd_request',
    ['单位-移动'] = 'event_unit_moved',
    ['单位-攻击开始'] = 'event_unit_damage_dealt',
    ['单位-攻击出手'] = 'event_unit_damage_dealt',
    ['单位-选中'] = 'event_player_unit',
    ['单位-取消选中'] = 'event_player_unit',
    ['单位-装备物品'] = 'event_unit_item',
    ['单位-取消装备'] = 'event_unit_item',
    ['奖励-成功'] = 'event_unit_loot',
    ['受到伤害'] = 'event_unit_damage_taken',
    ['造成伤害'] = 'event_unit_damage_dealt',
    --['单位-着陆'] = 'event_unit_landed', 这个是3D版本的，没做完，现在先不管了吧。
    ['单位-学习技能完成'] = 'event_unit_skill',
    ['单位-获得经验'] = 'event_unit_xp',
    ['单位-切换场景'] = 'event_unit_scene',
    ['技能-获得'] = 'event_unit_skill',
    ['技能-失去'] = 'event_unit_skill',
    ["技能-施法接近"] = 'event_unit_skill_stage',
    ["技能-施法开始"] = 'event_unit_skill_stage',
    ["技能-施法打断"] = 'event_unit_skill_stage',
    ["技能-施法引导"] = 'event_unit_skill_stage',
    ["技能-施法出手"] = 'event_unit_skill_stage',
    ["技能-施法完成"] = 'event_unit_skill_stage',
    ["技能-施法停止"] = 'event_unit_skill_stage',
    ["技能-冷却完成"] = 'event_unit_skill',
    ["技能-施法失败"] = 'event_unit_skill_result',
    ['效果-开始'] = 'event_eff_param',
    ['效果-已启动'] = 'event_eff_param',
    ['效果-结束'] = 'event_eff_param',
    ['效果-弹道命中单位'] = 'event_eff_param_impact_unit',
    ['效果-瞬移开始'] = 'event_eff_param',
    ['效果-瞬移完成'] = 'event_eff_param',
    ['玩家-输入作弊码'] = 'event_player_chat',
    ['玩家-输入聊天'] = 'event_player_chat',
    --['玩家-选择英雄'] = 'event_player_pick_hero',
    ['玩家-连入'] = 'event_player_connect',
    ['玩家-断线'] = 'event_player',
    ['玩家-重连'] = 'event_player',
    ['玩家-放弃重连'] = 'event_player',
    ['玩家-修改设置'] = 'event_player_config',
    ['玩家-界面消息'] = 'event_player_chat',
    ['玩家-切换场景'] = 'event_player_scene',
    ['玩家-按键按下'] = 'event_player_key_down',
    ['玩家-按键松开'] = 'event_player_key_up',
    ['玩家-鼠标按下'] = 'event_player_mouse_down',
    ['玩家-鼠标松开'] = 'event_player_mouse_up',
    ['玩家-滚轮移动'] = 'event_player_wheel_move',
    ['玩家-点击简易控件'] = 'event_player_click_component',
    ['游戏-加载场景'] = 'event_game_scene',
    ['游戏-阶段切换'] = 'event',
    ['游戏-帧'] = 'event',
    ['游戏-客户端消息'] = 'event_player_chat',
    ['计时器-游戏时间'] = 'event',
    ['自定义UI-消息'] = 'event_player_chat',
    ['区域-进入'] = 'event_area',
    ['区域-离开'] = 'event_area',
    ['游戏-字符串属性变化'] = 'game_string_attribute_change',
    ['玩家-数值属性变化'] = 'player_number_attribute_change',
    ['玩家-字符串属性变化'] = 'player_string_attribute_change',
    ['单位-数值属性变化'] = 'unit_number_attribute_change',
    ['单位-字符串属性变化'] = 'unit_string_attribute_change',
    ['弹道-创建'] = 'event_unit',
    ['弹道-移除'] = 'event_unit',
    -- ['控件-点击'] = 'event_component_click',
}

--dispatch机制存在问题，当多个触发器请求了这些事件时会发生争夺。
--目前暂时可能就不予考虑，用技能编辑器来解决了
evt.dispatch_events = {
    ['单位-即将死亡'] = 'event_unit_damage_taken',
    ['单位-即将获得状态'] = 'event_unit_buff',
    ['单位-请求命令'] = 'event_unit_cmd_request',
    ['单位-学习技能'] = 'event_unit_skill',
    ['单位-即将获得经验'] = 'event_unit_xp',
    ['技能-即将施法'] = 'event_unit_skill',
    ['技能-即将打断'] = 'event_unit_skill',
    ['运动-即将获得'] = 'event_unit_mover',
    ['运动-即将击中'] = 'event_unit_mover',
    ['玩家-小地图信号'] = 'event_player_ping',
    ["玩家-暂停游戏"] = 'event_player',
    ["玩家-恢复游戏"] = 'event_player',
}

--[[
用于删除事件的函数，然而由于大部分地图都使用了现有触发器，这个改动需要改动那些地图
---@field object table
---@field name string


evt.__index = evt

function evt:new(obj, name)
    local events_delegate = obj._events
    if not events_delegate then
        events_delegate = {}
        obj._events = events_delegate
    end

    local event_delegate = events_delegate[name]

    if not event_delegate then
        event_delegate = {}
        events_delegate[name] = event_delegate
        local base_event = base.event_subscribe_list[name] or name
        if obj.event_subscribe then
            obj:event_subscribe(base_event)
        end
    end

    local event = { object = obj, name = name}
    setmetatable(event, self.__index)
    return event
end

function evt:remove()
    if self.object then
        self.object._events = nil
        if self.object.event_unsubscribe then
            local base_event = base.event_subscribe_list[self.name] or self.name
            self.object:event_unsubscribe(base_event)
        end
    end
end
]]--

return {
    Trigger = Trigger
}