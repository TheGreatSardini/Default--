--widget--custom9.lua

--DEFAULT-- windows colors variables:
--------------------------------------
--P.MS.TC.value  = TITLE_COLOR
--P.MS.TCA.value = TITLE_COLOR_A
--P.MS.TTC.value = TITLE_TEXT_COLOR
--P.MS.WC.value  = WN_COLOR
--P.MS.WCA.value = WN_COLOR_A
--P.MS.WTC.value = WN_TEXT_COLOR
--P.MS.BC.value  = BUTTON_COLOR
--P.MS.BBC.value = BUTTON_BORDER_COLOR
--P.MS.BCA.value = BUTTON_COLOR_A
--P.MS.BTC.value = BUTTON_TEXT_COLOR
--P.MS.wTC.value = WIDGET_TEXT_COLOR
--P.MS.wAC.value = WIDGET_ANIM_COLOR
--P.MS.WFC.value = WIDGET_FIXED_COLOR

--DEFAULT-- updated variables:
-------------------------------
--currentTime = num
--inspace = 0 in atmo 1 in space
--xSpeedKPH = num km/h
--ySpeedKPH = num km/h
--zSpeedKPH = num km/h
--xyzSpeedKPH = num km/h
--velMag = num m/s
--Az = drift rot angle in deg
--Ax = drift pitch angle in deg
--Ax0 = pitch angle in deg
--Ay0 = roll angle in deg
--ThrottlePos = num
--MM = string ("CRUISE" / "TRAVEL" / "PARKING" / "DRONE")
--closestPlanetIndex = num (planet index for Helios library)
--atmofueltank = JSON
--spacefueltank = JSON
--rocketfueltank = JSON
--fueltanks = table (all fueltanks JSON data)
--fueltanks_size = num (total number of fuel tanks)

--DEFAULT-- keybind variables:
-------------------------------
--CLICK = bool
--CTRL = bool
--ALT = bool
--SHIFT = bool
--mwCLICK = bool
--GEAR = bool
--pitchInput = num (-1 / 0 / 1)
--rollInput = num (-1 / 0 / 1)
--yawInput = num (-1 / 0 / 1)
--brakeInput = num (-1 / 0 / 1)
--strafeInput = num (-1 / 0 / 1)
--upInput = num (-1 / 0 / 1)
--forwardInput = num (-1 / 0 / 1)
--boosterInput = num (-1 / 0 / 1)

local widget_font = "Play"
local utils = require("cpml/utils")
WidgetsPlusPlusCustom = {}
WidgetsPlusPlusCustom.__index = WidgetsPlusPlusCustom

function WidgetsPlusPlusCustom.new(core, unit, DB, antigrav, warpdrive, shield, switch, player, telemeter)
    local self = setmetatable({}, WidgetsPlusPlusCustom)
    self.core = core
    self.unit = unit
    self.DB = DB
    self.antigrav = antigrav
    self.warpdrive = warpdrive
    self.shield = shield
    self.switch = switch
    self.player = player
    self.telemeter = telemeter

    self.buttons = {} -- list of buttons to be implemented in widget

    self.width = DUSystem.getScreenWidth()
    self.height = DUSystem.getScreenHeight()
    self.vFov = DUSystem.getCameraVerticalFov()
    self.hFov = DUSystem.getCameraHorizontalFov()
    self.name = 'MAP+-' -- name of the widget
    self.SVGSize = {x=280,y=280} -- size of the window to fit the svg, in pixels
    self.pos = {x=10, y=10}
    self.class = 'widgets'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
    self.title = nil
    self.scalable = true

    self.map_scale = 1
    self.atmoScale = 1
    return self
end

function WidgetsPlusPlusCustom.getSize(self) --returns the svg size
    return self.SVGSize
end

function WidgetsPlusPlusCustom.getName(self) --returns the widget name
    return self.name
end

function WidgetsPlusPlusCustom.getTitle(self) --returns the widget name
    return self.title
end

