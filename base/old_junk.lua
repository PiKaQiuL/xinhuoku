local skill = base.lni:create('skill', base.table.skill)
base.lni:current(skill)
base.lni[=[
['.拾取物品']
max_level = 1
init_level = 1
affect_unit_tag = {'物品'}
break_walk = 1
instant = 1
ignore_uncontrol = 1
target_type = 1
affect_type = 7
need_cast_in_range = 1

['.丢弃物品']
max_level = 1
init_level = 1
break_walk = 1
instant = 1
ignore_uncontrol = 1
target_type = 3
need_cast_in_range = 1
]=]

local item_map = setmetatable({}, { __mode = 'k' })

local function method_tostring(self)
    return ('{item|%s} <- %s'):format(self._name, self._skill or self._unit)
end

local function count_item(unit)
    local count = 0
    for skill in unit:each_skill() do
        if item_map[skill] then
            count = count + 1
        end
    end
    return count
end

local function create_to_point(item, point)
    local unit = item._owner:create_unit(item._name, point, 0)
    if not unit then
        return nil
    end
    item._unit = unit
    item_map[unit] = item
    item:event_notify('物品-创建', item)
    return item
end

local function create_to_unit(item, target, skill_name)
    if item._has_skill then
        if count_item(target) >= target:get '物品栏' then
            return create_to_point(item, target:get_point())
        end
        local skill = target:add_skill(skill_name, '物品')
        if not skill then
            return nil
        end
        item._skill = skill
        item_map[skill] = item
    end
    item:event_notify('物品-创建', item)
    target:event_notify('单位-获得物品', target, item)
    if item.on_get then
        item:on_get(target)
    end
    return item
end

local function create(name, owner, target)
    local data = base.table.item[name]
    if not data then
        error(('错误的物品名：[%s]'):format(name), 3)
    end
    if not base.table.unit[name] then
        error(('没有找到关联单位：[%s]'):format(name), 3)
    end
    local skill_name = data.Skill
    local has_skill = true
    if not base.table.skill[skill_name] then
        has_skill = false
    end
    if type(owner) ~= 'userdata' or (owner.type ~= 'unit' and owner.type ~= 'player') then
        error('物品所有者必须是单位或玩家', 3)
    end
    if (type(target) ~= 'userdata' or target.type ~= 'unit') and (type(target) ~= 'table' or target.type ~= 'point') then
        error('物品创建位置必须是单位或点', 3)
    end

    local item = setmetatable({
        _name = name,
        _owner = owner,
        _has_skill = has_skill,
    }, base.item.method[name])

    if target.type == 'unit' then
        return create_to_unit(item, target, skill_name)
    else
        return create_to_point(item, target)
    end
end

local function save_skill(item)
    local skill = item._skill
    item._cd = skill:get_cd()
    item._stack = skill:get_stack()
    item._save_time = base.clock()
end

local function load_skill(item)
    local skill = item._skill
    local passed_itme = base.clock() - item._save_time
    local cool = skill.cool
    if skill.ignore_cooldown_reduce == 0 then
        cool = cool - cool * skill.owner:get '冷却缩减' / 100.0
    end
    item._cd = item._cd - passed_itme / 1000.0
    if skill.cooldown_mode ~= 0 then
        for stack = item._stack+1, skill.charge_max_stack do
            if item._cd > 0 then
                break
            end
            item._cd = item._cd + cool
            item._stack = stack
            if stack == skill.charge_max_stack then
                item._cd = 0
            end
        end
    end
    if item._cd > 0 then
        if cool < item._cd then
            skill:active_cd(item._cd, false)
        else
            skill:active_cd(cool, false)
            skill:set_cd(item._cd)
        end
    end
    if item._stack ~= skill:get_stack() then
        skill:add_stack(item._stack - skill:get_stack())
    end
end

local function remove_as_skill(item)
    local skill = item._skill
    if not skill then
        return false
    end
    save_skill(item)
    item._skill = nil
    item_map[skill] = nil
    skill:remove()
    return true
end

local function remove_as_unit(item)
    local unit = item._unit
    if not unit then
        return false
    end
    item._unit = nil
    item_map[unit] = nil
    unit:remove()
    return true
