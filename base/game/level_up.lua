local default_gameplay_id = "$$.gameplay.dflt.root"
local setting_raw = false

base.game:unit_attribute_sync('等级', 'self|sight')

local function get_xp_grant_rule()
    local default_gameplay = base.eff.cache(default_gameplay_id)
    return default_gameplay and default_gameplay.XPGrantRule
end

---获取单位升级配置
function base.runtime.unit:get_level_profile()
    if self.level_profile then
        return base.eff.cache(self.level_profile)
    else
        local cache = base.eff.cache(self:get_name())
        if cache then
            local level_profile_id = cache.LevelProfile
            return base.eff.cache(level_profile_id)
        end
    end
end

-- 计算level-1升到level级所需的经验
local function calc_single_level_exp(profile, level)
    if level <= 0 then
        return 0
    elseif profile.XPLevelValues[level] then
        return profile.XPLevelValues[level]
    else
        return profile.XPLevelFactor*level + profile.XPBonusPerLevel
    end
end

-- 计算0升到level级所需的经验和
local function calc_cumu_level_exp(profile, level)
    if level < 0 then
        return 0
    end
    if level == 0 then
        return 0
    end

    local values_count = #profile.XPLevelValues
    local total = 0
    for i = 1, values_count do
        total = total + profile.XPLevelValues[i]
        if i == level then
            return total
        end
    end

    -- values_count ~ level
    total = total + profile.XPBonusPerLevel*(level-values_count) + profile.XPLevelFactor*(level+values_count+1)*(level-values_count)/2

    return total
end

-- 计算经验对应的[等级、剩余经验]
local function calc_rem_exp(profile, exp, max_level)
    if max_level <= 0 then
        return 0, exp
    end
    local values_count = #profile.XPLevelValues
    for i = 1, values_count do
        local level_exp = calc_single_level_exp(profile, i)
        if level_exp <= exp then
            exp = exp - level_exp
            if i >= max_level then
                return i, exp
            end
        else
            return i - 1, exp
        end
    end
    local level = values_count
    local step = 1
    while true do
        local next_level = level + step
        if next_level > max_level then
            if step <= 1 then
                return level, exp
            else
                step = step/2
            end
        else
            local level_exp = profile.XPBonusPerLevel*step + profile.XPLevelFactor*(level+next_level+1)*step/2
            if level_exp <= exp then
                level = next_level
                exp = exp - level_exp
                step = step*2
            else
                if step <= 1 then
                    return level, exp
                else
                    step = step/2
                end
            end
        end
    end
end

---获取单位当前等级
---@return number
function base.runtime.unit:get_level()
    return self:get_ex('等级', 0)
end

local function set_level_raw(unit, level, max_level)
    setting_raw = true
    if unit:get_ex('等级', 0) ~= level then
        unit:set_ex('等级', level, 0)
    end
    if level < max_level then
        unit:set_attribute_sync('升级所需经验', 'self')
        unit:set_ex('升级所需经验', unit:get_single_level_exp(level + 1) , 0)
    else
        unit:set_attribute_sync('升级所需经验', 'self')
        unit:set_ex('升级所需经验', math.huge, 0)
    end
    setting_raw = false
end

---获取单位等级上限
---@return number
function base.runtime.unit:get_max_level()
    return self:get_ex('等级上限', 0)
end

local function set_max_level_raw(unit, max_level)
    setting_raw = true
    unit:set_ex('等级上限', max_level, 0)
    setting_raw = false
end

---获取单位当前总经验
---@return number
function base.runtime.unit:get_exp()
    return self:get_ex('经验', 0)
end

local function set_exp_raw(unit, exp)
    setting_raw = true
    unit:set_ex('经验', exp, 0)
    setting_raw = false
end

---获取单位当前等级剩余经验
---@return number
function base.runtime.unit:get_rem_exp()
    return self:get_ex('剩余经验', 0)
end

local function set_rem_exp_raw(unit, rem_exp)
    setting_raw = true
    unit:set_attribute_sync('剩余经验', 'self')
    unit:set_ex('剩余经验', rem_exp, 0)
    setting_raw = false
end

---获取单位经验倍率
---@return number
function base.runtime.unit:get_exp_fraction()
    local level_profile = self:get_level_profile()
    if not level_profile then
        return 0
    end
    if self.exp_fraction_override then
        return self.exp_fraction_override
    end
    return level_profile.Fraction
end

---设置单位经验倍率
---@param fraction number
function base.runtime.unit:set_exp_fraction(fraction)
    local level_profile = self:get_level_profile()
    if not level_profile then
        return
    end
    self.exp_fraction_override = fraction
end

