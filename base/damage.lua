local setmetatable = setmetatable
local tostring = tostring
local math = math
local ac_event_dispatch = base.event_dispatch
local ac_event_notify = base.event_notify
local table_insert = table.insert
local table_remove = table.remove

DamageInstance = DamageInstance or base.tsc.__TS__Class()
DamageInstance.name = 'DamageInstance'

local mt = DamageInstance.prototype

--类型
mt.type = 'damage'

--来源
mt.source = nil

--目标
mt.target = nil

--初始伤害
mt.damage = 0

--当前伤害
mt.current_damage = 0

--是否成功
mt.success = true

--关联技能
mt.skill = nil

--关联弹道
mt.missile = nil

--是否触发攻击特效
mt.attack = nil

--是否是Aoe伤害
mt.aoe = false

--是否是暴击
mt.crit_flag = nil

--累计的伤害倍率变化
mt.change_rate = 1

--跳字类型
mt.text_type = nil

--伤害类型
mt.damage_type = nil

--是否是暴击
function mt:is_crit()
	return self.crit_flag
end

--伤害是否触发攻击效果
function mt:is_attack()
	if self.attack == nil then
		self.attack = self.skill and self.skill:is_common_attack()
	end
	return self.attack
end

--是否是AOE
function mt:is_aoe()
	return self.aoe
end

--是否是物品
function mt:is_item()
	return self.skill and self.skill:is_skill() and self.skill:get_type() == '物品'
end

--获取原始伤害
function mt:get_damage()
	return self.damage
end

--获取当前伤害
function mt:get_current_damage()
	return self.current_damage
end

---comment
---@param amount number
function mt:set_current_damage(amount)
	self.current_damage = amount
end

--获取伤害方向
function mt:get_angle()
	return self.angle or self.source:get_point():angle(self.target:get_point())
end

function mt:mul(n, callback)
	if callback then
		if not self.cost_mul then
			self.cost_mul = {}
		end
		table_insert(self.cost_mul, {n, callback})
		return
	end
	self.change_rate = self.change_rate * (1 + n)
end

function mt:div(n, callback)
	if callback then
		if not self.cost_div then
			self.cost_div = {}
		end
		table_insert(self.cost_div, {n, callback})
		return
	end
	self.change_rate = self.change_rate * (1 - n)
end

-- 初始化属性
function mt:on_attribute_attack()
	if self.has_attribute_attack then
		return
	end
	self.has_attribute_attack = true
	local source = self.source
	if not self['破甲'] then
		self['破甲'] = source:get '破甲'
	end
	if not self['穿透'] then
		self['穿透'] = source:get '穿透'
	end
	if not self['暴击'] then
		self['暴击'] = source:get '暴击'
	end
	if not self['暴击伤害'] then
		self['暴击伤害'] = source:get '暴击伤害'
	end
	if not self['吸血'] then
		self['吸血'] = source:get '吸血'
	end
	if not self['法术破甲'] then
		self['法术破甲'] = source:get '法术破甲'
	end
	if not self['法术穿透'] then
		self['法术穿透'] = source:get '法术穿透'
	end
	if not self['攻击范围'] then
		self['攻击范围'] = source:get '攻击范围'
	end
	if not self.damage_type then
		if self.skill and self.skill:is_common_attack() then
			self.damage_type = '物理'
		else
			self.damage_type = '魔法'
		end
	end
end

function mt:on_attribute_crit()
	if self.crit_flag ~= nil then
		return
	end
	if not self:is_attack() or self.target:get_tag() == '建筑' then
		self.crit_flag = false
		return
	end
	if self['暴击'] >= math.random(100) then
		self.crit_flag = true
	else
		self.crit_flag = false
	end
end

function mt:on_attribute_defence()
	if self.has_attribute_defence then
		return
	end
	self.has_attribute_defence = true
	local target = self.target
	if not self['护甲'] then
		self['护甲'] = target:get '护甲'
	end
	if not self['格挡'] then
		self['格挡'] = target:get '格挡'
	end
	if not self['魔抗'] then
		self['魔抗'] = target:get '魔抗'
	end
end

-- 计算暴击伤害
local function on_crit(self)
	if self:is_crit() then
		self:mul(self['暴击伤害'] / 100 - 1)
	end
end

local function on_block(self)
	if self.dot then
		return
	end
	local block = self['格挡']
	if block <= 0 then
		return
	end
	local skill = self.skill
	if skill and skill:is_skill() and skill:is_cast() then
		local target = self.target
		if not skill._has_block then
			skill._has_block = {}
		end
		if not skill._has_block[target] then
			skill._has_block[target] = 0
		end
		if skill._has_block[target] >= block then
			return
		end
		skill._has_block[target] = skill._has_block[target] + math.min(block, self.current_damage)
		if skill._has_block[target] > block then
			self.current_damage = skill._has_block[target] - block
			skill._has_block[target] = block
			return
		end
	end
	self.current_damage = self.current_damage - block
end

