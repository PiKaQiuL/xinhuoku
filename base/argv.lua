
local shell = include 'base.shell'

local function get(player, str)
    return shell(player, ('return require("base.argv").get("%s")'):format(str))
end

local function has(player, str)
    return shell(player, ('return require("base.argv").has("%s")'):format(str))
end

return {
    get = get,
    has = has
}