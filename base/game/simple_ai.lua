local mt = base.ai['简易AI']

mt.pulse = 200

function mt:on_add(state)
    self._simple_ai = state
end

function mt:on_remove()
    self._simple_ai = nil
end

base.game:event('单位-初始化', function (_, unit)
    local data = unit:get_data()
    unit:add_ai '简易AI'
    {
        ai_attack = base.ai_attack {},
        auto_attack = data.SimpleAiSearch == 1,
        chase_limit = data.SimpleAiChaseLimit,
        disable_search = 0,
        mode = 'none',
    }
end)

local function approach_cast(unit)
    local command = unit:is_walking() and unit:get_walk_command()
    return command and command ~= 'attack' and command ~= 'walk'
end

local sqrt = math.sqrt
local function get_dis_point(point1, point2)
	local x1, y1 = point1:get_xy()
	local x2, y2 = point2:get_xy()
	local x = x1 - x2
	local y = y1 - y2
	return sqrt(x * x + y * y)
end

local function search(unit, state)
    -- 是否禁止搜敌
    if state.disable_search ~= 0 then
        return nil
    end

    local attack_skill = unit:attack_skill()

    -- 没有攻击能力，禁止搜敌
    if not attack_skill then
        return nil
    end

    -- 失控，禁止搜敌
    if unit:has_restriction '失控' then
        return nil
    end

    -- 如果能攻击到上次搜到的敌人，则返回这个人
    if state.last_search and unit:can_attack(state.last_search) then
        return state.last_search
    else
        state.last_search = nil
    end

    -- 搜敌
    local search_range = unit:get '搜敌范围'
    local target
    if state.chase_limit and state.chase_limit < search_range then
        unit:set('搜敌范围', state.chase_limit)
        target = state.ai_attack(unit)
        unit:set('搜敌范围', search_range)
    else
        target = state.ai_attack(unit)
    end
    if target then
        state.last_search = target
        return target
    end

    return nil
end

local function lock_attack(unit, state)
    -- 锁定攻击、攻击目标存活且不在视野内，则走到目标消失的位置
    local target = state.lock_target
    if target:is_alive() and not target:is_visible(unit) then
        if state.visible_point then
            return
        end
        state.visible_point = target:get_point():polar_to({unit:get_point() / target:get_point(), 300})
        unit:walk(state.visible_point)
        return true
    end
    state.visible_point = nil

    -- 攻击目标死亡/不在视野内/物免/主动攻击友方单位，则停止攻击
    if not target:is_alive()
        or not target:is_visible(unit)
        or target:has_restriction '物免'
        or (target:is_ally(unit) and not unit:has_restriction '失控')
    then
        return
    end

    -- 如果没有攻击能力，则等待
    local attack_skill = unit:attack_skill()
    if not attack_skill then
        return true
    end

    -- 如果目标离开了攻击范围，则追击
    if unit:get_point():distance(target:get_point()) > unit:get '攻击范围' + target:get_attackable_radius() then
        unit:attack(target)
        return true
    end

    -- 攻击还在冷却，则等待
    if attack_skill:get_cd() > 0 then
        return true
    end

    -- 攻击目标
    if unit:attack(target) then
        return true
    end
end

local function search_and_attack(unit, state, mode)
    local target = search(unit, state)
    if target then
        local attack_skill = unit:attack_skill()
        if mode == '立即' then
            unit:attack(target)
        elseif attack_skill:get_cd() <= 0 then
            unit:attack(target)
        elseif unit:get_point():distance(target:get_point()) > unit:get '攻击范围' + target:get_attackable_radius() then
            unit:attack(target)
        end
        if not state.guard_point then
            state.guard_point = unit:get_point()
        end
        return true
    end
end

local function walk_attack(unit, state)
    -- 搜索附近的敌人
    if search_and_attack(unit, state) then
        return true
    end

    -- 向目标点移动
    unit:walk(state.walk_attack)
    return true
end

local function ai_walk(unit, state)
    -- 如果正在遣返，则检查是否遣返完成
    if state.chase_back then
        if unit:get_point():distance(state.guard_point) > 1 then
            unit:walk(state.guard_point)
            return true
        end
        state.chase_back = nil
        state.guard_point = nil
    end

    -- 如果超出追击范围，则强制遣返
    if state.guard_point and unit:get_point():distance(state.guard_point) > state.chase_limit then
        state.chase_back = true
        unit:walk(state.guard_point)
    end

    -- 搜索附近的敌人
    if search_and_attack(unit, state) then
        return true
    end

    -- 清除状态
    state.guard_point = nil

    -- 沿着路线移动
    local target = state.walk_point[state.walk_index]
    if target then
        unit:walk(target)
        if unit:get_point():distance(target:get_point()) < 200 then
            state.walk_index = state.walk_index + 1
        end
        return true
    end
end

