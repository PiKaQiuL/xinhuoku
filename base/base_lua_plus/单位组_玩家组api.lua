function base.unit_group_add_item(单位组, 单位)
    ---@ui 向~1~添加~2~
    ---@belong 单位组
    ---@description 向单位组添加单位
    ---@applicable action
    ---@name1 单位组
    ---@name2 单位
    if (unit_group_check(单位组) and unit_check(单位)) then
        单位组:add_item(单位)
    end
end
 ---@keyword 添加 单位
function base.unit_group_add_items(单位组, 目标单位组)
    ---@ui 向~1~添加~2~
    ---@belong 单位组
    ---@description 向单位组添加单位组
    ---@applicable action
    ---@name1 单位组
    ---@name2 目标单位组
    if (unit_group_check(单位组) and unit_group_check(目标单位组)) then
        单位组:add_items(目标单位组)
    end
end
 ---@keyword 添加 单位组
function base.unit_group_contains(单位组, 单位)
    ---@ui ~1~是否包含~2~
    ---@belong 单位组
    ---@description 单位组是否包含单位
    ---@applicable value
    ---@name1 单位组
    ---@name2 单位
    if (unit_group_check(单位组) and unit_check(单位)) then
        return 单位组:contains(单位)
    else
        return false
    end
end
 ---@keyword 包含 单位
function base.unit_group_copy(单位组)
    ---@ui ~1~的复制
    ---@belong 单位组
    ---@description 单位组的复制
    ---@applicable value
    ---@name1 单位组
    if (unit_group_check(单位组)) then
        return 单位组:copy()
    end
end
 ---@keyword 复制
function base.unit_group_remove_item(单位组, 单位)
    ---@ui 从~1~移除~2~
    ---@belong 单位组
    ---@description 从单位组移除单位
    ---@applicable action
    ---@name1 单位组
    ---@name2 单位
    if (unit_group_check(单位组) and unit_check(单位)) then
        单位组:remove_item(单位)
    end
end
 ---@keyword 移除 单位
function base.unit_group_remove_items(单位组, 目标单位组)
    ---@ui 从~1~移除~2~
    ---@belong 单位组
    ---@description 从单位组移除单位组
    ---@applicable action
    ---@name1 单位组
    ---@name2 目标单位组
    if (unit_group_check(单位组) and unit_group_check(目标单位组)) then
        单位组:remove_items(目标单位组)
    end
end
 ---@keyword 移除 单位组
function base.unit_group_union(单位组, 目标单位组)
    ---@ui ~1~与~2~的并集
    ---@belong 单位组
    ---@description 单位组的并集
    ---@applicable value
    ---@name1 单位组1
    ---@name2 单位组2
    if (unit_group_check(单位组) and unit_group_check(目标单位组)) then
        return 单位组:union(目标单位组)
    end
end
 ---@keyword 并集
function base.unit_group_sub(单位组, 目标单位组)
    ---@ui ~1~减去~2~的差集
    ---@belong 单位组
    ---@description 单位组的差集
    ---@applicable value
    ---@name1 单位组1
    ---@name2 单位组2
    if (unit_group_check(单位组) and unit_group_check(目标单位组)) then
        return 单位组:sub(目标单位组)
    end
end
 ---@keyword 差集
function base.unit_group_intersect(单位组, 目标单位组)
    ---@ui ~1~与~2~的交集
    ---@belong 单位组
    ---@description 单位组的交集
    ---@applicable value
    ---@name1 单位组1
    ---@name2 单位组2
    if (unit_group_check(单位组) and unit_group_check(目标单位组)) then
        return 单位组:intersect(目标单位组)
    end
end
 ---@keyword 交集
function base.unit_group_count(单位组)
    ---@ui ~1~的单位数量
    ---@belong 单位组
    ---@description 单位组的单位数量
    ---@applicable value
    ---@name1 单位组
    if (unit_group_check(单位组)) then
        return 单位组:get_length()
    end
end
 ---@keyword 单位 数量
function base.unit_group_get_items_map(单位组)
    ---@ui ~1~
    ---@belong 单位组
    ---@applicable value
    ---@selectable false
    ---@name1 单位组
    if (unit_group_check(单位组)) then

    else
        单位组 = base.单位组()
    end
    return 单位组:get_items_map()
end ---@keyword 单位组