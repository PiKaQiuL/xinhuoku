---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by xindong.
--- DateTime: 2021/5/11 20:18
---

local log_warn = log.warn
local log_debug = log.debug
local log_error = log.error
local log_info = log.info

---@param f string
local function fmt(f, ...)
    return f:format(...)
end

_G.fmt = fmt

function log.debugf(fmt, ...)
    if select('#', ...) == 0 then
        return log_debug(fmt)
    end
    return log_debug((fmt):format(...))
end

function log.infof(fmt, ...)
    if select('#', ...) == 0 then
        return log_info(fmt)
    end
    return log_info((fmt):format(...))
end

function log.warnf(fmt, ...)
    if select('#', ...) == 0 then
        return log_warn(fmt)
    end
    return log_warn((fmt):format(...))
end

function log.errorf(fmt, ...)
    if select('#', ...) == 0 then
        return log_error(fmt)
    end
    return log_error((fmt):format(...))
end

local print = print
_G.printf = function(fmt, ...)
    if select('#', ...) == 0 then
        return print(fmt)
    end
    return print((fmt):format(...))
end

function log.traceback_debug_bp(...)
    if debug_bp then
        debug_bp()
    end
end

function log.error_debug_bp(...)
    if debug_bp then
        debug_bp()
    end
end