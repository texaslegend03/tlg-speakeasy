-- moonshinemaster.lua
local VORPcore = exports['vorp_core']
local isMinigameActive = false
local isBrewing = false
local minigameState = nil
local lastBrewTrigger = 0

local speakeasyData = {
    ["Valentine Speakeasy"] = {
        entrance = vector4(-294.8379, 773.6043, 122.4680, 106.5352),
        interior = vector3(1627.64, 822.9, 123.94),
        still = vector4(1635.2037, 828.8015, 121.7142, 249.0636),
        stash = vector4(1628.8544, 832.3642, 121.7443, 342.9294),
        gatherPrompt = vector3(1628.8071, 831.1607, 124.9388)
    },
    ["St. Denis Speakeasy"] = {
        entrance = vector4(2801.1492, -1167.8979, 47.9280, 328.5178),
        interior = vector3(1785.01, -821.53, 191.01),
        still = vector4(1794.3488, -818.9418, 189.3715, 221.9173),
        stash = vector4(1790.6483, -813.2516, 189.3715, 305.2269),
        gatherPrompt = vector3(1789.5686, -813.7832, 192.5660)
    },
    ["Blackwater Speakeasy"] = {
        entrance = vector4(-808.3959, -1362.4348, 43.6613, 273.5056),
        interior = vector3(-1861.7, -1722.17, 88.35),
        still = vector4(-1870.0344, -1727.5067, 86.0275, 66.3558),
        stash = vector4(-1864.6903, -1731.8602, 86.0275, 165.8448),
        gatherPrompt = vector3(-1863.9672, -1730.8575, 89.2220)
    },
    ["Tumbleweed Speakeasy"] = {
        entrance = vector4(-5517.1445, -2962.4446, -0.8052, 5.8392),
        interior = vector3(-2769.3, -3048.87, -9.7),
        still = vector4(-2774.8235, -3040.8032, -11.9282, 346.4167),
        stash = vector4(-2778.8408, -3046.0442, -11.9282, 57.1431),
        gatherPrompt = vector3(-2778.0986, -3046.9338, -8.7336)
    },
    ["Strawberry Speakeasy"] = {
        entrance = vector4(-1782.4546, -387.2557, 159.2520, 323.5451),
        interior = vector3(-1085.63, 714.14, 83.23),
        still = vector4(-1095.1429, 715.0342, 81.0064, 38.7463),
        stash = vector4(-1093.0219, 708.0108, 81.0063, 117.9610),
        gatherPrompt = vector3(-1092.4403, 708.5665, 84.2008)
    }
}

local stillPrompt = PromptRegisterBegin()
PromptSetControlAction(stillPrompt, 0xE8342FF2) -- Alt key
PromptSetText(stillPrompt, CreateVarString(10, "LITERAL_STRING", "Brew Moonshine"))
PromptSetEnabled(stillPrompt, false)
PromptSetVisible(stillPrompt, false)
PromptSetStandardMode(stillPrompt, true)
PromptRegisterEnd(stillPrompt)

