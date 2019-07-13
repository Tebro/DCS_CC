
if GLOBAL_MOOSE_DEBUG then
    BASE:TraceOnOff(true)
    BASE:TraceAll(true)
    BASE:TraceLevel(2)
end


env.info("LOADING DCS_CC", GLOBAL_DEBUG_MODE)

dcs_cc = {}

dcs_cc.banks = {}
dcs_cc.banks.red = config.startingResources
dcs_cc.banks.blue = config.startingResources

dcs_cc.coalitions = {
    coalition.side.BLUE,
    coalition.side.RED,
}

dcs_cc.objects = config.objects 

dcs_cc.spawnZone = {
    ["blue"] = ZONE:New(config.spawnZone.blue),
    ["red"] = ZONE:New(config.spawnZone.red),
}

dcs_cc.captureZones = {}
dcs_cc.transportGroups = {}
dcs_cc.unitZones = {}
dcs_cc.crates = {
    ["red"] = {},
    ["blue"] = {}
}

function dcs_cc.initCargoZones(Side)
    local _result = {}
    for _, _zone in pairs(config.cargoZones[Side]) do
        table.insert(_result, ZONE:New(_zone))
    end
    return _result
end

dcs_cc.cargoZones = {
    ["red"] = dcs_cc.initCargoZones("red"),
    ["blue"] = dcs_cc.initCargoZones("blue")
}

dcs_cc.spawners = {}

function dcs_cc.getSpawner(Template)
    if dcs_cc.spawners[Template] == nil then
        dcs_cc.spawners[Template] = SPAWN:New(Template)
    end
    return dcs_cc.spawners[Template]
end

function dcs_cc.getCoalitionName(Coalition)
    if Coalition == coalition.side.BLUE then
        return "blue"
    end
    return "red"
end

function dcs_cc.getMooseCoalition( Side )
    if Side == "red" then
        return coalition.side.RED
    end
    return coalition.side.BLUE
end

function dcs_cc.coalitionBalance(Coalition)
    local _balance = dcs_cc.banks[dcs_cc.getCoalitionName(Coalition)]
    local msg = MESSAGE:New("Balance: " .. _balance, 10)
    msg:ToCoalition(Coalition)
end

function dcs_cc.spawnGroup(Details, Side)
    local _spawn = dcs_cc.getSpawner(Details.group[Side])
    local _spawnedGroup = _spawn:SpawnInZone(dcs_cc.spawnZone[Side], true)
    return _spawnedGroup
end

function dcs_cc.updateBalance(Side, Price)
    local _newBalance = dcs_cc.banks[Side] - Price
    if _newBalance >= 0 then
        dcs_cc.banks[Side] = _newBalance
        return true, _newBalance
    end
    return false, -1
end

function dcs_cc.buyItem(Item, Coalition)
    local _side = dcs_cc.getCoalitionName(Coalition)
    env.info("Shopping for " .. _side)
    local _details = dcs_cc.objects[Item]
    local _price = _details.price

    local _enoughResources, _newBalance = dcs_cc.updateBalance(_side, _price)

    if _enoughResources then
        dcs_cc.spawnGroup(_details, _side)
        local msg = MESSAGE:New(Item .. " bought for " .. _price .. ", new balance is: " .. _newBalance .. ", please stand by as they are delivered", 10)
        msg:ToCoalition(Coalition)
    else
        local msg = MESSAGE:New("You do not have enough funds to buy " .. Item .. ". Balance is " .. dcs_cc.banks[_side] .. " but the cost for that item is ".. _price, 10)
    end
end

dcs_cc.cargoIdx = 0

function dcs_cc.getCargoIndex()
    dcs_cc.cargoIdx = dcs_cc.cargoIdx + 1
    return dcs_cc.cargoIdx
end

function dcs_cc.unloadCargo(CargoGroup, Group)
    local _unit = Group:GetPlayerUnits()[1]
    if _unit:InAir() == false then
        local _menuCommand = dcs_cc.transportGroups[Group.GroupName]
        CargoGroup:UnBoard()
        _menuCommand:Remove()
        dcs_cc.transportGroups[Group.GroupName] = nil
        MESSAGE:New("Cargo unloading", 10):ToGroup(Group)
    else
        MESSAGE:New("Land first dummy...", 10):ToGroup(Group)
    end
end

function dcs_cc.addCrateToCoalition(Side, CargoDetails, Crate, StaticName)
    table.insert(dcs_cc.crates[Side],  {
        ["crate"] = Crate, 
        ["details"] = CargoDetails,
        ["staticName"] = StaticName
    })
end

