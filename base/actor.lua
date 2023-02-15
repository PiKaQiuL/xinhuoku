Actor = Actor or base.tsc.__TS__Class()
Actor.name = 'Actor'

-- 服务端通过rpc调用客户端actor相关api
---@class Actor
---@field set_position fun(self:Actor, x:number, y:number, z:number)
---@field set_scale fun(x:number, y:number, z:number)
---@field set_owner fun(self:Actor, player_number:number)
---@field set_grid_size fun(self:Actor, size:table)
---@field set_grid_range fun(self:Actor, start_id:table, range:table)
---@field set_grid_state fun(self:Actor, grid_id:table, state:integer)
---@field play fun()
---@field cache table?
---@field init_normal boolean?
---@field _id number
---@field sync boolean
---@field name string
local mt = Actor.prototype
local id = -1
-- actor_map保留每个id对应哪些player_slot创建了
local actor_map = setmetatable({}, { __mode = 'v' })

local sub_class_action = {}

---comment
---@param self Actor
---@param cache table
---@param on boolean
function sub_class_action.PlayAnim(self, cache, on)
    if self.parent and self.parent.type == 'unit' then
        if on then
            local unit = self.parent
            unit:play_animation(cache.PlayAnimName){
                speed = cache.PlayAnimSpeed or 1,
                loop = cache.PlayAnimLoop or false,
                part = 0,
            }
            self.PlayAnimName = cache.PlayAnimName
        else
            if self.PlayAnimName then
                self.parent:remove_animation(self.PlayAnimName)
            end
        end
    end
end

---comment
---@param name string
---@param exclude table
---@param sync boolean attach到单位后是否跟单位一起同步
---@return Actor|nil
function base.actor(name, exclude, sync)
    local cache = base.eff.cache(name)
    if not cache then
        return nil
    end
    -- exclude = {1,2}表示slot 1,2的客户端不创建actor
    exclude = exclude or {}
    if sync == nil then
        sync = true
    end
    local exclude_ids = {}
    for _, v in pairs(exclude) do
        exclude_ids[v] = true
    end

    local player_ids = base.rpc.call_other(exclude_ids, {
        method = 'create_actor',
        cls = 'actor',
        args= {id, name}
    })
    actor_map[id] = setmetatable({
        _slot_ids = player_ids,
        exclude_slots = exclude,
        _id = id,
        type = 'actor',
        sync = sync,
        name = name, -- 对应客户端ActorData.ini里的表名
        owner_id = nil, -- 所属player的slot_id
        cast_shadow = true, --有时候attach之后不cast_shadow，仅对模型表现有用
        position = { cache.Offset.X , cache.Offset.Y, cache.Offset.Z }, -- 默认创建在0,0,0位置，指相对于parent Node，parent nil就是相对于场景node
        rotation = { cache.Rotation.X, cache.Rotation.Y, cache.Rotation.Z }, -- 欧拉角
        scale = nil,
        volume = nil,
        asset = nil,
        show_ = true, -- 显示或隐藏，仅对模型和特效有效
        socket = nil,
        launch_unit = nil,
        launch_site = nil,
        launch_position = nil,
        launch_ground_z = nil,
        parent = nil  -- attach_to的unit或actor,为了简便起见，不存在多层attach，最多两层
    }, { __index = mt })
    local actor = actor_map[id]
    id = id - 1
    actor.cache = cache
    return actor
end

function mt:destroy(force)
    self:do_subclass_action(false)
    force = force or false
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'destroy',
        cls = 'actor',
        args = {self._id, force}
    })
    if self.parent and self.parent.type == 'unit' and self.sync then
        -- 更新服务器的actor
        self.parent:detach_actor(self._id)
    end
    actor_map[self._id] = nil
end

function mt:is_valid()
   return actor_map[self._id] ~= nil
end

mt.remove = mt.destroy