-- 刷新单位等级属性
local function refresh_unit_level_attributes(unit)
    -- log.debug(unit, "refresh_unit_level_attributes")
    local level_profile = unit:get_level_profile()
    if not level_profile then
        return 0
    end
    if not unit.level_attributes then
        unit.level_attributes = {}
    end

    for _, pair in ipairs(unit.level_attributes) do
        local it_delta = 0 - (pair.Value)
        if pair.Percentage then
            unit:add_ex(pair.Key, it_delta, 2)
        else
            unit:add_ex(pair.Key, it_delta, 1)
        end
    end

    unit.level_attributes = {}
    if not level_profile.AttributePerLevel then
        return
    end

    local level = unit:get_level()
    local index_reversed = #level_profile.AttributePerLevel
    for index, pair in ipairs(level_profile.AttributePerLevel) do
        local value_accumulated = (level and pair.Value(unit:get_creation_param()) * (level - 1)) or 0
        unit.level_attributes[index_reversed - index + 1] = { Key = pair.Key, Value = value_accumulated, Percentage = pair.Percentage }
        local it_delta = value_accumulated
        if pair.Key == '经验' or pair.Key == '等级' or pair.Key == '等级上限' or pair.Key == '剩余经验' then
            log.warn("不支持在升级属性加成设置经验相关属性")
        else
            if pair.Percentage then
                unit:add_ex(pair.Key, it_delta, 2)
            else
                unit:add_ex(pair.Key, it_delta, 1)
            end
        end
    end
end

---设置单位等级
---@param level number
---@return number
function base.runtime.unit:set_level(level)
    -- log.debug(self, "set_level", level)
    local level_profile = self:get_level_profile()
    if not level_profile then
        return 0
    end

    if level < 0 then
        level = 0
    end
    local max_level = self:get_max_level()
    if level > max_level then
        level = max_level
    end

    local curr_level = self:get_level()
    if level == curr_level then
        return curr_level
    end

    local exp = calc_cumu_level_exp(level_profile, level)
    self:set_exp(exp)
    return level
end

---增加单位等级
---@param level number
---@return number
function base.runtime.unit:add_level(level)
    -- log.debug(self, "add_level", level)
    local level_profile = self:get_level_profile()
    if not level_profile then
        return 0
    end

    local curr_level = self:get_level()
    return self:set_level(curr_level + level)
end

---设置单位等级上限
---@param max_level number
function base.runtime.unit:set_max_level(max_level)
    set_max_level_raw(self, max_level)
    if self:get_level() > max_level then
        self:set_exp(self:get_exp())
    end
end

---设置单位当前总经验
---@param exp number
---@return number
function base.runtime.unit:set_exp(exp)
    -- log.debug(self, "set_exp", exp)
    local level_profile = self:get_level_profile()
    if not level_profile then
        return 0
    end

    local curr_level = self:get_level()
    local max_level = self:get_max_level()
    local new_level, new_rem_exp = calc_rem_exp(level_profile, exp, max_level)

    set_exp_raw(self, exp)
    set_level_raw(self, new_level, max_level)
    set_rem_exp_raw(self, new_rem_exp)

    refresh_unit_level_attributes(self)

    self:event_notify('单位-获得经验', {hero = self, exp = self:get_exp()})
    if curr_level ~= new_level then
        self:event_notify('单位-升级', self, new_level)
    end
    return self:get_exp()
end

---单位获得经验
---@param exp number
---@param ignore_fraction boolean 是否忽略单位经验倍率
---@return number
function base.runtime.unit:add_exp(exp, ignore_fraction)
    -- log.debug(self, "add_exp", exp, ignore_fraction)
    local level_profile = self:get_level_profile()
    if not level_profile then
        return 0
    end

    local curr_level = self:get_level()
    local curr_exp = self:get_exp()
    local curr_rem_exp = self:get_rem_exp()

    if exp == 0 then
        return curr_exp
    end

    if ignore_fraction == nil then
        ignore_fraction = false
    end
    if not ignore_fraction then
        exp = exp * self:get_exp_fraction()
    end

    self:event_notify('单位-即将获得经验', {hero = self, exp = exp})

    if exp<0 then
        self:set_exp(curr_exp + exp)
    else
        local max_level = self:get_max_level()
        local curr_level_max_xp = calc_single_level_exp(level_profile, curr_level + 1)
        if curr_level < max_level and exp + curr_rem_exp >= curr_level_max_xp then
            -- 如果升级，全部重设
            self:set_exp(curr_exp + exp)
        else
            -- 如果已满级或不够升级，直接加上
            set_exp_raw(self, curr_exp + exp)
            set_rem_exp_raw(self, curr_rem_exp + exp)
            self:event_notify('单位-获得经验', {hero = self, exp = self:get_exp()})
        end
    end

    return self:get_exp()
end

---计算单位某一级所需的经验值
---@param level number
---@return number
function base.runtime.unit:get_single_level_exp(level)
    local level_profile = self:get_level_profile()
    if not level_profile then
        return 0
    end
    local max_level = self:get_max_level()
    if level > max_level then
        return -1
    end
    return calc_single_level_exp(level_profile, level)
end

---计算单位升到指定等级所需的总经验值
---@param level number
---@return number
function base.runtime.unit:get_cumu_level_exp(level)
    local level_profile = self:get_level_profile()
    if not level_profile then
        return 0
    end
    local max_level = self:get_max_level()
    if level > max_level then
        return -1
    end
    return calc_cumu_level_exp(level_profile, level)
