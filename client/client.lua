local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil
local currentTaxi = nil
local currentDriver = nil
local Customer = nil
local parkingDone = false
local ArrivedS1 = false
local inCar = false
local onRoute = false
local Destination = nil
local cancelTaxi = false
local blip = nil
local isTaxiSended = false
local curSequence = nil
local DriveFast = true
local canDispatch = true
local bIsNear = false

Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/taxirequest', _U('suggest_request'))
	TriggerEvent('chat:addSuggestion', '/taxicancel', _U('suggest_cancel'))
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()
	if ESX.PlayerData then
		ESX.PlayerLoaded = true
        print('AI Taxi : Ready')
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
	ESX.PlayerData = playerData
end)

RegisterNetEvent('esx:onPlayerDeath')
AddEventHandler('esx:onPlayerDeath', function(data)
    if Customer ~= nil then
        TaskVehicleDriveWander(currentDriver, currentTaxi, Config.DriveSpeedNormal, Config.DriveStyleNormal)
        Finalize(false, true, true)
    end
end)

RegisterNetEvent("esx_TaxiInc:cancelTaxi")
AddEventHandler("esx_TaxiInc:cancelTaxi",function()
    if Customer ~= nil then
        TaskVehicleDriveWander(currentDriver, currentTaxi, Config.DriveSpeedNormal, Config.DriveStyleNormal)
        Finalize(false, true, true)
    else
        TalkBox(_U('cancel_false'), 'inform')
    end
end)

RegisterNetEvent("esx_TaxiInc:callTaxi")
AddEventHandler("esx_TaxiInc:callTaxi",function(coords)
    if not canDispatch then
        TalkBox(_U('request_too_fast'), 'error')
        return
    end
    if Customer then
        TalkBox(_U('request_wait'), "inform")
    else
        -- Find Nearest Vehicle Node around player for Taxi to stop at, we don't want taxi to run over the player
        -- Taxi Target Point
        local Found, outPos, outHeading = GetClosestVehicleNodeWithHeading(coords.x + math.random(-5, 5),coords.y + math.random(-5, 5), coords.z,1,3.0, 0)
        if Found then
            -- So, we managed to find a spot for the taxi, lets load our Ped hash and Vehicle hash
            while not HasModelLoaded(Config.PedHash) do
                RequestModel(Config.PedHash)
                Wait(50)
            end
            while not HasModelLoaded(Config.VehicleHash) do
                RequestModel(Config.VehicleHash)
                Wait(50)
            end
            -- Gonna spawn the taxi outside player FOV.
            local FoundEx, outPosEx, outHeadingEx = GetClosestVehicleNodeWithHeading(coords.x + math.random(Config.RGNLow, Config.RGNHigh),coords.y + math.random(Config.RGNLow, Config.RGNHigh),coords.z,1,3.0,0)
            if FoundEx then
                Customer = outPos
                canDispatch = false
                if DoesEntityExist(currentTaxi) then
                    ESX.Game.DeleteVehicle(currentTaxi)
                end
                ESX.Game.SpawnVehicle(Config.VehicleHash, outPosEx, outHeadingEx, function(callback_vehicle)
                    SetEntityAsMissionEntity(callback_vehicle, true, true)
                    SetVehicleEngineOn(callback_vehicle, true, true, false)
                    SetVehicleEngineHealth(callback_vehicle, GetVehicleEngineHealth(callback_vehicle) + 1000.0)
                    currentDriver = CreatePedInsideVehicle(callback_vehicle, 26, Config.PedHash, -1, true, false)
                    SetBlockingOfNonTemporaryEvents(currentDriver, true)
                    if DoesBlipExist(GetBlipFromEntity(currentDriver)) ~= 1 then
                        blip = AddBlipForEntity(currentDriver)
                        SetBlipAsFriendly(blip, true)
                        SetBlipSprite(blip, 198)
                        BeginTextCommandSetBlipName("STRING")
		                AddTextComponentString('Taxi')
		                EndTextCommandSetBlipName(blip)
                    end
                    currentTaxi = callback_vehicle
                    DriveToLocation(outPos, currentDriver, currentTaxi, true)
                    isTaxiSended = true
                end)
                SetModelAsNoLongerNeeded(Config.PedHash)
                SetModelAsNoLongerNeeded(Config.VehicleHash)
                TalkBox(_U('request_success'), 'inform')
            else
                TalkBox(_U('request_fail_spawn_ofov'), 'error')
            end
        else
            TalkBox(_U('request_fail_tts'), 'error')
        end
    end
end)

