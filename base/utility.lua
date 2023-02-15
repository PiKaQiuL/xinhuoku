
Region = Region or base.tsc.__TS__Class()
Region.name = 'Region'

Target = Target or base.tsc.__TS__Class()
Target.name = 'Target'

Mover = Mover or base.tsc.__TS__Class()
Mover.name = 'Mover'

Sight = Sight or base.tsc.__TS__Class()
Sight.name = 'Sight'

function base.hash(str)
    -- djb33
    local hash = 5381
    for i = 1, #str do
        hash = (hash << 5) + hash + str:byte(i)
        hash = hash & 0xFFFFFFFF
    end
    return hash
end

function base.sight_line(start, angle, len)
    local r = base.tsc.__TS__New(Sight)
    for l = 0, len, 128 do
        table.insert(r, start:polar_to({angle, l + 128}))
    end
    return r
end

function base.math_angle(r1, r2)
	local r = (r1 - r2) % 360
	if r >= 180 then
		return 360 - r, 1
	else
		return r, -1
	end
end

function base.sight_range(poi, radius)
    local tbl = base.tsc.__TS__New(Sight)
    for r = radius, 0, -128 do
        local delta = math.acos(1-8192/r/r)
        delta = 360 / math.ceil(360 / delta)
        for l = 0, 360, delta do
            table.insert(tbl, poi:polar_to({ l, r }))
        end
    end
    return tbl
end

function base.split(str, p)
    local rt = {}
    string.gsub(str, '[^' .. p .. ']+', function (w) table.insert(rt, w) end)
    return rt
end

function base.utf8_sub(s, i, j)
    local codes = { utf8.codepoint(s, 1, -1) }
    local len = #codes
    if i < 0 then
        i = len + 1 +i
    end
    if i < 1 then
        i = 1
    end
    if j < 0 then
        j = len + 1 + j
    end
    if j > len then
        j = len
    end
    if i > j then
        return ''
    end
    return utf8.char(table.unpack(codes, i, j))
end

function base.to_type(value, expect_type)
    if expect_type == 'float' then
        if type(value) == 'number' then
            return value
        else
            return 0.0
        end
    elseif expect_type == 'int' then
        if math.type(value) == 'integer' then
            return value
        else
            return 0
        end
    elseif expect_type == 'bool' then
        if type(value) == 'boolean' then
            return value
        else
            return false
        end
    elseif expect_type == 'string' then
        if type(value) == 'string' then
            return value
        else
            return ''
        end
    elseif expect_type == 'handle' then
        if type(value) == 'table' or type(value) == 'userdata' then
            return value
        else
            return nil
        end
    end
end

function base.check_skill(skill)
    if skill and skill:is_skill() then
        return skill
    end
    return nil
end

function base.check_attack(attack)
    if attack and not attack:is_skill() then
        return skill
    end
    return nil
end

function base.check_point(point)
    if type(point) == 'table' and point.type == 'point' then
        return point
    end
    if (type(point) == 'table' or type(point) == 'userdata') and point.get_point then
        return point:get_point()
    end
    return nil
end

function base.check_unit(unit)
    if type(unit) == 'userdata' and unit.type == 'unit' then
        return unit
    end
    return nil
end

function base.get_x(obj)
    local x, y = obj:get_xy()
    return x
end

function base.get_y(obj)
    local x, y = obj:get_xy()
    return y
end

function base.remove(obj)
    if obj then
        obj:remove()
    end
end

function base.bit_has(int, bit)
    if not math.tointeger(int) then
        return false
    end
    return int & bit ~= 0
end

function base.is_cast(skill)
    if skill:is_skill() and skill:is_cast() then
        return true
    end
    return false
end

local gc_mt = {}
gc_mt.__mode = 'k'
gc_mt.__index = gc_mt
function gc_mt:__shl(obj)
    if obj == nil then
        return nil
    end
    self[obj] = true
    return obj
end
function gc_mt:flush()
    for obj in pairs(self) do
        obj:remove()
    end
end
function base.gc()
    return setmetatable({}, gc_mt)
end

function base.default(v, default)
    if v == nil then
        return default
    end
    return v
end

return {
    Region = Region,
    Target = Target,
    Mover = Mover
}