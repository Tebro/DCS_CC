
local dcs_cc = require("dcs_cc")

describe("dcs_cc", function() 
    -- Some global config and mocks
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
    _G.coalition = {
        side = {
            BLUE = 1,
            RED = 2
        }
    }

    dcs_cc.spawnZone = {
        blue = ZONE:New("blueSpawn"),
        red = ZONE:New("redSpawn")
    }

    describe("dcs_cc.initCargoZones()", function()
        it("Sets up cargo zones correctly", function()

            _G.config = {}
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

    describe("dcs_cc.getCoalitionName()", function()
        it("returns the right string", function()
            assert.are.equal("red", dcs_cc.getCoalitionName(coalition.side.RED))
            assert.are.equal("blue", dcs_cc.getCoalitionName(coalition.side.BLUE))
        end)
    end)
end)