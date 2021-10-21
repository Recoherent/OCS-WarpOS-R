local constants = {}

constants.mainOptions = { "Settings", "Navigation", "Map", "Crew", "Advanced" }

constants.settingOptions = { "Set dimensions", "Set name" }

constants.navOptions = { "Jump", "Set target", "Set movement", "Hyperdrive" }

constants.mapOptions = { "Load coordinates from disk", "Save coordinates to memory", "Set cursor as jump target" }

constants.crewOptions = { "<NOT IMPLEMENTED>" }

constants.advancedOptions = { "Maintenance mode", "Disable core", "Install to drive" }

constants.rotationValues = {
    {"Front", "w"},
    {"Right +90deg", "d"},
    {"Back +180deg", "s"},
    {"Left -90deg", "a"}
}

return constants