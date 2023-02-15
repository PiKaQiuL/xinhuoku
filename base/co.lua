
local table_pack = table.pack
local table_unpack = table.unpack
local coroutine_running = coroutine.running
local coroutine_yield = coroutine.yield
local coroutine_resume = coroutine.resume
local coroutine_wrap = coroutine.wrap
local error = error
local type = type
local tostring = tostring
local xpcall = xpcall

--local old_log_error = log.error
--log.error = function(s)
--    old_log_error('123')
--    old_log_error(debug.traceback(tostring(s), 2))
--end

local function check(func)
    if type(func) ~= 'function' then
        log.error(debug.traceback('param 1 is not a function'))
        return false
    end
    return true
end

-- 将异步回调转换为协程
local function wrap(func)
    return function(...)
        --if not check(func) then return false end
        local co, main = coroutine_running()
        if main then
            error ('cannot wrap coroutine by main thread!!!')
            return func
        end

        local has_yield = false
        local ret = nil
        local called = false
        local cb = function(...)
            if called then
                return
            end
            called = true
            if not has_yield then
                ret = table_pack(...)
                return
            end
            --local curr = coroutine.running()
            --log.info(('\n>>>0\nresume\niiid: %d, curr: [thread:%d] :%s\nco: [thread:%d]:%s\n<<<0\n'):format(iiid, get_tm(curr), debug.traceback(curr), get_tm(co), debug.traceback(co)))
            local result, co_error = coroutine_resume(co, ...)
            --log.info(('\n>>>1\nreturn: %s\niiid: %d, co: [thread:%d] :%s\n<<<1\n'):format(tostring(result), iiid, get_tm(co), debug.traceback(co)))
            if not result then
                local error_msg = tostring(co_error) .. debug.traceback(co)
                log.error(error_msg)
                if debug_bp then
                    debug_bp()
                end
            end
        end
        local args = table_pack(...)
        args[args.n + 1] = cb
        func(table_unpack(args, 1, args.n + 1))
        if ret then
            --log.info(('\n>>>2\nimmediately return\niiid: %d, co: [thread:%d]'):format(iiid, get_tm(co)))
            -- 如果func调用时在内部立即调用了cb, 则不能等yield返回, 应该立即return
            return table_unpack(ret, 1, ret.n)
        end
        has_yield = true
        --log.info(('\n>>>2\nyield\niiid: %d, co: [thread:%d] :%s\n<<<2\n'):format(iiid, get_tm(co), debug.traceback(co)))
        return coroutine_yield()
    end
end

local function call(func, ...)
    return wrap(func)(...)
end

local function async(fn, ...)
    local xpcall_fn = function(...)xpcall(fn, function(...)
        log.info('--async xpcall error:')
        log.error(...)
        if debug_bp then
            debug_bp()
        end
    end, ...)end
    local async_fn = coroutine_wrap(xpcall_fn)
    async_fn(...)
end

local async_next = (function(fn, ...)
    local args = table_pack(...)
    base.next(function()
        async(fn, table_unpack(args, 1, args.n))
    end)
end)

local sleep = function(timeout)
    local _sleep = wrap(base.wait)
    return _sleep(timeout)
end

local sleep_one_frame = function()
    local _sleep_one_frame = wrap(base.next)
    return _sleep_one_frame()
end

local will_async = function(func)
    return function(...)
        async(func, ...)
    end
end

coroutine.co_wrap = wrap
coroutine.call = call
coroutine.async = async
coroutine.will_async = will_async
coroutine.async_next = async_next
coroutine.sleep = sleep
coroutine.sleep_one_frame = sleep_one_frame

return {
    wrap = wrap,
    call = call,
    async = async,
    async_next = async_next,
    will_async = will_async,
    sleep = sleep,
    sleep_one_frame = sleep_one_frame,
}
