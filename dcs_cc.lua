
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

dcs_cc.warehouses = {
    ["red"] = WAREHOUSE:New(STATIC:FindByName(config.warehouses.red)),
    ["blue"] = WAREHOUSE:New(STATIC:FindByName(config.warehouses.blue)),
}

dcs_cc.captureZones = {}

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

function dcs_cc.addObjectToCoalitionWarehouse(Details, Side)
    local _warehouse = dcs_cc.warehouses[Side]
    local _group = GROUP:FindByName(Details.group[Side])
    _warehouse:AddAsset(_group, 1)
end

function dcs_cc.buyItem(Item, Coalition)
    local _side = dcs_cc.getCoalitionName(Coalition)
    env.info("Shopping for " .. _side)
    local _details = dcs_cc.objects[Item]
    local _price = _details.price

    local _newBalance = dcs_cc.banks[_side] - _price

    if _newBalance >= 0 then
        dcs_cc.banks[_side] = _newBalance
        dcs_cc.addObjectToCoalitionWarehouse(_details, _side)
        local msg = MESSAGE:New(Item .. " bought for " .. _price .. ", new balance is: " .. _newBalance .. ", please stand by as they are delivered", 10)
        msg:ToCoalition(Coalition)
        return _newBalance
    else
        local msg = MESSAGE:New("You do not have enough funds to buy " .. Item .. ". Balance is " .. dcs_cc.banks[_side] .. " but the cost for that item is ".. _price, 10)
        return dcs_cc.banks[_side]   
    end
end


function dcs_cc.requestGroup(Group, Coalition)
    local _side = dcs_cc.getCoalitionName(Coalition)
    local _warehouse = dcs_cc.warehouses[_side]
    local _groupName = dcs_cc.objects[Group].group[_side]

    local _numAvailable = _warehouse:GetNumberOfAssets(WAREHOUSE.Descriptor.GROUPNAME, _groupName)

    if _numAvailable > 0 then
        _warehouse:AddRequest(_warehouse, WAREHOUSE.Descriptor.GROUPNAME, _groupName)
        local msg = MESSAGE:New("Bringing out units from warehouse, they will be available shortly...", 10)
        msg:ToCoalition(Coalition)
    else
        MESSAGE:New("No units available...", 10):ToCoalition(Coalition)
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
    
    local _spawnMenu = MENU_COALITION:New(_coalition, "Spawn", _mainMenu)

    for _item, _ in pairs(dcs_cc.objects) do
        MENU_COALITION_COMMAND:New(_coalition, _item, _spawnMenu, dcs_cc.requestGroup, _item, _coalition)
    end
end

-- Start warehouses
for _, warehouse in pairs(dcs_cc.warehouses) do
    warehouse:Start()
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