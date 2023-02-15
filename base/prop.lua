local prop = {}

local mt = {}
mt.__index = mt

mt.player = nil
mt.inited = nil
mt.on_init_events = nil

function mt:init_items(items)
    self.items = items
    for k, v in pairs(items) do
        log.info(('+   [%s] = %s'):format(k, v))
    end
    self:query()
end

function mt:init_status(status)
    self.status = {}
    for _, name in ipairs(status) do
        self.status[name] = true
    end
    log.info(('拥有状态：%s'):format(table.concat(status, ';')))
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

function mt:update(items)
    for k, v in pairs(items) do
        self.items[k] = v
        log.info(('+   [%s] = %s'):format(k, v))
    end
end

function mt:query()
    log.info(('监听玩家[%d]的道具变化'):format(self.player:get_slot_id()))
    base.rpc.database.query('item:'..tostring(self.player:get_slot_id()))
    {
        ok = function (items)
            log.info(('监听玩家[%d]的道具变化成功'):format(self.player:get_slot_id()))
            self:update(items)
            self:query()
        end,
        error = function (code)
            log.error(('监听玩家[%d]的道具变化失败，原因为：%s'):format(self.player:get_slot_id()), code)
        end,
        timeout = function ()
            log.error(('监听玩家[%d]的道具变化超时'):format(self.player:get_slot_id()))
        end,
    }
end

function mt:get(name)
    local n = self.items[name]
    if n then
        return n
    else
        return 0
    end
end

function mt:cost(events, name, value)
    local value = math.tointeger(value)
    assert(type(name) == 'string', '道具名称必须是字符串')
    assert(value ~= nil, '道具数量必须是整数')
    assert(value > 0, '扣除的道具数量必须大于0')
    local n = self:get(name)
    if n - value < 0 then
        events.error '数量不够'
        return
    end

    log.info(('推送玩家[%d]的道具变化：[%s] %+d'):format(self.player:get_slot_id(), name, -value))
    base.rpc.database.commit('item:'..tostring(self.player:get_slot_id()), {{name, -value}})
    {
        ok = function (data)
            local v = data[name]
            self.items[name] = v
            log.info(('推送玩家[%d]的道具变化成功，现有数量为：%d'):format(self.player:get_slot_id(), v))
            events.ok()
        end,
        error = function (code)
            log.info(('推送玩家[%d]的道具变化失败，原因为：%s'):format(self.player:get_slot_id(), code))
            events.error(code)
        end,
        timeout = function ()
            log.info(('推送玩家[%d]的道具变化超时'):format(self.player:get_slot_id()))
            events.timeout()
        end,
    }
end

