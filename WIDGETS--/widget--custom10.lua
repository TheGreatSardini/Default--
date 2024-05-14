--widget--custom10.lua

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
    self.name = 'TRAVEL PLANNER+-' -- name of the widget
    self.SVGSize = {x=1300,y=1000} -- size of the window to fit the svg, in pixels
    self.pos = {x=10, y=10}
    self.class = 'widgetnopadding'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
    self.title = 'TRAVEL PLANNER+-'
    self.scalable = true

    self.warp = {}
    self.selected = {name = "n/a", dist = 0, warp = false, pos = {0,0,0}}
    self.pageNum = 1
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


local abs, floor, format, sub, acos, sqrt, cos, sin, deg, ceil, clamp, cos = math.abs, math.floor, string.format, string.sub, math.acos, math.sqrt, math.cos, math.sin, math.deg, math.ceil, utils.clamp, math.cos

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function getClosestPointToLine(lp1x, lp1y, lp1z, lp2x, lp2y, lp2z, px, py, pz) -- lp1 = line point A / lp2 = line point B / p = point to compare
    local alpha = ((px-lp1x)*(lp2x-lp1x) + (py-lp1y)*(lp2y-lp1y) + (pz-lp1z)*(lp2z-lp1z)) / ((lp2x-lp1x)*(lp2x-lp1x) + (lp2y-lp1y)*(lp2y-lp1y) + (lp2z-lp1z)*(lp2z-lp1z))
    local cptlx, cptly, cptlz = lp1x + alpha*(lp2x-lp1x), lp1y + alpha*(lp2y-lp1y), lp1z + alpha*(lp2z-lp1z)
    local dist = sqrt((cptlx-px)^2 + (cptly-py)^2 + (cptlz-pz)^2)
    return cptlx, cptly, cptlz, dist
end


local function c2WC(posString)
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
    local WFC = P.MS.WFC.value
    local WTC = P.MS.wTC.value
    --local wTC = P.MS.wTC.value
    local WAC = P.MS.wAC.value
    local WC = P.MS.WC.value
    local WCA = P.MS.WCA.value
    local wAC = P.MS.wAC.value
    local BTC = P.MS.BTC.value

