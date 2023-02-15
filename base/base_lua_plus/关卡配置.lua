function base.create_wave(关卡配置表, 波次初始朝向)
    ---@ui 根据关卡配置表~1~创建初始朝向为~2~的波次
    ---@belong game
    ---@description 创建波次
    ---@applicable action
    for 波次序号, 波次表id in ipairs(关卡配置表.waves) do
        local 波次表 = base.eff.cache(波次表id)
        base.timer_sleep(波次表.wave_delay)
        for 刷怪序号, 刷怪表id in ipairs(波次表.wave_data) do
            local 刷怪表 = base.eff.cache(刷怪表id)
            local 路径表 = base.eff.cache(刷怪表.lineEx)
            local 刷怪次数 = 刷怪表.times
            local 单次刷怪数量 = 刷怪表.num
            base.timer_sleep(刷怪表.delay)
            for index = 1, 刷怪次数, 1 do
                for 序号 = 1, 单次刷怪数量, 1 do
                    local unit = base.player_create_unit_ai(base.player(0), 刷怪表.monster, base.line_get(路径表.Line(), 1), 波次初始朝向, false)
                    base.unit_ai_move_to(unit, 路径表.Line(), false)
                end
                base.timer_sleep(刷怪表.pulse)
            end
        end
    end
end ---@keyword 波次