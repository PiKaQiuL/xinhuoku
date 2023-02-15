local lni_writer = require 'base.lni_writer'
local MSG = {type='s2c_rpc'}
local cmsg_pack_pack = cmsg_pack.pack

local function call_all(args) --所有玩家发消息
    MSG.args = args
    local msg = cmsg_pack_pack(MSG)
    local called_players = {}
    for player in base.each_player() do
        player:ui_message(msg)
        called_players[player:get_slot_id()] = true
    end
    return called_players
end

local function call_some(ids, args) -- 向ids里的玩家发消息
    MSG.args = args
    local msg = cmsg_pack_pack(MSG)
    for id, _ in pairs(ids) do
        base.player(id):ui_message(msg)
    end
    return ids
end

local function call_other(exclude, args) -- 向exclude之外的玩家发消息, 返回发了消息的玩家id列表
    if not exclude then
        return call_all(args)
    end
    local called_players = {}
    MSG.args = args
    local msg = cmsg_pack_pack(MSG)
    for player in base.each_player() do
        local id = player:get_slot_id()
        if not exclude[id] then
            player:ui_message(msg)
            called_players[id] = true
        end
    end
    return called_players
end

base.rpc = {
    call_all = call_all,
    call_some = call_some,
    call_other = call_other
} 

function rpc_call(k, player, ...)
    player:ui_message(cmsg_pack_pack({type = '__simple_rpc__', args = { name = k, args = {...}}}))
end


------这段服务器客户端一样---
local cb_id = 1
local rpc_impl = {}
local make_args
local rpc = {
    __index = function(t, k)
        return function( ...)
            rpc_call(k, make_args(nil, ...))
        end
    end,
    __newindex = function(t, k, v)
        rawset(rpc_impl, k, v)
    end
}

make_args = function (owner, ...)
    local args = {...}
    local xargs = {}
    for i,v in ipairs(args) do
        if type(v) == 'function' then
            xargs[i] = {__rpc_cb__ = cb_id}
            rpc[cb_id] = v
            cb_id = cb_id + 1
        elseif type(v) == 'table' and v.__rpc_cb__ then
            xargs[i] = function(...)
                if owner then
                    rpc.callback(owner, v.__rpc_cb__, ...)
                else
                    rpc.callback(v.__rpc_cb__, ...)
                end
            end
        else 
            xargs[i] = v
        end
    end
    return table.unpack(xargs)
end

function rpc_accept(owner, k, ...)
    if type(rpc_impl[k]) == 'function' then
        rpc_impl[k](make_args(owner, ...))
    end
end

setmetatable(rpc, rpc)
------这段服务器客户端一样---

rpc.callback = function(player, id, ...)
    rpc_accept(player, id, ...)
end

function base.ui.proto.__simple_rpc__(player, call)
    rpc_accept(player, call.name, player, table.unpack(call.args))
end


base.xrpc = rpc
return base.xrpc

