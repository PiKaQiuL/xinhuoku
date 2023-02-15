function base.score_commit_init(game_name)
    ---@ui 基于~1~新建云变量变更请求
    ---@belong score
    ---@description 新建一个云变量变更请求
    ---@applicable both
    ---@arg1 "__MAIN_MAP__"
    if game_name == '__MAIN_MAP__' then
        game_name = nil
    end
    local c = score.get_commit(game_name)
    base.last_created_score_committer = c
    return c
end
 ---@keyword 提交
function base.get_last_created_score_committer()
    ---@ui 触发器最后创建的云变量变更请求
    ---@belong score
    ---@description 触发器最后创建的云变量变更请求
    ---@applicable value
    return base.last_created_score_committer
end
 ---@keyword 提交
function base.get_last_commit_success()
    ---@ui 触发器最后提交的云变量变更请求是否成功
    ---@belong score
    ---@description 触发器最后提交的云变量变更请求是否成功
    ---@applicable value
    return base.last_commit_success
end
 ---@keyword 提交
function base.get_last_commit_error_code()
    ---@ui 触发器最后提交的云变量变更请求错误代码
    ---@belong score
    ---@description 触发器最后提交的云变量变更请求错误代码
    ---@applicable value
    return base.last_commit_error_code
end
 ---@keyword 提交
function base.get_last_commit_error_msg()
    ---@ui 触发器最后提交的云变量变更请求错误消息
    ---@belong score
    ---@description 触发器最后提交的云变量变更请求错误消息
    ---@applicable value
    return base.last_commit_error_msg
end
 ---@keyword 提交
function base.string_to_score_game(game_name)
    ---@ui 地图~1~
    ---@belong score
    ---@description 转换字符串地图名为地图
    ---@applicable value
    return game_name
end

 ---@keyword 地图
function base.score_money_get(player, key)
    ---@ui 获取玩家~1~的云变量货币~2~的值
    ---@belong score
    ---@description 获得玩家的云变量货币值
    ---@applicable value
    ---@arg1 "我的货币"
    ---@arg2 base.player(1)
    local error_code, data, err_msg = score.money_get{
        user_id = tostring(player:user_id()),
        key = key
    }
    base.last_commit_error_code = error_code
    base.last_commit_error_msg = err_msg
    if error_code == 0 then
        return ((data and data[1] and data[1].value) or 0)
    else
        log.error(fmt("错误码: %s, 错误数据: %s, 错误信息: %s", error_code, json.encode(data), err_msg))
        base.last_commit_error_code = error_code
        return 0
    end
end
 ---@keyword 数值 货币
function base.score_geti(player, key)
    ---@ui 玩家~1~的数值型云变量~2~的值
    ---@belong score
    ---@description 获得玩家的数值型云变量值
    ---@applicable value
    ---@arg1 "自定义积分"
    ---@arg2 base.player(1)
    local error_code, data, err_msg = score.get{
        user_id = tostring(player:user_id()),
        key = key
    }
    base.last_commit_error_code = error_code
    base.last_commit_error_msg = err_msg
    if error_code == 0 then
        return ((data and data[1] and data[1].i_value) or 0)
    else
        log.error(fmt("错误码: %s, 错误数据: %s, 错误信息: %s", error_code, json.encode(data), err_msg))
        return 0
    end
end
 ---@keyword 数值
function base.score_gets(player, key)
    ---@ui 获取玩家~1~的字符串型云变量~2~的值
    ---@belong score
    ---@description 获得玩家的字符串云变量值
    ---@applicable value
    ---@arg1 "自定义积分"
    ---@arg2 base.player(1)
    local error_code, data, err_msg = score.get{
        user_id = tostring(player:user_id()),
        key = key
    }
    base.last_commit_error_code = error_code
    base.last_commit_error_msg = err_msg
    if error_code == 0 then
        return ((data and data[1] and data[1].s_value) or "")
    else
        log.error(fmt("错误码: %s, 错误数据: %s, 错误信息: %s", error_code, json.encode(data), err_msg))
        return 0
    end
end
 ---@keyword 数值
function base.score_get(player, key)
    ---@ui 玩家~1~的任意表格类型云变量~2~的值
    ---@belong score
    ---@description 获得玩家的任意表格类型云变量值
    ---@applicable value
    ---@arg1 "自定义积分"
    ---@arg2 base.player(1)
    local error_code, data, err_msg = score.get{
        user_id = tostring(player:user_id()),
        key = key
    }
    base.last_commit_error_code = error_code
    base.last_commit_error_msg = err_msg
    if error_code == 0 then
        return ((data and data[1] and data[1].value) or nil)
    else
        log.error(fmt("错误码: %s, 错误数据: %s, 错误信息: %s", error_code, json.encode(data), err_msg))
        return 0
    end
