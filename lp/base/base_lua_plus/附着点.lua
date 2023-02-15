--- lua_plus ---
-- TODO pay/backend/debugger/score
function base.附着点(unit:unit, socket:string)附着点
    ---@ui ~1~的绑点~2~
    ---@belong actor
    ---@description 单位的绑点
    ---@applicable value
    ---@name1 单位
    ---@name2 绑点
    if unit ~= nil then
        return {
            unit,
            socket
        }
    end
end ---@keyword 单位 绑点