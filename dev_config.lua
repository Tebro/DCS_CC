-- Set to true to get alert boxes with log messages
GLOBAL_DEBUG_MODE = false

config = {}

config.startingResources = 10000

config.warehouses = {
    ["blue"] = "BlueWarehouse",
    ["red"] = "RedWarehouse"
}

-- Configuration of buyable groups
config.objects = {
    ["Tank Group"] = {
        ["price"] = 1000,
        -- A group name referencing a late activated group placed in the mission
        ["group"] = {
            ["blue"] = "TanksTemplate",
        }
    },
}