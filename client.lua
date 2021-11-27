local QBCore = exports['qb-core']:GetCoreObject()

local config = Config
local dynamicHealth = false
local dynamicHunger = false
local dynamicThirst = false
local dynamicStress = false
local dynamicOxygen = false
local dynamicEngine = false
local dynamicNitro = false

local speedMultiplier = config.UseMPH and 2.23694 or 3.6
local seatbeltOn = false
local cruiseOn = false
local showaltitude = false
local showseatbelt = false
local nos = 0
local stress = 0
local hunger = 100
local thirst = 100
local cashAmount = 0
local bankAmount = 0
local nitroActive = 0
local harness = 0
local hp = 100
local armed = 0
local parachute = -1
local oxygen = 100
local engine = 0
local dev = false
local playerDead = false


-- Events

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(100)
    TriggerEvent("hud:client:ChangeSquare")
end)

RegisterNetEvent("hud:client:EngineHealth", function(newEngine)
    engine = newEngine
end)

RegisterNetEvent('hud:client:ToggleAirHud', function()
    showaltitude = not showaltitude
end)

RegisterNetEvent('hud:client:UpdateNeeds', function(newHunger, newThirst) -- Triggered in qb-core
    hunger = newHunger
    thirst = newThirst
end)

RegisterNetEvent('hud:client:UpdateStress', function(newStress) -- Add this event with adding stress elsewhere
    stress = newStress
end)

RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
    showseatbelt = not showseatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- Triggered in smallresources
    seatbeltOn = not seatbeltOn
end)

RegisterNetEvent('seatbelt:client:ToggleCruise', function() -- Triggered in smallresources
    cruiseOn = not cruiseOn
end)

RegisterNetEvent('hud:client:UpdateNitrous', function(hasNitro, nitroLevel, bool)
    nos = nitroLevel
    nitroActive = bool
end)

RegisterNetEvent('hud:client:UpdateHarness', function(harnessHp)
    hp = harnessHp
end)

RegisterNetEvent("qb-admin:client:ToggleDevmode", function()
    dev = not dev
end)

RegisterNetEvent("hud:client:ToggleCinematic", function()
    cinematic = not cinematic
    if CinematicModeOn == true then
        CinematicShow(false)
        CinematicModeOn = false
        TriggerEvent('QBCore:Notify', 'Cinematic mode off!', 'error')
        DisplayRadar(1)
    elseif CinematicModeOn == false then
        CinematicShow(true)
        CinematicModeOn = true
        TriggerEvent('QBCore:Notify', 'Cinematic mode on!')
    end
end)

RegisterCommand('+engine', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle ~= nil and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, 0) then
        if (GetIsVehicleEngineRunning(vehicle)) then
            QBCore.Functions.Notify('Engine halted!', "error")
        else
            QBCore.Functions.Notify('Engine started!')
        end
        SetVehicleEngineOn(vehicle, (not GetIsVehicleEngineRunning(vehicle)), false, true)
    end
end)

RegisterKeyMapping('+engine', 'Toggle Engine', 'keyboard', 'G')


local function IsWhitelistedWeaponArmed(weapon)
    if weapon ~= nil then
        for _, v in pairs(config.WhitelistedWeaponArmed) do
            if weapon == GetHashKey(v) then
                return true
            end
        end
    end
    return false
end

local prevPlayerStats = { nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil }

local function updatePlayerHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevPlayerStats[k] ~= v then
            shouldUpdate = true
            break
        end
    end
    prevPlayerStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'hudtick',
            show = data[1],
            dynamicHealth = data[2],
            dynamicHunger = data[3],
            dynamicThirst = data[4],
            dynamicStress = data[5],
            dynamicOxygen = data[6],
            dynamicEngine = data[7],
            dynamicNitro = data[8],
            health = data[9],
            playerDead = data[10],
            armor = data[11],
            thirst = data[12],
            hunger = data[13],
            stress = data[14],
            voice = data[15],
            radio = data[16],
            talking = data[17],
            armed = data[18],
            oxygen = data[19],
            parachute = data[20],
            nos = data[21],
            cruise = data[22],
            nitroActive = data[23],
            harness = data[24],
            hp = data[25],
            speed = data[26],
            engine = data[27],
            cinematic = data[28],
            dev = data[29],
        })
    end
end

local prevVehicleStats = { nil, nil, nil, nil, nil, nil, nil, nil }

