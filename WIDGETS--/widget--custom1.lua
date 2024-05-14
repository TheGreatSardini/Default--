--widget--custom1.lua

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

local delay = 0
local widget_font = "Play"
local utils = require("cpml/utils")
local BookmarksPOI = require (widgetsFolder .. ".BookmarksPOI")
local BookmarksCustoms = require (widgetsFolder .. ".BookmarksCustoms")

local planets = {}
local ind = 0
for k, planet in pairs(Helios) do
    ind = ind + 1
    planets[ind] = planet
end

ind = 0
local bookmarks = {}
for i, poi in ipairs(BookmarksPOI) do
    ind = ind + 1
    bookmarks[ind] = poi
end
for i, poi in ipairs(BookmarksCustoms) do
    ind = ind + 1
    bookmarks[ind] = poi
end

ind = ind + 1
bookmarks[ind] = {id = 999, center = {0,0,0}, name = {"Safe Zone"}, radius = 100000, type = {"SZ"}}

ind = ind + 1
bookmarks[ind] = {id = 9999, center = {0,0,0}, name = {"Closest Safe Zone"}, radius = 100000, type = {"SZ"}}


local entriesTotNum = ind

local moon_distance = 20  -- SU
moon_distance = moon_distance * 200 * 1000

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
    self.name = 'SOLAR SYSTEM+-' -- name of the widget
    self.SVGSize = {x=self.width,y=self.height} -- size of the window to fit the svg, in pixels
    self.pos = {x=0, y=0}
    self.class = 'widgets'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = false  --allow widget to be dragged
    self.fixed = true  --prevent widget from going over others
    self.title = nil
    self.scalable = false
    
    self.click = false
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

--function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
--    return nil
--end

--function WidgetsPlusPlusCustom.loadData(self)
--end
--
--function WidgetsPlusPlusCustom.saveData(self)
--end

function WidgetsPlusPlusCustom.onActionStart(self, action) -- uncomment to receive pressed key
    if action == "leftmouse" and not ALT then
        self.click = true 
    end
end

function WidgetsPlusPlusCustom.onActionStop(self, action) -- uncomment to receive released key
    if action == "leftmouse" and not ALT then
        self.click = false 
    end
end

-- function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive held key
--      --DUSystem.print(action)
-- end

--function WidgetsPlusPlusCustom.onInputText(self, text) -- uncomment to process lua chat
    --DUSystem.print("typed: "..text)
--end

----------------
-- WIDGET SVG --
----------------
local sqrt, tan, rad, atan, format, clamp, concat, abs, floor = math.sqrt, math.tan, math.rad, math.atan, string.format, utils.clamp, table.concat, math.abs, math.floor

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end


local function intersectVecSphere(posx,posy,posz, dirx,diry,dirz, centerx,centery,centerz, radius)
    local t = 200000000
    if vectorLen(posx-centerx,posy-centery,posz-centerz) < radius then
        posx,posy,posz = posx+dirx*t,posy+diry*t,posz+dirz*t
        dirx,diry,dirz = -dirx,-diry,-dirz
    end
    local offsetx,offsetxy,offsetxz = posx-centerx,posy-centery,posz-centerz --ray.position - sphere.position
    local b = dotVec(offsetx,offsetxy,offsetxz,dirx,diry,dirz) --offset:dot(ray.direction)
    local c = dotVec(offsetx,offsetxy,offsetxz,offsetx,offsetxy,offsetxz) - radius * radius --offset:dot(offset) - sphere.radius * sphere.radius
    if c > 0 and b > 0 then
        return false
    end
    local discr = b * b - c
    if discr < 0 then
        return false
    end
    t = -b - sqrt(discr)
    t = t < 0 and 0 or t
    return {posx+dirx*t,posy+diry*t,posz+dirz*t}, t--ray.position + ray.direction * t, t
end


