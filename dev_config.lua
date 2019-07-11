-- Set to true to get alert boxes with log messages
GLOBAL_DEBUG_MODE = false
GLOBAL_MOOSE_DEBUG = false

config = {}


config.startingResources = 10000

config.baseResourceGeneration = 200
config.zoneResourceGeneration = 100
config.resourceTickSeconds = 60

-- The name of each sides warehouse
config.spawnZone = {
    ["blue"] = "BlueSpawn",
    ["red"] = "RedSpawn"
}

config.transportGroups = {
    ["red"] = {
        "transport2",
        "transport5"
    },
    ["blue"] = {
        "transport1",
        "transport3",
        "transport4"
    }
}

-- The available capture zones (trigger zone names) and initial owner
-- Owning is does not generate resource, but is a must have anyway
config.captureZones = {
    ["Zone1"] = "blue",
    ["Zone2"] = "red",
    ["Zone3"] = "red",
    ["Zone4"] = "blue",
    ["Zone5"] = "blue",
}

-- Name of static objects representing cargo crates
config.crateTemplate = {
    ["red"] = "Crate",
    ["blue"] = "Crate"
}

-- Configuration of buyable groups
config.objects = {
    ["Tank Group"] = {
        ["price"] = 1000,
        ["transportable"] = true,
        ["crates"] = 2,
        -- A group name referencing a late activated group placed in the mission
        ["group"] = {
            ["blue"] = "BlueTanksTemplate",
            ["red"] = "RedTanksTemplate"
        }
    },
    ["Truck Group"] = {
        ["price"] = 50,
        ["transportable"] = true,
        ["crates"] = 1,
        ["group"] = {
            ["blue"] = "BlueTrucksTemplate",
            ["red"] = "RedTrucksTemplate"
        }
    },
    ["Infantry Squad"] = {
        ["price"] = 100,
        ["transportable"] = true,
        ["group"] = {
            ["blue"] = "BlueSquadTemplate",
            ["red"] = "RedSquadTemplate"
        }
    }
}