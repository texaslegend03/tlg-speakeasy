-- client.lua
local VORPcore = exports['vorp_core']
local MenuData = exports.vorp_menu:GetMenuData()
local ownedSpeakeasies = {}
local blips = {}
local supplyBlips = {}
local isGathering = false
local lastSpawnTime = 0
local isDelivering = false
local deliveryWagon = nil
local deliveryBlip = nil
local deliveryJugs = 0
local deliverySpeakeasy = nil
local cachedIdentifier = nil
local pinnedInteriors = {}
local hasTeleported = false

print("Starting tlg-speakeasy client.lua")

-- Request interior map shells
RequestImap(GetHashKey("MP006_A3SUPP_MOONSHINE01"))
RequestImap(GetHashKey("MP006_A3SUPP_MOONSHINE01_PLUG"))
RequestImap(GetHashKey("MP006_A2SUPP_MOONSHINE02"))
RequestImap(GetHashKey("MP006_A2SUPP_MOONSHINE02_PLUG"))
RequestImap(GetHashKey("MP006_A4SUPP_MOONSHINE03"))
RequestImap(GetHashKey("MP006_A4SUPP_MOONSHINE03_PLUG"))
RequestImap(GetHashKey("MP006_A1SUPP_MOONSHINE04"))
RequestImap(GetHashKey("MP006_A1SUPP_MOONSHINE04_PLUG"))
RequestImap(GetHashKey("MP006_A4SUPP_MOONSHINE05"))
RequestImap(GetHashKey("MP006_A4SUPP_MOONSHINE05_PLUG"))

-- Speakeasy IPL mappings
local speakeasyIPLMapping = {
    ["Valentine Speakeasy"] = "moonshine1_int",
    ["St. Denis Speakeasy"] = "moonshine2_int",
    ["Blackwater Speakeasy"] = "moonshine3_int",
    ["Tumbleweed Speakeasy"] = "moonshine4_int",
    ["Strawberry Speakeasy"] = "moonshine5_int"
}

-- Common entity sets for all speakeasies
local entitySetsCommon = {
    "mp006_mshine_band2",
    "mp006_mshine_bar_benchAndFrame",
    "mp006_mshine_hidden_door_open",
    "mp006_mshine_shelfwall1",
    "mp006_mshine_shelfwall2",
    "mp006_mshine_still_hatch"
}

-- Specific entity sets for each speakeasy
local entitySetsSpecific = {
    ["Valentine Speakeasy"] = {
        "mp006_mshine_dressing_1",
        "mp006_mshine_location1",
        "mp006_mshine_pic_09",
        "mp006_mshine_Still_2",
        "mp006_mshine_theme_floral"
    },
    ["St. Denis Speakeasy"] = {
        "mp006_mshine_dressing_3",
        "mp006_mshine_location2",
        "mp006_mshine_pic_04",
        "mp006_mshine_Still_3",
        "mp006_mshine_theme_hunter"
    },
    ["Blackwater Speakeasy"] = {
        "mp006_mshine_dressing_1",
        "mp006_mshine_location1",
        "mp006_mshine_pic_09",
        "mp006_mshine_Still_3",
        "mp006_mshine_theme_hunter"
    },
    ["Tumbleweed Speakeasy"] = {
        "mp006_mshine_dressing_1",
        "mp006_mshine_location1",
        "mp006_mshine_pic_09",
        "mp006_mshine_Still_2",
        "mp006_mshine_theme_refined"
    },
    ["Strawberry Speakeasy"] = {
        "mp006_mshine_dressing_1",
        "mp006_mshine_location1",
        "mp006_mshine_pic_09",
        "mp006_mshine_Still_2",
        "mp006_mshine_theme_goth"
    }
}

-- Speakeasy data with coordinates and supply pickups
local speakeasyData = {
    ["Valentine Speakeasy"] = {
        entrance = vector4(-294.8379, 773.6043, 122.4680, 106.5352),
        interior = vector4(1628.55, 825.97, 124.99, 70.0),
        still = vector4(1635.2037, 828.8015, 121.7142, 249.0636),
        stash = vector4(1628.8544, 832.3642, 121.7443, 342.9294),
        gatherPrompt = vector3(1628.8071, 831.1607, 124.9388),
        supplyPickups = {
            {coords = vector3(770.7023, 885.8149, 120.9266), item = "wood", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("p_ambwoodpile01x"), blip = nil},
            {coords = vector3(768.0393, 879.1390, 120.9346), item = "corn", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("mp001_s_moonshinesack01x"), blip = nil}
        }
    },
    ["St. Denis Speakeasy"] = {
        entrance = vector4(2801.1492, -1167.8979, 47.9280, 328.5178),
        interior = vector4(1787.25, -819.09, 192.65, 230.0),
        still = vector4(1794.3488, -818.9418, 189.3715, 221.9173),
        stash = vector4(1790.6483, -813.2516, 189.3715, 305.2269),
        gatherPrompt = vector3(1789.5686, -813.7832, 192.5660),
        supplyPickups = {
            {coords = vector3(2073.6675, -842.2899, 42.5814), item = "wood", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("p_ambwoodpile01x"), blip = nil},
            {coords = vector3(2047.6730, -822.4078, 42.9968), item = "corn", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("mp001_s_moonshinesack01x"), blip = nil}
        }
    },
    ["Blackwater Speakeasy"] = {
        entrance = vector4(-808.4632, -1362.8220, 43.7176, 266.0617),
        interior = vector4(-1863.2271, -1725.2749, 89.3035, 164.0711),
        still = vector4(-1870.0344, -1727.5067, 86.0275, 66.3558),
        stash = vector4(-1864.6903, -1731.8602, 86.0275, 165.8448),
        gatherPrompt = vector3(-1863.9672, -1730.8575, 89.2220),
        supplyPickups = {
            {coords = vector3(-1637.9012, -1381.4896, 83.8069), item = "wood", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("p_ambwoodpile01x"), blip = nil},
            {coords = vector3(-1611.1866, -1421.0529, 81.8538), item = "corn", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("mp001_s_moonshinesack01x"), blip = nil}
        }
    },
    ["Tumbleweed Speakeasy"] = {
        entrance = vector4(-5517.1445, -2962.4446, -0.8052, 5.8392),
        interior = vector4(-2772.3164, -3047.5073, -8.6522, 76.1827),
        still = vector4(-2774.8235, -3040.8032, -11.9282, 346.4167),
        stash = vector4(-2778.8408, -3046.0442, -11.9282, 57.1431),
        gatherPrompt = vector3(-2778.0986, -3046.9338, -8.7336),
        supplyPickups = {
            {coords = vector3(-3544.2634, -3012.7749, 11.6253), item = "wood", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("p_ambwoodpile01x"), blip = nil},
            {coords = vector3(-3550.3474, -3046.6311, 11.9325), item = "corn", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("mp001_s_moonshinesack01x"), blip = nil}
        }
    },
    ["Strawberry Speakeasy"] = {
        entrance = vector4(-1782.4546, -387.2557, 159.2520, 323.5451),
        interior = vector4(-1088.2479, 712.7059, 84.2823, 126.7639),
        still = vector4(-1095.1429, 715.0342, 81.0064, 38.7463),
        stash = vector4(-1093.0219, 708.0108, 81.0063, 117.9610),
        gatherPrompt = vector3(-1092.4403, 708.5665, 84.2008),
        supplyPickups = {
            {coords = vector3(-1293.2087, 391.8129, 95.1040), item = "wood", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("p_ambwoodpile01x"), blip = nil},
            {coords = vector3(-1290.4161, 410.3042, 94.9497), item = "corn", amount = 5, guard = nil, prop = nil, propHash = GetHashKey("mp001_s_moonshinesack01x"), blip = nil}
        }
    }
}

