-- function table.push_back(t:table, e:item)
--     table.insert(t, e)
-- end

-- function table.pop_back(t:table) unknown
--     return table.remove(t)
-- end
function table.pop_front(t)
    return table.remove(t, 1)
end
function table.getn(t, index)
    return t[index]
end