local function updateVehicleHud(data)
    local shouldUpdate = false
    for k, v in pairs(data) do
        if prevVehicleStats[k] ~= v then shouldUpdate = true break end
    end
    prevVehicleStats = data
    if shouldUpdate then
        SendNUIMessage({
            action = 'car',
            show = data[1],
            isPaused = data[2],
            seatbelt = data[3],
            speed = data[4],
            fuel = data[5],
            altitude = data[6],
            showaltitude = data[7],
            showseatbelt = data[8],
        })
    end
end

local lastFuelUpdate = 0
local lastFuelCheck = {}

local function getFuelLevel(vehicle)
    local updateTick = GetGameTimer()
    if (updateTick - lastFuelUpdate) > 2000 then
        lastFuelUpdate = updateTick
        lastFuelCheck = math.floor(exports['LegacyFuel']:GetFuel(vehicle))
    end
    return lastFuelCheck
end

-- HUD Update loop

CreateThread(function()
    local wasInVehicle = false;
    while true do
        Wait(50)
        if LocalPlayer.state.isLoggedIn then
            local show = true
            local player = PlayerPedId()
            local weapon = GetSelectedPedWeapon(player)
            -- player hud
            if config.dynamicHealth == true then
                dynamicHealth  = true
            else
                dynamicHealth = false
            end
            if config.dynamicHunger == true then
                dynamicHunger  = true
            else
                dynamicHunger = false
            end
            if config.dynamicThirst == true then
                dynamicThirst  = true
            else
                dynamicThirst = false
            end
            if config.dynamicStress == true then
                dynamicStress  = true
            else
                dynamicStress = false
            end
            if config.dynamicOxygen == true then
                dynamicOxygen  = true
            else
                dynamicOxygen = false
            end
            if config.dynamicEngine == true then
                dynamicEngine  = true
            else
                dynamicEngine = false
            end
            if config.dynamicNitro == true then
                dynamicNitro  = true
            else
                dynamicNitro = false
            end

            if not IsWhitelistedWeaponArmed(weapon) then
                if weapon ~= `WEAPON_UNARMED` then
                    armed = true
                else
                    armed = false
                end
            end
            if IsPedDeadOrDying(player) or QBCore.Functions.GetPlayerData().metadata["inlaststand"] then
                playerDead=true
        
            else
               playerDead=false
            end    
            parachute = GetPedParachuteState(PlayerPedId())
            -- stamina
            if not IsEntityInWater(PlayerPedId()) then
                oxygen = 100 - GetPlayerSprintStaminaRemaining(PlayerId())  
            end
            -- oxygen
            if IsEntityInWater(PlayerPedId()) then
                oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
            end
            -- player hud
            local talking = NetworkIsPlayerTalking(PlayerId())
            local voice = 0
            if LocalPlayer.state['proximity'] ~= nil then
                voice = LocalPlayer.state['proximity'].distance
            end
            if IsPauseMenuActive() then
                show = false
            end
            if not ( IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle) ) then
            updatePlayerHud({
                show, 
                dynamicHealth,
                dynamicHunger,
                dynamicThirst,
                dynamicStress,
                dynamicOxygen,
                dynamicEngine,
                dynamicNitro,
                GetEntityHealth(player) - 100,
                playerDead,
                GetPedArmour(player),
                thirst,
                hunger,
                stress,
                voice,
                LocalPlayer.state['radioChannel'],
                talking,
                armed,
                oxygen,
                GetPedParachuteState(player),
                -1,
                cruiseOn,
                nitroActive,
                harness,
                hp,
                math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                -1,
                cinematic,
                dev,

            }) 
            end
            -- vehcle hud
            local vehicle = GetVehiclePedIsIn(player)
            if IsPedInAnyHeli(player) or IsPedInAnyPlane(player) then
                showaltitude = true
                showseatbelt = false
            end
            if IsPedInAnyVehicle(player) and not IsThisModelABicycle(vehicle) then
                if not wasInVehicle then
                    DisplayRadar(true)
                end
                wasInVehicle = true
                QBCore.Functions.TriggerCallback('hud:server:HasHarness', function(hasItem)
                    if hasItem then
                        harness = true
                    else
                        harness = false
                    end
                end, "harness")
                updatePlayerHud({
                    show, 
                    dynamicHealth,
                    dynamicHunger,
                    dynamicThirst,
                    dynamicStress,
                    dynamicOxygen,
                    dynamicEngine,
                    dynamicNitro,
                    GetEntityHealth(player) - 100,
                    playerDead,
                    GetPedArmour(player),
                    thirst,
                    hunger,
                    stress,
                    voice,
                    LocalPlayer.state['radioChannel'],
                    talking,
                    armed,
                    oxygen,
                    GetPedParachuteState(player),
                    nos,
                    cruiseOn,
                    nitroActive,
                    harness,
                    hp,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    (GetVehicleEngineHealth(vehicle) /10),
                    cinematic,
                    dev,
                })
                updateVehicleHud({
                    show,
                    IsPauseMenuActive(),
                    seatbeltOn,
                    math.ceil(GetEntitySpeed(vehicle) * speedMultiplier),
                    getFuelLevel(vehicle),
                    math.ceil((GetEntityCoords(player).z *.5)),
                    showaltitude,
                    showseatbelt,
                })
                showaltitude = false
                showseatbelt = true
            else
                if wasInVehicle then
                    wasInVehicle = false
                    SendNUIMessage({
                        action = 'car',
                        show = false,
                        seatbelt = false,
                        cruise = false,
                    })
                    seatbeltOn = false
                    cruiseOn = false
                    harness = false
                end
                DisplayRadar(false)
            end
        else
            SendNUIMessage({
                action = 'hudtick',
                show = false
            })
            DisplayRadar(false)
            Wait(500)
        end
    end
