--- lua_plus ---
function base.get_ai(name:id)ai_id
    ---@ui 获取或创建名为~1~的ai表
    ---@belong ai
    ---@description 获取或创建AI表
    ---@applicable value
    return base.ai[name]
end

function base.unit_enable_ai(unit:unit)
    ---@ui 启用~1~的ai
    ---@belong ai
    ---@description 启用单位的AI
    ---@applicable action
    ---@name1 单位
    if unit_check(unit) then
        unit:enable_ai()
    end
end
 ---@keyword 启用
function base.unit_disable_ai(unit:unit)
    ---@ui 禁止用~1~的ai
    ---@belong ai
    ---@description 禁用单位的AI
    ---@applicable action
    ---@name1 单位
    if unit_check(unit) then
        unit:disable_ai()
    end
end
 ---@keyword 禁用
function base.unit_execute_ai(unit:unit)
    ---@ui 执行~1~的AI
    ---@belong ai
    ---@description 执行单位的AI
    ---@applicable action
    ---@name1 单位
    if unit_check(unit) then
        unit:execute_ai()
    end
end
 ---@keyword 执行
function base.unit_ai_attack_move_to(unit:unit, line:line, cycle:是否)
    ---@ui 令~1~沿路线~2~进攻(是否循环:~3~)
    ---@belong ai
    ---@description 令单位沿指定路线进攻
    ---@applicable action
    ---@name1 单位
    ---@name2 路线
    if unit_check(unit) then
        base.unit_add_ai(unit, '自定义AI', {
            path = line,
            cycle = cycle
        })
    end
end
 ---@keyword 路线
function base.unit_ai_move_to(unit:unit, line:line, cycle:是否)
    ---@ui 令~1~沿路线~2~行动(是否循环:~3~)
    ---@belong ai
    ---@description 令单位沿指定路线行动
    ---@applicable action
    ---@name1 单位
    ---@name2 路线
    if unit_check(unit) then
        base.unit_add_ai(unit, '仅移动AI', {
            path = line,
            cycle = cycle
        })
    end
end
 ---@keyword 路线
---comment
---@param line Point[]
---@param offset_x number
---@param offset_y number
---@return Point[]
local function line_with_offset(line:unknown, offset_x:unknown, offset_y:unknown)
    ---@type Point[]
    local new_line:unknown = {}
    for index:unknown, value:unknown in ipairs(line) do
        local x:unknown = base.math.max(50, value[1] + offset_x)
        local y:unknown = base.math.max(50, value[2] + offset_y)
        new_line[index] = base.point(x, y)
    end
    return new_line
end

function base.unit_group_ai_attack_move_to(unit_group:单位组, line:line, cycle:是否)
    ---@ui 令~1~集体沿路线~2~进攻，并尽可能保持队形(是否循环:~3~)
    ---@belong ai
    ---@description 令单位组沿指定路线进攻（保持队形）
    ---@applicable action
    ---@name1 单位组
    ---@name2 路线
    if unit_group_check(unit_group) then
        if base.unit_group_count(unit_group) <= 0 then
            return
        end
        local items_map:unknown = base.unit_group_get_items_map(unit_group)
        local max_x:unknown, max_y:unknown, min_x:unknown, min_y:unknown
        ---@type Point[]
        for unit:unknown, _:unknown in pairs(items_map) do
            local point:unknown = unit:get_point()
            max_x = or(and(max_x, base.math.max(max_x, point[1])), point[1])
            max_y = or(and(max_y, base.math.max(max_y, point[2])), point[2])
            min_x = or(and(min_x, base.math.min(min_x, point[1])), point[1])
            min_y = or(and(min_y, base.math.min(min_y, point[2])), point[2])
        end
        local center:unknown = base.point((max_x - min_x) / 2 + min_x, (max_y - min_y) / 2 + min_y, 0)
        for unit:unknown, _:unknown in pairs(items_map) do
            local point:unknown = unit:get_point()
            local offset_x:unknown = point[1] - center[1]
            local offset_y:unknown = point[2] - center[2]
            local path:unknown = line
            if and(base.math.abs(offset_x) < 1500, base.math.abs(offset_y) < 1500) then
                path = line_with_offset(line, offset_x, offset_y)
            end
            base.unit_add_ai(unit, '自定义AI', {
                path = path,
                cycle = cycle
            })
        end
    end
end
 ---@keyword 路线
function base.unit_group_ai_move_to(unit_group:单位组, line:line, cycle:是否)
    ---@ui 令~1~集体沿路线~2~行动，并尽可能保持队形(是否循环:~3~)
    ---@belong ai
    ---@description 令单位组沿指定路线行动 （保持队形）
    ---@applicable action
    ---@name1 单位组
    ---@name2 路线
    if unit_group_check(unit_group) then
        if base.unit_group_count(unit_group) <= 0 then
            return
        end
        local items_map:unknown = base.unit_group_get_items_map(unit_group)
        local max_x:unknown, max_y:unknown, min_x:unknown, min_y:unknown
        ---@type Point[]
        for unit:unknown, _:unknown in pairs(items_map) do
            local point:unknown = unit:get_point()
            max_x = or(and(max_x, base.math.max(max_x, point[1])), point[1])
            max_y = or(and(max_y, base.math.max(max_y, point[2])), point[2])
            min_x = or(and(min_x, base.math.min(min_x, point[1])), point[1])
            min_y = or(and(min_y, base.math.min(min_y, point[2])), point[2])
        end
        local center:unknown = base.point((max_x - min_x) / 2 + min_x, (max_y - min_y) / 2 + min_y, 0)
        for unit:unknown, _:unknown in pairs(items_map) do
            local point:unknown = unit:get_point()
            local offset_x:unknown = point[1] - center[1]
            local offset_y:unknown = point[2] - center[2]
            local path:unknown = line
            if and(base.math.abs(offset_x) < 1500, base.math.abs(offset_y) < 1500) then
                path = line_with_offset(line, offset_x, offset_y)
            end
            base.unit_add_ai(unit, '仅移动AI', {
                path = path,
                cycle = cycle
            })
        end
    end
end ---@keyword 路线