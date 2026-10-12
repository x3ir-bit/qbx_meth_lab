local QBCore = exports['qb-core']:GetCoreObject()
local dealerNames = { 'Tony', 'Vince', 'Sal', 'Mike', 'Frank', 'Joe' }

RegisterNetEvent('qbx_meth_lab:server:hireDealer', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local labData = _G.lab_data
    if not Player or not labData or not labData.owned then return end

    if #labData.dealers >= Config.Dealers.max then
        TriggerClientEvent('QBCore:Notify', src, 'Maximum dealers hired.', 'error')
        return
    end

    local name = dealerNames[#labData.dealers + 1] or ('Dealer ' .. (#labData.dealers + 1))
    table.insert(labData.dealers, {
        citizenid = 'npc_dealer_' .. os.time(),
        name = name,
        joined = os.time(),
        inventory = {},
        moneyCollected = 0,
        unitsSold = 0,
        selling = false
    })
    exports['qbx_meth_lab']:SaveLabData()
    TriggerClientEvent('QBCore:Notify', src, name .. ' hired as dealer.', 'success')
    TriggerEvent('qbx_meth_lab:server:broadcast')
end)   

RegisterNetEvent('qbx_meth_lab:server:fireDealer', function(index)
    local src = source
    local labData = _G.lab_data
    if not labData or not labData.owned then return end

    if labData.dealers[index] then
        table.remove(labData.dealers, index)
        exports['qbx_meth_lab']:SaveLabData()
        TriggerClientEvent('QBCore:Notify', src, 'Dealer fired.', 'success')
        TriggerEvent('qbx_meth_lab:server:broadcast')
    end
end)

RegisterNetEvent('qbx_meth_lab:server:refillDealer', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local labData = _G.lab_data
    if not Player or not labData or not labData.owned then return end

    local citizenid = Player.PlayerData.citizenid
    for i, dealer in ipairs(labData.dealers) do
        if dealer.citizenid == citizenid then
            local filled = 0
            for itemName, storageAmount in pairs(labData.storage) do
                if storageAmount > 0 and filled < Config.Dealers.maxBaggies and itemName ~= 'lab_cash' then
                    local take = math.min(storageAmount, Config.Dealers.maxBaggies - filled)
                    if take > 0 then
                        labData.storage[itemName] = storageAmount - take
                        if labData.storage[itemName] <= 0 then labData.storage[itemName] = nil end
                        dealer.inventory[itemName] = (dealer.inventory[itemName] or 0) + take
                        filled = filled + take
                    end
                end
            end
            exports['qbx_meth_lab']:SaveLabData()
            if filled > 0 then
                TriggerClientEvent('QBCore:Notify', src, ('Refilled with %d items.'):format(filled), 'success')
            else
                TriggerClientEvent('QBCore:Notify', src, 'No items in storage.', 'error')
            end
            TriggerEvent('qbx_meth_lab:server:broadcast')
            return
        end
    end
end)

CreateThread(function()
    while true do
        Wait(Config.Dealers.sellInterval * 1000)

        local labData = _G.lab_data
        if not (labData and labData.owned and labData.dealers) then
            Wait(10000)
        else
            local changed = false

            for i, dealer in ipairs(labData.dealers) do
                if not dealer.selling then
                    local totalInInv = 0
                    for _, amount in pairs(dealer.inventory or {}) do
                        totalInInv = totalInInv + amount
                    end

                   if totalInInv < Config.Dealers.maxBaggies then
    local space = Config.Dealers.maxBaggies - totalInInv
    for _, recipe in pairs(Config.Recipes) do
        if space <= 0 then break end
        local stashItem = exports.ox_inventory:GetItem(Config.StorageBag.stashId, recipe.product)
        if stashItem and stashItem.count > 0 then
            local take = math.min(stashItem.count, space)
            exports.ox_inventory:RemoveItem(Config.StorageBag.stashId, recipe.product, take)
            dealer.inventory[recipe.product] = (dealer.inventory[recipe.product] or 0) + take
            space = space - take
            changed = true
        end
    end    
                        local newTotal = 0
                        for _, amount in pairs(dealer.inventory) do
                            newTotal = newTotal + amount
                        end

                        if newTotal > 0 then
                            dealer.selling = true
                            local sellLoc = Config.Dealers.sellLocations[math.random(#Config.Dealers.sellLocations)]
                            TriggerClientEvent('qbx_meth_lab:client:dealerGoSell', -1, i, sellLoc)
                        end
                    end
                else
                    local soldThisCycle = 0
                    for itemName, amount in pairs(dealer.inventory) do
                        if amount > 0 then
                            local sellAmount = math.min(amount, math.random(1, 3))
                            dealer.inventory[itemName] = amount - sellAmount
                            if dealer.inventory[itemName] <= 0 then dealer.inventory[itemName] = nil end

                            local drugType = nil
                            for dt, recipe in pairs(Config.Recipes) do
                                if recipe.product == itemName then
                                    drugType = dt
                                    break
                                end
                            end

                            if drugType then
                                local quality = math.random(40, 95)
                                local price = exports['qbx_meth_lab']:CalculateSellPrice(drugType, quality)
                                local total = price * sellAmount
                                dealer.moneyCollected = (dealer.moneyCollected or 0) + total
                                dealer.unitsSold = (dealer.unitsSold or 0) + sellAmount
                                soldThisCycle = soldThisCycle + sellAmount
                            end
                        end
                    end

                    local remaining = 0
                    for _, amount in pairs(dealer.inventory) do
                        remaining = remaining + amount
                    end

                    if remaining == 0 then
                        dealer.selling = false
                        TriggerClientEvent('qbx_meth_lab:client:dealerComeBack', -1, i)
                    end

                    if soldThisCycle > 0 then
                        changed = true
                    end
                end

           if dealer.moneyCollected and dealer.moneyCollected > 0 then
    		   labData.lab_cash = (labData.lab_cash or 0) + dealer.moneyCollected
		   dealer.totalEarned = (dealer.totalEarned or 0) + dealer.moneyCollected
    		   dealer.moneyCollected = 0
    		   changed = true
		end   
            end

            if changed then
                exports['qbx_meth_lab']:SaveLabData()
                TriggerEvent('qbx_meth_lab:server:broadcast')
            end
        end
    end
end)   