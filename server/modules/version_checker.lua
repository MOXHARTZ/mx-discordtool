local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version', 0)

local function tonumberToVersion(number)
    local split = number:split('.')
    local version = ''
    for i = 1, #split do
        version = version .. split[i]
    end
    return tonumber(version)
end

local function checkVersionDifference(version)
    local currentVersion = tonumberToVersion(currentVersion)
    local version = tonumberToVersion(version)
    return version - currentVersion
end

if currentVersion then
    PerformHttpRequest('https://raw.githubusercontent.com/MOXHARTZ/mx-discordtool/main/fxmanifest.lua', function(code, res, headers)
        if code == 404 then
            return Warn('Api is down. We could not check the version.')
        end
        if code == 200 then
            local version = res:match("version%s+['\"]([%d%.]+)['\"]")
            local difference = checkVersionDifference(version)
            if difference == 0 then return Debug('^2 AWESOME ! You are using the latest version of mx-discordtool. ^0') end
            if difference > 5 then return error('^1You are using a very old version of mx-discordtool. Please update the script. Otherwise you may encounter errors.^0') end
            return Warn('You are using an old version of mx-discordtool. Please update the script.')
        end
    end, 'GET', '', {}, {})
else
    error('We could not check the version. Because you are using a interesting version of mx-discordtool. Please update the script.')
end
