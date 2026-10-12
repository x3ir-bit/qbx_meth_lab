local QBCore = exports['qb-core']:GetCoreObject()

-- ============================================================
-- LAB STATE
-- ============================================================
local lab = {
    owned = false,
    upgraded = false,
    owner = nil,
    workers = {},
    dealers = {},
    storage = {},
    lab_cash = 0,
    doorPosition = { x = Config.Lab.position.x, y = Config.Lab.position.y, z = Config.Lab.position.z },
    machines = {
        meth    = { active = false, progress = 0, duration = 0, config = nil, savedConfigs = {} },
        cocaine = { active = false, progress = 0, duration = 0, config = nil, savedConfigs = {} },
        oxy     = { active = false, progress = 0, duration = 0, config = nil, savedConfigs = {} },
        pill    = { active = false, progress = 0, duration = 0, config = nil, savedConfigs = {} }
    }
}

_G.lab_data = lab
local labLoaded = false

-- ============================================================
-- DATABASE
-- ============================================================
local function saveLab()
    if not labLoaded then return end

    local data = json.encode({
        owned = lab.owned,
        upgraded = lab.upgraded,
        owner = lab.owner,
        workers = lab.workers,
        dealers = lab.dealers,
        storage = lab.storage,
        lab_cash = lab.lab_cash,
        doorPosition = lab.doorPosition,
        machines = lab.machines,
        settings = {
            workerSalary = Config.Workers.salary,
            dealerSalary = Config.Dealers.salary,
            maxWorkers = Config.Workers.max,
            maxDealers = Config.Dealers.max,
            cookInterval = Config.Workers.cookInterval,
            sellInterval = Config.Dealers.sellInterval,
            transferMin = Config.TransferMin
        }
    })

    MySQL.query(
        'INSERT INTO `meth_lab_data` (`id`, `data`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `data` = VALUES(`data`)',
        { 1, data }
    )
end

local function loadLab()
    MySQL.query('SELECT `data` FROM `meth_lab_data` WHERE `id` = ?', { 1 }, function(result)
        if not result or not result[1] or not result[1].data then
            labLoaded = true
            return
        end

        local ok, data = pcall(json.decode, result[1].data)
        if not ok or type(data) ~= 'table' then
            print('[qbx_meth_lab] ERROR: Invalid saved data.')
            labLoaded = true
            return
        end

        lab.owned = data.owned or false
        lab.upgraded = data.upgraded or false
        lab.owner = data.owner
        lab.workers = data.workers or {}
        lab.dealers = data.dealers or {}
        lab.storage = data.storage or {}
        lab.lab_cash = data.lab_cash or 0
        lab.doorPosition = data.doorPosition or { x = Config.Lab.position.x, y = Config.Lab.position.y, z = Config.Lab.position.z }

        if data.machines then
            for key, saved in pairs(data.machines) do
                if lab.machines[key] then
                    lab.machines[key].active = saved.active or false
                    lab.machines[key].progress = saved.progress or 0
                    lab.machines[key].duration = saved.duration or 0
                    lab.machines[key].config = saved.config
                    lab.machines[key].savedConfigs = saved.savedConfigs or {}
                end
            end
        end

        if data.settings then
            if data.settings.workerSalary then Config.Workers.salary = data.settings.workerSalary end
            if data.settings.dealerSalary then Config.Dealers.salary = data.settings.dealerSalary end
            if data.settings.maxWorkers then Config.Workers.max = data.settings.maxWorkers end
            if data.settings.maxDealers then Config.Dealers.max = data.settings.maxDealers end
            if data.settings.cookInterval then Config.Workers.cookInterval = data.settings.cookInterval end
            if data.settings.sellInterval then Config.Dealers.sellInterval = data.settings.sellInterval end
            if data.settings.transferMin then Config.TransferMin = data.settings.transferMin end
        end

        labLoaded = true
        print(('[qbx_meth_lab] Loaded. Owned: %s, Upgraded: %s'):format(tostring(lab.owned), tostring(lab.upgraded)))
    end)
end

