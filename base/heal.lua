
local setmetatable = setmetatable
local math = math
local table_insert = table.insert

HealInstance = HealInstance or base.tsc.__TS__Class()
HealInstance.name = 'HealInstance'

local mt = HealInstance.prototype

--来源
mt.source = nil

--目标
mt.target = nil

--治疗量
mt.heal = 0

--当前治疗43
mt.current_heal = 0

--累计的治疗倍率变化
mt.change_rate = 1

function mt:is_skill()
	return self.skill and self.skill:is_skill()
end

function mt:get_heal()
	return self.heal
end

function mt:get_current_heal()
	return self.current_heal
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

local function on_texttag(self)
	if self.current_heal < 1 then
		return
	end
	local text = ('%d'):format(math.floor(self.current_heal))
	local source_player = self.source and self.source:get_owner()
	local target_player = self.target and self.target:get_owner()
	local done_for_source_player = false
	if self.source:get_tag() == '英雄' then
		self.source:texttag(self.target, text, '生命恢复', 'self')
		done_for_source_player = true
	end
	if (source_player ~= target_player or not done_for_source_player) and self.target:get_tag() == '英雄' then
		self.target:texttag(self.target, text, '生命恢复', 'self')
	end
end

local function on_heal_mul_div(heal)
	--禁止获取治疗
	heal.get_heal, heal.get_current_heal = false, false
	
	heal.source:event_notify('造成治疗', heal)
	heal.target:event_notify('受到治疗', heal)

	heal.get_heal, heal.get_current_heal = nil

	heal.current_heal = heal.current_heal * heal.change_rate

	if heal.cost_mul then
		for _, data in ipairs(heal.cost_mul) do
			local n, callback = data[1], data[2]
			heal.current_heal = heal.current_heal * (1 + n)
			callback(heal)
		end
	end

	if heal.cost_div then
		for _, data in ipairs(heal.cost_div) do
			local n, callback = data[1], data[2]
			heal.current_heal = heal.current_heal * (1 - n)
			callback(heal)
		end
	end
end

function mt:dispatch()
	self.success = false
	if not self.target or self.heal == 0 then
		self.current_heal = 0
		return
	end

	if not self.target:is_alive() then
		self.current_heal = 0
		return
	end

	self.current_heal = self.heal
	
	--进行治疗计算
	on_heal_mul_div(self)
	
	if self.current_heal < 0 then
		self.current_heal = 0
	end

	self.success = true
	
	--总之就是加了一口血
	self.target:add('生命', self.current_heal)

	self.source:event_notify('造成治疗效果', self)
	self.target:event_notify('受到治疗效果', self)
	
	on_texttag(self)

	self.source:event_notify('造成治疗结束', self)
	self.target:event_notify('受到治疗结束', self)
end

--治疗单位
function base.runtime.unit:heal(data)
	if not data.source then
		data.source = self
	end
	if not data.target then
		data.target = self
	end
	local heal = setmetatable(data, mt)
	heal:dispatch()
end

function base.runtime.unit:heal_ex(unit, amount)
	local heal = {
		source = self,
		target = unit,
		heal = amount,
	}
	self:heal(heal)
end


return {
	HealInstance = HealInstance
}