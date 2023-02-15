local mt = {}
mt.__index = mt
mt.x_scale = 1.0
mt.y_scale = 1.0
mt.z_scale = 1.0
mt.target = nil
mt.height = 0.0
mt.speed = 1.0
mt.face = 0.0
mt.angle = {0.0, 0.0, 0.0}

function mt:remove()
    if self._removed then
        return
    end
    self._removed = true
    self._dummy:remove()
    if self.on_remove then
        self:on_remove()
    end
end

function mt:get_dummy()
    return self._dummy
end

function mt:set_remaining(time)
    if self._remove_timer then
        self._remove_timer:remove()
    end
    if self._removed then
        return
    end
    self._remove_timer = base.wait(time * 1000, function ()
        self:remove()
    end)
end

function mt:set_sync(sync)
    self._dummy:set_sync(sync)
end

local function create_effect(self, data)
    local name = data.model
    local unit_data = base.table.unit[name]
    if not unit_data then
        error(('单位[%s]不存在'):format(name), 3)
    end
    --[[
    local effect_data = base.table.effect[name]
    if not effect_data then
        error(('特效[%s]不存在'):format(name), 3)
    end
    ]]
    local target
	local height = nil
    if data.target.type == 'point' then
		target = data.target
	else
		target = data.target[1]
        height = data.target[2]
	end
	local face
	if type(data.angle) == 'table' then
		face = 0
	else
		face = data.angle or 0
    end
    local dummy = self:create_unit(data.model, target, face)
    if not dummy then
        return nil
    end

    data._dummy = dummy

    if height then
        dummy:set_height(height)
    end

    if data.size then
        dummy:set_model_attribute('缩放', data.size)
    end
    if data.x_scale then
        dummy:set_model_attribute('X轴缩放', data.x_scale)
    end
    if data.y_scale then
        dummy:set_model_attribute('Y轴缩放', data.y_scale)
    end
    if data.z_scale then
        dummy:set_model_attribute('Z轴缩放', data.z_scale)
    end
    if type(data.angle) == 'table' then
        dummy:set_model_attribute('朝向', data.angle)
    else
        dummy:set_model_attribute('朝向', {0, 0, 0})
	end
    if data.speed then
        dummy:set_model_attribute('动画速度', data.speed)
    end

    if data.sight then
        dummy:add_sight(data.sight)
    --[[
    elseif effect_data.SightType == 1 then
        dummy:add_sight(base.sight_line(data.target, effect_data.SightAngle, effect_data.SightLine))
    elseif effect_data.SightType == 2 then
        dummy:add_sight(base.sight_range(data.target, effect_data.SightRange))]]
    end
    if data.sync then
        dummy:set_sync(data.sync)
    end

    local effect = setmetatable(data, mt)

    if data.time then
        effect:set_remaining(data.time)
    end

    if effect.on_create then
        effect:on_create()
    end
    return effect
end

function base.runtime.player:effect(data)
    return create_effect(self, data)
end

function base.runtime.unit:effect(data)
    return create_effect(self, data)
end
