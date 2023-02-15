local mt = {
    __len = function(tbl)
        return #tbl.__items
    end,
    __newindex = function(tbl, key, value)
        -- print ('set : ', key, value)
        if type(value) == 'table' or tbl.__items[key] ~= value then
            tbl.__ischange = true
            tbl.__modify[key] = true
            tbl.__items[key] = value
        end
    end,
    __index = function(tbl, key)
        -- print ('get : ', key, tbl.__items[key])
     return tbl.__items[key]
    end,
    __pairs = function (tbl)
       return next, tbl.__items, nil
    end, 
}

local function get_table()
    -- 获取一个支持记录是否改变的表
    return setmetatable({
        __items = {},
        __modify = {},
        __ischange = false,
    }, mt)
end

local function set_table(tbl)
    -- 将一个表修改为我们的同步表
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            tbl[k] = set_table(v)
        end
    end
    tbl = {
        __items = tbl,
        __modify = {},
        __ischange = false,
    }
    tbl = setmetatable(tbl, mt)
    return tbl
end

local function to_normal(tbl)
    local new_table = {}
    for k, v in pairs(tbl.__items) do
        if type(v) == 'table' then
            new_table[k] = to_normal(v)
        else
            new_table[k] = v
        end
    end
    return new_table
end

function check_sync_modify_table(ori_tbl)
    local tmp_tbl = {}
    local is_modify = false
    for k, v in pairs(ori_tbl.__items) do
        if type(v) == 'table' then
            local sub_tbl = check_sync_modify_table(v)
            if sub_tbl ~= nil then
                is_modify = true
                tmp_tbl[k] = sub_tbl
            elseif ori_tbl.__modify[k] then
                is_modify = true
                tmp_tbl[k] = {}
            end
        elseif ori_tbl.__modify[k] then
            is_modify = true
            tmp_tbl[k] = v
        end
        ori_tbl.__modify[k] = false
    end
    ori_tbl.__ischange = false
    if is_modify then
        return tmp_tbl
    end
    return nil
end

function check_sync_del_table(ori_tbl)
    local delete = {}
    local is_delete = false
    for k, v in pairs(ori_tbl.__modify) do
        if v and ori_tbl.__items[k] == nil then
            is_delete = true
            delete[k] = true
        end
        ori_tbl.__modify[k] = false
    end
    for k, v in pairs(ori_tbl.__items) do
        if type(v) == 'table' then
            local tmp = check_sync_del_table(v)
            if tmp ~= nil then
                delete[k] = tmp
                is_delete = true
            end
        end
    end
    if is_delete then
        return delete
    end
    return nil
end

function base.mix_table(ori_tbl, new_tbl)
    local tbl = ori_tbl
    for k, v in pairs(new_tbl) do
        if type(v) == 'table' then
            if tbl[k] == nil then
                tbl[k] = v
            else
                mix_table(tbl[k], v)
            end
        else
            tbl[k] = v
        end
    end
    return tbl
end

function base.mix_modify_to_delete(delete_table, modify_table)
    local tbl = delete_table
    for k, v in pairs(modify_table) do
        if type(v) == 'table' then
            if tbl[k] then
                tbl[k] = mix_modify_to_delete(tbl[k], v)
            end
        elseif tbl[k] ~= nil then
            tbl[k] = nil
        end
    end
    return tbl
end

function base.mix_delete_to_modify(modify_table, delete_table)
    local tbl = modify_table
    for k, v in pairs(delete_table) do
        if type(v) == 'table' then
            if tbl[k] then
                tbl[k] = mix_delete_to_modify(tbl[k], v)
            end
        elseif tbl[k] ~= nil then
            tbl[k] = nil
        end
    end
    return tbl
end

function base.check_sync_table(tbl)
    local modify_table = check_sync_modify_table(tbl)
    local delete_table = check_sync_del_table(tbl)
    return {
        modify = modify_table or {},
        delete = delete_table or {},
    }
end

function base.get_attr_sync_table()
    return get_table()
end

function base.modify_table_to_sync(tbl)
    return set_table(tbl)
end

function base.sync_table_to_normal(tbl)
    return to_normal(tbl)
end