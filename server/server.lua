ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx_TaxiInc:pay')
AddEventHandler('esx_TaxiInc:pay', function(price)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	xPlayer.removeMoney(price)
    if Config.EnableMythicNotify then
        TriggerClientEvent('mythic_notify:client:SendAlert', source, { type = 'success', text = _U('pay_msg', price)})
    else
        TriggerClientEvent('esx:showNotification', _source, _U('pay_msg', price))
    end
end)

RegisterCommand('taxirequest', function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    local Coords = xPlayer.getCoords(true)
    TriggerClientEvent('esx_TaxiInc:callTaxi', source, Coords)
end)

RegisterCommand('taxicancel', function(source, args, raw)
    TriggerClientEvent('esx_TaxiInc:cancelTaxi', source)
end)