-- Delivery drop-off points
local dropOffPoints = {
    {name = "Rhodes Saloon", coords = vector3(1320.28, -1355.71, 78.28)},
    {name = "Emerald Ranch", coords = vector3(1410.09, 259.01, 89.93)},
    {name = "Blackwater", coords = vector3(-833.75, -1406.95, 43.37)},
    {name = "Heartland Camp", coords = vector3(-116.42, -26.64, 95.85)},
    {name = "Limpany Ruins", coords = vector3(-383.31, -99.23, 44.47)}
}

-- Request IMAPs for moonshine interiors
Citizen.CreateThread(function()
    local imaps = {
        0xCB28C7F6,
        0x0FE8850C,
        0x8BE643CA
    }
    for _, imap in pairs(imaps) do
        if not IsImapActive(imap) then
            RequestImap(imap)
        end
    end
end)

-- Thread to handle interior entity set activation/deactivation based on proximity
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for name, data in pairs(speakeasyData) do
            local dist = #(playerCoords - vector3(data.interior.x, data.interior.y, data.interior.z))
            local interiorId = GetInteriorAtCoords(data.interior.x, data.interior.y, data.interior.z)

            if IsValidInterior(interiorId) then
                if dist < 100.0 then
                    -- Pin interior and activate entity sets
                    if not pinnedInteriors[interiorId] then
                        Citizen.InvokeNative(0x4E4F6F226F4BC6F7, interiorId) -- PinInteriorInMemory
                        pinnedInteriors[interiorId] = true
                        print("Pinned interior for " .. name .. ": ID=" .. interiorId)
                    end

                    -- Build a fresh list of sets
                    local entitySets = {}
                    for _, set in ipairs(entitySetsCommon) do
                        table.insert(entitySets, set)
                    end
                    for _, set in ipairs(entitySetsSpecific[name] or {}) do
                        table.insert(entitySets, set)
                    end

                    -- Activate entity sets
                    for _, setName in ipairs(entitySets) do
                        if not IsInteriorEntitySetActive(interiorId, setName) then
                            ActivateInteriorEntitySet(interiorId, setName)
                        end
                    end
                else
                    -- Unpin interior and deactivate entity sets
                    if pinnedInteriors[interiorId] then
                        Citizen.InvokeNative(0x9A0E3B7A25F3F8AE, interiorId) -- UnpinInterior
                        pinnedInteriors[interiorId] = nil
                        print("Unpinned interior for " .. name .. ": ID=" .. interiorId)
                    end

                    -- Build list of all sets to deactivate
                    local allSets = {}
                    for _, set in ipairs(entitySetsCommon) do
                        table.insert(allSets, set)
                    end
                    for _, specific in pairs(entitySetsSpecific) do
                        for _, set in ipairs(specific) do
                            table.insert(allSets, set)
                        end
                    end

                    -- Deactivate all sets
                    for _, set in pairs(allSets) do
                        if IsInteriorEntitySetActive(interiorId, set) then
                            DeactivateInteriorEntitySet(interiorId, set)
                        end
                    end
                end
            else
                print("Invalid interior ID for " .. name .. ": " .. interiorId)
            end
        end
    end
end)

-- Blip for Moonshine Store
Citizen.CreateThread(function()
    local storeCoords = vector3(1448.81, 369.25, 89.89)
    local storeBlip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, storeCoords.x, storeCoords.y, storeCoords.z)
    SetBlipSprite(storeBlip, -392465725, 1)
    Citizen.InvokeNative(0x9CB1A1623062F402, storeBlip, 'Moonshine Store')
    Citizen.InvokeNative(0x662D364ABF16DE2F, storeBlip, GetHashKey("BLIP_MODIFIER_MP_COLOR_32"))
    Citizen.InvokeNative(0x8DE82BC774F3B862, storeBlip, 153) -- Saloon icon
    blips["moonshine_store"] = storeBlip

    -- Blips for speakeasies
    for name, data in pairs(speakeasyData) do
        blips[name] = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, data.entrance.x, data.entrance.y, data.entrance.z)
        SetBlipSprite(blips[name], -392465725, 1)
        Citizen.InvokeNative(0x9CB1A1623062F402, blips[name], 'Speakeasy')
    end
end)

-- Cleanup blips on resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, blip in pairs(blips) do
            RemoveBlip(blip)
        end
    end
end)

