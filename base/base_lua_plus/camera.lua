function base.player_lock_camera(player)
    ---@ui 为~1~锁定镜头
    ---@belong player
    ---@description 锁定镜头
    ---@applicable action
    ---@arg1 base.player(1)
    if player_check(player) then
        player:lock_camera()
    end
end
 ---@keyword 锁定
function base.player_set_camera(player, camera_id_name, time)
    ---@ui 设置~1~的镜头对象为~2~,变化时间为~3~秒
    ---@belong camera
    ---@description 设置玩家镜头
    ---@applicable action
    ---@arg1 base.player(1)
    local camera = base.eff.cache(camera_id_name)
    if player_check(player) then
        if (camera and camera.NodeType == 'Camera') then
            player:set_camera{
                position = {
                    camera.Position.x,
                    camera.Position.y,
                    camera.Position.z
                },
                rotation = {
                    camera.Rotation.rx,
                    camera.Rotation.ry,
                    camera.Rotation.rz
                },
                focus_distance = camera.Distance,
                time = time * 1000
            }
        else
            log.error"无效的镜头数据，请检测传入镜头数据是否正确"
        end
    end
end
 ---@keyword 设置
function base.player_shake_camera(player, type, frequency, amplitude, time)
    ---@ui 对~1~，以模式~2~震动镜头（频率：~3~，幅度：~4~，时间：~5~）
    ---@belong camera
    ---@description 震动镜头
    ---@applicable action
    ---@name1 玩家
    ---@name2 相机震动维度
    ---@name3 频率
    ---@name4 幅度
    ---@name5 时间
    ---@arg1 base.player(1)
    if player_check(player) then
        player:shake_camera(type, frequency, amplitude, time)
    end
end
 ---@keyword 晃动 震动
function base.player_unlock_camera(player)
    ---@ui 为~1~解锁镜头
    ---@belong camera
    ---@description 解锁镜头
    ---@applicable action
    ---@name1 玩家
    ---@arg1 base.player(1)
    if player_check(player) then
        player:unlock_camera()
    end
end
 ---@keyword 解锁
function base.player_camera_focus(player, unit)
    ---@ui 使~1~的镜头跟随~2~
    ---@belong camera
    ---@description 使镜头跟随单位
    ---@applicable action
    ---@name1 玩家
    ---@name2 单位
    ---@arg1 base.player(1)
    if player_check(player) then
        player:camera_focus(unit)
    end
end ---@keyword 跟随