--widget--custom3.lua

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

    self.stopDist = 0.25
    self.atmoTravel = false
    self.altitudeHold = 0
    self.arrived = false
    self.atmoLockedDestination = {}
    self.input = false
    self.precision = 0
    self.maxSpeed = 50000
    self.maxSpeedIncrement = 1000
    
    self.buttons = {} -- list of buttons to be implemented in widget
    self.name = "TRAVELER+-" -- name of the widget
    self.SVGSize = {x=500,y=200} -- size of the window to fit the svg, in pixels
    self.pos = {x=500, y=500}
    self.class = "widgets"  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
    self.title = nil
    self.scalable = true
    
    self.inspace = 0
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

function WidgetsPlusPlusCustom.getFixed(self) --returns the widget name
    return self.fixed
end

function WidgetsPlusPlusCustom.getScalable(self) --returns the widget name
    return self.scalable
end

function WidgetsPlusPlusCustom.getDraggable(self) --returns the widget name
    return self.draggable
end

function WidgetsPlusPlusCustom.getPos(self) --returns the widget name
    return self.pos
end

function WidgetsPlusPlusCustom.getButtons(self) --returns buttons list
    return self.buttons
end

function WidgetsPlusPlusCustom.onActionStart(self, action)
    if action == "up" or action == "forward" or action == "backward" then self.input = true
    elseif action == "option2" then
        DUSystem.print("Travel engaged, press any key to abort!")
        P.AP_lockedDestination = P.AP_destination.value
        Nav:resetThrottleValue()
        Nav:setThrottleValue(0)
        if self.inspace == 0 then
            self.altitudeHold = alt
            self.atmoTravel = true
            self.arrived = false
        else
            self.atmoTravel = false
        end
    end
end

function WidgetsPlusPlusCustom.onActionStop(self, action)
    if action == "up" or action == "forward" or action == "backward" then self.input = false end
    --DUSystem.print(tostring(self.input))
end

function WidgetsPlusPlusCustom.loadData(self)
    local load = Data:getData("TRAVELER") ~= nil and Data:getData("TRAVELER") or nil
    if load then
        self.stopDist = load.a or 0.25
        self.atmoTravel = load.b or false
        self.altitudeHold = load.c or 0
        self.arrived = load.d or false
        self.atmoLockedDestination = load.e or {}
        self.precision = load.f or 0
        self.maxSpeed = load.g or 50000
    end
end
--
function WidgetsPlusPlusCustom.saveData(self)
    if Data then
        local save = {a=self.stopDist, b=self.atmoTravel, c=self.altitudeHold, d=self.arrived, e=self.atmoLockedDestination, f=self.precision, g=self.maxSpeed}
        Data:setData("TRAVELER",save)
    end
end

local abs, floor, asin, sqrt, cos, acos, sin, deg, atan, rad, sign, clamp, rad2deg, max, ceil = math.abs, math.floor, math.asin, math.sqrt, math.cos, math.acos, math.sin, math.deg, math.atan, math.rad, utils.sign, utils.clamp, constants.rad2deg, math.max, math.ceil
local format = string.format

local function vectorLen(x,y,z)
    return sqrt(x*x+y*y+z*z)
end

local function vectorLen2(x,y,z)
    return x*x+y*y+z*z
end

