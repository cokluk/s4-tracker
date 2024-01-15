Scenes = {}
Lines = {}
SceneMax = 0

entity= nil
pCoords = nil
SceneMax = nil

RegisterNetEvent('s4-tracker:startWatcing')
AddEventHandler('s4-tracker:startWatcing', function(data)
    Scenes = data
    entity = PlayerPedId()
    pCoords = GetEntityCoords(entity)
    SceneMax = #Scenes
    SetEntityVisible(entity, false, false)
    Wait(100)
    for k,v in pairs(Scenes) do
        InitializeScene(k, v)
        Wait(1000)
    end
end)

cam = nil
InitializeScene = function(k, scene)
   if k == 1 then 
      DisplayRadar(false)
      pedHeading = scene['players'][1].heading
      pedCoords = ToVec3(scene['players'][1].coords)
      pedOffset = ToVec3(scene['players'][1].pedOffset)
      Dv(ToVec3(scene['players'][1].coords), 50)
      RequestCollisionAtCoord(ToVec3(scene['players'][1].coords))
      SetEntityCoords(entity, ToVec3(scene['players'][1].coords))
      cam = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', pedCoords, ToVec3(scene['players'][1].rot), 90.0, false, 2)
      SetCamActive(cam, true)
      RenderScriptCams(true, false, 3000, true, false, false)
      SetCamParams(cam, pedCoords.x , pedCoords.y, pedCoords.z + 20.5,  -90.0, 180.0, pedHeading - 50.0, 43.0557, 1000, 0, 0, 2);    
        for x,v in pairs(scene['players']) do
            scene['players'][x].createdPed = CreatePed(4, v.model, pedCoords.x, pedCoords.y, pedCoords.z, pedHeading, false, true)
            for i=1, #Scenes do
                Scenes[i]['players'][x].createdPed = scene['players'][x].createdPed
            end
        end

        b = 0 
        for i=1, #Scenes do
            if Scenes[i]['vehicles'][1] then 
                b = i
                for x,v in pairs(Scenes[i]['vehicles']) do
                    if not IsModelInCdimage(v.model) then return end
                    RequestModel(v.model)  
                    while not HasModelLoaded(v.model) do  
                        Wait(0)
                    end
                    v.createdVeh = CreateVehicle(v.model, ToVec3(v.coords), v.heading, true, false)     
                end
                break
            end
        end
  
        for i = b, 1, -1 do
            Scenes[i]['vehicles'] = Scenes[b]['vehicles']
        end

    elseif k == 15 or SceneMax == k then 
        if cam ~= nil then
            RenderScriptCams(false, false, 0, true, false, false)
            DestroyCam(cam, false)
            cam = nil
        end
        for x,v in pairs(scene['players']) do
            DeletePed(v.createdPed)
            DeleteEntity(v.createdPed)
        end
        for x,v in pairs(scene['vehicles']) do
            DeleteVehicle(v.createdVeh)
            DeleteEntity(v.createdVeh)
        end
        SetEntityCoords(GetPlayerPed(-1), pCoords)
        SetEntityVisible(GetPlayerPed(-1), true, true)
        DisplayRadar(true)
        Wait(2000)
        TriggerServerEvent("s4-tracker:stopWatch")
    else 
        Lines = {}
        for x,v in pairs(scene['vehicles']) do
            local createdVeh = scene['vehicles'][x].createdVeh
            SetEntityCoordsNoOffset(createdVeh, ToVec3(v.coords))
            SetEntityHeading(createdPed, v.heading)
        end
        for x,v in pairs(scene['players']) do
            local createdPed = scene['players'][x].createdPed
 
            for w, q in pairs(scene['vehicles']) do
               for s,f in pairs(q.vehicleSeat) do
                  if v.t_pid == f.pid then 
                    SetPedIntoVehicle(v.createdPed, q.createdVeh, f.seat)
                    break
                  end
               end
            end

            if v.aimcoords.x ~= 0 then 
                if GetSelectedPedWeapon(createdPed) ~= v.weapon then
                    GiveWeaponToPed(createdPed, v.weapon, 1, false, true)
                end
                if v.isShooting == true then 
                    TaskShootAtCoord(createdPed, ToVec3(v.aimcoords), 10.0, "CFiringPatternInfo")
                    table.insert(Lines, {
                        targetCoords = ToVec3(v.coords),
                        coords = ToVec3(v.aimcoords)
                    })
                else 
                    table.insert(Lines, {
                        targetCoords = ToVec3(v.coords),
                        coords = ToVec3(v.aimcoords)
                    })
                    TaskAimGunAtCoord(createdPed, ToVec3(v.aimcoords), 1000, 100, false, false)
                    SetPedKeepTask(createdPed, true)
                end
            end

            pedCoords = GetEntityCoords(createdPed)
            SetCamParams(cam, pedCoords.x , pedCoords.y, pedCoords.z + 20.5,  -90.0, 180.0, pedHeading - 50.0, 43.0557, 1000, 0, 0, 2);    
 
            if v.isInVehicle == false then 
                SetEntityHeading(createdPed, v.heading)
                SetEntityRotation(createdPed, ToVec3(v.rot), false, true)
                SetEntityCoordsNoOffset(createdPed, ToVec3(v.coords))
            end
        end
       
        KeepDrawLine()
    end
end
 
KeepDrawLine = function()
    Citizen.CreateThread(function()
        while #Lines > 0 do 
            for k,v in pairs(Lines) do
                DrawLine(v.targetCoords.x, v.targetCoords.y, v.targetCoords.z + 0.50, v.coords.x, v.coords.y, v.coords.z, 255, 0, 0, 255)
            end
            Citizen.Wait(0)
        end
    end)
end

function ToVec3(vector)
    return vector3(vector.x, vector.y, vector.z)
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    TriggerServerEvent("s4-tracker:stopWatch")
    SetEntityVisible(PlayerPedId(), true, true)
end)
 