function WidgetsPlusPlusCustom.getPos(self) --returns the widget name
    return self.pos
end

function WidgetsPlusPlusCustom.getButtons(self) --returns buttons list
    return self.buttons
end

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return nil
end

-- function WidgetsPlusPlusCustom.loadData(self)
-- local load = Data:getData("INFO") ~= nil and Data:getData("INFO") or nil
-- if load then
-- self.SVGSize = load.a
--self.pos = load.b
-- end
-- end

-- function WidgetsPlusPlusCustom.saveData(self)
-- if Data then
-- local save = {a=self.SVGSize} --{a=self.SVGSize, b=self.pos}
-- Data:setData("INFO",save)
-- end
-- end

--function WidgetsPlusPlusCustom.onActionStart(self, action)
--     --DUSystem.print(action)
--end
--function WidgetsPlusPlusCustom.onActionStop(self, action) -- uncomment to receive released key
--     --DUSystem.print(action)
--end
--function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive pressed key
--     --DUSystem.print(action)
--end




local BookmarksPOI = require (widgetsFolder .. ".BookmarksPOI")
local BookmarksCustoms = require (widgetsFolder .. ".BookmarksCustoms")
local spacePOIS = {}
local customPOIS = {}
for i, poi in pairs(Helios) do
    spacePOIS[#spacePOIS+1] = poi
end
for i, poi in ipairs(BookmarksPOI) do
    if poi.bodyId == 0 then
        spacePOIS[#spacePOIS+1] = poi
    else
        customPOIS[#customPOIS+1] = poi
    end
end
for i, poi in ipairs(BookmarksCustoms) do
    if poi.bodyId == 0 then
        spacePOIS[#spacePOIS+1] = poi
    else
        customPOIS[#customPOIS+1] = poi
    end
end


local abs, floor, format, sub, acos, sqrt, cos, sin, deg, ceil, clamp, cos = math.abs, math.floor, string.format, string.sub, math.acos, math.sqrt, math.cos, math.sin, math.deg, math.ceil, utils.clamp, math.cos

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

local function cross(x, y, z, vx, vy, vz)
    return y*vz - z*vy, z*vx - x*vz, x*vy - y*vx
end

local function vectorLen2(x,y,z)
    return x * x + y * y + z * z
end

local function project_on_plane(x, y, z, pnx, pny, pnz)
    local dot = dotVec(x, y, z, pnx, pny, pnz)
    local len2 = vectorLen2(pnx, pny, pnz)
    return (x - pnx*dot)/len2, (y - pny*dot)/len2, (z - pnz*dot)/len2
end

local function rotateVec(vx, vy, vz, phi, ax, ay, az)
    local l = sqrt(ax*ax + ay*ay + az*az)
    local ux, uy, uz = ax/l, ay/l, az/l
    local c, s = cos(phi), sin(phi)
    local m1x, m1y, m1z = (c + ux * ux * (1-c)), (ux * uy * (1-c) - uz * s), (ux * uz * (1-c) + uy * s)
    local m2x, m2y, m2z = (uy * ux * (1-c) + uz * s), (c + uy * uy * (1-c)), (uy * uz * (1-c) - ux * s)
    local m3x, m3y, m3z = (uz * ux * (1-c) - uy * s), (uz * uy * (1-c) + ux * s), (c + uz * uz * (1-c))
    return m1x*vx+m1y*vy+m1z*vz, m2x*vx+m2y*vy+m2z*vz, m3x*vx+m3y*vy+m3z*vz
end

local function getConstructRotation(x, y, z) --UPDATED
    if x == nil then x, y, z = -1,0,0 end
    x, y, z = normalizeVec(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CUx, CUy, CUz = cWOUPx, cWOUPy, cWOUPz
    local cx, cy, cz = cross(x, y, z, CUx, CUy, CUz)
    local rAx, rAy, rAz =  normalizeVec(cx, cy, cz)
    local ConstructRot = acos(clamp(dotVec(rAx, rAy, rAz, CRx, CRy, CRz), -1, 1)) * 57.2957795130
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CUx, CUy, CUz) > 0 then ConstructRot = -ConstructRot end --system.print("rot: "..ConstructRot)
    return ConstructRot
end

local TABLE = {}
TABLE = {
    index = function (t,val)
        for i,v in ipairs(t) do
            if v == val then 
                return i
            end
        end
        return nil
    end,

    valUp = function (t,val)
        local index = TABLE.index(t,val)
        local newVal 
        if index == nil then
            newVal = t[1]
        elseif t[index+1] == nil then
            newVal = t[1]
        else
            newVal = t[index+1]
        end
        return newVal
    end,

    valDown = function (t,val)
        local index = TABLE.index(t,val)
        local newVal
        if index == nil then
            newVal = t[1]
        elseif t[index-1] == nil then
            newVal = t[#t]
        else
            newVal = t[index-1]
        end
        return newVal
    end,
}

local function convertToWorldCoordinates(posString)
    local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local posPattern = '::pos{' .. num .. ',' .. num .. ',' .. num .. ',' .. num ..  ',' .. num .. '}'
    local systemId, bodyId, latitude, longitude, altitude = string.match(posString,posPattern)

    systemId = tonumber(systemId)
    bodyId = tonumber(bodyId)
    latitude = tonumber(latitude)
    longitude = tonumber(longitude)
    altitude = tonumber(altitude)

    if tonumber(bodyId) == 0 then
        return latitude,longitude,altitude
    end

    latitude = 0.0174532925199 * math.max(math.min(latitude, 90), -90)
    longitude = 0.0174532925199 * (longitude % 360)

    local center, radius = Helios[bodyId].center, Helios[bodyId].radius
    local xproj = cos(latitude)
    local px, py, pz = center[1]+(tonumber(radius)+altitude)*xproj*cos(longitude),
    center[2]+(tonumber(radius)+altitude)*xproj*sin(longitude),
    center[3]+(tonumber(radius)+altitude)*sin(latitude)
    return px, py, pz
end

----------------
-- WIDGET SVG --
----------------
function WidgetsPlusPlusCustom.SVG_Update(self)

    if inspace == 0 then
        local bf = function()
            if mouseWheel > 0 then
                self.atmoScale = TABLE.valUp({"1","1.5","2","2.5","3","3.5","4","4.5","5"}, self.atmoScale)
                --system.print("Map scale: "..self.atmoScale)
            elseif mouseWheel < 0 then
                self.atmoScale = TABLE.valDown({"1","1.5","2","2.5","3","3.5","4","4.5","5"}, self.atmoScale)
                --system.print("Map scale: "..self.atmoScale)
            end
            windowsShow()
        end
        self.buttons[1] = {"Zoom: "..self.atmoScale, bf, {class= nil, width = 65, height = 20, posX = 1, posY = 1}}
    end

    local WFC = P.MS.WFC.value
    local WTC = P.MS.wTC.value
    local WAC = P.MS.wAC.value
    local WC = P.MS.WC.value
    local WCA = P.MS.WCA.value

    local MapSVG_Outring = [[
    <circle cx="100" cy="100" r="98.5" stroke-width="]].. 1.5/self.map_scale ..[[" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
    ]]

    local MapSVG_Planet = ""
    local MapSVG_Planets = ""
    local MapSVG_Construct = ""
    local MapSVG_LocalBookmarks = ""
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    local pCx, pCy, pCz = 0, 0, 0
    local sizeScale = 1
    local currentPlanetAtmoAltitude = planet.atmosphereThickness

    if (inspace == 1 and alt > currentPlanetAtmoAltitude + 100000) or (inspace == 1 and alt == 0) then
        local cx, cy = cWPx/100000000*90, cWPy/100000000*90
        MapSVG_Construct = [[
        <circle cx="]].. 100 + cx..[[" cy="]].. 100 + cy..[[" r="1" stroke-width="0" fill="red"/>
        ]]


        for i, v in ipairs (spacePOIS) do
            if v.type[1] ~= "Moon" and v.type[1] ~= "Asteroid" then
                if spacePOIS[i].center ~= nil and #spacePOIS[i].center == 3 then
                    pCx, pCy, pCz = spacePOIS[i].center[1], spacePOIS[i].center[2], spacePOIS[i].center[3]
                    sizeScale = 1
                elseif spacePOIS[i].pos ~= nil and string.sub(spacePOIS[i].pos,1,6) == "::pos{" then
                    pCx, pCy, pCz = convertToWorldCoordinates(spacePOIS[i].pos)
                    sizeScale = 0.7
                end

                local px, py = pCx/100000000*90,pCy/100000000*90
                local pname = spacePOIS[i].name[1] or "no name"
                local pdist = format(" (%.1fSU)",vectorLen(cWPx-pCx,cWPy-pCy,cWPz-pCz)/1000/200)
                local textOffset = 5.5
                if pname == "Sicari" or pname == "Ion" or pname == "Thades" then textOffset = -6 end
                MapSVG_Planets = MapSVG_Planets ..[[
                <circle cx="]].. 100 + px..[[" cy="]].. 100 + py ..[[" r="]].. 1.5*sizeScale ..[[" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WTC..[["/>
                <text x="]].. 100 + px..[[" y="]].. 100 + py + textOffset ..[[" font-size="]].. 5*sizeScale ..[[" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="]]..WTC..[[">
                <tspan x="]].. 100 + px..[[" >]]..pname ..[[</tspan>
                <tspan x="]].. 100 + px..[[" dy="]].. 3*sizeScale ..[[" font-size="]].. 3*sizeScale ..[[">]]..pdist..[[</tspan>
                </text>
                ]]
            end
        end

        if P.AP_destination.value ~= nil and #P.AP_destination.value == 3 then
            local Dx, Dy, Dz = P.AP_destination.value[1], P.AP_destination.value[2], P.AP_destination.value[3]
            local px, py = Dx/100000000*90, Dy/100000000*90
            local pname = "Destination"
            local pdist = format(" (%.1fSU)",vectorLen(cWPx-Dx,cWPy-Dy,cWPz-Dz)/1000/200)
            local textOffset = 3.5
            MapSVG_Planets = MapSVG_Planets ..[[
            <circle cx="]].. 100 + px..[[" cy="]].. 100 + py ..[[" r="]].. 1 ..[[" stroke-width="0.1" stroke="red" fill="red"/>
            <text x="]].. 115 + px..[[" y="]].. 100 + py ..[[" font-size="4" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="red">
            <tspan x="]].. 115 + px..[[" >]]..pname ..[[</tspan>
            <tspan x="]].. 115 + px..[[" dy="3" font-size="3">]]..pdist..[[</tspan>
            </text>
            ]]
        end

        MapSVG_Planet = [[
        <text x="1" y="8" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="hanging" stroke-width="0" fill="]]..WTC..[[">
        <tspan font-size="10" >SPACE</tspan>
        </text>
        <circle cx="100" cy="100" r="80" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
        <circle cx="100" cy="100" r="60" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
        <circle cx="100" cy="100" r="40" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
        <circle cx="100" cy="100" r="20" stroke-width="0.1" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA..[["/>
        ]]

        local SFx, SFy, SFz = 13856701.7693, 7386301.6554, -258251.0307
        cx, cy = SFx/100000000*90, SFy/100000000*90
        MapSVG_Planets = MapSVG_Planets ..[[
        <circle cx="]].. 100 + cx..[[" cy="]].. 100 + cy ..[[" r="]].. 20 ..[[" stroke-width="0.05" stroke="red" stroke-dasharray="4" stroke-opacity="0.7" fill="none"/>]]
    else
        local cPR = currentPlanetRadius
        local cPCx, cPCy, cPCz = currentPlanetCenter[1], currentPlanetCenter[2], currentPlanetCenter[3]
        local planet_scale = (-alt / (cPR/4)) + 1
        planet_scale = clamp(planet_scale,0.5,1)
        local atmo_map_scale = self.atmoScale
        MapSVG_Planet = [[
        <text x="1" y="25" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="hanging" stroke-width="0" fill="]]..WTC..[[">
        <tspan font-size="10" >]]..currentPlanetName..[[</tspan>]]
        --<tspan font-size="7" >]].."(x"..atmo_map_scale..")"..[[</tspan>
        ..[[</text>
        <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="]].. 1/self.map_scale ..[[" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 85*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 70*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 50*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 27*planet_scale..[[" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="0.1" ry="]].. 90*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 85*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 70*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 50*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="]].. 27*planet_scale..[[" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        <ellipse cx="100" cy="100" rx="]].. 90*planet_scale..[[" ry="0.1" stroke-width="0.5" stroke="]]..WFC..[[" fill="none"/>
        ]]

        --DUSystem.print("a")
        local rot = getConstructRotation(cPCx-cWPx, cPCy-cWPy, cPCz+cPR-cWPz)
        --DUSystem.print("b")
        MapSVG_Construct = [[
        <polygon points="100 95, 97.5 105, 102.5 105" stroke-width="0" fill="]]..WAC..[[" transform="rotate(]]..rot..[[ 100 100)"/>
        ]]

        for i, v in ipairs(customPOIS) do
            local posx, posy, posz = convertToWorldCoordinates(v.pos)
            local MarkerDistance = vectorLen(posx-cWPx,posy-cWPy,posz-cWPz)
            if MarkerDistance < cPR/atmo_map_scale then
                if v.pos ~= nil  then
                    local M3Dx, M3Dy, M3Dz = (posx-cPCx)/(cPR/atmo_map_scale)*90*planet_scale, (posy-cPCy)/(cPR/atmo_map_scale)*90*planet_scale, (posz-cPCz)/(cPR/atmo_map_scale)*90*planet_scale
                    local VUx, VUy, VUz = normalizeVec(cPCx-cWPx, cPCy-cWPy, cPCz-cWPz)
                    local popx, popy, popz = project_on_plane(VUx, VUy, VUz, 0, 0, 1)
                    local rvx, rvy, rvz = rotateVec(popx, popy, popz, math.rad(-90), 0, 0, 1)
                    local VEx, VEy, VEz = normalizeVec(rvx, rvy, rvz)
                    local crx, cry, crz = cross(VUx, VUy, VUz, VEx, VEy, VEz)
                    local VNx, VNy, VNz = normalizeVec(crx, cry, crz)
                    local reso = DULibrary.systemResolution3({VEx, VEy, VEz},{VNx, VNy, VNz},{VUx, VUy, VUz},{M3Dx, M3Dy, M3Dz})
                    posx, posy, posz = reso[1], reso[2], reso[3]
                    MapSVG_LocalBookmarks = MapSVG_LocalBookmarks..[[
                    <circle cx="]].. 100 + posx..[[" cy="]].. 100 + posy ..[[" r="]].. 1.5 ..[[" stroke-width="0" fill="]]..WTC..[["/>
                    <text x="]].. 100 + posx..[[" y="]].. 100 + posy + 5.5  ..[[" font-size="5" text-anchor="middle" font-family="]]..widget_font..[[" alignment-baseline="baseline" fill="]]..WTC..[[">
                    <tspan x="]].. 100 + posx..[[" >]]..v.name[1] ..[[</tspan>
                    <tspan x="]].. 100 + posx..[[" dy="3" font-size="3">]].." ("..floor(MarkerDistance/100)/10 .."km)"..[[</tspan>
                    </text>
                    ]]
                end
            end
        end
    end

    MapSVG = '<div><svg viewBox="0 0 200 200">'..MapSVG_Outring..MapSVG_Planet..MapSVG_Planets..MapSVG_LocalBookmarks..MapSVG_Construct..'</svg></div>'
    return MapSVG
end

