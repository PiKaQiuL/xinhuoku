local type = type
local pairs = pairs
local gsub = string.gsub
local find = string.find
local tostring = tostring

local buf 

local esc_map = {
    ['\\'] = '\\\\',
    ['\r'] = '\\r',
    ['\n'] = '\\n',
    ['\t'] = '\\t',
    ['\''] = '\\\'',
}

local function format_key(name)
    if type(name) ~= 'string' then
        return tostring(name)
    end
    name = gsub(name, "[\\\r\n\t']", esc_map)
    return "'" .. name .. "'"
end

local function format_value(value)
    if type(value) ~= 'string' then
        if type(value) == 'function' then -- function特殊处理下，否则反序列化的时候会导致整个解失败(function本身就不序列化了，所以直接返回了空字符串)
            return ''
        end
        if type(value) == 'number' then
            if value % 1 == 0 and (value > 2147483647 or value < -2147483648) then
                return "'overflow(" .. tostring(value) .. ")'"
            end
        end
        return tostring(value)
    end
    value = gsub(value, "[\\\r\n\t']", esc_map)
    return "'" .. value .. "'"
end

local function convert_table(tbl)
    for key, data in pairs(tbl) do
        if type(data) == 'table' then
            buf[#buf+1] = format_key(key) .. '={'
            convert_table(data)
            buf[#buf+1] = '},'
        else
            buf[#buf+1] = format_key(key) .. '=' .. format_value(data) .. ','
        end
    end
end

local function convert_root(root)
    if type(root) == 'table' then
        for key, data in pairs(root) do
            if type(data) == 'table' then            
                buf[#buf+1] = format_key(key) .. '={'
                convert_table(data)
                buf[#buf+1] = '}'
            else
                buf[#buf+1] = format_key(key) .. '=' .. format_value(data)
            end
        end
    elseif type(root) == 'nil' then
        buf[#buf+1] = '=nil'
    else
        buf[#buf+1] = '=' .. format_value(root)
    end
end

return function (lni)
    buf = {'[root]'}

    convert_root(lni)

    return table.concat(buf, '\n')
end