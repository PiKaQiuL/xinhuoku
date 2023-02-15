--- lua_plus ---
function base.create_item_on_point(id:item_id, target:point)item
    ---@ui 在~2~处创建物品~1~
    ---@belong item
    ---@description 创建物品
    ---@applicable both
    ---@arg1 base.unit_get_point(e.unit)
    local item:unknown = base.item.create_to_point(id, target, target:get_scene())
    base.last_created_item = item
    return item
end
 ---@keyword 创建 点
function base.create_item_on_unit(id:item_id, target:unit)item
    ---@ui 创建物品~1~并交给~2~
    ---@belong item
    ---@description 为单位创建物品
    ---@applicable both
    ---@arg1 e.unit
    if unit_check(target) then
        local item:unknown = base.item.create_to_unit(id, target)
        base.last_created_item = item
        return item
    end
end
 ---@keyword 创建 单位
function base.unit_add_item(unit:unit, item:item)boolean
    ---@ui 为~1~添加物品~2~
    ---@belong item
    ---@description 将物品添加给单位
    ---@applicable action
    ---@arg1 base.get_last_created_item()
    ---@arg2 e.unit
    if and(unit_check(unit), item_check(item)) then
        return item:add_to(unit)
    end
end
 ---@keyword 添加 单位
function base.unit_has_item(unit:unit, id:item_id)boolean
    ---@ui 单位~1~是否持有物品~2~
    ---@belong item
    ---@description 单位是否持有指定ID的物品
    ---@applicable value
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:has_item(id)
    end

end
 ---@keyword 持有 单位
function base.unit_all_items(unit:unit)table<item>
    ---@ui 获取~1~身上所有物品
    ---@belong item
    ---@description 获取单位身上所有物品
    ---@applicable value
    ---@arg1 e.unit
    if unit_check(unit) then
        return unit:all_items()
    end
end
 ---@keyword 获取
function base.item_add_extra_mod(item:item, buff_id_name:buff_id, IsEquip:IsEquip)
    ---@ui 为~1~添加额外增益词条~2~,在~3~栏中生效
    ---@belong item
    ---@description 为物品添加额外增益词条
    ---@applicable action
    if item_check(item) then
        return item:add_extra_mod(buff_id_name, IsEquip)
    end
end
 ---@keyword 词条
function base.remove_extra_mod(item:item, buff_id_name:buff_id, IsEquip:IsEquip)
    ---@ui 移除~1~的一条~3~栏上的额外增益词条~2~
    ---@belong item
    ---@description 为物品移除额外增益词条
    ---@applicable action
    if item_check(item) then
        return item:remove_extra_mod(buff_id_name, IsEquip)
    end
end
 ---@keyword 词条
function base.item_generate_rand_mod(item:item)
    ---@ui 为~1~生成词条随机结果
    ---@belong item
    ---@description 为物品的词条生成随机结果（每个词条只会生成一次）
    ---@applicable action
    if item_check(item) then
        return item:generate_rand_mod()
    end
end
 ---@keyword 词条
function base.get_last_created_item()item
    ---@ui 触发器最后创建的物品
    ---@belong item
    ---@description 触发器最后创建的物品
    ---@applicable value
    return base.last_created_item
end
 ---@keyword 物品
function base.item_rnd_value(item:item, buff_id_name:buff_id, prop_name:单位属性)
    ---@ui 物品~1~的词条~2~中~3~属性的随机结果
    ---@belong item
    ---@description 物品的词条随机结果
    ---@applicable value
    if item_check(item) then
        return item:randomized_value(buff_id_name, prop_name)
    end
end
 ---@keyword 词条
function base.item_set_stack(item:item, stack:number)
    ---@ui 设置~1~的堆叠层数为~2~
    ---@belong item
    ---@description 设置物品堆叠层数
    ---@applicable action
    if item_check(item) then
        item:set_stack(stack)
    end
end
 ---@keyword 词条
function base.item_stack(item:item)number
    ---@ui ~1~的堆叠层数
    ---@belong item
    ---@description 物品的堆叠层数
    ---@applicable value
    if item_check(item) then
        return or(item.stack, 0)
    end
end
 ---@keyword 单位
