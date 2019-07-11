
basePath = "C:\\Users\\Richard\\DCS_MISSIONS\\DCS_CC"

function loadScript()
    assert(loadfile(basePath .. "\\dev_config.lua"))()
    assert(loadfile(basePath .. "\\dcs_cc.lua"))()
end

-- Load it once
loadScript()

-- Setup radio option to reload it

--devMenu = MENU_MISSION:New("DCS_CC DEVELOPMENT")
--MENU_MISSION_COMMAND:New("Reload scripts", devMenu, loadScript, nil)