function StartMoonshineMinigame(speakeasyType)
    if isMinigameActive or isBrewing then
        TriggerEvent('vorp:TipRight', "Error: A minigame is already in progress!", 3000)
        return
    end

    isMinigameActive = true
    isBrewing = true

    local playerPed = PlayerPedId()
    SetEntityInvincible(playerPed, true)

    RequestAnimDict("mech_inventory@crafting@fallbacks")
    while not HasAnimDictLoaded("mech_inventory@crafting@fallbacks") do
        Citizen.Wait(100)
    end
    TaskPlayAnim(playerPed, "mech_inventory@crafting@fallbacks", "full_craft_and_stow", 8.0, -8.0, -1, 27, 0, false, false, false)

    SendNUIMessage({ action = "start" })
    SetNuiFocus(true, true)
    TriggerEvent('vorp:TipRight', "Keep the temperature between 140-160°F. Use 'T' to add wood.", 30000)

    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local offset = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, -1.5, 0.75)
    SetCamCoord(cam, offset.x, offset.y, offset.z)
    PointCamAtEntity(cam, playerPed, 0.0, 0.0, 0.0, true)
    SetCamFov(cam, 50.0)
    RenderScriptCams(true, true, 500, true, false)

    minigameState = {
        temperature = 150,
        progress = 0,
        lastStirTime = GetGameTimer(),
        addCornTriggered = false,
        addCornSuccess = false,
        totalStirPrompts = 0,
        successfulStirs = 0,
        stirInterval = math.random(8000, 12000),
        stirWindow = 3000,
        addCornWindow = 5000
    }

    Citizen.CreateThread(function()
        while isMinigameActive do
            Citizen.Wait(100)
        end
        ClearPedTasks(playerPed)
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(cam, false)
        SetEntityInvincible(playerPed, false)
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hide" })
        isBrewing = false
        minigameState = nil
    end)

    Citizen.CreateThread(function()
        local lastUpdateTime = GetGameTimer()
        while isMinigameActive do
            Citizen.Wait(0)
            local currentTime = GetGameTimer()
            local deltaTime = (currentTime - lastUpdateTime) / 1000
            lastUpdateTime = currentTime

            minigameState.temperature = minigameState.temperature - 2.0 * deltaTime
            if minigameState.temperature < 0 then minigameState.temperature = 0 end

            if currentTime - minigameState.lastStirTime > minigameState.stirInterval and minigameState.totalStirPrompts < 2 then
                minigameState.totalStirPrompts = minigameState.totalStirPrompts + 1
                local xPos = math.random(40, 60)
                local yPos = math.random(40, 60)
                SendNUIMessage({ action = "show_stir_button", duration = minigameState.stirWindow, x = xPos, y = yPos })
                minigameState.stirInterval = math.random(8000, 12000)
            end

            if minigameState.progress >= 50 and not minigameState.addCornTriggered then
                minigameState.addCornTriggered = true
                local xPos = math.random(40, 60)
                local yPos = math.random(40, 60)
                SendNUIMessage({ action = "show_mash_button", duration = minigameState.addCornWindow, x = xPos, y = yPos })
            end

            if minigameState.temperature <= 135 or minigameState.temperature >= 175 then
                isMinigameActive = false
                TriggerEvent('vorp:TipRight', "Brewing failed! Temperature out of range.", 3000)
                SendNUIMessage({ action = "end", result = "fail" })
                TriggerServerEvent("speakeasy:brewFailed", speakeasyType)
                break
            end

            if minigameState.temperature >= 140 and minigameState.temperature <= 160 then
                minigameState.progress = minigameState.progress + 5.0 * deltaTime
            end

            SendNUIMessage({
                action = "update",
                temperature = math.floor(minigameState.temperature),
                progress = math.floor(minigameState.progress)
            })

            if minigameState.progress >= 100 then
             isMinigameActive = false
             local reward = 2
             if minigameState.successfulStirs >= minigameState.totalStirPrompts then reward = reward + 1 end
             if minigameState.addCornSuccess then reward = reward + 1 end
             TriggerServerEvent("speakeasy:brewSuccess", speakeasyType, reward)  -- Direct trigger
             SendNUIMessage({ action = "end", result = "success", reward = reward })
             TriggerEvent('vorp:TipRight', "Brewing succeeded! Reward: " .. reward .. " moonshine", 3000)
             break
          end
        end
    end)
end

RegisterNUICallback("raise_temp", function(data, cb)
    if minigameState and isMinigameActive then
        minigameState.temperature = minigameState.temperature + 20
        if minigameState.temperature > 200 then minigameState.temperature = 200 end
    end
    cb("ok")
end)

RegisterNUICallback("stir", function(data, cb)
    if minigameState and isMinigameActive and minigameState.totalStirPrompts > minigameState.successfulStirs then
        minigameState.successfulStirs = minigameState.successfulStirs + 1
        minigameState.lastStirTime = GetGameTimer()
        SendNUIMessage({ action = "hide_stir_button" })
        PlaySoundFrontend("HUD_SHOP_SOUNDSET", "PURCHASE", true, 0)
    end
    cb("ok")
end)

RegisterNUICallback("add_mash", function(data, cb)
    if minigameState and isMinigameActive and minigameState.addCornTriggered and not minigameState.addCornSuccess then
        minigameState.addCornSuccess = true
        SendNUIMessage({ action = "hide_mash_button" })
        PlaySoundFrontend("HUD_SHOP_SOUNDSET", "PURCHASE", true, 0)
    end
    cb("ok")
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustPressed(0, 0xB2CE5D) then -- 'T' key
            if isMinigameActive and minigameState then
                TriggerNUICallback("raise_temp", {}, function() end)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local isNearStill = false
        local targetSpeakeasy = nil

        for name, data in pairs(speakeasyData) do
            local stillDist = #(playerCoords - vector3(data.still.x, data.still.y, data.still.z))
            if stillDist < 1.5 then
                isNearStill = true
                targetSpeakeasy = name
                break
            end
        end

        if isNearStill and targetSpeakeasy and not isBrewing then
            PromptSetEnabled(stillPrompt, true)
            PromptSetVisible(stillPrompt, true)
            if PromptHasStandardModeCompleted(stillPrompt) then
                local currentTime = GetGameTimer()
                if currentTime - lastBrewTrigger > 2000 then
                    TriggerServerEvent('speakeasy:startBrewing', targetSpeakeasy)
                    lastBrewTrigger = currentTime
                end
            end
        else
            PromptSetEnabled(stillPrompt, false)
            PromptSetVisible(stillPrompt, false)
        end
    end
end)