function dcs_cc.unloadCrate(Side, CargoType, StaticSpawn, Group)
    local _unit = Group:GetPlayerUnits()[1]
    local _pos = _unit:GetCoordinate()
    local _altitude = _unit:GetAltitude() - _pos:GetLandHeight()
    if _altitude < 20 then
        local _cratePos = _unit:GetPointVec2():AddX(20):SetAlt()
        local _staticName = CargoType .. dcs_cc.getCargoIndex()
        local _crate = StaticSpawn:SpawnFromPointVec2(_cratePos, 0, _staticName)

        local _details = dcs_cc.objects[CargoType]
        dcs_cc.addCrateToCoalition(Side, _details, _crate, _staticName)

        local _menuCommand = dcs_cc.transportGroups[Group.GroupName]
        _menuCommand:Remove()
        dcs_cc.transportGroups[Group.GroupName] = nil
        MESSAGE:New("Crate dropped", 10):ToGroup(Group)
    else
        MESSAGE:New("Must be within correct altitude", 10):ToGroup(Group)
    end
end

function dcs_cc.spawnFromCrate(Side, Crate)
    local _static = STATIC:FindByName(Crate.staticName, true)
    local _spawn = dcs_cc.getSpawner(Crate.details.group[Side])
    local _pos = _static:GetPointVec2()
    _spawn:SpawnFromStatic(_static)
    _static:Destroy(false)


    for _i, _crate in pairs(dcs_cc.crates[Side]) do
        if _crate.staticName == Crate.staticName then
            table.remove(dcs_cc.crates[Side], _i)
            break
        end
    end
end

-- Brutal copy paste from: https://stackoverflow.com/questions/24821045/does-lua-have-something-like-pythons-slice
function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

function dcs_cc.spawnFromMultipleCrates(Side, Crates)
    local _requiredCrates = Crates[1].details.crates
    local _selectedCrates = table.slice(Crates, 2, _requiredCrates) -- select one less for just deleting

    dcs_cc.spawnFromCrate(Side, Crates[1])

    for _, _c in pairs(_selectedCrates) do
        local _static = STATIC:FindByName(_c.staticName, true)
        _static:Destroy(false)
        for _i, _crate in pairs(dcs_cc.crates[Side]) do
            if _crate.staticName == _c.staticName then
                table.remove(dcs_cc.crates[Side], _i)
                break
            end
        end
    end

end

function dcs_cc.unpackCrate(Group, Coalition)
    local _side = dcs_cc.getCoalitionName(Coalition)
    local _zone = dcs_cc.unitZones[Group.GroupName]

    local _cratesInZone = {}
    for _, _crate in pairs(dcs_cc.crates[_side]) do
        local _static = STATIC:FindByName(_crate.staticName, true)
        if _zone:IsVec2InZone(_static:GetVec2()) then
            table.insert(_cratesInZone, _crate)
        end
    end

    local _countedByTemplate = {}

    for _, _crate in pairs(_cratesInZone) do
        if _crate.details.crates == 1 then -- shortcut if a single crate package is found
            dcs_cc.spawnFromCrate(_side, _crate)
            MESSAGE:New("Crate unpacked", 10):ToGroup(Group)
            return
        end
        local _template = _crate.details.group[_side]
        if _countedByTemplate[_template] then
            table.insert(_countedByTemplate[_template], _crate)
        else
            _countedByTemplate[_template] = {_crate}
        end
    end

    for _template, _crates in pairs(_countedByTemplate) do
        local _requiredCrates = _crates[1].details.crates
        if table.getn(_crates) >= _requiredCrates then
            dcs_cc.spawnFromMultipleCrates(_side, _crates)
            MESSAGE:New("Crates unpacked", 10):ToGroup(Group)
            return
        end
    end

    MESSAGE:New("No viable crates nearby", 10):ToGroup(Group)
end

function dcs_cc.getCargoPrice(Details)
    if Details.crates and Details.crates > 0 then
        return Details.price/Details.crates
    end
    return Details.price
end

function dcs_cc.buyAsCargo(Item, Coalition, Group)
    local _side = dcs_cc.getCoalitionName(Coalition)
    local _unit = Group:GetPlayerUnits()[1]
    if _unit ~= nil then
        if dcs_cc.transportGroups[Group.GroupName] == nil then
            for _, _zone in pairs(dcs_cc.cargoZones[_side]) do
                if _unit:IsInZone(_zone) and _unit:InAir() == false then
                    local _details = dcs_cc.objects[Item]
                    local _price = dcs_cc.getCargoPrice(_details)

                    local _enoughResources, _newBalance = dcs_cc.updateBalance(_side, _price)
                    local _cargoGroup = nil

                    if _enoughResources then

                        if _details.crates and _details.crates > 0 then
                            local _country = Group:GetCountry()
                            local _staticSpawn = SPAWNSTATIC:NewFromStatic(config.crateTemplate[_side], _country, Coalition)
                            MESSAGE:New("Crate has been loaded!", 10):ToGroup(Group)
                            local _menuCommand = MENU_GROUP_COMMAND:New(Group, "Unload Crate", nil, dcs_cc.unloadCrate, _side, Item, _staticSpawn, Group)
                            dcs_cc.transportGroups[Group.GroupName] = _menuCommand
                        else
                            local _spawnedGroup = dcs_cc.spawnGroup(_details, _side)
                            _cargoGroup = CARGO_GROUP:New(_spawnedGroup, "Cargo", "Cargo " .. dcs_cc.getCargoIndex())
                            _cargoGroup:Board(_unit, 25)
                            MESSAGE:New("The cargo is on the way", 10):ToGroup(Group)
                            local _menuCommand = MENU_GROUP_COMMAND:New(Group, "Unload Cargo", nil, dcs_cc.unloadCargo, _cargoGroup, Group)
                            dcs_cc.transportGroups[Group.GroupName] = _menuCommand
                        end
                    else
                        MESSAGE:New("Not enough resources", 10):ToGroup(Group)
                    end
                    return -- skip the rest to prevent invalid messages
                end
            end
            -- In no zone
            MESSAGE:New("You are not in the correct zone", 10):ToGroup(Group)
        else
            MESSAGE:New("You are already carrying cargo!", 10):ToGroup(Group)
        end
    end
