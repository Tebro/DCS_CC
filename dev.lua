
basePath = "C:\\Users\\Richard\\DCS_MISSIONS\\DCS_CC"

function loadScript()
    assert(loadfile(basePath .. "\\dev_config.lua"))()
    assert(loadfile(basePath .. "\\dcs_cc.lua"))()
end

-- Load it once
loadScript()


-- run the start function
dcs_cc.start()