end)

-- low fuel
CreateThread(function()
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                if exports['LegacyFuel']:GetFuel(GetVehiclePedIsIn(PlayerPedId(), false)) <= 20 then -- At 20% Fuel Left
                    TriggerServerEvent("InteractSound_SV:PlayOnSource", "pager", 0.10)
                    TriggerEvent('QBCore:Notify', "Low Fuel!", "error")
                    Wait(60000) -- repeats every 1 min until empty
                end
            end
        end
        Wait(10000)
    end
end)

RegisterNetEvent("hud:client:ChangeSquare", function()
    RequestStreamedTextureDict("squaremap", false)
        if not HasStreamedTextureDictLoaded("squaremap") then
            Wait(500)
        end
        if Config.ShowMapNotif == true then
            TriggerEvent('QBCore:Notify', 'Square map loading...')
        end
            SetMinimapClipType(0)
            AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "squaremap", "radarmasksm")
            AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "squaremap", "radarmasksm")
            -- 0.0 = nav symbol and icons left 
            -- 0.1638 = nav symbol and icons stretched
            -- 0.216 = nav symbol and icons raised up
            SetMinimapComponentPosition("minimap", "L", "B", 0.0, -0.047, 0.1638, 0.183)

            -- icons within map
            SetMinimapComponentPosition("minimap_mask", "L", "B", 0.2, 0.0, 0.065, 0.20)

            -- -0.01 = map pulled left
            -- 0.025 = map raised up
            -- 0.262 = map stretched
            -- 0.315 = map shorten
            SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.01, 0.025, 0.262, 0.300)
            SetBlipAlpha(GetNorthRadarBlip(), 0)
            SetRadarBigmapEnabled(true, false)
            SetMinimapClipType(0)
            Wait(500)
            SetRadarBigmapEnabled(false, false)
            Wait(1200)
        if Config.ShowMapNotif == true then
            TriggerEvent('QBCore:Notify', 'Square map loaded!')
        end
end)

RegisterNetEvent("hud:client:ChangeCircle", function()
    RequestStreamedTextureDict("circlemap", false)
        if not HasStreamedTextureDictLoaded("circlemap") then
            Wait(500)
        end
        if Config.ShowMapNotif == true then
            TriggerEvent('QBCore:Notify', 'Circle map loading...')
        end
            SetMinimapClipType(1)
            AddReplaceTexture("platform:/textures/graphics", "radarmasksm", "circlemap", "radarmasksm")
            AddReplaceTexture("platform:/textures/graphics", "radarmask1g", "circlemap", "radarmasksm")
            -- -0.0100 = nav symbol and icons left 
            -- 0.180 = nav symbol and icons stretched
            -- 0.258 = nav symbol and icons raised up
            SetMinimapComponentPosition("minimap", "L", "B", -0.0100, -0.030, 0.180, 0.258)

            -- icons within map
            SetMinimapComponentPosition("minimap_mask", "L", "B", 0.200, 0.0, 0.065, 0.20)

            -- -0.00 = map pulled left
            -- 0.015 = map raised up
            -- 0.252 = map stretched
            -- 0.338 = map shorten
            SetMinimapComponentPosition('minimap_blur', 'L', 'B', -0.00, 0.015, 0.252, 0.338)
            SetBlipAlpha(GetNorthRadarBlip(), 0)
            SetMinimapClipType(1)
            SetRadarBigmapEnabled(true, false)
            Wait(500)
            SetRadarBigmapEnabled(false, false)
            Wait(1200)
        if Config.ShowMapNotif == true then
            TriggerEvent('QBCore:Notify', 'Circle map loaded!')
        end
end)