local function norm(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

local function cross(x, y, z, vx, vy, vz)
    return y*vz - z*vy, z*vx - x*vz, x*vy - y*vx
end

local function project_on_plane(x,y,z,nx,ny,nz)
    local dot = dotVec(x,y,z,nx,ny,nz)
    local len2 = vectorLen2(nx,ny,nz)
    return x-(dot*nx)/len2, y-(dot*ny)/len2, z-(dot*nz)/len2
end

local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function dotVec(x1,y1,z1,x2,y2,z2)
    return x1*x2 + y1*y2 + z1*z2
end

local function getAARo(ox, oy, oz, nx, ny, nz, px, py, pz)
    ox, oy, oz = normalizeVec(ox, oy, oz)
    nx, ny, nz = normalizeVec(nx, ny, nz)
    local ax, ay, az = cross(ox, oy, oz, nx, ny, nz)
    local axisLen = vectorLen(ax, ay, az)
    local angle = 0
    ax, ay, az = normalizeVec(ax, ay, az)
    if axisLen > 0.000001
    then
        angle = asin(clamp(axisLen, 0, 1))
    else
        ax, ay, az = px, py, pz
    end
    if dotVec(ox, oy, oz, nx, ny, nz) < 0
    then
        angle = math.pi - angle
    end
    return ax, ay, az, angle
end

local function rotateVec(vx, vy, vz, phi, ax, ay, az)
    local l = sqrt(ax*ax + ay*ay + az*az)
    local ux, uy, uz = ax/l, ay/l, az/l
    local cs, s = cos(phi), sin(phi)
    local m1x, m1y, m1z = (cs + ux * ux * (1-cs)), (ux * uy * (1-cs) - uz * s), (ux * uz * (1-cs) + uy * s)
    local m2x, m2y, m2z = (uy * ux * (1-cs) + uz * s), (cs + uy * uy * (1-cs)), (uy * uz * (1-cs) - ux * s)
    local m3x, m3y, m3z = (uz * ux * (1-cs) - uy * s), (uz * uy * (1-cs) + ux * s), (cs + uz * uz * (1-cs))
    return m1x*vx+m1y*vy+m1z*vz, m2x*vx+m2y*vy+m2z*vz, m3x*vx+m3y*vy+m3z*vz
end

local function getConstructRot(x, y, z)
    if x == nil then x, y, z = -1,0,0 end
    x, y, z = norm(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CUx, CUy, CUz = cWOUPx, cWOUPy, cWOUPz
    local cx, cy, cz = cross(x, y, z, CUx, CUy, CUz)
    local rAx, rAy, rAz = norm(cx, cy, cz) -- rot axis
    local ConstructRot = acos(clamp(dotVec(rAx, rAy, rAz,CRx, CRy, CRz), -1, 1)) * rad2deg
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CUx, CUy, CUz) < 0 then ConstructRot = -ConstructRot end
    return ConstructRot
end

local function getConstructPitch(x, y, z)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = norm(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CFx, CFy, CFz = cWOFx, cWOFy, cWOFz
    local cx, cy, cz = cross(x, y, z, CRx, CRy, CRz)
    local pAx, pAy, pAz = norm(cx, cy, cz) --pitch axis
    local ConstructPitch = acos(clamp(dotVec(pAx, pAy, pAz, CFx, CFy, CFz), -1, 1)) * rad2deg
    cx, cy, cz = cross(pAx, pAy, pAz, CFx, CFy, CFz)
    if dotVec(cx, cy, cz, CRx, CRy, CRz) < 0 then ConstructPitch = -ConstructPitch end
    return ConstructPitch
end

local function getConstructRoll(x,y,z)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = norm(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CFx, CFy, CFz = -cWOFx, -cWOFy, -cWOFz
    local cx, cy, cz = cross(x, y, z, CFx, CFy, CFz)
    local rAx, rAy, rAz = norm(cx, cy, cz) --roll Axis
    local ConstructRoll = acos(clamp(dotVec(rAx, rAy, rAz, CRx, CRy, CRz), -1, 1)) * rad2deg
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CFx, CFy, CFz) < 0 then ConstructRoll = -ConstructRoll end
    return ConstructRoll
end

local function rollAngularVelocity(x,y,z, angle, speed)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = norm(x,y,z)
    local CFx, CFy, CFz = -cWOFx, -cWOFy, -cWOFz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(-angle), CFx, CFy, CFz) end
    local RollDeg = getConstructRoll(x, y, z)
    local PIDget = 0-RollDeg*0.05*speed
    return PIDget * CFx, PIDget * CFy, PIDget * CFz
end

local function pitchAngularVelocity(x,y,z, angle, speed)
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = norm(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(-angle), CRx, CRy, CRz) end
    local PitchDeg = getConstructPitch(x, y, z)
    local PIDget = 0-PitchDeg*0.05*speed
    return PIDget * CRx, PIDget * CRy, PIDget * CRz
end

local function yawAngularVelocity(x,y,z, angle, speed)
    if x == nil then x, y, z = -1,0,0 end
    x, y, z = norm(x,y,z)
    local CUx, CUy, CUz = cWOUPx, cWOUPy, cWOUPz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(angle), CUx, CUy, CUz) end
    local YawDeg = getConstructRot(x, y, z)
    local PIDget = 0-YawDeg*0.5*speed
    return PIDget * CUx, PIDget * CUy, PIDget * CUz
