function base.game.default_game_result(data)
    if type(data) == 'table' then
        base.game.time_stop()
        if data.player then
            xpcall(function()
                data.player:ui'default_game_result'{result = data.result}
            end, function()
                log.info('send player_game_result failed')
            end)
        end
    end
end