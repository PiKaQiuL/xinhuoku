local table_sort = table.sort
local string_rep = string.rep
local type = type
local pairs = pairs
local ipairs = ipairs
local math_type = math.type

local TAB = setmetatable({}, { __index = function (self, n)
    self[n] = string_rep('\t', n)
    return self[n]
end})

local KEY = {}

return function (tbl)
    if type(tbl) ~= 'table' then
        error('必须是表')
    end
    local table_mark = {}
    local lines = {}
    lines[#lines+1] = '{'
    local function unpack(tbl, tab)
        if table_mark[tbl] then
            error('不能循环引用')
        end
        table_mark[tbl] = true
        local keys = {}
        for key in pairs(tbl) do
            if type(key) == 'string' then
                if key:find('[^%w_]') then
                    KEY[key] = ('[%q]'):format(key)
                else
                    KEY[key] = key
                end
            elseif math_type(key) == 'integer' then
                KEY[key] = ('[%d]'):format(key)
            else
                error('必须使用字符串或整数作为键')
            end
            keys[#keys+1] = key
        end
        table_sort(keys, function (a, b)
            return KEY[a] < KEY[b]
        end)
        for _, key in ipairs(keys) do
            local value = tbl[key]
            local tp = type(value)
            if tp == 'table' then
                lines[#lines+1] = ('%s%s = {'):format(TAB[tab+1], KEY[key])
                unpack(value, tab+1)
                lines[#lines+1] = ('%s},'):format(TAB[tab+1])
            elseif tp == 'string' or tp == 'number' or tp == 'boolean' then
                lines[#lines+1] = ('%s%s = %q,'):format(TAB[tab+1], KEY[key], value)
            else
                error(('不支持的值类型[%s]'):format(tp))
            end
        end
    end
    unpack(tbl, 0)
    lines[#lines+1] = '}'
    return table.concat(lines, '\n')
end
