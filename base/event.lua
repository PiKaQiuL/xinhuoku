local setmetatable = setmetatable
local ipairs = ipairs

local ac_game = base.game
local co = include 'base.co'
--全局事件转换
local dispatch_events = {
    '单位-即将获得状态',
    '单位-学习技能',
    '单位-请求命令',
    '技能-即将施法',
    '技能-即将打断',
    '运动-即将获得',
    '运动-即将击中',
    '玩家-小地图信号',
    "玩家-暂停游戏",
    "玩家-恢复游戏",
}

local notify_events = {
    '单位-初始化',
    '单位-创建',
    '弹道-创建',
    '单位-死亡',
    '单位-移除',
    '弹道-移除',
    '单位-复活',
    '单位-获得状态',
    '单位-失去状态',
    '单位-购买物品',
    '单位-出售物品',
    '单位-撤销物品',
    '单位-发布命令',
    '单位-执行命令',
    '单位-移动',
    '移动-开始',
    '移动-结束',
    '技能-获得',
    '技能-失去',
    "技能-施法接近",
    "技能-施法开始",
    "技能-施法打断",
    "技能-施法引导",
    "技能-施法出手",
    "技能-施法完成",
    "技能-施法停止",
    "技能-冷却完成",
    "技能-施法失败",
    '玩家-输入作弊码',
    '玩家-输入聊天',
    '玩家-选择英雄',
    '玩家-连入',
    '玩家-断线',
    '玩家-重连',
    '玩家-暂时离开',
    '玩家-回到游戏',
    '玩家-放弃重连',
    '玩家-修改设置',
    '游戏-阶段切换',
    '自定义UI-消息',
    '玩家-切换场景',
    '单位-切换场景',
    '游戏-加载场景',

    '游戏-属性变化',
    '游戏-字符串属性变化',
    '玩家-属性变化',
    '玩家-数值属性变化',
    '玩家-字符串属性变化',
    '单位-属性变化',
    '单位-属性改变',
    '单位-数值属性变化',
    '单位-字符串属性变化',
}

function base.assign_event(name, f)
    base.event[name] = f
end

for _, event in ipairs(dispatch_events) do
    base.assign_event(event, function(self, ...)
        if not self then
            log.error('[event] dispatch to null', event)
            return
        end
        return self:event_dispatch(event, self, ...)
    end)
end

for _, event in ipairs(notify_events) do
    base.assign_event(event, function(self, ...)
        if not self then
            log.error('[event] notify to null', event)
            return
        end
        return self:event_notify(event, self, ...)
    end)
end

-- 上层拆分的事件，需要订阅原事件
local event_subscribe_list = {
    ['玩家-界面消息'] = '自定义UI-消息',
}
base.event_subscribe_list = event_subscribe_list

base.assign_event('自定义UI-消息', function (self, ...)
    self:event_notify('玩家-界面消息', self, ...)
end)

local evt_list
local args

local event_name_send_to_client = {}

function base.forward_event_register(name)
    event_name_send_to_client[name] = true
end

local scene_manager = require 'base.game.scene'

local function have_func(t, name)
    return type(t) == 'table' and type(t[name]) == 'function'
end

local function get_obj_scene(obj)
    if type(obj) == 'table' then
        local obj_scene = nil
        if obj.scene then
            return obj.scene
        end
        if have_func(obj, 'get_scene_name') then
            return obj:get_scene_name()
        end
        if have_func(obj, 'get_owner') then
            return get_obj_scene(obj:get_owner())
        end
        if obj.source then
            return get_obj_scene(obj.source)
        end
    end
end

local function check_obj_scene(scene, obj)
    if type(obj) == 'table' then
        local obj_scene = get_obj_scene(obj)
        --- base.game 之类的
        if obj_scene == nil then
            return true
        end
        return obj_scene == scene
    else
        return true
    end
end

function check_event_scene(event, obj)
    if type(event) == 'table' then
        if event.scene then
            local scene = event.scene
            if scene == '' then
                return true
            else
                -- return scene_manager.is_scene_activated(scene) and check_obj_scene(scene, obj)
                return check_obj_scene(scene, obj)
            end
        else
            return true
        end
    else
        return false
    end
end

