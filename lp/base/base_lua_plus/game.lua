--- lua_plus ---
-- game可由base.game直接访问，在代码中配置
-- function base.get_player_scene_name(player:player) string
--     ---@ui ~1~所在的场景名
--     ---@arg1 base.player(1)
--     ---@description 玩家所在的场景
--     ---@keyword 玩家 场景
--     ---@belong game
--     ---@applicable value
--     if player_check(player) then
--         return player:get_scene_name()
--     end
-- end

function base.player_jump_scene(player:player, scene:场景, keep_hero:是否)boolean
    ---@ui 使~1~跳转到场景~2~,带上主控单位:~3~
    ---@belong game
    ---@description 跳转玩家场景
    ---@applicable action
    ---@name1 玩家
    ---@name2 场景名
    ---@name3 带上主控单位
    ---@arg1 base.player(1)
    if player_check(player) then
        return player:jump_scene(scene, keep_hero)
    end
end
 ---@keyword 跳转 场景
function base.game_ui_message(message_name:string, data:table)
    ---@ui 向客户端发送消息~1~,数据为~2~
    ---@belong game
    ---@description 向客户端发消息
    ---@applicable action
    ---@name1 玩家
    ---@name2 数据
    base.game:ui(message_name)(data)
end
 ---@keyword 客户端 消息
function base.custom_event_notify(event_name:自定义事件名, event_param:自定义事件参数)
    base.game:event_notify(event_name, event_param)
end

local player_info:unknown = {}
function base.player_win_game(player:player)
    ---@ui ~1~赢得游戏
    ---@belong player
    ---@description 玩家赢得游戏
    ---@applicable action
    ---@name1 玩家
    ---@arg1 base.player(1)
    if and(player_check(player), player_info[player] == nil) then
        player_info[player] = 'win'
        base.game.default_game_result{
            result = 'win',
            player = player
        }
        -- base.game:event_notify('win_or_failed', {result = 'win', player = player})
        -- base.game.time_stop()
        -- -- player:lock_camera()
        -- player:ui'player_game_result'{
        --     result = 'win'
        -- }
    end
end

function base.player_fail_game(player:player)
    ---@ui ~1~游戏失败
    ---@belong player
    ---@description 玩家游戏失败
    ---@applicable action
    ---@name1 玩家
    ---@arg1 base.player(1)
    if and(player_check(player), player_info[player] == nil) then
        player_info[player] = 'failed'
        base.game.default_game_result{
            result = 'failed',
            player = player
        }
        -- base.game:event_notify('win_or_failed', {result = 'failed', player = player})
        -- base.game.time_stop()
        -- -- player:lock_camera()
        -- player:ui'player_game_result'{
        --     result = 'fail'
        -- }
    end
end

function base.object_store_value(object:unknown, key:string, value:unknown)
    ---@ui 在~1~上保存值：~3~，索引为~2~
    ---@belong game
    ---@description 在对象上保存任意值
    ---@applicable action
    ---@name1 对象
    ---@name2 Key
    ---@name3 值
    ---@arg1 base.get_last_created_item()
    ---@arg2 'Key'
    ---@arg3 base.get_last_created_unit()
    base.game.object_store_value(object, key, value)
end

function base.object_restore_value(object:unknown, key:string)nil
    ---@ui ~1~上保存的索引为~2~的值
    ---@belong game
    ---@description 对象上保存的任意值
    ---@applicable value
    ---@name1 对象
    ---@name2 Key
    ---@arg1 'Key'
    ---@arg2 base.get_last_created_unit()
    return base.game.object_restore_value(object, key)
end

function base.pause_game()
    ---@ui 暂停游戏
    ---@belong game
    ---@description 暂停游戏
    ---@applicable both
    base.game.time_stop()
end ---@keyword 停止 时间
function base.pause_game_time(sec:number)
    ---@ui 暂停游戏~1~秒
    ---@belong game
    ---@description 暂停游戏一段时间
    ---@applicable both
    base.game.time_stop(sec)
    base.timer_sleep(0.04)
    base.game.cancel_time_stop()
end
 ---@keyword 停止 时间
function base.unpause_game()
    ---@ui 取消暂停游戏
    ---@belong game
    ---@description 取消暂停游戏
    ---@applicable both
    base.game.cancel_time_stop()
end
 ---@keyword 停止 取消
function base.switch_fov_mode(number:number, scene:场景)
    ---@ui 切换场景~2~迷雾模式为~1~
    ---@belong game
    ---@description 切换迷雾模式
    base.game.switch_fov_mode(number, scene)
end