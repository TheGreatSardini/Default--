--widget--custom7.lua

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
    
    self.width = DUSystem.getScreenWidth()
    self.height = DUSystem.getScreenHeight()
    self.vFov = DUSystem.getCameraVerticalFov()
    self.hFov = DUSystem.getCameraHorizontalFov()
    self.name = 'AR TRANSPONDER--' -- name of the widget
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

function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return nil
end

--function WidgetsPlusPlusCustom.loadData(self)
--    self.modeOn = Data:getData("DM_droneMode") ~= nil and Data:getData("DM_droneMode") or false
--end
--
--function WidgetsPlusPlusCustom.saveData(self)
--    if Data then
--        Data:setData("DM_droneMode",self.modeOn)
--    end
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

-- function WidgetsPlusPlusCustom.onActionLoop(self, action) -- uncomment to receive pressed key
--      --DUSystem.print(action)
-- end

----------------
-- WIDGET SVG --
----------------
local proximity = 50 --on screen proximity in pixels to offset text
local yOffset = 25 --offset in pixels when overlapping
local fontSize = 20
local color = "lime"
local color2 = "lime" --"skyblue"
local sqrt, tan, rad, atan, cos, sin, format, concat, sort, clamp, abs, floor = math.sqrt, math.tan, math.rad, math.atan, math.cos, math.sin, string.format, table.concat, table.sort, utils.clamp, math.abs, math.floor

local function stringToTable(String, Separator)
    local Separator = Separator or ','
    local axes = {}
    for axis in String:gmatch('[^'..Separator..']+') do
        axes[#axes + 1] = axis
    end
    return axes
end

local vec2Dist = function(x1,y1,x2,y2)
    return sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))
end


