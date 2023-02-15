--- lua_plus ---
function base.timer_clock()number
    ---@ui 已经过的游戏时间(秒)
    ---@belong timer
    ---@description 当前游戏时间
    ---@applicable value
    return base.clock() / 1000
end
 ---@keyword 游戏 时间
function base.timer_remove(timer:timer)
    ---@ui 移除计时器~1~
    ---@belong timer
    ---@description 移除计时器
    ---@applicable action
    if timer_check(timer) then
        timer:remove()
    end
end
 ---@keyword 移除 计时器
function base.timer_resume(timer:timer)
    ---@ui 恢复计时器~1~
    ---@belong timer
    ---@description 恢复计时器
    ---@applicable action
    if timer_check(timer) then
        timer:resume()
    end
end
 ---@keyword 恢复 计时器
function base.timer_pause(timer:timer)
    ---@ui 暂停计时器~1~
    ---@belong timer
    ---@description 暂停计时器
    ---@applicable action
    if timer_check(timer) then
        timer:pause()
    end
end
 ---@keyword 暂停 计时器
function base.timer_restart(timer:timer)
    ---@ui 重启计时器~1~
    ---@belong timer
    ---@description 重启计时器
    ---@applicable action
    if timer_check(timer) then
        timer:restart()
    end
end
 ---@keyword 重启 计时器
function base.timer_sleep(time:number)
    ---@ui 等待~1~秒
    ---@belong timer
    ---@description 等待一段时间
    ---@applicable action
    return coroutine.sleep(math.floor(time * 1000))
end
 ---@keyword 等待 时间
function base.timer_wait(time:number, func:function<timer>())timer
    ---@ui 等待~1~秒后执行~2~
    ---@belong timer
    ---@description 等待一段时间后执行动作
    ---@applicable both
    return base.wait(math.floor(time * 1000), func)
end
 ---@keyword 等待 执行
function base.timer_loop(time:number, func:function<timer>())timer
    ---@ui 每~1~秒执行~2~
    ---@belong timer
    ---@description 每隔一段时间循环执行动作
    ---@applicable both
    return base.loop(math.floor(time * 1000), func)
end
 ---@keyword 循环 执行
function base.timer_timer(time:number, times:integer, func:function<timer>())timer
    ---@ui 每~1~秒执行~3~共执行~2~次
    ---@belong timer
    ---@description 每隔一段时间循环执行动作(限定次数)
    ---@applicable both
    return base.timer(math.floor(time * 1000), times, func)
end

 ---@keyword 循环 执行
function base.remaining(timer:timer)number
    ---@ui ~1~的剩余时间
    ---@belong timer
    ---@description 计时器剩余的秒数
    ---@applicable both
    return timer:get_remaining_time() // 1000
end ---@keyword 剩余 时间