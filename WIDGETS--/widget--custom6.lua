--widget--custom6.lua

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
    self.name = 'DB MANAGEMENT' -- name of the widget
    self.SVGSize = {x=300,y=65} -- size of the window to fit the svg, in pixels
    self.pos = {x=50, y=50}
    self.class = 'widgetnopadding'  --class = "widgets" (only svg)/ class = "widgetnopadding" (default-- widget style)
    self.draggable = true  --allow widget to be dragged
    self.fixed = false  --prevent widget from going over others
    self.title = "DB MANAGEMENT"
    self.data = {}
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

function WidgetsPlusPlusCustom.loadData(self) --replace the flush thrust
    self.data = {}
    if not self.DB then return end
    local dbKeys = self.DB.getKeyList()
    for i, v in ipairs(dbKeys) do
        self.data[v] = Data:getData(v)
    end
    --DUSystem.print(Data:serialize(self.data))
end

--[[
function WidgetsPlusPlusCustom.flushOverRide(self) --replace the flush thrust
    return 0,0,0,0,0,0
end

function WidgetsPlusPlusCustom.onUpdate(self) --triggered onUpdate
    return nil
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
local function is_number(str)
    return not (str == "" or str:find("%D"))
end

local concat = table.concat
local widget_font = "Play"
local i = 0
function WidgetsPlusPlusCustom.SVG_Update(self)
    i = i+1
    if i > 100 then self:loadData()
        i=0
    end --refresh the data every 100 ticks
    local WTC = P.MS.WTC.value
    local SVG = {}
    local dbKeys = self.DB.getKeyList()
    local ind = 0
    local SVGind = 0
    local name = ""
    local svgSizeY = 75
    
    SVGind = SVGind + 1
    SVG[SVGind] = '<div><svg viewBox="0 0 '.. self.SVGSize.x ..' '.. self.SVGSize.y ..'">'..[[
    <text x="5" y="10" font-size="20" text-anchor="start" font-family="Play" alignment-baseline="baseline" fill="]]..WTC..[[">Users data found: ]].. #dbKeys ..[[ entries</text>
    <text x="5" y="35" font-size="20" text-anchor="start" font-family="Play" alignment-baseline="baseline" fill="]]..WTC..[[">Total memory: ]].. Data:getLen() ..[[/30000bits</text>
    ]]

    local masterUserID = self.data.masterUserID ~= nil and tostring(self.data.masterUserID) or tostring(0)
    local masterUser = self.data[masterUserID] ~= nil and self.data[masterUserID].name ~= nil and "masterUser="..self.data[masterUserID].name or masterUserID
    for i, v in ipairs(dbKeys) do
        name = type(self.data[v]) == "table" and self.data[v].name ~= nil and self.data[v].name or v == "masterUserID" and masterUser or v
        --DUSystem.print(i.."="..v.."="..type(v).."="..name.."="..type(self.data[v]))
        if name and name ~= "" then
            ind = ind +1
            local bf = function() return function()
                if v and mouseWheel == 0 then
                    self.DB.clearValue(tostring(v))
                    DUSystem.print(name.."'s data has been removed from Databank")
                    self:loadData()
                    self.buttons[ind] = nil
                    windowsShow()
            end end end

            self.buttons[ind] = {"X", bf(), {name = "DBM_"..name, class = nil, width = 25, height = 25, posX = 270, posY = 80 + (ind-1) * 30}}

            SVGind = SVGind + 1
            local bits = v ~= "masterUserID" and [[: ]].. #(self.DB.getStringValue(v)) ..[[bits]] or ""
            SVG[SVGind] = [[<text x="5" y="]].. 65 + (ind-1) * 30 ..[[" font-size="20" text-anchor="start" font-family="Play" alignment-baseline="baseline" fill="]]..WTC..[[">-]].. name .. bits..[[</text>]]
            --DUSystem.print(i.."="..v.."="..type(v))
            svgSizeY = svgSizeY + 30
        end
    end
    self.SVGSize.y = svgSizeY + 5

    SVGind = SVGind + 1
    SVG[SVGind] = '</svg></div>'
    return concat(SVG)
end
