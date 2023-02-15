--local lni = require 'lni'
--local lni_writer = require 'base.lni_writer'
local cmsg_pack_pack = cmsg_pack.pack
local cmsg_pack_unpack = cmsg_pack.unpack

local MSG = {}
local SUBSCRIBE = {}
local BIND = {}
local CACHE = {}

local proto = {}
local unique = {}

local eff = base.eff

local logger = log.warn
if base.test then
    logger = log.error
end

local function subscribe(player, func)
    if not SUBSCRIBE[player] then
        SUBSCRIBE[player] = { id = 0, pool = {} }
    end
    local pool = SUBSCRIBE[player].pool
    local id = pool[#pool]
    if id then
        pool[#pool] = nil
    else
        id = SUBSCRIBE[player].id + 1
        SUBSCRIBE[player].id = id
    end
    SUBSCRIBE[player][func] = id
    SUBSCRIBE[player][id] = func
    return id
end

local function unsubscribe(player, func)
    if not SUBSCRIBE[player] then
        return false
    end
    local id = SUBSCRIBE[player][func]
    if not id then
        return false
    end
    SUBSCRIBE[player][func] = nil
    SUBSCRIBE[player][id] = nil
    local pool = SUBSCRIBE[player].pool
    pool[#pool+1] = id
    return true
end

local function get_subscribe(player, id)
    if not SUBSCRIBE[player] then
        return nil
    end
    return SUBSCRIBE[player][id]
end

function proto.notify(player, data)
    local callback = get_subscribe(player, data.id)
    if not callback then
        return
    end
    callback(table.unpack(data.args))
end


function proto.drop_item(player, data)
    local unit = player:get_hero()
    if not unit then
        return
    end
    if math.type(data.slot) ~= 'integer' then
        return
    end
    local target = base.point(data.x, data.y)
    unit:event_notify('单位-丢弃物品', unit, data.slot, target)
end

function proto.reconncet(player,data)
    -- 改ui消息的时候发现ac有重发消息，但是感觉没有起效，先注释了吧
    -- local cache = CACHE[player]
    -- if not cache then
    --     return
    -- end
    -- for _, key in ipairs(cache) do
    --     local msg = cache[key]
    --     player:ui_message(msg)
    -- end
    -- local path = player.watch_player.map_path
    -- log.info('change_map',path)
    -- player:ui 'set_chess_board'({
    --     map_path = path,
    -- })
end

---comment
---@param player Player
---@param data any
function proto.cast(player, data)
    local target = data.target
    if data.target_is_unit_id then
        target = base.game.unit_map[data.target]
    end
    ---@type Unit Description
    local unit = player:get_hero()
    if unit then
        local skill_id = data.skill_id
        if skill_id then
            local skill = unit:get_skill(skill_id)
            if skill then
                unit:cast_request(skill, target, data.data)
                return
            end
        end
        unit:cast_request(data.name, target, data.data)
    end
end

function proto.client_channel_finish(player, data)
    local unit = player:get_hero()
    local skill = unit:find_skill(data.name)
    if skill then
        skill:channel_finish()
    end
end

function proto.call_ui_response(player, data)
    local ui_response_id = data.id
    local ret = require(ui_response_id)(data)
end

--客户端的按键转发给服务器，服务器收到消息之后在服务端发起事件
function proto.__client_key_down(_, msg)
    local player = base.player(msg.player_id)
    player:event_notify('玩家-按键按下', player, msg.key)
end

function proto.__client_key_up(_, msg)
    local player = base.player(msg.player_id)
    player:event_notify('玩家-按键松开', player, msg.key)
end

function proto.__client_mouse_down(_, msg)
    local player = base.player(msg.player_id)
    player:event_notify('玩家-鼠标按下', player, msg.key)
end

function proto.__client_mouse_up(_, msg)
    local player = base.player(msg.player_id)
    player:event_notify('玩家-鼠标松开', player, msg.key)
end

function proto.__client_wheel_move(_, msg)
    local player = base.player(msg.player_id)
    player:event_notify('玩家-滚轮移动', player, msg.delta_wheel)
end

--处理从客户端转发来的事件
function proto.__client_event_to_server(_, msg)
    local obj = base.event_deserialize(msg.obj)
    local name = msg.name
    local args = base.event_deserialize(msg.args)
    print('服务端收到转发事件：'..name)
    if obj and name and args then
        base.event_notify(obj, name, table.unpack(args))
    else
        print('事件'..name..'参数反序列化失败！')
    end
end

-- 处理客户端请求地编默认单位
function proto.__get_default_unit(_, msg)
    local node_mark = msg.node_mark
    local unit = base.game.get_default_unit(node_mark)
    local unit_id
    if unit then
        unit_id = unit:get_id()
    end
    base.game:ui'__return_default_unit'{
        ok = (unit ~= nil),
        node_mark = node_mark,
        unit_id = unit_id
    }
end

--处理客户端拾取物品请求
function proto.__unit_try_pick_item(_, msg)
    local unit = base.unit(msg.unit_id)
    local item = base.unit(msg.item_id).item
    local ret = false
    if unit and item then
        ret = item:pick_by(unit)
    end
    base.game:ui'__unit_try_pick_item_result'{
        unit_id = msg.unit_id,
        item_id = msg.item_id,
        ok = ret,
    }
end

--处理客户端丢弃物品请求
function proto.__item_try_drop(_, msg)
    local item = base.unit(msg.item_id).item
    local ret = false
    if item then
        ret = item:drop()
    end
    base.game:ui'__item_try_drop_result'{
        item_id = msg.item_id,
        ok = ret,
    }
end

function proto.__client_select_unit(_, msg)
    local player = base.player(msg.player_id)
    local unit = base.unit(msg.unit_id)
    if unit then
        unit:event_notify('单位-选中', player, unit)
    end
end

function proto.__client_cancel_select_unit(_, msg)
    local player = base.player(msg.player_id)
    local unit = base.unit(msg.unit_id)
    if unit then
        unit:event_notify('单位-取消选中', player, unit)
    end
end

function proto.__client_send_message(_, msg)
    local message = msg.msg
    local player = base.player(msg.player_id)
    if player then
        player:event_notify('游戏-客户端消息', player, message)
    end
end

function unique.bind(args)
    local buf = {'bind', ('%q'):format(args.name)}
    for i, key in ipairs(args.key) do
        buf[i+2] = ('%q'):format(key)
    end
    return table.concat(buf, '|')
end

function unique.subscribe(args)
    local buf = {'subscribe', ('%q'):format(args.name)}
    for i, key in ipairs(args.key) do
        buf[i+2] = ('%q'):format(key)
    end
    return table.concat(buf, '|')
end

local function cache_message(player, msg, type, args)
    if not unique[type] then
        return
    end
    local key = unique[type](args)
    local cache = CACHE[player]
    if not cache then
        cache = {}
        CACHE[player] = cache
    end
    if not cache[key] then
        cache[#cache+1] = key
    end
    cache[key] = msg
end

function base.runtime.player:ui(type, guarantee)
    return function (args)
        MSG.type = type
        MSG.args = args
        local msg = cmsg_pack_pack(MSG)
        -- cache_message(self, msg, type, args)
        if stop_ui then
            return
        end
        self:ui_message(msg, guarantee)
    end
end


function base.game:ui(type, guarantee)
    return function (args)
        MSG.type = type
        MSG.args = args
        local msg = cmsg_pack_pack(MSG)
        for player in base.each_player 'user' do
            -- cache_message(self, msg, type, args)
            if stop_ui then
                return
            end
            player:ui_message(msg, guarantee)
        end
    end
end


--[[
base.game:event('玩家-重连', function (_, player)
    local cache = CACHE[player]
    if not cache then
        return
    end
    for _, key in ipairs(cache) do
        local msg = cache[key]
        player:ui_message(msg)
    end
end)]]

base.game:event('玩家-界面消息', function (_, player, str)
    if str:find('--!', 1, true) then
        logger(table.concat({('玩家[%d]发送了非法的消息'):format(player:get_slot_id()), str}, '\r\n'))
        return
    end

    local suc, res = pcall(cmsg_pack_unpack, str)
    if not suc then
        logger(table.concat({('玩家[%d]发送了无法解析的消息'):format(player:get_slot_id()), str, str, res}, '\r\n'))
        return
    end
    local type, args = res.type, res.args
    if not proto[type] then
        logger(table.concat({('玩家[%d]发送了无人处理的消息[%s]'):format(player:get_slot_id(), type), str}, '\r\n'))
        return
    end
    xpcall(proto[type], logger, player, args)
end)

--[[
base.loop(33, function ()
    base.game:ui 'clock' (base.clock())
end)
base.game:ui 'clock' (base.clock())
]]

local function copy_key(key, keys)
    local new_keys = {}
    if keys then
        for i, k in ipairs(keys) do
            new_keys[i] = k
        end
    end
    new_keys[#new_keys+1] = key
    return new_keys
end

local function new_bind(player, name, keys)
    local state = {}
    return setmetatable({}, {
        __index = function (self, key)
            if not state[key] then
                local t = new_bind(player, name, copy_key(key, keys))
                state[key] = t
            end
            return state[key]
        end,
        __newindex = function (self, key, value)
            -- 把旧的订阅释放掉（客户端不需要释放，因为客户端是通过事件名来存储的，会被新的订阅覆盖）
            local old = state[key]
            if type(old) == 'function' then
                unsubscribe(player, old)
            end
            state[key] = value
            if type(value) == 'function' then
                -- 通知客户端订阅事件，监听返回时使用notify协议
                local id = subscribe(player, value)
                player:ui 'subscribe' {
                    name = name,
                    key = copy_key(key, keys),
                    value = id,
                }
            else
                player:ui 'bind' {
                    name = name,
                    key = copy_key(key, keys),
                    value = value,
                }
            end
        end,
    })
end

local function bind(player, name)
    if not BIND[player] then
        BIND[player] = {}
    end
    if not BIND[player][name] then
        BIND[player][name] = new_bind(player, name)
    end
    return BIND[player][name]
end

base.ui = {
    bind = bind,
    proto = proto
}