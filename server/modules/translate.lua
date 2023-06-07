local URL = 'https://raw.githubusercontent.com/MOXHARTZ/fivem-manager-bot-translations/main/'
local translates = {}

local function getTranslations()
    PerformHttpRequest(URL .. config.language .. '.json', function(statusCode, response, headers)
        if statusCode == 404 and config.language ~= 'en-US' then
            Debug('We could not find the your language, We will use the default language: en-US.', '\n ^2If you want to help us translate the bot, please visit: https://github.com/MOXHARTZ/fivem-manager-bot-translations^0')
            config.language = 'en-US'
            return getTranslations()
        end
        if statusCode == 200 then
            local data = json.decode(response)
            if data then
                translates = data
            else
                Warn('We could not load the translation file.')
            end
        end
    end, 'GET', '', { ['Content-Type'] = 'application/json' })
end

CreateThread(getTranslations)

function _T(key, ...)
    local args = { ... }
    local text = translates[key]
    if not text then return key end
    for i = 1, #args do
        text = text:gsub('{' .. i - 1 .. '}', args[i])
    end
    return text
end