end

local function add_item(item, unit)
    if unit == item:get_holder() then
        return false
    end
    local skill
    if item._has_skill then
        if count_item(unit) >= unit:get '物品栏' then
            return false
        end
        skill = unit:add_skill(item.Skill, '物品')
        if not skill then
            return false
        end
    end
    local source = item._skill and item._skill.owner
    remove_as_unit(item)
    remove_as_skill(item)
    if skill then
        item._skill = skill
        item_map[skill] = item
        load_skill(item)
    end
    
    if source then
        source:event_notify('单位-失去物品', source, item)
        if item.on_lose then
            item:on_lose(source)
        end
    end
    unit:event_notify('单位-获得物品', unit, item)
    if item.on_get then
        item:on_get(unit)
    end
    
    return true
end

local function pick_item(item, unit)
    local target = item._unit
    if not target then
        return false
    end
    if count_item(unit) >= unit:get '物品栏' then
        return false
    end
    local skill = unit:find_skill '.拾取物品'
    if not skill then
        skill = unit:add_skill('.拾取物品', '隐藏')
        if not skill then
            return false
        end
    end
    skill:set_option('range', item.PickRange or 0)
    return unit:cast('.拾取物品', target, { pick_item = item })
end

local function blink_item(item, target)
    if item._skill then
        local unit = item._owner:create_unit(item._name, target, 0)
        if not unit then
            return false
        end
        local source = item._skill.owner
        remove_as_skill(item)
        item._unit = unit
        item_map[unit] = item
        source:event_notify('单位-失去物品', source, item)
        if item.on_lose then
            item:on_lose(source)
        end
        return true
    else
        item._unit:blink(target)
        return true
    end
end

local function drop_item(item, unit, target)
    if not item._skill or item._skill.owner ~= unit then
        return
    end
    local skill = unit:find_skill '.丢弃物品'
    if not skill then
        skill = unit:add_skill('.丢弃物品', '隐藏')
        if not skill then
            return false
        end
    end
    skill:set_option('range', item.DropRange or 0)
    return unit:cast('.丢弃物品', target, { drop_item = item })
end

local function find_item_by_name(unit, name)
    if not base.table.item[name] then
        return nil
    end
    for skill in unit:each_skill() do
        local item = item_map[skill]
        if item and item._name == name then
            return item
        end
    end
    return nil
end

local function find_item_by_slot(unit, slot)
    for skill in unit:each_skill() do
        local item = item_map[skill]
        if item and skill:get_slot_id() == slot then
            return item
        end
    end
    return nil
end

local DUMMY_FUNCTION = function () end