function base.event_serialize(t, depth)
    depth = depth or 0
    if depth > 10 then
        log.info('自定义事件参数的表深度超过上限！')
        return nil
    end
    local type_t = type(t)
    if type_t == "table" or type_t == "userdata" then
        if t == base.game then
            return '{game}'
        elseif base.tsc.__TS__InstanceOf(t, Unit) then
            local id = t:get_id()
            return '{unit|'..id..'}'
        elseif base.tsc.__TS__InstanceOf(t, Player) then
            local id = t:get_slot_id()
            return '{player|'..id..'}'
        elseif base.tsc.__TS__InstanceOf(t, Item) then
            local id = t.unit and t.unit:get_id()
            return '{item|'..id..'}'
        elseif base.tsc.__TS__InstanceOf(t, Actor) then
            return '{actor|'..t._id..'}'
        else
            local ret = {}
            for k, v in pairs(t) do
                local s_k = base.event_serialize(k, depth + 1)
                local s_v = base.event_serialize(v, depth + 1)
                if s_k == nil or s_v == nil then
                    --表包含无法序列化的内容
                    return nil
                end
                ret[s_k] = s_v
            end
            return ret
        end
    elseif type_t == 'function' or type_t == "thread" then
        return nil
    else
        return t
    end
end

function base.event_deserialize(t)
    local type_t = type(t)
    if type_t == 'string' then
        if t == '{game}' then
            return base.game
        end
        local type, ret
        type, ret = t:match('{(.*)|(.*)}')
        if type and ret then
            if type == 'player' then
                return base.player(tonumber(ret))
            elseif type == 'unit' then
                return base.unit(tonumber(ret))
            elseif type == 'item' then
                local unit = base.unit(tonumber(ret))
                return unit and unit.item or nil
            elseif type == 'actor' then
                return base.actor_from_id(tonumber(ret))
            end
        end
        -- 不是序列化的字符串，直接返回
        return t
    elseif type_t == 'table' then
        local ret = {}
        for s_k, s_v in pairs(t) do
            local k = base.event_deserialize(s_k)
            local v = base.event_deserialize(s_v)
            if k ~= nil and v ~= nil then
                ret[k] = v
            else
                return nil
            end
        end
        return ret
    else
        return t
    end
end

local function __server_event_to_client(obj, name, ...)
    -- if __lua_state_name == 'StateGame' then --只在游戏中转发
        --序列化事件参数
        local s_obj = base.event_serialize(obj)
        local args = base.event_serialize{...}

        if s_obj == nil or args == nil then
            print('序列化事件：'..name..'的参数失败！')
            return
        end
        base.next(function()
            --延迟到下一帧发，因为可能需要等单位属性同步
            print('服务端向客户端转发事件：'..name)
            base.game:ui'__server_event_to_client'{
                obj = s_obj,
                name = name,
                args = args
            }
        end)
    -- end
end

function base.event_dispatch(obj, name, ...)
    if not evt_list then
        evt_list = base.trig.event.event_list
        args = base.trig.event.evt_args
    end

    local events = obj._events
    if not events then
        return
    end
    local event = events[name]
    if not event or #event < 0 then
        return
    end

    local combined_args
    if evt_list and evt_list[name] and args[evt_list[name]] then
        combined_args = args[evt_list[name]](obj, name, ...)
    elseif event.custom_event then
        -- 触发器定义的自定义事件
        combined_args = args.event_custom_event(obj, name, ...)
    end
    for i = #event, 1, -1 do
        -- log.info(name, i, event[i].scene, scene_manager.is_scene_activated(event[i].scene))
        local res, arg
        if event[i].combine_args then
            if check_event_scene(event[i], obj) then
                res, arg = event[i](combined_args)
            end
        else
            res, arg = event[i](...)
        end
        if res ~= nil then
            return res, arg
        end
    end
end

function base.event_notify(obj, name, ...)
    if event_name_send_to_client[name] == true then
        __server_event_to_client(obj, name, ...)
    end
    if not evt_list then
        evt_list = base.trig.event.event_list
        args = base.trig.event.evt_args
    end

    local events = obj._events
    if not events then
        return
    end
    local event = events[name]
    if not event or #event < 0 then
        return
    end

    local combined_args
    if evt_list and evt_list[name] and args[evt_list[name]] then
        combined_args = args[evt_list[name]](obj, name, ...)
    elseif event.custom_event then
        -- 触发器定义的自定义事件
        combined_args = args.event_custom_event(obj, name, ...)
    end
    for i = #event, 1, -1 do
        -- log.info(name, i, event[i].scene, scene_manager.is_scene_activated(event[i].scene))
        if event[i].combine_args then
            if check_event_scene(event[i], obj) then
                event[i](combined_args)
            end
        else
            event[i](...)
        end
    end
end

function base.event_register(obj, name, f)
    local trig = base.trig:new(f)
    trig:add_event(obj, name)
    return trig
end

function base.game:event_dispatch(name, ...)
    return base.event_dispatch(self, name, ...)
end

function base.game:event_notify(name, ...)
    return base.event_notify(self, name, ...)
end

function base.game:event(name, f)
    return base.event_register(self, name, f)
end