-- Main prompt handling thread
Citizen.CreateThread(function()
    -- Register prompts
    local enterPrompt = PromptRegisterBegin()
    PromptSetControlAction(enterPrompt, 0xE8342FF2) -- Alt key
    PromptSetText(enterPrompt, CreateVarString(10, "LITERAL_STRING", "Enter Speakeasy"))
    PromptSetEnabled(enterPrompt, false)
    PromptSetVisible(enterPrompt, false)
    PromptSetHoldMode(enterPrompt, true)
    PromptRegisterEnd(enterPrompt)

    local exitPrompt = PromptRegisterBegin()
    PromptSetControlAction(exitPrompt, 0xC7B5340A) -- 1 key
    PromptSetText(exitPrompt, CreateVarString(10, "LITERAL_STRING", "Exit Speakeasy"))
    PromptSetEnabled(exitPrompt, false)
    PromptSetVisible(exitPrompt, false)
    PromptSetHoldMode(exitPrompt, true)
    PromptRegisterEnd(exitPrompt)

    local stillPrompt = PromptRegisterBegin()
    PromptSetControlAction(stillPrompt, 0xE8342FF2) -- Alt key
    PromptSetText(stillPrompt, CreateVarString(10, "LITERAL_STRING", "Brew Moonshine"))
    PromptSetEnabled(stillPrompt, false)
    PromptSetVisible(stillPrompt, false)
    PromptSetStandardMode(stillPrompt, true)
    PromptRegisterEnd(stillPrompt)

    local stashPrompt = PromptRegisterBegin()
    PromptSetControlAction(stashPrompt, 0xE8342FF2) -- Alt key
    PromptSetText(stashPrompt, CreateVarString(10, "LITERAL_STRING", "Access Stash"))
    PromptSetEnabled(stashPrompt, false)
    PromptSetVisible(stashPrompt, false)
    PromptSetStandardMode(stashPrompt, true)
    PromptRegisterEnd(stashPrompt)

    local gatherPrompt = PromptRegisterBegin()
    PromptSetControlAction(gatherPrompt, 0xCEFD9220) -- E key
    PromptSetText(gatherPrompt, CreateVarString(10, "LITERAL_STRING", "Start Gathering"))
    PromptSetEnabled(gatherPrompt, false)
    PromptSetVisible(gatherPrompt, false)
    PromptSetStandardMode(gatherPrompt, true)
    PromptRegisterEnd(gatherPrompt)

    local isBrewing = false
    local stashCooldown = 0
    local gatherCooldown = 0

    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for name, data in pairs(speakeasyData) do
            local isOwner = cachedIdentifier and ownedSpeakeasies[cachedIdentifier] and ownedSpeakeasies[cachedIdentifier].name == name
            if isOwner then
                -- Entrance prompt
                local entranceDist = #(playerCoords - vector3(data.entrance.x, data.entrance.y, data.entrance.z))
                if entranceDist < 2.5 then
                    PromptSetEnabled(enterPrompt, true)
                    PromptSetVisible(enterPrompt, true)
                    if PromptHasHoldModeCompleted(enterPrompt) and not hasTeleported then
                        hasTeleported = true
                        TriggerServerEvent('speakeasy:assignInstance', name)
                        Wait(1000)
                    end
                else
                    PromptSetEnabled(enterPrompt, false)
                    PromptSetVisible(enterPrompt, false)
                end

                -- Exit prompt
                if data.interior then
                    local exitDist = #(playerCoords - vector3(data.interior.x, data.interior.y, data.interior.z))
                    if exitDist < 2.5 then
                        PromptSetEnabled(exitPrompt, true)
                        PromptSetVisible(exitPrompt, true)
                        if PromptHasHoldModeCompleted(exitPrompt) then
                            DoScreenFadeOut(500)
                            Wait(500)
                            SetEntityCoords(PlayerPedId(), data.entrance.x, data.entrance.y, data.entrance.z)
                            Wait(500)
                            DoScreenFadeIn(500)
                            hasTeleported = false
                        end
                    else
                        PromptSetEnabled(exitPrompt, false)
                        PromptSetVisible(exitPrompt, false)
                    end
                end

                -- Brew prompt
                local stillDist = #(playerCoords - vector3(data.still.x, data.still.y, data.still.z))
                if stillDist < 1.5 then
                    PromptSetEnabled(stillPrompt, true)
                    PromptSetVisible(stillPrompt, true)
                    if PromptHasStandardModeCompleted(stillPrompt) and not isBrewing then
                        TriggerServerEvent('speakeasy:startBrewing', name)
                        isBrewing = true
                        Wait(1000)
                        isBrewing = false
                    end
                else
                    PromptSetEnabled(stillPrompt, false)
                    PromptSetVisible(stillPrompt, false)
                end

                -- Stash prompt
                local stashDist = #(playerCoords - vector3(data.stash.x, data.stash.y, data.stash.z))
                if stashDist < 1.5 and GetGameTimer() > stashCooldown then
                    PromptSetEnabled(stashPrompt, true)
                    PromptSetVisible(stashPrompt, true)
                    if PromptHasStandardModeCompleted(stashPrompt) then
                        TriggerServerEvent('speakeasy:openStash', name)
                        stashCooldown = GetGameTimer() + 1000
                    end
                else
                    PromptSetEnabled(stashPrompt, false)
                    PromptSetVisible(stashPrompt, false)
                end

                -- Gather prompt
                local gatherDist = #(playerCoords - data.gatherPrompt)
                if gatherDist < 1.5 and GetGameTimer() > gatherCooldown then
                    PromptSetEnabled(gatherPrompt, true)
                    PromptSetVisible(gatherPrompt, true)
                    if PromptHasStandardModeCompleted(gatherPrompt) and not isGathering then
                        TriggerEvent('speakeasy:triggerGather', name)
                        gatherCooldown = GetGameTimer() + 1000
                    end
                else
                    PromptSetEnabled(gatherPrompt, false)
                    PromptSetVisible(gatherPrompt, false)
                end
            end
        end
    end
end)

-- Teleport to speakeasy interior
RegisterNetEvent('speakeasy:teleportToInterior')
AddEventHandler('speakeasy:teleportToInterior', function(data)
    local speakeasyType = data.speakeasyType
    local spec = speakeasyData[speakeasyType]
    if not spec or not spec.interior then
        print("Teleport failed: No interior for " .. tostring(speakeasyType))
        TriggerEvent('vorp:TipRight', "Error: No interior for this speakeasy!", 3000)
        return
    end

    DoScreenFadeOut(500)
    Wait(500)
    local ped = PlayerPedId()
    local coords = spec.interior
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w)

    local id = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if IsValidInterior(id) then
        Citizen.InvokeNative(0x4E4F6F226F4BC6F7, id) -- PinInteriorInMemory
        local sets = {}
        for _, v in ipairs(entitySetsCommon) do
            table.insert(sets, v)
        end
        for _, v in ipairs(entitySetsSpecific[speakeasyType] or {}) do
            table.insert(sets, v)
        end
        for _, name in ipairs(sets) do
            if not IsInteriorEntitySetActive(id, name) then
                ActivateInteriorEntitySet(id, name)
            end
        end
    end

    DoScreenFadeIn(500)
    Wait(500)
    if data.bucketId then
      
    end

    print(("Teleported to interior for %s at %.2f, %.2f, %.2f"):format(speakeasyType, coords.x, coords.y, coords.z))
end)

-- Notification handler
RegisterNetEvent('vorp:TipRight')
AddEventHandler('vorp:TipRight', function(message, duration)
    print("Notification triggered: " .. message)
    Citizen.InvokeNative(0x9741B5470A3E3B4, message, duration or 5000) -- Display notification
end)

-- Custom CircleZone implementation
local CircleZone = {}

function CircleZone:new(center, radius, options)
    local zone = {
        center = center,
        radius = radius + 0.0,
        useZ = options.useZ or false,
        name = options.name or "unnamed_zone",
        _isPlayerInside = false,
        onPlayerInOut = nil
    }
    setmetatable(zone, self)
    self.__index = self
    return zone
end

function CircleZone:Create(center, radius, options)
    options = options or {}
    local zone = CircleZone:new(center, radius, options)
    Citizen.CreateThread(function()
        while true do
            Wait(500)
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local dist = zone.useZ and #(playerCoords - center) or #(vector2(playerCoords.x, playerCoords.y) - vector2(center.x, center.y))
                local isInside = dist < radius
                if isInside ~= zone._isPlayerInside then
                    zone._isPlayerInside = isInside
                    if zone.onPlayerInOut then
                        zone:onPlayerInOut(isInside)
                    end
                end
            end
        end
    end)
    return zone
end

function CircleZone:isPlayerInside()
    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then return false end
    local playerCoords = GetEntityCoords(playerPed)
    local dist = self.useZ and #(playerCoords - self.center) or #(vector2(playerCoords.x, playerCoords.y) - vector2(self.center.x, self.center.y))
    return dist < self.radius
end

