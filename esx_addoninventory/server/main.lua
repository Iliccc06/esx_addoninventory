if ESX.GetConfig().OxInventory then
    AddEventHandler('onServerResourceStart', function(resourceName)
        if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
            -- Učitavanje inventara iz JSON fajla
            local data = loadInventory()

            -- Proverite da li postoji 'addon_inventory' u podacima
            if data['addon_inventory'] then
                local stashes = data['addon_inventory']

                for i = 1, #stashes do
                    local stash = stashes[i]
                    -- Proverava se da li je naziv stash-a za društvo i postavlja se ako jeste
                    local jobStash = stash.name:find('society') and string.sub(stash.name, 9)
                    -- Registracija stash-a u ox_inventory
                    exports.ox_inventory:RegisterStash(stash.name, stash.label, 100, 200000, stash.shared == 0 and true or false, jobStash)
                end
            else
                print("Nema podataka o addon inventarima u JSON fajlu.")
            end
        end
    end)

    return
end

local jsonFile = "./inventorii.json"

local function loadInventory()
    local loadFile = LoadResourceFile(GetCurrentResourceName(), jsonFile)
    if loadFile then
        return json.decode(loadFile)
    else
        return {} -- Ako fajl ne postoji, vraća prazan objekat
    end
end

local function saveInventory(data)
    SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode(data, { indent = true }), -1)
end

local function createInventory(type, identifier)
    local data = loadInventory()
    if not data[type] then
        data[type] = {}
    end

    if not data[type][identifier] then
        data[type][identifier] = {
            items = {} -- Prazan inventar
        }
        saveInventory(data)
    end
end

local function updateInventory(type, identifier, item, count)
    local data = loadInventory()
    if data[type] and data[type][identifier] then
        local inventory = data[type][identifier].items

        if inventory[item] then
            inventory[item] = inventory[item] + count
            if inventory[item] <= 0 then
                inventory[item] = nil 
            end
        else
            if count > 0 then
                inventory[item] = count
            end
        end
        saveInventory(data)
    end
end

RegisterNetEvent('esx_addoninventory:getSharedInventory')
AddEventHandler('esx_addoninventory:getSharedInventory', function(identifier, cb)
    local data = loadInventory()


    print("Učitani podaci iz inventara: " .. json.encode(data))

    if not data['organization'] then
        data['organization'] = {}
    end

    if not data['organization'][identifier] then
        data['organization'][identifier] = { items = {} }
        saveInventory(data)
    end

    local inventory = data['organization'][identifier].items

    print("Inventar za " .. identifier .. ": " .. json.encode(inventory))

    local inventoryWrapper = {
        items = inventory,
        addItem = function(itemName, count)
            inventory[itemName] = (inventory[itemName] or 0) + count
            saveInventory(data)  
        end,
        removeItem = function(itemName, count)
            if inventory[itemName] then
                inventory[itemName] = inventory[itemName] - count
                if inventory[itemName] <= 0 then
                    inventory[itemName] = nil
                end
                saveInventory(data)  
            end
        end
    }

    cb(inventoryWrapper)  
end)


RegisterServerEvent('esx_addoninventory:getPlayerInventory')
AddEventHandler('esx_addoninventory:getPlayerInventory', function(playerId, cb)
    local identifier = 'player_' .. playerId
    local data = loadInventory()
    createInventory('player', identifier)
    cb(data['player'][identifier])
end)

RegisterServerEvent('esx_addoninventory:addItem')
AddEventHandler('esx_addoninventory:addItem', function(type, identifier, item, count)
    createInventory(type, identifier)
    updateInventory(type, identifier, item, count)
end)

RegisterServerEvent('esx_addoninventory:removeItem')
AddEventHandler('esx_addoninventory:removeItem', function(type, identifier, item, count)
    createInventory(type, identifier)
    updateInventory(type, identifier, item, -count)
end)

local function getItem(inventory, itemName)
    if inventory[itemName] then
        return { count = inventory[itemName], label = itemName }
    else
        return { count = 0, label = itemName } 
    end
end
