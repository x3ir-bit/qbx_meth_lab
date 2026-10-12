local QBCore = exports['qb-core']:GetCoreObject()

local workerNames = { 'Carlos', 'Miguel', 'Rafael', 'Diego', 'Andre', 'Pedro', 'Lucas', 'Mateo' }
local dealerNames = { 'Tony', 'Vince', 'Sal', 'Mike', 'Frank', 'Joe' }

RegisterNetEvent('qbx_meth_lab:server:hireWorker', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local labData = _G.lab_data
    if not Player or not labData or not labData.owned then return end

    if #labData.workers >= Config.Workers.max then
        TriggerClientEvent('QBCore:Notify', src, 'Maximum workers hired.', 'error')
        return
    end

    local name = workerNames[#labData.workers + 1] or ('Worker ' .. (#labData.workers + 1))
    table.insert(labData.workers, {
        citizenid = 'npc_' .. os.time(),
        name = name,
        joined = os.time(),
        unitsManufactured = 0
    })
    exports['qbx_meth_lab']:SaveLabData()
    TriggerClientEvent('QBCore:Notify', src, name .. ' hired as worker.', 'success')
    TriggerEvent('qbx_meth_lab:server:broadcast')
end)

RegisterNetEvent('qbx_meth_lab:server:fireWorker', function(index)
    local src = source
    local labData = _G.lab_data
    if not labData or not labData.owned then return end

    if labData.workers[index] then
        local name = labData.workers[index].name
        table.remove(labData.workers, index)
        exports['qbx_meth_lab']:SaveLabData()
        TriggerClientEvent('QBCore:Notify', src, name .. ' fired.', 'success')
        TriggerEvent('qbx_meth_lab:server:broadcast')
    end
end)

CreateThread(function()
    while true do
        Wait(Config.Workers.cookInterval * 1000)

        local labData = _G.lab_data
        if not (labData and labData.owned and labData.workers and #labData.workers > 0) then
            Wait(10000)
        else
            local changed = false

            for drugType, machine in pairs(labData.machines) do
                local recipe = Config.Recipes[drugType]
                if not recipe or not machine.config then goto continue end
                if not machine.active then goto continue end

                local canCook = true
                for _, ing in ipairs(recipe.ingredients) do
                    if (labData.storage[ing.item] or 0) < ing.amount then
                        canCook = false
                        break
                    end
                end

                if canCook then
                    for _, ing in ipairs(recipe.ingredients) do
                        labData.storage[ing.item] = labData.storage[ing.item] - ing.amount
                        if labData.storage[ing.item] <= 0 then labData.storage[ing.item] = nil end
                    end

                    local quality = recipe.baseQuality
                    local additives = machine.config.additives or {}
                    for _, addName in ipairs(additives) do
                        if (labData.storage[addName] or 0) > 0 then
                            labData.storage[addName] = labData.storage[addName] - 1
                            if labData.storage[addName] <= 0 then labData.storage[addName] = nil end
                            quality = quality + 5
                        end
                    end
                    quality = math.min(100, quality)

                    local qty = machine.config.quantity or 1
                    local produced = math.max(1, math.floor(qty * (0.8 + quality / 200)))
                    local ok, err = pcall(function()
    exports.ox_inventory:AddItem(Config.StorageBag.stashId, recipe.product, produced)
end)
if not ok then
    print('[qbx_meth_lab] Failed to add to stash: ' .. tostring(err))
end      
                    changed = true

                    local perWorker = math.ceil(produced / #labData.workers)
                    for i = 1, #labData.workers do
                        labData.workers[i].unitsManufactured = (labData.workers[i].unitsManufactured or 0) + perWorker
                    end

                    if labData.owner then
                        local ownerPlayer = QBCore.Functions.GetPlayer(labData.owner)
                        if ownerPlayer then
                            TriggerClientEvent('QBCore:Notify', ownerPlayer.PlayerData.source,
                                ('Produced %dx %s (Quality: %d%%)'):format(produced, recipe.label, quality), 'success')
                        end
                    end
                end
                ::continue::
            end

            if changed then
                exports['qbx_meth_lab']:SaveLabData()
                TriggerEvent('qbx_meth_lab:server:broadcast')
            end
        end
    end
end)   