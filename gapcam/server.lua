local mounted = {}
local mode = Config.Inventory
local QBCore, ESX

local function started(name) return GetResourceState(name) == 'started' end

if mode == 'auto' then
    if started('ox_inventory') then mode = 'ox'
    elseif started('qs-inventory') then mode = 'qs'
    elseif started('qbx_core') then mode = 'qbx'
    elseif started('qb-core') then mode = 'qb'
    elseif started('es_extended') then mode = 'esx'
    else mode = 'none' end
end

print(('^2[gapcam]^7 inventory mode: %s'):format(mode))

local bridge = {}

if mode == 'ox' then
    function bridge.has(src) return (exports.ox_inventory:Search(src, 'count', Config.Item) or 0) > 0 end
    function bridge.remove(src) return exports.ox_inventory:RemoveItem(src, Config.Item, 1) end
    function bridge.add(src) exports.ox_inventory:AddItem(src, Config.Item, 1) end
    function bridge.register() end

elseif mode == 'qs' then
    function bridge.has(src) return (exports['qs-inventory']:GetItemTotalAmount(src, Config.Item) or 0) > 0 end
    function bridge.remove(src) return exports['qs-inventory']:RemoveItem(src, Config.Item, 1) end
    function bridge.add(src) exports['qs-inventory']:AddItem(src, Config.Item, 1) end
    function bridge.register()
        exports['qs-inventory']:CreateUsableItem(Config.Item, function(src)
            TriggerClientEvent('gapcam:use', src)
        end)
    end

elseif mode == 'qbx' then
    local function player(src) return exports.qbx_core:GetPlayer(src) end
    function bridge.has(src)
        local p = player(src)
        local item = p and p.Functions.GetItemByName(Config.Item)
        return item ~= nil and (item.amount or item.count or 0) > 0
    end
    function bridge.remove(src) local p = player(src) return p and p.Functions.RemoveItem(Config.Item, 1) end
    function bridge.add(src) local p = player(src) if p then p.Functions.AddItem(Config.Item, 1) end end
    function bridge.register()
        exports.qbx_core:CreateUseableItem(Config.Item, function(src) TriggerClientEvent('gapcam:use', src) end)
    end

elseif mode == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
    function bridge.has(src)
        local p = QBCore.Functions.GetPlayer(src)
        local item = p and p.Functions.GetItemByName(Config.Item)
        return item ~= nil and (item.amount or 0) > 0
    end
    function bridge.remove(src) local p = QBCore.Functions.GetPlayer(src) return p and p.Functions.RemoveItem(Config.Item, 1) end
    function bridge.add(src) local p = QBCore.Functions.GetPlayer(src) if p then p.Functions.AddItem(Config.Item, 1) end end
    function bridge.register()
        QBCore.Functions.CreateUseableItem(Config.Item, function(src) TriggerClientEvent('gapcam:use', src) end)
    end

elseif mode == 'esx' then
    ESX = exports.es_extended:getSharedObject()
    function bridge.has(src)
        local p = ESX.GetPlayerFromId(src)
        local item = p and p.getInventoryItem(Config.Item)
        return item ~= nil and (item.count or 0) > 0
    end
    function bridge.remove(src)
        local p = ESX.GetPlayerFromId(src)
        if not p then return false end
        p.removeInventoryItem(Config.Item, 1)
        return true
    end
    function bridge.add(src) local p = ESX.GetPlayerFromId(src) if p then p.addInventoryItem(Config.Item, 1) end end
    function bridge.register()
        ESX.RegisterUsableItem(Config.Item, function(src) TriggerClientEvent('gapcam:use', src) end)
    end

else
    function bridge.has() return true end
    function bridge.remove() return true end
    function bridge.add() end
    function bridge.register() end
end

CreateThread(function()
    Wait(1000)
    bridge.register()
end)

lib.callback.register('gapcam:canPlace', function(source)
    return not mounted[source] and bridge.has(source)
end)

lib.callback.register('gapcam:consume', function(source)
    if mounted[source] then return false end
    if not bridge.remove(source) then return false end
    mounted[source] = true
    return true
end)

RegisterNetEvent('gapcam:returnItem', function()
    local src = source
    if not mounted[src] then return end
    mounted[src] = nil
    bridge.add(src)
end)

AddEventHandler('playerDropped', function()
    mounted[source] = nil
end)
