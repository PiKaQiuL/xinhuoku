function base.capturer_remove(capturer)
    ---@ui 移除弹道捕获器~1~
    ---@belong unit
    ---@description 移除弹道捕获器
    ---@applicable action
    ---@name1 弹道捕获器
    if capturer ~= nil then
        capturer:remove()
    end
end

 ---@keyword 移除
function base.unit_capturer(unit, radius)
    ---@ui 为~1~创建捕获范围为~2~的捕获器
    ---@belong unit
    ---@description 创建弹道捕获器
    ---@applicable value
    ---@name1 单位
    ---@name2 范围半径
    if unit ~= nil then
        return unit:capturer{
            radius = radius
        }
    end
end ---@keyword 创建