end

function yawAngleToPos(x,y,z) -- renturns angle in deg
    local popx, popy, popz = project_on_plane(x-cWPx, y-cWPy, z-cWPz, cWOUPx, cWOUPy, cWOUPz)
    local crx, cry, crz = cross(cWOFx, cWOFy, cWOFz, popx, popy, popz)
    local dot1 = dotVec(crx, cry, crz, cWOUPx, cWOUPy, cWOUPz)
    
    local dot2 = dotVec(cWOFx, cWOFy, cWOFz, popx, popy, popz)
    
    local yatp = deg(atan(dot1, dot2))
    yatp = clamp(abs(yatp),0,179.999)*sign(yatp)
    return yatp
end

function WidgetsPlusPlusCustom.vbCalc(self)
    local MaxBrakesForce = DUConstruct.getMaxBrake() or 0--unitData.maxBrake ~= nil and unitData.maxBrake or 0
    local maxSpeed = 50000*0.27777777777
    local cAV = DUConstruct.getVelocity()
    local cAVx, cAVy, cAVz = cAV[1], cAV[2], cAV[3]
    local cWAV = DUConstruct.getWorldAbsoluteVelocity()
    local zSpeedMPS = abs(cAVz) --sqrt(cAVx^2+cAVy^2+cAVz^2) getConstructIMass
    local cM = DUConstruct.getTotalMass()
    --local cM = construct.getInertialMass()
    local gravity = self.core.getWorldGravity()
    local g = self.core.getGravityIntensity()
    local G_axis = -1*sign(cWAV[1]*gravity[1] + cWAV[2]*gravity[2] + cWAV[3]*gravity[3])
    local brakesAcceleration = MaxBrakesForce + g*G_axis * cM
    local brakeDistance = cM * maxSpeed^2 / brakesAcceleration * (1 - sqrt(1 - ((zSpeedMPS)^2 / maxSpeed^2)))
    brakeDistance = brakeDistance == brakeDistance and zSpeedKPH > 70 and math.abs(brakeDistance) or 0
    return brakeDistance