function WidgetsPlusPlusCustom.SVG_Update(self)
    delay = delay + 1 <= 60 and delay + 1 or 60
    if delay >= 60 then
        --DUSystem.print("AR transponder update start")
        local WTC = P.MS.wTC.value --WIDGET_TEXT_COLOR
        local BBC = P.MS.BBC.value --BUTTON_BORDER_COLOR
        local BC = P.MS.BC.value --BUTTON_COLOR
        local WC = P.MS.WC.value --WN_COLOR
        local AC = P.MS.wAC.value --WIDGET_ANIM_COLOR
        local WFC = P.MS.WFC.value --WIDGET_FIXED_COLOR
        local atmoRadar = radar[1]
        local spaceRadar = radar[2]
        local currentRadar = {}
        local transponderData = {}
        if atmoRadar ~= nil and  atmoRadar.getOperationalState() == 1 then
            currentRadar = atmoRadar
        elseif spaceRadar ~= nil and  spaceRadar.getOperationalState() == 1 then 
            currentRadar = spaceRadar
        else currentRadar = nil
        end
        if currentRadar ~= nil then
            local ind = 0
            local getIds = currentRadar.getConstructIds()
            --DUSystem.print("Radar Contacts: " .. #getIds)
            for k, id in pairs(getIds) do
                if currentRadar.hasMatchingTransponder(id) then
                    ind = ind +1
                    local pos = currentRadar.getConstructWorldPos(id)
                    transponderData[ind] = {id = id, name = currentRadar.getConstructName(id), localPos = pos, abandonned = false}
                elseif currentRadar.isConstructAbandoned(id) == true then
                    ind = ind +1
                    local pos = currentRadar.getConstructWorldPos(id)
                    local kind = currentRadar.getConstructKind(id)
                    local t_kind = kind == 4 and "Static" or kind == 5 and "Dynamic" or kind == 6 and "Space" or kind == 7 and "Alien"
                    local size = currentRadar.getConstructCoreSize(id)
                    transponderData[ind] = {id = id, name = currentRadar.getConstructName(id).."("..size..", "..t_kind..")", localPos = pos, abandonned = true}
                end
            end
        end
        if #transponderData > 0 then
            --DUSystem.print("AR transponder data found")
            local sw = DUSystem.getScreenWidth()
            local sh = DUSystem.getScreenHeight()
            local vFov = DUSystem.getCameraVerticalFov()
            local hFov = DUSystem.getCameraHorizontalFov()
            local near = 0.1
            local far = 100000000.0
            local aspectRatio = sh/sw
            local tanFov = 1.0/tan(rad(vFov)*0.5)
            local field = -far/(far-near)
            local af = aspectRatio*tanFov
            local nq = near*field
            local camPv3 = vec3(DUSystem.getCameraPos())
            local camWP = DUSystem.getCameraWorldPos()
            local camWPv3 = vec3(camWP)
            local camWPx, camWPy, camWPz = camWP[1], camWP[2], camWP[3]
            local camWF = DUSystem.getCameraWorldForward()
            local camWFv3 = vec3(camWF)
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
            local mPP = self.player.getPosition()
            local mPPx, mPPy = mPP[1], mPP[2]
            
            local posX, posY, posZ = 0, 0, 0
            local vx, vy, vz = 0, 0, 0
            local sx, sy, sz = 0, 0, 0
            local sPX, sPY = 0
            local dist = 0
            
            local function projection2D()
                vx = posX * camWRx + posY * camWRy + posZ * camWRz
                vy = posX * camWFx + posY * camWFy + posZ * camWFz
                vz = posX * camWUx + posY * camWUy + posZ * camWUz
                sx = (af * vx)/vy
                sy = ( -tanFov * vz)/vy
                sz = ( -field * vy + nq)/vy
                sPX, sPY = (sx+1)*sw*0.5, (sy+1)*sh*0.5 -- screen pos X Y
                dist = sqrt(posX*posX + posY*posY + posZ*posZ) -- distance from camera to pos
            end

            local SVG = {}
            local svgi = 0

            svgi = svgi + 1
            SVG[svgi] = [[
            <div><svg style="position: absolute; left:0px; top:0px"viewBox="0 0 ]].. sw ..[[ ]].. sh ..[[">
            ]] 
            local bti = 0
            self.buttons = {}
            for i, data in ipairs(transponderData) do
                --if debug then DUSystem.print("section: 91") end
                pCx, pCy, pCz = data.localPos[1], data.localPos[2], data.localPos[3] 
                posX = pCx - camWPx
                posY = pCy - camWPy
                posZ = pCz - camWPz
                projection2D()
                if sz < 1 and sPX > 0 and sPX < sw and sPY > 0  and sPY < sh then
                    local name = data.name
                    local destPos = {pCx, pCy, pCz}
                    local bf = function() return function()
                                            DUSystem.print('Detination locked on: '..name)
                                            DUSystem.setWaypoint('::pos{0,0,'..destPos[1]..','..destPos[2]..','..destPos[3]..'}')
                                            P.AP_destination.value = destPos
                                            P.AP_destination.name = name
                                            windowsShow()
                                            end end
                    local bsize = 50
                    bti = bti + 1
                    self.buttons[bti] = {"", bf(), {name = name, class = 'separator', width = bsize, height = bsize, posX = sPX-bsize/2, posY = sPY-bsize/2}}
                    if abs(sPX - self.width/2) < bsize/2 and abs(sPY - self.height/2) < bsize/2 then
                        if self.click == true and (P.AP_destination.name == nil or P.AP_destination.name ~= nil and name ~= P.AP_destination.name) then
                            DUSystem.print('Detination locked on: '..name)
                            DUSystem.setWaypoint('::pos{0,0,'..destPos[1]..','..destPos[2]..','..destPos[3]..'}')
                            P.AP_destination.value = destPos
                            P.AP_destination.name = name
                            self.click = false
                        end
                    end
                    local dist_str = "0"
                    if dist >= 200000 then
                        dist_str = format('%.2f SU', dist / 200000)
                    elseif dist >= 1000 then
                        dist_str = format('%.1f km', dist / 1000)
                    else
                        dist_str = format('%.0f m', dist)
                    end
                    local s_color = data.abandonned == false and WFC or "red"
                    local t_color = data.abandonned == false and WTC or "red"
                    local sF = 1 + ((1 / dist) * 50)* 1
                    if abs(sPX - sw/2) < 10*sF and abs(sPY - sh/2) < 10*sF then sF = clamp(sF*2,0,5) end
                    svgi = svgi +1
                    SVG[svgi] = [[
                    <circle style="opacity:0.8;fill:none;stroke:]]..s_color..[[;stroke-width:]]..(1*sF)..[[;stroke-miterlimit:]]..(1*sF)..[[;" cx="]]..sPX..[[" cy="]]..sPY..[[" r="]]..(10*sF)..[[" />]]

                        
                        svgi = svgi +1
                        SVG[svgi] = [[
                        <polyline style="opacity:0.8;fill:none;stroke:]]..s_color..[[;stroke-width:]]..(1*sF)..[[;stroke-miterlimit:]]..(1*sF)..[[;" points="]]..sPX-(10*sF)..[[,]]..sPY-(10*sF)..[[ ]]..sPX-(20*sF)..[[,]]..sPY-(20*sF)..[[ ]]..sPX-(50*sF)..[[,]]..sPY-(20*sF)..[["/>
                        <text text-anchor="end" alignment-baseline="bottom" x="]]..sPX-(25*sF)..[[" y="]]..sPY-(22*sF)..[[" style="font-size:]]..11*sF..[[px;fill:]]..t_color..[[">]]..name..[[ (]]..dist_str..[[)</text>
                        ]]
                end
            end

            svgi = svgi + 1
            SVG[svgi] = '</svg></div>'
            local SVG = concat(SVG)
            return SVG
        else return ""
        end
    end
    return ""
end
