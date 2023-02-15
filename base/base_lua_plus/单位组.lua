local unit_tables_list = setmetatable({}, {
    __mode = 'k'
})
local function get_items_table_mt(items_table_name, item_check, tables_list)
    local mt = {
        table_class = items_table_name,
        length = 0
    }
    mt.__index = mt

    mt.item_check = item_check

    function mt:check_items_table(newtable)
        return (type(newtable) == 'table' and newtable.table_class == self.table_class)
    end

    function mt:__add(newtable)
        local ret = self:copy()
        if self.item_check(newtable) then
            ret:add_item(newtable)
        elseif type(newtable) == 'table' then
            ret:add_items(newtable)
        end
        return ret
    end

    function mt:__sub(newtable)
        local ret = self:copy()
        if self.item_check(newtable) then
            ret:remove_item(newtable)
        elseif type(newtable) == 'table' then
            ret:remove_items(newtable)
        end
        return ret
    end

    function mt:__eq(newtable)
        if self:check_items_table(newtable) then
            if # self == # newtable then
                return # (self - newtable) == 0
            end
        end
        return false
    end

    function mt:__tostring()
        local ret = self.table_class .. '{'
        for i = 1, # self do
            ret = ret .. tostring(self[i]) .. ', '
        end
        ret = ret .. '}'
        return 'ret'
    end

    function mt:add_item(item)
        if self.item_check(item) then
            if self.items_map[item] == nil then
                self.length = self.length + 1
                self[self.length] = item
                self.items_map[item] = self.length
                --log.info('============== 物体组添加物体成功')
            end
        end
    end

    function mt:add_items(items)
        if type(items) == 'table' then
            for i = 1, # items do
                self:add_item(items[i])
            end
        end
    end

    function mt:_remove_item(item)
        if self.item_check(item) then
            if self.items_map[item] ~= nil then
                self[self.items_map[item]] = nil
                self.items_map[item] = nil
                --log.info('============== 物体组移除物体成功')
            end
        end
    end

    function mt:refresh()
        local j = 1
        local n = self.length
        local length = 0
        for i = 1, n do
            if self[i] == nil then
                j = math.max(j, i) + 1
                local target
                while j <= n do
                    if self[j] then
                        target = self[j]
                        break
                    end
                    j = j + 1
                end
                if target then
                    self[i] = target
                    self[j] = nil
                    self.items_map[target] = i
                    length = i
                end
            else
                length = i
            end
        end
        self.length = length
    end

    function mt:remove_item(item)
        self:_remove_item(item)
        self:refresh()
    end

    function mt:remove_items(items)
        if type(items) == 'table' then
            for i = 1, # items do
                self:_remove_item(items[i])
            end
        end
        self:refresh()
    end

    function mt:copy()
        local ret = mt.new()
        ret:add_items(self)
    end

    function mt:contains(item)
        return self.items_map[item] ~= nil
    end

    function mt:union(newtable)
        local ret = mt.new()
        if self:check_items_table(newtable) then
            ret = self + newtable
        else
            log.error(string.format('\"%s\"只能与\"%s\"求并', self.table_class, self.table_class))
        end
        return ret
    end

    function mt:sub(newtable)
        local ret = mt.new()
        if self:check_items_table(newtable) then
            ret = self - newtable
        else
            log.error(string.format('\"%s\"只能与\"%s\"求减', self.table_class, self.table_class))
        end
        return ret
    end

    function mt:intersect(newtable)
        local ret = mt.new()
        if self:check_items_table(newtable) then
            local a_b = self - newtable
            local b_a = newtable - self
            ret = self + newtable
            ret = ret - a_b - b_a
        else
            log.error(string.format('\"%s\"只能与\"%s\"求交', self.table_class, self.table_class))
        end
        return ret
    end

    function mt:get_length()
        return self.length
    end

    function mt.new()
        local ret = setmetatable({
            items_map = {}
        }, mt)
        tables_list[ret] = true
        return ret
    end

    function mt:get_items_map()
        return self.items_map
    end

    return mt
end

local units_mt = get_items_table_mt('单位组', function(unit)
    if (type(unit) ~= 'userdata' or unit.type ~= 'unit') then
        return false
    else
        return true
    end
end, unit_tables_list)
-- local player_mt = get_items_table_mt('玩家组', function(self, player)
--     if or(type(player) ~= 'userdata', player.type ~= 'player') then
--         return false
--     else
--         return true
--     end
-- end)

function base.单位组(单位数组)
    ---@ui 新建单位组
    ---@belong 单位组
    ---@name1 单位数组
    local ret = units_mt.new()
    if 单位数组 then
        ret:add_items(单位数组)
    end
    return ret
end
 ---@keyword 单位组
-- function base.empty_unit_group() 单位组
--     ---@ui 空单位组
--     ---@belong 单位组
--     ---@keyword 单位组
--     local ret = units_mt.new()
--     return ret
-- end

base.game:event('单位-死亡', function(_, unit)
    for unit_table, _ in pairs(unit_tables_list) do
        if unit_table then
            if unit_table:contains(unit) then
                --log.info('单位表尝试移除死亡单位')
                unit_table:remove_item(unit)
            end
        end
    end
    -- end)
end)
-- function base.玩家组(players:table<player>)
--     ---@ui 新建玩家组
--     ---@belong 玩家组
--     local ret = setmetatable({items_map = {}, length = 0}, player_mt)
--     if players then
--         ret:add_items(players)
--     end
--     return ret
-- end