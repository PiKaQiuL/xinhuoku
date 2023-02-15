local on_reborn
local reborn_timer = {}
local update_timer = {}

local function update_reborn(hero, time)
    local player = hero:get_owner()
    if player:get_hero() ~= hero then
        return
    end
    if update_timer[player] then
        update_timer[player]:remove()
    end
    if time <= 0 then
        player:set('复活时间', 0)
        player:set('复活时间上限', 0)
        return
    end
    player:set('复活时间', base.clock() + time)
    player:set('复活时间上限', time)
    update_timer[player] = base.loop(1000, function ()
        if player:get_hero() == hero then
            return
        end
        player:set('复活时间', 0)
        player:set('复活时间上限', 0)
        update_timer[player]:remove()
    end)
end

base.game:event('单位-死亡', function(_, hero)
    if not on_reborn then
        return
    end
    if hero:get_tag() ~= '英雄' or hero:is_illusion() then
        return
    end
    local new_time, point = on_reborn(hero)
    if not new_time or new_time < 0 then
        return
    end
    update_reborn(hero, new_time)
    reborn_timer[hero] = base.wait(new_time, function()
        hero:reborn(point or hero:get_point())
    end)
    log.info('英雄死亡', hero, '等级', hero:get_level(), '复活时间', new_time)
end)

base.game:event('单位-复活', function(trg, hero)
    update_reborn(hero, 0)
    if reborn_timer[hero] then
        reborn_timer[hero]:remove()
        reborn_timer[hero] = nil
    end
end)

function base.game:on_reborn(func)
    on_reborn = func
end
