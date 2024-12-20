--[[if ESX.GetConfig().OxInventory then
	AddEventHandler('onServerResourceStart', function(resourceName)
		if resourceName == 'ox_inventory' or resourceName == GetCurrentResourceName() then
			local stashes = MySQL.query.await('SELECT * FROM addon_inventory')

			for i=1, #stashes do
				local stash = stashes[i]
				local jobStash = stash.name:find('society') and string.sub(stash.name, 9)
				exports.ox_inventory:RegisterStash(stash.name, stash.label, 100, 200000, stash.shared == 0 and true or false, jobStash)
			end
		end
	end)

	return
end

Items = {}
local InventoriesIndex, Inventories, SharedInventories = {}, {}, {}

MySQL.ready(function()
	local items = MySQL.query.await('SELECT * FROM items')

	for i=1, #items, 1 do
		Items[items[i].name] = items[i].label
	end

	local result = MySQL.query.await('SELECT * FROM addon_inventory')

	for i=1, #result, 1 do
		local name   = result[i].name
		local label  = result[i].label
		local shared = result[i].shared

		local result2 = MySQL.query.await('SELECT * FROM addon_inventory_items WHERE inventory_name = @inventory_name', {
			['@inventory_name'] = name
		})

		if shared == 0 then

			table.insert(InventoriesIndex, name)

			Inventories[name] = {}
			local items       = {}

			for j=1, #result2, 1 do
				local itemName  = result2[j].name
				local itemCount = result2[j].count
				local itemOwner = result2[j].owner

				if items[itemOwner] == nil then
					items[itemOwner] = {}
				end

				table.insert(items[itemOwner], {
					name  = itemName,
					count = itemCount,
					label = Items[itemName]
				})
			end

			for k,v in pairs(items) do
				local addonInventory = CreateAddonInventory(name, k, v)
				table.insert(Inventories[name], addonInventory)
			end

		else
			local items = {}

			for j=1, #result2, 1 do
				table.insert(items, {
					name  = result2[j].name,
					count = result2[j].count,
					label = Items[result2[j].name]
				})
			end

			local addonInventory    = CreateAddonInventory(name, nil, items)
			SharedInventories[name] = addonInventory
			GlobalState.SharedInventories = SharedInventories
		end
	end
end)

function GetInventory(name, owner)
	for i=1, #Inventories[name], 1 do
		if Inventories[name][i].owner == owner then
			return Inventories[name][i]
		end
	end
end

function GetSharedInventory(name)
	return SharedInventories[name]
end

function AddSharedInventory(society)
    if type(society) ~= 'table' or not society?.name or not society?.label then return end
    -- society (array) containing name (string) and label (string)

    -- addon inventory:
    MySQL.Async.execute('INSERT INTO addon_inventory (name, label, shared) VALUES (@name, @label, @shared)', {
        ['name'] = society.name,
        ['label'] = society.label,
        ['shared'] = 1
    })

    SharedInventories[society.name] = CreateAddonInventory(society.name, nil, {})
end

AddEventHandler('esx_addoninventory:getInventory', function(name, owner, cb)
	cb(GetInventory(name, owner))
end)

AddEventHandler('esx_addoninventory:getSharedInventory', function(name, cb)
	cb(GetSharedInventory(name))
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	local addonInventories = {}

	for i=1, #InventoriesIndex, 1 do
		local name      = InventoriesIndex[i]
		local inventory = GetInventory(name, xPlayer.identifier)

		if inventory == nil then
			inventory = CreateAddonInventory(name, xPlayer.identifier, {})
			table.insert(Inventories[name], inventory)
		end

		table.insert(addonInventories, inventory)
	end

	xPlayer.set('addonInventories', addonInventories)
end)
--]]
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

-- Funkcija za učitavanje JSON fajla
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

-- Kreiranje inventara ako ne postoji
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

-- Dodavanje ili uklanjanje stavki iz inventara
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

-- Dobijanje inventara
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