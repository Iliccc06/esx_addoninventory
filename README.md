# esx_addoninventory
if someone wants esx_addoninventory but in json


if you want it to work you have to replace the path and getstock item with this code

RegisterNetEvent('something:getStockItem', function(itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    local inventory = xPlayer.getInventoryItem(itemName)

    if xPlayer.job.name ~= 'something' then
        print(('[^3WARNING^7] Player ^5%s^7 attempted ^something:getStockItem^7 (cheating)'):format(source))
        return
    end

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_something', function(inventory)
        local itemCount = inventory.items[itemName] or 0
    
        if itemCount < count or count < 1 then
            return xPlayer.showNotification(TranslateCap('quantity_invalid'))
        end
    
        inventory.removeItem(itemName, count)
        xPlayer.addInventoryItem(itemName, count)
        xPlayer.showNotification(TranslateCap('have_withdrawn', count, itemName))
    
        print("You take: " .. itemName .. " Količina: " .. count)
    end)
end)

ESX.RegisterServerCallback('something:getStockItems', function(source, cb)
    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_something', function(inventory)
        print("Inventar:", json.encode(inventory.items)) 
        cb(inventory.items)
    end)
end)

RegisterNetEvent('something:putStockItems', function(itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
	local sourceItem = xPlayer.getInventoryItem(itemName)
    
    if xPlayer.job.name ~= 'something' then
        print(('[^3WARNING^7] Player ^5%s^7 attempted ^something:putStockItems^7 (cheating)'):format(source))
        return
    end

    TriggerEvent('esx_addoninventory:getSharedInventory', 'society_something', function(inventory)
        local itemCount = inventory.items[itemName] or 0
        
        local sourceItem = xPlayer.getInventoryItem(itemName)
        
        if sourceItem.count < count or count < 1 then
            return xPlayer.showNotification(TranslateCap('quantity_invalid'))
        end
        xPlayer.removeInventoryItem(itemName, count)
        inventory.addItem(itemName, count)
        xPlayer.showNotification(TranslateCap('have_deposited', count, itemName))
    
        print("You put: " .. itemName .. " Količina: " .. count)
    end)
end)

local function getItem(inventory, itemName)
    if inventory[itemName] then
        return { count = inventory[itemName], label = itemName }
    else
        return { count = 0, label = itemName } 
    end
end
