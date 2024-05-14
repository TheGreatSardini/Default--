--widget--custom8.lua

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

    self.name = 'ULTIMATE RACING++' -- name of the widget
    self.SVGSize = {x=275, y=345} -- size of the window to fit the svg, in pixels
    self.pos = {x=200, y=250}
    self.class = 'widgetnopadding'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
    self.title = "ULTIMATE RACING++"
    self.scalable = true

    self.active = false

    self.moveX = 0
    self.moveY = 0
    self.moveZ = 0
    self.boost = 0

    self.rollLock = false
    self.pitchLock = false
    self.sport = false
    self.autoBrake = false

    self.rollInput = 0
    self.pitchInput = 0
    self.previousDeltaY = 0
    self.yawInput = 0
    self.previousDeltaX = 0
    self.invertInput = false
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

function WidgetsPlusPlusCustom.loadData(self)
    local load = Data:getData("MCFlight") ~= nil and Data:getData("MCFlight") or nil
    if load then
        self.rollLock = load.r
        self.pitchLock = load.p
        self.sport = load.s
        self.autoBrake = load.au
        self.active = load.a
        self.invertInput = load.i
    end
end
--
function WidgetsPlusPlusCustom.saveData(self)
    if Data then
        local save = {a=self.active, r=self.rollLock, p=self.pitchLock, s=self.sport, au=self.autoBrake, i=self.invertInput}
        Data:setData("MCFlight",save)
    end
end

function WidgetsPlusPlusCustom.onActionStart(self, action)
    --DUSystem.print(action)
    if self.active == true then
        if action == 'option1' then
        elseif action == 'option2' then
        elseif action == 'option3' then
        elseif action == 'option4' then
        elseif action == 'option5' then
        elseif action == 'option6' then
        elseif action == 'option7' then
        elseif action == 'option8' then
        elseif action == 'option9' then
        elseif action == 'speedup' then
            
        elseif action == 'speeddown' then
            
        elseif action == 'stopengines' then
            
        elseif action == 'forward' then
            self.moveY = 1
            brakeInput = 0
        elseif action == 'backward' then
            self.moveY = -1
        elseif action == 'yawright' then
            if self.invertInput == false then
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = 1
                else
                    self.yawInput = -1
                end
            else
                self.moveX = 1
            end
        elseif action == 'yawleft' then
            if self.invertInput == false then
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = -1
                else
                    self.yawInput = 1
                end
            else
                self.moveX = -1
            end
        elseif action == 'right' then
            if self.invertInput == false then
                self.moveX = 1
            else
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = 1
                else
                    self.yawInput = -1
                end
            end
        elseif action == 'left' then
            if self.invertInput == false then
                self.moveX = -1
            else
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = -1
                else
                    self.yawInput = 1
                end
            end
        elseif action == 'straferight' then
            self.moveX = 1
        elseif action == 'strafeleft' then
            self.moveX = -1
        elseif action == 'up' then
            self.moveZ = 1
        elseif action == 'down' then
            self.moveZ = -1
        elseif action == 'groundaltitudeup' then
            
        elseif action == 'groundaltitudedown' then
            
        elseif action == 'lshift' then
            self.boost = 1
        elseif action == 'lalt' then
            --DUSystem.lockView(0)
        elseif action == 'brake' then
            
        elseif action == 'gear' then
            
        elseif action == 'light' then
            
        elseif action == 'booster' then
            self.moveY = 1
            self.boost = 1
        elseif action == 'antigravity' then
            
        elseif action == 'warp' then
        
        end
    end
end

function WidgetsPlusPlusCustom.onActionStop(self, action)
     --DUSystem.print(action)
    if self.active == true then
        if action == 'option1' then
        elseif action == 'option2' then
        elseif action == 'option3' then
        elseif action == 'option4' then
        elseif action == 'option5' then
        elseif action == 'option6' then
        elseif action == 'option7' then
        elseif action == 'option8' then
        elseif action == 'option9' then
        elseif action == 'speedup' then
            
        elseif action == 'speeddown' then
            
        elseif action == 'stopengines' then
            
        elseif action == 'forward' then
            if self.sport == false then
                self.moveY = 0
            end
            if self.autoBrake == true then
                brakeInput = 1
            end
        elseif action == 'backward' then
            self.moveY = 0
        elseif action == 'yawright' then
            if self.invertInput == false then
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = 0
                else
                    self.yawInput = 0
                end
            else
                self.moveX = 0
            end
        elseif action == 'yawleft' then
            if self.invertInput == false then
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = 0
                else
                    self.yawInput = 0
                end
            else
                self.moveX = 0
            end
        elseif action == 'right' then
            if self.invertInput == false then
                self.moveX = 0
            else
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = 0
                else
                    self.yawInput = 0
                end
            end
        elseif action == 'left' then
            if self.invertInput == false then
                self.moveX = 0
            else
                if self.rollLock == false and self.pitchLock == false then
                    self.rollInput = 0
                else
                    self.yawInput = 0
                end
            end
        elseif action == 'straferight' then
            self.moveX = 0
        elseif action == 'strafeleft' then
            self.moveX = 0
        elseif action == 'up' then
            self.moveZ = 0
        elseif action == 'down' then
            self.moveZ = 0
        elseif action == 'groundaltitudeup' then
            
        elseif action == 'groundaltitudedown' then
            
        elseif action == 'lshift' then
            self.boost = 0
        elseif action == 'lalt' then
            --DUSystem.lockView(1)
        elseif action == 'brake' then
            
        elseif action == 'gear' then
            
        elseif action == 'light' then
            
        elseif action == 'booster' then
            self.boost = 0
        elseif action == 'antigravity' then
            
        elseif action == 'warp' then
            
        end
    end
