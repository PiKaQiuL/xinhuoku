-- 哈希表均为弱键，不可遍历元素
local wk_mt = { __mode = 'k' }
local function new_wk()
    return setmetatable({}, wk_mt)
end

local mt = {}
mt.__index = mt

-- tp为编辑器中的值类型，在编译时生成
function mt:save(k1, k2, tp, value)
    if k1 == nil then
        error(('目录不存在'), 2)
    end
    if k2 == nil then
        error(('标签不存在'), 2)
    end
    local parent = self.t[k1]
    if not parent then
        parent = new_wk()
        self.t[k1] = parent
    end
    parent[k2] = {tp, value}
end

-- tp为编辑器中的值类型，def为该类型的默认值，在编译时生成
function mt:load(k1, k2, tp, def)
    if k1 == nil then
        error(('目录不存在'), 2)
    end
    if k2 == nil then
        error(('标签不存在'), 2)
    end
    local parent = self.t[k1]
    if not parent then
        return def
    end
    local value = parent[k2]
    if not value then
        return def
    end
    if tp ~= value[1] then
        error(('存储类型为[%s]，不能将其读取为[%s]'):format(value[1], tp), 2)
    end
    return value[2]
end

function mt:flush()
    self.t = new_wk()
end

function mt:flush_parent(k1)
    self.t[k1] = nil
end

function mt:flush_child(k1, k2)
    local parent = self.t[k1]
    if not parent then
        return
    end
    parent[k2] = nil
end

function base.hashtable()
    return setmetatable({ t = new_wk() }, mt)
end

base.Hashtable = base.hashtable()
