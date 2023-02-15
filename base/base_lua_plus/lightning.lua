function base.lightning_remove(lightning)
    ---@ui 移除闪电~1~
    ---@belong lightning
    ---@description 移除闪电
    ---@applicable action
    if lightning_check(lightning) then
        lightning:remove()
    end
end
 ---@keyword 移除
-- 被代码中的定义覆盖
function base.player_create_lightning(player, model, source, target)
    ---@ui 以~3~为起点~4~为终点创建模型为~2~的闪电，所属玩家为~1~
    ---@belong lightning
    ---@description 创建闪电给单位
    ---@arg1 base.player(0)
    if player_check(player) then
        local lightning = player:create_lightning{
            model = model,
            source = source,
            target = target
        }
        base.last_created_lightning = lightning
        return lightning
    end
    base.last_created_lightning = nil
end
 ---@keyword 创建 单位
-- 被代码中的定义覆盖
function base.unit_create_lightning(unit, model, source, target)
    ---@ui 以~3~为起点~4~为终点创建模型~2~的闪电，所属单位为~1~
    ---@belong lightning
    ---@description 创建闪电给玩家
    ---@arg1 base.player(0)
    if unit_check(unit) then
        local lightning = unit:lightning{
            model = model,
            source = source,
            target = target
        }
        base.last_created_lightning = lightning
        return lightning
    end
    base.last_created_lightning = nil
end ---@keyword 创建 玩家