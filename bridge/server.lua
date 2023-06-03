-- Referenced: https://github.com/overextended/ox_inventory/blob/main/modules/bridge/server.lua

local resource = GetCurrentResourceName()
local scriptPath = ('bridge/%s/server.lua'):format(config.framework)
local resourceFile = LoadResourceFile(resource, scriptPath)
if not resourceFile then
    return error(('Failed to load %s'):format(scriptPath))
end

local func, err = load(resourceFile, ('@@%s/%s'):format(resource, scriptPath))

if not func then
    return error(('Failed to load %s: %s'):format(scriptPath, err))
end

func()
