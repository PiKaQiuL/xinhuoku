function base.snapshot_get_point(snapshot)
    ---@ui 快照~1~的坐标
    ---@belong eff_param
    ---@description 快照的坐标
    ---@applicable value
    if snapshot_check(snapshot) then
        return snapshot:get_point()
    end
end
 ---@keyword 坐标
function base.snapshot_get_name(snapshot)
    ---@ui 快照~1~的单位Id
    ---@belong eff_param
    ---@description 快照的单位Id
    ---@applicable value
    if snapshot_check(snapshot) then
        return snapshot:get_name()
    end
end
 ---@keyword 单位Id
function base.snapshot_get_owner(snapshot)
    ---@ui 快照~1~的所属玩家
    ---@belong eff_param
    ---@description 快照的所属玩家
    ---@applicable value
    if snapshot_check(snapshot) then
        return snapshot:get_owner()
    end
end
 ---@keyword 玩家
function base.snapshot_get_facing(snapshot)
    ---@ui 快照~1~的朝向
    ---@belong eff_param
    ---@description 快照的朝向
    ---@applicable value
    if snapshot_check(snapshot) then
        return snapshot:get_facing()
    end
end ---@keyword 朝向 角度