end

---初始化单位升级配置
function base.runtime.unit:init_level_profile(profile)
    if not profile then
        return
    end
    set_max_level_raw(self, profile.Level)
    self:set_exp(self:get_exp() or 0)
end

---设置单位升级配置
function base.runtime.unit:set_level_profile(profile_id)
    local curr_level_profile = self:get_level_profile()
    self.level_profile = profile_id

    local level_profile = self:get_level_profile()
    if level_profile then
        if  not curr_level_profile then
            self:init_level_profile(level_profile)
        else
            set_max_level_raw(self, level_profile.Level)
            self:set_exp(self:get_exp())
        end
    end
end

---设置是否禁止单位参与击杀经验值分配
---@param value boolean
function base.runtime.unit:set_prohibit_exp_distribute(value)
    self.prohibit_exp_distribution = value
end

base.game:event('单位-初始化', function(_, unit)
    if unit:is_illusion() then
        return
    end

    local level_profile = unit:get_level_profile()
    -- log.debug(unit, level_profile)
    if not level_profile then
        return
    end
    -- log.debug(level_profile.Level)
    unit:init_level_profile(level_profile)
end)

base.game:event('单位-死亡', function (_, killed_unit, killer, kill_type)
    -- log.debug('单位-死亡', killed_unit, killer, kill_type)
    local xp_grant_rule = get_xp_grant_rule()
    if not xp_grant_rule or not xp_grant_rule.XPGrant then
        return
    end
    local xp_grant = xp_grant_rule.XPGrant(killed_unit, killer, kill_type)
    if not xp_grant or xp_grant == 0 then
        return
    end

    local target_filter = base.target_filters:new(xp_grant_rule.XPDistributionFilter)
    local validator = xp_grant_rule.XPDistributionCheck
    local function validate(unit)
        local level_profile = unit:get_level_profile()
        if not level_profile then
            return false
        end
        local max_level = unit:get_max_level()
        if not max_level or max_level <= 0 then
            return false
        end
        if unit.prohibit_exp_distribution then
            return false
        end
        if (not level_profile.MaxLevelLeech) and unit:get_level() >= max_level then
            return false
        end
        if target_filter:validate(killed_unit, unit) ~= base.eff.e_cmd.OK then
            return false
        end
        if not validator then
            return true
        end
        return validator(unit, killed_unit, killer)
    end

    local killer_valid = validate(killer)
    local killer_grant = 0
    local function distribute(group)
        local group_out = {}
        if killer_valid then
            table.insert(group_out, killer)
        end
        for _, it_unit in ipairs(group) do
            if it_unit ~= killer and validate(it_unit) then
                table.insert(group_out, it_unit)
            end
        end
        if #group_out == 0 then
            return 0
        end
        local per_unit_grant = xp_grant / #group_out
        for _, it_unit in ipairs(group_out) do
            if it_unit == killer then
                it_unit:add_exp(killer_grant + per_unit_grant)
            else
                it_unit:add_exp(per_unit_grant)
            end
        end
        return #group_out
    end

    -- 击杀者独占
    if killer_valid then
        local level_profile = killer:get_level_profile()
        killer_grant = xp_grant * level_profile.KillerFraction
        xp_grant = xp_grant - killer_grant
    end

    if xp_grant == 0 then
        return
    end

    -- 剩余均分
    local scene_name = killed_unit:get_scene_name()
    local radius = xp_grant_rule.XPDistributionRadius
    local group = base.selector():allow_god():in_circle(base.circle(killed_unit:get_point(), radius)):of_scene(scene_name):of_type('all'):enable_death(true):get()
    local distribute_count = distribute(group)

    -- 均分不到（范围内没人、击杀者不合法）
    if distribute_count == 0 then
        if xp_grant_rule.XPDistributionGlobal then
            local scale_x, scale_y = base.game.get_scene_scale(scene_name)
            local scene_rect = base.rect(base.point(0, 0), base.point(scale_x, scale_y), scene_name)
            group = base.selector():allow_god():in_rect(scene_rect):of_scene(scene_name):of_type('all'):enable_death(true):get()
            distribute(group)
        end
    end
end)

base.game:event('单位-属性变化', function(_, unit, key, value, change_value)
    -- 事件必须是阻塞的，保证自己设值的时候setting_raw为true，其他途径修改时为false
    if setting_raw or change_value == 0 then
        return
    end
    local level_profile = unit:get_level_profile()
    if not level_profile then
        return
    end
    if key == base.table.constant['单位属性']['经验'] then
        -- log.debug('更新经验')
        unit:set_exp(unit:get_exp())
    elseif key == base.table.constant['单位属性']['等级'] then
        -- log.debug('更新等级')
        unit:set_level(unit:get_level())
    elseif key == base.table.constant['单位属性']['等级上限'] then
        -- log.debug('更新等级上限')
        unit:set_max_level(unit:get_max_level())
    elseif key == base.table.constant['单位属性']['剩余经验'] then
        -- ?
    end
end)

-- TODO: 删除get_max_exp、set_level_exp