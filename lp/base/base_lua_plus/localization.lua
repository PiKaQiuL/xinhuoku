--- lua_plus ---
--服务端的get_text假处理
_G.get_text = function(id:unknown)
    return '@' .. id .. '@'
end