--护甲减免伤害
mt.DEF_SUB = 0.01
mt.DEF_ADD = 0.01

local function on_defence(self)
	local target = self.target
	local def, pene, pene_rate
	if self.damage_type == '物理' then
		def = self['护甲']
		pene, pene_rate = self['破甲'], self['穿透']
	else
		def = self['魔抗']
		pene, pene_rate = self['法术破甲'], self['法术穿透']
	end
	-- 计算护甲穿透
	if def > 0 and self.target:get_tag() ~= '建筑' then
		if pene_rate < 100 then
			def = def * (1 - pene_rate / 100)
		else
			def = 0
		end
		def = def - pene
		if def < 0 then
			def = 0
		end
	end
	if def < 0 then
		--每点负护甲相当于受到的伤害加深
		local def = - def
		self.current_damage = self.current_damage * (1 + self.DEF_ADD * def)
	elseif def > 0 then
		--每点护甲相当于生命值增加 X%
		self.current_damage = self.current_damage / (1 + self.DEF_SUB * def)
	end
end

local function on_life_steal(self)
	if self:is_item() then
		return
	end
	local life_steal = self['吸血']
	if life_steal == 0 then
		return
	end
	if self.aoe then
		life_steal = life_steal * 0.25
	end
	self.source:heal
	{
		source = self.source,
		heal = self.current_damage * life_steal / 100,
		skill = self.skill,
		damage = self,
		life_steal = true,
	}
end

local function format_damage(damage, text_type)
	if text_type == '物理流血' or text_type == '魔法流血' then
		return ('%.3f'):format(damage)
	else
		return tostring(math.floor(damage))
	end
end

--伤害漂浮文字
local function on_texttag(self)
	if self.current_damage < 1 then
		return
	end
	local text_type = self.text_type
	if text_type == '无' then
		self.text_type = nil
		return
	end
	if not text_type then
		if self.damage_type == '物理' then
			if self:is_crit() then
				text_type = '物理暴击'
			else
				text_type = '物理伤害'
			end
		elseif self.damage_type == '魔法' then
			if self:is_crit() then
				text_type = '魔法暴击'
			else
				text_type = '魔法伤害'
			end
		else
			text_type = '物理伤害'
		end
		self.text_type = text_type
	end
	local source_player = self.source and self.source:get_owner()
	local target_player = self.target and self.target:get_owner()
	local done_for_source_player = false
	if self.source:get_tag() == '英雄' then
		self.source:texttag(self.target, format_damage(self.current_damage, text_type), text_type, 'self')
		done_for_source_player = true
	else
		local p = self.source:get_owner()
		if p then
			local hero = p:get_hero()
			if hero then
				hero:texttag(self.target, format_damage(self.current_damage, text_type), text_type, 'self')
				done_for_source_player = true
			end
		end
	end
	if (source_player ~= target_player or not done_for_source_player) and self.target:get_tag() == '英雄' then
		self.target:texttag(self.target, format_damage(self.current_damage, text_type), text_type, 'self')
	end
end

local function on_damage_mul_div(self)
	--禁止获取伤害
	self.get_damage = false
	self.get_current_damage = false

	self.source:on_response("ResponseDamage", base.response.e_location.Attacker, self.ref_param, self)
	self.target:on_response("ResponseDamage", base.response.e_location.Defender, self.ref_param, self)

	self.source:event_notify('造成伤害', self)
	self.target:event_notify('受到伤害', self)

	self.get_damage = nil
	self.get_current_damage = nil

	self.current_damage = self.current_damage * self.change_rate

	if self.cost_mul then
		for _, data in ipairs(self.cost_mul) do
			local n, callback = data[1], data[2]
			callback(self)
			self.current_damage = self.current_damage * (1 + n)
		end
	end

	if self.cost_div then
		for _, data in ipairs(self.cost_div) do
			local n, callback = data[1], data[2]
			callback(self)
			self.current_damage = self.current_damage * (1 - n)
		end
	end
end

