function base.skill_table(name, level, key)
    if not base.table.skill[name] then
        return nil
    end
    local values = base.skill[name][key]
    if not values then
        return nil
    end
    local value = values[level]
    return value
end

function base.unit_table(name, key)
    local data = base.table.unit[name]
    if not data then
        return nil
    end
    local value
    local tp = type(key)
    if tp == 'string' then
        value = data[key]
    elseif tp == 'table' then
        for _, key in ipairs(key) do
            value = value[key]
            if value == nil then
                return nil
            end
        end
    end
    return value
end

function base.buff_table(name, key)
    local data = base.table.buff[name]
    if not data then
        return nil
    end
    local value = data[key]
    if value == nil then
        return nil
    end
    return value
end

function base.attack_table(name, key)
    local data = base.table.skill[name]
    if not data then
        return nil
    end
    local value
    local tp = type(key)
    if tp == 'string' then
        value = data[key]
    elseif tp == 'table' then
        for _, key in ipairs(key) do
            value = value[key]
            if value == nil then
                return nil
            end
        end
    end
    return value
end

function base.item_table(name, key)
    local data = base.table.item[name]
    if not data then
        return nil
    end
    local value = data[key]
    if value == nil then
        return nil
    end
    return value
end