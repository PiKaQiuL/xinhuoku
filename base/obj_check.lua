function unit_check(unit, disable_error)
    local t = type(unit)
    if (t == 'function') then
        return true
    elseif (t ~= 'table' and t ~= 'userdata') or unit.type ~= 'unit' then
        if not disable_error then
            log.error("单位参数无效，请检测函数传入值。参数：", unit)
        end
        return false
    else
        return true
    end
end

function item_check (item, disable_error)
    if (type(item) ~= 'table' and type(item) ~= 'userdata') or item.type ~= 'item' then
        if not(disable_error) then
            log.error("物品参数无效，请检测函数传入值。参数：", item)
        end
        return false
    else
        return true
    end
end

function skill_check(skill, disable_error)
    if (type(skill) ~= 'table' and type(skill) ~= 'userdata') or skill.type ~= 'skill' then
        if not(disable_error) then
            log.error("技能参数无效，请检测函数传入值。参数:", skill)
        end
        return false
    else
        return true
    end
end

function eff_param_check (eff_param, disable_error)
    if (type(eff_param) ~= 'table' and type(eff_param) ~= 'userdata') or eff_param.type ~='eff_param' then
        if not(disable_error) then
            log.error("效果节点参数无效，请检测函数传入值，参数：", eff_param)
        end
        return false
    else
        return true
    end
end

function player_check (player, disable_error)
    if player == nil then
        if not(disable_error) then
            log.error("玩家参数为空，请检测函数传入值")
        end
        return false
    else
        return true
    end
end


function mover_check (mover, disable_error)
    if mover == nil then
        if not(disable_error) then
            log.error("mover参数为空，请检测函数传入值")
        end
        return false
    else
        return true
    end
end

function circle_check(obj, disable_error)
    if obj and (type(obj) == 'table' or type(obj) == 'userdata') and obj.type == 'circle' then
        return true
    else
        if not(disable_error) then
            log.error("圆形区域参数为空，请检测函数传入值")
        end
        return false
    end
end

function rect_check(obj, disable_error)
    if obj and (type(obj) == 'table' or type(obj) == 'userdata') and obj.type == 'rect' then
        return true
    else
        if not(disable_error) then
            log.error("矩形区域参数为空，请检测函数传入值")
        end
        return false
    end
end

function area_check(obj, disable_error)
    if circle_check(obj, true) or rect_check(obj, true) then
        return true
    else
        if not(disable_error) then
            log.error("区域参数为空，请检测函数传入值")
        end
        return false
    end
end

function point_check (point, disable_error)
    if (type(point) ~= 'table' and type(point) ~= 'userdata') or point.type ~= 'point' then
        if not(disable_error) then
            log.error("点参数无效，请检测函数传入值，参数：", point)
        end
        return false
    else
        return true
    end
end

function line_check (line, disable_error)
    if (type(line) ~= 'table' and type(line) ~= 'userdata') or line.type ~= 'line' then
        if not(disable_error) then
            log.error("线参数无效，请检测函数传入值，参数：", line)
        end
        return false
    else
        return true
    end
end

function buff_check (buff, disable_error)
    if (type(buff) ~= 'table' and type(buff) ~= 'userdata') or buff.type ~='buff' then
        if not(disable_error) then
            log.debug("Buff参数无效，请检测函数传入值，参数：", buff)
        end
        return false
    else
        return true
    end
end

function unit_group_check(unit_group, disable_error)
    if type(unit_group) == 'table' and unit_group.table_class == '单位组' then
        return true
    else
        if not(disable_error) then
            log.error"单位组参数无效，请检测函数传入值"
        end
        return false
    end
end

function lightning_check (lightning, disable_error)
    if lightning == nil then
        if not(disable_error) then
            log.error("闪电参数为空，请检测函数传入值")
        end
        return false
    else
        return true
    end
end

function icon_check(icon, disable_error)
    if (type(icon) ~= 'table' and type(icon) ~= 'userdata') or icon.type ~= "icon" then
        if not(disable_error) then
            log.error("小地图图标参数为空，请检测函数传入值")
        end
        return false
    end
    return true
