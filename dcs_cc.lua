
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
    local _spawn = SPAWN:New(Details.group[Side])
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
        MESSAGE:New("Cargo unloading", 10):ToGroup(Group)
    else
        MESSAGE:New("Land first dummy...", 10):ToGroup(Group)
    end
end

function dcs_cc.buyAsCargo(Item, Coalition, Group)
    local _side = dcs_cc.getCoalitionName(Coalition)
    local _unit = Group:GetPlayerUnits()[1]
    if _unit ~= nil then
        if dcs_cc.transportGroups[Group.GroupName] == nil then
            if _unit:IsInZone(dcs_cc.spawnZone[_side]) and _unit:InAir() == false then
                local _details = dcs_cc.objects[Item]

                local _enoughResources, _newBalance = dcs_cc.updateBalance(_side, _details.price)
                local _cargoGroup = nil


                if _enoughResources then

                    --if _details.crates and _details.crates > 0 then
                    --    -- TODO crates
                    --else
                        local _spawnedGroup = dcs_cc.spawnGroup(_details, _side)
                        _cargoGroup = CARGO_GROUP:New(_spawnedGroup, "Cargo", "Cargo " .. dcs_cc.getCargoIndex())
                        _cargoGroup:Board(_unit, 25)
                        MESSAGE:New("The cargo is on the way", 10):ToGroup(Group)
                        local _menuCommand = MENU_GROUP_COMMAND:New(Group, "Unload Cargo", nil, dcs_cc.unloadCargo, _cargoGroup, Group)
                        dcs_cc.transportGroups[Group.GroupName] = _menuCommand
                    --end
                else
                    MESSAGE:New("Not enough resources", 10):ToGroup(Group)
                end

            else
                MESSAGE:New("You are not in the correct zone", 10):ToGroup(Group)
            end
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
                    env.info("Adding cargo buying for: " .. _groupName, GLOBAL_DEBUG_MODE)
                    local _buyAsCargoMenu = MENU_GROUP:New(_group, "Buy as cargo", _mainMenu)

                    for item, details in pairs(dcs_cc.objects) do
                        if details.group[_side] ~= nil and details.transportable then
                            local _title = item .. ": " .. details.price
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