-- Moonshine Store setup
Citizen.CreateThread(function()
    print("Setting up Moonshine Store NPC and blips")
    local pedModel = GetHashKey("u_m_o_valbartender_01")
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do Wait(100) end
    local ped = CreatePed(pedModel, 1448.81, 369.25, 89.89 - 1.0, 86.9942, false, true)
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_LEAN_BACK_WALL_SMOKING", 0, true)

    local speakeasies = {
        {name = "Valentine Speakeasy", price = 50, coords = speakeasyData["Valentine Speakeasy"].entrance},
        {name = "St. Denis Speakeasy", price = 50, coords = speakeasyData["St. Denis Speakeasy"].entrance},
        {name = "Blackwater Speakeasy", price = 50, coords = speakeasyData["Blackwater Speakeasy"].entrance},
        {name = "Tumbleweed Speakeasy", price = 50, coords = speakeasyData["Tumbleweed Speakeasy"].entrance},
        {name = "Strawberry Speakeasy", price = 50, coords = speakeasyData["Strawberry Speakeasy"].entrance}
    }

    local storePrompt = PromptRegisterBegin()
    PromptSetControlAction(storePrompt, 0x760A9C6F) -- G key
    PromptSetText(storePrompt, CreateVarString(10, "LITERAL_STRING", "Moonshine Store"))
    PromptSetEnabled(storePrompt, false)
    PromptSetVisible(storePrompt, false)
    PromptSetHoldMode(storePrompt, true)
    PromptRegisterEnd(storePrompt)

    print("Creating CircleZone for Moonshine Store")
    local storeZone = CircleZone:Create(vector3(1448.81, 369.25, 89.89), 50.0, {name = "moonshine_store", useZ = true})
    if not storeZone then
        print("Error: Failed to create CircleZone for Moonshine Store")
        TriggerEvent('vorp:TipRight', "Error: Moonshine Store zone creation failed", 5000)
        return
    end

    storeZone.onPlayerInOut = function(isInside)
        if isInside then
            print("Player entered Moonshine Store zone")
            Citizen.CreateThread(function()
                while storeZone:isPlayerInside() do
                    Wait(0)
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local dist = #(playerCoords - vector3(1448.81, 369.25, 89.89))
                    if dist < 2.0 then
                        PromptSetEnabled(storePrompt, true)
                        PromptSetVisible(storePrompt, true)
                        if PromptHasHoldModeCompleted(storePrompt) then
                            print("Store prompt triggered")
                            TriggerServerEvent('speakeasy:requestSync')
                            if cachedIdentifier then
                                print("Using cached identifier: " .. cachedIdentifier)
                                TriggerEvent('speakeasy:callback:store_menu', cachedIdentifier)
                            else
                                print("No cached identifier, fetching new one")
                                TriggerServerEvent('speakeasy:getIdentifier', "store_menu")
                            end
                            Wait(1000)
                        end
                    else
                        PromptSetEnabled(storePrompt, false)
                        PromptSetVisible(storePrompt, false)
                    end
                end
            end)
        else
            print("Player exited Moonshine Store zone")
            PromptSetEnabled(storePrompt, false)
            PromptSetVisible(storePrompt, false)
        end
    end

    print("Moonshine Store setup complete")
end)

