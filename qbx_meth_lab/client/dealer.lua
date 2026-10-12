-- ============================================================
-- DEALER NPC: idles in lab, goes out to sell when server says so
-- ============================================================

local dealerSellState = {}

RegisterNetEvent('qbx_meth_lab:client:dealerGoSell', function(_, index, sellCoords)
    local dealerPeds = _G._labDealerPeds
    local ped = dealerPeds and dealerPeds[index]
    if not ped or not DoesEntityExist(ped) then return end

    dealerSellState[index] = { selling = true, sellCoords = sellCoords }

    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)

    DoScreenFadeOut(300)
    Wait(350)
    SetEntityCoords(ped, sellCoords.x, sellCoords.y, sellCoords.z, false, false, false, false)
    Wait(100)
    DoScreenFadeIn(300)

    local dict = 'mp_common'
    local anim = 'givetake1_a'
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

    CreateThread(function()
        while dealerSellState[index] and dealerSellState[index].selling do
            if ped and DoesEntityExist(ped) then
                if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                    TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 0, 0.0, false, false, false, false, false, false)
                end
            end
            Wait(2000)
        end
    end)
end)

RegisterNetEvent('qbx_meth_lab:client:dealerComeBack', function(_, index)
    local dealerPeds = _G._labDealerPeds
    local ped = dealerPeds and dealerPeds[index]
    if not ped or not DoesEntityExist(ped) then return end

    dealerSellState[index] = nil

    local offset = 3.0 + (index - 1) * 1.5
    local coords = vector3(Config.Lab.pedSpawnPos.x + offset, Config.Lab.pedSpawnPos.y, Config.Lab.pedSpawnPos.z)

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)

    DoScreenFadeOut(300)
    Wait(350)
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    Wait(100)
    DoScreenFadeIn(300)

    FreezeEntityPosition(ped, false)

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
end)

CreateThread(function()
    while true do
        Wait(4000)
        local dealerPeds = _G._labDealerPeds
        if not dealerPeds then Wait(2000) end
        for i, ped in pairs(dealerPeds or {}) do
            if ped and DoesEntityExist(ped) then
                if not (dealerSellState[i] and dealerSellState[i].selling) then
                    local dict = 'amb@world_human_drug_dealer_hard@male@idle_b'
                    local anim = 'idle_d'
                    if not IsEntityPlayingAnim(ped, dict, anim, 3) then
                        RequestAnimDict(dict)
                        local t = 0
                        while not HasAnimDictLoaded(dict) do
                            Wait(50)
                            t = t + 1
                            if t > 20 then break end
                        end
                        if HasAnimDictLoaded(dict) then
                            TaskPlayAnim(ped, dict, anim, 8.0, -8.0, -1, 0, 0.0, false, false, false, false, false, false)
                        end
                    end
                end
            end
        end
    end
end)   