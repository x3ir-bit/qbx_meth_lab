local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================================
-- STATE
-- ============================================================
local labData = {}
local workerPeds = {}
local dealerPeds = {}
local isInside = false
local blip = nil
local iplLoaded = false
local exitCooldown = 0
local lastDoorPos = nil
local storageBag = nil
local isEntering = false
local propsLoaded = false   

_G._labDealerPeds = dealerPeds

-- ============================================================
-- IPL
-- ============================================================
local function ensureIplLoaded()
    if iplLoaded then return true end
    RequestIpl(Config.Lab.iplName)
    Wait(2000)
    iplLoaded = true
    local id = GetInteriorAtCoords(Config.Lab.interiorCoords.x, Config.Lab.interiorCoords.y, Config.Lab.interiorCoords.z)
    if id and id ~= 0 and IsValidInterior(id) then
        PinInteriorInMemory(id)
    end
    return id ~= 0
end

-- ============================================================
-- PED HELPERS
-- ============================================================
local function loadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local timeout = 0
    while not HasModelLoaded(model) do
        Wait(50)
        timeout = timeout + 1
        if timeout > 60 then
            print('[qbx_meth_lab] Failed to load model: ' .. tostring(model))
            return false
        end
    end
    return true
end

local function spawnPed(model, coords, heading)
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, heading, true, false)
    if ped == 0 then
        print('[qbx_meth_lab] CreatePed returned 0')
        return nil
    end
    SetEntityAsMissionEntity(ped, true, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, true)
    return ped
end

local function destroyPed(ped)
    if ped and DoesEntityExist(ped) then
        SetEntityAsMissionEntity(ped, true, true)
        DeleteEntity(ped)
    end
end

local function removeAllPeds()
    for _, p in pairs(workerPeds) do destroyPed(p) end
    for _, p in pairs(dealerPeds) do destroyPed(p) end
    workerPeds = {}
    dealerPeds = {}
end

-- ============================================================
-- ANIMATION HELPERS
-- ============================================================
local function playDealerIdle(ped)
    local dict = 'amb@world_human_drug_dealer_hard@male@idle_b'
    local anim = 'idle_d'
    RequestAnimDict(dict)
    local t = 0
    while not HasAnimDictLoaded(dict) do
        Wait(50)
        t = t + 1
        if t > 40 then break end
    end
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 0, 0.0, false, false, false, false, false, false)
    end
end

-- ============================================================
-- PED SYNC
-- ============================================================
local function SyncWorkerPeds()
    local workers = labData.workers or {}
    if not type(workers) == 'table' then workers = {} end
    local desired = 0
    for _ in pairs(workers) do desired = desired + 1 end
    while #workerPeds < desired do
        local idx = #workerPeds + 1
        local offset = (idx - 1) * 1.5
        local coords = vector3(Config.Lab.pedSpawnPos.x + offset, Config.Lab.pedSpawnPos.y, Config.Lab.pedSpawnPos.z)
        if loadModel(Config.Workers.model) then
            local ped = spawnPed(Config.Workers.model, coords, 0.0)
            if ped then
                workerPeds[idx] = ped
                TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_USE_PHONE', 0, true)
            end
        end
        Wait(100)
    end
    while #workerPeds > desired do
        local ped = table.remove(workerPeds)
        destroyPed(ped)
    end
end

local function SyncDealerPeds()
    local dealers = labData.dealers or {}
    if not type(dealers) == 'table' then dealers = {} end
    local desired = 0
    for _ in pairs(dealers) do desired = desired + 1 end
    while #dealerPeds < desired do
        local idx = #dealerPeds + 1
        local offset = 3.0 + (idx - 1) * 1.5
        local coords = vector3(Config.Lab.pedSpawnPos.x + offset, Config.Lab.pedSpawnPos.y, Config.Lab.pedSpawnPos.z)
        if loadModel(Config.Dealers.model) then
            local ped = spawnPed(Config.Dealers.model, coords, 180.0)
            if ped then
                dealerPeds[idx] = ped
                playDealerIdle(ped)
            end
        end
        Wait(100)
    end
    while #dealerPeds > desired do
        local ped = table.remove(dealerPeds)
        destroyPed(ped)
    end
end

local function SyncPeds()
    SyncWorkerPeds()
    SyncDealerPeds()
end

-- ============================================================
-- BLIP
-- ============================================================
local function updateBlip(pos)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
        blip = nil
    end
    blip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(blip, Config.Lab.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Lab.blip.scale)
    SetBlipColour(blip, Config.Lab.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Lab.blip.label)
    EndTextCommandSetBlipName(blip)