-- Handle supply gathering
RegisterNetEvent('speakeasy:triggerGather')
AddEventHandler('speakeasy:triggerGather', function(speakeasyName)
    print("speakeasy:triggerGather called with speakeasyName: " .. tostring(speakeasyName))
    if isGathering then
        TriggerEvent('vorp:TipRight', "Error: Already gathering supplies!", 3000)
        print("Gather blocked: Already gathering")
        return
    end
    local currentTime = GetGameTimer()
    if currentTime - lastSpawnTime < 5000 then
        TriggerEvent('vorp:TipRight', "Error: Cooldown active, wait a moment!", 3000)
        print("Gather blocked: Cooldown active")
        return
    end

    isGathering = true
    lastSpawnTime = currentTime
    print("Checking speakeasyData for " .. tostring(speakeasyName))
    local speakeasy = speakeasyData[speakeasyName]
    if not speakeasy then
        TriggerEvent('vorp:TipRight', "Error: Invalid speakeasy!", 3000)
        print("Gather failed: Invalid speakeasy " .. tostring(speakeasyName))
        print("Available speakeasyData keys: " .. json.encode(table.concat(getTableKeys(speakeasyData), ", ")))
        isGathering = false
        return
    end
    if not speakeasy.supplyPickups or #speakeasy.supplyPickups == 0 then
        TriggerEvent('vorp:TipRight', "Error: No supply pickups defined for " .. speakeasyName, 3000)
        print("Gather failed: No supply pickups for " .. speakeasyName)
        isGathering = false
        return
    end

    print("Spawning supplies for " .. speakeasyName)
    for i, pickup in ipairs(speakeasy.supplyPickups) do
        print("Processing pickup " .. i .. ": item=" .. pickup.item .. ", coords=" .. tostring(pickup.coords))
        RequestModel(pickup.propHash)
        local modelTimeout = GetGameTimer() + 10000
        while not HasModelLoaded(pickup.propHash) and GetGameTimer() < modelTimeout do
            Wait(100)
        end
        if not HasModelLoaded(pickup.propHash) then
            print("Failed to load model: " .. pickup.propHash .. ", using fallback")
            pickup.propHash = GetHashKey("p_crate02x")
            RequestModel(pickup.propHash)
            modelTimeout = GetGameTimer() + 5000
            while not HasModelLoaded(pickup.propHash) and GetGameTimer() < modelTimeout do
                Wait(100)
            end
            if not HasModelLoaded(pickup.propHash) then
                print("Failed to load fallback model: " .. pickup.propHash)
                TriggerEvent('vorp:TipRight', "Error: Failed to load supply model!", 3000)
                isGathering = false
                return
            end
        end
        local foundGround, groundZ = false, pickup.coords.z
        local tryZ = pickup.coords.z + 200.0
        for i = 1, 100 do
            foundGround, groundZ = GetGroundZFor_3dCoord(pickup.coords.x, pickup.coords.y, tryZ, false)
            if foundGround then break end
            tryZ = tryZ - 2.0
        end
        if not foundGround then
            local rayHandle = StartShapeTestRay(pickup.coords.x, pickup.coords.y, pickup.coords.z + 200.0, pickup.coords.x, pickup.coords.y, pickup.coords.z - 200.0, -1, PlayerPedId(), 0)
            local _, hit, _, _, groundZ = GetShapeTestResult(rayHandle)
            if hit then foundGround = true end
        end
        local spawnZ = foundGround and (groundZ < pickup.coords.z - 10.0 and pickup.coords.z or groundZ + 0.5) or pickup.coords.z + 0.5
        print("Spawning prop at " .. pickup.coords.x .. ", " .. pickup.coords.y .. ", " .. spawnZ .. " (foundGround=" .. tostring(foundGround) .. ", groundZ=" .. tostring(groundZ) .. ")")
        pickup.prop = CreateObject(pickup.propHash, pickup.coords.x, pickup.coords.y, spawnZ - 1.0, true, true, false)
        if not DoesEntityExist(pickup.prop) then
            print("Failed to spawn prop: " .. pickup.propHash .. " at " .. pickup.coords.x .. ", " .. pickup.coords.y .. ", " .. spawnZ)
            TriggerEvent('vorp:TipRight', "Error: Failed to spawn supply!", 3000)
            isGathering = false
            return
        end
        SetEntityAsMissionEntity(pickup.prop, true, true)
        Citizen.InvokeNative(0x58A850EAEE20FAA3, pickup.prop, true) -- PlaceObjectOnGroundProperly
        Wait(500)
        FreezeEntityPosition(pickup.prop, true)
        print("Spawned prop: " .. pickup.propHash .. " at " .. pickup.coords.x .. ", " .. pickup.coords.y .. ", " .. spawnZ)

        pickup.blip = Citizen.InvokeNative(0x45F13B7E0A15C880, -1282792512, pickup.coords.x, pickup.coords.y, spawnZ, 10.0)
        Citizen.InvokeNative(0xD38744167B6FC735, pickup.blip, 10)
        Citizen.InvokeNative(0x2F8B4D1C595B11DB, pickup.blip, 128)
        Citizen.InvokeNative(0x662D364ABF16DE2F, pickup.blip, true)
        Citizen.InvokeNative(0x9CB1A1623062F402, pickup.blip, CreateVarString(10, "LITERAL_STRING", "Supply Area"))
        print("Created radius blip for " .. pickup.item .. " at " .. pickup.coords.x .. ", " .. pickup.coords.y .. ", " .. spawnZ .. " with radius 10.0")

        local guardModel = GetHashKey("G_M_M_UNIBANDITOS_01")
        RequestModel(guardModel)
        modelTimeout = GetGameTimer() + 5000
        while not HasModelLoaded(guardModel) and GetGameTimer() < modelTimeout do
            Wait(100)
        end
        if not HasModelLoaded(guardModel) then
            print("Failed to load guard model: " .. guardModel)
            TriggerEvent('vorp:TipRight', "Error: Failed to load guard model!", 3000)
        else
            local guardX, guardY = pickup.coords.x + 2.0, pickup.coords.y + 2.0
            local foundGuardGround, guardZ = false, spawnZ
            tryZ = spawnZ + 200.0
            for i = 1, 100 do
                foundGuardGround, guardZ = GetGroundZFor_3dCoord(guardX, guardY, tryZ, false)
                if foundGuardGround then break end
                tryZ = tryZ - 2.0
            end
            if not foundGuardGround then
                local rayHandle = StartShapeTestRay(guardX, guardY, spawnZ + 200.0, guardX, guardY, spawnZ - 200.0, -1, PlayerPedId(), 0)
                local _, hit, _, _, guardZ = GetShapeTestResult(rayHandle)
                if hit then foundGuardGround = true end
            end
            local guardSpawnZ = foundGuardGround and (guardZ < pickup.coords.z - 10.0 and pickup.coords.z or guardZ + 0.5) or spawnZ
            pickup.guard = CreatePed(guardModel, guardX, guardY, guardSpawnZ, 0.0, true, false)
            if DoesEntityExist(pickup.guard) then
                Citizen.InvokeNative(0x283978A15512B2FE, pickup.guard, true)
                SetEntityAsMissionEntity(pickup.guard, true, true)
                local enemyGroup = GetRandomIntInRange(1, 1000)
                Citizen.InvokeNative(0xC80A74F8D7F18B, enemyGroup, GetHashKey("ENEMY"))
                Citizen.InvokeNative(0x028F76B6E78246EB, pickup.guard, enemyGroup, -1)
                Citizen.InvokeNative(0xB8B6430EAD2D2437, enemyGroup, GetHashKey("ENEMY"))
                Citizen.InvokeNative(0x9D5A25BADB742ACD, GetHashKey("ENEMY"), GetHashKey("PLAYER"), -4)
                GiveWeaponToPed(pickup.guard, GetHashKey("WEAPON_REVOLVER_CATTLEMAN"), 50, false, true)
                SetCurrentPedWeapon(pickup.guard, GetHashKey("WEAPON_REVOLVER_CATTLEMAN"), true)
                TaskCombatPed(pickup.guard, PlayerPedId(), 0, 16)
                print("Spawned hostile guard at " .. guardX .. ", " .. guardY .. ", " .. guardSpawnZ .. " for " .. pickup.item)
            else
                print("Failed to spawn guard at " .. guardX .. ", " .. guardY .. ", " .. guardSpawnZ)
            end
            SetModelAsNoLongerNeeded(guardModel)
        end
    end

    TriggerEvent('vorp:TipRight', "Supplies spawned! Check the blips to collect them.", 5000)
    print("Notification 'Supplies spawned!' triggered for display")

    Citizen.CreateThread(function()
        local collectPrompt = PromptRegisterBegin()
        PromptSetControlAction(collectPrompt, 0xCEFD9220) -- E key
        PromptSetText(collectPrompt, CreateVarString(10, "LITERAL_STRING", "Collect Supply"))
        PromptSetEnabled(collectPrompt, false)
        PromptSetVisible(collectPrompt, false)
        PromptSetStandardMode(collectPrompt, true)
        PromptRegisterEnd(collectPrompt)

        local lastNotification = 0
        while isGathering do
            Wait(0)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local closestPickup = nil
            local closestDist = 1.5

            for _, pickup in pairs(speakeasy.supplyPickups) do
                if pickup.prop and DoesEntityExist(pickup.prop) then
                    local dist = #(playerCoords - vector3(pickup.coords.x, pickup.coords.y, pickup.coords.z))
                    if dist < closestDist then
                        closestDist = dist
                        closestPickup = pickup
                    end
                end
            end

            if closestPickup then
                local dist = #(playerCoords - vector3(closestPickup.coords.x, closestPickup.coords.y, closestPickup.coords.z))
                if dist < 1.5 then
                    PromptSetEnabled(collectPrompt, true)
                    PromptSetVisible(collectPrompt, true)
                    if PromptHasStandardModeCompleted(collectPrompt) then
                        print("Collecting " .. closestPickup.item .. " (amount: " .. closestPickup.amount .. ")")
                        TriggerServerEvent('speakeasy:collectSupply', closestPickup.item, closestPickup.amount)
                        DeleteObject(closestPickup.prop)
                        closestPickup.prop = nil
                        if closestPickup.blip then
                            RemoveBlip(closestPickup.blip)
                            closestPickup.blip = nil
                        end
                        if closestPickup.guard and DoesEntityExist(closestPickup.guard) then
                            DeletePed(closestPickup.guard)
                            closestPickup.guard = nil
                            print("Removed guard for " .. closestPickup.item)
                        end
                        print("Collected and removed prop/blip for " .. closestPickup.item)
                        local currentTime = GetGameTimer()
                        if currentTime - lastNotification > 5000 then
                            TriggerEvent('vorp:TipRight', "Collected " .. closestPickup.amount .. " " .. closestPickup.item .. "!", 3000)
                            lastNotification = currentTime
                        end
                    end
                else
                    PromptSetEnabled(collectPrompt, false)
                    PromptSetVisible(collectPrompt, false)
                end
            else
                PromptSetEnabled(collectPrompt, false)
                PromptSetVisible(collectPrompt, false)
            end

            local anyPropExists = false
            for _, pickup in pairs(speakeasy.supplyPickups) do
                if pickup.prop and DoesEntityExist(pickup.prop) then
                    anyPropExists = true
                    break
                end
            end
            if not anyPropExists then
                isGathering = false
                if GetGameTimer() - lastNotification > 5000 then
                    TriggerEvent('vorp:TipRight', "All supplies collected!", 3000)
                    lastNotification = GetGameTimer()
                end
                print("All supplies collected for " .. speakeasyName)
                break
            end
        end
        PromptDelete(collectPrompt)
        for _, pickup in pairs(speakeasy.supplyPickups) do
            if pickup.prop and DoesEntityExist(pickup.prop) then
                DeleteObject(pickup.prop)
                pickup.prop = nil
                print("Cleaned up prop: " .. pickup.propHash)
            end
            if pickup.blip then
                RemoveBlip(pickup.blip)
                pickup.blip = nil
                print("Cleaned up blip for " .. pickup.item)
            end
            if pickup.guard and DoesEntityExist(pickup.guard) then
                DeletePed(pickup.guard)
                pickup.guard = nil
                print("Cleaned up guard for " .. pickup.item)
            end
        end
        isGathering = false
    end)
end)

-- Drop moonshine items
RegisterNetEvent('speakeasy:dropMoonshine')
AddEventHandler('speakeasy:dropMoonshine', function(amount)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    TriggerServerEvent('vorp:dropItem', "moonshine", amount, coords.x, coords.y, coords.z)
end)

