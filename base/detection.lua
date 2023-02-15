local check_table = {}
local use_table = {}

local sessionId = 0
local channel = "__edun_yidun_"

if base.game.get_session_id then
    channel = channel..tostring(base.game.get_session_id())
end

base.detection = {}

function find_details(sub_label)
    if not (sub_label.details and sub_label.details.hitInfos) then
        return nil
    end
    local list = {}
    for key in ipairs(sub_label.details.hitInfos) do
        table.insert(list, sub_label.details.hitInfos[key])
    end
    return list
end

function find_sub_label(label)
    if not label.subLabels then
        return nil
    end
    local list = {}
    for key in ipairs(label.subLabels) do
        tmp = find_details(label.subLabels[key])
        if tmp then
            for v in ipairs(tmp) do
                table.insert(list, tmp[v])
            end
        end
    end
    return list
end

function find_label_list(label_list)
    if not label_list then
        return nil
    end
    local list = {}
    for key in ipairs(label_list) do
        tmp = find_sub_label(label_list[key])
        if tmp then
            for v in ipairs(tmp) do
                table.insert(list, tmp[v])
            end
        end
    end
    return list
end

base.s.subscribe_message(channel,{
    ok = function (result)
        local message = result.message
        if message.code ~= 200 then -- 如果易盾服务挂了返回3检测不通过阻止创建角色，并提示稍后再试
            log.error("文本检测-易盾服务挂了")
            if use_table[message.sessionId] then
                use_table[message.sessionId] = false
                check_table[message.sessionId](3)
                check_table[message.sessionId] = nil
            end
        end
        if use_table[message.sessionId] then
            use_table[message.sessionId] = false
            if message.labels then
                local list = find_label_list(message.labels)
                check_table[message.sessionId](message.suggestion, list)
            else
                check_table[message.sessionId](message.suggestion, {})
            end
            check_table[message.sessionId] = nil
        end
    end,
})

function base.detection.check_text(text, callback)
    sessionId = sessionId + 1
    if sessionId > 2000000 then
        sessionId = 1
    end
    local id = tostring(sessionId)..tostring(os.time())
    check_table[id] = callback
    use_table[id] = true
    local filter_text, change = base.game.filter_word(text)
    if change then
        log.info("命中内部词库 : ", text)
        callback(2, {})
        return
    end
    base.s.publish_message('channel_netease_dun', {
        type = "text",
        data = text,
        sessionId = id,
        channel = channel
    })
    -- 超时返回3检测不通过阻止创建角色，并提示稍后再试
    base.wait(2000, function()
        if use_table[id] then
            use_table[id] = false
            log.error("文本检测,底层服务返回超时")
            check_table[id](3)
            check_table[id] = nil
        end
    end)
end