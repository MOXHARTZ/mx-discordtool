lib.callback.register('mx-discordtool:takeScreenshot', function()
    local promise = promise:new()
    exports['screenshot-basic']:requestScreenshotUpload(config.webhook, 'files[]', function(data)
        local image = json.decode(data)
        promise:resolve(image.attachments[1].proxy_url)
    end)
    return Citizen.Await(promise)
end)


RegisterNetEvent('mx-discordtool:die', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 0)
end)