--只有当actor attach_to unit之后或者set_owner之后actor才有了阵营迷雾可见性
--对客户端来说set_owner只有在敌我看到的表现不一致的时候才有用
--如果敌我看到的表现一致，那set_owner应该是一个纯服务器的函数和概念
--服务器创建actor的时候，在每个客户端actor的owner都是各自客户端的slot_id
--独立的actor对player可见，attach的actor遵循父节点的可见性
function mt:attach_to(target, socket)
    -- 重置位置和旋转
    self.position = {0, 0, 0}
    self.rotation = {0, 0, 0}
    
    if target.type == 'actor' and target.parent then
        target = target.parent -- 由于actor的父子关系只会维护一层，所以只用追溯一层parent
    end
    if target.type == 'unit' then
        self.parent = target
        self.socket = socket
        if self.sync then
            -- attach_actor已经同步了其他属性
            target:attach_actor(self._id, self)
            target:update_actor(self._id, 'show', self.show_ and '1' or '0')
            if self.launch_unit then
                target:update_actor(self._id, 'launch_unit', tostring(self.launch_unit))
            end
            if self.launch_site then
                target:update_actor(self._id, 'launch_site', self.launch_site)
            end
            if self.launch_position then
                target:update_actor(self._id, 'launch_position', string.format('%f,%f,%f',self.launch_position[1],self.launch_position[2],self.launch_position[3]))
            end
            if self.launch_ground_z then
                target:update_actor(self._id, 'launch_ground_z', tostring(self.launch_ground_z))
            end
        end
        local target_id = target:get_id()
        local destroy_slots = {}
        local attach_slots = {}
        for k, _ in pairs(self._slot_ids) do
            if target:is_visible(base.player(k)) then
                -- 只有unit对player可见才发attach_to rpc
                attach_slots[k] = true
            else
                -- unit不可见则发destroy rpc
                destroy_slots[k] = true
            end
        end
        base.rpc.call_some(attach_slots, {
            method = 'attach_to',
            cls = 'actor',
            args = {self._id, target_id, socket}
        })
        base.rpc.call_some(destroy_slots, {
            method = 'destroy',
            cls = 'actor',
            args = {self._id, true}
        })
    elseif target.type == 'actor' then
        self.parent = target
        self.socket = socket
        base.rpc.call_some(self._slot_ids, {
            method = 'attach_to',
            cls = 'actor',
            args = {self._id, target._id, socket}
        })
    else
        log.warn('target must be unit or actor.')
        return
    end
    self:on_normal_init()
end

function mt:detach()
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'detach',
        cls = 'actor',
        args = {self._id}
    })
    if self.sync and self.parent and self.parent.type == 'unit' then
        self.parent:detach_actor(self._id)
    end
end

function mt:get_visible_slots()
    if self.parent and self.parent.type == 'unit' then
        local slots = {}
        for k, _ in pairs(self._slot_ids) do
            if self.parent:is_visible(base.player(k)) then
                slots[k] = true
            end
        end
        return slots
    end
    return self._slot_ids
end

function mt:show(status)
    if status == nil then
        status = true
    end
    self.show_ = status
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'show', status and '1' or '0')
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'show',
        cls = 'actor',
        args = {self._id, status}
    })
end

function mt:set_owner(owner)
    local owner_id = owner
    if base.tsc.__TS__InstanceOf(owner, Player) then
        owner_id = owner.id
    end
    self.owner_id = owner_id
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'owner_id', tostring(owner_id))
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_owner',
        cls = 'actor',
        args = {self._id, owner_id}
    })
end

function mt:set_shadow(enable)
    self.cast_shadow = enable
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'cast_shadow', enable and '1' or '0')
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_shadow',
        cls = 'actor',
        args = {self._id, enable}
    })
end

function mt:set_facing(facing)
    self:set_rotation(0, 0, facing)
end

function mt:on_normal_init()
    if self.init_normal then
        return
    end
    self.init_normal = true
    self:do_subclass_action(true)
end

function mt:do_subclass_action(on)
    if not self.cache then
        return
    end
    local action = sub_class_action[self.cache.SubClass]
    if action then
        action(self, self.cache, on)
    end
end

function mt:set_position(x0, y0, z0)
    local x, y, z = 0, 0, 0
    if type(x0) == 'table' and x0.type == 'point' then
        x, y, z = x0[1], x0[2], x0[3]
    elseif type(x0) == 'number' then
        x, y, z = x0, y0, z0
    end
    self.position = {x, y, z}
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'position', string.format('%f,%f,%f',x,y,z))
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_position',
        cls = 'actor',
        args = {self._id, x, y, z}
    })
    self:on_normal_init()
end

function mt:set_ground_z(z)
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_ground_z',
        cls = 'actor',
        args = {self._id, z}
    })
end

---comment
---@param x number|nil
---@param y? number
---@param z? number
---@param facing? number
---@param use_ground_height? boolean
function mt:set_bearings(x, y, z, facing, use_ground_height)
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_bearings',
        cls = 'actor',
        args = {self._id, x, y, z, facing, use_ground_height}
    })
end

