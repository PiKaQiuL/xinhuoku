local ac = ac
local sh = base.select_hero
local RandomableHero = {}
local ShowableHero = {}
local SelectableHero = {}
local HeroState
local CountDown
local EnableSelectHero = true
local EnableSameHeroInGame = true
local EnableSameHeroInTeam = false
local RandomMode = 'click'

local function init()
    if HeroState then
        return
    end
    HeroState = {}
    for name, unit in pairs(base.table.unit) do
        if unit.UnitTag == '英雄' and unit.Useable == 1 then
            HeroState[name] = {
                show = true,
                can_select = true,
                can_random = true,
            }
            RandomableHero[#RandomableHero+1] = name
            ShowableHero[#ShowableHero+1] = name
            SelectableHero[#SelectableHero+1] = name
        end
    end
    table.sort(RandomableHero)
    table.sort(ShowableHero)
    table.sort(SelectableHero)
end

local function get_showable_heroes()
    init()
    return ShowableHero
end

local function get_randomable_heroes()
    init()
    return RandomableHero
end

local function get_selectable_heroes()
    init()
    return SelectableHero
end

local clicked = {}
local selected = {}
local randomed = {}

local function get_enable_heroes(player, list)
    local team = player:get_team_id()
    local cant_use = {}
    for p in base.each_player 'user' do
        if p:get_team_id() == team then
            if not EnableSameHeroInTeam then
                local name = selected[p] or clicked[p]
                if name then
                    cant_use[name] = true
                end
            end
        else
            if not EnableSameHeroInGame then
                local name = selected[p] or clicked[p]
                if name then
                    cant_use[name] = true
                end
            end
        end
    end
    local tbl = {}
    for _, name in ipairs(list) do
        if not cant_use[name] then
            tbl[#tbl+1] = name
        end
    end
    return tbl
end

local function get_random_hero(player)
    local tbl = get_enable_heroes(player, get_randomable_heroes())
    if #tbl == 0 then
        return nil
    end
    return tbl[math.random(#tbl)]
end

local function click_hero(player, hero)
    if selected[player] then
        return
    end
    if clicked[player] == hero then
        return
    end
    local team = player:get_team_id()
    for p in base.each_player 'user' do
        if p:get_team_id() == team then
            if not EnableSameHeroInTeam and clicked[p] == hero then
                return
            end
        else
            if not EnableSameHeroInGame and clicked[p] ~= hero then
                return
            end
        end
    end
    clicked[player] = hero
    for p in base.each_player 'user' do
        if not EnableSameHeroInGame or p:get_team_id() == team then
            sh:op_click(p, player, hero)
        else
            sh:op_click(p, player, nil)
        end
    end
end

local function select_finish()
    if CountDown then CountDown:remove() end
    sh:op_stop()
end

local function check_all_finish()
    local selects = get_selectable_heroes()
    if #selects == 0 then
        return true
    end
    for p in base.each_player 'user' do
        if p:controller() ~= 'none' then
            if not selected[p] then
                return false
            end
        end
    end
    return true
end

local function select_hero(player, hero)
    if selected[player] then
        return
    end
    click_hero(player, hero)
    selected[player] = hero
    local team = player:get_team_id()
    for p in base.each_player 'user' do
        if not EnableSameHeroInGame or p:get_team_id() == team then
            sh:op_select(p, player, hero)
        else
            sh:op_select(p, player, nil)
        end
    end
    player:event_dispatch('玩家-选择英雄', player, hero)
    if check_all_finish() then
        select_finish()
    end
end

local function select_random()
    for player in base.each_player 'user' do
        print(player,player:controller())
        if player:controller() ~= 'none' and not selected[player] then
            if not clicked[player] then
                click_hero(player, get_random_hero(player))
            end
            select_hero(player, clicked[player])
        end
    end
end

local function count_down(time)
    CountDown = base.wait(time, function()
        select_random()
        select_finish()
    end)
end

function sh:on_init()
    if not EnableSelectHero then
        sh:op_stop()
        return
    end
    if check_all_finish() then
        select_random()
        sh:op_stop()
        return
    end
    local time = base.table.config.game_stage.time_selecthero
    local enable_random
    if RandomMode then
        enable_random = true
    end
    for p in base.each_player 'user' do
        local hero = get_showable_heroes()
        sh:op_init
        {
            player = p,
            time = time // 1000,
            hero = hero,
            random = enable_random,
        }
    end
    count_down(time)
end

function sh:on_click(player, hero)
    if not HeroState[hero] then
        return
    end
    click_hero(player, hero)
end

function sh:on_select(player, hero)
    if not HeroState[hero] then
        return
    end
    if not HeroState[hero].can_select and randomed[player] ~= hero then
        return
    end
    select_hero(player, hero)
end

function sh:on_random(player)
    if not RandomMode or RandomMode == 'disable' then
        return
    end
    local hero = get_random_hero(player)
    if not hero then
        return
    end
    randomed[player] = hero
    if RandomMode == 'click' then
        click_hero(player, hero)
    elseif RandomMode == 'select' then
        select_hero(player, hero)
    end
end

base.game.select_hero = {}

function base.game.select_hero:enable(enable)
    EnableSelectHero = enable
end

function base.game.select_hero:add_hero(name, show, can_select, can_random)
    if not HeroState then
        HeroState = {}
    end
    HeroState[name] = {
        show = show,
        can_select = show and can_select,
        can_random = can_random,
    }
    if show then
        ShowableHero[#ShowableHero+1] = name
    end
    if show and can_select then
        SelectableHero[#SelectableHero+1] = name
    end
    if can_random then
        RandomableHero[#RandomableHero+1] = name
    end
end

function base.game.select_hero:enable_same_hero(mode, enable)
    if mode == 'game' then
        EnableSameHeroInGame = enable
    elseif mode == 'team' then
        EnableSameHeroInTeam = enable
    end
end

function base.game.select_hero:set_random_mode(mode)
    RandomMode = mode
end