end

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    --DUSystem.print("test flush")
    if P.AP_lockedDestination ~= nil and type(P.AP_lockedDestination) == "table" then
        local lD = P.AP_lockedDestination
        local lDx, lDy, lDz = lD[1], lD[2], lD[3]
        local cWAV = DUConstruct.getWorldVelocity()
        local cWAVx, cWAVy, cWAVz = cWAV[1], cWAV[2], cWAV[3]
        local speed = vectorLen(cWAVx, cWAVy, cWAVz)
        cWAVx, cWAVy, cWAVz = normalizeVec(cWAVx, cWAVy, cWAVz)
        
        local axx, axy, axz, an = 0,0,0,0
        local otAVx,otAVy,otAVz = 0,0,0
        local longitudinalSpeed = 0
        local lateralSpeed = 0
        local verticalSpeed = 0
        
        if self.inspace == 0 and self.atmoTravel == true then
            verticalSpeed = (self.altitudeHold - alt)*2.5
            local cPCx, cPCy, cPCz = currentPlanetCenter[1], currentPlanetCenter[2], currentPlanetCenter[3]
            local Cx, Cy, Cz = lDx-cPCx, lDy-cPCy, lDz-cPCz
            local nrx, nry, nrz = rotateVec(cWORx, cWORy, cWORz, rad(90), wVx, wVy, wVz)
            local offset = DULibrary.systemResolution3({cWORx, cWORy, cWORz},{nrx, nry, nrz},{wVx, wVy, wVz},{Cx, Cy, Cz})
            local BD = brakingCalculation() + self.precision
            if BD > offset[2] then self.arrived = true end
            if self.arrived == false then
                longitudinalSpeed = abs(offset[2]) > 5 and offset[2] or 0
            end
            if longitudinalSpeed == 0 then
                self.arrived = true
                enableAutoLand()
                P.AP_lockedDestination = nil
                return nil
            end
            local yAVx, yAVy, yAVz = 0,0,0
            if self.arrived == false then
                yAVx, yAVy, yAVz = yawAngularVelocity(cWOFx, cWOFy, cWOFz, yawAngleToPos(lDx, lDy, lDz), 0.05)
            end
            --DUSystem.print(tostring(self.arrived))
            local rAVx, rAVy, rAVz = rollAngularVelocity(wVx, wVy, wVz, 0, P.ES.rSF.value)
            local pa = 0
            local pAVx, pAVy, pAVz = pitchAngularVelocity(wVx, wVy, wVz, pa , 0.1)
            otAVx = yAVx + pAVx + rAVx
            otAVy = yAVy + pAVy + rAVy
            otAVz = yAVz + pAVz + rAVz

        elseif self.inspace == 1 and self.atmoTravel == false then
            lDx, lDy, lDz = lD[1] - cWPx, lD[2] - cWPy, lD[3] - cWPz
            fBD = brakingCalculation()
            longitudinalSpeed = (vectorLen(lDx, lDy, lDz) - fBD - (self.stopDist*200000))*3.6
            longitudinalSpeed = longitudinalSpeed > 5 and longitudinalSpeed or 0 --and an < 0.1
            if speed > 2000 / 3.6 then
                axx, axy, axz, an = getAARo(cWAVx+cWOFx*2, cWAVy+cWOFy*2, cWAVz+cWOFz*2, lDx, lDy, lDz, 0, 0, 1)
                
            else 
                axx, axy, axz, an = getAARo(cWOFx, cWOFy, cWOFz, lDx, lDy, lDz, 0, 0, 1)
            end
            otAVx = axx * an
            otAVy = axy * an
            otAVz = axz * an
        end
            
        if self.input == true then
            P.AP_lockedDestination = nil
            self.input = false
            DUSystem.print("TRAVELER--: Construct alignement aborted")
            return nil
        end
        --DUSystem.print(longitudinalSpeed.." / "..lateralSpeed.." / "..verticalSpeed.." / "..otAVx.." / "..otAVy.." / "..otAVz)
        longitudinalSpeed = longitudinalSpeed <= self.maxSpeed and longitudinalSpeed or self.maxSpeed
        return longitudinalSpeed, lateralSpeed, verticalSpeed, otAVx, otAVy, otAVz
    else
        return nil
    end
end

--------------------
-- CUSTOM BUTTONS --
--------------------
--local button_function = function() system.print("Hello world!") end



local function SecondsToClock(seconds)
  local seconds = tonumber(seconds)
  if seconds <= 0 or floor(seconds/3600) > 24 then
    return "00:00:00"
  else
    local hours = format("%02.f", floor(seconds/3600))
    local mins = format("%02.f", floor(seconds/60 - (hours*60)))
    local secs = format("%02.f", floor(seconds - hours*3600 - mins *60))
    return hours..":"..mins..":"..secs
  end
