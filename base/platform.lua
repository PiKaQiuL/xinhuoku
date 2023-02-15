
local shell = include 'base.shell'

local function get(player)
   return shell(player, 'return common.get_platform()')
end

return {
    get = get,
}