
local co        = include 'base.co'
local json      = include 'base.json_save'

local session = 10000

local redis = {}
local subscribed = {}
local response = {}

local function info(text)
    local str = '[redis] ' .. text
    print(str)
    log.warn(str)
end

local function sub(channel, session, callback)
    if not response[channel] then response[channel] = {} end
    response[channel][session] = callback
    if subscribed[channel] then 
        return
    end
    local function finish(session_id, result, obj)
        if obj then
            info(('收到 redis 消息 %s'):format(json(obj)))
        end
        if response[channel] then
            if response[channel][session_id] then
                response[channel][session_id](result, obj)
            end
            response[channel][session_id] = nil
        end
    end
    base.s.subscribe_message(channel, {
        ok = function (obj)
            finish(obj.message.sessionId, true, obj.message)
        end,
        error = function (code, reason)
            info(('订阅 [%s] 失败，code [%d], reason [%s].'):format(channel, code, reason))
            finish(session, false)
        end,
        timeout = function ()
            info(('订阅 [%s] 失败，超时'):format(channel))
            finish(session, false)
        end
    })
    subscribed[channel] = true
end

local function pub(channel, msg)
    base.s.publish_message(channel, msg)
end

function redis:send_impl(channel, msg, callback)
    msg = msg or {}
    session = session + 1
    session_id = session
    msg.sessionId = session_id
    msg.responseChannel = channel .. self.id
    info('session id : ' .. msg.sessionId)
    info('res channel : ' .. msg.responseChannel)
    sub(msg.responseChannel, msg.sessionId, callback)
    pub(channel, msg) 
end

function redis:send(channel, msg)
    local send = co.wrap(redis.send_impl)
    return send(self, channel, msg)
end

local instances = {}
local function get(id)
    if not instances[id] then
        instances[id] = setmetatable({
            id = id
        }, {__index = redis})
    end
    return instances[id]
end

return get