function mt:multi_cost(events, data)
    local list = {}
    for name, value in pairs(data) do
        local value = math.tointeger(value)
        assert(type(name) == 'string', '道具名称必须是字符串')
        assert(value ~= nil, '道具数量必须是整数')
        assert(value > 0, '扣除的道具数量必须大于0')
        local n = self:get(name)
        if n - value < 0 then
            events.error '数量不够'
            return
        end
        list[#list+1] = {name, -value}
    end
    if #list > 10 then
        events.error '最多只能同时扣除10个道具'
        return
    end

    log.info(('推送玩家[%d]的道具批量变化'):format(self.player:get_slot_id()))
    for _, item in ipairs(list) do
        local name, value = item[1], item[2]
        log.info(('+   [%s] %d'):format(name, value))
    end

    base.rpc.database.commit('item:'..tostring(self.player:get_slot_id()), list)
    {
        ok = function (items)
            log.info(('推送玩家[%d]的道具批量变化成功'):format(self.player:get_slot_id()))
            for name, v in pairs(items) do
                log.info(('+   [%s] %d'):format(name, v))
                self.items[name] = v
            end
            events.ok()
        end,
        error = function (code)
            log.info(('推送玩家[%d]的道具批量变化失败，原因为：%s'):format(self.player:get_slot_id(), code))
            events.error(code)
        end,
        timeout = function ()
            log.info(('推送玩家[%d]的道具批量变化超时'):format(self.player:get_slot_id()))
            events.timeout()
        end,
    }
end

function mt:has(name)
    return not not self.status[name]
end

function mt:init_result(type, res)
    if self.inited then
        return
    end
    if res == 'error' or res == 'timeout' then
        self.inited = res
        self:check_init()
        return
    end
    if not self.has_inited then
        self.has_inited = {}
    end
    self.has_inited[type] = res
    if self.has_inited['道具'] == 'ok' and self.has_inited['状态'] == 'ok' then
        self.inited = 'ok'
        self:check_init()
    end
end

local function init_prop()
    for player in base.each_player 'user' do
        if player:controller() == 'human' then
            log.info(('请求玩家[%s]的道具'):format(player:get_slot_id()))
            prop[player] = setmetatable({ player = player }, mt)
            base.rpc.database.connect('item:'..tostring(player:get_slot_id()))
            {
                ok = function (items)
                    log.info(('请求玩家[%s]的道具成功'):format(player:get_slot_id()))
                    prop[player]:init_items(items)
                    prop[player]:init_result('道具', 'ok')
                end,
                error = function (code)
                    log.info(('请求玩家[%s]的道具失败，原因为： %s'):format(player:get_slot_id(), code))
                    prop[player]:init_result('道具', 'error')
                end,
                timeout = function ()
                    log.info(('请求玩家[%s]的道具超时'):format(player:get_slot_id()))
                    prop[player]:init_result('道具', 'timeout')
                end,
            }
            base.rpc.database.connect('status:'..tostring(player:get_slot_id()))
            {
                ok = function (status)
                    log.info(('请求玩家[%s]的状态成功'):format(player:get_slot_id()))
                    prop[player]:init_status(status)
                    prop[player]:init_result('状态', 'ok')
                end,
                error = function (code)
                    log.info(('请求玩家[%s]的状态失败，原因为： %s'):format(player:get_slot_id(), code))
                    prop[player]:init_result('状态', 'error')
                end,
                timeout = function ()
                    log.info(('请求玩家[%s]的状态超时'):format(player:get_slot_id()))
                    prop[player]:init_result('状态', 'timeout')
                end,
            }
        end
    end
end

init_prop()

base.prop = {}

function base.prop.on_init(player)
    return function (events)
        if not prop[player] then
            return false
        end
        prop[player].on_init_events = events
        prop[player]:check_init()
    end
end

function base.prop.get(player, name)
    if not prop[player] or prop[player].inited ~= 'ok' then
        return false
    end
    return prop[player]:get(name)
end

function base.prop.cost(player, name, value)
    return function (events)
        events.ok = events.ok or function () end
        events.error = events.error or function () end
        events.timeout = events.timeout or function () end
        if not prop[player] then
            events.error '未初始化'
            return
        end
        if prop[player].inited == nil then
            events.error '正在连接'
            return
        end
        if prop[player].inited == 'error' then
            events.error '连接失败'
            return
        end
        if prop[player].inited == 'timeout' then
            events.error '连接超时'
            return
        end
        return prop[player]:cost(events, name, value)
    end
end

function base.prop.multi_cost(player, name, value)
    return function (events)
        events.ok = events.ok or function () end
        events.error = events.error or function () end
        events.timeout = events.timeout or function () end
        if not prop[player] then
            events.error '未初始化'
            return
        end
        if prop[player].inited == nil then
            events.error '正在连接'
            return
        end
        if prop[player].inited == 'error' then
            events.error '连接失败'
            return
        end
        if prop[player].inited == 'timeout' then
            events.error '连接超时'
            return
        end
        return prop[player]:multi_cost(events, name, value)
    end
end

function base.prop.has(player, name)
    if not prop[player] or prop[player].inited ~= 'ok' then
        return false
    end
    return prop[player]:has(name)
end
