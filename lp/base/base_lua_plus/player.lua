--- lua_plus ---
function base.player_add_attribute(player:player, state:玩家属性, value:number)
    ---@ui 使~1~的属性~2~增加~3~
    ---@belong player
    ---@description 玩家增加属性
    ---@applicable action
    ---@name1 玩家
    ---@name2 玩家属性
    ---@name3 数值
    ---@arg1 13
    ---@arg2 玩家属性["金钱"]
    ---@arg3 base.player(1)
    if player_check(player) then
        player:add(state, value)
    end
end
 ---@keyword 属性 增加
function base.get_player_controller(player:player)玩家控制者
    ---@ui ~1~的控制者类型
    ---@belong player
    ---@description 玩家的控制者类型
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:controller()
    end
end
 ---@keyword 控制者 类型
-- TODO:等 jj 设计
-- function base.player_event_cheat(player:player, name:'玩家事件_输入作弊码', callback:function<trigger,player,string>)
--     ---@ui ~1~注册~2~事件返回值
--     if player ~= nil then
--         player:event(name, callback)
--     end
-- end

--[[function base.player_event(player:player, name:string, callback:function<trigger>)
    ---@ui 为触发器~3~添加~1~的~2~事件
    ---@arg1 base.player(1)
    ---@description 为触发器添加玩家事件
    ---@belong player
    ---@applicable action
    if player ~= nil then
        player:event(name, callback)
    end
end

function base.player_event_dispatch(player:player, name:单位事件, ...)
    ---@ui ~1~以参数~3~触发名为~2~的事件(关心返回值)
    if player ~= nil then
        player:event_dispatch(name, ...)
    end
end

function base.player_event_notify(player:player, name:单位事件, ...)
    ---@ui ~1~以参数~3~触发名为~2~的事件
    if player ~= nil then
        player:event_notify(name, ...)
    end
end]]
--

function base.player_game_state(player:player)玩家游戏状态
    ---@ui ~1~的游戏状态
    ---@belong player
    ---@description 玩家的游戏状态
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:game_state()
    end
end
 ---@keyword 游戏状态
function base.player_get_attribute(player:player, state:玩家属性)number
    ---@ui ~1~的~2~属性
    ---@belong player
    ---@description 玩家的属性
    ---@applicable value
    ---@name1 玩家
    ---@name2 玩家属性
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:get(state)
    end
end
 ---@keyword 属性
function base.player_get_hero(player:player)unit
    ---@ui ~1~的主控单位
    ---@belong player
    ---@description 玩家的主控单位
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:get_hero()
    end
end
 ---@keyword 主控单位
function base.player_get_slot_id(player:player)integer
    ---@ui ~1~的槽位Id
    ---@belong player
    ---@description 玩家的槽位Id
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:get_slot_id()
    end
end
 ---@keyword 槽位
function base.player_get_team_id(player:player)integer
    ---@ui ~1~的队伍Id
    ---@belong player
    ---@description 玩家的队伍Id
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:get_team_id()
    end
end
 ---@keyword 队伍
--[[ function base.get_player_input_mouse(player:player) point
    ---@ui ~1~的鼠标位置
    ---@arg1 base.player(1)
    ---@description 玩家的鼠标位置
    ---@keyword 鼠标 位置
    ---@belong player
    ---@applicable value
    ---@name1 玩家
    if player_check(player) then
        return player:input_mouse():copy_to_scene_point(player:get_scene_name())
    end
end ]]
function base.get_player_input_rocker(player:player)number
    ---@ui ~1~的摇杆方向
    ---@belong player
    ---@description 玩家的摇杆方向
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:input_rocker()
    end
end
 ---@keyword 摇杆 方向

function base.is_player_abort(player:player)boolean
    ---@ui ~1~是否已放弃游戏
    ---@belong player
    ---@description 玩家是否已放弃游戏
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:is_abort()
    end
end
 ---@keyword 放弃
function base.kick_player(player:player, backend:string, frontend:string)
    ---@ui 把~1~踢出游戏，客户端记录:~3~,服务端记录~2~
    ---@belong player
    ---@description 将玩家踢出游戏
    ---@applicable action
    ---@name1 玩家
    ---@name2 服务端记录
    ---@name3 客户端记录
    ---@arg1 base.player(1)
    if player_check(player) then
        player:kick()
    end
end
 ---@keyword 踢出
function base.player_leave_reason(player:player)string
    ---@ui 玩家的~1~退出记录
    ---@belong player
    ---@description 玩家的退出记录
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:leave_reason()
    end
end
 ---@keyword 退出