end

-- ============================================================
-- DOOR ZONE
-- ============================================================
local doorZoneName = 'meth_lab_door'

local function updateDoorZone(pos)
    pcall(function() exports.ox_target:removeBoxZone(doorZoneName) end)
    exports.ox_target:addBoxZone({
        name = doorZoneName,
        coords = vector3(pos.x, pos.y, pos.z),
        size = { x = 2.0, y = 2.0, z = 2.0 },
        rotation = 0.0,
        debug = false,
        options = {
            {
                type = 'client',
                event = 'qbx_meth_lab:client:enterLab',
                icon = 'fas fa-door-open',
                label = 'Enter Meth Lab',
                canInteract = function() return not isInside end
            }
        },
        distance = 3.0
    })
end

-- ============================================================
-- STORAGE BAG PROP
-- ============================================================
local function spawnStorageBag()
    if storageBag and DoesEntityExist(storageBag) then return end
    local S = Config.StorageBag
    local model = joaat(S.model)
    print('[qbx_meth_lab] Spawning storage bag: ' .. S.model .. ' valid=' .. tostring(IsModelValid(model)))
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        print('[qbx_meth_lab] MODEL NOT FOUND: ' .. S.model)
        return
    end
    RequestModel(model)
    local t = 0
    while not HasModelLoaded(model) do
        Wait(50)
        t = t + 1
        if t > 60 then
            print('[qbx_meth_lab] Timed out loading model: ' .. S.model)
            return
        end
    end
    storageBag = CreateObjectNoOffset(model, S.coords.x, S.coords.y, S.coords.z, true, false, false)
    SetEntityHeading(storageBag, S.heading)
    FreezeEntityPosition(storageBag, true)
    SetEntityInvincible(storageBag, true)
    SetEntityAsMissionEntity(storageBag, true, true)
    SetModelAsNoLongerNeeded(model)
    print('[qbx_meth_lab] Storage bag spawned')
end

local function removeStorageBag()
    if storageBag and DoesEntityExist(storageBag) then
        DeleteEntity(storageBag)
    end
    storageBag = nil
end

-- ============================================================
-- INIT
-- ============================================================
CreateThread(function()
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    DoScreenFadeIn(500)
    SetNuiFocus(false, false)
    TriggerServerEvent('qbx_meth_lab:server:load')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    DoScreenFadeIn(500)
    SetNuiFocus(false, false)
    TriggerServerEvent('qbx_meth_lab:server:load')
end)

-- ============================================================
-- RECEIVE DATA
-- ============================================================
RegisterNetEvent('qbx_meth_lab:client:receiveData', function(data)
    if not data then return end
    labData = data

    SyncPeds()

    local pos = data.doorPosition
    if pos and (not lastDoorPos or lastDoorPos.x ~= pos.x or lastDoorPos.y ~= pos.y or lastDoorPos.z ~= pos.z) then
        updateBlip(pos)
        updateDoorZone(pos)
        lastDoorPos = pos
    end

    SendNUIMessage({ action = 'updateData', data = data })
end)

-- ============================================================
-- INITIAL BLIP + ZONE
-- ============================================================
CreateThread(function()
    Wait(3000)
    local pos = labData.doorPosition or Config.Lab.position
    updateBlip(pos)
    lastDoorPos = pos

    while GetResourceState('ox_target') ~= 'started' do
        Wait(500)
    end
    updateDoorZone(pos)
end)

-- ============================================================
-- INTERIOR PROPS
-- ============================================================
local function loadInteriorProps()
    if propsLoaded then return end
    local interiorId = Config.Lab.interiorId
    if not interiorId or interiorId == 0 or not IsValidInterior(interiorId) then return end

    -- Disable ALL props first
    for _, prop in ipairs(Config.LabProps.basic) do
        DisableInteriorProp(interiorId, prop)
    end
    for _, prop in ipairs(Config.LabProps.upgraded) do
        DisableInteriorProp(interiorId, prop)
    end

    Wait(200)

    -- Enable ONLY the correct set (not both)
    if labData.upgraded then
        for _, prop in ipairs(Config.LabProps.upgraded) do
            EnableInteriorProp(interiorId, prop)
        end
    else
        for _, prop in ipairs(Config.LabProps.basic) do
            EnableInteriorProp(interiorId, prop)
        end
    end

    RefreshInterior(interiorId)
    propsLoaded = true
end   

