local uiOpen = false

RegisterNetEvent('qbx_meth_lab:client:openLabUI', function()
    if uiOpen then return end
    local data = lib.callback.await('qbx_meth_lab:getLabData', false)
    if not data then
        SetNuiFocus(false, false)
        return
    end
    uiOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'open', data = data })
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    uiOpen = false
    cb('ok')
end)

RegisterNUICallback('buyLab', function(_, cb)
    TriggerServerEvent('qbx_meth_lab:server:buyLab')
    cb('ok')
end)

RegisterNUICallback('upgradeLab', function(_, cb)
    TriggerServerEvent('qbx_meth_lab:server:upgradeLab')
    cb('ok')
end)

RegisterNUICallback('hireWorker', function(_, cb)
    TriggerServerEvent('qbx_meth_lab:server:hireWorker')
    cb('ok')
end)

RegisterNUICallback('fireWorker', function(data, cb)
    TriggerServerEvent('qbx_meth_lab:server:fireWorker', data.index)
    cb('ok')
end)

RegisterNUICallback('hireDealer', function(_, cb)
    TriggerServerEvent('qbx_meth_lab:server:hireDealer')
    cb('ok')
end)

RegisterNUICallback('fireDealer', function(data, cb)
    TriggerServerEvent('qbx_meth_lab:server:fireDealer', data.index)
    cb('ok')
end)

RegisterNUICallback('refillDealer', function(_, cb)
    TriggerServerEvent('qbx_meth_lab:server:refillDealer')
    cb('ok')
end)

RegisterNUICallback('buySupply', function(data, cb)
    if data and data.index then
        TriggerServerEvent('qbx_meth_lab:server:buySupplies', data.index)
    end
    cb('ok')
end)

RegisterNUICallback('retrieveItem', function(data, cb)
    if data and data.item and data.amount then
        TriggerServerEvent('qbx_meth_lab:server:retrieveItem', data.item, data.amount)
    end
    cb('ok')
end)

RegisterNUICallback('saveConfig', function(data, cb)
    if data and data.drugType and data.config then
        TriggerServerEvent('qbx_meth_lab:server:updateMachineConfig', data.drugType, data.config)
    end
    cb('ok')
end)

RegisterNUICallback('selectConfig', function(data, cb)
    if data and data.drugType and data.configName then
        TriggerServerEvent('qbx_meth_lab:server:selectMachineConfig', data.drugType, data.configName)
    end
    cb('ok')
end)

RegisterNUICallback('deleteConfig', function(data, cb)
    if data and data.drugType and data.configName then
        TriggerServerEvent('qbx_meth_lab:server:deleteMachineConfig', data.drugType, data.configName)
    end
    cb('ok')
end)

RegisterNUICallback('startManufacturing', function(data, cb)
    if data and data.drugType then
        TriggerServerEvent('qbx_meth_lab:server:startManufacturing', data.drugType)
    end
    cb('ok')
end)

RegisterNUICallback('stopManufacturing', function(data, cb)
    if data and data.drugType then
        TriggerServerEvent('qbx_meth_lab:server:stopManufacturing', data.drugType)
    end
    cb('ok')
end)

RegisterNUICallback('transferBank', function(data, cb)
    if data and data.amount and data.toBank ~= nil then
        TriggerServerEvent('qbx_meth_lab:server:transferBank', data.amount, data.toBank)
    end
    cb('ok')
end)

RegisterNUICallback('saveSettings', function(data, cb)
    if data and data.settings then
        TriggerServerEvent('qbx_meth_lab:server:saveSettings', data.settings)
    end
    cb('ok')
end)

RegisterNUICallback('saveDoorPos', function(data, cb)
    if data and data.x and data.y and data.z then
        TriggerServerEvent('qbx_meth_lab:server:saveDoorPos', data.x, data.y, data.z)
    end
    cb('ok')
end)

RegisterNUICallback('exit', function(_, cb)
    SetNuiFocus(false, false)
    uiOpen = false
    cb('ok')
end)   