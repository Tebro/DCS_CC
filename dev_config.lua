-- Set to true to get alert boxes with log messages
GLOBAL_DEBUG_MODE = false
GLOBAL_MOOSE_DEBUG = false

config = {}


config.startingResources = 10000

config.baseResourceGeneration = 100
config.zoneResourceGeneration = 300
config.resourceTickSeconds = 60

-- The name of each sides warehouse
config.spawnZone = {
    ["blue"] = "BlueSpawn",
    ["red"] = "RedSpawn"
}

config.cargoZones = {
    ["blue"] = {
        "BlueSpawn",
        "Zone5"
    },
    ["red"] = {
        "RedSpawn",
        "Zone5"
    }
}

config.transportGroups = {
    ["red"] = {
        "transport2",
        "transport5",
        "transport6",
        "transport7"
    },
    ["blue"] = {
        "transport1",
        "transport3",
        "transport4",
        "transport8"
    }
}

-- The available capture zones (trigger zone names) and initial owner
-- Owning it does not generate resource, but it is a must have anyway
config.captureZones = {
    ["Zone1"] = "blue",
    ["Zone2"] = "red",
    ["Zone3"] = "red",
    ["Zone4"] = "blue",
    ["Zone5"] = "blue",
    ["Zone6"] = "blue"
}

-- Name of static objects representing cargo crates
config.crateTemplate = {
    ["red"] = "Crate",
    ["blue"] = "Crate"
}

-- Configuration of buyable groups
config.objects = {
    ["Tank Group"] = {
        ["price"] = 3000,
        ["transportable"] = true,
        ["crates"] = 2,
        -- A group name referencing a late activated group placed in the mission
        ["group"] = {
            ["blue"] = "BlueTanksTemplate",
            ["red"] = "RedTanksTemplate"
        }
    },
    ["APC Group"] = {
        price = 750,
        transportable = true,
        crates = 1,
        group = {
            blue = "BlueAPC",
            red = "RedAPC"
        }
    },
    ["IFV Group"] = {
        price = 2000,
        transportable = true,
        crates = 2,
        group = {
            blue = "BlueIFV",
            red = "RedIFV"
        }
    },
    ["Support Group"] = {
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
    },
    ["Hawk"] = {
        price = 6000,
        transportable = true,
        crates = 3,
        group = {
            blue = "BlueHawk"
        }
    },
    ["SA6"] = {
        ["price"] = 6000,
        ["transportable"] = true,
        ["crates"] = 3,
        ["group"] = {
            ["red"] = "RedSA6",
        }
    },
    ["Short range SAM"] = {
        price = 3000,
        transportable = true,
        crates = 1,
        group = {
            red = "RedShortSAM",
            blue = "BlueShortSAM"
        }
    },
    ["Mobile AAA"] = {
        price = 1500,
        transportable = true,
        crates = 1,
        group = {
            red = "RedAAA",
            blue = "BlueAAA"
        }
    },
    ["JTAC"] = {
        price = 1000,
        transportable = true,
        crates = 1,
        group = {
            blue = "BlueJTAC",
            red = "RedJTAC"
        }
    },
--    ["Stinger team"] = {
--        ["price"] = 3000,
--        ["transportable"] = true,
--        ["crates"] = 1,
--        ["group"] = {
--            ["blue"] = "BlueStinger",
--            ["red"] = "RedStinger"
--        }
--    },
}
