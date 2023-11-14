--DEFAULT-- windows colors variables:
--------------------------------------
--P.MS.TITLE_COLOR.value
--P.MS.TITLE_COLOR_A.value
--P.MS.TITLE_TEXT_COLOR.value
--P.MS.WN_COLOR.value
--P.MS.WN_COLOR_A.value
--P.MS.WN_TEXT_COLOR.value
--P.MS.BUTTON_COLOR.value
--P.MS.BUTTON_BORDER_COLOR.value
--P.MS.BUTTON_COLOR_A.value
--P.MS.BUTTON_TEXT_COLOR.value
--P.MS.WIDGET_TEXT_COLOR.value
--P.MS.WIDGET_ANIM_COLOR.value
--P.MS.WIDGET_FIXED_COLOR.value

--DEFAULT-- updated variables:
-------------------------------
--currentTime = num
--inspace = 0 in atmo 1 in space
--xSpeedKPH = num kmph
--ySpeedKPH = num kmph
--zSpeedKPH = num kmph
--xyzSpeedKPH = num kmph
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

utils            = require("cpml/utils")

local widget_font = "Play"
local only_show_damaged = false
local damage_levels = {{100,  'yellow'},
                       {50,  'orange'},
                       {10,  'red'},
                      }
function ar_round(num, numDecimalPlaces) -- http://lua-users.org/wiki/SimpleRound
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

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
    self.title = nil
    self.name = "AR DAMAGE REPPORT--" -- name of the widget
    self.SVGSize = {x=self.width,y=self.height} -- size of the window to fit the svg, in pixels
    self.pos = {x=0, y=0}
    self.class = "widgets"  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = false  --allow widget to be dragged
    self.fixed = true  --prevent widget from going over others
    
    self.showFullHp = false
    self.elementsId = {}
    self.elementsLocalPos = {}
    self:loadElements()
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

function WidgetsPlusPlusCustom.getPos(self) --returns the widget pos
    return self.pos
end

function WidgetsPlusPlusCustom.getButtons(self) --returns buttons list
    return self.buttons
end

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return nil
end

function WidgetsPlusPlusCustom.loadElements(self)
    self.elementsId = self.core.getElementIdList()
    for i, v in ipairs(self.elementsId) do
        self.elementsLocalPos[i] = self.core.getElementPositionById(v)
    end
end
--------------------
-- CUSTOM BUTTONS --
--------------------
--local button_function = function() system.print("Hello world!") end

--self.buttons = {
--                {button_text = "TEXT", button_function = button_function, class = nil, width = 0, height = 0, posX = 0, posY = 0},   -- class = "separator"   (for invisible background button)
--                }


----------------
-- WIDGET SVG --
----------------
local sqrt, tan, rad, format, concat = math.sqrt, math.tan, math.rad, string.format, table.concat