Citizen.CreateThread(function()
    while true do
         Citizen.Wait(0)
         if Customer then
            if isTaxiSended then
                local currentVeh = GetVehiclePedIsIn(PlayerPedId())
                local myCoords = GetEntityCoords(PlayerPedId())
                local taxiCoords = GetEntityCoords(currentDriver)
                if not IsPedInAnyTaxi(currentDriver) or IsPedDeadOrDying(currentDriver) then
                    TalkBox(_U('cancel_driver_interrupt'), "error")
                    Finalize(false, false)
                    goto Continue
                end
                if GetVehicleEngineHealth(currentTaxi) == -4000 then
                    TalkBox(_U('cancel_taxidestroyed'), "error")
                    Finalize(false, true)
                    goto Continue
                end
                if GetVehicleFuelLevel(currentTaxi) == 0 then
                    TalkBox(_U('cancel_outoffuel'), "error")
                    Finalize(false, true)
                    goto Continue
                end
                if GetDistanceBetweenCoords(myCoords.x,myCoords.y,myCoords.z,taxiCoords.x,taxiCoords.y,taxiCoords.z) < 10 and not onRoute and vehicle ~= currentTaxi then
                    TaskVehicleDriveWander(currentDriver, currentTaxi, 0.0, Config.DriveStyleNormal)
                    bIsNear = true
                end
                if bIsNear and GetDistanceBetweenCoords(myCoords.x,myCoords.y,myCoords.z,taxiCoords.x,taxiCoords.y,taxiCoords.z) >= 15 and not onRoute and vehicle ~= currentTaxi then
                    TalkBox(_U('cancel_walkaway'), "error")
                    Finalize(false, true)
                    goto Continue
                end
                if currentVeh == currentTaxi then
                    if not onRoute then
                        local waypoint = GetFirstBlipInfoId(8)
                        if not DoesBlipExist(waypoint) then
                            ESX.ShowHelpNotification(_U('await_placeway'))
                        end
                        if DoesBlipExist(waypoint) then
                            Destination = GetBlipInfoIdCoord(waypoint)
                            DriveToLocation(Destination, currentDriver, currentTaxi)
                            ESX.ShowHelpNotification(_U('await_success'))
                            onRoute = true
                            Citizen.Wait(9000)
                            DriveFast = false
                        end
                    end
                end
                ::Continue::
            end
         end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if onRoute then
            local currentVeh = GetVehiclePedIsIn(PlayerPedId())
            local myCoords = GetEntityCoords(PlayerPedId())
            local taxiCoords = GetEntityCoords(currentDriver)
            if currentVeh == currentTaxi then
                -- Check our location and Destination
                if GetDistanceBetweenCoords(myCoords.x, myCoords.y, myCoords.z, Destination.x, Destination.y, Destination.z) < 20 then
                    TaskVehicleDriveWander(currentDriver, currentTaxi, 0.0, Config.DriveStyleNormal)
                    Finalize(true, true)
                end
                 -- Handle Destination Changing
                local waypoint = GetFirstBlipInfoId(8)
                if DoesBlipExist(waypoint) then
                    if Destination ~= GetBlipInfoIdCoord(waypoint) then
                        Destination = GetBlipInfoIdCoord(waypoint)
                        DriveToLocation(Destination, currentDriver, currentTaxi)
                        TalkBox(_U('trip_changedDesti'), 'inform')
                    end
                end
                -- Handle Go Faster
                if not DriveFast then
                    ESX.ShowHelpNotification(_U('trip_sonic_promp'))
                end
                if IsControlJustReleased(0, Keys['E']) and not DriveFast then
                    ESX.ShowHelpNotification(_U('trip_sonic_confirm'))
                    SetDriveTaskDrivingStyle(currentDriver, Config.DriveStyleFast)
                    SetDriveTaskCruiseSpeed(currentDriver, Config.DriveSpeedFast)
                    DriveFast = true
                end
            else
                TalkBox(_U('cancel_jumpoff'), 'error')
                TaskVehicleDriveWander(currentDriver, currentTaxi, Config.DriveSpeedNormal, Config.DriveStyleNormal)
                Finalize(true, true)
            end
        end
    end
end)

function DriveToLocation(Dest, ped, veh, slow)
    local _, sequence = OpenSequenceTask(ped)
    if slow then
        TaskVehicleDriveToCoordLongrange(ped, veh, Dest.x, Dest.y, Dest.z, 10.0, Config.DriveStyleNormal, 30.0)
    else
        TaskVehicleDriveToCoordLongrange(ped, veh, Dest.x, Dest.y, Dest.z, Config.DriveSpeedNormal, Config.DriveStyleNormal, 30.0)
    end
    CloseSequenceTask(sequence)
    curSequence = sequence
	return sequence
end

function Finalize(chargePlayer, removeCar, cancel)
    local playerPed = GetPlayerPed(-1)
    if cancel then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle == currentTaxi then
            TalkBox(_U('cancel_fail'),'error')
            return
        else
            TalkBox(_U('cancel_success'),'error')
        end
    end
    if chargePlayer then
        myCoords = GetEntityCoords(playerPed)
        route2 = CalculateTravelDistanceBetweenPoints(Customer.x, Customer.y, Customer.z, myCoords.x, myCoords.y, myCoords.z)
		if DriveFast then 
            PricePerKM = Config.FarePer1KMFast 
        else 
            PricePerKM = Config.FarePer1KMSlow 
        end
        if not Config.FreeOfCharge then
		    price = (route2/1000) * PricePerKM
        else
            price = 0.0
        end
		TriggerServerEvent('esx_TaxiInc:pay', price)
		TaskLeaveVehicle(GetPlayerPed(-1), currentTaxi, 1)
		Citizen.Wait(3000)
    end
    TaskVehicleDriveWander(currentDriver, currentTaxi, Config.DriveSpeedNormal, Config.DriveStyleNormal)
    onRoute = false
    Customer = nil
    parkingDone = false
    ArrivedS1 = false
    inCar = false
    Destination = nil
    cancelTaxi = false
    RemoveBlip(blip)
    blip = nil
    isTaxiSended = false
    curSequence = nil
    DriveFast = true
    bIsNear = false
    Citizen.Wait(15000)
    DeletePed(currentDriver)
    if removeCar then
        ESX.Game.DeleteVehicle(currentTaxi)
    else
        SetVehicleAsNoLongerNeeded(currentTaxi)
    end
    currentTaxi = nil
    currentDriver = nil
    canDispatch = true
end

function TalkBox(msg, type)
    -- Inform - 'inform'
    -- Error - 'error'
    -- Success - 'success'
    if Config.EnableMythicNotify then
        exports['mythic_notify']:DoHudText(type, msg)
    else
        ESX.ShowNotification(msg)
    end
end