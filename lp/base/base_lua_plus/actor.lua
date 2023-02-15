--- lua_plus ---
function base.get_last_created_actor()actor
    ---@ui 触发器最后创建的表现
    ---@belong actor
    ---@description 触发器最后创建的表现
    ---@applicable value
    return base.last_created_actor
end
 ---@keyword 表现
function base.create_actor_at(name:actor_id, point:point, use_terrain:是否)actor
    ---@ui 在~2~处创建表现:~1~ （使用相对地面高度：~3~）
    ---@belong actor
    ---@description 创建表现
    ---@applicable both
    ---@name1 表现Id
    ---@name2 位置
    ---@arg1 是否[true]
    local actor:unknown = base.actor(name)
    base.last_created_actor = actor
    if not(actor) then
        return
    end
    actor:set_position(point[1], point[2], point[3])
    if use_terrain then
        actor:set_ground_z(point[3])
    end
    return actor
end
 ---@keyword 创建
function base.actor_set_grount_height(actor:actor, height:number)
    ---@ui 设置~1~地面相对高度为~2~
    ---@belong actor
    ---@description 设置表现地面相对高度
    ---@applicable action
    ---@name1 表现
    if actor then
        actor:set_ground_z(height)
    end
end
 ---@keyword 高度 相对
function base.actor_set_position(actor:actor, point:point)
    ---@ui 将~1~移动到~2~
    ---@belong actor
    ---@description 移动表现
    ---@applicable action
    ---@name1 表现
    ---@name2 点
    if actor then
        actor:set_position(point[1], point[2], point[3])
    end
end
 ---@keyword 移动
function base.actor_set_facting(actor:actor, angle:angle)
    ---@ui 设置~1~的朝向为~2~
    ---@belong actor
    ---@description 设置表现朝向
    ---@applicable action
    ---@name1 表现
    ---@name2 角度值
    if actor then
        actor:set_facing(angle)
    end
end
 ---@keyword 朝向 角度
function base.actor_attach_to_unit(actor:actor, host:unit, socket:string)
    ---@ui 将~1~附着到~2~的附着点~3~处
    ---@belong actor
    ---@description 将表现附着到单位上
    ---@applicable action
    ---@name1 表现
    ---@name2 宿主
    if actor then
        actor:attach_to(host, socket)
        local cache:unknown = base.eff.cache(host:get_name())
        if and(cache, cache.ShowShadow == false) then
            actor:set_shadow(false)
        end
        local actors:unknown = host.actors
        if not(actors) then
            actors = {}
            host.actors = actors
        end
        table.insert(host.actors, actor)
        actor.trig_host = host
    end
end

 ---@keyword 附着 单位
function base.create_actor_on_buff(name:actor_id, host:buff)actor
    ---@ui 为buff~2~创建表现~1~
    ---@belong actor
    ---@description 为Buff创建表现
    ---@applicable both
    ---@name1 表现
    ---@name2 宿主
    if buff_check(host) then
        local ubuff:unknown = host.unit_buff
        if ubuff then
            local actor:unknown = ubuff:create_actor(name)
            base.last_created_actor = actor
            actor.trig_host = host
            return actor
        end
    end
    base.last_created_actor = nil
    return nil
end
 ---@keyword 附着 Buff
function base.buff_get_actor(host:buff, name:actor_id)actor
    ---@ui 附着在Buff~1~上的Id为~2~表现
    ---@belong actor
    ---@description Buff上附着的表现
    ---@applicable value
    ---@name1 宿主
    ---@name2 表现
    if buff_check(host) then
        local ubuff:unknown = host.unit_buff
        if and(ubuff, ubuff.actors) then
            for _:unknown, actor:unknown in pairs(ubuff.actors) do
                if and(actor, actor.name == name, actor:is_valid()) then
                    return actor
                end
            end
        end
    end
    return nil
end
 ---@keyword 附着 Buff
function base.unit_get_actor(host:unit, name:actor_id)actor
    ---@ui 附着在~1~上的Id为~2~表现
    ---@belong actor
    ---@description 单位上附着的表现
    ---@applicable value
    ---@name1 宿主
    ---@name2 表现
    if unit_check(host) then
        if host.actors then
            for _:unknown, actor:unknown in pairs(host.actors) do
                if and(actor, actor.name == name, actor:is_valid()) then
                    return actor
                end
            end
        end
    end
    return nil
end
 ---@keyword 附着 单位
function base.eff_param_get_actor(host:ref_param, name:actor_id)actor
    ---@ui 附着在节点~1~上的Id为~2~表现
    ---@belong actor
    ---@description 效果节点上附着的表现
    ---@applicable value
    ---@name1 宿主
    ---@name2 表现
    if eff_param_check(host) then
        if host.actors then
            for _:unknown, actor:unknown in pairs(host.actors) do
                if and(actor, actor.name == name, actor:is_valid()) then
                    return actor
                end
            end
        end
    end
    return nil
end

 ---@keyword 附着 效果节点
function base.actor_attach_to_actor(actor:actor, host:actor, socket:string)
    ---@ui 将~1~附着到~2~的附着点~3~处
    ---@belong actor
    ---@description 将表现附着到表现上
    ---@applicable action
    ---@name1 表现
    ---@name2 宿主
    ---@name3 绑点
    if actor then
        actor:attach_to(host, socket)
        local cache:unknown = base.eff.cache(host.name)
        if and(cache, cache.ShowShadow == false) then
            actor:set_shadow(false)
        end
        local actors:unknown = host.actors
        if not(actors) then
            actors = {}
            host.actors = actors
        end
        table.insert(host.actors, actor)
        actor.trig_host = host
    end
end
 ---@keyword 附着 表现
