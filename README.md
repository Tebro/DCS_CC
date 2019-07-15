# DCS_CC
DCS Command and Conquer

A framework to help mission designers to create PvP missions focusing on ground units and area control.


# Getting started

This will try and help you get started creating missions using this tooling.

## Configuration

To use this tooling you need to create some things in the mission editor and then link them to the framework using a configuration file.

It is recommended that you use the dev_config.lua as a starting point, it is what is used during the development and has examples of all available configuration.

### Basic options

First some basic options that must be specified.

#### `config.startingResources`

How many resources should the teams start with?

#### `config.baseResourceGeneration`

How many resources should each team get each tick no matter what

#### `config.zoneResourceGeneration`

How many resources should each team get for each capture zone they control each tick.

More on capture zones later.

#### `config.resourceTickSeconds`

How often should the teams gain resources based on the values above. Value is in seconds.

### `config.spawnZone` AKA the base

This is a table containing the names of the trigger zones (in the mission editor) where the teams bought units should spawn. This can be considered the main base.

### `config.cargoZones`

This lists which trigger zones can be used by each team to buy cargo, at least the spawnZones should be listed here, but it is up to the mission designer.

Note that if a cargo zone is also listed as a capture zone the team has to control the zone before they can buy there. More on capture zones later.

### `config.transportGroups`

This contains the names of the groups that can transport cargo, these groups MUST contain only one unit each. So if you want to have 4 helicopters that can transport cargo, you must create 4 groups with one helicopter each and list their names here.

### `config.captureZones`
This is a table/map where the key is the name of the trigger zone from the mission editor, and the value is either "red" or "blue", it is a technical requirement to specify the inital owner, but it does not generate money for any side until they are controlling it by having units inside.

As mentioned above if you list a zone name here as well as in the cargo zone listing the team must control the zone to be able to buy cargo in it.

NOTICE: Do not place FARPs inside capture zones at this time, it breaks them and is a known issue.

### `config.crateTemplate`

This is a static object that is placed in the mission editor, you can use the same object for both sides, and the "Container" is a pretty good fit.


### Group templates for shopping

Teams are able to buy ground units, either directly at their base, or as cargo for transports to ship closer to the front.

To specify what kind of groups the players can buy you need to fill out the `config.objects` variable in your config file.

The variable is a lua table and in this case used as a map, with the key being the name of the buyable group, and the value being another table/map defining the options.

The `group` key holds a table/map with keys being either "red" or "blue" (or both) and the value is the name of a group in the mission editor. The group should be late activated so that it does not exist in the game, only as a template from which more groups can be spawned.

Example:
```lua
config.objects = {
    ["Tank group"] = {
        ["price"] = 1000,
        ["transportable"] = true,
        ["crates"] = 2,
        ["group"] = {
            ["blue"] = "SomeBlueGroupWithTanks",
            ["red"] = "SomeRedGroupWithTanks"
        }
    }
}
```

So when a player on the blue opens the shopping menu there will be an option to buy a "Tank group", it will cost the team 1000 resources, it can be bought as cargo, and requires two crates to be transported to the same location. When bought (or unpacked from crates) it will result in a group matching the "SomeBlueGroupWithTanks" that the mission creator specified.

## Script loading

After you have completed setting up your config file, you need to load the scripts into your mission.

1. Set up a trigger, which uses a "TIME MORE" condition to load MOOSE, these scripts are currently developed using the version in this repository so it would be a safe bet to use that same version.

2. Set up another trigger, with a bit more in "TIME MORE" than before that loads your config file.

3. Set up one last trigger, again with more time in "TIME MORE" that loads the dcs_cc.lua script.


# Contributors

- [Tebro](https://github.com/Tebro)
- [mBloodnok](https://github.com/mBloodnok)