---comment
---@param target Unit|Actor
---@param socket string?
function mt:set_position_from(target, socket)
    local slots = self:get_visible_slots()
    local tid = target._id
    if target.type == 'unit' then
        tid = target:get_id()
    end
    if not tid then
        return
    end
    base.rpc.call_some(slots, {
        method = 'set_position_from',
        cls = 'actor',
        args = {self._id, tid, socket}
    })
end

function mt:set_rotation(x, y, z)
    self.rotation = {x, y, z}
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'rotation', string.format('%f,%f,%f',x,y,z))
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_rotation',
        cls = 'actor',
        args = {self._id, x, y, z}
    })
end

function mt:set_scale(x, y, z)
    if not y then
        y = x
    end
    if not z then
        z = x
    end
    self.scale = {x, y, z}
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'scale', string.format('%f,%f,%f',x,y,z))
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_scale',
        cls = 'actor',
        args = {self._id, x, y, z}
    })
end

function mt:set_asset(asset)
    self.asset = asset
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'asset', asset)
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_asset',
        cls = 'actor',
        args = {self._id, asset}
    })
end

function mt:set_volume(volume)
    self.volume = volume
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'volume', tostring(volume))
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_volume',
        cls = 'actor',
        args = {self._id, volume}
    })
end

function mt:set_launch_site(unit, socket)
    local unit_id = nil
    if type(unit) == 'number' then
        unit_id = unit
    elseif unit.type == 'unit' then
        unit_id = unit:get_id()
    end
    self.launch_unit = unit_id
    self.launch_site = socket
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'launch_unit', tostring(unit_id))
        self.parent:update_actor(self._id, 'launch_site', socket)
    end
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_launch_site',
        cls = 'actor',
        args = {self._id, unit_id, socket}
    })
end

function mt:set_launch_position(x, y, z)
    self.launch_position = {x, y, z}
    local slots = self:get_visible_slots()
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'launch_position', string.format('%f,%f,%f',x,y,z))
    end
    base.rpc.call_some(slots, {
        method = 'set_launch_position',
        cls = 'actor',
        args = {self._id, x, y, z}
    })
end

function mt:set_launch_ground_z(z)
    self.launch_ground_z = z
    local slots = self:get_visible_slots()
    if self.parent and self.parent.type == 'unit' then
        self.parent:update_actor(self._id, 'launch_ground_z', tostring(self.launch_ground_z))
    end
    base.rpc.call_some(slots, {
        method = 'set_launch_ground_z',
        cls = 'actor',
        args = {self._id, z}
    })
end

function mt:set_grid_size(size)
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_grid_size',
        cls = 'actor',
        args = {self._id, size}
    })
end

function mt:set_grid_range(start_id, range)
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_grid_range',
        cls = 'actor',
        args = {self._id, start_id, range}
    })
end

function mt:set_grid_state(grid_id, state)
    local slots = self:get_visible_slots()
    base.rpc.call_some(slots, {
        method = 'set_grid_state',
        cls = 'actor',
        args = {self._id, grid_id, state}
    })
end

setmetatable(mt, { __newindex = function(t, k, v)
    rawset(t, k, function(caller, ...)
        local slots = caller:get_visible_slots()
        base.rpc.call_some(slots, {
            method = k,
            cls = 'actor',
            args = {caller._id, ...}
        })
    end)
end})

-- 以下是不需要同步的函数，通过__newindex添加
local actor_funcs = {
    'play',
    'play_animation',
    'stop',
    'pause',
    'resume',
    'mute'
}

for k,v in pairs(actor_funcs) do
    mt[v] = true -- 触发调用__newindex
end

function base.actor_info()
    for k, v in pairs(actor_map) do
        if v.parent and v.parent.type == 'unit' then
            if not v.parent:is_alive() then
                actor_map[k] = nil
            end
        end
    end
    return actor_map
end

--玩家切换场景删除没有parent的actor
base.game:event('玩家-切换场景', function(trg, player, scene_name)
    for k, v in pairs(actor_map) do
        if not v.parent or v.parent.type == 'actor' then
            local player_id = player:get_slot_id()
            base.rpc.call_some({[player_id]=true}, {
                method = 'destroy',
                cls = 'actor',
                args = {v._id, true}
            })
            v._slot_ids[player_id] = nil
            local cnt = 0
            local exclude_slots = {}
            for k, _ in pairs(v._slot_ids) do
                cnt = cnt + 1
                table.insert(exclude_slots, k)
            end
            v.exclude_slots = exclude_slots
            if cnt == 0 then
                actor_map[v._id] = nil
            end
        end
    end
end)

return {
    Actor = Actor
}