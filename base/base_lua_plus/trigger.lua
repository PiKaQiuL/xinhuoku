function base.trigger_disable(trigger)
    ---@ui 关闭触发器~1~
    ---@belong trigger
    ---@description 关闭触发器
    ---@applicable action
    ---@name1 触发器
    if trigger_check(trigger) then
        trigger:disable()
    end
end
 ---@keyword 关闭 触发器
function base.trigger_enable(trigger)
    ---@ui 开启触发器~1~
    ---@belong trigger
    ---@description 开启触发器
    ---@applicable action
    ---@name1 触发器
    if trigger_check(trigger) then
        trigger:enable()
    end
end
 ---@keyword 开启 触发器
function base.trigger_is_enable(trigger)
    ---@ui 触发器~1~是否开启
    ---@belong trigger
    ---@description 触发器是否开启
    ---@applicable value
    ---@name1 触发器
    if trigger_check(trigger) then
        return trigger:is_enable()
    end
end
 ---@keyword 触发器 开启
function base.trigger_remove(trigger)
    ---@ui 移除触发器~1~
    ---@belong trigger
    ---@description 移除触发器
    ---@applicable action
    ---@name1 触发器
    if trigger_check(trigger) then
        trigger:remove()
    end
end
 ---@keyword 移除 触发器
function base.trigger_new(func, t, disable, scene)
    local trig = base.trig:new(func, true, scene)
    if type(t) == 'table' then
        for _, event in ipairs(t) do
            -- if and(type(event.obj) == 'string') then
            --     table.insert(pending_game_units, {node_mark = event.obj, event_name = event.event_name, trg = trig})
            -- else
            if event then
                if not(event.time) then
                    trig:add_event(event.obj, event.event_name, event.custom_event)
                else
                    trig:add_event_game_time(event.time, event.periodic)
                end
            end
        end
    end
    if disable then
        trig:disable()
    end
    return trig
end

function base.trigger_add_event(trigger, trigger_event)
    ---@ui 为触发器~1~添加事件~2~
    ---@belong trigger
    ---@description 为触发器添加事件
    ---@applicable action
    ---@name1 触发器
    ---@name2 触发事件
    if trigger_check(trigger) then
        -- if and(type(event.obj) == 'string') then
        --     table.insert(pending_game_units, {node_mark = trigger_event.obj, event_name = trigger_event.event_name, trg = trigger_event})
        -- else
        if trigger_event then
            if not(trigger_event.time) then
                trigger:add_event(trigger_event.obj, trigger_event.event_name, trigger_event.custom_event)
            else
                trigger:add_event_game_time(trigger_event.time, trigger_event.periodic)
            end
        end
    end
end

 ---@keyword 添加 事件
--把触发事件表包装成函数
function base.trigger_event_wrapper_unit(unit, event_name)
    ---@ui ~1~~2~时
    ---@belong unit
    ---@description 单位事件
    ---@applicable value
    ---@name1 单位
    if ((type(unit) == 'function' or cache_type(unit) or unit_check(unit, true) or any_unit_check(unit, true) or id_check(unit, true)) and event_name_check(event_name, true)) then
        return {
            obj = unit,
            event_name = event_name
        }
    else
        log.error"单位事件参数无效，请检测函数传入值"
    end
end

function base.trigger_event_wrapper_skill(skill, event_name)
    ---@ui 技能~1~~2~时
    ---@belong skill
    ---@applicable value
    if ((skill_check(skill, true) or cache_type(skill, true) or any_skill_check(skill, true) or id_check(skill, true)) and event_name_check(event_name, true)) then
        return {
            obj = skill,
            event_name = event_name
        }
    else
        log.error"技能事件参数无效，请检测函数传入值"
    end
end

function base.trigger_event_wrapper_eff_param(eff_param, event_name)
    ---@ui 效果~1~~2~时
    ---@belong effparam
    ---@applicable value
    if ((eff_param_check(eff_param, true) or cache_type(eff_param) or any_eff_param_check(eff_param, true) or id_check(eff_param, true)) and event_name_check(event_name, true)) then
        return {
            obj = eff_param,
            event_name = event_name
        }
    else
        log.error"效果事件参数无效，请检测函数传入值"
    end
end

function base.trigger_event_wrapper_player(player, event_name)
    ---@ui ~1~~2~时
    ---@belong player
    ---@applicable value
    if ((player_check(player, true) or any_player_check(player, true)) and event_name_check(event_name, true)) then
        return {
            obj = player,
            event_name = event_name
        }
    else
        log.error"玩家事件参数无效，请检测函数传入值"
    end
end

function base.trigger_event_wrapper_game(event_name)
    ---@ui 游戏事件~1~时
    ---@belong gamer
    ---@applicable value
    if event_name_check(event_name, true) then
        return {
            obj = base.game,
            event_name = event_name
        }
    else
        log.error"游戏事件参数无效，请检测函数传入值"
    end
end

function base.trigger_event_wrapper_mover(mover, event_name)
    ---@ui 运动~1~~2~时
    ---@belong mover
    ---@applicable value
    if ((mover_check(mover, true) or any_mover_check(mover, true) or id_check(mover, true)) and event_name_check(event_name, true)) then
        return {
            obj = mover,
            event_name = event_name
        }
    else
        log.error"运动事件参数无效，请检测函数传入值"
    end
end

function base.trigger_event_wrapper_timer_periodic(time)
    ---@ui 游戏开始后每~1~秒执行
    ---@belong timer
    ---@description 循环游戏时间事件
    ---@applicable value
    if time_check(time) then
        return {
            obj = base.game,
            time = time,
            periodic = true
        }
    end
end

function base.trigger_event_wrapper_timer_once(time)
    ---@ui 游戏开始后~1~秒执行
    ---@belong timer
    ---@description 单次游戏时间事件
    ---@applicable value
    if time_check(time) then
        return {
            obj = base.game,
            time = time,
            periodic = false
        }
    end
end


function base.trigger_event_wrapper_area(area, event_name)
    ---@ui 任意单位~2~区域~1~时
    ---@belong area
    ---@description 区域事件
    ---@applicable value
    if (area_check(area, true) and event_name_check(event_name, true)) then
        return {
            obj = area,
            event_name = event_name
        }
    else
        log.error"区域事件参数无效，请检测函数传入值"
    end
end

-- function base.trigger_event_wrapper_component(player:player, event_name:控件事件 ,event_label:string) trigger_event
--     ---@ui ~1~~2~事件标签为~3~的控件时
--     ---@description 控件事件
--     ---@belong component
--     ---@applicable value
--     return { obj = player, event_name = event_name}
-- end

function base.trigger_custom_event_wrapper(event_name)
    ---@ui 自定义事件~1~时
    ---@belong trigger
    ---@description 自定义事件
    ---@applicable value
    if event_name_check(event_name) then
        return {
            obj = base.game,
            custom_event = true,
            event_name = event_name
        }
    end
end

base.game:event('游戏-阶段切换', function()
    if base.game:status() == 4 then
        base.game:event_notify'游戏-初始化'
    end
    if base.game:status() == 4 then
        if base.auxiliary.get_map_kind() == 2 then
            base.game:event_notify'游戏-装备局开始'
        else
            base.game:event_notify'游戏-开始'
        end
    end
end)