function base.player_send_message(player:player, text:string, type:消息类型, time:number)
    ---@ui 向~1~显示~3~消息，内容为~2~持续~4~秒
    ---@belong player
    ---@description 向玩家显示消息
    ---@applicable action
    ---@name1 玩家
    ---@name2 消息内容
    ---@name3 消息类型
    ---@name4 持续时间
    ---@arg1 3
    ---@arg2 '$player1$:你好，世界'
    ---@arg3 消息类型["chat"]
    ---@arg4 base.player(1)
    local data:unknown = {
        text = text,
        type = type,
        time = time * 1000
    }
    if player_check(player) then
        player:message(data)
    end
end
 ---@keyword 玩家 消息
function base.player_message_box(player:player, text:string)
    ---@ui 向~1~发送弹框消息:~2~
    ---@belong player
    ---@description 向玩家显示弹框消息
    ---@applicable action
    ---@name1 玩家
    ---@name2 消息内容
    ---@arg1 '$player1$:你好，世界'
    ---@arg2 base.player(1)
    if player_check(player) then
        player:message_box(text)
    end
end
 ---@keyword 玩家 消息
function base.player_set_attribute_number(player:player, state:玩家属性, value:number)
    ---@ui 将~1~的属性~2~设置为~3~
    ---@belong player
    ---@description 设置玩家数值型属性
    ---@applicable action
    ---@name1 玩家
    ---@name2 玩家属性
    ---@name3 值
    ---@arg1 1000
    ---@arg2 玩家属性["金钱"]
    ---@arg3 base.player(1)
    if player_check(player) then
        player:set(state, value)
    end
end
 ---@keyword 设置 属性
function base.player_set_attribute_string(player:player, state:玩家属性, value:string)
    ---@ui 将~1~的属性~2~设置为~3~
    ---@belong player
    ---@description 设置玩家字符型属性
    ---@applicable action
    ---@name1 玩家
    ---@name2 玩家属性
    ---@name3 值
    ---@arg1 1000
    ---@arg2 玩家属性["金钱"]
    ---@arg3 base.player(1)
    if player_check(player) then
        player:set(state, value)
    end
end
 ---@keyword 设置 属性
function base.player_set_afk(player:player)
    ---@ui 将~1~设置为挂机状态
    ---@belong player
    ---@description 将玩家设置为挂机状态
    ---@applicable action
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        player:set_afk()
    end
end
 ---@keyword 设置 状态
function base.player_set_hero(player:player, hero:unit)
    ---@ui 设置~1~的主控单位为~2~
    ---@belong player
    ---@description 设置玩家主控单位
    ---@applicable action
    ---@name1 玩家
    ---@name2 英雄
    ---@arg1 base.player(1)
    if player_check(player) then
        player:set_hero(hero)
    end
end
 ---@keyword 设置 单位
function base.player_set_team_id(player:player, id:integer)
    ---@ui 设置~1~的队伍Id为~2~
    ---@belong player
    ---@description 设置玩家队伍Id
    ---@applicable action
    ---@name1 玩家
    ---@name2 队伍Id
    ---@arg1 base.player(1)
    if player_check(player) then
        player:set_team_id(id)
    end
end
 ---@keyword 设置 队伍
function base.get_player_user_agent(player:player)string
    ---@ui ~1~的用户客户端
    ---@belong player
    ---@description 玩家的用户客户端
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:user_agent()
    end
end
 ---@keyword 客户端
function base.player_user_id(player:player)integer
    ---@ui ~1~的虚拟用户Id
    ---@belong player
    ---@description 玩家的虚拟用户Id
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:user_id()
    end
end
 ---@keyword 用户 Id
function base.player_get_scene_name(player:player)string
    ---@ui ~1~所在场景的名称
    ---@belong player
    ---@description 玩家所在场景的名称
    ---@applicable value
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:get_scene_name()
    end
end
 ---@keyword 场景
function base.player_get_user_nick(player:player)string
    ---@ui 玩家~1~的昵称
    ---@belong player
    ---@description 玩家的昵称
    ---@applicable value
    ---@name1 玩家
    if player_check(player) then
        return player:get_user_info'nick'
    end
end
 ---@keyword 昵称
function base.get_each_player(type:用户类型)table<player>
    ---@ui 获取~1~玩家类型所有玩家
    ---@belong player
    ---@description 获取指定玩家类型所有玩家
    ---@applicable value
    ---@name1 玩家类型
    local players:unknown = {}
    for player:unknown in base.each_player(type) do
        table.insert(players, player)
    end
    return players
end ---@keyword 玩家类型