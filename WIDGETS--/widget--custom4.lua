--widget--custom4.lua

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
    self.player = player
    self.telemeter = telemeter

    self.buttons = {} -- list of buttons to be implemented in widget
    
    self.width = DUSystem.getScreenWidth()
    self.height = DUSystem.getScreenHeight()
    self.vFov = DUSystem.getCameraVerticalFov()
    self.hFov = DUSystem.getCameraHorizontalFov()
    self.name = 'TARGET VECTOR--' -- name of the widget
    self.SVGSize = {x=self.width,y=self.height} -- size of the window to fit the svg, in pixels
    self.pos = {x=0, y=0}
    self.class = 'widgets'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = false  --allow widget to be dragged
    self.fixed = true  --prevent widget from going over others
    self.title = nil
    self.scalable = false
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

--[[
function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return 0,0,0,0,0,0
end

function WidgetsPlusPlusCustom.onUpdate(self) --triggered onUpdate
    return nil
end

function WidgetsPlusPlusCustom.loadData(self) -- called on data load
end

function WidgetsPlusPlusCustom.saveData(self) -- called on data save
end

function WidgetsPlusPlusCustom.onActionStart(self, action) -- uncomment to receive pressed key
     --DUSystem.print(action)
end

function WidgetsPlusPlusCustom.onActionStop(self, action) -- uncomment to receive released key
     --DUSystem.print(action)
end

function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive held key
     --DUSystem.print(action)
end

function WidgetsPlusPlusCustom.onInputText(self, text) -- uncomment to process lua chat
    --DUSystem.print("typed: "..text)
end
]]

----------------
-- WIDGET SVG --
----------------
local sqrt, rad, atan, format, clamp, concat = math.sqrt, math.rad, math.atan, string.format, utils.clamp, table.concat

--local function dotVec(x1,y1,z1,x2,y2,z2)
--    return x1*x2 + y1*y2 + z1*z2
--end
--
local function normalizeVec(x,y,z)
    local l = sqrt(x*x + y*y + z*z)
    return x/l, y/l, z/l
end

local function vectorLen(x,y,z)
    return sqrt(x * x + y * y + z * z)
end

local function multiplyVec(x,y,z,factor)
    return x*factor, y*factor, z*factor
end

local function world2local(x,y,z)
    local v = DULibrary.systemResolution3({cWORx, cWORy, cWORz},{cWOFx, cWOFy, cWOFz},{cWOUPx, cWOUPy, cWOUPz},{x,y,z})
    return v[1],v[2],v[3]
end

function WidgetsPlusPlusCustom.SVG_Update(self)
    --DUSystem.print("1")
    local deg2px = self.height / self.vFov
    local near = 0.1
    local far = 100000000.0
    local aspectRatio = self.height / self.width
    local tanFov = 1.0 / math.tan(rad(self.vFov) * 0.5)
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
    --DUSystem.print("2")
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    local cWOUP = DUConstruct.getWorldOrientationUp()
    local cWOF = DUConstruct.getWorldOrientationForward()
    local cWOR = DUConstruct.getWorldOrientationRight()
    local cWOUPx, cWOUPy, cWOUPz = cWOUP[1], cWOUP[2], cWOUP[3] --getConstructWorldOrientationUp
    local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3] --getConstructWorldOrientationForward
    local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3] --getConstructWorldOrientationRight
    --DUSystem.print("3")
    local function l2W(ox,oy,oz)
        local x = ox * cWORx + oy * cWOFx + oz * cWOUPx + cWPx
        local y = ox * cWORy + oy * cWOFy + oz * cWOUPy + cWPy
        local z = ox * cWORz + oy * cWOFz + oz * cWOUPz + cWPz
        return x,y,z
    end
    
    local vx, vy, vz = 0, 0, 0
    local sx, sy, sz = 0, 0, 0
    local sPX, sPY = 0, 0
    local dist = 0
    
    local SVGind = 0
    --DUSystem.print("4")
    local function projection2D(posX, posY, posZ)
        posX = posX - camWPx
        posY = posY - camWPy
        posZ = posZ - camWPz
        vx = posX * camWRx + posY * camWRy + posZ * camWRz
        vy = posX * camWFx + posY * camWFy + posZ * camWFz
        vz = posX * camWUx + posY * camWUy + posZ * camWUz
        sx = (af * vx)/vy
        sy = ( -tanFov * vz)/vy
        sz = ( -field * vy + nq)/vy
        sPX, sPY = (sx+1)*self.width*0.5, (sy+1)*self.height*0.5 -- screen pos X Y
        dist = sqrt(posX*posX + posY*posY + posZ*posZ) -- distance from camera to pos
        return sPX, sPY
    end
    --DUSystem.print("5")
    local function buildLine(x,y,z,color,startPosX,startPosY)
        local spd = vectorLen(x,y,z)
        local maxSafeVel = 1000
        local scale1 = 10 / math.log(maxSafeVel)
        local len = clamp(math.log(math.abs(spd)+1)*scale1,0,42)
        --DUSystem.print("spd="..spd)

        local tsx, tsy, tsz = normalizeVec(x,y,z)
        local tsx, tsy, tsz = multiplyVec(tsx, tsy, tsz,len)
        tsx, tsy, tsz = l2W(tsx, tsy, tsz)
        local endPosX, endPosY = projection2D(tsx, tsy, tsz)
        endPosX = tostring(endPosX) ~= "-nan(ind)" and endPosX or startPosX
        endPosY = tostring(endPosY) ~= "-nan(ind)" and endPosY or startPosY
        --DUSystem.print(endPosX.." / "..endPosY)
        return format('<line x1="%.2f" y1="%.2f" x2="%.2f" y2= "%.2f" stroke="%s" stroke-width="3"/>', startPosX, startPosY, endPosX, endPosY, color)
    end

    local SVG = {}
    SVGind = SVGind + 1
    SVG[SVGind] = format('<div><svg style="position: absolute; left:0px; top:0px" viewBox="0 0 %.1f %.1f" >', self.width, self.height)
    --DUSystem.print("6")
    local startPosX, startPosY = projection2D(cWPx, cWPy, cWPz)
    SVGind = SVGind + 1
    SVG[SVGind] = format('<text x="%.2f" y="%.2f" font-size="50" text-anchor="middle" font-family="Play" alignment-baseline="middle" stroke-width="0" fill="red">O</text> ', startPosX, startPosY)
    
    --Target Vector = Blue
    SVGind = SVGind + 1
    SVG[SVGind] = buildLine(TargetSpeed[1], TargetSpeed[2], TargetSpeed[3],"blue",startPosX,startPosY)

    --Thrust sent to engines = Red
    SVGind = SVGind + 1
    local x,y,z = world2local(ThrustAcc[1], ThrustAcc[2], ThrustAcc[3])
    SVG[SVGind] = buildLine(x,y,z,"red",startPosX-1,startPosY)

    -- Vector sent to brakes = Orange
    SVGind = SVGind + 1
    x,y,z = world2local(BrakeAcc[1], BrakeAcc[2], BrakeAcc[3])
    SVG[SVGind] = buildLine(x,y,z,"orange",startPosX+1,startPosY)

    -- Velocity Vector
    SVGind = SVGind + 1
    x,y,z = world2local(cWAVx, cWAVy, cWAVz)
    SVG[SVGind] = buildLine(x,y,z,"green",startPosX+1,startPosY)


    SVGind = SVGind + 1
    SVG[SVGind] = '</svg></div>'
    return concat(SVG)
    --return ''
end
