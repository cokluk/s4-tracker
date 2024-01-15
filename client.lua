Scenes = {}
Metadata = {}
Players = {}
Save = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)	 
        if NetworkIsPlayerActive(PlayerId()) then
            TriggerServerEvent("s4-tracker:player")
            break
        end
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    while true do 
        CurrentScene = {}

        CurrentScene = GetSceneData()

        if #Scenes >= 15 then
            if Save == true then
                TriggerServerEvent('s4-tracker:save', Scenes, Metadata)
                Save = false
                Metadata = {}
                Scenes = {}
            else
                Scenes = {}
            end
        else 
            table.insert(Scenes, CurrentScene)
        end

        Citizen.Wait(1000)
    end
end)
 
if Config.EnableCommands == true then
    RegisterCommand("save", function()
        Save = true
    end)

    RegisterCommand("watch", function(source, args)
        TriggerServerEvent("s4-tracker:requestWatch", args[1])
    end)
end

RegisterNetEvent('s4-tracker:save')
AddEventHandler('s4-tracker:save', function(meta)
    Save = true
    if meta then Metadata = meta end
end)

RegisterNetEvent('s4-tracker:syncPlayers')
AddEventHandler('s4-tracker:syncPlayers', function(players)
    Players = players
end)

GetSceneData = function()
   Scene = {}
   Scene['players'] = GetClosestPlayers(Config.Radius)
   Scene['vehicles'] = GetClosestVehicles(Config.Radius)
   for k,v in pairs(Scene['players']) do
       Scene['players'][k].pInfo = Players[v.t_pid] 
   end
   return Scene
end

function GetClosestVehicles(radius)
    local vehicles = {}
    local playerCoords = GetEntityCoords(PlayerPedId())
    local vehiclePool = GetGamePool('CVehicle')  
 
    for i = 1, #vehiclePool do  
        if #(playerCoords - GetEntityCoords(vehiclePool[i])) <= radius then
            if NetworkGetEntityIsNetworked(vehiclePool[i] ) then
                table.insert(vehicles, {
                    vid = vehiclePool[i],
                    model = GetEntityModel(vehiclePool[i]),
                    vehicleSeat = {},
                    speed = GetEntitySpeed(vehiclePool[i]),
                    coords = GetEntityCoords(vehiclePool[i]),
                    heading = GetEntityHeading(vehiclePool[i]),
                })
            end
        end
    end

    for k,v in pairs(vehicles) do
        for i = -1, GetVehicleMaxNumberOfPassengers(v.vid) do
            if GetPedInVehicleSeat(v.vid, i) ~= 0 then
                ped = GetPedInVehicleSeat(v.vid, i)
                nPed = NetworkGetPlayerIndexFromPed(ped)
                table.insert(vehicles[k].vehicleSeat, {
                    seat = i,
                    ped = ped,
                    pid = GetPlayerServerId(nPed)
                })
            end
        end
    end
 
    return vehicles
end


-- TaskShootAtCoord


function GetClosestPlayers(radius)
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetCoords = GetEntityCoords(targetPed)
        local distance = #(playerCoords - targetCoords)
        t_ped = NetworkGetPlayerIndexFromPed(targetPed)
        t_pid = GetPlayerServerId(t_ped)

        isShooting = IsPedShooting(targetPed)
        isAiming = IsPlayerFreeAiming(t_ped)
        weapon = GetSelectedPedWeapon(targetPed)

        entity = nil
        hit = vector3(0.0, 0.0, 0.0)
        aimcoords = vector3(0.0, 0.0, 0.0)

        if isAiming and targetPed == PlayerPedId() then
            hit, aimcoords, entity = RayCastGamePlayCamera(1000.0)
        end
 
        if distance <= radius then

            pInfo = {}
            
            table.insert(players, {
                player = player,
                t_ped  = t_ped,
                t_pid  = t_pid,
                model = GetEntityModel(targetPed),
                coords = targetCoords,
                rot = GetEntityRotation(targetPed),
                pedOffset = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, 1.0),
                heading = GetEntityHeading(targetPed),
                isDead = IsPlayerDead(t_ped),
                health = GetEntityHealth(targetPed),
                armor = GetPedArmour(targetPed),
                isInVehicle = IsPedInAnyVehicle(targetPed, false),
                vehModel = GetVehiclePedIsUsing(playerPed),
                isDead = IsPlayerDead(t_ped),
                isUsingWeapon = IsPedArmed(targetPed, 7),
                weapon = weapon,
                isShooting = isShooting,
                isAiming = isAiming,
                isRunning = IsPedRunning(targetPed),
                hit = hit,
                aimcoords = aimcoords,
                entity = entity or nil,
                pInfo = pInfo
            })
        end
    end

    return players
end

function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

function RayCastGamePlayCamera(distance)
	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination = 
	{ 
		x = cameraCoord.x + direction.x * distance, 
		y = cameraCoord.y + direction.y * distance, 
		z = cameraCoord.z + direction.z * distance 
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, -1, 1))
	return b, c, e
end

RegisterNetEvent("s4-tracker:playerLoaded")
AddEventHandler("s4-tracker:playerLoaded", Config.SkinFunction)
 
DumpTable = function(table, nb)
	if nb == nil then
		nb = 0
	end

	if type(table) == 'table' then
		local s = ''
		for i = 1, nb + 1, 1 do
			s = s .. "    "
		end

		s = '{\n'
		for k,v in pairs(table) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			for i = 1, nb, 1 do
				s = s .. "    "
			end
			s = s .. '['..k..'] = ' .. DumpTable(v, nb + 1) .. ',\n'
		end

		for i = 1, nb, 1 do
			s = s .. "    "
		end

		return s .. '}'
	else
		return tostring(table)
	end
end



Dv = function(coords, radius)

	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = GetVehiclesInArea(coords, radius)

		for k,entity in ipairs(vehicles) do
			local attempt = 0

			while not NetworkHasControlOfEntity(entity) and attempt < 100 and DoesEntityExist(entity) do
				Citizen.Wait(100)
				NetworkRequestControlOfEntity(entity)
				attempt = attempt + 1
			end

			if DoesEntityExist(entity) and NetworkHasControlOfEntity(entity) then
				DeleteVehicle(entity)
			end
		end
	else
		local vehicle, attempt = GetVehicleInDirection(), 0

		if IsPedInAnyVehicle(GetPlayerPed(-1), true) then
			vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)
		end

		while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
			Citizen.Wait(100)
			NetworkRequestControlOfEntity(vehicle)
			attempt = attempt + 1
		end

		if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
		   DeleteVehicle(vehicle)
		end
	end

end


GetVehiclesInArea = function(coords, maxDistance)
	return EnumerateEntitiesWithinDistance(GetGamePool('CVehicle'), false, coords, maxDistance)
end

GetVehicleInDirection = function()
	local playerPed    = GetPlayerPed(-1)
	local playerCoords = GetEntityCoords(playerPed)
	local inDirection  = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle    = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

	if hit == 1 and GetEntityType(entityHit) == 2 then
		local entityCoords = GetEntityCoords(entityHit)
		return entityHit, entityCoords
	end

	return nil
end


DeleteVehicle = function(vehicle)
	SetEntityAsMissionEntity(vehicle, false, true)
	DeleteVehicle(vehicle)
end