function WidgetsPlusPlusCustom.SVG_Update(self)
    delay = delay + 1 <= 60 and delay + 1 or 60
    if delay >= 60 then
        local WTC = P.MS.wTC.value --WIDGET_TEXT_COLOR
        local BBC = P.MS.BBC.value --BUTTON_BORDER_COLOR
        local BC = P.MS.BC.value --BUTTON_COLOR
        local WC = P.MS.WC.value --WN_COLOR
        local AC = P.MS.wAC.value --WIDGET_ANIM_COLOR
        local FC = P.MS.WFC.value --WIDGET_FIXED_COLOR
    
        local deg2px = self.height / self.vFov
        local near = 0.1
        local far = 100000000.0
        local aspectRatio = self.height / self.width
        local tanFov = 1.0 / tan(rad(self.vFov) * 0.5)
        local field = -far / (far - near)
        local af = aspectRatio*tanFov
        local nq = near*field
        local camWP = DUSystem.getCameraWorldPos()
        local camWPx, camWPy, camWPz = camWP[1], camWP[2], camWP[3]
        local camWF = DUSystem.getCameraWorldForward()
        local camWFx, camWFy, camWFz = camWF[1], camWF[2], camWF[3]
        local camWR = DUSystem.getCameraWorldRight()
        local camWRx, camWRy, camWRz = camWR[1], camWR[2], camWR[3]
        local camWU = DUSystem.getCameraWorldUp()
        local camWUx, camWUy, camWUz = camWU[1], camWU[2], camWU[3]
    
        local cWP = DUConstruct.getWorldPosition()
        local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
        local cWOU = DUConstruct.getWorldOrientationUp()
        local cWOUx, cWOUy, cWOUz = cWOU[1], cWOU[2], cWOU[3]
        local cWOF = DUConstruct.getWorldOrientationForward()
        local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3]
        local cWOR = DUConstruct.getWorldOrientationRight()
        local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3]
        local cAV = DUConstruct.getWorldVelocity ()
        local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
        local velMag = sqrt(cAVx^2+cAVy^2+cAVz^2)
    
        local posX, posY, posZ = 0, 0, 0
        local vx, vy, vz = 0, 0, 0
        local sx, sy, sz = 0, 0, 0
        local sPX, sPY = 0, 0
        local dist = 0
        local pCx, pCy, pCz = 0, 0, 0
        local posX, posY, posZ = 0, 0, 0
        local big = 20
        local little = 14
        local dist_str = ""
        local SVGind = 0

        local FIVS = intersectVecSphere(cWPx, cWPy, cWPz, cWOFx, cWOFy, cWOFz, 13856549.3576,7386341.6738,-258459.8925, 18000000) --::pos{0,0,13856549.3576,7386341.6738,-258459.8925} --forward safe zone
        local szcnx, szcny, szcnz = normalizeVec(cWPx-13856549.3576, cWPy-7386341.6738, cWPz+258459.8925)
        --DUSystem.print('CIVS')
        local CIVS = {0,0,0}
        local dist2SZcenter = vectorLen(cWPx-13856549.3576, cWPy-7386341.6738, cWPz+258459.8925)
        if dist2SZcenter < 18000000 then --DUSystem.print('inside')
            local szcnx, szcny, szcnz = normalizeVec(cWPx-13856549.3576, cWPy-7386341.6738, cWPz-258459.8925)
            CIVS = intersectVecSphere(cWPx, cWPy, cWPz, szcnx, szcny, szcnz, 13856549.3576,7386341.6738,-258459.8925, 18000000) -- closest safe zone inside
        else --DUSystem.print('outside')
            local szcnx, szcny, szcnz = normalizeVec(13856549.3576-cWPx, 7386341.6738-cWPy, -258459.8925-cWPz)
            CIVS = intersectVecSphere(cWPx, cWPy, cWPz, szcnx, szcny, szcnz, 13856549.3576,7386341.6738,-258459.8925, 18000000) -- closest safe zone outside
        end
    
        if P.AP_destination.value ~= nil and #P.AP_destination.value == 3 and P.AP_destination.value[1] ~= 0 and P.AP_destination.value[2] ~= 0 then
            bookmarks[entriesTotNum+1] = {center = P.AP_destination.value, name = {'Destination'}, radius = 0, type = {'Destination'}}
            --DUSystem.print("destination found")
        else
            bookmarks[entriesTotNum+1] = {} --{center = {0,0,0}, name = {" "}, radius = 0, type = {''}}
        end
    
        local function projection2D()
            vx = posX * camWRx + posY * camWRy + posZ * camWRz
            vy = posX * camWFx + posY * camWFy + posZ * camWFz
            vz = posX * camWUx + posY * camWUy + posZ * camWUz
            sx = (af * vx)/vy
            sy = ( -tanFov * vz)/vy
            sz = ( -field * vy + nq)/vy
            sPX, sPY = (sx+1)*self.width*0.5, (sy+1)*self.height*0.5 -- screen pos X Y
            dist = sqrt(posX*posX + posY*posY + posZ*posZ) -- distance from camera to pos
        end
        
        local SVG = {}
        SVGind = SVGind + 1
        SVG[SVGind] = format('<div><svg style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >', self.width, self.height)
        if ALT == true then
            SVGind = SVGind + 1
            SVG[SVGind] = format('<circle cx="%.1f" cy="%.1f" r="4" stroke="white" stroke-width="2" fill="black" fill-opacity="0.2"/>', self.width/2, self.height/2)  -- Overlay alignment circle
        end
        
        posX = cWOFx*1000000000000 - camWPx
        posY = cWOFy*1000000000000 - camWPy
        posZ = cWOFz*1000000000000 - camWPz
        projection2D()
        SVGind = SVGind + 1
        SVG[SVGind] = format('<text x="%.2f" y="%.2f" font-size="20" text-anchor="middle" font-family="%s" alignment-baseline="middle" fill="%s">╬</text>', sPX, sPY, widget_font, FC)
        
        if velMag > 5 then
            posX = (cAVx)*1000000000000 - camWPx
            posY = (cAVy)*1000000000000 - camWPy
            posZ = (cAVz)*1000000000000 - camWPz
            projection2D()
        end
        SVGind = SVGind + 1
        SVG[SVGind] = format('<text x="%.2f" y="%.2f" font-size="20" text-anchor="middle" font-family="%s" alignment-baseline="middle" fill="%s">┼</text>', sPX, sPY, widget_font, AC)

        local bti = 0
        self.buttons = {}
        for i, v in ipairs(planets) do
            if planets[i].center ~= nil and #planets[i].center == 3 then
                pCx, pCy, pCz = planets[i].center[1], planets[i].center[2], planets[i].center[3]
            elseif planets[i].pos ~= nil and string.sub(planets[i].pos,1,6) == '::pos{' then
                pCx, pCy, pCz = convertToWorldCoordinates(planets[i].pos)
            else
                goto skip
            end
            posX = pCx - camWPx
            posY = pCy - camWPy
            posZ = pCz - camWPz
            projection2D()

            if sz < 1 and sPX > 0 and sPX < self.width and sPY > 0  and sPY < self.height then
                if dist >= 200000 then
                    dist_str = format('%.2f SU', dist / 200000)
                elseif dist >= 1000 then
                    dist_str = format('%.1f km', dist / 1000)
                else
                    dist_str = format('%.0f m', dist)
                end
                local bmradius = planets[i].radius ~= nil and planets[i].radius or 1
                local bmName = planets[i].name and type(planets[i].type) == "table" and planets[i].name[1] or "missing name"
                local e_T = planets[i].type and type(planets[i].type) == "table" and planets[i].type[1] or "bookmark"
                --DUSystem.print(e_T)

                --DUSystem.print(bmName)
                if dist > bmradius*5 then
                    local size = atan(bmradius/2, dist) * (self.width / tan(rad(self.hFov * 0.5)))
                    local offsetx, offsety = 0, 0
                    if bmName == 'Sicari' then offsety = -70 end
                    local fop = inspace == 1 and 1 or 0.8
                    SVGind = SVGind + 1
                    SVG[SVGind] = format('<circle cx=%.2f cy=%.2f r=%.2f stroke=%s stroke-width=%.f stroke-opacity=%.1f fill=%s fill-opacity="0.2"/>', sPX, sPY, size, BBC, 2, fop, WC)
                    if e_T == "Planet" or (e_T == "Moon" and dist < moon_distance) or (e_T == "Asteroid" and dist < moon_distance) then
                        SVGind = SVGind + 1
                        SVG[SVGind] = format('<text x="%.2f" y="%.2f" style="fill:%s; text-anchor: middle; font-family: Play; fill-opacity:%.1f">', sPX+offsetx, sPY+offsety, WTC, fop)
                                    ..format('<tspan x="%.2f" dy="%.2f" style="font-size: %.1f; fill-opacity:%.1f">%s</tspan>', sPX+offsetx, size + big, big, fop, bmName)
                                    ..format('<tspan x="%.2f" dy="%.2f" style="font-size: %.1f; fill-opacity:%.1f">%s</tspan>', sPX+offsetx, little, little, fop, dist_str)
                                    .."</text>"
                        local destName = bmName
                        local aWPx, aWPy, aWPz = normalizeVec(cWPx-pCx, cWPy-pCy, cWPz-pCz)
                        local aT = planets[i].atmosphereThickness + bmradius
                        aWPx, aWPy, aWPz = pCx + aT * aWPx, pCy + aT * aWPy, pCz + aT * aWPz
                        local destPos = {aWPx, aWPy, aWPz}
                        local bf = function() return function()
                                                DUSystem.print('Detination locked on: '..destName)
                                                DUSystem.setWaypoint('::pos{0,0,'..aWPx..','..aWPy..','..aWPz..'}')
                                                P.AP_destination.value = destPos
                                                P.AP_destination.name = destName
                                                windowsShow()
                                                end end
                        bti = bti + 1
                        local bsize = size>50 and size or 50
                        --self.buttons[bti] = {"X", bf(), {name = planets[i].name[1], class = nil, width = bsize, height = bsize, posX = sPX-bsize/2, posY = sPY-bsize/2}}
                        self.buttons[bti] = {"", bf(), {name = planets[i].name[1], class = 'separator', width = bsize, height = bsize, posX = sPX-bsize/2, posY = sPY-bsize/2}}

                        if self.click == true and abs(sPX - self.width/2) < bsize/2 and abs(sPY - self.height/2) < bsize/2 and (P.AP_destination.name == nil or P.AP_destination.name ~= nil and destName ~= P.AP_destination.name) then
                            DUSystem.print('Detination locked on: '..destName)
                            DUSystem.setWaypoint('::pos{0,0,'..aWPx..','..aWPy..','..aWPz..'}')
                            P.AP_destination.value = destPos
                            P.AP_destination.name = destName
                            self.click = false
                            --windowsShow()
                        end
                    end
                end
            end
            ::skip::
        end

        for i, v in ipairs(bookmarks) do
            if bookmarks[i].id == 999 then
                if FIVS == false then
                    goto skip
                else
                    bookmarks[i].center = FIVS
                    --DUSystem.print(IVS[1].."/"..IVS[2].."/"..IVS[3].."/"..ivsD)
                end
            elseif bookmarks[i].id == 9999 then
                if CIVS == false then
                    goto skip
                else
                    bookmarks[i].center = CIVS
                    --DUSystem.print(IVS[1].."/"..IVS[2].."/"..IVS[3].."/"..ivsD)
                end
            end
        
            if bookmarks[i].center ~= nil and #bookmarks[i].center == 3 then
                pCx, pCy, pCz = bookmarks[i].center[1], bookmarks[i].center[2], bookmarks[i].center[3]
            elseif bookmarks[i].pos ~= nil and string.sub(bookmarks[i].pos,1,6) == '::pos{' then
                pCx, pCy, pCz = convertToWorldCoordinates(bookmarks[i].pos)
            else
                goto skip
            end
            posX = pCx - camWPx
            posY = pCy - camWPy
            posZ = pCz - camWPz
            projection2D()

            if sz < 1 and sPX > 0 and sPX < self.width and sPY > 0  and sPY < self.height then
                if dist >= 200000 then
                    dist_str = format('%.2f SU', dist / 200000)
                elseif dist >= 1000 then
                    dist_str = format('%.1f km', dist / 1000)
                else
                    dist_str = format('%.0f m', dist)
                end
                local bmradius = bookmarks[i].radius ~= nil and bookmarks[i].radius or 1
                local bmName = bookmarks[i].name and type(bookmarks[i].type) == "table" and bookmarks[i].name[1] or "missing name"
                local destName = bmName
                local destPos = {pCx, pCy, pCz}
                local e_T = bookmarks[i].type and type(bookmarks[i].type) == "table" and bookmarks[i].type[1] or "bookmark"
                --DUSystem.print(e_T)

                local sF = 1.5
                local fop = inspace == 0 and 1 or 0.4
                if dist > currentPlanetRadius/2 then
                    fop = 0.4
                end

                local bf = function() return function()
                                        DUSystem.print('Detination locked on: '..destName)
                                        DUSystem.setWaypoint('::pos{0,0,'..destPos[1]..','..destPos[2]..','..destPos[3]..'}')
                                        P.AP_destination.value = destPos
                                        P.AP_destination.name = destName
                                        windowsShow()
                                        end end

                local bsize = 50
                if abs(sPX - self.width/2) < bsize/2 and abs(sPY - self.height/2) < bsize/2 then
                    fop = 1
                    if self.click == true and (P.AP_destination.name == nil or P.AP_destination.name ~= nil and destName ~= P.AP_destination.name) then
                        DUSystem.print('Detination locked on: '..destName)
                        DUSystem.setWaypoint('::pos{0,0,'..destPos[1]..','..destPos[2]..','..destPos[3]..'}')
                        P.AP_destination.value = destPos
                        P.AP_destination.name = destName
                        self.click = false
                    end
                end

                if e_T == "Destination" then
                    fop = 1
                    SVGind = SVGind + 1
                    SVG[SVGind] = format([[<polyline style="opacity:%.1f;fill:none;stroke:%s;stroke-width:%.2f;stroke-miterlimit:%.2f;" 
                    points="%.1f,%.1f %.1f,%.1f %.1f,%.1f"/>]], fop, BBC, 2*sF, 1*sF, sPX-(10*sF), sPY+(10*sF), sPX-(20*sF), sPY+(20*sF), sPX-(50*sF), sPY+(20*sF))
                    ..format([[<text text-anchor="end" alignment-baseline="hanging" x="%.1f" y="%.1f" style="fill-opacity:%.1f;font-size:%.2fpx;fill:%s">%s (%s)</text>]], sPX-(25*sF), sPY+(22*sF), fop, 11*sF, WTC, bmName, dist_str)
                    bti = bti + 1
                    self.buttons[bti] = {"", bf(), {name = bookmarks[i].name[1], class = 'separator', width = bsize, height = bsize, posX = sPX-bsize/2, posY = sPY-bsize/2}}
                    SVGind = SVGind + 1
                    SVG[SVGind] = format([[<circle style="opacity:%.1f;fill:none;stroke:%s;stroke-width:%.2f;stroke-miterlimit:%.2f;" cx="%.1f" cy="%.1f" r="%.1f" />]], fop, BBC, 2*sF, 1*sF, sPX, sPY, 10*sF)

                elseif e_T == "SZ" then
                    if inspace == 1 then
                        fop = 1
                        local szT = bmName
                        if DUConstruct.isInPvPZone() == false then
                            szT = szT:gsub("%Safe", "PVP")
                        end
                        SVGind = SVGind + 1
                        SVG[SVGind] = format([[<polyline style="opacity:%.1f;fill:none;stroke:%s;stroke-width:%.2f;stroke-miterlimit:%.2f;" 
                        points="%.1f,%.1f %.1f,%.1f %.1f,%.1f"/>]], fop, BBC, 2*sF, 1*sF, sPX+(10*sF), sPY+(10*sF), sPX+(20*sF), sPY+(20*sF), sPX+(50*sF), sPY+(20*sF))
                        ..format([[<text text-anchor="start" alignment-baseline="hanging" x="%.1f" y="%.1f" style="fill-opacity:%.1f;font-size:%.2fpx;fill:%s">%s (%s)</text>]], sPX+(25*sF), sPY+(22*sF), fop, 11*sF, WTC, szT, dist_str)
                        bti = bti + 1
                        self.buttons[bti] = {"", bf(), {name = bookmarks[i].name[1], class = 'separator', width = bsize, height = bsize, posX = sPX-bsize/2, posY = sPY-bsize/2}}
                        SVGind = SVGind + 1
                        SVG[SVGind] = format([[<circle style="opacity:%.1f;fill:none;stroke:%s;stroke-width:%.2f;stroke-miterlimit:%.2f;" cx="%.1f" cy="%.1f" r="%.1f" />]], fop, BBC, 2*sF, 1*sF, sPX, sPY, 10*sF)
                    end
                else
                    if (dist < currentPlanetRadius*5 and bookmarks[i].bodyId ~= 0 ) or (inspace == 1 and bookmarks[i].bodyId == 0 ) then
                        local w = ""
                        if bookmarks[i].warp ~= nil and bookmarks[i].warp == true then
                            w = "(Warp Available)"
                        end
                        SVGind = SVGind + 1
                        SVG[SVGind] = format([[<polyline style="opacity:%.1f;fill:none;stroke:%s;stroke-width:%.2f;stroke-miterlimit:%.2f;" 
                        points="%.1f,%.1f %.1f,%.1f %.1f,%.1f"/>]], fop, BBC, 2*sF, 1*sF, sPX-(10*sF), sPY-(10*sF), sPX-(20*sF), sPY-(20*sF), sPX-(50*sF), sPY-(20*sF))
                        ..format([[<text text-anchor="end" alignment-baseline="bottom" x="%.1f" y="%.1f" style="fill-opacity:%.1f;font-size:%.2fpx;fill:%s">%s (%s)</text>]], sPX-(25*sF), sPY-(22*sF), fop, 11*sF, WTC, bmName..w, dist_str)
                        bti = bti + 1
                        self.buttons[bti] = {"", bf(), {name = bookmarks[i].name[1], class = 'separator', width = bsize, height = bsize, posX = sPX-bsize/2, posY = sPY-bsize/2}}
                        SVGind = SVGind + 1
                        SVG[SVGind] = format([[<circle style="opacity:%.1f;fill:none;stroke:%s;stroke-width:%.2f;stroke-miterlimit:%.2f;" cx="%.1f" cy="%.1f" r="%.1f" />]], fop, BBC, 2*sF, 1*sF, sPX, sPY, 10*sF)
                    end
                end
                --DUSystem.print(e_T)
            end
            ::skip::
        end
        SVGind = SVGind + 1
        SVG[SVGind] = '</svg></div>'
        --DUSystem.print(concat(SVG))
        return concat(SVG)
    end
    return ""
end