--WLP.winlibCSSUpdate(self)
    --DUSystem.print(WLP.css.base)
    if not string.find(WLP.css.base,".mapPlanet {",1,true) then
        DUSystem.print("TRAVEL PLANNER: updating CSS mapPlanet")
        WLP.css.base = WLP.css.base..[[ 
        .mapPlanet {
            position:absolute;
            border: 0px solid rgba(0, 0, 0, 0)!important;
            background: rgba(0, 0, 0, 0)!important;
            font-family:"Play" !important;
            font-size:25px !important;
            text-align: center !important;
            vertical-align: text-top !important;
            box-shadow:0px 0px rgba(0, 0, 0, 0) !important;
            color:]]..BTC..[[ !important;
            overflow:visible !important;
            padding-top:0px !important;
        }
        ]]
        --DUSystem.print(WLP.css.base)
    end
    if not string.find(WLP.css.base,".mapMarker {",1,true) then
        DUSystem.print("TRAVEL PLANNER: updating CSS mapMarkers")
        WLP.css.base = WLP.css.base..[[ 
        .mapMarker {
            position:absolute;
            border: 0px solid rgba(0, 0, 0, 0)!important;
            background: rgba(0, 0, 0, 0)!important;
            font-family:"Play" !important;
            font-size:25px !important;
            text-align: center !important;
            vertical-align: text-top !important;
            box-shadow:0px 0px rgba(0, 0, 0, 0) !important;
            color:]]..WTC..[[ !important;
            overflow:visible !important;
            padding-top:0px !important;
        }
        ]]
    end

    self.buttons = {}
    local bmind = 0
    local bookmarks = {}
    local ind = 0
    local markers = {}
    for k, planet in pairs(Helios) do
        if planet.type[1] ~= "Moon" and planet.type[1] ~= "Asteroid" then
            ind = ind + 1
            markers[ind] = {name = planet.name, center = planet.center, warp = true, iconPath = planet.iconPath, showName = true}
        end
    end
    for i, poi in ipairs(BookmarksPOI) do
        if poi.bodyId == 0 then
            local x, y, z = c2WC(poi.pos)
            ind = ind + 1
            markers[ind] = {name = poi.name or "noName", center = {x,y,z}, warp = poi.warp or false, symbol = poi.symbol or "❤", showName = true}
            bmind = bmind + 1
            bookmarks[bmind] = {name = poi.name, pos = poi.pos}
        end
    end
    for i, poi in ipairs(BookmarksCustoms) do
        if poi.bodyId == 0 then
            --DUSystem.print(poi.name[1])
            local x, y, z = c2WC(poi.pos)
            ind = ind + 1
            markers[ind] = {name = poi.name or "noName", center = {x,y,z}, warp = poi.warp or false, symbol = poi.symbol or "❤", showName = true}
        end
        bmind = bmind + 1
        bookmarks[bmind] = {name = poi.name, pos = poi.pos}
    end
    -- for i, aster in ipairs(asteroids) do
        -- local x, y, z = convertToWorldCoordinates(aster)
        -- markers[ind] = {name = {"Asteroid "..i}, center = {x,y,z}, warp = false, symbol = "☭", showName = false}
        -- ind = ind + 1
    -- end

    local mapcenter = 800
    local plasvg = [[<circle cx="]].. mapcenter..[[" cy="500" r="400" stroke-width="0.05" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA/2 ..[["/>
                    <circle cx="]].. mapcenter..[[" cy="500" r="300" stroke-width="0.05" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA/2 ..[["/>
                    <circle cx="]].. mapcenter..[[" cy="500" r="200" stroke-width="0.05" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA/2 ..[["/>
                    <circle cx="]].. mapcenter..[[" cy="500" r="100" stroke-width="0.05" stroke="]]..WFC..[[" fill="]]..WC..[[" fill-opacity="]]..WCA/2 ..[["/>
                    ]]

    local SFx, SFy = 13856701.7693, 7386301.6554
    local cx, cy = SFx/100000000*400, SFy/100000000*400
    plasvg = plasvg ..[[
    <circle cx="]].. mapcenter + cx..[[" cy="]].. 500 + cy ..[[" r="]].. 90 ..[[" style="fill:none;stroke:red;stroke-width:1;stroke-dasharray:4;stroke-opacity:0.5"/>]]

    local bt = {}
    local color = ""
    local fs = 12
    local textOffset = 10
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    local bti = 0

    for i, marker in ipairs(markers) do
        textOffset = -15
        local plname = markers[i].name[1]
        local PCx, PCy, PCz = markers[i].center[1],markers[i].center[2],markers[i].center[3]

        local bf = function() return function ()
            local redraw = false
            if self.selected.name ~= markers[i].name[1] then redraw = true end
            local dist = vectorLen(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)
            self.selected = {name = markers[i].name[1], dist = dist, warp = markers[i].warp, pos = {markers[i].center[1],markers[i].center[2],markers[i].center[3]}}
            DUSystem.setWaypoint("::pos{0,0,"..self.selected.pos[1]..","..self.selected.pos[2]..","..self.selected.pos[3].."}")
            if redraw == true  then windowsShow() if self.warpdrive then self.warpdrive.showWidget() end end
            self.warp = {}
            windowsShow()
        end end

        local bpx, bpy = PCx/100000000*400, PCy/100000000*400
        if marker.iconPath ~= nil then
            --DUSystem.print(markers[i].name[1])
            local html = '<img src="'..markers[i].iconPath..'" style="width:48px;height:48px;opacity:0.75">' 
            bti = bti + 1
            self.buttons[bti] = {html, bf(), { name = "tp_"..markers[i].name[1], class= "mapPlanet", width = 50, height = 50, posX = mapcenter - 25 + bpx, posY = 500 - 25 + bpy}}
            textOffset = 40
        else
            --DUSystem.print(markers[i].name[1])
            local html = marker.symbol
            bti = bti + 1
            self.buttons[bti] = {html, bf(), { name = "tp_"..markers[i].name[1], class= "mapMarker", width = 25, height = 25, posX = mapcenter - 12.5 + bpx, posY = 500 - 12.5 + bpy}}
        end

        if marker.warp == true then
            color = WFC
            fs = 15
        else 
            color = wAC
            textOffset = -15
            fs = 15
        end
        if plname == "Ion" or plname == "Thades" then textOffset = -30 end
        if plname == "Sicari" then textOffset = -50 end
        if marker.showName == true then
            plasvg = plasvg ..[[
                            <text x="]].. mapcenter + bpx..[[" y="]].. 500 + bpy + textOffset  ..[[" font-size="]]..fs..[[" text-anchor="middle" font-family="Play" alignment-baseline="baseline" fill="]]..color..[[">
                            <tspan x="]].. mapcenter + bpx..[[" >]]..plname ..[[</tspan>
                            </text>
                        ]]
        end
    end

    if self.warp.warp1Stop ~= nil then
        local swpx , swpy, swpz = self.warp.warp1Stop[1], self.warp.warp1Stop[2], self.warp.warp1Stop[3]
        local bf = function() return function()
            DUSystem.setWaypoint("::pos{0,0,"..swpx..","..swpy..","..swpz.."}")
        end end
        local bpx, bpy = swpx/100000000*400, swpy/100000000*400
        bti = bti + 1
        self.buttons[bti] = {"➀", bf(), { name = "wwp1", class= "mapMarker", width = 25, height = 25, posX = mapcenter - 12.5 + bpx, posY = 500 - 12.5 + bpy}}
    end
    if self.warp.warp2Stop ~= nil then
        local swpx , swpy, swpz = self.warp.warp2Stop[1], self.warp.warp2Stop[2], self.warp.warp2Stop[3]
        local bf = function() return function()
            DUSystem.setWaypoint("::pos{0,0,"..swpx..","..swpy..","..swpz.."}")
        end end
        local bpx, bpy = swpx/100000000*400, swpy/100000000*400
        bti = bti + 1
        self.buttons[bti] = {"➁", bf(), { name = "wwp2", class= "mapMarker", width = 25, height = 25, posX = mapcenter - 12.5 + bpx, posY = 500 - 12.5 + bpy}}
    end

    local ccpx, ccpy = cWPx/100000000*400, cWPy/100000000*400
    bti = bti + 1
    self.buttons[bti] = {[[<div><svg height="50" width="50">
            <text x="10" y="20" font-size="30" font-family="Play" text-anchor="middle" alignment-baseline="middle" fill="red">☟</text>
            </svg></div>]], nil, { name = "mypos", class= "mapMarker", width = 25, height = 30, posX = mapcenter - 12.5 + ccpx, posY = 500 - 30 + ccpy}}

    local function calculateWarpRoute(wpX, wpY, wpZ)
        wpX, wpY, wpZ = wpX or 0, wpY or 0, wpZ or 0
        local routeSubDiv = {}
        local indRT = 0
        local w1Dist = {}
        for i, marker in ipairs(markers) do
            if marker.warp == true then
                local cwd = vectorLen(markers[i].center[1]-wpX, markers[i].center[2]-wpY, markers[i].center[3]-wpZ)
                if cwd == 0 then 
                    self.warp.warp1Dest = markers[i]
                    self.warp.warp1Stop = markers[i].center
                    self.warp.warp2Dest = nil
                    self.warp.warp2Stop = nil
                    self.warp.warpDistance = vectorLen(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)
                    self.warp.cruiseDistance = 0
                    return
                end
                indRT = indRT + 1
                routeSubDiv[indRT] = {}
                local normX, normY, normZ = normalizeVec(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)
                local dist = vectorLen(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)
                local l = dist/5
                local n = 0
                for j=0, 5, 1 do
                    n = j * l
                    routeSubDiv[indRT][j+1] = {cWPx + normX * n, cWPy + normY * n, cWPz + normZ * n, i, n}
                end
                w1Dist[indRT] = {id = i, dist = cwd, warpDist = vectorLen(markers[i].center[1]-cWPx, markers[i].center[2]-cWPy, markers[i].center[3]-cWPz)}
            end
        end
        table.sort(w1Dist, function(a,b) return a.dist < b.dist end)
        
        local routeTest = {}
        local minDist = 999999999999999999999999999
        local totalDist = 0
        indRT = 0
        for i, marker in ipairs(markers) do
            if marker.warp == true then
                local mX, mY, mZ = markers[i].center[1], markers[i].center[2], markers[i].center[3]
                for i2, line in ipairs(routeSubDiv) do
                    if  marker ~= markers[routeSubDiv[i2][4]] then
                        for i3, subdiv in ipairs(line) do
                            local sX, sY, sZ = subdiv[1], subdiv[2], subdiv[3]
                            local cpX, cpY, cpZ, distCP = getClosestPointToLine(mX, mY, mZ, sX, sY, sZ, wpX, wpY, wpZ)
                            local dist = vectorLen(sX-cpX, sY-cpY, sZ-cpZ)
                            local dist1 = vectorLen(sX-cWPx, sY-cWPy, sZ-cWPz)
                            totalDist = distCP
                            local dist2 = vectorLen(mX-cpX, mY-cpY, mZ-cpZ)
                            local distTot = vectorLen(mX-sX, mY-sY, mZ-sZ)
                            if totalDist < minDist and dist+dist2 <= distTot + 10000 then
                                minDist = totalDist
                                indRT = indRT + 1
                                routeTest[indRT] = {subdiv[5]+dist, {sX, sY, sZ}, subdiv[4], {cpX, cpY, cpZ}, i, distCP}
                            end
                        end
                    end
                end
            end
        end
        
        local multi = true
        for i, route in ipairs(routeTest) do
            if w1Dist[1].dist < routeTest[indRT][6] then
                multi = false
            end
        end

        if multi == false then
            self.warp.warp1Dest = markers[w1Dist[1].id]
            self.warp.warp1Stop = markers[w1Dist[1].id].center
            self.warp.warp2Dest = nil
            self.warp.warp2Stop = nil
            self.warp.warpDistance = w1Dist[1].warpDist
            self.warp.cruiseDistance = w1Dist[1].dist
        else
            if indRT ~= 0 then
                self.warp.warp1Dest = markers[routeTest[indRT][3]]
                self.warp.warp1Stop = routeTest[indRT][2]
                self.warp.warp2Dest = markers[routeTest[indRT][5]]
                self.warp.warp2Stop = routeTest[indRT][4]
                self.warp.warpDistance = routeTest[indRT][1]
                self.warp.cruiseDistance = routeTest[indRT][6]
            else
                self.warp = {}
            end
        end
    end

    if self.warp.warp1Dest ~= nil then
        local pX, pY = self.warp.warp1Dest.center[1], self.warp.warp1Dest.center[2]
        local wpx, wpy = pX/100000000*400, pY/100000000*400
        plasvg = plasvg .. [[<polyline points="]].. mapcenter + ccpx .. "," .. 500 + ccpy .. " ".. mapcenter + wpx .. "," .. 500 + wpy ..[[" style="fill:none;stroke:red;stroke-width:1;stroke-dasharray:4"/>]]
        if self.warp.warp2Dest and self.warp.warp2Stop then
            pX, pY = self.warp.warp1Stop[1], self.warp.warp1Stop[2]
            wpx, wpy = pX/100000000*400, pY/100000000*400
            pX, pY = self.warp.warp2Dest.center[1], self.warp.warp2Dest.center[2]
            local wp1x, wp1y = pX/100000000*400, pY/100000000*400
            plasvg = plasvg .. [[<polyline points="]]..  mapcenter + wpx .. "," .. 500 + wpy .. " ".. mapcenter + wp1x .. "," .. 500 + wp1y ..[[" style="fill:none;stroke:red;stroke-width:1;stroke-dasharray:4"/>]]
            pX, pY = self.warp.warp2Stop[1], self.warp.warp2Stop[2]
            wpx, wpy = pX/100000000*400, pY/100000000*400
            pX, pY = self.selected.pos[1], self.selected.pos[2]
            wp1x, wp1y = pX/100000000*400, pY/100000000*400
            plasvg = plasvg .. [[<polyline points="]]..  mapcenter + wpx .. "," .. 500 + wpy .. " ".. mapcenter + wp1x .. "," .. 500 + wp1y ..[[" style="fill:none;stroke:red;stroke-width:0.5;stroke-dasharray:2 3"/>]]
        else
            pX, pY = self.warp.warp1Stop[1], self.warp.warp1Stop[2]
            wpx, wpy = pX/100000000*400, pY/100000000*400
            pX, pY = self.selected.pos[1], self.selected.pos[2]
            wp1x, wp1y = pX/100000000*400, pY/100000000*400
            plasvg = plasvg .. [[<polyline points="]]..  mapcenter + wpx .. "," .. 500 + wpy .. " ".. mapcenter + wp1x .. "," .. 500 + wp1y ..[[" style="fill:none;stroke:red;stroke-width:0.5;stroke-dasharray:2 3"/>]]
        end
    end

    local bf = function() return function()
                local sspx, sspy, sspz = self.selected.pos[1], self.selected.pos[2], self.selected.pos[3]
                calculateWarpRoute(sspx, sspy, sspz)
                DUSystem.print("Calculating multi warp route")
                windowsShow()
            end end
    bti = bti + 1
    self.buttons[bti] = {"CALCULATE MULTI WARPS ROUTE", bf(), {name = "cmwr", width = 250, height = 25, posX = 5, posY = 870}}

    bf = function() return function()
                DUSystem.setWaypoint("::pos{0,0,"..self.selected.pos[1]..","..self.selected.pos[2]..","..self.selected.pos[3].."}")
                P.AP_destination.value = self.selected.pos
                P.AP_destination.name = self.selected.name
                DUSystem.print("Autopilot destination set to: "..self.selected.name)
                windowsShow()
            end end
    bti = bti + 1
    self.buttons[bti] = {"SET AS AUTOPILOT DESTINATION", bf(), { name = "saad", width = 250, height = 25, posX = 5, posY = 840}}

    plasvg = plasvg ..[[<text x="]].. 130 ..[[" y="]].. 160 ..[[" font-size="20" text-anchor="middle" font-family="Play" alignment-baseline="baseline" fill="]]..WTC..[[">]]..self.pageNum..[[</text>]]

    if self.selected.name ~= "n/a" then
        local pX, pY = self.selected.pos[1], self.selected.pos[2]
        local wpx, wpy = pX/100000000*400, pY/100000000*400
        plasvg = plasvg .. [[<circle cx="]].. mapcenter + wpx..[[" cy="]].. 500 + wpy ..[[" r="15" stroke-width="2" stroke="red" fill="none"/>]]
    end

    bf = function() return function()
        self.pageNum = utils.clamp(self.pageNum - 1, 1, 100)
        windowsShow()
    end end
    bti = bti + 1
    self.buttons[bti] = {"<<", bf(), {name = "prevPage", width = 25, height = 25, posX = 5, posY = 150}}

    bf = function() return function()
        self.pageNum = utils.clamp(self.pageNum + 1, 1, 100)
        windowsShow()
    end end
    bti = bti + 1
    self.buttons[bti] = {">>", bf(), {name = "nextPage", width = 25, height = 25, posX = 230, posY = 150}}

    local maxButtons = 20
    for i, v in ipairs(bookmarks) do
        if i >= (self.pageNum-1) * maxButtons and i <= self.pageNum * maxButtons then
            local bmf = function() return function()
                DUSystem.setWaypoint(bookmarks[i].pos)
                local bx, by, bz = c2WC(bookmarks[i].pos)
                local redraw = false
                if self.selected.name ~= bookmarks[i].name[1] then redraw = true end
                local dist = vectorLen(bx-cWPx, by-cWPy, bz-cWPz)
                self.selected = {name = bookmarks[i].name[1], dist = dist, warp = bookmarks[i].warp ~= nil and bookmarks[i].warp or false, pos = {bx, by, bz}}
                
                if redraw == true  then windowsShow() if self.warpdrive then self.warpdrive.showWidget() end end
            end end
            bti = bti + 1
            local btName = bookmarks[i].name[1]
            self.buttons[bti] = {btName, bmf(), {name = "tpbt_"..btName, width = 250, height = 25, posX = 5 , posY = 180 + (i-1)*30 - (self.pageNum-1) * (maxButtons-1)*30}}
        end
    end

    local tempWarp = "n/a"
    if self.selected.warp == true then tempWarp = ceil(((DUConstruct.getMass()/100) * (self.selected.dist / 200000))*0.00025) end
    local closestP = "n/a"
    local planetDistance = 999999999999
    local cpi = 0
    local cpdist = 0
    for i, v in pairs(Helios) do
        cpdist = vectorLen(v.center[1]-self.selected.pos[1], v.center[2]-self.selected.pos[2], v.center[3]-self.selected.pos[3])
        if cpdist < planetDistance then
            planetDistance = cpdist
            closestP = v.name[1]
        end
    end

    local d1Name = self.warp.warp1Dest ~= nil and self.warp.warp1Dest.name[1] or "n/a"
    local d2Name = self.warp.warp2Dest ~= nil and self.warp.warp2Dest.name[1] or "n/a"
    local warpable = self.warp.warpDistance ~= nil and floor(self.warp.warpDistance/1000/200).."su" or "n/a"
    local cruise = self.warp.cruiseDistance ~= nil and floor(self.warp.cruiseDistance/1000/200).."su" or "n/a"

    local textSvg = [[
                    <text x="]].. 5 ..[[" y="]].. 25 ..[[" font-size="20" text-anchor="start" font-family="Play" alignment-baseline="baseline" fill="]]..WTC..[[">
                    <tspan x="]].. 5 ..[[" dy="20" >Name: ]]..self.selected.name ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Distance : ]].. format('%.2f SU',self.selected.dist / 200000) ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Warpable: ]]..tostring(self.selected.warp) ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Warpcells: ]].. tempWarp ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Closest planet: ]].. closestP .."("..floor(planetDistance/1000/200).."su)"..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="800" >First Warp destination: ]].. d1Name ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Second Warp destination: ]].. d2Name ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Warpable distance: ]].. warpable ..[[</tspan>
                    <tspan x="]].. 5 ..[[" dy="20" >Remaining Cruise distance: ]].. cruise ..[[</tspan>
                    </text>
                    ]]

    plasvg = '<div><svg style="position: absolute; left:0px; top:0px"  viewBox="0 0 1300 1000">'..plasvg..textSvg..'</svg></div>'

    return plasvg
end

