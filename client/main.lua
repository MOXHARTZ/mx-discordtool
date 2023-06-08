lib.callback.register('mx-discordtool:takeScreenshot', function(webhook)
    local promise = promise:new()
    exports['screenshot-basic']:requestScreenshotUpload(webhook, 'files[]', function(data)
        local image = json.decode(data)
        promise:resolve(image.attachments[1].proxy_url)
    end)
    return Citizen.Await(promise)
end)

lib.callback.register('mx-discordtool:isModelExist', function(model)
    return IsModelInCdimage(model)
end)


RegisterNetEvent('mx-discordtool:die', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
end)