local function none(unit, state)
    -- 如果正在遣返，则检查是否遣返完成
    if state.chase_back then
        if unit:get_point():distance(state.guard_point) > 1 then
            unit:walk(state.guard_point)
            return true
        end
        state.chase_back = nil
        state.guard_point = nil
    end

    -- 如果超出追击范围，则强制遣返
    if state.guard_point and unit:get_point():distance(state.guard_point) > state.chase_limit then
        state.chase_back = true
        unit:walk(state.guard_point)
    end

    -- 如果正在移动，则什么都不做
    if unit:is_walking() then
        return true
    end

    -- 如果允许自动攻击，则进行搜敌
    if state.auto_attack and search_and_attack(unit, state) then
        return true
    end
end

function mt:on_idle()
    local unit = self
    local state = unit._simple_ai

    if not state then
        return
    end

    -- 如果单位正在施法，则等待
    if unit:current_skill() then
        return
    end

    -- 如果单位在向远处施法，则等待
    if approach_cast(unit) then
        return
    end

    -- 锁定攻击，表示玩家主动发布攻击命令，持续攻击某个单位
    if state.mode == 'lock-attack' then
        if lock_attack(unit, state) then
            return
        end
    end

    -- 移动攻击，表示单位在一边移动一边搜敌
    if state.mode == 'walk-attack' then
        if walk_attack(unit, state) then
            return
        end
    end

    -- AI移动，使用API让单位沿着路点移动，同时也会搜敌
    if state.mode == 'ai-walk' then
        if ai_walk(unit, state) then
            return
        end
    end

    -- 空闲
    if state.mode == 'none' then
        if none(unit, state) then
            return
        end
    end

    state.mode = 'none'
end

base.game:event('单位-执行命令', function (_, unit, command, target)
    local state = unit._simple_ai
    if not state then
        return
    end
    state.guard_point = nil
    state.chase_back = nil
    if command == 'stop' then
        state.mode = 'none'
    elseif command == 'walk' then
        state.mode = 'none'
    elseif command == 'walk-attack' then
        state.mode = 'walk-attack'
        state.walk_attack = target
        search_and_attack(unit, state, '立即')
    elseif command == 'attack' then
        state.mode = 'lock-attack'
        state.lock_target = target
        lock_attack(unit, state)
    end
end)

base.game:event('单位-死亡', function (_, unit)
    local state = unit._simple_ai
    if not state then
        return
    end
    state.guard_point = nil
    state.chase_back = nil
    state.mode = 'none'
end)

base.game:event('技能-施法开始', function (_, unit, cast)
    if cast.break_order ~= 1 then
        return
    end
    local state = unit._simple_ai
    if not state then
        return
    end
    state.guard_point = nil
    state.chase_back = nil
    state.mode = 'none'
end)

base.simple_ai = {}

-- 允许在空闲状态下自动攻击
--   unit(unit) - 单位
--   enable(boolean) - 是否允许，默认为允许
function base.simple_ai.auto_attack(unit, enable)
    unit._simple_ai.auto_attack = enable
end

-- 允许搜敌
--   unit(unit) - 单位
--   enable(boolean) - 是否允许，默认为允许
function base.simple_ai.search(unit, enable)
    if enable then
        unit._simple_ai.disable_search = unit._simple_ai.disable_search - 1
    else
        unit._simple_ai.disable_search = unit._simple_ai.disable_search + 1
    end
end

-- 设置追击限制
--   unit(unit) - 单位
--   range(number/nil) - 0表示不允许追击，nil表示无限制
function base.simple_ai.chase_limit(unit, range)
    unit._simple_ai.chase_limit = range
end

-- 添加类型仇恨
--   unit(unit) - 单位
--   type(string) - 单位Id
--   threat(integer) - 仇恨值
function base.simple_ai.add_type_threat(unit, type, threat)
    unit._simple_ai.attack:add_type_threat(type, threat)
end

-- 添加队伍仇恨
--   unit(unit) - 单位
--   team(integer) - 队伍ID
--   threat(integer) - 仇恨值
function base.simple_ai.add_team_threat(unit, team, threat)
    unit._simple_ai.attack:add_team_threat(team, threat)
end

-- 添加单位仇恨
--   unit(unit) - 单位
--   target(unit) - 目标单位
--   threat(integer) - 仇恨值
--   [time(integer)] - 持续时间（毫秒）
function base.simple_ai.add_threat(unit, target, threat, time)
    unit._simple_ai.attack:add_threat(target, threat, time)
end

-- 沿着路线移动
--   unit(unit) - 单位
--   points(table/nil) - 路点列表，设置为nil可以取消移动
function base.simple_ai.walk(unit, points)
    unit._simple_ai.walk_point = points
    unit._simple_ai.walk_index = 1
    unit._simple_ai.mode = 'ai-walk'
end
