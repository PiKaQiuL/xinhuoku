Player = Player or base.tsc.__TS__Class()
Player.name = 'Player'
local cmsg_pack = cmsg_pack.pack

---@class Player
---@field create_unit fun(self:Player, id:string, point:Point, facing:number, on_init:fun(unit:Unit)?, scene_name:string?):Unit
---@field get_team_id fun():number
---@field get_slot_id fun():number
---@field create_illusion fun(self:Player, point:Point, facing:number, link:string|Unit, on_init:fun(unit:Unit)?, scene_name:string?)
---@field get_scene_name fun(self:Player)
---@field set fun(self:Player, key:string, value:number|string|table)
---@field get fun(self:Player, key:string):number|string|table
local mt = Player.prototype

base.runtime.player = mt

--类型
mt.type = 'player'

--调试器
function mt:__debugger_extand()
    local player = self
    -- 属性部分
    local attr = {}
    local sort = {}
    for key, id in pairs(base.table.constant['玩家属性']) do
        sort[key] = id
        table.insert(attr, key)
    end
    table.sort(attr, function(key1, key2)
        return sort[key1] < sort[key2]
    end)
    local proxy = {}
    function proxy:__index(key)
        return player:get(key)
    end
    function proxy:__newindex(key, value)
        player:set(key, value)
    end
    return setmetatable(attr, proxy)
end

function mt:get_team()
    local id = self:get_team_id()
    return base.team(id)
end

function mt:set_team(team)
    local id = team:get_id()
    self:set_team_id(id)
end

function mt:get_num(name, ...)
    local ret = self:get(name, ...);
    if type(ret) ~= "number" then
        log.warn("尝试用数字方法获取玩家的非数字属性"..name)
    end
    return ret
end

function mt:set_num(name, value, ...)
    if type(value) ~= "number" then
        log.warn("尝试用数字方法设置玩家的非数字属性"..name)
    end
    return self:set(name, value, ...);
end

--获得金钱
--	钱
--	原因
function mt:add_gold(gold, reason)
	if not reason then
		log.error('获得金钱没有原因')
	end
	local data = {player = self, gold = gold, reason = reason or '未知'}
	self:event_notify('玩家-即将获得金钱', data)
	gold = data.gold
	self:add('金钱', gold)
	self:event_notify('玩家-获得金钱', data)
	return gold
end


function mt:event(name, f)
    return base.event_register(self, name, f)
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
    local res, arg = ac_event_dispatch(ac_game, name, ...)
    if res ~= nil then
        return res, arg
    end
    return nil
end

function mt:event_notify(name, ...)
    ac_event_notify(self, name, ...)
    ac_event_notify(ac_game, name, ...)
end

function mt:is_ally(other)
    return self:get_team_id() == other:get_team_id()
end

function mt:match_mask(other, mask)
    if mask.Self and other == self then
        return true
    elseif mask.Ally and other ~= self and self:is_ally(other) then
        return true
    elseif mask.Enemy and not self:is_ally(other) then
        return true
    end
    return false
end

local players
local player_types
local function init_players()
    local slots = {}
    for i in pairs(base.table.config.player_setting) do
        slots[#slots+1] = i
    end
    table.sort(slots)
    players = {}
    player_types = {}
    for i, id in ipairs(slots) do
        players[i] = base.player(id)
        player_types[i] = base.table.config.player_setting[id][1]
    end
end

function base.each_player(type)
    if not players then
        init_players()
    end
    local i = 0
    local function next()
        i = i + 1
        if not players[i] then
            return nil
        end
        if not type or player_types[i] == type then
            return players[i]
        else
            return next()
        end
    end
    return next
end

-- local jump_scene = mt.jump_scene

-- function mt:jump_scene(scene_name, keep_hero)
--     local hero = self:get_hero()
--     jump_scene(self, scene_name, false)
--     if keep_hero then
--         hero:jump_scene(scene_name)
--         base.wait(1000, function()
--             self:set_hero(hero)
--         end)
--     end
-- end

function mt:set_table_attr(key, value)
    if type(value) == 'table' then
        local sync_table = base.check_sync_table(value)
        local normal_table = base.sync_table_to_normal(value)
        local ori_tbl = self:get_sync_table(key)
        if ori_tbl then
            ori_tbl.delete = base.mix_modify_to_delete(ori_tbl.delete, sync_table.modify)
            ori_tbl.modify = base.mix_delete_to_modify(ori_tbl.modify, sync_table.delete)
            ori_tbl.delete = base.mix_table(ori_tbl.delete, sync_table.delete)
            ori_tbl.modify = base.mix_table(ori_tbl.modify, sync_table.modify)
        else
            ori_tbl = sync_table
        end
        self:set_table(key, normal_table, ori_tbl)
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

return {
    Player = Player
}
