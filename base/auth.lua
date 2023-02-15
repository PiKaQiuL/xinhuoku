
local co = include 'base.co'
local redis = include 'base.redis'

local auth = {}

-- 创建实名认证对象
-- 参数 user_id
function auth.new(user_id)
    return setmetatable({
        id = user_id
    }, {__index = auth})
end

-- 请求实名认证
-- 参数：姓名，身份证号
-- 返回：
--    result 
--    errorMsg
function auth:do_auth(name, id)

    self:print(('请求实名验证, user id [%d], 姓名 [%s], 身份证号 [%s]'):format(self.id, name, id))

    local api = '/auth/do_auth'
    local result, info = redis(self.id):send(api, {
        userId = self.id,
        name = name,
        id = id
    })
    if not result then
        self:print('实名验证失败, redis 错误')
        return false, 'redis error'
    end

    if info.result then
        self:print('实名验证成功')
        return true
    else
        self:print(('实名验证失败, 错误信息 [%s].'):format(info.errorMsg))
        return false, info.errorMsg
    end
end

-- 请求获取实名认证信息
-- 返回身份证号及姓名
function auth:get_auth_info()

    self:print(('请求获取实名验证信息, user id [%d].'):format(self.id))

    local api = '/auth/get_auth_info'
    local result, info = redis(self.id):send(api, {
        userId = self.id
    })
    if not result then
        self:print('获取实名验证信息失败, redis 错误')
        return false, 'redis error'
    end

    if info.result then
        self:print('获取实名验证信息成功，姓名 [%s], 身份证号 [%s]', info.name, info.id)
        return true, info.name, info.id
    else
        self:print(('获取实名验证信息失败, 错误信息 [%s].'):format(info.errorMsg))
        return false, info.errorMsg
    end

end

-- 传入身份证号，判断是否成年
function auth:is_adult(id)
    local born_date = id:sub(7, 14)
    local year = tonumber(born_date:sub(1, 4))
    local month = tonumber(born_date:sub(5, 6))
    local day = tonumber(born_date:sub(7, 8))
    local current = os.date('*t')
    local c_year, c_month, c_day = current.year, current.month, current.day
    if c_year - year > 18 then 
        return true
    elseif c_year - year == 18 then
        if c_month > month then
            return true
        elseif c_month == month then
            return c_day >= day
        else
            return false
        end
    else
        return false
    end
end

function auth:print(...)
    print(...)
    log.info(...)
end

return auth