local function each_item(unit, name)
    if name and not base.table.item[name] then
        return DUMMY_FUNCTION
    end
    local items
    for skill in unit:each_skill() do
        local item = item_map[skill]
        if item then
            if not name or name == item._name then
                if items then
                    items[#items+1] = item
                else
                    items = {item}
                end
            end
        end
    end
    if items then
        local i = 0
        return function ()
            i = i + 1
            return items[i]
        end
    else
        return DUMMY_FUNCTION
    end
end

local function get(obj)
    return item_map[obj]
end

local method = setmetatable({}, {
    __index = function (self, name)
        local data = base.table.item[name]
        if not data then
            error(('物品[%s]不存在'):format(name), 2)
        end
        local bind = {}
        data.__index = data
        bind.__index = bind
        bind.__tostring = method_tostring
        setmetatable(bind, data)
        setmetatable(data, base.item.runtime)
        rawset(self, name, bind)
        return bind
    end,
})

local mt = base.skill['.拾取物品']
function mt:on_cast_finish()
    local unit = self.owner
    local item = self.pick_item
    if not item then
        return
    end
    add_item(item, unit)
end

local mt = base.skill['.丢弃物品']
function mt:on_cast_finish()
    local unit = self.owner
    local item = self.drop_item
    if not item then
        return
    end
    local target = self:get_target()
    if target.type == 'point' then
        blink_item(item, target)
    elseif target.type == 'unit' then
        add_item(item, target)
    end
end

local mt = {}
mt.__index = mt

mt.type = 'item'
-- 物品名字
mt._name = nil
-- 所有者
mt._owner = nil
-- 关联技能对象
mt._skill = nil
-- 关联单位对象
mt._unit = nil
-- 层数
mt._stack = 0
-- 冷却
mt._cd = 0
-- 保存时间
mt._save_time = 0

-- 获取所有者
function mt:get_owner()
    return self._owner
end

-- 获取持有者
function mt:get_holder()
    if self._skill then
        return self._skill.owner
    end
    return nil
end

-- 获取物品名字
function mt:get_name()
    return self._name
end

-- 删除物品
function mt:remove()
    if self._removed then
        return
    end
    self._last_point = self:get_point()
    self._removed = true
    remove_as_skill(self)
    remove_as_unit(self)
    item:event_notify('物品-移除', item)
end

-- 获取状态
function mt:state()
    if self._removed then
        return 'removed'
    end
    if self._skill then
        return 'held'
    end
    if self._unit then
        return 'placed'
    end
    return 'unknow'
end

-- 获取位置
function mt:get_point()
    if self._removed then
        return self._last_point or base.point(0, 0)
    end
    if self._skill then
        return self._skill.owner:get_point()
    end
    if self._unit then
        return self._unit:get_point()
    end
    return base.point(0, 0)
end

-- 传送物品到某个位置
function mt:blink(target)
    if self._removed then
        return
    end
    return blink_item(self, target:get_point())
end

-- 发起事件
function mt:event_dispatch(name, ...)
    local res, arg = base.event_dispatch(self, name, ...)
    if res ~= nil then
        return res, arg
    end
    local res, arg = base.event_dispatch(base.game, name, ...)
    if res ~= nil then
        return res, arg
    end
    return nil
end

function mt:event_notify(name, ...)
    base.event_notify(self, name, ...)
    base.event_notify(base.game, name, ...)
end

-- 创建物品
    -- 名字
    -- 单位/点
function base.runtime.player:create_item(name, target)
    return create(name, self, target)
end

-- 创建物品
    -- 名字
    -- [单位/点]
function base.runtime.unit:create_item(name, target)
    return create(name, self, target or self)
end

-- 添加物品
    -- 物品
function base.runtime.unit:add_item(item)
    if type(item) ~= 'table' or item.type ~= 'item' then
        error('add_item 的参数必须是物品', 2)
    end
    if item._removed then
        return false
    end
    return add_item(item, self)
end

-- 令单位拾取物品
    -- 物品
function base.runtime.unit:pick_item(item)
    if type(item) ~= 'table' or item.type ~= 'item' then
        error('pick_item 的参数必须是物品', 2)
    end
    if item._removed then
        return false
    end
    return pick_item(item, self)
end

-- 令单位将物品扔在地上
    -- 物品
    -- 位置
function base.runtime.unit:drop_item(item, target)
    if type(item) ~= 'table' or item.type ~= 'item' then
        error('drop_item 的参数#1必须是物品', 2)
    end
    if type(target) ~= 'table' or target.type ~= 'point' then
        error('drop_item 的参数#2必须是点', 2)
    end
    if item._removed then
        return false
    end
    return drop_item(item, self, target)
end

-- 令单位将物品交给另一个单位
    -- 物品
    -- 单位
function base.runtime.unit:give_item(item, target)
    if type(item) ~= 'table' or item.type ~= 'item' then
        error('give_item 的参数#1必须是物品', 2)
    end
    if type(item) ~= 'userdata' or item.type ~= 'unit' then
        error('give_item 的参数#2必须是单位', 2)
    end
    if item._removed then
        return false
    end
    return drop_item(item, self, target)
end

-- 寻找单位的物品
    -- 物品名
function base.runtime.unit:find_item(name)
    local tp = type(name)
    if tp == 'string' then
        return find_item_by_name(self, name)
    elseif tp == 'integer' then
        return find_item_by_slot(self, name)
    else
        error('find_item 的参数必须是字符串或整数', 2)
    end
end

-- 遍历单位的物品
    -- [物品名]
function base.runtime.unit:each_item(name)
    return each_item(self, name)
end

---@field get_name fun():string
base.item = {
    get = get,
    method = method,
    runtime = mt,
}