end

-- setup menu
for _, _coalition in pairs(dcs_cc.coalitions) do
    local _mainMenu = MENU_COALITION:New(_coalition, "DCS Command & Conquer")
    local _side = dcs_cc.getCoalitionName(_coalition)

    MENU_COALITION_COMMAND:New(_coalition, "Balance", _mainMenu, dcs_cc.coalitionBalance, _coalition)

    local _buyMenu = MENU_COALITION:New(_coalition, "Buy", _mainMenu)

    for item, details in pairs(dcs_cc.objects) do
        if details.group[_side] ~= nil then
            env.info("Adding item: " .. item .. " to side: " .. _side, GLOBAL_DEBUG_MODE)
            local _title = item .. ": " .. details.price
            MENU_COALITION_COMMAND:New(_coalition, _title, _buyMenu, dcs_cc.buyItem, item, _coalition)
        end
    end
    
    for _, _groupName in pairs(config.transportGroups[_side]) do
        dcs_cc.transportGroups[_groupName] = nil
        SCHEDULER:New(nil,
            function()
                local _group = GROUP:FindByName(_groupName)
                if _group and _group:IsAlive() then
                    local _unit = _group:GetPlayerUnits()[1]
                    function _unit:OnEventDead(EventData)
                        dcs_cc.transportGroups[_groupName] = nil
                        dcs_cc.unitZones[_groupName] = nil
                    end
                    if dcs_cc.unitZones[_groupName] == nil then
                        dcs_cc.unitZones[_groupName] = ZONE_UNIT:New(_groupName, _unit, 100, {})
                    end

                    MENU_GROUP_COMMAND:New(_group, "Unpack crate", nil, dcs_cc.unpackCrate, _group, _coalition)

                    local _buyAsCargoMenu = MENU_GROUP:New(_group, "Buy as cargo", _mainMenu)

                    for item, details in pairs(dcs_cc.objects) do
                        if details.group[_side] ~= nil and details.transportable then
                            local _title = ""
                            if details.crates and details.crates > 0 then
                                _title = item .. ": " .. dcs_cc.getCargoPrice(details) .. " (crates required: " .. details.crates .. ")"
                            else
                                _title = item .. ": " .. dcs_cc.getCargoPrice(details)
                            end
                            MENU_GROUP_COMMAND:New(_group, _title, _buyAsCargoMenu, dcs_cc.buyAsCargo, item, _coalition, _group)
                        end
                    end
                end
            end, {}, 10, 10)
    end
end

-- Start Capture Zones

for _zone, _side in pairs(config.captureZones) do
    local _triggerZone = ZONE:New(_zone)
    local _coalition = dcs_cc.getMooseCoalition(_side)

    local _captureZone = ZONE_CAPTURE_COALITION:New(_triggerZone, _coalition)
    -- Start the zone monitoring process in 30 seconds and check every 30 seconds.
    _captureZone:Start(30, 30)
    _captureZone:Mark()
    table.insert(dcs_cc.captureZones, _captureZone)
end

function dcs_cc.tickResources()
    env.info("RUNNING TICKS", GLOBAL_DEBUG_MODE)
    local _redTickAmount = config.baseResourceGeneration
    local _blueTickAmount = config.baseResourceGeneration

    for _, _captureZone in pairs(dcs_cc.captureZones) do
        if _captureZone:IsGuarded() then
            local _tickAmount = config.zoneResourceGeneration

            if _captureZone:GetCoalition() == coalition.side.RED then
                _redTickAmount = _redTickAmount + _tickAmount
            else
                _blueTickAmount = _blueTickAmount + _tickAmount
            end
        end
    end

    dcs_cc.banks.red = dcs_cc.banks.red + _redTickAmount
    dcs_cc.banks.blue = dcs_cc.banks.blue + _blueTickAmount

    MESSAGE:New("Resources gained, Blue: " .. _blueTickAmount .. ", Red: " .. _redTickAmount, 10):ToAll()
end

-- Resource ticking
SCHEDULER:New(nil, dcs_cc.tickResources, {}, config.resourceTickSeconds, config.resourceTickSeconds):Start()
env.info("LOADING DCS_CC FINISHED", GLOBAL_DEBUG_MODE)
MESSAGE:New("Ready to Command & Conquer", 10):ToAll()