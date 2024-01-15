Config = {}

Config.GetPlayerNamesFromServer = true -- may affect your server performance

Config.GetPlayerSkinsFromServer = true -- may affect your server performance

Config.Radius = 15.0 -- radius to get players and vehicles

Config.Bucket = 4404 -- routing bucket for players

Config.EnableCommands = true -- enable commands

Config.SkinFunction = function() -- client function to get skin
    TriggerEvent('skinchanger:getSkin', function(skin)
        TriggerServerEvent("s4-tracker:playerSkin", skin)
    end)
end