-- ============================================================
-- HELPERS
-- ============================================================
local function buildData()
    return {
        owned = lab.owned,
        upgraded = lab.upgraded,
        owner = lab.owner,
        workers = lab.workers,
        dealers = lab.dealers,
        storage = lab.storage,
        lab_cash = lab.lab_cash,
        doorPosition = lab.doorPosition,
        machines = lab.machines,
        config = {
            WorkerSalary = Config.Workers.salary,
            DealerSalary = Config.Dealers.salary,
            MaxWorkers = Config.Workers.max,
            MaxDealers = Config.Dealers.max,
            CookInterval = Config.Workers.cookInterval,
            SellInterval = Config.Dealers.sellInterval,
            TransferMin = Config.TransferMin
        }
    }
end

local function sendLabData(src)
    TriggerClientEvent('qbx_meth_lab:client:receiveData', src, buildData())
end

local function broadcastLabData()
    for _, p in ipairs(GetPlayers()) do
        sendLabData(p)
    end
end

local function isOwner(src)
    local player = QBCore.Functions.GetPlayer(src)
    return player and lab.owned and lab.owner == player.PlayerData.citizenid
end

local function canAfford(src, amount)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end
    return (player.Functions.GetMoney('cash') + player.Functions.GetMoney('bank')) >= amount
end

local function takeMoney(src, amount)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end
    local cash = player.Functions.GetMoney('cash')
    if cash >= amount then
        player.Functions.RemoveMoney('cash', amount, 'lab')
    else
        player.Functions.RemoveMoney('cash', cash, 'lab')
        player.Functions.RemoveMoney('bank', amount - cash, 'lab')
    end
end

local function addItem(src, item, count)
    return exports.ox_inventory:AddItem(src, item, count)
end

-- ============================================================
-- EXPORTS
-- ============================================================
exports('GetLabData', function()
    return lab
end)

exports('SaveLabData', function()
    saveLab()
end)

exports('CalculateSellPrice', function(drugType, quality)
    local recipe = Config.Recipes[drugType]
    if not recipe then return 0 end
    local min, max = recipe.sellRange.min, recipe.sellRange.max
    local q = math.min(100, math.max(0, quality)) / 100
    return math.floor(min + (max - min) * q)
end)

-- ============================================================
-- BROADCAST
-- ============================================================
AddEventHandler('qbx_meth_lab:server:broadcast', function()
    broadcastLabData()
end)

-- ============================================================
-- SERVER START
-- ============================================================
CreateThread(function()
    MySQL.ready(function()
        MySQL.query([[CREATE TABLE IF NOT EXISTS `meth_lab_data` (
            `id` INT NOT NULL PRIMARY KEY,
            `data` LONGTEXT NOT NULL
        )]])
        loadLab()
    end)
end)

-- ============================================================
-- STORAGE BAG STASH
-- ============================================================
AddEventHandler('onServerResourceStart', function(res)
    if res == 'ox_inventory' or res == GetCurrentResourceName() then
        exports.ox_inventory:RegisterStash(
            Config.StorageBag.stashId,
            Config.StorageBag.label,
            Config.StorageBag.slots,
            907184,
            false
        )
        print('[qbx_meth_lab] Storage bag stash registered')
    end
end)

RegisterNetEvent('qbx_meth_lab:server:openStorageBag', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    exports.ox_inventory:forceOpenInventory(src, 'stash', Config.StorageBag.stashId)
end)   

RegisterNetEvent('qbx_meth_lab:server:openStorageBag', function()
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local ok, err = pcall(function()
        exports.ox_inventory:OpenInventory(src, Config.StorageBag.stashId, {
            name = Config.StorageBag.label
        })
    end)
    if not ok then
        print('[qbx_meth_lab] Failed to open stash: ' .. tostring(err))
    end
end)        

-- ============================================================
-- PLAYER LOAD
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:load', function()
    sendLabData(source)
end)