function base.actor_destroy(actor:actor, flag:表现摧毁方式)
    ---@ui 摧毁~1~，方式为~2~
    ---@belong actor
    ---@description 摧毁表现
    ---@applicable action
    ---@name1 表现
    ---@arg1 表现摧毁方式[false]
    ---@arg2 base.get_last_created_actor()
    if actor then
        actor:destroy(flag)
    end
end
 ---@keyword 摧毁
function base.actor_set_asset_model(actor:actor, asset:model_id)
    ---@ui 将~1~的模型资源替换为~2~
    ---@belong actor
    ---@description 替换表现的模型资源（仅对模型和粒子表现有效）
    ---@applicable action
    ---@name1 表现
    ---@name2 新模型
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:set_asset(asset)
    end
end
 ---@keyword 模型
function base.actor_set_asset_sound(actor:actor, asset:sound_id)
    ---@ui 将表现~1~的音效资源替换为~2~
    ---@belong actor
    ---@description 替换表现的音效资源（仅对音效表现有效）
    ---@applicable action
    ---@name1 表现
    ---@name2 新音效
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:set_asset(asset)
    end
end
 ---@keyword 音效
function base.actor_set_owner(actor:actor, owner:number)
    ---@ui 将~1~的所属玩家设置为~2~号位的玩家
    ---@belong actor
    ---@description 设置表现所属玩家
    ---@applicable action
    ---@name1 表现
    ---@name2 新玩家号
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:set_owner(owner)
    end
end

 ---@keyword 玩家
function base.actor_set_shadow(actor:actor, enable:是否)
    ---@ui 将~1~设置为显示影子:~2~
    ---@belong actor
    ---@description 设置表现是否显示影子（仅限模型表现）
    ---@applicable action
    ---@name1 表现
    ---@name2 是否显示影子
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:set_shadow(enable)
    end
end
 ---@keyword 影子
function base.actor_set_scale(actor:actor, scale:number)
    ---@ui 设置~1~的缩放值为~2~
    ---@belong actor
    ---@description 设置表现缩放（仅限模型和粒子表现）
    ---@applicable action
    ---@name1 表现
    ---@name2 缩放值
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:set_scale(scale)
    end
end
 ---@keyword 缩放
function base.actor_play(actor:actor)
    ---@ui 播放~1~
    ---@belong actor
    ---@description 播放表现（仅限音效、粒子和材质表现）
    ---@applicable action
    ---@name1 表现
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:play()
    end
end
 ---@keyword 播放
function base.actor_stop(actor:actor)
    ---@ui 停止播放~1~
    ---@belong actor
    ---@description 停止播放表现（仅限音效和粒子表现）
    ---@applicable action
    ---@name1 表现
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:stop()
    end
end
 ---@keyword 停止
function base.actor_pause(actor:actor)
    ---@ui 暂停音效表现~1~
    ---@belong actor
    ---@description 暂停表现（仅限音效表现）
    ---@applicable action
    ---@name1 表现
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:pause()
    end
end
 ---@keyword 暂停
function base.actor_resume(actor:actor)
    ---@ui 继续播放音效表现~1~
    ---@belong actor
    ---@description 继续播放被暂停的表现（仅限音效表现）
    ---@applicable action
    ---@name1 表现
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:resume()
    end
end
 ---@keyword 继续
function base.actor_set_volume(actor:actor, volume:number)
    ---@ui 设置音效表现~1~的音量为~2~
    ---@belong actor
    ---@description 设置表现音量（仅限音效表现）
    ---@applicable action
    ---@name1 表现
    ---@name2 音量
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:set_volume(volume)
    end
end
 ---@keyword 音量
function base.actor_set_grid_size(actor:actor, size_x:number, size_y:number)
    ---@ui 设置网格表现~1~的网格大小为~2~ ~3~
    ---@belong actor
    ---@description 设置网格物体的网格大小（仅限网格表现）
    ---@applicable action
    ---@name1 网格表现
    ---@name2 X轴大小
    ---@name3 Y轴大小（未设置同X轴）
    ---@arg1 base.get_last_created_actor()
    if actor then
        if and(size_y, size_y ~= 0) then
            actor:set_grid_size{
                size_x,
                size_y
            }
        else
            actor:set_grid_size{
                size_x,
                size_x
            }
        end
    end
end
 ---@keyword 网格 大小
function base.actor_set_grid_range(actor:actor, start_x:integer, start_y:integer, range_x:integer, range_y:integer)
    ---@ui 设置网格表现~1~的原点偏移（原点默认在左下角）为~2~ ~3~，网格范围为~4~ ~5~
    ---@belong actor
    ---@description 设置网格物体的原点偏移和网格范围（仅限网格表现）
    ---@applicable action
    ---@name1 网格表现
    ---@name2 X轴偏移
    ---@name3 Y轴偏移
    ---@name4 X轴范围
    ---@name5 Y轴范围
    ---@arg1 base.get_last_created_actor()
    if actor then
        actor:set_grid_range({
            start_x,
            start_y
        }, {
            range_x,
            range_y
        })
    end
end
 ---@keyword 网格 偏移 范围
function base.actor_set_grid_state(actor:actor, id_x:integer, id_y:integer, state:integer)
    ---@ui 设置网格表现~1~中坐标为~2~ ~3~的子网格状态为~4~
    ---@belong actor
    ---@description 设置网格表现中子网格的状态（仅限网格表现）
    ---@applicable action
    ---@name1 网格表现
    ---@name2 子网格X轴坐标
    ---@name3 子网格Y轴坐标
    ---@name4 状态
    ---@arg1 1
    ---@arg2 base.get_last_created_actor()
    if actor then
        actor:set_grid_state({
            id_x,
            id_y
        }, state)
    end
end ---@keyword 网格 状态