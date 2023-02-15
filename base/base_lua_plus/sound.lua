function base.player_play_music(player, path)
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
function base.player_play_sound(player, name)
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
function base.point_play_sound(point, name, distance, scene_name)
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
function base.point_play_sound2(point, name, distance)
    ---@ui 在点~1~处以截断距离~3~播放音乐~2~
    ---@belong sound
    ---@description 在指定点播放音效
    ---@applicable action
    if point_check(point) then
        point:play_sound(name, distance, point:get_scene())
    end
end ---@keyword 播放