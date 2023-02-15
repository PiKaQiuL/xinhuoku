--- lua_plus ---
function base.player_play_music(player:player, path:string)
    ---@ui 为~1~播放音乐~2~
    ---@belong sound
    ---@description 播放音乐
    ---@applicable action
    ---@arg1 base.player(1)
    if player_check(player) then
        player:play_music(path)
    end
end
 ---@keyword 播放
function base.player_play_sound(player:player, name:string)
    ---@ui ~1~播放音效~2~
    ---@belong sound
    ---@description 播放音效
    ---@applicable action
    ---@arg1 base.player(1)
    if player_check(player) then
        player:play_sound(name)
    end
end

 ---@keyword 播放
function base.point_play_sound(point:point, name:string, distance:number, scene_name:场景)
    ---@ui 在场景~4~的点~1~处以截断距离~3~播放音乐~2~
    ---@belong sound
    ---@description 在指定点播放音效
    ---@applicable action
    ---@selectable false
    if point_check(point) then
        point:is_visible(name, distance, scene_name)
    end
end
 ---@keyword 播放
function base.point_play_sound2(point:point, name:string, distance:number)
    ---@ui 在点~1~处以截断距离~3~播放音乐~2~
    ---@belong sound
    ---@description 在指定点播放音效
    ---@applicable action
    if point_check(point) then
        point:play_sound(name, distance, point:get_scene())
    end
end ---@keyword 播放