local function cost_shield(self)
    local target = self.target
    local effect_damage = self.current_damage
    local shields = target._shields
    if not shields then
        return effect_damage
    end
    local lost_shields = {}
    for _, shield in ipairs(shields) do
        if effect_damage < shield.life then
            shield:add_life( - effect_damage)
            effect_damage = 0
            break
        end
        effect_damage = effect_damage - shield.life
        lost_shields[#lost_shields+1] = shield
    end
    for _, shield in ipairs(lost_shields) do
        shield:remove()
    end
    if #shields == 0 then
        target:set('护盾', 0)
    end
    return effect_damage
end

--死亡
function mt:kill()
	local target = self.target
	if target:has_restriction '免死' then
		target:set('生命', 0)
		return false
	end
	if target:event_dispatch('单位-即将死亡', self) == false then
		return false
	end
	return target:kill(self.source)
end

--开始一次伤害流程
base.event['伤害-结算'] = function (self)
	---@type Unit Description
	local source, target = self.source, self.target
	self.success = false
	if not target or not target:is_alive() then
		self.current_damage = 0
		return
	end
	if self.skill and self.skill:is_common_attack() then
		if target:has_restriction '物免' then
			self.current_damage = 0
			return
		end
	else
		if target:has_restriction '魔免' then
			self.current_damage = 0
			return
		end
	end

	if not source then
		self.source = self.target
		source = target
		log.error('伤害没有伤害来源')
	end

	ac_event_notify(self, '伤害初始化', self)

	if self.damage == 0 then
		self.current_damage = 0
		return
	end

	self:on_attribute_attack()
	self:on_attribute_crit()
	self:on_attribute_defence()

	self.current_damage = self.damage

	--检验伤害有效性
	if source:event_dispatch('造成伤害开始', self) == false then
		self.current_damage = 0
		return
	end

	if target:event_dispatch('受到伤害开始', self) == false then
		self.current_damage = 0
		return
	end

	if self.damage_type ~= '真实' then
		source:event_notify('造成伤害前效果', self)
		target:event_notify('受到伤害前效果', self)

		-- TODO: 用attack模拟的法球不支持*伤害初始化*事件
		if self:is_attack() then
			if not self.has_attack_start then
				source:event_notify('法球开始', self)
			end
			if not self.has_attack_shot then
				source:event_notify('法球出手', self)
			end
		end
		ac_event_notify(self, '伤害前效果', self)

		-- 计算暴击
		on_crit(self)
		--计算格挡
		on_block(self)
		--计算护甲
		on_defence(self)
		--加成和减免
		on_damage_mul_div(self)
	end

	self.success = true

	--造成伤害
	if self.current_damage < 0 then
		self.current_damage = 0
	end

	--消耗护盾
	local effect_damage = cost_shield(self)
	local life = target:get '生命'
	if life <= effect_damage then
		local shield_absorbed = self.current_damage - effect_damage
		self.fatal = true
		if source then
			source:on_response("ResponseDamage", base.response.e_location.Attacker, self.ref_param, self)
		end
		if target then
			target:on_response("ResponseDamage", base.response.e_location.Defender, self.ref_param, self)
		end
		effect_damage = self.current_damage - shield_absorbed
		if life <= effect_damage then
			self:kill()
		else
			self.fatal = false
			target:set('生命', life - effect_damage)
		end
	else
		target:set('生命', life - effect_damage)
	end
	--漂浮文字
	on_texttag(self)
	-- 伤害通知
	if self.skill then
		self.skill:notify_damage(self)
	end

	if self.damage_type ~= '真实' then

		if self.target:get_tag() ~= '建筑' then
			--吸血
			on_life_steal(self)
		end

		--伤害效果
		source:event_notify('造成伤害效果', self)
		target:event_notify('受到伤害效果', self)
	end

	source:event_notify('造成伤害结束', self)
	target:event_notify('受到伤害结束', self)
end

base.event['伤害-攻击开始'] = function (self)
	self.common_attack = true
	self:on_attribute_attack()
	self.has_attack_start = true
	self.source:event_notify('单位-攻击开始', self)
	self.source:event_notify('法球开始', self)
	self:on_attribute_crit()
end

base.event['伤害-攻击出手'] = function (self)
	self.has_attack_shot = true
	self.source:event_notify('单位-攻击出手', self)
	self.source:event_notify('法球出手', self)
end

function mt:event(name, f)
	local events = self._events
	if not events then
		events = {}
		self._events = events
	end
	local event = events[name]
	if not event then
		event = {}
		events[name] = event
	end
	return base.trigger(event, f)
end

--需要注册的事件
local event_subscribe_list = {
	['造成伤害开始']	= '单位-造成伤害',
	['受到伤害开始']	= '单位-受到伤害',
	['造成伤害前效果']	= '单位-造成伤害',
	['受到伤害前效果']	= '单位-受到伤害',
	['造成伤害-加']		= '单位-造成伤害',
	['受到伤害-加']		= '单位-受到伤害',
	['造成伤害-减']		= '单位-造成伤害',
	['受到伤害-减']		= '单位-受到伤害',
	['造成伤害']		= '单位-造成伤害',
	['受到伤害']		= '单位-受到伤害',
	['造成伤害效果']	= '单位-造成伤害',
	['受到伤害效果']	= '单位-受到伤害',
	['造成伤害结束']	= '单位-造成伤害',
	['受到伤害结束']	= '单位-受到伤害',
	['单位-即将死亡']	= '单位-受到伤害',
}
for k, v in pairs(event_subscribe_list) do
	base.event_subscribe_list[k] = v
end

--为每个英雄注册一个初始的伤害事件
base.game:event('单位-创建英雄', function(_, hero)
	hero:event_subscribe '单位-造成伤害'
	hero:event_subscribe '单位-受到伤害'
	hero:event_subscribe '单位-攻击开始'
end)

base.runtime.damage = mt

return {
	DamageInstance = DamageInstance
}