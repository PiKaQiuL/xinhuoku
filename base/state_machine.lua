-- state 相关api
local mt = {}
mt.__index = mt

base.runtime.state_machine = mt
function mt:transit(state_id)
    self:internal_transit(state_id)
end

-- state 相关api
local mt = {}
mt.__index = mt

base.runtime.state_machine_state = mt
