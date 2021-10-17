-- disk var holds a proxy to a floppy disk in a drive
local disk = disk
local map = {}

local gpu = gpu
local t = require("terminal")
local core = core

-- map center
local mx = 1
local my = 1

-- map cursor position
local cx = 1
local cy = 1

--basic table matching function, gives success and index
function map.tableSearch(table, value)
    for i, v in pairs(table) do
        if v == value then
            return true, i
        end
    end
    return false, 0
end

--reads coordinates from a loaded disk and hands back a table with them all
function map.parseDisk()
    -- making sure that there's a disk in there that has the required "coords" file
    reloadComponents()
    disk = _G.disk
    if disk ~= false then
        if disk.exists("coords") then
            local file = disk.open("coords")
            -- parse the file's full data into a table. entries separated by line break
            local fullCoordSet = {}
            for v in string.gmatch(disk.read(file, disk.size("coords")), "%C+") do
                table.insert(fullCoordSet, v)
            end
            disk.close(file)
            return fullCoordSet
        else
            -- make sure to handle this properly, me
            return "no file"
        end
    else
        return "no file"
    end
end

function map.parseCoordSet(coords)
    --pretty simple, carves up the individual sets given by parseDisk into tables with each entry separated per-line. order: name, description x, y, size, color, identifying character
    local coordinates = {}
    for v in string.gmatch(coords, "[^|]+") do
        table.insert(coordinates, v)
    end
    return coordinates
end

function map.parseAllCoords(coords)
    local finalCoordinates = {}
    for i, v in ipairs(coords) do
        table.insert(finalCoordinates, map.parseCoordSet(v))
    end
    return finalCoordinates
end

--appends new coordinates onto an existing table, discarding duplicates. don't tell anyone that this is just a standard table manipulation function!
function map.addNewCoordinates(loaded, newcoords)
    for i, v in ipairs(newcoords) do
        if not map.tableSearch(loaded, v) then
            table.insert(loaded, v)
        end
    end
    return loaded
end

--adjusts real-world x/z to map coordinates (divide and ceiling by factor of 10,000)
function map.parseLocation(x, z)
    x = math.ceil(x/10000)
    z = math.ceil(z/10000)
    return x, z
end

--adjusts map coordinate of cursor to expected real-world x/z (*10,000 - 5,000)
function map.cursorLocation()
    x = (cx*10000)-5000
    y = (cy*10000)-5000
    return x, y
end

--this is all drawing stuff now

function map.setMapCenter(x, y)
    mx = x
    my = y
end

function map.setCursor(x, y)
    cx = x
    cy = y
end

function map.moveCursor(x, y)
    cx = cx + x
    if cx > 20 then cx = 20 end
    if cx < -20 then cx = -20 end
    cy = cy + y
    if cy > 20 then cy = 20 end
    if cy < -20 then cy = -20 end
end

function map.drawCelestial(coordinates)
    local dx = (tonumber(coordinates[3]) * 2) - 1 + mx
    local dy = tonumber(coordinates[4]) + my
    local s = tonumber(coordinates[5])
    local color = tonumber(coordinates[6])
    local char = coordinates[7]

    t.setForeground(color)
    t.setBackground(color)
    gpu.fill(dx+(-s+2), dy+(-s/2+1), s*2, s, char)
end

function map.drawAllCelestials(fullCoordinateSet)
    for i, coord in ipairs(fullCoordinateSet) do
        map.drawCelestial(coord)
    end
end

function map.drawPoint(x, y, char1, char2, foreground, background)
    t.setForeground(foreground)
    if not background then
        local q, p, transcolor = gpu.get((x*2)-1+mx, y+my)
        t.setBackground(transcolor)
    else
        t.setBackground(background)
    end

    gpu.set((x*2)-1+mx, y+my, char1)
    gpu.set((x*2)+mx, y+my, char2)
end

-- this function gets which celestial body is underneath the current cursor position, and then returns its name, description, and color
function map.getCursorInfo(allCoordinates)
    local char = gpu.get((cx*2)-1+mx, cy+my)
    for i, coordinate in ipairs(allCoordinates) do
        if coordinate[7] == char then
            return coordinate[1], coordinate[2], tonumber(coordinate[6])
        end
    end
    return " ", " ", 0x000000
end

--draws the cursor, and also gives an info output for whatever was just drawn over
function map.drawCursor(allCoordinates)
    local drawnOverName, drawnOverDesc, drawnOverColor = map.getCursorInfo(allCoordinates)
    map.drawPoint(cx, cy, "<", ">", 0xFFFFFF, false)
    return drawnOverName, drawnOverDesc, drawnOverColor
end

return map