base.game:event('单位-购买物品', function (_, unit, name)
    unit:buy_item(name)
end)

base.game:event('单位-出售物品', function (_, unit, slot)
    local skill = unit:find_skill(slot, '物品')
    if not skill then
        return
    end
    local item = base.item.get(skill)
    if not item then
        return
    end
    unit:sell_item(item)
end)