end
----------------
-- WIDGET SVG --
----------------
function WidgetsPlusPlusCustom.SVG_Update(self)
    local WTC = P.MS.wTC.value
    local s = 0
    local distance = 0
    local estimatedTime = "00:00:00"
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]

    self.inspace = 0
    if self.unit.getAtmosphereDensity() < 0.00001 then
        self.inspace = 1
    end

    if P.AP_destination.value ~= nil and #P.AP_destination.value == 3 and P.AP_destination.value[1] ~= 0 and P.AP_destination.value[2] ~= 0 then
        local bf = function() return function()
                            if mouseWheel == 0 then
                                    DUSystem.print("Travel engaged, press any key to abort!")
                                    P.AP_lockedDestination = P.AP_destination.value
                                    Nav:resetThrottleValue()
                                    Nav:setThrottleValue(0)
                                    if self.inspace == 0 then
                                        self.altitudeHold = alt
                                        self.atmoTravel = true
                                        self.arrived = false
                                    else
                                        self.atmoTravel = false
                                    end
                            elseif mouseWheel > 0 then
                                if self.stopDist >= 1 then
                                    self.stopDist = clamp(self.stopDist+0.1,0.01,25)
                                else
                                    self.stopDist = clamp(self.stopDist+0.01,0.01,25)
                                end
                            elseif mouseWheel < 0 then
                                if self.stopDist > 1 then
                                    self.stopDist = clamp(self.stopDist-0.1,0.01,25)
                                else
                                    self.stopDist = clamp(self.stopDist-0.01,0.01,25)
                                end
                            end
                            windowsShow()
                    end end
        local ptpd = P.AP_destination.value
        distance = vectorLen(ptpd[1]-cWPx,ptpd[2]-cWPy,ptpd[3]-cWPz)
        s = distance /(xyzSpeedKPH*0.27777777777)
        s = type(s) == "number" and tostring(s) ~= "inf" and s or 0
        estimatedTime = SecondsToClock(s)
        local btText = 'START (Atmo travel)'
        if self.inspace == 1 then
            if self.stopDist >= 1 then
                btText = format('START (stop @: %.1f SU)', self.stopDist)
            else
                btText = format('START (stop @: %.0f km)', self.stopDist*200)
            end
        end
        self.buttons[1] = {btText, bf(), {name = "traveler start", class = nil, width = 275, height = 25, posX = 0, posY = 120}}

        if self.inspace == 0 then
            bf = function() return function()
                if mouseWheel > 0 then
                    if self.precision >= 1 then
                        self.precision = clamp(self.precision+1,-50,50)
                    else
                        self.precision = clamp(self.precision+1,-50,50)
                    end
                elseif mouseWheel < 0 then
                    if self.precision > 1 then
                        self.precision = clamp(self.precision-1,-50,50)
                    else
                        self.precision = clamp(self.precision-1,-50,50)
                    end
                end
                windowsShow()
            end end
            self.buttons[2] = {"LANDING PRECISION ADJUSTMENT: "..self.precision.."m", bf(), {name = "traveler precision", class = nil, width = 275, height = 25, posX = 0, posY = 150}}
        else
            bf = function() return function()
                if mouseWheel == 0 then
                    self.maxSpeedIncrement = self.maxSpeedIncrement == 1000 and 10000 or 1000
                elseif mouseWheel > 0 then
                    self.maxSpeed = self.maxSpeed + self.maxSpeedIncrement
                elseif mouseWheel < 0 then
                    self.maxSpeed = self.maxSpeed - self.maxSpeedIncrement > 0  and self.maxSpeed - self.maxSpeedIncrement or 0
                end
                windowsShow()
            end end
            self.buttons[2] = {"MAX SPEED: "..self.maxSpeed.."kmph (+-"..self.maxSpeedIncrement..")", bf(), {name = "traveler maxSpeed", class = nil, width = 275, height = 25, posX = 0, posY = 150}}
        end
    else
        self.buttons = {}
    end

    if distance > 50000 then distance = tostring(floor((distance / 200000)*100)/100).." SU"
    else distance = tostring(floor((distance/1000)*100)/100).." KM"
    end

    local fBD, bBD = brakingCalculation()
    local fBDtext = ""
    if fBD == nil then fBDtext = "error" end
    if fBD < 1000 then
        fBDtext = format("%.0f", fBD).."m"
    else
        fBDtext = format("%.1f", fBD/1000).."km"
    end
    if fBD > 50000 then 
        fBDtext = format("%.2f",fBD/200000).."su"
    end

    local SVG = [[
        <text x="0" y="45" font-size="20" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]]..distance..[[</text> 
        <text x="0" y="72" font-size="30" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]]..estimatedTime..[[</text> 
        <text x="0" y="95" font-size="20" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">]].."Braking distance: ".. fBDtext ..[[</text> 
    ]]
    
    SVG = '<div><svg viewBox="0 0 '.. self.SVGSize.x ..' '.. self.SVGSize.y ..'">'..SVG..'</svg></div>'
    return SVG
end