function base.item_unit(item:item)unit
    ---@ui 物品~1~的物品单位
    ---@belong item
    ---@description 物品在地上时的单位
    ---@applicable value
    if item_check(item) then
        return item.unit
    end
end
 ---@keyword 单位
function base.item_unit_get_item(unit:unit)item
    ---@ui 物品单位~1~对应的物品对象
    ---@belong item
    ---@description 物品单位对应的物品对象
    ---@applicable value
    if unit_check(unit) then
        if not(unit.item) then
            log.debug"物品不是物品单位，只有物品单可获取物品对象"
            return nil
        end
        return unit.item
    end
end
 ---@keyword 单位
function base.item_blink(item:item, target:point)boolean
    ---@ui 将物品~1~瞬移到到点~2~
    ---@belong item
    ---@description 移动物品
    ---@applicable action
    if item_check(item) then
        if target:get_scene() == item.unit:get_Scene_name() then
            return item.unit:blink(target)
        else
            log.info(string.format('目标点[%s]与物体所处的场景不同，无法瞬移', target, item.unit:get_Scene_name()))
            return false
        end
    end
end
 ---@keyword 移动
function base.item_get_holder(item:item)unit
    ---@ui 物品~1~的持有者单位
    ---@belong item
    ---@description 物品的持有者单位
    ---@applicable value
    if item_check(item) then
        return item:carrier()
    end
end
 ---@keyword 持有者 单位
function base.item_get_name(item:item)item_id
    ---@ui 物品~1~的Id
    ---@belong item
    ---@description 物品的Id
    ---@applicable value
    if item_check(item) then
        return item.link
    end
end
 ---@keyword 物品 Id
function base.item_grant_tag(item:item)string
    ---@ui 物品~1~被赋予的标签
    ---@belong item
    ---@description 物品被赋予的标签
    ---@applicable value
    if and(item_check(item), item.granted_tag) then
        return item.granted_tag
    end
    return ''
end
 ---@keyword 标签
function base.item_get_owner(item:item)player
    ---@ui 物品~1~的拥有者玩家
    ---@belong item
    ---@description 物品的持有者玩家
    ---@applicable value
    if item_check(item) then
        return item.unit:get_owner()
    end
end
 ---@keyword 持有者 玩家
function base.item_remove(item:item)
    ---@ui 移除物品~1~
    ---@belong item
    ---@description 移除物品
    ---@applicable action
    if item_check(item) then
        item:remove()
    end
end
 ---@keyword 移除
function base.drop_item(item:item)boolean
    ---@ui 卸下物品~1~
    ---@belong item
    ---@description 卸下物品
    ---@applicable action
    if item_check(item) then
        return item:drop()
    end
end
 ---@keyword 卸下
function base.item_skill(item:item)skill
    ---@ui 物品~1~附加的技能
    ---@belong item
    ---@description 物品附加的技能
    ---@applicable value
    if item_check(item) then
        return item.active_skill
    end
end
 ---@keyword 技能
function base.item_get_equip_state(item:item)boolean
    ---@ui 物品~1~是否在装备状态
    ---@belong item
    ---@description 物品的装备状态
    ---@applicable value
    if item_check(item) then
        local slot_cache:unknown = and(item.slot, item.slot.cache)
        if slot_cache == nil then
            return false
        end
        local equip_state:unknown = slot_cache.Equip
        return equip_state
    end
end
 ---@keyword 物品
function base.get_inventory_items(unit:unit, index:integer)table<item>
    ---@ui 获取单位~1~身上编号为~2~的物品栏内的全部物品
    ---@belong item
    ---@description 获取指定编号物品栏的全部物品
    ---@applicable value
    if unit_check(unit) then
        return unit:get_inventory_items(index)
    end
end
 ---@keyword 物品
function base.give_item_to_inventory(item:item, unit:unit, index:integer)table<item>
    ---@ui 将~1~添加到~2~的第~3~个物品栏中
    ---@belong item
    ---@description 将物品添加到指定单位的指定物品栏
    ---@applicable action
    if and(unit_check(unit), item_check(item)) then
        if unit.inventorys ~= nil then
            if unit.inventorys[index] ~= nil then
                unit.inventorys[index]:add_item(item)
            end
        end
    end
end ---@keyword 物品