-- server.lua
local VORPcore = exports.vorp_core:GetCore()
local VORPInv = exports.vorp_inventory:vorp_inventoryApi()
local oxmysql = exports.oxmysql

local ownedSpeakeasies = {}
local playerJugs = {}
local playerBrews = {}

print("Starting tlg-speakeasy server.lua (patched for moonshine)")

-- Helper SQL wrapper
local function ExecuteSql(query, params, cb)
    if cb then
        oxmysql:execute(query, params or {}, cb)
    else
        oxmysql:executeSync(query, params or {})
    end
end

-- Database init
Citizen.CreateThread(function()
    ExecuteSql("CREATE TABLE IF NOT EXISTS speakeasies (identifier VARCHAR(50) PRIMARY KEY, speakeasy_name VARCHAR(100) NOT NULL, owner_name VARCHAR(100) NOT NULL DEFAULT 'Unknown')", {})
    ExecuteSql("SELECT identifier, speakeasy_name, owner_name FROM speakeasies", {}, function(result)
        for _, row in pairs(result or {}) do
            ownedSpeakeasies[row.identifier] = {
                name = row.speakeasy_name,
                ownerName = row.owner_name
            }
            VORPInv.registerInventory("speakeasy_stash_" .. row.speakeasy_name, "Speakeasy Stash", 20, false, true, true)
        end
        print("Server loaded " .. tostring(#result) .. " owned speakeasies")
        TriggerClientEvent('speakeasy:updateOwnedSpeakeasies', -1, ownedSpeakeasies)
    end)
end)

RegisterServerEvent('speakeasy:getIdentifier')
AddEventHandler('speakeasy:getIdentifier', function(context)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then
        print("speakeasy:getIdentifier failed: No user found for source " .. src)
        Citizen.CreateThread(function()
            local maxRetries = 5
            local retryCount = 0
            while retryCount < maxRetries do
                Wait(5000)
                user = VORPcore.getUser(src)
                if user then
                    local character = user.getUsedCharacter
                    if character and character.identifier then
                        print("Sending identifier " .. character.identifier .. " for context " .. context .. " to source " .. src)
                        TriggerClientEvent('speakeasy:callback:' .. context, src, character.identifier)
                        return
                    end
                end
                retryCount = retryCount + 1
                print("Retry " .. retryCount .. ": No user/character for source " .. src)
            end
            TriggerClientEvent('speakeasy:callback:' .. context, src, nil)
        end)
        return
    end
    local character = user.getUsedCharacter
    if not character or not character.identifier then
        print("speakeasy:getIdentifier failed: No character/identifier for source " .. src)
        TriggerClientEvent('speakeasy:callback:' .. context, src, nil)
        return
    end
    print("Sending identifier " .. character.identifier .. " for context " .. context .. " to source " .. src)
    TriggerClientEvent('speakeasy:callback:' .. context, src, character.identifier)
end)

RegisterServerEvent('speakeasy:requestSync')
AddEventHandler('speakeasy:requestSync', function()
    local src = source
    TriggerClientEvent('speakeasy:updateOwnedSpeakeasies', src, ownedSpeakeasies)
end)

RegisterServerEvent('speakeasy:buySpeakeasy')
AddEventHandler('speakeasy:buySpeakeasy', function(speakeasyName, price)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then
        print("No user found for source: " .. src)
        return
    end
    local character = user.getUsedCharacter
    if not character then
        print("No character data for source: " .. src)
        return
    end
    local identifier = character.identifier
    local ownerName = character.firstname .. " " .. character.lastname

    if ownedSpeakeasies[identifier] then
        TriggerClientEvent('vorp:TipRight', src, "You already own a speakeasy!", 5000)
        return
    end

    for _, data in pairs(ownedSpeakeasies) do
        if data.name == speakeasyName then
            TriggerClientEvent('vorp:TipRight', src, speakeasyName .. " is already owned!", 5000)
            return
        end
    end

    if character.money >= price then
        character.removeCurrency(0, price)
        ownedSpeakeasies[identifier] = {name = speakeasyName, ownerName = ownerName}
        playerJugs[identifier] = playerJugs[identifier] or {}
        playerJugs[identifier][speakeasyName] = playerJugs[identifier][speakeasyName] or {jugs = 0}
        playerBrews[identifier] = playerBrews[identifier] or {}
        playerBrews[identifier][speakeasyName] = playerBrews[identifier][speakeasyName] or {count = 0}
        print("Initialized playerBrews for " .. identifier .. " at " .. speakeasyName .. ": " .. json.encode(playerBrews[identifier]))
        oxmysql:executeSync("INSERT INTO speakeasies (identifier, speakeasy_name, owner_name) VALUES (@identifier, @speakeasyName, @ownerName)", {
            ['@identifier'] = identifier,
            ['@speakeasyName'] = speakeasyName,
            ['@ownerName'] = ownerName
        })
        
        VORPInv.registerInventory("speakeasy_stash_" .. speakeasyName, "Speakeasy Stash", 20, false, true, true)
        TriggerClientEvent('speakeasy:updateOwnedSpeakeasies', -1, ownedSpeakeasies)
        TriggerClientEvent('vorp:TipRight', src, "You bought " .. speakeasyName .. " for $" .. price, 5000)
        print("ownedSpeakeasies updated after buy: " .. json.encode(ownedSpeakeasies))
    else
        TriggerClientEvent('vorp:TipRight', src, "Not enough cash! You need $" .. price, 5000)
    end
end)

RegisterServerEvent('speakeasy:requestSellSpeakeasy')
AddEventHandler('speakeasy:requestSellSpeakeasy', function()
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    if not ownedSpeakeasies[identifier] then
        TriggerClientEvent('vorp:TipRight', src, "You don’t own a speakeasy!", 5000)
        return
    end

    local speakeasyName = ownedSpeakeasies[identifier].name
    local sellPrice = math.floor(50 * 0.75)
    TriggerClientEvent('speakeasy:confirmSellSpeakeasy', src, speakeasyName, sellPrice)
end)

RegisterServerEvent('speakeasy:sellSpeakeasy')
AddEventHandler('speakeasy:sellSpeakeasy', function(speakeasyName)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    if not ownedSpeakeasies[identifier] or ownedSpeakeasies[identifier].name ~= speakeasyName then
        TriggerClientEvent('vorp:TipRight', src, "You do not own this speakeasy!", 5000)
        return
    end

    local sellPrice = math.floor(50 * 0.75)
    character.addCurrency(0, sellPrice)
    oxmysql:executeSync("DELETE FROM speakeasies WHERE identifier = @identifier", {['@identifier'] = identifier})
    ownedSpeakeasies[identifier] = nil
    playerJugs[identifier][speakeasyName] = nil
    playerBrews[identifier][speakeasyName] = nil
    TriggerClientEvent('speakeasy:updateOwnedSpeakeasies', -1, ownedSpeakeasies)
    TriggerClientEvent('vorp:TipRight', src, "You sold " .. speakeasyName .. " for $" .. sellPrice, 5000)
    print("ownedSpeakeasies updated after sell: " .. json.encode(ownedSpeakeasies))
end)

RegisterServerEvent('speakeasy:requestSellMoonshine')
AddEventHandler('speakeasy:requestSellMoonshine', function()
    local src = source
    local moonshineCount = VORPInv.getItemCount(src, "moonshine") or 0
    print("Player " .. src .. " has " .. moonshineCount .. " moonshine in inventory")
    if moonshineCount < 1 then
        TriggerClientEvent('vorp:TipRight', src, "No moonshine to sell!", 5000)
        return
    end
    local sellPrice = moonshineCount * 10
    VORPInv.subItem(src, "moonshine", moonshineCount)
    local user = VORPcore.getUser(src)
    if user then
        local character = user.getUsedCharacter
        character.addCurrency(0, sellPrice)
    end
    TriggerClientEvent('vorp:TipRight', src, "You sold " .. moonshineCount .. " moonshine for $" .. sellPrice .. "!", 5000)
end)

RegisterServerEvent('speakeasy:sellMoonshine')
AddEventHandler('speakeasy:sellMoonshine', function()
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter

    local moonshineCount = VORPInv.getItemCount({source = src, item = "moonshine"})
    if moonshineCount <= 0 then
        TriggerClientEvent('vorp:TipRight', src, "You have no moonshine to sell!", 5000)
        return
    end

    local sellPrice = moonshineCount * 10
    VORPInv.subItem(src, "moonshine", moonshineCount)
    character.addCurrency(0, sellPrice)

    TriggerClientEvent('vorp:TipRight', src, "You sold " .. moonshineCount .. " moonshine for $" .. sellPrice .. "!", 5000)
end)

RegisterServerEvent('speakeasy:assignInstance')
AddEventHandler('speakeasy:assignInstance', function(speakeasyType)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    -- Create a unique bucket ID per player-speakeasy combo
    local bucketId = GetHashKey("speakeasy_" .. speakeasyType .. "_" .. identifier) % 65535
    SetPlayerRoutingBucket(src, bucketId)

    -- Send teleport instruction to client
    TriggerClientEvent('speakeasy:teleportToInterior', src, {
        speakeasyType = speakeasyType,
        bucketId = bucketId
    })
end)

RegisterServerEvent('speakeasy:resetInstance')
AddEventHandler('speakeasy:resetInstance', function()
    local src = source
    SetPlayerRoutingBucket(src, 0)
end)

RegisterServerEvent('speakeasy:openStash')
AddEventHandler('speakeasy:openStash', function(speakeasyType)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    if not ownedSpeakeasies[identifier] or ownedSpeakeasies[identifier].name ~= speakeasyType then
        TriggerClientEvent('vorp:TipRight', src, "You do not own this speakeasy!", 5000)
        return
    end

    VORPInv.OpenInv(src, "speakeasy_stash_" .. speakeasyType)
end)

RegisterServerEvent('speakeasy:brewSuccess')
AddEventHandler('speakeasy:brewSuccess', function(speakeasyType, rewardAmount)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier
    if not ownedSpeakeasies[identifier] or ownedSpeakeasies[identifier].name ~= speakeasyType then
        TriggerClientEvent('vorp:TipRight', src, "You do not own this speakeasy!", 5000)
        return
    end
    playerJugs[identifier] = playerJugs[identifier] or {}
    playerJugs[identifier][speakeasyType] = playerJugs[identifier][speakeasyType] or {jugs = 0}
    playerJugs[identifier][speakeasyType].jugs = playerJugs[identifier][speakeasyType].jugs + rewardAmount
    playerBrews[identifier][speakeasyType] = playerBrews[identifier][speakeasyType] or {count = 0}
    playerBrews[identifier][speakeasyType].count = playerBrews[identifier][speakeasyType].count + 1

    local canCarry = VORPInv.canCarryItem(src, "moonshine", rewardAmount)
    if canCarry then
        VORPInv.addItem(src, "moonshine", rewardAmount)
        TriggerClientEvent('vorp:TipRight', src, "Added " .. rewardAmount .. " moonshine to inventory!", 5000)
        print("Brew success for " .. identifier .. " at " .. speakeasyType .. ": added " .. rewardAmount .. " moonshine")
    else
        -- Inventory full: drop moonshine on ground near player
        TriggerClientEvent('vorp:TipRight', src, "Inventory full! Moonshine dropped on the ground.", 5000)
        print("Brew success but inventory full for " .. identifier .. " at " .. speakeasyType .. ". Dropping moonshine.")
        -- Drop moonshine item at player's location
        TriggerClientEvent('speakeasy:dropMoonshine', src, rewardAmount)
    end

    -- After success, check for delivery prompt
    local brewCount = playerBrews[identifier][speakeasyType].count
    local totalJugs = playerJugs[identifier][speakeasyType].jugs
    if brewCount >= 1 then
        TriggerClientEvent('speakeasy:openDeliveryPrompt', src, speakeasyType, totalJugs, brewCount)
    end
end)

RegisterServerEvent('speakeasy:completeBrewing')
AddEventHandler('speakeasy:completeBrewing', function(speakeasyType, rewardAmount)
    TriggerEvent('speakeasy:brewSuccess', speakeasyType, rewardAmount)
end)

RegisterServerEvent('speakeasy:brewFailed')
AddEventHandler('speakeasy:brewFailed', function(speakeasyType)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    TriggerClientEvent('vorp:TipRight', src, "Brewing failed! Try again.", 5000)
    print(identifier .. " failed brewing at " .. speakeasyType)
end)

RegisterServerEvent('speakeasy:startBrewing')
AddEventHandler('speakeasy:startBrewing', function(speakeasyType)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    print("Brewing started for " .. speakeasyType .. " by " .. identifier)

    if not ownedSpeakeasies[identifier] or ownedSpeakeasies[identifier].name ~= speakeasyType then
        TriggerClientEvent('vorp:TipRight', src, "You do not own this speakeasy!", 5000)
        print("Brew rejected: " .. identifier .. " does not own " .. speakeasyType)
        return
    end

    local woodCount = VORPInv.getItemCount(src, "wood") or 0
    local cornCount = VORPInv.getItemCount(src, "corn") or 0
    print("Checking supplies for " .. identifier .. ": wood=" .. woodCount .. ", corn=" .. cornCount)
    if woodCount >= 1 and cornCount >= 1 then
        local woodSuccess = VORPInv.subItem(src, "wood", 1)
        local cornSuccess = VORPInv.subItem(src, "corn", 1)
        if not woodSuccess or not cornSuccess then
            TriggerClientEvent('vorp:TipRight', src, "Error: Failed to remove supplies!", 5000)
            print("Failed to remove supplies for " .. identifier .. ": woodSuccess=" .. tostring(woodSuccess) .. ", cornSuccess=" .. tostring(cornSuccess))
            return
        end
        playerBrews[identifier] = playerBrews[identifier] or {}
        playerBrews[identifier][speakeasyType] = playerBrews[identifier][speakeasyType] or {count = 0}
        local brewCount = playerBrews[identifier][speakeasyType].count or 0
        local jugs = playerJugs[identifier] and playerJugs[identifier][speakeasyType] and playerJugs[identifier][speakeasyType].jugs or 0
        print("Sending brewCount: " .. brewCount .. " to client for " .. speakeasyType)
        TriggerClientEvent('speakeasy:startBrewingMinigame', src, speakeasyType, jugs, brewCount)
    else
        TriggerClientEvent('vorp:TipRight', src, "You need 1 wood and 1 corn to brew moonshine!", 5000)
        print(identifier .. " lacks supplies: wood=" .. woodCount .. ", corn=" .. cornCount)
    end
end)
 

RegisterServerEvent('speakeasy:requestDelivery')
AddEventHandler('speakeasy:requestDelivery', function(speakeasyType, totalJugs)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    print("Delivery requested for " .. speakeasyType .. " by " .. identifier .. " with " .. totalJugs .. " jugs")

    if not ownedSpeakeasies[identifier] or ownedSpeakeasies[identifier].name ~= speakeasyType then
        TriggerClientEvent('vorp:TipRight', src, "You don't own this speakeasy!", 5000)
        print(identifier .. " does not own " .. speakeasyType)
        return
    end

    if not playerJugs[identifier] or not playerJugs[identifier][speakeasyType] or playerJugs[identifier][speakeasyType].jugs < 3 then
        TriggerClientEvent('vorp:TipRight', src, "Not enough jugs to deliver!", 5000)
        print(identifier .. " has insufficient jugs: " .. (playerJugs[identifier] and playerJugs[identifier][speakeasyType] and playerJugs[identifier][speakeasyType].jugs or 0))
        return
    end

    local moonshineCount = VORPInv.getItemCount(src, "moonshine")
    if moonshineCount < totalJugs then
        TriggerClientEvent('vorp:TipRight', src, "Not enough moonshine in inventory!", 5000)
        return
    end

    VORPInv.subItem(src, "moonshine", totalJugs)

    playerJugs[identifier][speakeasyType].jugs = 0
    playerBrews[identifier][speakeasyType].count = 0
    TriggerClientEvent('speakeasy:startDelivery', src, speakeasyType, totalJugs)
    print("Started delivery for " .. identifier .. " at " .. speakeasyType)
end)

RegisterServerEvent('speakeasy:completeDelivery')
AddEventHandler('speakeasy:completeDelivery', function(speakeasyType, totalJugs)
    local src = source
    local user = VORPcore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    local identifier = character.identifier

    print("Delivery completed for " .. speakeasyType .. " by " .. identifier .. " with " .. totalJugs .. " jugs")
    
    TriggerClientEvent('speakeasy:cleanupDelivery', src)

    if not ownedSpeakeasies[identifier] or ownedSpeakeasies[identifier].name ~= speakeasyType then
        TriggerClientEvent('vorp:TipRight', src, "You don't own this speakeasy!", 5000)
        print(identifier .. " does not own " .. speakeasyType)
        return
    end

    local sellPrice = math.floor(totalJugs * 10 * 1.5)
    local success, error = pcall(function()
        VORPInv.addItem(src, "moonshine", 2)
    end)
    if not success then
        print("Failed to add moonshine for player " .. src .. ": " .. tostring(error))
        TriggerClientEvent('vorp:TipRight', src, "Error: Failed to add moonshine bottles!", 5000)
        return
    end
    character.addCurrency(0, sellPrice)
    TriggerClientEvent('vorp_inventory:reloadPlayerInventory', src)
    TriggerClientEvent('vorp:TipRight', src, "Delivery completed! You earned $" .. sellPrice .. " and 2 moonshine bottles!", 5000)
    print("Completed delivery for " .. identifier .. ": $" .. sellPrice .. " and 2 moonshine bottles")
end)

RegisterServerEvent('speakeasy:collectSupply')
AddEventHandler('speakeasy:collectSupply', function(item, amount)
    local src = source
    local canCarry = VORPInv.canCarryItem(src, item, amount)
    if canCarry then
        VORPInv.addItem(src, item, amount)
        TriggerClientEvent('vorp:TipRight', src, "Collected " .. amount .. " " .. item .. "!", 3000)
        print("Player " .. src .. " collected " .. amount .. " " .. item)
    else
        TriggerClientEvent('vorp:TipRight', src, "Cannot carry more " .. item .. "!", 3000)
        print("Player " .. src .. " cannot carry " .. amount .. " " .. item)
    end
end)