-- ============================================================
-- ENTER LAB
-- ============================================================
RegisterNetEvent('qbx_meth_lab:client:enterLab', function()
    if isInside or isEntering then return end
isEntering = true

    CreateThread(function()
        if not ensureIplLoaded() then
		isEntering = false
            TriggerClientEvent('QBCore:Notify', LocalPlayer.serverId, 'Failed to load interior.', 'error')
            return
        end

        local ped = PlayerPedId()
        DoScreenFadeOut(500)
        Wait(600)

        local entry = Config.Lab.interiorEntryPos
        SetEntityCoords(ped, entry.x, entry.y, entry.z, false, false, false, false)

        Wait(200)
        DoScreenFadeIn(500)

        isInside = true
        exitCooldown = 5
        loadInteriorProps()
        SyncPeds()
        spawnStorageBag()
		isEntering = false   
    end)
end)

-- ============================================================
-- EXIT LAB
-- ============================================================
CreateThread(function()
    while true do
        Wait(1000)
        if isInside then
            if exitCooldown > 0 then
                exitCooldown = exitCooldown - 1
            else
                local pos = GetEntityCoords(PlayerPedId())
                local exitPos = Config.Lab.interiorExitPos
                if #(pos - exitPos) < 2.5 then
                    isInside = false
                    removeAllPeds()
                    removeStorageBag()
		    propsLoaded = false
                    DoScreenFadeOut(500)
                    Wait(600)
                    local door = labData.doorPosition or Config.Lab.position
                    SetEntityCoords(PlayerPedId(), door.x, door.y, door.z, false, false, false, false)
                    Wait(200)
                    DoScreenFadeIn(500)
                end
            end
        end
    end
end)

-- ============================================================
-- ANIMATION LOOP
-- ============================================================
CreateThread(function()
    while true do
        Wait(5000)
        if isInside then
            for _, p in pairs(workerPeds) do
                if p and DoesEntityExist(p) then
                    local scenarios = { 'WORLD_HUMAN_USE_PHONE', 'WORLD_HUMAN_PAPARAZZI', 'WORLD_HUMAN_CONVERSATION_PHONE' }
                    TaskStartScenarioInPlace(p, scenarios[math.random(#scenarios)], 0, true)
                end
            end
        end
    end
end)

-- ============================================================
-- APPLY UPGRADE
-- ============================================================
RegisterNetEvent('qbx_meth_lab:client:applyUpgrade', function()
    if isInside then
        propsLoaded = false
        loadInteriorProps()
    end
end)   

-- ============================================================
-- OX_TARGET: Laptop
-- ============================================================
CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(500)
    end
    Wait(2000)

    exports.ox_target:addModel(joaat('bkr_prop_clubhouse_laptop_01a'), {
        {
            name = 'methlab_laptop',
            icon = 'fas fa-laptop',
            label = 'Open Lab Terminal',
            distance = 2.5,
            canInteract = function()
                local pos = GetEntityCoords(PlayerPedId())
                local interiorId = GetInteriorAtCoords(pos.x, pos.y, pos.z)
                return interiorId == Config.Lab.interiorId
            end,
            onSelect = function()
                TriggerEvent('qbx_meth_lab:client:openLabUI')
            end
        }
    })
end)

-- ============================================================
-- OX_TARGET: Storage Bag
-- ============================================================
CreateThread(function()
    while GetResourceState('ox_target') ~= 'started' do
        Wait(500)
    end
    Wait(3000)

    exports.ox_target:addModel(joaat(Config.StorageBag.model), {
        {
            name = 'lab_storage_bag',
            icon = 'fas fa-box',
            label = 'Open Lab Storage',
            distance = 2.0,
            canInteract = function()
                return isInside
            end,
            onSelect = function()
                TriggerServerEvent('qbx_meth_lab:server:openStorageBag')
            end
        }
    })
end)

-- ============================================================
-- CLEANUP
-- ============================================================
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    removeAllPeds()
    removeStorageBag()
    propsLoaded = false
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    pcall(function() exports.ox_target:removeBoxZone(doorZoneName) end)
    SetNuiFocus(false, false)
end)

-- ============================================================
-- DEBUG
-- ============================================================
RegisterCommand('unfixscreen', function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    DoScreenFadeIn(500)
end, false)

RegisterCommand('getinterior', function()
    local id = GetInteriorAtCoords(GetEntityCoords(PlayerPedId()))
    print('^2Interior ID: ' .. tostring(id))
end, false)

RegisterCommand('getcoords', function()
    local c = GetEntityCoords(PlayerPedId())
    print(('^2Coords: vector3(%.2f, %.2f, %.2f)'):format(c.x, c.y, c.z))
end, false)   