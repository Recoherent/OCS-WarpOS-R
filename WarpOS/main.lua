--i'm recoherent, and i'll be your commentator for today
local t = require("terminal")
local colors = require("colors")
local const = require("constants")
local map = require("map")
local gpu = gpu
local core = core
local screen = screen
local computer = computer
local tier = tier

local page = "main"
local loadedCoordinates = {}

local w, h = gpu.getResolution()



local function getKey()
    while true do
        local name, _, char = computer.pullSignal(5)
        if name == "key_down" then
            return string.char(char), char
        end
        reloadComponents()
        if not gpu.getScreen() then
            local bg = gpu.getBackground()
            local fg = gpu.getForeground()

            if bg == nil then
                bg = 0x000000
            end
            if fg == nil then
                fg = 0xFFFFFF
            end

            gpu.bind(screen.address)
            gpu.setBackground(bg)
            gpu.setForeground(fg)
        end
    end
end

local function getText()
    local buffer = ""
    while true do
        local key = getKey()
        if key == "\13" then
            t.print("")
            return buffer
        elseif key == "\8" and buffer ~= "" then
            local x, y = t.getCursor()
            t.setCursor(x - 1, y)
            gpu.set(x - 1, y, " ")
            buffer = string.sub(buffer, 1, -2)
        elseif string.byte(key) > 31 and string.byte(key) ~= 127 then
            buffer = buffer .. key
            t.write(key)
        end
    end
end

