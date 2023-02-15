local math = math
local table = table
local setmetatable = setmetatable
local type = type

Point = Point or base.tsc.__TS__Class()
Point.name = 'Point'

---@class Point:Target
---@field is_visible fun(self:Point, player:Player):boolean
---@field group_range fun(self:Point, radius:number, tag:string, scene_name:string, boolean:boolean):Unit[]
---@field group_line fun(self:Point, width:number, height:number, angle:number, scene_name:string, boolean:boolean):Unit[]
---@field group_sector fun(self:Point, radius:number, angle:number, arc:number, scene_name:string, boolean:boolean):Unit[]
local mt = Point.prototype

--注册点(C)
base.runtime.point = mt

--类型
mt.type = 'point'

--坐标
mt[1] = 0
mt[2] = 0
mt[3] = 0

--创建一个点
--	base.point(x, y, z)
local function create_point(x, y, z)
    return setmetatable({x, y, z}, mt)
end

if base.test then
    function mt:__tostring()
        return ('{point|%08X|(%f, %f, %d)}'):format(base.test.topointer(self), self[1], self[2], self[3])
    end
else
    function mt:__tostring()
        return ('{point|(%f, %f, %d)}'):format(self[1], self[2], self[3])
    end
end

--获取坐标
--	@2个坐标值
function mt:get_xy()
    return self[1], self[2]
end

function mt:get_x()
    return self[1]
end

function mt:get_y()
    return self[2]
end

-- 获取z
function mt:get_z()
    return self[3]
end

function mt:get_scene()
    return nil
end

function mt:get_scene_name()
    return self:get_scene()
end

mt.__call = mt.get_xy

--复制点
function mt:copy()
    return base.point(self[1], self[2], self[3])
end

function mt:copy_to_scene_point(scene)
    return base.scene_point(self[1], self[2], self[3], scene)
end

--返回点
function mt:get_point()
    return self
end

-- 转换为矢量
function mt:to_vector(height)
    return {self[1], self[2], height}
end

--按照极坐标系移动(point:polar_to({angle, distance}))
--	@新点
local cos = base.math.cos
local sin = base.math.sin
function mt:__add(data)
    return create_point(self[1] + data[1], self[2] + data[2], self[3] + data[3])
end

--按照极坐标系移动(point:polar_to({angle, distance}))
--	@新点
function mt:__sub(data)
    local x, y = self[1], self[2]
    local angle, distance = data[1], data[2]
    return create_point(x + distance * cos(angle), y + distance * sin(angle))
end

--求距离(point * point)
function mt:__mul(dest)
    return self:distance(dest)
end

--求方向(mt / point)
local atan = base.math.atan
function mt:__div(dest)
    return self:angle(dest)
end

function mt:__unm()
    return create_point(-self[1], -self[2], -self[3])
end

function mt:add(data)
    return create_point(self[1] + data[1], self[2] + data[2], self[3] + data[3])
end

--按照极坐标系移动(point:polar_to{angle, distance} )
--	@新点
function mt:polar_to(data)
    local x, y = self[1], self[2]
    local angle, distance = data[1], data[2]
    return create_point(x + distance * cos(angle), y + distance * sin(angle))
end

function mt:polar_to_ex(angle, distance)
    local x, y = self[1], self[2]
    return create_point(x + distance * cos(angle), y + distance * sin(angle))
end

--求方向(向量self和向量dest的夹角)
function mt:angle(dest)
    local x1, y1 = self[1], self[2]
    local x2, y2 = dest[1], dest[2]
    return atan(y2 - y1, x2 - x1)
end

--与目标的距离
local sqrt = math.sqrt
function mt:distance(dest)
    local x1, y1 = self[1], self[2]
    local x2, y2 = dest[1], dest[2]
    local x0 = x1 - x2
    local y0 = y1 - y2
    return sqrt(x0 * x0 + y0 * y0)
end

-- 将self映射到坐标系(point, facing)后, self在该坐标系里的位置
function mt:to_coordinate(point, facing)
    local offset = self + (-point)
    if facing ~= 0 then
        local sin_a = sin(facing)
        local cos_a = cos(facing)
        offset[1], offset[2] = cos_a * offset[1] + sin_a * offset[2], -sin_a * offset[1] + cos_a * offset[2]
    end

    return offset
end

base.point = create_point

function mt:get_unit()
    return nil
end

function mt:get_owner()
    return nil
end

function mt:get_facing()
    return nil
end

function mt:get_team_id()
    return nil
end

---comment
---@param dest Target
---@return boolean
function mt:is_ally(dest)
    return self:get_team_id() == dest:get_team_id()
end

---comment
---@param dest table
---@return number
function mt:angle_to(dest)
    local x1, y1 = self[1], self[2]
    local x2, y2 = dest[1], dest[2]
    if(x1==y1 and x2==y2)then
        return nil
    end
    return atan(y2 - y1, x2 - x1)
end

function mt:get_snapshot()
	local snapshot=base.snapshot:new()
	snapshot.origin_type='point'
	snapshot.point=self:get_point()
    return snapshot
end

--TODO: 需要特别指定一个中立玩家：
function mt:create_effect(model)
	base.player(0):effect{
        model = model,
        target = {self , self[3] or 0},
        time = 0.7,
        speed = 1,
    }
end

---comment
---@param dest Player
---@return boolean
function mt:is_visible_to(dest)
    return self:is_visible(dest)
end

function mt.has_restriction(_,_)
    return false
end

---comment
function mt.has_label(_,_)
    return false
end

---comment
function mt.get_attackable_radius(_)
    return 0
end

return {
    Point = Point
}