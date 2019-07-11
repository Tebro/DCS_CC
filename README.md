# DCS_CC
DCS Command and Conquer


## Dev Setup

- Create a new mission
- Add a trigger zone for both teams (where they can buy units)
- Update the dev_config.lua config.spawnZone with said zones
- Create late activated groups as templates for shopping
- Update the config file with these groups
- Create more trigger zones as captureZones (you guessed it, also in the config)
- Create a static object (I recommend the Container type) and fill that into config.crateTemplate (this is needed for transport crates) (can use the same object for both sides)
- Create a trigger where you load Moose.lua
- Create a trigger that loads dev.lua