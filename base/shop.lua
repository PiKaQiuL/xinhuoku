local undo_list = setmetatable({}, { __mode = 'k' })
local function get_undo_list(unit)
    local list = undo_list[unit]
    if not list then
        list = {}
        undo_list[unit] = list
    end
    return list
end

local function on_can_buy(unit, name)
    local bind = base.item.method[name]
    if not bind.on_can_buy then
        return
    end
    return bind:on_can_buy(unit)
end

local function on_item_buy(unit, name)
    local player = unit:get_owner()

    local buy_price = item.BuyPrice or 0
    if player:get '金钱' < buy_price then
        return false, '金钱不足'
    end

    player:add_gold(-buy_price, '购物')
    local item = unit:create_item(name)

    if not item then
        return false, '创建失败'
    end

    return true, item
end

local function buy_item(unit, name)
    local data = base.table.item[name]
    if not data then
        return false, '物品不存在'
    end
    -- 检查自定义购买规则
    local suc, res = on_can_buy(unit, name)
    if suc ~= nil then
        return suc, res
    end
    -- 购买物品
    local suc, res = on_item_buy(unit, name)
    if suc ~= nil then
        return suc, res
    end
    return false, '未知原因'
end

local function on_can_sell(unit, item)
    if not item.on_can_sell then
        return
    end
    return item:on_can_sell(unit)
end

local function on_sell_item(unit, item)
    local player = unit:get_owner()
    local sell_price = item.SellPrice or 0
    player:add_gold(sell_price,'出售棋子')
    return true
end

local function sell_item(unit, item)
    if unit ~= item:get_holder() then
        return false, '单位不持有这个物品'
    end
    -- 检查自定义出售规则
    local suc, res = on_can_sell(unit, item)
    if suc ~= nil then
        return suc, res
    end
    -- 出售物品
    local suc, res = on_sell_item(unit, item)
    if suc ~= nil then
        return suc, res
    end
    return false, '未知原因'
end

function base.runtime.unit:buy_item(name)
    local suc, res = buy_item(self, name)
    if suc then
        self:event_notify('单位-购买物品成功', self, name, res)
        local bind = base.item.method[name]
        if bind.on_buy then
            bind.on_buy(self)
        end
        return res
    else
        self:event_notify('单位-购买物品失败', self, name, res)
        return nil
    end
end

function base.runtime.unit:sell_item(item)
    if type(item) ~= 'table' or item.type ~= 'item' then
        error('sell_item 的参数必须是物品', 2)
    end
    if item._removed then
        return false
    end
    local suc, res = sell_item(self, item)
    if suc then
        self:event_notify('单位-出售物品成功', self, item)
        if item.on_sell then
            item:on_sell(self)
        end
        return true
    else
        self:event_notify('单位-出售物品失败', self, item, res)
        return false
    end
end
