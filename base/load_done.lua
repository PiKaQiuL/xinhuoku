local scene_manager = require 'base.game.scene'

local inited_scenes = base.game.get_all_scene_name()
if type(inited_scenes) == 'table' then
    for i = 1, #inited_scenes do
        scene_manager.set_scene_activated(inited_scenes[i])
    end
end
