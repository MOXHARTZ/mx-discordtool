-- Referenced: https://github.com/overextended/ox_inventory/blob/main/modules/bridge/server.lua

local existQb = GetResourceState('qb-core') == 'started'
local existEsx = GetResourceState('es_extended') == 'started'

if existQb and existEsx then
    return error('What the hell? You have both qb-core and es_extended installed. Please remove one of them.')
elseif not existQb and not existEsx then
    return error('You need to install qb-core or es_extended to use this resource.')
elseif existQb then
    config.framework = 'qb'
elseif existEsx then
    config.framework = 'esx'
end

Framework = {}
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