local function generateSelector(options)
    t.setBackground(t.getColor("gray"))
    t.setForeground(t.getColor("white"))

    local _, y = t.getCursor()

    local toggle = true

    local function toggleBackgroundColor()
        toggle = not toggle
        if toggle then
            t.setBackground(t.getColor("gray"))
            t.setForeground(t.getColor("white"))
        else
            t.setBackground(t.getColor("silver"))
            t.setForeground(t.getColor("black"))
        end
    end

    for i = 1, #options + 1 do
        gpu.fill(1, y - 1 + i, w, 1, " ")
        toggleBackgroundColor()
    end

    if (#options + 1) % 2 ~= 0 then
        toggleBackgroundColor()
    end

    t.setCursor(1, y)
    t.print("0: Go home")
    toggleBackgroundColor()

    for i, v in ipairs(options) do
        t.print(i .. ": " .. v)
        toggleBackgroundColor()
    end
end

local function drawBanner(page)
    local curBg = gpu.getBackground()
    t.setBackground(t.getColor("silver"))
    t.setForeground(t.getColor("cyan"))

    gpu.fill(1, 1, w, 1, " ")

    local bannerText = core.name() .. " - " .. page

    t.setCursor(math.floor((w - #bannerText) / 2), 1)
    t.print(bannerText)
    t.setBackground(curBg)
end

local function printError(text)
    t.setBackground(t.getColor("red"))
    gpu.fill(1, h, w, 1, " ")
    t.setCursor((w - #text) / 2, h)
    t.write(text)
end

local function prepPage(page)
    t.setBackground(t.getColor("black"))
    t.clear()
    drawBanner(page)
    t.setForeground(t.getColor("white"))
end

local function noPage()
    printError("This function does not exist.")
end

local function displayMainScreen()
    prepPage("Home")
    t.setForeground(t.getColor("cyan"))
    t.setBackground(t.getColor("black"))

    t.setCursor(8, 4)
    t.print("Welcome to")
    t.setCursor(8, 5)
    t.printMap(t.logo, true)
    local verText = "Version " .. string.gsub(_G._VERSION, "WarpOS ", "")
    t.setCursor(74 - #verText, 11)

    t.setForeground(t.getColor("white"))
    t.print(verText)

    t.setCursor(52,12)
    t.write("Original by ")
    t.setForeground(t.getColor("yellow"))
    t.print("IpsumCapra")
    t.setForeground(t.getColor("white"))
    t.setCursor(54,13)
    t.write("Edited by ")
    t.setForeground(t.getColor("cyan"))
    t.print("Recoherent")

    t.setCursor(1, 18)
    generateSelector(const.mainOptions)
end

local function displaySettingsScreen()
    local position = { core.getLocalPosition() }
    local charge, max, unit = core.getEnergyStatus()
    local mass, volume = core.getShipSize()

    local posDim = { core.dim_positive() }
    local negDim = { core.dim_negative() }

    prepPage("Settings")

    t.setBackground(t.getColor("cyan"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 3, w, 1, " ")
    t.setCursor(1, 3)
    t.print("Ship information:")

    t.setBackground(t.getColor("gray"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 4, w, 13, " ")
    t.print("Current position")
    t.write("x: ")
    t.print(tostring(position[1]))
    t.write("y: ")
    t.print(tostring(position[2]))
    t.write("z: ")
    t.print(tostring(position[3]))

    t.print("")
    t.print("Energy")
    t.print(charge .. " / " .. max .. " " .. unit)

    t.print("")
    t.print("Dimensions")
    t.print("Front, right, up: " .. posDim[1] .. ", " .. posDim[2] .. ", " .. posDim[3])
    t.print("Back, left, down: " .. negDim[1] .. ", " .. negDim[2] .. ", " .. negDim[3])
    t.print("")
    t.print("Mass, volume: " .. mass .. ", " .. volume)

    t.setCursor(1, 18)
    generateSelector(const.settingOptions)
end

local function displayNavScreen()
    local position = { core.getLocalPosition() }
    local movement = { core.movement() }
    local hs = core.isInHyperspace()

    prepPage("Navigation")

    t.setBackground(t.getColor("cyan"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 3, w, 1, " ")
    t.setCursor(1, 3)
    t.print("Current position:")

    t.setBackground(t.getColor("gray"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 4, w, 4, " ")
    t.write("x: ")
    t.print(tostring(position[1]))
    t.write("y: ")
    t.print(tostring(position[2]))
    t.write("z: ")
    t.print(tostring(position[3]))
    t.write("Hyperspace: ")
    t.print(tostring(hs))

    t.setBackground(t.getColor("cyan"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 9, w, 1, " ")
    t.setCursor(1, 9)
    t.print("Movement settings:")

    t.setBackground(t.getColor("gray"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 10, w, 6, " ")
    t.write("x: ")
    t.print(tostring(movement[1]))
    t.write("y: ")
    t.print(tostring(movement[2]))
    t.write("z: ")
    t.print(tostring(movement[3]))
    t.print("")
    t.print("Target position: " .. position[1] + movement[1] .. " " .. position[2] + movement[2] .. " " .. position[3] + movement[3])
    t.print("Rotation: " .. const.rotationValues[core.rotationSteps() + 1][1])

    t.setCursor(1, 18)
    generateSelector(const.navOptions)
end

local function displayMapScreen()
    local position = { core.getLocalPosition() }
    local sx, sy = map.parseLocation(position[1], position[3])
    local hs = core.isInHyperspace()
    local cname, cdesc, ccolor = " ", " ", 0x000000
    local cx, cz = 0, 0

    gpu.setResolution(gpu.maxResolution())
    w, h = gpu.getResolution()
    prepPage("Map")

    if loadedCoordinates == {} then
        table.insert(loadedCoordinates, {
            " ",
            " ",
            "0",
            "0",
            "40",
            "0x000000",
            " "
        })
    end

    t.setBackground(t.getColor("cyan"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 32, 79, 1, " ")
    t.setCursor(1, 32)
    t.print("Ship status:")

    t.setBackground(t.getColor("gray"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 33, 79, 4, " ")
    t.write("x: ")
    t.print(tostring(position[1]))
    t.write("y: ")
    t.print(tostring(position[2]))
    t.write("z: ")
    t.print(tostring(position[3]))
    t.write("Hyperspace: ")
    t.print(tostring(hs))

    t.setCursor(1, 38)
    generateSelector(const.mapOptions)

    map.setMapCenter(120, 21)
    t.setBackground(t.getColor("black"))
    gpu.fill(80, 2, 81, 40, " ")
    --t.setBackground(t.getColor("gray"))
    --gpu.fill(101, 12, 60, 30, " ")

    map.drawAllCelestials(loadedCoordinates)
    map.drawPoint(sx, sy, "(", ")", 0xFFFFFF, 0x000000)

    cname, cdesc, ccolor = map.drawCursor(loadedCoordinates)

    t.setBackground(ccolor)
    gpu.fill(1, 3, 79, 1, " ")
    t.setBackground(t.getColor("black"))
    t.setForeground(ccolor)
    t.setCursor(2, 3)
    t.print(" " .. cname .. " ")

    t.setForeground(t.getColor("white"))
    t.setCursor(1, 4)
    t.print(cdesc)

    cx, cz = map.cursorLocation()
    t.setCursor(1, 6)
    t.write("x: ")
    t.print(tostring(cx))
    t.write("y: ")
    t.print(tostring(cz))

end

local function loadFromDisk()
    local rawCoords = map.parseDisk()
    if rawCoords ~= "no file" then
        local parsedCoords = map.parseAllCoords(rawCoords)
        local position = { core.getLocalPosition() }
        local sx, sy = map.parseLocation(position[1], position[3])
        
        loadedCoordinates = map.addNewCoordinates(loadedCoordinates, parsedCoords)
        displayMapScreen()
    else
        printError("No coordinate file found.")
    end

end

local function displayCrewScreen()
    prepPage("Crew")

    t.setBackground(t.getColor("silver"))

    t.setCursor(1, 18)
    generateSelector(const.crewOptions)
end

local function displayAdvancedScreen()
    local isValid, msg = core.getAssemblyStatus()

    prepPage("Advanced settings")

    t.setBackground(t.getColor("cyan"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 3, w, 1, " ")
    t.setCursor(1, 3)
    t.print("Current mode:")

    t.setBackground(t.getColor("gray"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 4, w, 1, " ")
    t.print(core.command())

    t.setBackground(t.getColor("cyan"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 6, w, 1, " ")
    t.setCursor(1, 6)
    t.print("Assembly status:")

    t.setBackground(t.getColor("gray"))
    t.setForeground(t.getColor("white"))
    gpu.fill(1, 7, w, 2, " ")
    t.print("Valid: " .. tostring(isValid))
    t.print("Message: " .. msg)

    t.setCursor(1, 18)
    generateSelector(const.advancedOptions)
end

local function namingScreen()
    prepPage("Naming")
    t.setBackground(t.getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Enter a new name and press enter to confirm.")
    t.setBackground(t.getColor("gray"))
    gpu.fill(1, 4, w, 1, " ")
    t.write("New name: ")
    core.name(getText())
    displaySettingsScreen()
end

local function dimensionsScreen()
    local pos = { core.dim_positive() }
    local neg = { core.dim_negative() }

    local dimensions = {
        ["Front"] = pos[1],
        ["Right"] = pos[2],
        ["Up"] = pos[3],
        ["Back"] = neg[1],
        ["Left"] = neg[2],
        ["Down"] = neg[3]
    }

    prepPage("Dimensions")
    t.setBackground(t.getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Enter new dimensions. Press enter to keep current value.")

    local y = 4

    for k, v in pairs(dimensions) do
        while true do
            t.setBackground(t.getColor("gray"))
            t.setCursor(1, y)
            gpu.fill(1, y, w, 1, " ")
            t.write(k .. "(" .. v .. ")" .. ": ")

            local value = getText()
            if value == "" then
                break
            end

            local dimension = tonumber(value)
            if dimension ~= nil then
                if dimension > -1 then
                    dimensions[k] = dimension
                    break
                else
                    printError("Value must be higher than, or equal to zero.")
                end
            else
                printError("Invalid value.")
            end
        end
        y = y + 1
    end

    core.dim_positive(dimensions["Front"], dimensions["Right"], dimensions["Up"])
    core.dim_negative(dimensions["Back"], dimensions["Left"], dimensions["Down"])
    displaySettingsScreen()
end

local function movementScreen()
    core.command("MANUAL", false)

    local pos = { core.dim_positive() }
    local neg = { core.dim_negative() }
    local movement = { core.movement() }
    local _, max = core.getMaxJumpDistance()
    local newMovement = {
        ["Front"] = movement[1],
        ["Up"] = movement[2],
        ["Right"] = movement[3],
    }

    prepPage("Movement")
    t.setBackground(t.getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Enter movement values. Negative value is opposite direction.")

    local y = 4
    for k, v in pairs(newMovement) do
        while true do
            printError("Choose a value between " .. pos[y - 3] + neg[y - 3] .. " and " .. max)
            t.setBackground(t.getColor("gray"))
            t.setCursor(1, y)
            gpu.fill(1, y, w, 1, " ")
            t.write(k .. "(" .. v .. ")" .. ": ")

            local value = getText()
            if value == "" then
                break
            end

            local amount = tonumber(value)
            if amount ~= nil then
                newMovement[k] = amount
                break
            else
                printError("Invalid value.")
            end
        end
        y = y + 1
    end
    prepPage("Rotation")

    t.setBackground(t.getColor("black"))
    t.setCursor(1, 3)
    gpu.fill(1, 3, w, 1, " ")
    t.print("Set rotation using WASD.")

    t.setBackground(t.getColor("gray"))
    t.setCursor(1, 4)
    gpu.fill(1, 4, w, 1, " ")

    while true do
        t.setCursor(1, 4)
        gpu.fill(1, 4, w, 1, " ")
        t.write("Rotation: " .. const.rotationValues[core.rotationSteps() + 1][1])

        local key = getKey()
        if key == "\13" then
            break
        else
            for k, v in ipairs(const.rotationValues) do
                if v[2] == key then
                    core.rotationSteps(k - 1)
                end
            end
        end
    end

    local rotatedMovement = {
        newMovement["Front"],
        newMovement["Right"]
    }

    local rotation = core.rotationSteps()
    if rotation == 1 then
        rotatedMovement[1] = -newMovement["Right"]
        rotatedMovement[2] = newMovement["Front"]
    elseif rotation == 2 then
        rotatedMovement[1] = -newMovement["Front"]
        rotatedMovement[2] = -newMovement["Right"]
    elseif rotation == 3 then
        rotatedMovement[1] = newMovement["Right"]
        rotatedMovement[2] = -newMovement["Front"]
    end

    core.movement(rotatedMovement[1], newMovement["Up"], rotatedMovement[2])
    displayNavScreen()
end

local function targetingScreen()
    noPage()
end

local function jump()
    printError("Jump? [Y/N]")
    local key = getKey()
    if key == "y" or key == "\13" then
        core.command("MANUAL", true)
    end
    displayNavScreen()
end

local function hyperdrive()
    local hs = core.isInHyperspace()
    local mass, vol = core.getShipSize()
    if mass < 4000 then
        printError("Ship too small! Aborting.")
        return
    end
    if hs then
        printError("Exit hyperspace? [Y/N]")
    else
        printError("Enter hyperspace? [Y/N]")
    end
    local key = getKey()
    if key == "y" or "\13" then
        core.command("HYPERDRIVE", true)
    end
    displayNavScreen()
end
    
local function maintenanceMode()
    core.command("MAINTENANCE", false)
    displayAdvancedScreen()
end

local function disableCore()
    core.command("OFFLINE", false)
    displayAdvancedScreen()
end

local screens = {
    main = displayMainScreen,
    settings = displaySettingsScreen,
    navigation = displayNavScreen,
    map = displayMapScreen,
    crew = displayCrewScreen,
    advanced = displayAdvancedScreen
}

local function switchToScreen(screen)
    page = screen
    gpu.setResolution(80, 25)
    w, h = gpu.getResolution()
    screens[screen]()
end

local actions = {
    main = {
        "settings",
        "navigation",
        "map",
        "crew",
        "advanced"
    },
    settings = {
        dimensionsScreen,
        namingScreen
    },
    navigation = {
        jump,
        targetingScreen,
        movementScreen,
        hyperdrive
    },
    map = {
        loadFromDisk,
        noPage,
        noPage
    },
    crew = {
        noPage
    },
    advanced = {
        maintenanceMode,
        disableCore
    }
}

if core.name() == "" then
    namingScreen()
end

map.setCursor(5, 5)
displayMainScreen()

while true do
    local key = getKey()
    if key == "0" and page ~= "main" then
        switchToScreen("main")
    -- literal clunkiest implementation in existence
    elseif key == "w" and page == "map" then
        map.moveCursor(0, -1)
        displayMapScreen()
    elseif key == "a" and page == "map" then
        map.moveCursor(-1, 0)
        displayMapScreen()
    elseif key == "s" and page == "map" then
        map.moveCursor(0, 1)
        displayMapScreen()
    elseif key == "d" and page == "map" then
        map.moveCursor(1, 0)
        displayMapScreen()
    else
        key = tonumber(key)
        if actions[page][key] ~= nil then
            if page == "main" then
                if actions["main"][key] == "map" and tier ~= 3 then
                    printError("The map screen requires t3 graphics")
                else
                    switchToScreen(actions["main"][key])
                end
            else
                actions[page][key]()
            end
        end
    end
end