end

-- function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive pressed key
--      --DUSystem.print(action)
-- end

local abs, floor, asin, sqrt, cos, acos, sin, deg, atan, rad, sign, clamp, rad2deg, max, ceil = math.abs, math.floor, math.asin, math.sqrt, math.cos, math.acos, math.sin, math.deg, math.atan, math.rad, utils.sign, utils.clamp, constants.rad2deg, math.max, math.ceil

local function vectorLen(x,y,z)
    return sqrt(x*x+y*y+z*z)
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

local function rotateVec(vx, vy, vz, phi, ax, ay, az)
    local l = sqrt(ax*ax + ay*ay + az*az)
    local ux, uy, uz = ax/l, ay/l, az/l
    local cs, s = cos(phi), sin(phi)
    local m1x, m1y, m1z = (cs + ux * ux * (1-cs)), (ux * uy * (1-cs) - uz * s), (ux * uz * (1-cs) + uy * s)
    local m2x, m2y, m2z = (uy * ux * (1-cs) + uz * s), (cs + uy * uy * (1-cs)), (uy * uz * (1-cs) - ux * s)
    local m3x, m3y, m3z = (uz * ux * (1-cs) - uy * s), (uz * uy * (1-cs) + ux * s), (cs + uz * uz * (1-cs))
    return m1x*vx+m1y*vy+m1z*vz, m2x*vx+m2y*vy+m2z*vz, m3x*vx+m3y*vy+m3z*vz
end

local function cross(x, y, z, vx, vy, vz)
    return y*vz - z*vy, z*vx - x*vz, x*vy - y*vx
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

local function getConstructRoll90(x,y,z) --for the auto yaw when pitch = 90
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = norm(x,y,z)
    local CRx, CRy, CRz = cWORx, cWORy, cWORz
    local CUx, CUy, CUz = -cWOUPx, -cWOUPy, -cWOUPz
    local cx, cy, cz = cross(x, y, z, CUx, CUy, CUz)
    local rAx, rAy, rAz = norm(cx, cy, cz) --roll Axis
    local ConstructRoll = acos(clamp(dotVec(rAx, rAy, rAz, CRx, CRy, CRz), -1, 1)) * rad2deg
    cx, cy, cz = cross(rAx, rAy, rAz, CRx, CRy, CRz)
    if dotVec(cx, cy, cz, CUx, CUy, CUz) < 0 then ConstructRoll = -ConstructRoll end
    return ConstructRoll
end

local function rollAngularVelocity90(x,y,z, angle, speed) --for the auto yaw when pitch = 90
    if x == nil then x, y, z = 0,0,1 end
    x, y, z = norm(x,y,z)
    local CUx, CUy, CUz = -cWOUPx, -cWOUPy, -cWOUPz
    if angle ~= 0 then x, y, z = rotateVec(x, y, z, rad(-angle), CUx, CUy, CUz) end
    local RollDeg = getConstructRoll90(x, y, z)
    if (RollPID90 == nil) then 
     RollPID90 = pid.new(0.05, 0, 1)
    end
    RollPID90:inject(0 - RollDeg)
    local PIDget = RollPID90:get()
    return PIDget * CUx * speed, PIDget * CUy * speed, PIDget * CUz * speed
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


