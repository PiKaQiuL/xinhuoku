--- lua_plus ---
function base.ai_attack_add_team_threat(ai_attack:ai_attack, team:integer, threat:integer)
    ---@ui 为搜敌器~1~添加队伍~2~的仇恨值~3~
    ---@belong ai
    ---@description 为搜敌器添加玩家队伍仇恨值
    ---@applicable action
    ---@name1 搜敌器
    ---@name2 队伍
    ---@name3 仇恨值
    if ai_attack ~= nil then
        ai_attack:add_team_threat(team, threat)
    end
end
 ---@keyword 仇恨 队伍
function base.ai_attack_add_unit_threat(ai_attack:ai_attack, unit:unit, threat:integer)
    ---@ui 搜敌器~1~添加~2~的仇恨值~3~
    ---@belong ai
    ---@description 为搜敌器添加单位仇恨值
    ---@applicable action
    ---@name1 搜敌器
    ---@name2 单位
    ---@name3 仇恨值
    if ai_attack ~= nil then
        ai_attack:add_threat(unit, threat)
    end
end
 ---@keyword 仇恨 单位
function base.ai_attack_add_type_threat(ai_attack:ai_attack, unit_tag:单位标签, threat:integer)
    ---@ui 搜敌器~1~添加对单位标签~2~的仇恨值~3~
    ---@belong ai
    ---@description 为搜敌器添加对某种标签的单位仇恨值
    ---@applicable action
    ---@name1 搜敌器
    ---@name2 单位标签
    ---@name3 仇恨值
    if ai_attack ~= nil then
        ai_attack:add_type_threat(unit_tag, threat)
    end
end
 ---@keyword 仇恨 标签
function base.ai_attack_remove(ai_attack:ai_attack)
    ---@ui 移除搜敌器~1~
    ---@belong ai
    ---@description 移除搜敌器
    ---@applicable action
    ---@name1 搜敌器
    if ai_attack ~= nil then
        ai_attack:remove()
    end
end ---@keyword 移除