-- ============================================================
-- SAVE DOOR POSITION
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:saveDoorPos', function(x, y, z)
    local src = source
    if not isOwner(src) then return end
    x = tonumber(x); y = tonumber(y); z = tonumber(z)
    if not x or not y or not z then return end

    lab.doorPosition = { x = x, y = y, z = z }
    TriggerClientEvent('QBCore:Notify', src, 'Door position updated.', 'success')
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- BUY LAB
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:buyLab', function()
    local src = source
    if lab.owned then
        TriggerClientEvent('QBCore:Notify', src, 'Lab is already owned.', 'error')
        return
    end
    if not canAfford(src, Config.Lab.purchasePrice) then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money ($' .. Config.Lab.purchasePrice .. ').', 'error')
        return
    end
    takeMoney(src, Config.Lab.purchasePrice)
    lab.owned = true
    local player = QBCore.Functions.GetPlayer(src)
    lab.owner = player.PlayerData.citizenid
    TriggerClientEvent('QBCore:Notify', src, 'You now own the Meth Lab!', 'success')
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- UPGRADE LAB
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:upgradeLab', function()
    local src = source
    if not isOwner(src) then
        TriggerClientEvent('QBCore:Notify', src, 'You do not own this lab.', 'error')
        return
    end
    if lab.upgraded then
        TriggerClientEvent('QBCore:Notify', src, 'Already upgraded.', 'error')
        return
    end
    if not canAfford(src, Config.Lab.upgradePrice) then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money ($' .. Config.Lab.upgradePrice .. ').', 'error')
        return
    end
    takeMoney(src, Config.Lab.upgradePrice)
    lab.upgraded = true
    TriggerClientEvent('QBCore:Notify', src, 'Lab upgraded!', 'success')
    TriggerClientEvent('qbx_meth_lab:client:applyUpgrade', src)
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- BUY SUPPLIES
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:buySupplies', function(index)
    local src = source
    if not isOwner(src) then return end
    local supply = Config.Supplies[index]
    if not supply then return end
    if not canAfford(src, supply.price) then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough money.', 'error')
        return
    end
    takeMoney(src, supply.price)
    lab.storage[supply.item] = (lab.storage[supply.item] or 0) + supply.amount
    TriggerClientEvent('QBCore:Notify', src, 'Bought ' .. supply.amount .. 'x ' .. supply.label, 'success')
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- RETRIEVE ITEM
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:retrieveItem', function(item, amount)
    local src = source
    if not isOwner(src) then return end
    amount = tonumber(amount) or 1

    -- Check if it's in the physical bag (stash)
    local stashItem = exports.ox_inventory:GetItem(Config.StorageBag.stashId, item)
    if stashItem and stashItem.count >= amount then
        exports.ox_inventory:RemoveItem(Config.StorageBag.stashId, item, amount)
        if exports.ox_inventory:AddItem(src, item, amount) then
            TriggerClientEvent('QBCore:Notify', src, 'Took ' .. amount .. 'x ' .. item, 'success')
        else
            exports.ox_inventory:AddItem(Config.StorageBag.stashId, item, amount)
            TriggerClientEvent('QBCore:Notify', src, 'Inventory full.', 'error')
        end
        broadcastLabData()
        return
    end

    -- Fallback: check lab.storage (raw materials)
    if not lab.storage[item] or lab.storage[item] < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough in storage.', 'error')
        return
    end
    lab.storage[item] = lab.storage[item] - amount
    if lab.storage[item] <= 0 then lab.storage[item] = nil end

    if addItem(src, item, amount) then
        TriggerClientEvent('QBCore:Notify', src, 'Took ' .. amount .. 'x ' .. item, 'success')
    else
        lab.storage[item] = (lab.storage[item] or 0) + amount
        TriggerClientEvent('QBCore:Notify', src, 'Inventory full.', 'error')
    end
    broadcastLabData()
    saveLab()
end)   

-- ============================================================
-- SAVE MACHINE CONFIG
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:updateMachineConfig', function(drugType, config)
    local src = source
    if not isOwner(src) then return end
    if not lab.machines[drugType] then return end
    if not config or not config.name then
        TriggerClientEvent('QBCore:Notify', src, 'Config needs a name.', 'error')
        return
    end

    local machine = lab.machines[drugType]
    local savedConfigs = machine.savedConfigs

    local found = false
    for i, existing in ipairs(savedConfigs) do
        if existing.name == config.name then
            savedConfigs[i] = config
            found = true
            break
        end
    end
    if not found then
        table.insert(savedConfigs, config)
    end

    machine.config = config
    TriggerClientEvent('QBCore:Notify', src, ('Config "%s" saved for %s.'):format(config.name, drugType), 'success')
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- SELECT SAVED CONFIG
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:selectMachineConfig', function(drugType, configName)
    local src = source
    if not isOwner(src) then return end
    if not lab.machines[drugType] then return end

    local machine = lab.machines[drugType]
    for _, cfg in ipairs(machine.savedConfigs) do
        if cfg.name == configName then
            machine.config = cfg
            TriggerClientEvent('QBCore:Notify', src, ('Loaded config "%s".'):format(configName), 'success')
            broadcastLabData()
            saveLab()
            return
        end
    end
    TriggerClientEvent('QBCore:Notify', src, 'Config not found.', 'error')
