Players = {}

RegisterNetEvent("s4-tracker:save")
AddEventHandler("s4-tracker:save", function(data, Metadata)
    local source = source
    math = math.random(1111111111, 9999999999)

    check = LoadResourceFile(GetCurrentResourceName(), "track-data/track-"..math..".json")
    
    while check do
        math = math.random(1111111111, 9999999999)
        check = LoadResourceFile(GetCurrentResourceName(), "track-data/track-"..math..".json")
    end
 
    SaveResourceFile(GetCurrentResourceName(), "track-data/track-"..math..".json", json.encode(data), -1)
 
    if not Metadata then return end
    if Metadata.trigger then 
        Metadata.track = math
        TriggerEvent(Metadata.trigger, Metadata)
    end

end)

Framework = nil
esx = false
Citizen.CreateThread(function()
    for i = 0, GetNumResources(), 1 do
        local resource_name = GetResourceByFindIndex(i)
        if resource_name == "es_extended" and GetResourceState(resource_name) == "started" then
            esx = true
            Framework = exports['es_extended']:getSharedObject()
            break
        end
    end
    Framework = exports['qb-core']:GetCoreObject()
end)

GetPinfo = function(source)
    local source = source
    if esx == true then 
        local xPlayer = Framework.GetPlayerFromId(source)
        return {
            identifier = xPlayer.identifier,
            name = xPlayer.getName()
        }
    else 
        local xPlayer = Framework.Functions.GetPlayer(source)
        return {
            identifier = xPlayer.PlayerData.citizenid,
            name = xPlayer.PlayerData.charinfo.firstname.." "..xPlayer.PlayerData.charinfo.lastname
        }
    end 
end

RegisterNetEvent("s4-tracker:player")
AddEventHandler("s4-tracker:player", function()
    local source = source
    local xPlayer = GetPinfo(source)
    if not Players[source] then 
        Players[source] = {}  
        Players[source].source = source
        Players[source].identifier = xPlayer.identifier
        Players[source].name = xPlayer.name
        Players[source].skin = {}
        TriggerClientEvent("s4-tracker:playerLoaded", source)
    end
end)

RegisterNetEvent("s4-tracker:playerSkin")
AddEventHandler("s4-tracker:playerSkin", function(skin)
    local source = source
    Players[source].skin = skin
    TriggerClientEvent("s4-tracker:syncPlayers", -1, Players)
end)

AddEventHandler("playerDropped", function()
    local source = source
    if Players[source] then
        Players[source] = nil  
    end
end)


RegisterNetEvent("s4-tracker:requestWatch")
AddEventHandler("s4-tracker:requestWatch", function(track)
    check = LoadResourceFile(GetCurrentResourceName(), "track-data/track-"..track..".json")
    if check then
        SetPlayerRoutingBucket(source, Config.Bucket)
        TriggerClientEvent("s4-tracker:startWatcing", source, json.decode(check))
    end
end)

RegisterNetEvent("s4-tracker:stopWatch")
AddEventHandler("s4-tracker:stopWatch", function()
    SetPlayerRoutingBucket(source, 0)
end)