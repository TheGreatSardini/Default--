--widget--custom5.lua

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
    self.name = 'INFO' -- name of the widget
    self.SVGSize = {x=307,y=500} -- size of the window to fit the svg, in pixels
    self.pos = {x=10, y=10}
    self.class = 'widgetnopadding'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
    self.title = 'SHIP INFORMATION'
    self.scalable = true
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
        -- self.pos = load.b
    -- end
-- end

-- function WidgetsPlusPlusCustom.saveData(self)
    -- if Data then
        -- local save = {a=self.SVGSize, b=self.pos}
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
    local format = string.format
    local function toSu(v)
     return v == nil and 0 or v <= 10000 and format("%.0f",v).."m" or v > 10000 and format("%.1f",v/1000).."km" or v > 50000 and format("%.2f",v/200000).."su" or 0
    end
    local function altF(v)
     alt = alt == nil and 0 or alt
     return alt < 200000 and toSu(v) or "space"
    end

----------------
-- WIDGET SVG --
----------------
function WidgetsPlusPlusCustom.SVG_Update(self)
    local WFC = P.MS.WFC.value
    local WTC = P.MS.wTC.value
    local WAC = P.MS.wAC.value
    local WC = P.MS.WC.value
    local WCA = P.MS.WCA.value
    local fontSize = 15
    local lS = 25
    local info_window_height = 0

    local fBD, bBD = brakingCalculation()
    fBD = toSu(fBD)
    bBD = toSu(bBD)

    local t1, t2 = [[<tspan x="5" dy="]],[[" text-anchor="start" fill="]]..WFC..[[">]]
    local tmp1 = t1..lS..t2
    local tmp2 = [[</tspan><tspan x="300" dy="0" text-anchor="end" fill="]]..WTC..[[">]]
    local KeybindsSVG = [[
    <tspan x="5" text-anchor="start" fill="]]..WFC..[[">]]..'KEYBINDS:'..tmp2..''..[[</tspan>
    ]]..tmp1..'Main Menu: '..tmp2..'Alt + 1'..[[</tspan>
    ]]..tmp1..'Quick Menu: '..tmp2..'Alt + Alt Hold'..[[</tspan>
    ]]..tmp1..'AutoLand: '..tmp2..'G'..[[</tspan>
    ]]..tmp1..'Alt Lock at 11％ atmo: '..tmp2..P.KP.altitudeAP.value..'+'..P.KP.altitudeAP.value..[[</tspan>
    ]]..tmp1..'Reset Databank: lua channel '..tmp2..'reset all'..[[</tspan>
    ]]
    info_window_height = 6 * 30

    local InfoUnitSVG = [[
    ]]..t1..lS*2 ..t2..'W.POS: '..tmp2.. format("%.0f",currentWorldPos.x) ..":"..format("%.0f",currentWorldPos.y) ..":"..format("%.0f",currentWorldPos.z) ..[[</tspan>
    ]]..tmp1..'CLOSEST PLANET: '..tmp2..currentPlanetName..[[</tspan>
    ]]..tmp1..'ALTITUDE: '..tmp2..altF(alt)..[[</tspan>
    ]]..tmp1..'FLIGHT MODE: '..tmp2..MM .." MODE"..[[</tspan>
    ]]..tmp1..'OPTIMAL ORBITAL SPEED: '..tmp2..format("%.0f",math.sqrt(currentPlanetGM / (alt + currentPlanetRadius))*3.6).."kmph"..[[</tspan>
    ]]..tmp1..'MAX SPEED: '..tmp2..format("%.0f",unitData.maxSpeedkph).."kph"..[[</tspan>
    ]]..tmp1..'ACCELERATION: '..tmp2..format("%.4f",unitData.acceleration/10).."g"..[[</tspan>
    ]]..tmp1..'MAX BRAKE: '..tmp2..format("%.0f",unitData.maxBrake/1000).."kn"..[[</tspan>
    ]]..tmp1..'FORWARD BRAKE DISTANCE: '..tmp2..fBD..[[</tspan>
    ]]..tmp1..'BACKWARD BRAKE DISTANCE: '..tmp2..bBD..[[</tspan>
    ]]..tmp1..'ATMO TRHUST: '..tmp2..format("%.0f",unitData.atmoThrust/1000).."kn"..[[</tspan>
    ]]..tmp1..'SPACE TRHUST: '..tmp2..format("%.0f",unitData.spaceThrust/1000).."kn"..[[</tspan>
    ]]..tmp1..'CONSTRUCT WEIGHT: '..tmp2..format("%.2f",coreMass/1000).."tons"..[[</tspan>
    ]]..tmp1..'FPS: '..tmp2..format("%.0f",fps).."fps"..[[</tspan>
    ]]
    info_window_height = info_window_height + 12 * 30

    local InfoAGGSVG = ""
    if self.antigrav ~= nil then 
    InfoAGGSVG = [[
    ]]..t1..lS*2 ..t2..'ANTIGRAVITY STATE: '..tmp2..tostring(aggData.State):upper()..[[</tspan>
    ]]..tmp1..'POWER: '..tmp2..tostring(aggData.Power):upper()..[[％</tspan>
    ]]..tmp1..'FIELD: '..tmp2..tostring(aggData.Field):upper()..[[</tspan>
    ]]..tmp1..'COMPENSATION: '..tmp2..tostring(aggData.Compensation):upper()..[[</tspan>
    ]]..tmp1..'CURRENT ALTITUDE: '..tmp2..tostring(aggData.Altitude):upper().."m"..[[</tspan>
    ]]..tmp1..'SETUP ALTITUDE: '..tmp2..tostring(P.ES.agA.value):upper().."m"..[[</tspan>
    ]]
    info_window_height = info_window_height + 7 * 30
    end

    local InfoWarpSVG = ""
    if self.warpdrive ~= nil then
    InfoWarpSVG = [[
    ]]..t1..lS*2 ..t2..'WARP INFO: '..tmp2..tostring(warpData.Info):upper()..[[</tspan>
    ]]..tmp1..'CELLS COUNT: '..tmp2..tostring(warpData.Cells):upper()..[[</tspan>
    ]]..tmp1..'DESTINATION: '..tmp2..tostring(warpData.Destination):upper()..[[</tspan>
    ]]..tmp1..'DISTANCE: '..tmp2..format("%.1f",warpData.Distance/200000).." su"..[[</tspan>
    ]]
    info_window_height = info_window_height + 5 * 30
    end
    local InfoSVG = '<div><svg viewBox="0 0 309 '..info_window_height..'"><text x="5" y="20" font-size="'..fontSize..'" font-family="'..widget_font..'">'..KeybindsSVG..InfoUnitSVG..InfoAGGSVG..InfoWarpSVG..'</text></svg></div>'
    self.SVGSize.y = info_window_height
    return InfoSVG
end
