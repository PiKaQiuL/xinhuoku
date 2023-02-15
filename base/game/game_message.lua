function base.game:message(data)
    for player in base.each_player 'user' do
        player:message(data)
    end
end

function base.game:get_winner_team()
    return base.team(self:get_winner())
end