function WidgetsPlusPlusCustom.flushOverRide(self)
    if self.active == true then
        --variables
        
        --mouse control
        if P.w_open == false and P.QuickToolBar.w_open == false and P.KP.moC.value == true then
            if DUSystem.getMouseDeltaY() ~= 0 or self.previousDeltaY ~= 0 then 
                self.pitchInput = DUSystem.getMouseDeltaY() * P.KP.mCS.value * -0.25
                self.previousDeltaY = self.pitchInput
            end
            if DUSystem.getMouseDeltaX() ~= 0 or self.previousDeltaX ~= 0 then 
                self.yawInput = DUSystem.getMouseDeltaX() * P.KP.mCS.value * -0.25
                self.previousDeltaX = self.yawInput
            end
        end
        --thrust control
        if Nav:getMasterMode() ~= "CRUISE" then P.KP.flM.value = "CRUISE" Nav:setMasterMode("CRUISE") updateParams() end
        local longFactor = self.boost == 0 and Nav:getThrottleValue() or 50000
        local LS = self.moveY * longFactor
        local lS = self.moveX * 50000
        local vS = self.moveZ * 50000
        --rotations control
        local finalPitchInput = self.pitchLock == false and self.pitchInput + DUSystem.getControlDeviceForwardInput() or 0
        local finalRollInput = self.rollLock == false and self.rollInput + DUSystem.getControlDeviceYawInput() or 0
        local finalYawInput = self.yawInput - DUSystem.getControlDeviceLeftRightInput()
        local tAVx, tAVy, tAVz = 0,0,0
        local pFact = finalPitchInput * P.ES.pSF.value
        local rFact = finalRollInput * P.ES.rSF.value
        local yFact = finalYawInput  * P.ES.ySF.value
        tAVx = pFact * cWORx + rFact * cWOFx + yFact * cWOUPx
        tAVy = pFact * cWORy + rFact * cWOFy + yFact * cWOUPy
        tAVz = pFact * cWORz + rFact * cWOFz + yFact * cWOUPz
        if self.rollLock == true then
            local rAVx, rAVy, rAVz = rollAngularVelocity(wVx, wVy, wVz, 0, P.ES.rSF.value)
            tAVx = tAVx + rAVx
            tAVy = tAVy + rAVy
            tAVz = tAVz + rAVz
        end
        if self.pitchLock == true then
            local pAVx, pAVy, pAVz = pitchAngularVelocity(wVx, wVy, wVz, 0 , P.ES.pSF.value)
            tAVx = tAVx + pAVx
            tAVy = tAVy + pAVy
            tAVz = tAVz + pAVz
        end
        --DUSystem.print(LS.." / "..lS.." / "..vS)
        return LS, lS, vS, tAVx, tAVy, tAVz
    else
        return nil
    end
end

----------------
-- WIDGET SVG --
----------------
local upper = string.upper
local btW, btH = 265, 25
local btX, btY, btS = 5, 50, 5

function WidgetsPlusPlusCustom.SVG_Update(self)
    local WTC = P.MS.WTC.value
    local ind = 0
    --active
    local bf = function() return function()
                        self.active =  not self.active
                        DUSystem.print("Mouse control ultimate racing flight mode has been toggled: "..tostring(self.active))
                        P.KP.moC.value = false
                        P.KP.flM.value = "CRUISE"
                        Nav:setMasterMode("CRUISE")
                        -- if self.active == true then
                            -- DUSystem.lockView(1)
                        -- else
                            -- DUSystem.lockView(0)
                        -- end
                        updateParams()
                        windowsShow()
                end end
    local btText = "Mouse-Control Racing Mode ON:  ["..upper(tostring(self.active)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    --rollLock
    bf = function() return function()
                        self.rollLock = not self.rollLock
                        windowsShow()
                end end
    btText = "Flat Roll Lock:  ["..upper(tostring(self.rollLock)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    --pitchLock
    bf = function() return function()
                        self.pitchLock = not self.pitchLock
                        windowsShow()
                end end
    btText = "Flat Pitch Lock:  ["..upper(tostring(self.pitchLock)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    --sport
    bf = function() return function()
                        self.sport = not self.sport
                        windowsShow()
                end end
    btText = "Give me ALWAYS FULL POWA yeah:  ["..upper(tostring(self.sport)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    --autoBrake
    bf = function() return function()
                        self.autoBrake = not self.autoBrake
                        windowsShow()
                end end
    btText = "Auto Brake uppon W key release:  ["..upper(tostring(self.autoBrake)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    --QEAD invert
    bf = function() return function()
                        self.invertInput = not self.invertInput
                        windowsShow()
                end end
    btText = "Strafe(QE) / Roll(AD) invert:  ["..upper(tostring(self.invertInput)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    --inertia auto brake
    bf = function() return function()
                        P.AS.iAB.value = not P.AS.iAB.value
                        windowsShow()
                end end
    btText = "Inertia Auto Brake:  ["..upper(tostring(P.AS.iAB.value)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    --mouse lock
    bf = function() return function()
                        P.KP.moC.value = not P.KP.moC.value
                        windowsShow()
                        if P.KP.moC.value == true then
                            
                        else
                            
                        end
                end end
    btText = "Mouse control:  ["..upper(tostring(P.KP.moC.value)).."]"
    ind = ind + 1
    self.buttons[ind] = {btText, bf(), {name = "DM_button"..ind, class = nil, width = btW, height = btH, posX = btX, posY = btY + (btS + btH)*ind}}

    local SVG = [[
        <text x="5" y="5" font-size="15" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">Mouse-Control Ultimate Racing</text>
        <text x="5" y="32" font-size="18" text-anchor="start" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">Throttle: ]]..Nav:getThrottleValue()..[[kmph</text>
        <text x="270" y="305" font-size="12" text-anchor="end" font-family="]]..widget_font..[[" alignment-baseline="baseline" stroke-width="0" fill="]]..WTC..[[">By Jeronimo</text>
    ]]
    SVG = '<div><svg viewBox="0 0 '.. self.SVGSize.x ..' '.. self.SVGSize.y ..'">'..SVG..'</svg></div>'
    return SVG
end