end

function trigger_check (trigger, disable_error)
    if (type(trigger) ~= 'table' and type(trigger) ~= 'userdata')or trigger.type ~= 'trigger' then
        if not(disable_error) then
            log.error("触发器参数无效，请检测函数传入值，参数：", trigger)
        end
        return false
    else
        return true
    end
end

function snapshot_check (snapshot, disable_error)
    if (type(snapshot) ~= 'table' and type(snapshot) ~= 'userdata') or snapshot.type ~= 'snapshot' then
        if not(disable_error) then
            log.error("快照参数无效，请检测函数传入值，参数：", snapshot)
        end
        return false
    else
        return true
    end
end

function timer_check (timer, disable_error)
    if type(timer) ~= 'table' or timer.type ~= 'timer' then
        if not(disable_error) then
            log.error("计时器参数无效，请检测函数传入值，参数：", timer)
        end
        return false
    else
        return true
    end
end

function any_unit_check(unit, disable_error)
    if unit == base.any_unit then
        return true
    else
        if not(disable_error) then
            log.error"任意单位参数无效，请检测函数传入值"
        end
        return false
    end
end

function any_skill_check(skill, disable_error)
    if skill == base.any_skill then
        return true
    else
        if not(disable_error) then
            log.error"任意技能参数无效，请检测函数传入值"
        end
        return false
    end
end

function any_eff_param_check(eff_param, disable_error)
    if eff_param == base.any_eff_param then
        return true
    else
        if not(disable_error) then
            log.error"任意效果参数无效，请检测函数传入值"
        end
        return false
    end
end

function any_player_check(player, disable_error)
    if player == base.any_player then
        return true
    else
        if not(disable_error) then
            log.error"任意效果参数无效，请检测函数传入值"
        end
        return false
    end
end

function any_mover_check(mover, disable_error)
    if mover == base.any_mover then
        return true
    else
        if not(disable_error) then
            log.error"任意运动参数无效，请检测函数传入值"
        end
        return false
    end
end

function id_check(obj_id, disable_error)
    if type(obj_id) == 'string' then
        return true
    else
        if not(disable_error) then
            log.error"id参数无效，请检测函数传入值"
        end
        return false
    end
end

function cache_type(cache, disable_error)
    if type(cache) == 'table' and cache.NodeType then
        return true
    else
        if not(disable_error) then
            log.error"数据表参数无效，请检测函数传入值"
        end
        return false
    end
end

function event_name_check(event_name, disable_error)
    if type(event_name) == 'string' then
        return true
    else
        if not(disable_error) then
            log.error"事件名称参数无效，请检测函数传入值"
        end
        return false
    end
end

function time_check(time, disable_error)
    if type(time) == 'number' then
        return true
    else
        if not(disable_error) then
            log.error"时间参数无效，请检测函数传入值"
        end
        return false
    end
end

function component_type_check(component_type, check_tb, disable_error)
    local flag = 0
    for k, v in ipairs(check_tb) do
        if component_type == v then
            flag = 1
            break
        end
    end
    if flag == 1 then
        return true
    else
        if not(disable_error) then
            log.error('简易控件类型不正确')
        end
        return false
    end
end

function component_check(component, disable_error)
    if base.player(1).component[component] == nil then
        if not(disable_error) then
            log.error("简易控件参数无效，请检测函数传入值")
        end
        return false
    else
        return true
    end
end


---comment
---@param object table
---@param key string
---@param value any
function base.game.object_store_value(object, key, value)
    local t = type(object)
    if ((t == "table") or (t == 'userdata')) and key then
        object.__hashtable = object.__hashtable or {}
        object.__hashtable[key] = value
        return
    end
end

function base.game.object_restore_value(object, key)
    local t = type(object)
    if ((t == "table") or (t == 'userdata')) and key and type(object.__hashtable) == 'table' then
        return object.__hashtable[key]
    end
end