end)

-- ============================================================
-- DELETE SAVED CONFIG
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:deleteMachineConfig', function(drugType, configName)
    local src = source
    if not isOwner(src) then return end
    if not lab.machines[drugType] then return end

    local machine = lab.machines[drugType]
    for i, cfg in ipairs(machine.savedConfigs) do
        if cfg.name == configName then
            table.remove(machine.savedConfigs, i)
            if machine.config and machine.config.name == configName then
                machine.config = nil
            end
            TriggerClientEvent('QBCore:Notify', src, ('Deleted config "%s".'):format(configName), 'success')
            broadcastLabData()
            saveLab()
            return
        end
    end
    TriggerClientEvent('QBCore:Notify', src, 'Config not found.', 'error')
end)

-- ============================================================
-- START MANUFACTURING
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:startManufacturing', function(drugType)
    local src = source
    if not isOwner(src) then return end
    local machine = lab.machines[drugType]
    if not machine then return end
    if not machine.config then
        TriggerClientEvent('QBCore:Notify', src, 'Save a configuration first.', 'error')
        return
    end
    if #lab.workers < 1 then
        TriggerClientEvent('QBCore:Notify', src, 'Need at least 1 worker.', 'error')
        return
    end

    machine.active = true
    machine.progress = 0
    machine.duration = 0

    TriggerClientEvent('QBCore:Notify', src, ('Manufacturing started: %s (auto-continue)'):format(machine.config.name or drugType), 'success')
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- STOP MANUFACTURING
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:stopManufacturing', function(drugType)
    local src = source
    if not isOwner(src) then return end
    local machine = lab.machines[drugType]
    if not machine then return end

    machine.active = false
    machine.progress = 0
    TriggerClientEvent('QBCore:Notify', src, 'Manufacturing stopped.', 'success')
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- TRANSFER
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:transferBank', function(amount, toBank)
    local src = source
    if not isOwner(src) then return end
    amount = tonumber(amount) or 0
    if amount < Config.TransferMin then
        TriggerClientEvent('QBCore:Notify', src, 'Minimum: $' .. Config.TransferMin, 'error')
        return
    end
    if lab.lab_cash < amount then
        TriggerClientEvent('QBCore:Notify', src, 'Not enough lab cash.', 'error')
        return
    end
    lab.lab_cash = lab.lab_cash - amount
    local player = QBCore.Functions.GetPlayer(src)
    if player then
        if toBank then
            player.Functions.AddMoney('bank', amount, 'lab-transfer')
        else
            player.Functions.AddMoney('cash', amount, 'lab-transfer')
        end
        TriggerClientEvent('QBCore:Notify', src, 'Transferred $' .. amount, 'success')
    end
    broadcastLabData()
    saveLab()
end)

-- ============================================================
-- SAVE SETTINGS
-- ============================================================
RegisterNetEvent('qbx_meth_lab:server:saveSettings', function(settings)
    local src = source
    if not isOwner(src) then return end
    if not settings then return end

    if settings.workerSalary then Config.Workers.salary = math.max(0, tonumber(settings.workerSalary) or Config.Workers.salary) end
    if settings.dealerSalary then Config.Dealers.salary = math.max(0, tonumber(settings.dealerSalary) or Config.Dealers.salary) end
    if settings.maxWorkers then Config.Workers.max = math.max(1, tonumber(settings.maxWorkers) or Config.Workers.max) end
    if settings.maxDealers then Config.Dealers.max = math.max(1, tonumber(settings.maxDealers) or Config.Dealers.max) end
    if settings.manufactureTime then Config.Workers.cookInterval = math.max(5, tonumber(settings.manufactureTime) or Config.Workers.cookInterval) end
    if settings.dealerSellTime then Config.Dealers.sellInterval = math.max(10, tonumber(settings.dealerSellTime) or Config.Dealers.sellInterval) end
    if settings.transferMin then Config.TransferMin = math.max(0, tonumber(settings.transferMin) or Config.TransferMin) end

    TriggerClientEvent('QBCore:Notify', src, 'Settings saved.', 'success')
    saveLab()
end)

-- ============================================================
-- CALLBACK
-- ============================================================
lib.callback.register('qbx_meth_lab:getLabData', function(source)
    return buildData()
end)   