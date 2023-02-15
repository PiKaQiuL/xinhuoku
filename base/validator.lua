local base = base
--实现验证器的组合逻辑
base.validator = {}

local validator = base.validator
local eff = base.eff
local e_site = eff.e_site
local e_target_type=base.eff.e_target_type

--打包验证器调用
function base.validator.Wrap(...)
    return {...}
end

---And逻辑
--[[参数样例
base.validator.And(
    override_err_text,
    override_err_sound,
    {验证距离, eff_param, 5}, 实际使用时，用上面base.validator.Wrap打包，便于触发识别
    {验证法力值, eff_param, 300},
    {验证等级, eff_param, 2}
)]]
---@return number
---@return string
---@return string
function base.validator.And(...)
    local args = {...}
    local override_err_text, override_err_sound
    if args[1] ~= nil and args[1] ~= '' then
        override_err_text = args[1]
    end
    if args[2] ~= nil and args[2] ~= '' then
        override_err_sound = args[2]
    end
    local err_code, err_text, err_sound
    for i = 3, #args do
        local ft = args[i]
        err_code, err_text, err_sound = ft[1](select(2, table.unpack(ft)))
        if err_code ~= 0 then
            return err_code, override_err_text or err_text, override_err_sound or err_sound
        end
    end
    return 0
end

function base.validator.Or(...)
    local args = {...}
    local override_err_text, override_err_sound
    if args[1] ~= nil and args[1] ~= '' then
        override_err_text = args[1]
    end
    if args[2] ~= nil and args[2] ~= '' then
        override_err_sound = args[2]
    end
    local err_code, err_text, err_sound
    for i = 3, #args do
        local ft = args[i]
        err_code, err_text, err_sound = ft[1](select(2, table.unpack(ft)))
        if err_code == 0 then
            return 0
        end
    end
    return err_code, override_err_text or err_text, override_err_sound or err_sound
end

function base.validator.Not(...)
    local err_code, err_text, err_sound = base.validator.And(...)
    if err_code == 0 then
        return 1, err_text, err_sound
    else
        return 0
    end
end

-- ---比较
-- ---@param err_text string
-- ---@param err_sound string
-- ---@param value1 any 比较值1
-- ---@param cmp string "<|>|==|<=|>="
-- ---@param value2 any 比较值2
-- ---@return number err_code
-- ---@return string err_text
-- ---@return string err_sound
-- function base.validator.Compare(err_text, err_sound, value1, cmp, value2)
--     if cmp == '<' and value1 < value2 then
--         return 0
--     elseif cmp == '==' and value1 == value2 then
--         return 0
--     elseif cmp == '>' and value1 > value2 then
--         return 0
--     elseif cmp == '<=' and value1 <= value2 then
--         return 0
--     elseif cmp == '>=' and value1 >= value2 then
--         return 0
--     end

--     return 1, err_text, err_sound
-- end


local nan = 0/0
local inf = 1/0

---效果树自定义值[key]
---@param ref_param EffectParam
---@param key string
---@return number
function validator.user_data(ref_param, key)
    if key == nil or #key == 0 then
        return nan
    end

    local value = ref_param:user_data()[key]
    if not value then
        return nan
    end

    return value
end

---获取效果目标
---@param ref_param EffectParam
---@param site string 枚举，见base.eff.e_site
---@param type string 枚举，见base.eff.e_target_type
---@return Target
function validator.parse_loc(ref_param, site, type)
    local target = ref_param:get_site_target(site)
    if type == nil or type == e_target_type.any then
        return target
    end
    if type == e_target_type.point then
        return target:get_point()
    end
    if type == e_target_type.unit then
        return target:get_unit()
    end
end

---~A~和~B~之间的距离，~考虑/不考虑~单位自身尺寸
---@param ref_param EffectParam
---@param loc_a LocExpress
---@param loc_b LocExpress
---@param use_radius boolean
---@return number
function validator.loc_range(ref_param, loc_a, loc_b, use_radius)
    local a = ref_param:parse_loc(loc_a)
    local b = ref_param:parse_loc(loc_b)

    if a == nil or b == nil then
        return nan
    end

    local range = a:get_point():distance(b:get_point())

    if use_radius then
        range = range - a:get_attackable_radius() - b:get_attackable_radius()
        if range < 0 then
            range  = 0
        end
    end

    return range
end

---~A~到~B~的角度
---@param ref_param EffectParam
---@param loc_a LocExpress
---@param loc_b LocExpress
---@return number
function validator.loc_arc(ref_param, loc_a, loc_b)
    local a = ref_param:parse_loc(loc_a)
    local b = ref_param:parse_loc(loc_b)

    if a == nil or b == nil then
        return nan
    end

    local angle = a:get_point():angle_to(b:get_point())
    if angle == nil then
        if a:get_point():distance(b:get_point()) == 0 then
            angle = 0
        else
            angle = nan
        end
    end

    return angle
end


---~A~的目标类型
---@param ref_param EffectParam
---@param loc LocExpress
---@return string 枚举类型，无|单位|点|快照
function validator.loc_type(ref_param, loc)
    local a = ref_param:parse_loc(loc)

    if a == nil or a.type == nil then
        return "nil"
    end

    return a.type
end

---~A~对玩家~B~可见
---@param ref_param EffectParam
---@param ply PlayerExpress
---@param loc LocExpress
---@return boolean
function validator.loc_vision(ref_param, loc, ply)
    local a = ref_param:parse_loc(loc)
    local player = ref_param:parse_player(ply)

    if a == nil or player == nil then
        return false
    end

    return a:is_visible_to(player)
end


---玩家~A~对玩家~B~是盟友
---@param ref_param EffectParam
---@param ply_a PlayerExpress
---@param ply_b PlayerExpress
---@return boolean
function validator.is_player_ally(ref_param, ply_a, ply_b)
    local a = ref_param:parse_player(ply_a)
    local b = ref_param:parse_player(ply_b)

    if a == nil or b == nil then
        return false
    end

    return a:get_team_id() == b:get_team_id()
end