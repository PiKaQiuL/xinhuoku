
local co        = include 'base.co'
local redis     = include 'base.redis'
local api       = include 'base.pay.api'
local proto     = include 'base.pay.proto'
local events    = include 'base.pay.events'

local pay = {}

-- @public
-- 新建一个充值对象
-- info : 充值信息
    -- sandbox : 是否为沙盒环境
    -- map : 地图名
    -- player : 要充值的玩家
    -- amount : 充值金额
    -- type : 货币单位
    -- desc : 描述信息
    -- rate : 兑换比例
    -- service : 支付服务 AliPay/ApplePay/WXGame
    -- client : 客户端类型 Windows/iOS/Android/Web
    -- receipt : 收据 (ApplePay 需要传)
function pay.new(info)
    return setmetatable({
        sandbox = info.sandbox or false,
        map = info.map or '',
        player = info.player,
        amount = info.amount,
        type = info.type or '钻石',
        desc = info.desc or '充值钻石',
        rate = info.rate or 100,
        receipt = info.receipt or '',
        service = info.service or 'AliPay',
        client = info.client or 'Windows'
    }, {__index = pay})
end

-- @public
-- 执行充值操作
function pay:start()

    -- 定期检查支付是否完成
    local check_timer
    if self:get_service_type() == 'web' then
        check_timer = base.loop(5000, function()
            self:query_state()
        end)
    end

    self:keep_alive()

    local result, ret = xpcall(pay.start_impl, log.error, self)

    self:cancel_keep_alive()

    if check_timer then
        check_timer:remove()
    end

    if not result then
        self:info(('支付失败，错误信息 %s'):format(ret))
        return false
    end

    return true
end

-- @public
-- 主动查询订单状态, 仅在 web 支付环境下有效
function pay:query_state()
    if self:get_service_type() ~= 'web' then return end
    self:emit(events.DISABLE_UI)
    self:trigger('check')
end

-- @public
-- 取消订单
function pay:cancel()
    self:emit(events.DISABLE_UI)
    self:trigger('cancel')
end

-- @public
-- 注册外部事件
function pay:subscribe(event, callback)
    if not self.o_events then self.o_events = {} end
    local events = self.o_events
    events[event] = callback
end

-- @public
-- 获取交易号
function pay:get_transaction()
    return self.transaction
end

-- @public
-- 获取余额
function pay:get_balance()
    local result, balance = xpcall(pay.get_balance_impl, log.error, self)
    if not result then
        self:info(('获取余额失败，错误信息'):format(ret))
        return false
    end
    return true, balance
end

-- @private
function pay:start_impl()

    if not self.player then
        self:error('无效的玩家')
    end

    self.user_id = base.auxiliary.get_player_id(self.player)
    if not self.user_id then
        self:error('无效的 user id')
    end

    self:info(('开始充值 [%s], 充值金额 [%.2f], 兑换比例 [%d]'):format(self.type, self.amount, self.rate))

    local service_type = self:get_service_type()
    if service_type == 'web' then
        self:web_pay()
    elseif service_type == 'native' then
        self:native_pay()
    elseif service_type == 'direct' then
        self:direct_pay()
    end

    self:unregister()

    self:info(('订单支付完成, 准备添加 [%s] ...'):format(self.type))

    local score = math.floor(self.amount * self.rate)
    self:info(('将要添加 [%d] 个 [%s]'):format(score, self.type))

    local ret = self:add_score(score)

    self:emit(events.ENABLE_UI)
    return ret

end

function pay:get_service_type()
    self:info(('服务类型 [%s].'):format(self.service))
    local service_type_map = {
        ['ApplePay'] = 'native',
        ['AliPay'] = 'web',
        ['WXGame'] = 'direct',
    }
    return service_type_map[self.service]
end