-- Money HUD

RegisterNetEvent('hud:client:ShowAccounts')
AddEventHandler('hud:client:ShowAccounts', function(type, amount)
    if type == 'cash' then
        SendNUIMessage({
            action = 'show',
            type = 'cash',
            cash = amount
        })
    else
        SendNUIMessage({
            action = 'show',
            type = 'bank',
            bank = amount
        })
    end
end)

RegisterNetEvent('hud:client:OnMoneyChange')
AddEventHandler('hud:client:OnMoneyChange', function(type, amount, isMinus)
    QBCore.Functions.GetPlayerData(function(PlayerData)
        cashAmount = PlayerData.money['cash']
        bankAmount = PlayerData.money['bank']
    end)
    SendNUIMessage({
        action = 'update',
        cash = cashAmount,
        bank = bankAmount,
        amount = amount,
        minus = isMinus,
        type = type
    })
end)

-- Stress Gain

CreateThread(function() -- Speeding
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local speed = GetEntitySpeed(GetVehiclePedIsIn(ped, false)) * speedMultiplier
                local stressSpeed = seatbeltOn and config.MinimumSpeed or config.MinimumSpeedUnbuckled
                if speed >= stressSpeed then
                    TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                end
            end
        end
        Wait(10000)
    end
end)

local function IsWhitelistedWeaponStress(weapon)
    if weapon ~= nil then
        for _, v in pairs(config.WhitelistedWeaponStress) do
            if weapon == GetHashKey(v) then
                return true
            end
        end
    end
    return false
end

CreateThread(function() -- Shooting
    while true do
        if LocalPlayer.state.isLoggedIn then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= `WEAPON_UNARMED` then
                if IsPedShooting(ped) and not IsWhitelistedWeapon(weapon) then
                    if math.random() < config.StressChance then
                        TriggerServerEvent('hud:server:GainStress', math.random(1, 3))
                    end
                end
            else
                Wait(500)
            end
        end
        Wait(8)
    end
end)

-- Stress Screen Effects

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if stress >= 100 then
            local ShakeIntensity = GetShakeIntensity(stress)
            local FallRepeat = math.random(2, 4)
            local RagdollTimeout = (FallRepeat * 1750)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
            SetFlash(0, 0, 500, 3000, 500)

            if not IsPedRagdoll(ped) and IsPedOnFoot(ped) and not IsPedSwimming(ped) then
                SetPedToRagdollWithFall(ped, RagdollTimeout, RagdollTimeout, 1, GetEntityForwardVector(ped), 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
            end

            Wait(500)
            for i=1, FallRepeat, 1 do
                Wait(750)
                DoScreenFadeOut(200)
                Wait(1000)
                DoScreenFadeIn(200)
                ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
                SetFlash(0, 0, 200, 750, 200)
            end
        elseif stress >= config.MinimumStress then
            local ShakeIntensity = GetShakeIntensity(stress)
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', ShakeIntensity)
            SetFlash(0, 0, 500, 2500, 500)
        end
        Wait(GetEffectInterval(stress))
    end
end)

function GetShakeIntensity(stresslevel)
    local retval = 0.05
    for k, v in pairs(config.Intensity['shake']) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.intensity
            break
        end
    end
    return retval
end

function GetEffectInterval(stresslevel)
    local retval = 60000
    for k, v in pairs(config.EffectInterval) do
        if stresslevel >= v.min and stresslevel <= v.max then
            retval = v.timeout
            break
        end
    end
    return retval
end

-- cinematic mode
CinematicHeight = 0.2
CinematicModeOn = false
w = 0
function CinematicShow(bool)
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    if bool then
        for i = CinematicHeight, 0, -1.0 do
            Wait(10)
            w = i
        end 
    else
        for i = 0, CinematicHeight, 1.0 do 
            Wait(10)
            w = i
        end
    end
end
Citizen.CreateThread(function()
    minimap = RequestScaleformMovie("minimap")
    if not HasScaleformMovieLoaded(minimap) then
        RequestScaleformMovie(minimap)
        while not HasScaleformMovieLoaded(minimap) do 
            Wait(1)
        end
    end
    while true do
        Citizen.Wait(0)
        if w > 0 then
            BlackBars()
            DisplayRadar(0)
            SendNUIMessage({
                action = 'hudtick',
                show = false,
            })
            SendNUIMessage({
                action = 'car',
                show = false,
            })
        end
    end
end)
function BlackBars()
    DrawRect(0.0, 0.0, 2.0, w, 0, 0, 0, 255)
    DrawRect(0.0, 1.0, 2.0, w, 0, 0, 0, 255)
end