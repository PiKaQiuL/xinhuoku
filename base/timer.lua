local setmetatable = setmetatable
local ipairs = ipairs
local pairs = pairs
local table_insert = table.insert
local math_max = math.max
local math_floor = math.floor
local FRAME = 33

local cur_frame = 0
local max_frame = 0
local cur_index = 0
local free_queue = {}
local timer = {}
local game_timer = {}

local nexts = {}

local function update_next()
	local count = #nexts
	for i = 1, count do
		local next = nexts[i]
		if next then
			next.count = next.count + 1
			if next.count >= next.frame then
				nexts[i] = false
				next.cb()
			end
		end
	end

	for i = #nexts, 1, -1 do
		if nexts[i] == false then
			table.remove(nexts, i)
		end
	end
end

local function alloc_queue()
    local n = #free_queue
    if n > 0 then
        local r = free_queue[n]
        free_queue[n] = nil
        return r
    else
        return {}
    end
end

local function m_timeout(self, timeout)
    if self.pause_remaining or self.running then
        return
    end
    local ti = cur_frame + timeout
    local q = timer[ti]
    if q == nil then
        q = alloc_queue()
        timer[ti] = q
    end
    self.timeout_frame = ti
    self.running = true
    q[#q + 1] = self
end

local function m_wakeup(self)
    if self.removed then
        return
    end
    self.running = false
    self:on_timer()
    if self.removed then
        return
    end
    if self.timer_count then
        if self.timer_count > 1 then
            self.timer_count = self.timer_count - 1
            m_timeout(self, self.timeout)
        else
            self.removed = true
        end
    else
        m_timeout(self, self.timeout)
    end
end

local function get_remaining(self)
    if self.removed then
        return 0
    end
    if self.pause_remaining then
        return self.pause_remaining
    end
    if self.timeout_frame == cur_frame then
        return self.timeout or 0
    end
    return self.timeout_frame - cur_frame
end

local function on_tick()

    --update_next应该先执行，不然 q == nil 直接return了
    update_next()

    local q = timer[cur_frame]
    if q == nil then
        cur_index = 0
        return
    end
    for i = cur_index + 1, #q do
        local callback = q[i]
        cur_index = i
        q[i] = nil
        if callback then
            m_wakeup(callback)
        end
    end
    cur_index = 0
    timer[cur_frame] = nil
    free_queue[#free_queue + 1] = q
end

function base.clock()
    return cur_frame
end

function base.timer_size()
    local n = 0
    for _, ts in pairs(timer) do
        n = n + #ts
    end
    return n
end

function base.timer_all()
    local tbl = {}
    for _, ts in pairs(timer) do
        for i, t in ipairs(ts) do
            if t then
                tbl[#tbl + 1] = t
            end
        end
    end
    return tbl
end

base.perf_add('游戏-帧', 'STAT_LUA_TICK')
base.assign_event('游戏-帧', function (delta)
    base.perf('游戏-帧', function()
        base.game:event_notify('游戏-帧', delta)
        if cur_index ~= 0 then
            cur_frame = cur_frame - 1
        end
        max_frame = max_frame + delta
        while cur_frame < max_frame do
            cur_frame = cur_frame + 1
            on_tick()
        end
    end)
end)

Timer = Timer or base.tsc.__TS__Class()
Timer.name = 'Timer'

local mt = Timer.prototype
mt.type = 'timer'

if base.test then
    function mt:__tostring()
        return ('[table:timer:%X]'):format(base.test.topointer(self))
    end
else
    function mt:__tostring()
        return '[table:timer]'
    end
end

function mt:remove()
    self.removed = true
end

function mt:get_remaining_time()
    return get_remaining(self)
end

function mt:pause()
    if self.removed or self.pause_remaining then
        return
    end
    self.pause_remaining = get_remaining(self)
    self.running = false
    local ti = self.timeout_frame
    local q = timer[ti]
    if q then
        for i = #q, 1, -1 do
            if q[i] == self then
                q[i] = false
                return
            end
        end
    end
end

function mt:resume()
    if self.removed or not self.pause_remaining then
        return
    end
    local timeout = self.pause_remaining
    self.pause_remaining = nil
    m_timeout(self, timeout)
end

function mt:restart()
    if self.removed or self.pause_remaining or not self.running then
        return
    end
    local ti = self.timeout_frame
    local q = timer[ti]
    if q then
        for i = #q, 1, -1 do
            if q[i] == self then
                q[i] = false
                break
            end
        end
    end
    self.running = false
    m_timeout(self, self.timeout)
end

local function ptimer(timeout, on_timer, count)
    local info = debug.getinfo(2) -- 会取调这个函数的上一层的上一层的行号；并登记到性能统计里（注意调ptimer的那一层会被算作tailcall，所以是2不是3
    local label
    if info then
        label = info.short_src .. ':' .. info.currentline
    else
        label = '??'
    end
    base.perf_add(label, '游戏-帧')
    local t = {
        ['timeout'] = math_max(math_floor(timeout), 1),
    }
    if count then
        t.timer_count = count
    end

    --测试代码
    local a = 43434
    local b = 324
    local c = 323
    t.on_timer = function()
        a = 213
        b = 34234
        c = 2132321
        base.perf(label, function()
            a = 23123
            on_timer(t)
        end)
    end
    setmetatable(t, mt)
    m_timeout(t, t.timeout)
    return t
end

function base.wait(timeout, on_timer)
    return ptimer(timeout, on_timer, 1)
end

function base.wait_(timeout, on_timer)  -- 不参与性能统计的版本
    local t = setmetatable({
        ['timeout'] = math_max(math_floor(timeout), 1),
        ['on_timer'] = on_timer,
        ['timer_count'] = 1,
    }, mt)
    m_timeout(t, t.timeout)
    return t
end

function base.loop(timeout, on_timer)
    return ptimer(timeout, on_timer)
end

function base.loop_(timeout, on_timer) -- 不参与性能统计的版本
    local t = setmetatable({
        ['timeout'] = math_floor(timeout),
        ['on_timer'] = on_timer,
    }, mt)
    m_timeout(t, t.timeout)
    return t
end

function base.next(cb)
	table.insert(nexts, {
		count = 0,
		frame = 2,
		cb = cb
	})
end

function base.timer(timeout, count, on_timer)
    if count == 0 then
        return ptimer(timeout, on_timer)
    end
    return ptimer(timeout, on_timer, count)
end

function base.timer_(timeout, count, on_timer) -- 不参与性能统计的版本
    if count == 0 then
        return base.loop(timeout, on_timer)
    end
    local t = setmetatable({
        ['timeout'] = math_floor(timeout),
        ['on_timer'] = on_timer,
        ['timer_count'] = count,
    }, mt)
    m_timeout(t, t.timeout)
    return t
end

local function utimer_initialize(u)
    if not u._timers then
        u._timers = {}
    end
    if #u._timers > 0 then
        return
    end
    u._timers[1] = base.loop(10000, function()
        local timers = u._timers
        for i = #timers, 2, -1 do
            if timers[i].removed then
                local len = #timers
                timers[i] = timers[len]
                timers[len] = nil
            end
        end
        if #timers == 1 then
            timers[1]:remove()
            timers[1] = nil
        end
    end)
end

function base.uwait(u, timeout, on_timer)
    utimer_initialize(u)
    local t = base.wait(timeout, on_timer)
    table_insert(u._timers, t)
    return t
end

function base.uloop(u, timeout, on_timer)
    utimer_initialize(u)
    local t = base.loop(timeout, on_timer)
    table_insert(u._timers, t)
    return t
end

function base.utimer(u, timeout, count, on_timer)
    utimer_initialize(u)
    local t = base.timer(timeout, count, on_timer)
    table_insert(u._timers, t)
    return t
end

return {
    Timer = Timer
}