-- @private
-- web 支付，如支付宝
function pay:web_pay()

    -- 请求生成订单
    self.id, self.url = self:build()
    self:info(('生成订单成功，订单号 [%s], url [%s], 等待玩家支付'):format(self.id, self.url));

    -- 把 url 发送给客户端
    self:send_url()

    -- 等待玩家支付
    while true do
        local action = self:wait()
        self:info('action', action)
        if action == 'cancel' then
            self:info(('玩家取消订单, 订单号 [%s]'):format(self.id))
            local result, code = self:cancel_impl()
            if result then 
                self:info('玩家取消订单成功')
                self:error('玩家取消订单')
            end
            if code == api.ERROR_CODE.PAYMENT_ALREADY_FINISHED then
                self:info('玩家取消支付，但实际上已经支付完成')
                break
            end
        elseif action == 'check' then
            local status = self:query_state_impl()
            if status == api.STATUS.FINISH then
                break
            elseif status == api.STATUS.TIMEOUT then
                self:warn('订单超时')
                self:error('玩家订单超时')
            else
                self:info('玩家尚未支付')
                self:emit(events.ENABLE_UI)
                self:emit(events.UNFINISHED)
            end
        end
    end
end

-- @private
-- app 支付，如 apply pay
function pay:native_pay()
    self.id, self._, self.status, self.transaction = self:send()
    if self.status ~= api.STATUS.FINISH then
        self:error(('支付验证失败 [%s].'):format(self.status))
    end
end

-- @private
-- 直接支付，如微信小游戏
function pay:direct_pay()
    self.id, self._, self.status, self.transaction = self:send()
    if self.status ~= api.STATUS.FINISH then
        self:error(('支付验证失败 [%s].'):format(self.status))
    end
end

-- @private
-- 发送订单给服务器
function pay:send()
    
    self:info('准备生成订单 ...')

    local result, info = redis(self.user_id):send(api.REQ_CREATE_PAYMENT, {
        sandbox = self.sandbox or false,
        mapName = self.map,
        userId = self.user_id,
        serviceType = self.service,
        clientType = self.client,
        amount = self.amount,
        name = self.type,
        desc = self.desc,
        receipt = self.receipt
    })

    if not result then
        self:error(('发送订单失败'))
        return
    end

    self.transaction = info.transaction

    if info.result ~= 0 then
        self:error(('发送订单失败, 错误码 [%d].'):format(info.result))
        return
    end

    return info.id, info.url, info.status, info.transaction

end

-- @private
-- 把 url 发送给客户端
function pay:send_url()
    self:info(('发送 url 给客户端 [%s]'):format(self.url))
    self.player:ui(proto.S2C.NOTIFY_PAY_URL)({ url = self.url })
end

-- @private
-- 等待玩家界面上的操作
function pay:wait()
    local wait = co.wrap(self.wait_impl)
    return wait(self)
end

-- @private
-- 等待玩家界面上的操作
function pay:wait_impl(callback)
    local events = {'check', 'cancel'}
    for _, event in ipairs(events) do
        self:register(event, function() callback(event) end)
    end
end

-- @private
-- 日志
function pay:info(msg)
    local error_message = ('[充值] [user_id:%d] %s.'):format(self.user_id or 0, msg)
    log.info(error_message)
    print(error_message)
end

-- @private
-- 警告
function pay:warn(msg)
    local error_message = ('[充值] [user_id:%d] %s.'):format(self.user_id or 0, msg)
    log.warn(error_message)
    print(error_message)
end

-- @private
-- 报错
function pay:error(msg)
    local error_message = ('[充值错误] [user_id:%d] %s.'):format(self.user_id, msg)
    log.warn(error_message)
    error(error_message)
end

-- @private
function pay:basic_req()
    return {
        userId = self.user_id,
        serviceType = self.service,
        clientType = self.client,
        id = self.id
    }
end