-- Helper function to get table keys
function getTableKeys(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

-- Moonshine brewing minigame
function StartMoonshineMinigame(speakeasyType)
    local temp = 150
    local progress = 0
    SendNUIMessage({action = "start", speakeasyName = speakeasyType})
    while progress < 100 do
        Wait(1000)
        temp = temp + math.random(-5, 5)
        if temp < 140 then temp = temp + 5 elseif temp > 160 then temp = temp - 5 end
        progress = progress + (math.abs(temp - 150) < 10 and 1 or 0)
        SendNUIMessage({action = "update", temperature = temp, progress = progress})
        if IsControlJustPressed(0, 0xD82E0BD2) then -- T key
            SendNUIMessage({action = "raise_temp"})
            temp = temp + 10
            SendNUIMessage({action = "update", temperature = temp, progress = progress})
        end
        Wait(500)
    end
    SendNUIMessage({action = "end", success = true})
    print("Minigame ended with success for " .. speakeasyType)
end

-- Moonshine store menu
RegisterNetEvent('speakeasy:callback:store_menu')
AddEventHandler('speakeasy:callback:store_menu', function(identifier)
    if not identifier then
        print("No identifier received for store menu")
        TriggerEvent('vorp:TipRight', "Error: Unable to fetch player data!", 3000)
        return
    end
    print("Opening store menu for identifier: " .. identifier)
    print("ownedSpeakeasies: " .. json.encode(ownedSpeakeasies))
    local speakeasies = {
        {name = "Valentine Speakeasy", price = 50},
        {name = "St. Denis Speakeasy", price = 50},
        {name = "Blackwater Speakeasy", price = 50},
        {name = "Tumbleweed Speakeasy", price = 50},
        {name = "Strawberry Speakeasy", price = 50}
    }
    local menuElements = {}
    for _, speakeasy in pairs(speakeasies) do
        local isOwnedByPlayer = ownedSpeakeasies[identifier] and ownedSpeakeasies[identifier].name == speakeasy.name
        table.insert(menuElements, {
            label = speakeasy.name .. " ($" .. speakeasy.price .. ")" .. (isOwnedByPlayer and " [Owned]" or ""),
            value = speakeasy.name,
            desc = isOwnedByPlayer and "You already own this speakeasy" or "Buy this speakeasy for $" .. speakeasy.price
        })
    end
    table.insert(menuElements, {
        label = "Sell Moonshine ($10/jug)",
        value = "sell_moonshine",
        desc = "Sell your moonshine jugs"
    })
    if ownedSpeakeasies[identifier] then
        print("Adding Sell Speakeasy option for " .. ownedSpeakeasies[identifier].name)
        table.insert(menuElements, {
            label = "Sell Your Speakeasy",
            value = "sell_speakeasy",
            desc = "Sell " .. ownedSpeakeasies[identifier].name .. " for 75% of original price"
        })
    else
        print("No owned speakeasy for identifier: " .. identifier)
    end
    MenuData.CloseAll()
    local menuOpened = MenuData.Open('default', GetCurrentResourceName(), 'moonshine_store_menu', {
        title = "Moonshine Store",
        subtext = "Buy a speakeasy, sell moonshine, or sell your speakeasy",
        align = "top-left",
        elements = menuElements
    }, function(data, menu)
        print("Menu selection: " .. data.current.value)
        if data.current.value == "sell_moonshine" then
            TriggerServerEvent('speakeasy:requestSellMoonshine')
        elseif data.current.value == "sell_speakeasy" then
            TriggerServerEvent('speakeasy:requestSellSpeakeasy')
        else
            TriggerServerEvent('speakeasy:buySpeakeasy', data.current.value, 50)
        end
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
    if not menuOpened then
        print("Failed to open VORP menu")
        TriggerEvent('vorp:TipRight', "Error: Failed to open store menu!", 3000)
    end
end)

-- Update owned speakeasies
RegisterNetEvent('speakeasy:updateOwnedSpeakeasies')
AddEventHandler('speakeasy:updateOwnedSpeakeasies', function(data)
    ownedSpeakeasies = data
    print("Updated ownedSpeakeasies: " .. json.encode(ownedSpeakeasies))
end)

-- Initial sync callback
RegisterNetEvent('speakeasy:callback:initial_sync')
AddEventHandler('speakeasy:callback:initial_sync', function(identifier)
    cachedIdentifier = identifier
    print("Received identifier: " .. tostring(identifier))
end)

-- Confirm speakeasy sale
RegisterNetEvent('speakeasy:confirmSellSpeakeasy')
AddEventHandler('speakeasy:confirmSellSpeakeasy', function(speakeasyName, sellPrice)
    local menuElements = {
        {label = "Yes", value = "yes", desc = "Confirm selling " .. speakeasyName},
        {label = "No", value = "no", desc = "Cancel"}
    }
    MenuData.CloseAll()
    MenuData.Open('default', GetCurrentResourceName(), 'confirm_sell_speakeasy', {
        title = "Confirm Sale",
        subtext = "Sell " .. speakeasyName .. " for $" .. sellPrice .. "?",
        align = "top-left",
        elements = menuElements
    }, function(data, menu)
        if data.current.value == "yes" then
            TriggerServerEvent("speakeasy:sellSpeakeasy", speakeasyName)
        end
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end)

-- Confirm moonshine sale
RegisterNetEvent('speakeasy:confirmSellMoonshine')
AddEventHandler('speakeasy:confirmSellMoonshine', function(amount, sellPrice)
    local menuElements = {
        {label = "Yes", value = "yes", desc = "Confirm selling " .. amount .. " moonshine"},
        {label = "No", value = "no", desc = "Cancel"}
    }
    MenuData.CloseAll()
    MenuData.Open('default', GetCurrentResourceName(), 'confirm_sell_moonshine', {
        title = "Confirm Sale",
        subtext = "Sell " .. amount .. " moonshine for $" .. sellPrice .. "?",
        align = "top-left",
        elements = menuElements
    }, function(data, menu)
        if data.current.value == "yes" then
            TriggerServerEvent("speakeasy:sellMoonshine")
        end
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end)

-- Open delivery prompt
RegisterNetEvent('speakeasy:openDeliveryPrompt')
AddEventHandler('speakeasy:openDeliveryPrompt', function(speakeasyType, totalJugs, brewCount)
    print("OpenDeliveryPrompt called for " .. speakeasyType .. " with TotalJugs: " .. tostring(totalJugs) .. ", brewCount: " .. tostring(brewCount))
    TriggerEvent('speakeasy:closeMenus')
    if brewCount and brewCount >= 1 then
        print("Opening delivery prompt for " .. speakeasyType .. " with " .. brewCount .. " brews, TotalJugs: " .. tostring(totalJugs))
        local menuElements = {
            {label = "Yes", value = "yes", desc = "Start delivery after " .. brewCount .. " brews"},
            {label = "No", value = "no", desc = "Continue brewing"}
        }
        MenuData.CloseAll()
        MenuData.Open('default', GetCurrentResourceName(), 'delivery_prompt', {
            title = "Deliver Moonshine?",
            subtext = "You have brewed " .. brewCount .. " times. Deliver now?",
            align = "top-left",
            elements = menuElements
        }, function(data, menu)
            print("Delivery prompt selection: " .. data.current.value)
            if data.current.value == "yes" then
                TriggerServerEvent('speakeasy:requestDelivery', speakeasyType, totalJugs or 0)
            end
            menu.close()
        end, function(data, menu)
            menu.close()
        end)
    else
        print("Not opening delivery prompt: brewCount=" .. tostring(brewCount))
    end
end)

-- Start brewing minigame
RegisterNetEvent('speakeasy:startBrewingMinigame')
AddEventHandler('speakeasy:startBrewingMinigame', function(speakeasyType, totalJugs, brewCount)
    StartMoonshineMinigame(speakeasyType)
end)

-- Character selection handler
RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    Citizen.CreateThread(function()
        local tries = 0
        local maxTries = 10
        Wait(2000)

        while not cachedIdentifier and tries < maxTries do
            print("Requesting identifier (try " .. tries .. ")")
            TriggerServerEvent('speakeasy:getIdentifier', "initial_sync")
            tries = tries + 1
            Wait(2000)
        end

        if not cachedIdentifier then
            print("Failed to get identifier after retries!")
            TriggerEvent('vorp:TipRight', "Error: Could not load character data. Try reconnecting.", 10000)
            return
        end

        tries = 0
        while not next(ownedSpeakeasies) and tries < maxTries do
            print("Requesting owned speakeasies sync (try " .. tries .. ")")
            TriggerServerEvent('speakeasy:requestSync')
            tries = tries + 1
            Wait(2000)
        end

        if not next(ownedSpeakeasies) then
            print("Failed to sync owned speakeasies after retries!")
            TriggerEvent('vorp:TipRight', "Error: Could not sync speakeasy data. Try reconnecting.", 10000)
            return
        end

        print("Character selection sync complete. Identifier: " .. tostring(cachedIdentifier))
        print("Owned speakeasies: " .. json.encode(ownedSpeakeasies))
    end)
end)

-- Start delivery mission
RegisterNetEvent('speakeasy:startDelivery')
AddEventHandler('speakeasy:startDelivery', function(speakeasyType, totalJugs)
    if isDelivering then
        TriggerEvent('vorp:TipRight', "Error: Already delivering!", 3000)
        return
    end
    isDelivering = true
    deliveryJugs = totalJugs
    deliverySpeakeasy = speakeasyType

    local dropOff = dropOffPoints[math.random(1, #dropOffPoints)]
    local dropOffCoords = dropOff.coords

    deliveryBlip = Citizen.InvokeNative(0x45F13B7E0A15C880, -1282792512, dropOffCoords.x, dropOffCoords.y, dropOffCoords.z, 15.0)
    Citizen.InvokeNative(0xD38744167B6FC735, deliveryBlip, 1)
    Citizen.InvokeNative(0x2F8B4D1C595B11DB, deliveryBlip, 128)
    Citizen.InvokeNative(0x662D364ABF16DE2F, deliveryBlip, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, deliveryBlip, CreateVarString(10, "LITERAL_STRING", dropOff.name .. " Delivery Area"))

    TriggerEvent('vorp:TipRight', "Head to your wagon near the speakeasy entrance to start the delivery.", 5000)
    deliveryPrompt = PromptRegisterBegin()
    PromptSetControlAction(deliveryPrompt, 0xCEFD9220) -- E key
    PromptSetText(deliveryPrompt, CreateVarString(10, "LITERAL_STRING", "Complete Delivery"))
    PromptSetEnabled(deliveryPrompt, false)
    PromptSetVisible(deliveryPrompt, false)
    PromptSetStandardMode(deliveryPrompt, true)
    PromptRegisterEnd(deliveryPrompt)

    local playerPed = PlayerPedId()
    local wagonSpawned = false
    local hasEnteredWagon = false
    local encounterTriggered = false
    local suspicionLevel = 0
    local enemies = {}
    local deliveryPed = nil

    Citizen.CreateThread(function()
        while isDelivering do
            Wait(0)
            local playerCoords = GetEntityCoords(playerPed)
            local entranceCoords = vector3(speakeasyData[speakeasyType].entrance.x, speakeasyData[speakeasyType].entrance.y, speakeasyData[speakeasyType].entrance.z)
            local distToEntrance = #(playerCoords - entranceCoords)
            local wagonCoords = deliveryWagon and GetEntityCoords(deliveryWagon) or vector3(0, 0, 0)
            local distToDropOff = #(wagonCoords - dropOffCoords)

            if not wagonSpawned and distToEntrance < 50.0 then
                local wagonModel = GetHashKey("WAGON05X")
                RequestModel(wagonModel)
                while not HasModelLoaded(wagonModel) do Wait(100) end
                local spawnX, spawnY, spawnZ, spawnH
                if speakeasyType == "Valentine Speakeasy" then
                    spawnX, spawnY, spawnZ, spawnH = -300.0, 745.0, 117.0, 105.0
                elseif speakeasyType == "Blackwater Speakeasy" then
                    spawnX, spawnY, spawnZ, spawnH = -787.7158, -1388.6222, 43.3352, 95.9864
                elseif speakeasyType == "St. Denis Speakeasy" then
                    spawnX, spawnY, spawnZ, spawnH = 2823.2131, -1156.7513, 46.6891, 14.0161
                elseif speakeasyType == "Strawberry Speakeasy" then
                    spawnX, spawnY, spawnZ, spawnH = -1751.4659, -404.8795, 155.4885, 242.4969
                elseif speakeasyType == "Tumbleweed Speakeasy" then
                    spawnX, spawnY, spawnZ, spawnH = -5524.6650, -2967.6980, -1.6659, 104.0665
                else
                    spawnX = entranceCoords.x + 10.0
                    spawnY = entranceCoords.y + 10.0
                    spawnZ = entranceCoords.z + 1.0
                    spawnH = speakeasyData[speakeasyType].entrance.w
                end
                local foundGround, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 20.0, false)
                if foundGround then spawnZ = groundZ end
                deliveryWagon = CreateVehicle(wagonModel, spawnX, spawnY, spawnZ, spawnH, true, false)
                SetEntityAsMissionEntity(deliveryWagon, true, true)
                wagonSpawned = true
                TriggerEvent('vorp:TipRight', "Your wagon is ready! Get in and head to " .. dropOff.name .. ".", 5000)
                Wait(2000)
            end

            if wagonSpawned and not hasEnteredWagon then
                if GetVehiclePedIsIn(playerPed, false) == deliveryWagon then
                    hasEnteredWagon = true
                    TriggerEvent('vorp:TipRight', "Delivery started! Protect your wagon.", 5000)
                end
            end

            if wagonSpawned and hasEnteredWagon then
                local distToWagon = #(playerCoords - wagonCoords)
                if distToDropOff < 10.0 then
                    PromptSetEnabled(deliveryPrompt, true)
                    PromptSetVisible(deliveryPrompt, true)
                    if PromptHasStandardModeCompleted(deliveryPrompt) then
                        TriggerServerEvent('speakeasy:completeDelivery', speakeasyType, totalJugs)
                        if deliveryPed and DoesEntityExist(deliveryPed) then
                            DeletePed(deliveryPed)
                            deliveryPed = nil
                        end
                        CleanupDelivery()
                        return
                    end
                else
                    PromptSetEnabled(deliveryPrompt, false)
                    PromptSetVisible(deliveryPrompt, false)
                end

                if distToDropOff < 50.0 and deliveryPed == nil then
                    local pedModel = GetHashKey("cs_mp_moonshiner")
                    RequestModel(pedModel)
                    while not HasModelLoaded(pedModel) do Wait(100) end
                    local foundGround, groundZ = GetGroundZFor_3dCoord(dropOffCoords.x, dropOffCoords.y, dropOffCoords.z + 10.0, false)
                    local pedZ = foundGround and groundZ + 0.5 or dropOffCoords.z
                    deliveryPed = CreatePed(pedModel, dropOffCoords.x, dropOffCoords.y, pedZ, 0.0, true, false)
                    Citizen.InvokeNative(0x283978A15512B2FE, deliveryPed, true)
                    TaskStandStill(deliveryPed, -1)
                    TaskStartScenarioInPlace(deliveryPed, "WORLD_HUMAN_GUARD_LANTERN_NERVOUS", 0, true)

                end

                if distToDropOff < 200.0 then
                    Citizen.InvokeNative(0x2A32FAA32E194FF8, dropOffCoords.x, dropOffCoords.y, dropOffCoords.z, 5.0, 255, 0, 0, 100)
                end

                if IsEntityDead(playerPed) or (GetEntityHealth(deliveryWagon) <= 0) then
                    TriggerEvent('speakeasy:failDelivery', "The wagon was destroyed or you died.")
                    break
                end

                if not encounterTriggered and distToDropOff < 500.0 then
                    encounterTriggered = true
                    local maxSpeed = 8.0
                    local wagonSpeed = GetEntitySpeed(deliveryWagon)
                    if wagonSpeed > (maxSpeed * 0.75) then
                        local rand = math.random()
                        if rand < 0.4 then
                            local lawmen = {
                                {model = GetHashKey("MP_U_M_M_LAWCAMP_LAWMAN_01"), coords = vector3(wagonCoords.x + 50.0, wagonCoords.y + 50.0, wagonCoords.z)},
                                {model = GetHashKey("MP_U_M_M_LAWCAMP_LAWMAN_02"), coords = vector3(wagonCoords.x + 52.0, wagonCoords.y + 48.0, wagonCoords.z)},
                                {model = GetHashKey("MP_U_M_M_LAWCAMP_LAWMAN_01"), coords = vector3(wagonCoords.x - 50.0, wagonCoords.y - 50.0, wagonCoords.z)},
                                {model = GetHashKey("MP_U_M_M_LAWCAMP_LAWMAN_02"), coords = vector3(wagonCoords.x - 52.0, wagonCoords.y - 48.0, wagonCoords.z)}
                            }
                            for _, lawman in pairs(lawmen) do
                                local foundGround, groundZ = GetGroundZFor_3dCoord(lawman.coords.x, lawman.coords.y, lawman.coords.z + 10.0, false)
                                local pedZ = foundGround and groundZ + 0.5 or lawman.coords.z
                                local ped = CreatePed(lawman.model, lawman.coords.x, lawman.coords.y, pedZ, 0.0, true, false)
                                Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
                                Citizen.InvokeNative(0x7D9EFB7AD6B19754, ped, true)
                                TaskWanderInArea(ped, wagonCoords.x, wagonCoords.y, wagonCoords.z, 50.0, 0, 0)
                                table.insert(enemies, ped)
                            end
                            TriggerEvent('vorp:TipRight', "Lawmen are patrolling nearby. Slow down to avoid suspicion.", 5000)
                        else
                            local bandits = {
                                {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x + 30.0, wagonCoords.y + 30.0, wagonCoords.z)},
                                {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x + 28.0, wagonCoords.y + 32.0, wagonCoords.z)},
                                {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x - 30.0, wagonCoords.y - 30.0, wagonCoords.z)},
                                {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x - 28.0, wagonCoords.y - 32.0, wagonCoords.z)},
                                {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x + 30.0, wagonCoords.y - 30.0, wagonCoords.z)},
                                {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x - 30.0, wagonCoords.y + 30.0, wagonCoords.z)}
                            }
                            for _, bandit in pairs(bandits) do
                                local foundGround, groundZ = GetGroundZFor_3dCoord(bandit.coords.x, bandit.coords.y, bandit.coords.z + 10.0, false)
                                local pedZ = foundGround and groundZ + 0.5 or bandit.coords.z
                                RequestModel(bandit.model)
                                while not HasModelLoaded(bandit.model) do Wait(100) end
                                local ped = CreatePed(bandit.model, bandit.coords.x, bandit.coords.y, pedZ, 0.0, true, false)
                                Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
                                SetEntityAsMissionEntity(ped, true, true)
                                TaskCombatPed(ped, playerPed, 0, 16)
                                table.insert(enemies, ped)
                            end
                            TriggerEvent('vorp:TipRight', "Bandits are ambushing you! Protect the wagon!", 5000)
                            Citizen.CreateThread(function()
                                local banditWaves = 3
                                for wave = 1, banditWaves do
                                    Wait(math.random(30000, 60000)) -- Random delay between waves
                                    if not isDelivering then break end
                                    local waveBandits = {
                                        {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x + math.random(20, 40), wagonCoords.y + math.random(20, 40), wagonCoords.z)},
                                        {model = GetHashKey("G_M_M_UNIBANDITOS_01"), coords = vector3(wagonCoords.x - math.random(20, 40), wagonCoords.y - math.random(20, 40), wagonCoords.z)},
                                    }
                                    for _, bandit in pairs(waveBandits) do
                                        local foundGround, groundZ = GetGroundZFor_3dCoord(bandit.coords.x, bandit.coords.y, bandit.coords.z + 10.0, false)
                                        local pedZ = foundGround and groundZ + 0.5 or bandit.coords.z
                                        RequestModel(bandit.model)
                                        while not HasModelLoaded(bandit.model) do Wait(100) end
                                        local ped = CreatePed(bandit.model, bandit.coords.x, bandit.coords.y, pedZ, 0.0, true, false)
                                        Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
                                        SetEntityAsMissionEntity(ped, true, true)
                                        TaskCombatPed(ped, playerPed, 0, 16)
                                        table.insert(enemies, ped)
                                    end
                                    TriggerEvent('vorp:TipRight', "Another wave of bandits incoming!", 5000)
                                end
                            end)
                        end
                    end
                end
            end
        end
    end)
