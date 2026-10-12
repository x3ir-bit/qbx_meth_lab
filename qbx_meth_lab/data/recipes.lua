Config = Config or {}

Config.Lab = {
    blip = {
        sprite = 614,
        color = 2,
        scale = 0.8,
        label = 'Meth Lab'
    },
    position = vector4(449.73, -1787.23, 28.78, 241.74),
    interior = 247041,
    purchasePrice = 250000,
    upgradePrice = 150000,
    door = {
        position = vector4(449.73, -1787.23, 28.78, 241.74),
        heading = 241.74
    },
    laptop = {
        model = 'bkr_prop_clubhouse_laptop_01a',
        offset = vector3(0.0, 0.0, 0.0)
    }
}

Config.Additives = {
    { name = 'weed_nutrition',    min = -10, max = 15 },
    { name = 'aluminumoxide',    min = -5,  max = 10 },
    { name = 'nitrous',          min = -15, max = 20 },
    { name = 'jerry_can',        min = -20, max = 5 },
    { name = 'painkillers',      min = -5,  max = 12 },
    { name = 'saltsyre',         min = -10, max = 18 },
    { name = 'efedrin',          min = -8,  max = 14 },
    { name = 'bkr_prop_meth_lithium',  min = -5, max = 12 },
    { name = 'bkr_prop_meth_hcacid',   min = -12, max = 10 },
    { name = 'bkr_prop_meth_phosphorus', min = -8, max = 15 },
    { name = 'bkr_prop_meth_ammonia',  min = -10, max = 12 },
    { name = 'bkr_prop_meth_sacid',   min = -15, max = 10 }
}

Config.Recipes = {
    meth = {
        label = 'Methamphetamine',
        product = 'meth_baggie',
        baseQuality = 50,
        ingredients = {
            { item = 'bkr_prop_meth_sodium',  amount = 2 },
            { item = 'bkr_prop_meth_acetone', amount = 1 },
            { item = 'bkr_prop_meth_toulene', amount = 1 },
            { item = 'efedrin',               amount = 3 }
        },
        machineConfig = {
            freezerTemp = { min = -20, max = 0,   default = -10 },
            heaterTemp  = { min = 40,  max = 120, default = 80 },
            quantity    = { min = 1,   max = 10,  default = 5 }
        },
        cookTime = 120,
        sellRange = { min = 800, max = 2500 }
    },
    cocaine = {
        label = 'Cocaine',
        product = 'coke_baggie',
        baseQuality = 55,
        ingredients = {
            { item = 'bkr_prop_meth_sodium',  amount = 1 },
            { item = 'bkr_prop_meth_acetone', amount = 2 },
            { item = 'bkr_prop_meth_hcacid',  amount = 1 }
        },
        machineConfig = {
            freezerTemp = { min = -10, max = 10,  default = 0 },
            heaterTemp  = { min = 30,  max = 90,  default = 60 },
            quantity    = { min = 1,   max = 8,   default = 4 }
        },
        cookTime = 90,
        sellRange = { min = 1200, max = 3500 }
    },
    oxy = {
        label = 'Oxycodone',
        product = 'oxy_baggie',
        baseQuality = 45,
        ingredients = {
            { item = 'painkillers',           amount = 4 },
            { item = 'bkr_prop_meth_ammonia', amount = 1 },
            { item = 'bkr_prop_meth_sacid',  amount = 1 }
        },
        machineConfig = {
            freezerTemp = { min = -5, max = 5,   default = 0 },
            heaterTemp  = { min = 20, max = 60,  default = 40 },
            quantity    = { min = 1,  max = 6,   default = 3 }
        },
        cookTime = 60,
        sellRange = { min = 500, max = 1500 }
    },
    pill = {
        label = 'Mixed Pill',
        product = 'mixed_pill',
        baseQuality = 60,
        ingredients = {
            { item = 'meth_baggie',  amount = 1 },
            { item = 'coke_baggie',  amount = 1 },
            { item = 'oxy_baggie',   amount = 1 },
            { item = 'painkillers',  amount = 2 }
        },
        machineConfig = {
            freezerTemp = { min = -15, max = 5,  default = -5 },
            heaterTemp  = { min = 30,  max = 80, default = 50 },
            quantity    = { min = 1,   max = 5,  default = 3 }
        },
        cookTime = 180,
        sellRange = { min = 3000, max = 8000 }
    }
}

Config.Workers = {
    max = 4,
    salary = 500,
    cookInterval = 300
}

Config.Dealers = {
    max = 3,
    salary = 800,
    maxBaggies = 20,
    sellInterval = 120
}

Config.Supplies = {
    { item = 'bkr_prop_meth_sodium',   price = 50,   amount = 5 },
    { item = 'bkr_prop_meth_acetone',  price = 80,   amount = 3 },
    { item = 'bkr_prop_meth_toulene',  price = 80,   amount = 3 },
    { item = 'bkr_prop_meth_hcacid',   price = 60,   amount = 3 },
    { item = 'bkr_prop_meth_sacid',    price = 60,   amount = 3 },
    { item = 'bkr_prop_meth_lithium',  price = 70,   amount = 5 },
    { item = 'bkr_prop_meth_phosphorus', price = 65, amount = 5 },
    { item = 'bkr_prop_meth_ammonia',  price = 55,   amount = 3 },
    { item = 'efedrin',                price = 100,  amount = 5 },
    { item = 'weed_nutrition',         price = 40,   amount = 5 },
    { item = 'aluminumoxide',          price = 45,   amount = 5 },
    { item = 'nitrous',                price = 90,   amount = 3 },
    { item = 'jerry_can',              price = 120,  amount = 2 },
    { item = 'painkillers',            price = 35,   amount = 10 },
    { item = 'saltsyre',               price = 30,   amount = 5 }
}   