Config = {}

Config.Lab = {
    position = vector3(1109.4106, -2256.855, 31.1971),
    interiorCoords = vector3(1005.08, -3196.03, -38.99),
    interiorEntryPos = vector3(997.32, -3200.79, -36.39),
    interiorExitPos = vector3(996.91, -3200.81, -36.39),
    pedSpawnPos = vector3(1004.53, -3196.49, -38.995),
    iplName = "bkr_biker_interior_placement_interior_2_biker_dlc_int_ware01_milo",
    interiorId = 247041,
    purchasePrice = 250000,
    upgradePrice = 150000,
    blip = {
        sprite = 499,
        color = 25,
        scale = 0.8,
        label = 'Meth Lab'
    }
}   

Config.StorageBag = {
    model = 'bkr_prop_meth_bigbag_04a',
    coords = vector3(1003.1271, -3194.231, -39.2015),
    heading = 0.0,
    stashId = 'lab_storage_bag',
    label = 'Lab Storage',
    slots = 50
}   

Config.LabProps = {
    basic = { "meth_lab_empty", "meth_lab_basic" },
    upgraded = { "meth_lab_production", "meth_lab_upgrade", "meth_lab_setup", "meth_lab_product", "meth_lab_security" }
}

Config.Workers = {
    max = 4,
    salary = 500,
    cookInterval = 30,
    model = `S_M_M_HazmatWorker_01`
}

Config.Dealers = {
    max = 3,
    salary = 800,
    maxBaggies = 5,
    sellInterval = 120,
    model = `S_M_Y_Dealer_01`,
    sellLocations = {
        vector3(245.6, -134.9, 54.8),
        vector3(-73.7, -724.1, 31.2),
        vector3(1953.2, 3742.1, 34.2),
        vector3(394.5, 6431.9, 15.9),
        vector3(-251.4, -819.3, 30.4),
        vector3(2527.0, -3176.5, 7.4),
    }
}

Config.Recipes = {
    meth = {
        label = 'Methamphetamine',
        product = 'bkr_prop_meth_bag',
        baseQuality = 50,
        ingredients = {
            { item = 'bkr_prop_meth_sodium', amount = 2 },
            { item = 'bkr_prop_meth_acetone', amount = 1 },
            { item = 'bkr_prop_meth_toulene', amount = 1 },
            { item = 'efedrin', amount = 3 }
        },
        machineConfig = {
            freezerTemp = { min = -20, max = 0, default = -10 },
            heaterTemp = { min = 40, max = 120, default = 80 },
            quantity = { min = 1, max = 25, default = 5 }
        },
        cookTime = 120,
        sellRange = { min = 800, max = 2500 }
    },
    cocaine = {
        label = 'Cocaine',
        product = 'coca',
        baseQuality = 55,
        ingredients = {
            { item = 'bkr_prop_meth_sodium', amount = 1 },
            { item = 'bkr_prop_meth_acetone', amount = 2 },
            { item = 'bkr_prop_meth_hcacid', amount = 1 }
        },
        machineConfig = {
            freezerTemp = { min = -10, max = 10, default = 0 },
            heaterTemp = { min = 30, max = 90, default = 60 },
            quantity = { min = 1, max = 18, default = 4 }
        },
        cookTime = 90,
        sellRange = { min = 1200, max = 3500 }
    },
    oxy = {
        label = 'Oxycodone',
        product = 'bkr_prop_oxy_bag',
        baseQuality = 45,
        ingredients = {
            { item = 'painkillers', amount = 4 },
            { item = 'bkr_prop_meth_ammonia', amount = 1 },
            { item = 'bkr_prop_meth_sacid', amount = 1 }
        },
        machineConfig = {
            freezerTemp = { min = -5, max = 5, default = 0 },
            heaterTemp = { min = 20, max = 60, default = 40 },
            quantity = { min = 1, max = 6, default = 3 }
        },
        cookTime = 60,
        sellRange = { min = 500, max = 1500 }
    },
    pill = {
        label = 'Mixed Pill',
        product = 'bkr_prop_pill_bag',
        baseQuality = 60,
        ingredients = {
            { item = 'bkr_prop_meth_bag', amount = 1 },
            { item = 'bkr_prop_cocaine_bag', amount = 1 },
            { item = 'bkr_prop_oxy_bag', amount = 1 },
            { item = 'painkillers', amount = 2 }
        },
        machineConfig = {
            freezerTemp = { min = -15, max = 5, default = -5 },
            heaterTemp = { min = 30, max = 80, default = 50 },
            quantity = { min = 1, max = 5, default = 3 }
        },
        cookTime = 180,
        sellRange = { min = 3000, max = 8000 }
    }
}

Config.Additives = {
    { name = 'weed_nutrition', min = -10, max = 15 },
    { name = 'aluminumoxide', min = -5, max = 10 },
    { name = 'nitrous', min = -15, max = 20 },
    { name = 'jerry_can', min = -20, max = 5 },
    { name = 'painkillers', min = -5, max = 12 },
    { name = 'saltsyre', min = -10, max = 18 },
    { name = 'efedrin', min = -8, max = 14 },
    { name = 'bkr_prop_meth_lithium', min = -5, max = 12 },
    { name = 'bkr_prop_meth_hcacid', min = -12, max = 10 },
    { name = 'bkr_prop_meth_phosphorus', min = -8, max = 15 },
    { name = 'bkr_prop_meth_ammonia', min = -10, max = 12 },
    { name = 'bkr_prop_meth_sacid', min = -15, max = 10 }
}

Config.Supplies = {
    { item = 'bkr_prop_meth_sodium', label = 'Sodium', price = 50, amount = 5 },
    { item = 'bkr_prop_meth_acetone', label = 'Acetone', price = 80, amount = 3 },
    { item = 'bkr_prop_meth_toulene', label = 'Toluene', price = 80, amount = 3 },
    { item = 'bkr_prop_meth_hcacid', label = 'HCl Acid', price = 60, amount = 3 },
    { item = 'bkr_prop_meth_sacid', label = 'Sulfuric Acid', price = 60, amount = 3 },
    { item = 'bkr_prop_meth_lithium', label = 'Lithium', price = 70, amount = 5 },
    { item = 'bkr_prop_meth_phosphorus', label = 'Phosphorus', price = 65, amount = 5 },
    { item = 'bkr_prop_meth_ammonia', label = 'Ammonia', price = 55, amount = 3 },
    { item = 'efedrin', label = 'Ephedrine', price = 100, amount = 5 },
    { item = 'weed_nutrition', label = 'Weed Nutrition', price = 40, amount = 5 },
    { item = 'aluminumoxide', label = 'Alum. Oxide', price = 45, amount = 5 },
    { item = 'nitrous', label = 'Nitrous', price = 90, amount = 3 },
    { item = 'jerry_can', label = 'Jerry Can', price = 120, amount = 2 },
    { item = 'painkillers', label = 'Painkillers', price = 35, amount = 10 },
    { item = 'saltsyre', label = 'Salt Syrup', price = 30, amount = 5 }
}

Config.TransferMin = 100   