end)

RegisterNetEvent('speakeasy:cleanupDelivery')
AddEventHandler('speakeasy:cleanupDelivery', function()
    CleanupDelivery()
end)

function CleanupDelivery()
    print("Running CleanupDelivery...")

    -- Blip cleanup
    if deliveryBlip and DoesBlipExist(deliveryBlip) then
        RemoveBlip(deliveryBlip)
    end
    deliveryBlip = nil

    -- Wagon cleanup
    if deliveryWagon and DoesEntityExist(deliveryWagon) then
        DeleteVehicle(deliveryWagon)
    end
    deliveryWagon = nil

    -- Prompt cleanup
    if deliveryPrompt then
        PromptDelete(deliveryPrompt)
    end
    deliveryPrompt = nil

    -- Delivery NPC cleanup
    if deliveryPed and DoesEntityExist(deliveryPed) then
        DeletePed(deliveryPed)
    end
    deliveryPed = nil

    -- Enemies cleanup (safe loop)
    if enemies and type(enemies) == "table" then
        for _, ped in pairs(enemies) do
            if DoesEntityExist(ped) then
                DeletePed(ped)
            end
        end
    end
    enemies = {}

    -- Reset all delivery state
    isDelivering = false
    deliveryJugs = 0
    deliverySpeakeasy = nil

    print("CleanupDelivery finished, isDelivering reset to false")
end



RegisterNetEvent('speakeasy:failDelivery')
AddEventHandler('speakeasy:failDelivery', function(reason)
    TriggerEvent('vorp:TipRight', "Delivery failed: " .. reason, 5000)
    CleanupDelivery()
end)
