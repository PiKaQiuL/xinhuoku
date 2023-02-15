--- lua_plus ---
-- function table.push_back(t:table, e:item)
--     table.insert(t, e)
-- end

-- function table.pop_back(t:table) unknown
--     return table.remove(t)
-- end
function table.pop_front(t:table)unknown
    return table.remove(t, 1)
end
function table.getn(t:table, index:integer)unknown
    return t[index]
end