---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Yuri.
--- DateTime: 2018/4/22 22:06
---

require 'base.class'

local table_insert = table.insert
local table_concat = table.concat
local error = error

local traceback = nil

local debug = rawget(_G, 'debug')
if debug and debug.traceback then
    traceback = debug.traceback  -- 能用官方的traceback最好
else
    traceback = function(msg, level)
        return msg  -- 尴尬...
    end
end

---@class Exception: Class
---@field __call fun(msg: string): Exception
---@field __tostring fun(self): string
---@field msg string
---@field previous_exception Exception
---@field is_exception boolean
---@field to_string string
local Exception = class('Exception')
Exception.is_exception = true

function Exception.make(cls, ...)
    return Exception._make(cls, 2, ...)
end

function Exception._make(cls, trace_level, ...)
    trace_level = (trace_level or 1) + 1
    local e = cls.new(...)  ---@type Exception

    e:set_traceback(traceback(nil, trace_level + 1))
    return e
end

local function __Exception_index(self, cls, key)
    local ret = rawget(self, key)
    if ret then return ret end

    ret = cls[key]
    if ret then return ret end

    local previous_exception = rawget(self, 'previous_exception')
    if previous_exception then
        ret = previous_exception[key]
        if ret then return ret end
    end

    return nil
end

function Exception:ctor(msg)
    local cls = self.class
    local mt = {}
    for k, v in pairs(cls) do
        if k:sub(1, 2) == '__' and #k > 3 then
            mt[k] = v
        end
    end
    mt.__index = function(t, key)
        return __Exception_index(t, cls, key)
    end

    setmetatable(self, mt)
    self.msg = msg
end

function Exception:set_traceback(trace)
    self.traceback = trace
end

function Exception:set_previous_exception(err)
    self.previous_exception = err
    self._string = nil  -- 清掉缓存
end

function Exception:_to_string_to_t(t)
    local previous_exception = rawget(self, 'previous_exception')
    if previous_exception then
        previous_exception:_to_string_to_t(t)
        table_insert(t, '\n')
    end

    table_insert(t, '++++++++++++++++++++++++++++++++++++++++++++++++++\n')
    table_insert(t, self.__cname..': '..tostring(self.msg))
    table_insert(t, '\n')
    table_insert(t, self.traceback)
    table_insert(t, '\n--------------------------------------------------')
end

function Exception:to_string()

    if self.class ~= Exception then
        return self.__cname
    end

    if self._string then
        return self._string
    end

    local t = {}
    self:_to_string_to_t(t)

    self._string = table_concat(t)  -- cache it !

    return self._string
end

function Exception:__tostring()
    return self:to_string()
end

local function to_exception(err)
    if type(err) == 'table' and err.is_exception then
        return err
    end

    local e = Exception:_make(2, err)
    return e
end

---@param e Exception
local function throw(e)
    if instance_of(e, Exception) then
        local new_err = Exception:_make(2, 'rethrow exception')
        new_err:set_previous_exception(e)
        error(new_err)
    else
        error(to_exception(e))
    end
end

local default_exception_handler = nil

local function _default_exception_handler(err)
    --log.warn(tostring(err))
    log.error(err)
end

local function set_default_exception_handler(func)
    default_exception_handler = func
end

local function get_default_exception_handler()
    return default_exception_handler or _default_exception_handler
end

_G.Exception = Exception
_G.to_exception = to_exception
_G.throw = throw

base.Exception = Exception
base.to_exception = to_exception
base.throw = throw


_G.get_default_exception_handler = get_default_exception_handler
_G.set_default_exception_handler = set_default_exception_handler

return {
    Exception = Exception,
    to_exception = to_exception,
    throw = throw,
}