-- @private
-- 查询订单状态
function pay:query_state_impl()
    local result, info = redis(self.id):send(api.REQ_QUERY_PAYMENT, self:basic_req())
    if not result then
        self:info('查询订单状态失败')
        return
    end
    if info.result ~= api.ERROR_CODE.SUCCESS then
        self:info(('服务器查询订单状态失败，错误码 [%d].'):format(info.result))
        return 
    end

    self:info(('查询订单状态成功，订单 [%s] 状态 [%s].'):format(self.id, info.status))

    return info.status
end

-- @private
-- 取消订单
function pay:cancel_impl()
    local result, info = redis(self.user_id):send(api.REQ_CANCEL_PAYMENT, self:basic_req())
    if not result then
        self:info('取消订单失败')
        return false
    end
    if info.result ~= api.ERROR_CODE.SUCCESS then
        self:info(('服务器取消订单失败，错误码 [%d].'):format(info.result))
        return false, info.result
    end

    self:info(('取消订单 [%s] 成功.'):format(self.id))

    return true
end

-- @private
-- 添加积分
function pay:add_score(score)
    local add_score = function(self, callback)
        local c = base.s.get_commit()
        c.money_add(self.player, self.type, score)
        c.commit('充值-' .. self.id,
        {
            ok = function() 
                self:info('添加积分成功')
                callback(true) 
            end,
            error = function(code, reason)
                self:info(('添加积分失败, 错误码 %d, 原因 %s'):format(code, reason))
                callback(false) 
            end,
            timeout = function()
                self:info('添加积分失败， 超时')
                callback(false)
            end
        })
    end
    return co.wrap(add_score)(self)
end

-- @private
-- 注册内部事件
function pay:register(event, callback)
    if not self.events then self.events = {} end
    local events = self.events
    events[event] = callback
end

-- @private
-- 解除注册
function pay:unregister()
    self.events = {}
end

-- @private
-- 触发内部事件
function pay:trigger(event, ...)
    if self.events[event] then self.events[event](event, ...) end
end

-- @private
-- 触发外部事件
function pay:emit(event, ...)
    if self.o_events[event] then self.o_events[event](event, ...) end
end

local keep_alive_refs = 0

function pay:keep_alive()
    local alive_time = 30 * 60
    self:info(('%d 分钟后结束游戏'):format(alive_time // 60))
    keep_alive_refs = keep_alive_refs + 1
    base.game.keep_alive(alive_time)
end

function pay:cancel_keep_alive()
    keep_alive_refs = keep_alive_refs - 1
    self:info('支付计数 - 1')
    if keep_alive_refs == 0 then
        self:info('可以结束游戏')
        base.game.cancel_keep_alive()
    end
end

function pay:get_balance_impl()

    self:info('准备获取余额 ...')

    local result, info = redis(self.user_id):send(api.REQ_GET_BALANCE, {
        sandbox = self.sandbox or false,
        mapName = self.map,
        userId = self.user_id,
        serviceType = self.service,
        clientType = self.client
    })

    if not result then
        self:error(('获取余额失败'))
        return
    end

    if info.result ~= 0 then
        self:error(('获取余额, 错误码 [%d].'):format(info.result))
        return
    end

    self:info(('获取余额成功，余额 [%.2f].'):format(info.balance))

    return info.balance
end

function pay.subscribe_payment_message(player, cb)
    local user_id = base.auxiliary.get_player_id(player)
    local sub_channel = string.format("Redis.Server2Host.Channel.Payment_%s", user_id)
    log.info("subscribe_payment_message channel:"..sub_channel)
    base.s.subscribe_message(sub_channel, {
        ok = function (obj)
            log.info("subscribe_message success!")
            if obj then
                if cb then
                    cb(obj)
                end
                log.info('recieve subscribe_payment_message:', json.encode(obj))
                player:ui('on_balance_update')({info = obj})
            end
        end,
        error = function (code, reason)
            log.error('订阅 失败', channel, code, reason)
        end,
        timeout = function ()
            log.error('订阅 失败，超时', channel)
        end
    })
end

return pay