end

 ---@keyword 数值
function base.score_c_money_set(c, player, key, value)
    ---@ui 向~1~添加操作：将玩家~2~的货币~3~设置为~4~
    ---@belong score
    ---@description 添加云变量请求操作：设置玩家货币
    ---@applicable action
    ---@arg1 1
    ---@arg2 "我的货币"
    ---@arg3 base.player(1)
    ---@arg4 base.get_last_created_score_committer()
    if committer_check(c) then
        c.money_set{
            user_id = tostring(player:user_id()),
            key = key,
            value = value
        }
    end
end
 ---@keyword 数值
function base.score_c_money_add(c, player, key, value)
    ---@ui 向~1~添加操作：将玩家~2~的货币~3~增加~4~
    ---@belong score
    ---@description 添加云变量请求操作：修改玩家货币
    ---@applicable action
    ---@arg1 1
    ---@arg2 "我的货币"
    ---@arg3 base.player(1)
    ---@arg4 base.get_last_created_score_committer()
    if committer_check(c) then
        c.money_add{
            user_id = tostring(player:user_id()),
            key = key,
            value = value
        }
    end
end
 ---@keyword 数值
function base.score_c_money_cost(c, player, key, value)
    ---@ui 向~1~添加操作：将玩家~2~的货币~3~消耗~4~
    ---@belong score
    ---@description 添加云变量请求操作：消耗玩家货币
    ---@applicable action
    ---@arg1 1
    ---@arg2 "我的货币"
    ---@arg3 base.player(1)
    ---@arg4 base.get_last_created_score_committer()
    if committer_check(c) then
        c.money_cost{
            user_id = tostring(player:user_id()),
            key = key,
            value = value
        }
    end
end
 ---@keyword 数值
function base.score_c_seti(c, player, key, value)
    ---@ui 向~1~添加操作：将玩家~2~的数值型云变量~3~值设置为~4~
    ---@belong score
    ---@description 添加云变量请求操作：设置数值型云变量
    ---@applicable action
    ---@arg1 1
    ---@arg2 "自定义积分"
    ---@arg3 base.player(1)
    ---@arg4 base.get_last_created_score_committer()
    if committer_check(c) then
        c.set{
            user_id = tostring(player:user_id()),
            key = key,
            i_value = value
        }
    end
end
 ---@keyword 数值
function base.score_c_addi(c, player, key, value)
    ---@ui 向~1~添加操作：将玩家~2~的~3~值增加~4~
    ---@belong score
    ---@description 添加云变量请求操作：修改数值型云变量
    ---@applicable action
    ---@arg1 1
    ---@arg2 "自定义积分"
    ---@arg3 base.player(1)
    ---@arg4 base.get_last_created_score_committer()
    if committer_check(c) then
        c.addi{
            user_id = tostring(player:user_id()),
            key = key,
            value = value
        }
    end
end
 ---@keyword 数值
function base.score_c_sets(c, player, key, value)
    ---@ui 向~1~添加操作：将玩家~2~的字符串型云变量~3~值设置为~4~
    ---@belong score
    ---@description 添加云变量请求操作：设置字符串型云变量
    ---@applicable action
    ---@arg1 "自定义积分"
    ---@arg2 base.player(1)
    ---@arg3 base.get_last_created_score_committer()
    if committer_check(c) then
        c.set{
            user_id = tostring(player:user_id()),
            key = key,
            s_value = value
        }
    end
end
 ---@keyword 字符串
function base.score_c_set(c, player, key, value)
    ---@ui 向~1~添加操作：将玩家~2~的任意表格类型云变量~3~值设置为~4~
    ---@belong score
    ---@description 添加云变量请求操作：设置任意表格类型云变量
    ---@applicable action
    ---@arg1 "自定义积分"
    ---@arg2 base.player(1)
    ---@arg3 base.get_last_created_score_committer()
    if committer_check(c) then
        c.set{
            user_id = tostring(player:user_id()),
            key = key,
            value = value
        }
    end
end
 ---@keyword 字符串
function base.score_c_commit(c)
    ---@ui 向云端提交~1~
    ---@belong score
    ---@description 提交云变量变更请求
    ---@applicable both
    ---@arg1 base.get_last_created_score_committer()
    if committer_check(c) then
        local ec, j, err_msg = c.commit()
        if ec == 0 then
            base.last_commit_success = true
        else
            base.last_commit_success = false
        end
        base.last_commit_error_code = j
        base.last_commit_error_msg = err_msg
        return base.last_commit_success
    end
    base.last_commit_success = false
    base.last_commit_error_code = - 1
    base.last_commit_error_msg = nil
    return false
end ---@keyword 提交