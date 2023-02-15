local base = base
local log = log

Channeler = base.tsc.__TS__Class()
Channeler.name = 'Channeler'

--技能与引导效果通讯的类
---@class Channeler
base.channeler = Channeler.prototype

base.channeler.type = 'channeler'

---comment
---@return Channeler
function base.channeler:new()
    local channeler={ count = 0, ref_params = {} }
    setmetatable(channeler, self)
    return channeler
end

function base.channeler:start_channeling()
    if(not self.count) then
        log.error('引导器已销毁，无法开始引导。引导器：'..self.tostring())
    end
    self.count=self.count+1
end

function base.channeler:stop_channeling()
    if self.count<=0 then
        log.error('引导器计数小于0，无法停止引导。引导器：'..self.tostring())
    end

    self.count=self.count-1
    if(self.count<=0)then
        self:clear()
    end
end

function base.channeler:is_channeling()
    return self.count>0
end

function base.channeler:register(ref_param)
    table.insert(self.ref_params,ref_param)
end

function base.channeler:clear()
    self.count=nil
    if(not self.ref_params)then
        return
    end
    for _, value in ipairs(self.ref_params) do
        value:on_channeler_cleared()
    end
    self.ref_params=nil
end

function base.channeler:is_valid()
    return self.count~=nil
end

Channeled = base.tsc.__TS__Class()
Channeled.name = 'Channeled'

--引导效果与技能通讯的类
---@class Channeled
base.channeled = Channeled.prototype
base.channeled.type = 'channeled'

function base.channeled:new()
    local channeled={}
    setmetatable(channeled, self)
    return channeled
end

function base.channeled:start_channeling(channeler)
    self:stop_channeling()
    if not channeler then
        return
    end
    self.channeler=channeler
    channeler:start_channeling()
end

function base.channeled:stop_channeling()
    if not self.channeler then
        return
    end
    self.channeler:stop_channeling()
end

function base.channeled:is_channeling()
    if not self.channeler then
        return false
    end
    return self.channeler:is_channeling()
end

return {
    Channeler = Channeler,
    Channeled = Channeled
}