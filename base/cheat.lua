base.cheat = {}

local reload_start = {}
local reload_finish = {}
local reload_include = {}
local reloading = false
local path_map = {}

--local function safe_include(filename)
--    return xpcall(require, log.error, filename)
--end
--
--local function include(filename)
--    if reload_include[filename] == nil then
--        reload_include[#reload_include+1] = filename
--    end
--    reload_include[filename] = true
--    local ok, res = safe_include(filename)
--    if not ok then
--        return nil
--    end
--    return res
--end
--
--if base.test then
--    rawset(_G, 'include', include)
--
--    log.info('测试模式，接管 require')
--
--    local function require_load(name)
--        local msg = ''
--        if type(package.searchers) ~= 'table' then
--            error("'package.searchers' must be a table", 3)
--        end
--        for _, searcher in ipairs(package.searchers) do
--            local f, extra = searcher(name)
--            if type(f) == 'function' then
--                return f, extra
--            elseif type(f) == 'string' then
--                msg = msg .. f
--            end
--        end
--        error(("module '%s' not found:%s"):format(name, msg), 3)
--    end
--
--    function require(name)
--        local loaded = package.loaded
--        if type(name) ~= 'string' then
--            error(("bad argument #1 to 'require' (string expected, got %s)"):format(type(name)), 2)
--        end
--        local p = loaded[name]
--        if p ~= nil then
--            return p
--        end
--        local init, extra = require_load(name)
--        local res = init(name, extra)
--        if res ~= nil then
--            loaded[name] = res
--        end
--        if loaded[name] == nil then
--            loaded[name] = true
--        end
--        path_map[extra] = name
--        return loaded[name]
--    end
--else
--    rawset(_G, 'include', require)
--end
--
--local function reload_trigger()
--    log.info('---- Reloading trigger start ----')
--    for trg in base.each_trigger() do
--        local info = debug.getinfo(trg.callback, 'S')
--        local filename = info.source:sub(2)
--        if reload_include[path_map[filename]] ~= nil then
--            log.debug(('Reload trigger in %s at %s'):format(path_map[filename], filename))
--            trg:remove()
--        end
--    end
--    log.info('---- Reloading trigger end   ----')
--end
--
--local function reload_require()
--    log.info('---- Reloading require start ----')
--    local list = {}
--    for _, filename in ipairs(reload_include) do
--        package.loaded[filename] = nil
--        list[#list+1] = filename
--    end
--    for _, filename in ipairs(list) do
--        safe_include(filename)
--    end
--    log.info('---- Reloading require end   ----')
--end
--
--function base.cheat.on_reload(on_start, on_finish)
--    reload_start[#reload_start+1] = on_start
--    reload_finish[#reload_finish+1] = on_finish
--end

----------------- 作弊指令 -------------------
local gm = {}
function gm.is_reloading()
    return reloading
end

function gm.reload(player, cmd)
    --log.info('---- Reloading Start ----')
    --reloading = true
    --for _, func in ipairs(reload_start) do
    --    xpcall(func, log.error)
    --end
    --reload_start = {}
    --reload_finish = {}
    --reload_trigger()
    --reload_require()
    --for _, func in ipairs(reload_finish) do
    --    xpcall(func, log.error)
    --end
    --reloading = false
    --log.info('---- Reloading end   ----')
    reload()
end

local function get_dummy_skill(hero)
    if not base.table.skill['作弊指令'] then
        base.table.skill['作弊指令'] = { max_level = 1, init_level = 1 }
    end
    local skill = hero:find_skill '作弊指令'
    if not skill then
        skill = hero:add_skill('作弊指令', '隐藏')
    end
    return skill
end

local show_message = false
local function message(obj, ...)
    local n = select('#', ...)
    local arg = {...}
    for i = 1, n do
        if type(arg[i]) == 'table' and arg[i].type == 'point' then
            arg[i] = arg[i]:copy()
        end
        arg[i] = tostring(arg[i])
    end
    local str = table.concat(arg, '\t')
    print(obj, '-->', str)
    if show_message then
        for player in base.each_player 'user' do
            player:message
            {
                text = str,
                type = 'chat',
            }
        end
    end
end

function gm.show_message()
    show_message = not show_message
end

function gm.memory()
    collectgarbage 'collect'
    local memory = collectgarbage 'count'
    if memory < 1024 then
        print(string.format('%.3fk', memory))
        return
    end
    memory = memory / 1024
    if memory < 1024 then
        print(string.format('%.3fm', memory))
        return
    end
    memory = memory / 1024
    print(string.format('%.3fg', memory))
end

if base.test then
    function gm.snapshot(player, cmd)
        collectgarbage 'collect'
        collectgarbage 'collect'
        local snapshot = base.test.snapshot()
        local output = {}
        table.insert(output, '')
        table.insert(output, '--------snapshot--------')
        local n = 0
        local m = 0
        for _, u in pairs(base.test.unit()) do
            m = m + 1
            local ref = base.test.unit_coreref(u)
            if ref ~= nil then
                if not ref then
                    local name = tostring(u)
                    local desc = snapshot[name]
                    table.insert(output, '------------------------')
                    table.insert(output, ('%s	%s'):format(name, desc))
                    n = n + 1
                end
            end
        end
        table.insert(output, '------------------------')
        table.insert(output, (' total: %d/%d'):format(n, m))
        table.insert(output, '------------------------')
        for name, desc in pairs(snapshot) do
            table.insert(output, ('%s	%s'):format(name, desc))
            table.insert(output, '------------------------')
        end
        log.info(table.concat(output, '\n'))
    end
end

function gm.win(player, cmd)
    local team = tonumber(cmd[2])
    if team == nil or team < 1 or team > 2 then
        team = player:get_team_id()
    end
    if base.game.game_valid then
        base.game.game_valid()
    end
    base.game:set_winner(team)
end

function gm.wtf(player, cmd)
    if base.game.wtf() then
        base.game.wtf(false)
    else
        base.game.wtf(true)
        local hero = player:get_hero()
        if hero then
            for skl in hero:each_skill() do
                skl:set_cd(0)
            end
        end
    end
end

function gm.set_hero(player, cmd)
    local group = base.selector()
        : in_range(player:input_mouse(), cmd[2] and tonumber(cmd[2]) or 200)
        : of_type {'英雄'}
        : allow_god()
        : get()
    local hero = group[1]
    if not hero then
        return
    end
    player:set_hero(hero)
end

function gm.change_hero(player, cmd)
    cmd[3] = player:get_slot_id()
    local u = gm.addhero(player, cmd)
    player:set_hero(u)
end

local hero_list = setmetatable({}, { __index = function(self, key)
    setmetatable(self, nil)
    for name, unit in pairs(base.table.unit) do
        if unit.UnitTag == '英雄' and unit.Useable == 1 then
            table.insert(self, name)
        end
    end
    table.sort(self)
    return self[key]
end})

function gm.addhero(player, cmd)
    local hero = player:get_hero()
    local name, playerid = cmd[2], tonumber(cmd[3])
    local heroid = tonumber(name)
    if heroid then
        name = hero_list[heroid]
    elseif not base.table.unit[name] then
        name = nil
    end
    if not playerid then
        playerid = player:get_team_id() % 2 + 10
    end
    local x, y
    if hero then
        x, y = hero:get_xy()
    else
        x, y = 0, 0
    end
    if not name then
        if hero then
            name = hero:get_name()
        else
            return
        end
    end
    if not base.player(playerid) then
        return
    end
    local u = base.player(playerid):create_unit(name, base.point(x + 100, y + 100), 180)
    return u
end

function gm.hero(player, cmd)
    local name, playerid = tonumber(cmd[2]), tonumber(cmd[3])
    if not name then
        return
    end
    if not playerid then
        playerid = player:get_slot_id()
    end
    local player = base.player(playerid)
    local heroid = tonumber(name)
    if heroid then
        name = hero_list[heroid]
    elseif not base.table.unit[name] then
        name = nil
    end
    local hero = player:get_hero()
    if not name then
        if hero then
            name = hero:get_name()
        else
            return
        end
    end
    player:event_notify('玩家-选择英雄', player, name)
end

function gm.player(player, cmd)
    table.remove(cmd, 1)
    gm.call_method(player, cmd)
end

function gm.unit(player, cmd)
    table.remove(cmd, 1)
    for _, unit in base.selector()
        : in_range(player:input_mouse(), 100)
        : of_add '建筑'
        : of_add '守卫'
        : allow_god()
        : ipairs()
    do
        gm.call_method(unit, cmd)
    end
end

function gm.self(player, cmd)
    table.remove(cmd, 1)
    local hero = player:get_hero()
    if hero then
        gm.call_method(hero, cmd)
    end
end

function gm.reborn(player, cmd)
    local hero = player:get_hero()
    if hero then
        hero:reborn(player:input_mouse())
    end
end

function gm.killex(player, cmd)
    for _, u in base.selector()
        : in_range(player:input_mouse(), cmd[2] and tonumber(cmd[2]) or 200)
        : of_add '建筑'
        : allow_god()
        : ipairs()
    do
        u:kill()
    end
end

function gm.refresh(player)
    local hero = player:get_hero()
    if hero then
        hero:set('生命', hero:get '生命上限')
        hero:set('魔法', hero:get '魔法上限')
        for skill in hero:each_skill() do
            if skill:get_cd() > 0 then
                skill:set_cd(0)
            end
        end
    end
end

function gm.kill_all(player, cmd)
    local team = cmd[2]
    if team then
        team = tonumber(team)
    end
    for _, u in base.selector()
        : of_type {'小兵', '野怪'}
        : add_filter(function(u)
            return not team or team == u:get_team_id()
        end)
        : ipairs()
    do
        u:kill()
    end
end

function gm.lv(player, cmd)
    local hero = player:get_hero()
    if hero then
        hero:set_level(math.min(tonumber(cmd[2]) or 0, base.game.max_level))
    end
end

local heroes
function gm.never_dead(player, cmd)
    local hero = player:get_hero()
    if hero then
        if not heroes then
            heroes = {}
        end
        if heroes[hero] then
            heroes[hero] = nil
            hero:remove_restriction '免死'
        else
            heroes[hero] = true
            hero:add_restriction '免死'
        end
    end
end

--对自己造成伤害
function gm.damage(player, cmd)
    local hero = player:get_hero()
    if hero then
        get_dummy_skill(hero):add_damage
        {
            source = hero,
            damage = tonumber(cmd[2]),
            target = hero,
        }
    end
end

function gm.add_buff(player, cmd)
    local hero = player:get_hero()
    local name = cmd[2]
    if hero and name then
        hero:add_buff(name){ skill = get_dummy_skill(hero), time = tonumber(cmd[3]) }
    end
end

function gm.remove_buff(player, cmd)
    local hero = player:get_hero()
    local name = cmd[2]
    if hero and name then
        hero:remove_buff(name)
    end
end

function gm.move(player, cmd)
    local hero = player:get_hero()
    if hero then
        hero:blink(player:input_mouse())
    end
end

function gm.timefactor(player, cmd)
    local speed = tonumber(cmd[2])
    if speed then
        base.test.speed(speed)
    end
end

local closeai = false

function gm.is_closeai()
    return closeai
end

function gm.closeai()
    closeai = true
    base.game:disable_ai()
end

function gm.openai()
    closeai = false
    base.game:enable_ai()
end

function gm.call_method(obj, cmd)
    local f = obj[cmd[1]]
    if type(f) == 'function' then
        for i = 2, #cmd do
            local v = cmd[i]
            v = tonumber(v) or v
            if v == 'true' then
                v = true
            elseif v == 'false' then
                v = false
            end
            cmd[i] = v
        end
        local rs = {pcall(f, obj, table.unpack(cmd, 2))}
        message(obj, table.unpack(rs, 2))
    else
        message(obj, f)
    end
end

for name, func in pairs(gm) do
    base.cheat[name] = func
end

local cheat_trigger
function base.cheat.open(open)
    if not open then
        if cheat_trigger then
            cheat_trigger:remove()
            cheat_trigger = nil
        end
        return
    end
    if cheat_trigger then
        return
    end
    cheat_trigger = base.game:event('玩家-输入作弊码', function (_, player, command)
        log.info(('玩家[%d]输入作弊码：%s'):format(player:get_slot_id(), command))
        local cmd = base.split(command, ' ')
        if #cmd == 0 then
            return
        end
        local name = cmd[1]
        if gm[name] then
            print('=================')
            print(name)
            gm[name](player, cmd)
            return
        end
        -- 尝试调用单位事件
        table.insert(cmd, 1, 'self')
        local name = cmd[1]
        if gm[name] then
            print('=================')
            print(name)
            gm[name](player, cmd)
            return
        end
    end)
end
