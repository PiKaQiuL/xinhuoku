local table_writer = require 'base.table_writer'

local mt = {}
mt.__index = mt

mt.player = nil
mt.save = nil
mt.version = -1
mt.inited = nil
mt.on_init_events = nil

local function copy_table(tbl)
    local new = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            new[k] = copy_table(v)
        else
            new[k] = v
        end
    end
    return new
end

local SAVE = {}

function mt:init(version, save)
    self.version = version
    local lua = 'return ' .. save
    local func, err = load(lua, lua, 't')
    if not func then
        self.inited = 'error'
        log.error('存档语法错误：', err)
        return
    end
    local suc, data = pcall(func)
    if not suc then
        self.inited = 'error'
        log.error('存档运行时错误：', data)
        return
    end
    if type(data) ~= 'table' then
        data = {}
    end
    self.save = data
end

function mt:check_init()
    local events = self.on_init_events
    if not events then
        return
    end
    local state = self.inited
    if events[state] then
        events[state]()
    end
end

function mt:get()
    return copy_table(self.save)
end

function mt:commit(events, save)
    save = copy_table(save)
    log.info(('提交玩家[%d]的存档'):format(self.player:get_slot_id()))
    local suc, dump = pcall(table_writer, save)
    if not suc then
        log.info('存档序列化失败：' .. dump)
        events.error('存档序列化失败：' .. dump)
        return
    end
    log.info(('推送玩家[%d]的存档，版本为[%d]\r\n%s'):format(self.player:get_slot_id(), self.version, dump))
    base.rpc.database.commit("save:"..self.player:get_slot_id(), self.version, dump)
    {
        ok = function ()
            log.info(('推送玩家[%d]的存档成功'):format(self.player:get_slot_id()))
            self.save = save
            events.ok()
        end,
        error = function (code)
            log.info(('推送玩家[%d]的存档失败，原因为：%s'):format(self.player:get_slot_id(), code))
            events.error(code)
        end,
        timeout = function ()
            log.info(('推送玩家[%d]的存档超时'):format(self.player:get_slot_id()))
            events.timeout()
        end,
    }
end

local function init_save()
    for player in base.each_player 'user' do
        if player:controller() == 'human' then
            log.info(('请求玩家[%s]的存档'):format(player:get_slot_id()))
            SAVE[player] = setmetatable({ player = player }, mt)
            base.rpc.database.connect("save:"..player:get_slot_id())
            {
                ok = function (version, dump)
                    log.info(('请求玩家[%s]的存档成功，版本为[%d]\r\n%s'):format(player:get_slot_id(), version, dump))
                    SAVE[player].inited = 'ok'
                    SAVE[player]:init(version, dump)
                    SAVE[player]:check_init()
                end,
                error = function (code)
                    log.info(('请求玩家[%s]的存档失败，原因为： %s'):format(player:get_slot_id(), code))
                    SAVE[player].inited = 'error'
                    SAVE[player]:check_init()
                end,
                timeout = function ()
                    log.info(('请求玩家[%s]的存档超时'):format(player:get_slot_id()))
                    SAVE[player].inited = 'timeout'
                    SAVE[player]:check_init()
                end,
            }
        end
    end
end

init_save()

base.save = {}

function base.save.on_init(player)
    return function (events)
        if not SAVE[player] then
            return false
        end
        SAVE[player].on_init_events = events
        SAVE[player]:check_init()
    end
end

function base.save.get(player)
    if not SAVE[player] or SAVE[player].inited ~= 'ok' then
        return nil
    end
    return SAVE[player]:get()
end

function base.save.commit(player, save)
    return function (events)
        events.ok = events.ok or function () end
        events.error = events.error or function () end
        events.timeout = events.timeout or function () end
        if not SAVE[player] then
            events.error '未初始化'
            return
        end
        if SAVE[player].inited == nil then
            events.error '正在连接'
            return
        end
        if SAVE[player].inited == 'error' then
            events.error '连接失败'
            return
        end
        if SAVE[player].inited == 'timeout' then
            events.error '连接超时'
            return
        end
        return SAVE[player]:commit(events, save)
    end
end
