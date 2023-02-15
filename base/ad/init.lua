

local rpc = require 'base.rpc'

local id = 0
local function show_reward_video_ad(player, reward, amount, cb)
    id = id + 1
    local extra = tostring(id)
    local user_id = base.auxiliary.get_player_id(player)
    local sub_channel = string.format("Redis.Server2Host.Channel.Ad_%s_%s", user_id, extra)
    local server_verify = false
    if cb then
        base.s.subscribe_message(sub_channel, {
            ok = function (obj)
                log.info("finish ad", reward, amount)
                cb({ result = true})
                server_verify = true
            end,
            error = function (code, reason)
                log.error('订阅 失败', channel, code, reason)
            end,
            timeout = function ()
                log.error('订阅 失败，超时', channel)
            end
        })
    end

    rpc.show_reward_video_ad(player, reward, amount, extra, function(play_res) 
        if not play_res.result and not server_verify then
            cb(play_res)
        end
    end)
end

base.ad = {}
base.ad.show_reward_video_ad = show_reward_video_ad