function WidgetsPlusPlusCustom.SVG_Update(self)
    local debug = false --turn on/off debug printing
    if debug then DUSystem.print("section: 0") end
    local sw = self.width
    local sh = self.height
    local vFov = self.vFov
    local near = 0.1
    local far = 100000000.0
    local aspectRatio = sh/sw
    local tanFov = 1.0/tan(rad(vFov)*0.5)
    local field = -far/(far-near)
    local af = aspectRatio*tanFov
    local nq = near*field
    local camWP = DUSystem.getCameraWorldPos()
    local camWPx, camWPy, camWPz = camWP[1], camWP[2], camWP[3]
    local camWF = DUSystem.getCameraWorldForward()
    local camWFv3 = vec3(camWF)
    local camWFx, camWFy, camWFz = camWF[1], camWF[2], camWF[3]
    local camWR = DUSystem.getCameraWorldRight()
    local camWRx, camWRy, camWRz = camWR[1], camWR[2], camWR[3]
    local camWU = DUSystem.getCameraWorldUp()
    local camWUx, camWUy, camWUz = camWU[1], camWU[2], camWU[3]

    if debug then DUSystem.print("section: 10") end
    local cWP = DUConstruct.getWorldPosition()
    local cWPx, cWPy, cWPz = cWP[1], cWP[2], cWP[3]
    local cWOU = DUConstruct.getWorldOrientationUp()
    local cWOUx, cWOUy, cWOUz = cWOU[1], cWOU[2], cWOU[3]
    local cWOF = DUConstruct.getWorldOrientationForward()
    local cWOFx, cWOFy, cWOFz = cWOF[1], cWOF[2], cWOF[3]
    local cWOR = DUConstruct.getWorldOrientationRight()
    local cWORx, cWORy, cWORz = cWOR[1], cWOR[2], cWOR[3]
    local mPP = self.player.getPosition()
    local mPPx, mPPy = mPP[1], mPP[2]

    if debug then DUSystem.print("section: 20") end
    local posX, posY, posZ = 0, 0, 0
    local vx, vy, vz = 0, 0, 0
    local sx, sy, sz = 0, 0, 0
    local sPX, sPY = 0,0
    local dist = 0

    if debug then DUSystem.print("section: 30") end
    local function projection2D()
        -- matrix resolution
        vx = posX * camWRx + posY * camWRy + posZ * camWRz
        vy = posX * camWFx + posY * camWFy + posZ * camWFz
        vz = posX * camWUx + posY * camWUy + posZ * camWUz
        -- 2D projection
        sx = (af * vx)/vy
        sy = ( -tanFov * vz)/vy
        sz = ( -field * vy + nq)/vy
        sPX, sPY = (sx+1)*sw*0.5, (sy+1)*sh*0.5 -- screen pos X Y
        dist = sqrt(posX*posX + posY*posY + posZ*posZ) -- distance from camera to pos
    end

    if debug then DUSystem.print("section: 40") end
    local x = 0
    local y = 0
    local z = 0
    local vxyz = {}
    local vx = 0
    local vy = 0
    local vz = 0
    local textHeight = 0
    local elementsPos = {}

    if debug then DUSystem.print("section: 50") end
    for i, v in ipairs(self.elementsLocalPos) do
        vxyz = v
        vx,vy,vz = vxyz[1], vxyz[2], vxyz[3]+ textHeight
        x = vx * cWORx + vy * cWOFx + vz * cWOUx + cWPx
        y = vx * cWORy + vy * cWOFy + vz * cWOUy + cWPy
        z = vx * cWORz + vy * cWOFz + vz * cWOUz + cWPz
        elementsPos[i] = {x=x,y=y,z=z}
    end

    if debug then DUSystem.print("section: 60") end
    local SVG = [[<style>
                svg {
                position:absolute;
                top:0px;
                left:0px;
                filter: drop-shadow(2px 2px 0px black) drop-shadow(0px 0px 4px black);
                }
                </style><div>
                <svg viewBox="0 0 ]].. sw ..[[ ]].. sh ..[[">]]

                
    if debug then DUSystem.print("section: 70") end
    local SVG = SVG..[[
    <style>
        .labelWhite {text-anchor: middle; font-family: Play; alignment-baseline: middle; stroke-width: 0; fill: white;}
        .labelYellow {text-anchor: middle; font-family: Play; alignment-baseline: middle; stroke-width: 0; fill: gold;}
        .labelRed {text-anchor: middle; font-family: Play; alignment-baseline: middle; stroke-width: 0; fill: red;}
    </style>]]

    --Markers
    ----------
    if debug then DUSystem.print("section: 80") end
    local t = ""
    local style = "labelWhite"
    local fs = 50
    local svgT = {}
    local ind = 0
    local n1, n2, n3 = 0, 0, 0
    local maxHP = 0
    local HP = 0
    local id = 0

    if debug then DUSystem.print("section: 90") end
    for i, v in ipairs(elementsPos) do
        --if debug then DUSystem.print("section: 91") end
        posX = v.x - camWPx
        posY = v.y - camWPy
        posZ = v.z - camWPz
        projection2D()
        if sz < 1 and sPX > 0 and sPX < sw and sPY > 0  and sPY < sh then
            --if debug then DUSystem.print("section: 92") end
            id = self.elementsId[i]
            maxHP = self.core.getElementMaxHitPointsById(id)
            maxHP = maxHP > 0 and maxHP or 0
            HP = self.core.getElementHitPointsById(id)
            HP = HP > 0 and HP or 0
            t = HP > 0 and (HP / maxHP)*100 or 0
            if t >= 100 then  style = "labelWhite" 
            elseif t < 100 and t > 0 then  style = "labelYellow"
            elseif t == 0 then  style = "labelRed" t = self.core.getElementNameById(id)
            end
            local minSize = 15
            local size =  minSize + (1 / (dist*0.6) * (fs + maxHP / 50)) --(200 / (dist*0.2))
            local text = ""
            if type(t) == "number" and ((t >= 100 and self.showFullHp == true) or (t < 100)) then
                text = format('%.0f ％',t)
            elseif type(t) == "string" then
                text = format('%s',t)
            end

            if text ~= "" then 
                ind = ind +1
                svgT[ind] = format([[<text x=%.1f y=%.1f class=%s font-size=%.1f > %s </text>]], sPX, sPY, style, size, text)
            end
        end
    end
    if debug then DUSystem.print("section: 100") end
    SVG = SVG .. concat(svgT)
    --SVG = SVG..'<rect x="1" y="1" width="'.. sw-1 ..'" height="'.. sh-1 ..'" style="fill:none;stroke:red;stroke-width:2"'
    --DUSystem.print("svg="..SVG)
    if debug then DUSystem.print("section: end") end
    return SVG..'</svg></div>'
end
