base.math = {}

-- 使用角度制的三角函数
local deg = math.deg(1)
local rad = math.rad(1)

-- 正弦
local sin = math.sin
function base.math.sin(r)
    return sin(r * rad)
end

-- 余弦
local cos = math.cos
function base.math.cos(r)
    return cos(r * rad)
end

-- 正切
local tan = math.tan
function base.math.tan(r)
    return tan(r * rad)
end

-- 反正弦
local asin = math.asin
function base.math.asin(v)
    return asin(v) * deg
end

-- 反余弦
local acos = math.acos
function base.math.acos(v)
    return acos(v) * deg
end

-- 反正切
local atan = math.atan
function base.math.atan(v1, v2)
    return atan(v1, v2) * deg
end

-- 浮点数比较
function base.math.float_eq(a, b)
    return math.abs(a - b) <= 1e-5
end

function base.math.float_ueq(a, b)
    return math.abs(a - b) > 1e-5
end

function base.math.float_lt(a, b)
    return a - b < -1e-5
end

function base.math.float_le(a, b)
    return a - b <= 1e-5
end

function base.math.float_gt(a, b)
    return a - b > 1e-5
end

function base.math.float_ge(a, b)
    return a - b >= -1e-5
end

-- 随机浮点数
function base.math.random_float(a, b)
    return math.random() * (b - a) + a
end

---comment
---@param n number
local function is_int(n)
    return math.floor(n) == n
end

---随机整数
function base.math.random_int(a, b)
    if type(a) == 'number' and type(b) == 'number' then
        a = math.floor(a)
        b = math.floor(b)
        return math.random(a, b)
    end
end

function base.math.random_smart(a, b)
    if not b or not a then
        return a or b
    end
    if a == b then
        return a
    end
    if is_int(a) and is_int(b) then
        return math.random(a, b)
    end
    return base.math.random_float(a, b)
end

-- 浮点数小数部分（编辑器用）
function base.math.float_modf(n)
    local _, b = math.modf(n)
    return b
end

--计算2个角度之间的夹角
function base.math.included_angle(r1, r2)
    local r = (r1 - r2) % 360
    if r >= 180 then
        return 360 - r, 1
    else
        return r, -1
    end
end

function base.math.floor(x)
    return math.floor(x)
end

function base.math.abs(x)
    return math.abs(x)
end

function base.math.ceil (x)
    return math.ceil(x)
end

function base.math.deg (x)
    return math.deg(x)
end

function base.math.exp (x)
    return math.exp(x)
end

function base.math.floor (x)
    return math.floor(x)
end

function base.math.fmod (x, y)
    return math.fmod(x, y)
end

base.math.huge = math.huge

function base.math.log(...)
    return math.log(...)
end

function base.math.max(...)
    return math.max(...)
end

base.math.maxinteger = math.maxinteger

function base.math.min(...)
    return math.min(...)
end

base.math.mininteger = math.mininteger

function base.math.modf(x)
    return math.modf(x)
end

base.math.pi = math.pi

function base.math.rad(x)
    return math.rad(x)
end

function base.math.random(...)
    return math.random(...)
end

function base.math.randomseed(x)
    return math.randomseed(x)
end

function base.math.sqrt(x)
    return math.sqrt (x)
end

function base.math.tointeger(x)
    return math.tointeger(x)
end

function base.math.type(x)
    return math.type(x)
end

function base.math.ult(m, n)
    return math.ult(m, n)
end