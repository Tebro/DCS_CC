
local dcs_cc = require("dcs_cc")

describe("dcs_cc.initCargoZones()", function()
    it("Sets up cargo zones correctly", function()
        local _zoneIdCounter = 0
        local ZONE = {}
        function ZONE:New(Name)
            _zoneIdCounter = _zoneIdCounter + 1
            o = {id = _zoneIdCounter, name = Name}
            setmetatable(o, self)
            self.__index = self
            return o
        end
        function ZONE:GetName()
            return self.name
        end

        _G.ZONE = ZONE

        _G.config = {}

        dcs_cc.spawnZone = {
            blue = ZONE:New("blueSpawn"),
            red = ZONE:New("redSpawn")
        }
        _G.config.cargoZones = {
            red = {
                "redSpawn",
                "zone1"
            },
            blue = {
                "blueSpawn",
                "zone1"
            }
        }

        local _expected = {
            blue = {
                {id = 1, name = "blueSpawn"},
                {id = 3, name = "zone1"}
            },
            red = {
                {id = 2, name = "redSpawn"},
                {id = 3, name = "zone1"}
            }
        }

        local _result = dcs_cc.initCargoZones()
        assert.are.same(_expected, _result)

    end)
end)