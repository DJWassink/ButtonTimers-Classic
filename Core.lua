

ABT = LibStub("AceAddon-3.0"):NewAddon("ButtonTimers", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("ButtonTimers", "enUS", true)
local MSQ = LibStub("Masque", true)
local LSM = LibStub("LibSharedMedia-3.0")

--=========================================================================--
-- upvalues
--=========================================================================--

local _G, ABT, LibStub, DEFAULT_CHAT_FRAME, UIParent = _G, ABT, LibStub, DEFAULT_CHAT_FRAME, UIParent
local math, min, modf, print, setglobal, type = math, math.min, math.modf, print, setglobal, type
local ipairs, next, pairs, rawset, select, setmetatable, tinsert, unpack = ipairs, next, pairs, rawset, select, setmetatable, tinsert, unpack
local format, gmatch, gsub, strfind, strmatch, tonumber, tostring = format, gmatch, gsub, strfind, strmatch, tonumber, tostring
local ActionButton_OnEvent, CreateFrame, GameTooltip, GetActiveSpecGroup, GetNumGroupMembers, GetTime, InCombatLockdown, InterfaceOptionsFrame_OpenToCategory, IsInRaid, SecondsToTimeAbbrev, UnitBuff, UnitDebuff, UnitGUID, UnitName = ActionButton_OnEvent, CreateFrame, GameTooltip, GetActiveSpecGroup, GetNumGroupMembers, GetTime, InCombatLockdown, InterfaceOptionsFrame_OpenToCategory, IsInRaid, SecondsToTimeAbbrev, UnitBuff, UnitDebuff, UnitGUID, UnitName
local GetActionCharges, GetActionCooldown, GetActionInfo, GetActionText, GetActionTexture, GetItemInfo, GetItemSpell, GetMacroItem, GetMacroSpell, GetSpellCharges, GetSpellCooldown, GetSpellInfo, GetTotemInfo = GetActionCharges, GetActionCooldown, GetActionInfo, GetActionText, GetActionTexture, GetItemInfo, GetItemSpell, GetMacroItem, GetMacroSpell, GetSpellCharges, GetSpellCooldown, GetSpellInfo, GetTotemInfo


-- TBD:
--
-- Submission checklist
-- comment out all Debug Print statements!
-- update toc file revision

local PROFILEDB_FORMAT = 1
local ABT_MaxButton = 12
local ABT_MaxBar = 4
local ABT_Widgets = "ABTWid"
local ABT_Bars = {}
local ABT_Buttons = {}
local outer_margin = 8
local ABT_TARGET = 1
local ABT_FOCUS = 2
local ABT_PLAYER = 3
local ABT_MOUSEOVER = 4
local ABT_PARTY = 5
local ABT_PET = 6
local ABT_VEHICLE = 7
local ABT_TOTEM = 8
local ABT_BOSS = 9
local ABT_TARGET_NAMES = { [ABT_TARGET]="target", [ABT_FOCUS]="focus", [ABT_PLAYER]="player", [ABT_PARTY]="party", [ABT_PET]="pet", [ABT_VEHICLE]="vehicle", [ABT_TOTEM]="totem" }
local ABT_AURA = 1
local ABT_COOLDOWN = 2
local ABT_BOTH = 4
local ABT_NONE = 3
local ABT_VERTICAL = 1
local ABT_HORIZONTAL = 2
local ABT_TOPRIGHT = 1
local ABT_BOTTOMLEFT = 2
local ABT_ONBUTTONS = 3
local ABT_FULL = 1
local ABT_FIXED = 2
local TimeSinceLastUpdate = nil
local ABT_UpdateInterval = .05
local ABT_DebuffUpdateInterval = .1
local needGetDebuffs = false
local lastDebuffUpdate = 0
local strInfinity = string.char(0xe2, 0x88, 0x9e)
local g_iconCache = {}
local g_barScaleInited = {}

local tblDefaultsAddon = {
	enable = true,
	showDebug = false,
	showTrace = false, 
	showBackground = false,
}

local tblDefaultsBar = {
	enabled = true,
	locked = false,
	orientation = ABT_VERTICAL,
	location = ABT_TOPRIGHT,
	scale = 1,
	length = 300,
	spacing = 8,
	buttonCount = 12,
	actionOffset = 0,                            -- set with bar specific value when the complete defaults table is created
	attach = { "CENTER", nil, "CENTER", 0, 0 },  -- set with bar specific value when the complete defaults table is created
	auraColor = { 0, 1, 1, .5 },
	cooldownColor = { 0, 1, 0, .5 },
	hideTooltips = false,
	hideInPetBattles = true,
}

local tblDefaultsButton = {
	target = ABT_TARGET,
	bossTarget = 1,
	timerType = ABT_AURA,
	useAsSpellTarget = true,
	barType = ABT_FULL,
	barTime = 20,
	showOthers = false,
	showTickPrediction = true,
	auras = nil,
	showAuraIcon = false,
	ignoreButtonAura = false,
	spell = nil,
	colorChange = nil,  -- "Warn < cast time."
	castTimeAdjust = "0",
	timerColor = { 0, 1, 1, .5 },
	textColor = { 1, 1, 0, 1 },
	timerWarnColor = { 1, 0, 0, .5 },
	timerAdjust = "0",
}

--
-- This function returns a legit string no matter what you pass it.
-- It gets used in debug messages to avoid annoying lua errors.
function ABT:NS(arg1)
	if arg1 == nil then
		return "nil"
	elseif type(arg1) == "table" then
		local myval = "{"
		for i, j in pairs(arg1) do
			myval = myval.." ["..ABT:NS(i).."]="..ABT:NS(j)..","
		end
		myval = myval.."}"
		return myval
	else
		return tostring(arg1)
	end
end

function ABT:DebugTrace (arg1, enter)
	if ABT.db and ABT.db.profile.config.showTrace == true then
		if (enter) then
			DEFAULT_CHAT_FRAME:AddMessage("ABT:"..arg1.." enter")
		else
			DEFAULT_CHAT_FRAME:AddMessage("ABT:"..arg1.." exit")
		end
	end
end

function ABT:DebugPrint (arg1)
	if ABT.db.profile.config.showDebug == true then
		DEFAULT_CHAT_FRAME:AddMessage("ABT:"..arg1)
	end
end

-- parse comma separated aura list into a table
-- spellId's will stay spellIds; assume user wants exact matching
-- exception if fNamesOnly is passed because totem api returns name but not spellId
function ABT:parseAuraList(barIdx, buttonIdx, fNamesOnly)
	local auraList = self:GetValue(barIdx, buttonIdx, "auras")
	local spellNames = {}

	if auraList then
		for aura in gmatch(auraList, "[^\n\r,]+") do
			if aura then
				aura = gsub(aura, "^%s*(.-)%s*$", "%1") -- strip leading/trailing whitespace

				local id = tonumber(aura)
				if id then
					local name, _, icon = GetSpellInfo(id)
					if name then
						if fNamesOnly then id = name end
						g_iconCache[id] = icon
						tinsert(spellNames, id)
					end
				else
					local name, _, icon = GetSpellInfo(aura)
					name = name or aura
					g_iconCache[name] = icon or g_iconCache[name]
					tinsert(spellNames, name)
				end
			end
		end
	end

	return spellNames
end


function ABT:getKey(info)
	local key
	if #info == 3 then
		key = info[#info-2]..info[#info-1]..info[#info]
	elseif #info == 2 then
		key = info[#info-1]..info[#info]
	else
		key = info[#info]
	end
	return key
end

function ABT:GetValue (barIdx, buttonIdx, field)
	if buttonIdx and barIdx and field then
		return self.db.profile["bar"..barIdx]["button"..buttonIdx][field]
	elseif barIdx and field then
		return self.db.profile["bar"..barIdx].config[field]
	elseif field then
		return self.db.profile.config[field]
	end
end

function ABT:SetValue (barIdx, buttonIdx, field, value)
	if buttonIdx and barIdx and field then
		self.db.profile["bar"..barIdx]["button"..buttonIdx][field] = value
	elseif barIdx and field then
		self.db.profile["bar"..barIdx].config[field] = value
	elseif field then
		self.db.profile.config[field] = value
	end
end

-- actionOffset + buttonCount could push us outside of the 120 button set
-- This function will, if necessary, return a reduced value for buttonCount
-- to ensure that we aren't referencing an invalid action slot.
function ABT:GetUsableButtonCount(barIdx)
	local available = 120 - ABT:GetValue(barIdx, nil, "actionOffset")
	local requested = ABT:GetValue(barIdx, nil, "buttonCount")
	return min(available, requested)
end

function ABT:GetButtonLabel(info)
	local barIdx, buttonIdx = ABT:getIndex (info)
	return ABT:GetButtonName (barIdx, buttonIdx)
end

function ABT:IsButtonHidden(barIdx, buttonIdx)
	if barIdx and buttonIdx then
		-- return ABT:GetValue (barIdx, nil, "enabled") and buttonIdx > ABT:GetUsableButtonCount(barIdx)
		return buttonIdx > ABT:GetUsableButtonCount(barIdx)
	else
		return false
	end
end

function ABT:GetButtonHidden(info)
	ABT:IsButtonHidden(ABT:getIndex(info))
end

function ABT:getIndex(info)
	local buttonIdx = nil
	local barIdx = nil
	local field = nil

	for i = 1, #info do
		local a = strmatch(info[i], "button(.+)")
		if a and tonumber(a) then
			buttonIdx = tonumber(a)
		else
			a = strmatch(info[i], "bar(.+)")
			if a and tonumber(a) then
				barIdx = tonumber(a)
			else
				field = info[i]
			end
		end
	end
	return barIdx, buttonIdx, field
end

function ABT:getFunc(info)
	local barIdx, buttonIdx, field = ABT:getIndex(info)
	return ABT:GetValue (barIdx, buttonIdx, field)
end

function ABT:setFunc(info, value)
	local barIdx, buttonIdx, field = ABT:getIndex(info)
	ABT:SetValue (barIdx, buttonIdx, field, value)

	local barIdx, buttonIdx = ABT:getIndex(info)
	if barIdx ~= nil then   -- button option or bar option
		ABT:SetBar (barIdx)
	else                                             -- general option
		for barIdx = 1, ABT_MaxBar do
			ABT:SetBar (barIdx)
		end
	end
	ABT:MarkNeedDebuffs()
end

function ABT:isNotAura(info)
	local barIdx, buttonIdx = ABT:getIndex(info) 
	local type = ABT:GetValue (barIdx, buttonIdx, "timerType")
	return (type ~= ABT_AURA and type ~= ABT_BOTH)
end

function ABT:isNotCooldown(info)
	local barIdx, buttonIdx = ABT:getIndex(info) 
	local type = ABT:GetValue (barIdx, buttonIdx, "timerType")
	return (type ~= ABT_COOLDOWN and type ~= ABT_BOTH)
end

function ABT:isTotem(info)
	local barIdx, buttonIdx = ABT:getIndex(info) 
	return ABT:GetValue(barIdx, buttonIdx, "target") == ABT_TOTEM
end

local buttonOptions = {
	type = "group",
	name = function(info) return ABT:GetButtonLabel(info) end,
	hidden = function(info) return ABT:IsButtonHidden(ABT:getIndex(info)) end,
	order = function(info) local barIndex, buttonIndex = ABT:getIndex(info) return buttonIndex end,
	desc = "Options for each button",
	childGroups = "tree",
	inline = false,
	args = {
		target = {
			order = 2,
			type = "select",
			name = L["Target"],
			desc = L["Target to monitor for Auras."],
			values = { [ABT_TARGET]=L["Target"], [ABT_FOCUS]=L["Focus"], [ABT_PLAYER]=L["Player"], [ABT_PARTY]=L["Party/Raid Member"], [ABT_PET]=L["Pet"], [ABT_VEHICLE]=L["Vehicle"], [ABT_TOTEM]=L["Totem"], [ABT_BOSS]=L["Boss"] },
			style = "dropdown",
			set = "setFunc",
			get = "getFunc",
		},

		bossTarget = {
			order = 4,
			type = "select",
			hidden = function (info)  local barIdx, buttonIdx = ABT:getIndex(info) return ABT:GetValue (barIdx, buttonIdx, "target") ~= ABT_BOSS  end,
			name = L["Boss"],
			desc = L["Raid boss to target"],
			values = { L["Boss #1"], L["Boss #2"], L["Boss #3"], L["Boss #4"], L["Boss #5"] },
			style = "dropdown",
			set = "setFunc",
			get = "getFunc",
		},
		playerTarget = {
			order = 5,
			type = "select",
			hidden = function (info)  local barIdx, buttonIdx = ABT:getIndex(info) return ABT:GetValue (barIdx, buttonIdx, "target") ~= ABT_PARTY  end,
			name = L["Party/Raid Member"],
			desc = L["The party / raid member to target"],
			values = function () return ABT:GetPartyList() end,
			style = "dropdown",
			set = "setFunc",
			get = "getFunc",
		},
		useAsSpellTarget = {
			order = 6,
			type = "toggle",
			hidden = "isTotem",
			name = L["Use as spell target"],
			desc = L["If set, target will be the spell target as well as the target to monitor for the selected aura."],
			set = "setFunc",
			get = "getFunc",
		},
		timerType = {
			type = "select",
			order = 10,
			name = L["Type"],
			values = { [ABT_AURA]=L["Aura"], [ABT_COOLDOWN]=L["Cooldown"], [ABT_BOTH]=L["Both"], [ABT_NONE]=L["None"]},
			style = "dropdown",
			set = "setFunc",
			get = "getFunc",
		},
		barType = {
			type = "select",
			order = 20,
			name = L["Timer Type"],
			desc = L["Choose full time to see the full length of the timer, choose fixed time to see a set maximum time."],
			values = { [ABT_FULL]=L["Full time"], [ABT_FIXED]=L["Fixed time"] },
			style = "dropdown",
			set = "setFunc",
			get = "getFunc",
		},
		barTime = {
			order = 30,
			type = "range",
			hidden = function (info) local barIdx, buttonIdx = ABT:getIndex(info) return ABT:GetValue (barIdx, buttonIdx, "barType") ~= ABT_FIXED  end,
			name = L["Bar Time"],
			desc = L["Max time displayed on bar"],
			min = 1,
			max = 100,
			step = 1,
			bigStep = 1,
			set = "setFunc",
			get = "getFunc",
		},
		showOthers = {
			order = 40,
			type = "toggle",
			hidden = function(info) return ABT:isNotAura(info) or ABT:isTotem(info) end,
			name = L["Show others spells"],
			desc = L["Show this spell on the target even if someone else cast it."],
			set = "setFunc",
			get = "getFunc",
		},
		showTickPrediction = {
			order = 45,
			type = "toggle",
			hidden = function(info) return ABT:isNotAura(info) or ABT:isTotem(info) end,
			name = L["Show tick prediction"],
			desc = L["Show estimate of next dot tick time."],
			set = "setFunc",
			get = "getFunc",
		},
		auras = {
			order = 50,
			hidden = "isNotAura",
			type = "input",
			name = L["Other Auras"],
			desc = L["Add any additional aura names or spellIds as a comma separated list."],
			multiline = true,
			set = "setFunc",
			get = "getFunc",
		},
		showAuraIcon = {
			order = 55,
			hidden = "isNotAura",
			type = "toggle",
			name = L["Show Aura Icon"],
			desc = L["Display the aura's icon on the button in place of the spell icon."],
			set = "setFunc",
			get = "getFunc",
		},
		ignoreButtonAura = {
			order = 57,
			hidden = "isNotAura",
			type = "toggle",
			name = L["Ignore Button Aura"],
			desc = L["Do not show timer for the aura applied by the spell on the action button."],
			set = "setFunc",
			get = "getFunc",
		},
		spell = {
			order = 60,
			hidden = "isNotCooldown",
			type = "input",
			name = L["Cooldown Spell"],
			desc = L["If you would like to see the cooldown for a spell other than the one on the button, enter the name or spellId here."],
			set = "setFunc",
			get = "getFunc",
		},
		timerColor = {
			order = 70,
            name = L["Bar Color"],
            desc = L["Bar color for timers"],
            type = "color",
			hasAlpha = true,
            set = function (info, r, g, b, a) return ABT:setFunc (info, {r, g, b, a}) end,
            get = function (info) return unpack(ABT:getFunc(info)) end
        },
		textColor = {
			order = 70,
            name = L["Text Color"],
            desc = L["Text color for timers"],
            type = "color",
			hasAlpha = true,
            set = function (info, r, g, b, a) return ABT:setFunc (info, {r, g, b, a}) end,
            get = function (info) return unpack(ABT:getFunc(info)) end
        },
		timerWarnColor = {
			order = 70,
 			hidden = "isNotAura",
			name = L["Warning Bar Color"],
            desc = L["Bar color for timers when remaining time < cast time"],
            type = "color",
			hasAlpha = true,
            set = function (info, r, g, b, a) return ABT:setFunc (info, {r, g, b, a}) end,
            get = function (info) return unpack(ABT:getFunc(info)) end
        },
		colorChange = {
			order = 65,
			hidden = "isNotAura",
			type = "toggle",
			name = L["Warn < cast time."],
			desc = L["Change the bar color when timer < cast time."],
			set = "setFunc",
			get = "getFunc",
		},
		castTimeAdjust = {
			order = 66,
			hidden = "isNotAura",
			disabled = function(info) local barIdx, buttonIdx = ABT:getIndex(info); return not ABT:GetValue(barIdx, buttonIdx, "colorChange") end,
			type = "input",
			name = L["Adjust Cast Time"],
			desc = L["Number of seconds to add to cast time (can be negative)."],
			set = "setFunc",
			get = "getFunc",
		},
		timerAdjust = {
			order = 90,
			type = "input",
			name = L["Adjust Timer"],
			desc = L["Number of seconds to add to timer (can be negative)."],
			set = "setFunc",
			get = "getFunc",
		},
	}
}

function ABT:GetBarDesc(info)
	local offset = ABT:getFunc(info)
	local barIdx = modf(offset / 12) + 1
	local buttonIdx = (offset % 12) + 1
--  ABT:DebugPrint( "First button of bar is: Action bar: "..ABT:NS(barIdx)..", button: "..ABT:NS(buttonIdx))
	return "Bar: "..ABT:NS(barIdx)..", Button: "..ABT:NS(buttonIdx)
end

local barOptions = {
	type = "group",
	name = function(info) return info[#info] end,
	order = function(info) local barIdx, buttonIdx = ABT:getIndex(info); return barIdx end,
--	handler = ABT,
	desc = "Options for the bar",
	childGroups = "tree",
	inline = false,
	args = {
		enabled = {
			order = 10,
			type = "toggle",
			name = L["Bar Enabled"],
			desc = L["Enable this bar"],
			set = "setFunc",
			get = "getFunc",
		},
		locked = {
			order = 12,
			type = "toggle",
			name = L["Bar Locked"],
			desc = L["Lock bar in place"],
			set = "setFunc",
			get = "getFunc",
		},
		Padding1 = {
			order = 14,
			type = "description",
			name = "",
		},
		inCombat = {
			order = 15,
			type = "toggle",
			name = L["Hide out of combat"],
			desc = L["Show this bar only when in combat"],
			set = "setFunc",
			get = "getFunc",
		},
		hideInPetBattles = {
			order = 16,
			type = "toggle",
			name = L["Hide in pet battles"],
			desc = L["Hide this bar during pet battles"],
			set = "setFunc",
			get = "getFunc",
		},
		hideTooltips={
			order = 18,
			name= L["Hide Tooltips"],
			desc= L["Hide tooltips on buttons"],
			type= "toggle",
			set = "setFunc",
			get = "getFunc",
		},
		Padding2 = {
			order = 19,
			type = "description",
			name = "",
		},
		buttonCount = {
			order = 20,
			type = "range",
			name = L["Button Count"],
			desc = L["Number of Buttons on bar"],
			min = 1,
			max = 12,
			step = 1,
			bigStep = 1,
			set = "setFunc",
			get = "getFunc",
		},
		actionDesc = {
			order = 29,
			type = "description",
			name = L["First button on bar is action slot:"],
		},
		actionOffset = {
			order = 30,
			type = "range",
			name = function(info) return ABT:GetBarDesc(info) end,
			desc = L["Move this slider to change which action slots are shown on the bar."],
			min = 0,
			max = 119,
			step = 1,
			bigStep = 1,
			set = "setFunc",
			get = "getFunc",
		},	
		orientation = {
			order = 40,
			type = "select",
			name = L["Orientation"],
			values = { [ABT_VERTICAL]=L["Vertical"], [ABT_HORIZONTAL]=L["Horizontal"] },
			style = "dropdown",
			set = "setFunc",
			get = "getFunc",
		},
		location = {
			order = 45,
			type = "select",
			name = L["Timer Location"],
			values = { [1]=L["Right/Top"], [2]=L["Left/Bottom"], [3]=L["Timers on Buttons"] },
			style = "dropdown",
			set = "setFunc",
			get = "getFunc",
		},
		spacing = {
			order = 60,
			type = "range",
			name = L["Button Spacing"],
			desc = L["The space between the buttons"],
			min = 0,
			min = 0,
			max = 16,
			step = 1,
			bigStep = 1,
			set = "setFunc",
			get = "getFunc",
		},
		scale = {
			order = 70,
			type = "range",
			name = L["Bar Scale"],
			desc = L["Allows you to scale the bar size"],
			min = .1,
			max = 2,
			step = .01,
			bigStep = .01,
			set = "setFunc",
			get = "getFunc",
		},
		length = {
			order = 80,
			type = "range",
			name = L["Bar Length"],
			desc = L["Length of bar in pixels"],
			min = 1,
			max = 600,
			step = 1,
			bigStep = 1,
			set = "setFunc",
			get = "getFunc",
		},
		font = {
			order = 90,
			type = "select",
			dialogControl = "LSM30_Font", --Select your widget here
			name = L["Bar Font"],
			desc = L["Fonts to use for this bar"],
			values = AceGUIWidgetLSMlists.font, -- this table needs to be a list of keys found in the sharedmedia type you want
			get = "getFunc",
			set = "setFunc",
		},
				
		texture = {
			order = 100,
			type = "select",
			dialogControl = "LSM30_Statusbar", --Select your widget here
			name = L["Statusbar texture"],
			desc = L["Texture of the status bar"],
			values = AceGUIWidgetLSMlists.statusbar, -- this table needs to be a list of keys found in the sharedmedia type you want
			get = "getFunc",
			set = "setFunc",		
		},
		button1 = buttonOptions,
		button2 = buttonOptions,
		button3 = buttonOptions,
		button4 = buttonOptions,
		button5 = buttonOptions,
		button6 = buttonOptions,
		button7 = buttonOptions,
		button8 = buttonOptions,
		button9 = buttonOptions,
		button10 = buttonOptions,
		button11 = buttonOptions,
		button12 = buttonOptions,
	}
}

local options = {
    name = "ButtonTimers",
    handler = ABT,
    type = "group",
	childGroups = "tree",
    args = {
		enable={
			order = 10,
			name= L["Enable"],
			desc= L["Enables / disables the addon"],
			type= "toggle",
			set = "setFunc",
			get = "getFunc",
		},
	    showDebug = {
			order = 100,
			hidden = true,
            name = L["ShowDebug"],
            desc = L["Show debug messages"],
            type = "toggle",
            set = "setFunc",
            get = "getFunc",
        },
	    showTrace = {
			order = 110,
			hidden = true,
            name = L["ShowTrace"],
            desc = L["Show trace messages"],
            type = "toggle",
            set = "setFunc",
            get = "getFunc",
        },
		showBackground = {
			order = 120,
			hidden = true,
            name = L["ShowBackground"],
            desc = L["Show background bar"],
            type = "toggle",
            set = "setFunc",
            get = "getFunc",
        },
		bar1 = barOptions,
		bar2 = barOptions,
		bar3 = barOptions,
		bar4 = barOptions,
    },
}

function ABT:InitDefaults()
	local defaults = {
		global = {
			iconCache = {},
		},
		profile = { 
			dbFormat = 0,
			config = tblDefaultsAddon,
			['**'] = {
				config = tblDefaultsBar,
				['*'] = tblDefaultsButton,
			},
			bar1 = {
				config = {
					actionOffset = 108,  -- bar 10
					attach = { "CENTER", nil, "CENTER", 0, 0 },
				},
			},
			bar2 = {
				config = {
					actionOffset = 96,   -- bar 9
					attach = { "CENTER", nil, "CENTER", 44, 0 },
				},
			},
			bar3 = {
				config = {
					actionOffset = 84,   -- bar 8
					attach = { "CENTER", nil, "CENTER", 88, 0 },
				},
			},
			bar4 = {
				config = {
					actionOffset = 72,   -- bar 7
					attach = { "CENTER", nil, "CENTER", 132, 0 },
				},
			},
		},
	}

	return defaults
end

function ABT:MigrateUserSettings()
	local dbProfileFormat = self.db.profile.dbFormat or 0
	if (dbProfileFormat == PROFILEDB_FORMAT) then
		return
	end

	if (dbProfileFormat < 1) then
		-- if the current profile is character, then we know this is a brand new toon
		-- if the current profile is Default, then we know we're migrating user settings 
		-- to the new structured storage and profile
		if (self.db:GetCurrentProfile() ~= "Default") then
			self.db.profile.dbFormat = PROFILEDB_FORMAT
			return
		else
			-- ensures that we don't copy a table by reference but make a new copy of the contents
			local function SafeCopy(source)
				if type(source) == "table" then
					local retval = {}
					for k,v in pairs(source) do
						retval[k] = SafeCopy(v)
					end
					return retval
				end
				
				return source
			end

			-- copies the contents of a table into the other
			-- some profiles tables we cannot set by assignment and so use this
			local function CopyInto(dest, source)
				for k,v in pairs(source) do
					if type(v) == "table" then
						if (next(v)) then
							dest[k] = {}
							CopyInto(dest[k], v)
						end
					else
						dest[k] = v
					end
				end
			end

			-- inits bar/button table structures so we can just do assignments into it 			
			local function CreateBBStructure()
				local spec = { config = {} }
				for iBar=1, 4 do
					local strBar = format("bar%i", iBar)
					spec[strBar] = { config = {} }
					
					for iBtn=1, 12 do
						local strBtn = format("button%i", iBtn)
						spec[strBar][strBtn] = {}
					end
				end
				return spec
			end

			local function ParseSettingName(name)
				local _, index, newindex, strBar, strButton, strKey, spec = nil, 0
				_, newindex, strBar = strfind(name, "^(bar%d)", index+1)
				index = newindex or index

				_, newindex, strButton = strfind(name, "^(button%d+)", index+1)
				index = newindex or index

				_, newindex, strKey = strfind(name, "^(%a+)", index+1)
				index = newindex or index

				spec = (strfind(name, "(2)$")) and "secondary" or "primary" 

				if (strKey == "timerWarnColor") then
					print(name, spec, strBar, strButton, strKey)
				end
				return spec, strBar, strButton, strKey
			end


			local newdb = { primary = CreateBBStructure(), secondary = CreateBBStructure() }

			local ABT_second_spec_bar_fields = { ["enabled"] = true, ["buttonCount"] = true }
			for k,v in pairs(self.db.char) do
				local strSpec, strBar, strButton, strKey = ParseSettingName(k)

				if (strSpec == nil or strKey == nil) then
					print("error parsing", k)
				elseif (strBar == nil) then
					-- addon setting
					newdb[strSpec].config[strKey] = SafeCopy(v)
				elseif (strButton == nil) then
					-- bar setting
					if (ABT_second_spec_bar_fields[strKey]) then
						newdb[strSpec][strBar].config[strKey] = SafeCopy(v)
					elseif (strSpec == "primary") then 
						-- secondary spec has been using primary spec bar settings for all values
						-- other than enabbled and buttonCount. need to copy value into both profiles
						newdb["primary"][strBar].config[strKey] = SafeCopy(v)
						newdb["secondary"][strBar].config[strKey] = SafeCopy(v)
						-- print("making a copy of", k, "for secondary profile")
					--else
					--	print("ignoring junk setting", k)
					end
				else
					-- button setting
					newdb[strSpec][strBar][strButton][strKey] = SafeCopy(v)
				end
				
				-- clear the setting out of the old location
				self.db.char[k] = nil
			end

			newdb.primary.dbFormat = 1
			newdb.secondary.dbFormat = 1

			-- achievement info that would let us see if they have dual spec capability is not available at this time
			-- just assume they need two profiles
			local character = UnitName("player")
			local server = self.db.keys.realm

			self.newProfileNames = {
				format("%s - %s - %s", character, L["Primary"],   server),
				format("%s - %s - %s", character, L["Secondary"], server),
			}

			self.db:SetProfile(self.newProfileNames[2])
			CopyInto(self.db.profile, newdb.secondary)

			self.db:SetProfile(self.newProfileNames[1])
			CopyInto(self.db.profile, newdb.primary)

			-- self:OutputProfileState()
		end
	end

	self.db.profile.dbFormat = PROFILEDB_FORMAT
end

function ABT:CompleteProfileMigration()
	if self.newProfileNames then
		local offspec = 3 - GetActiveSpecGroup()
		-- print("current spec should be:", self.newProfileNames[3 - offspec], "  offspec should be", self.newProfileNames[offspec])
		if offspec == 1 then
			self.db:SetProfile(self.newProfileNames[2])
		end

		self.newProfileNames = nil
	end
end

function ABT:OnProfileChanged(event)
	self:MigrateUserSettings()
	self:CompleteProfileMigration()

	g_barScaleInited = {}
	self:SetAllBars("Profile Change")
end

function ABT:OnInitialize()
  -- Code that you want to run when the addon is first loaded goes here.
	ABT:DebugTrace ("OnInitialize", true)

	self.db = LibStub("AceDB-3.0"):New("ButtonTimersDB")
	-- Create the profile options and add them to our option table
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db, true)

	self:MigrateUserSettings()
	self.db:RegisterDefaults(ABT:InitDefaults())
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied",  "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset",   "OnProfileChanged")


	ABT:RegisterChatCommand("buttontimers", "SlashProcessorFunc")
	-- bt overwrites bartender, doh
	ABT:RegisterChatCommand("abt", "SlashProcessorFunc")
    LibStub("AceConfig-3.0"):RegisterOptionsTable("ButtonTimers", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("ButtonTimers", "ButtonTimers")


	ABT:MakeWidgets()
	ABT:DebugTrace ("OnInitialize")

	-- libSharedMedia
	LSM.RegisterCallback(self, "LibSharedMedia_Registered", "UpdateUsedMedia")

	-- Binding Variables
	for bar=1,ABT_MaxBar do
		setglobal("BINDING_HEADER_ButtonTimersBar"..bar, "ButtonTimers Bar "..bar);
		for button=1, ABT_MaxButton do
			local buttonName = ABT_Widgets.."bar"..bar.."button"..button.."Button"
			setglobal("BINDING_NAME_CLICK "..buttonName..":LeftButton", "Button "..button);
		end
	end
end

--
-- libSharedMedia Callback
-- This function will check newly registered media to see if
-- it's in use in the user's configuration. It's mainly here 
-- in case this add-on gets loaded before SharedMedia or other
-- media add-in mods
function ABT:UpdateUsedMedia (event, mediatype, key)
	if mediatype == "statusbar" then
		-- see if we are using this statusbar texture anywhere
		for barIdx = 1, ABT_MaxBar do
			-- if we're using it, update
			if key == ABT:GetValue (barIdx, nil, "texture") then
--				ABT:DebugPrint ("Found newly registered statusbar "..ABT:NS(key))
				ABT:SetBar (barIdx)
			end
		end
	end
	if mediatype == "font" then
		-- see if we are using font anywhere
		for barIdx = 1, ABT_MaxBar do
			-- if we're using it, update
			if key == ABT:GetValue (barIdx, nil, "font") then
--				ABT:DebugPrint ("Found newly registered font "..ABT:NS(key))
				ABT:SetBar (barIdx)
			end
		end
	end
end

function ABT:OnEnable()
	ABT:CompleteProfileMigration()

	-- we'll cache name-icon pairs into the global profile, but 
	-- spellid-icon pairs we'll keep only for the session
	local iconCache = ABT.db.global.iconCache
	g_iconCache = setmetatable( {}, {
		__index = iconCache,
		__newindex = function(t,k,v)
				if type(k) == "number" then
					rawset(t,k,v)
				else
					iconCache[k] = v
				end
			end, } )

	ABT:DebugTrace ("OnEnable", true)
    -- Called when the addon is enabled
	self:RegisterEvent ("UNIT_AURA", "MarkNeedDebuffs")
	self:RegisterEvent ("PLAYER_TOTEM_UPDATE", "MarkNeedDebuffs")
	self:RegisterEvent ("PLAYER_TARGET_CHANGED", "MarkNeedDebuffs")
	self:RegisterEvent ("PLAYER_FOCUS_CHANGED", "MarkNeedDebuffs")
	self:RegisterEvent ("PLAYER_ENTERING_WORLD", "SetAllBars")
	self:RegisterEvent ("ACTIONBAR_UPDATE_COOLDOWN", "GetCooldowns")
	self:RegisterEvent ("ACTIONBAR_UPDATE_USABLE", "GetCooldowns")
	self:RegisterEvent ("GROUP_ROSTER_UPDATE", "UpdatePlayerTargets")
	self:RegisterEvent ("ACTIONBAR_SLOT_CHANGED", function (event, arg1) 
			ABT:ApplyDefault(event, arg1) ABT:ButtonUpdate()
			end)
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "ShowBars")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "HideBars")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", function() self:ProcessCombatLogEvent(CombatLogGetCurrentEventInfo()) end)
	self:RegisterEvent("PET_BATTLE_OPENING_START", "HideBars")
	self:RegisterEvent("PET_BATTLE_OVER", "ShowBars")
	ABT:RegisterMSQ()
	ABT:ButtonUpdate()
	ABT:DebugTrace ("OnEnable")
end

-- if entering combat, all enabled bars should be shown
-- otherwise (pet battles), show if not a combat only bar
function ABT:ShowBars(event)
	if ABT:GetValue(nil, nil, "enable") then
		for barIdx = 1, ABT_MaxBar do
			if ABT:GetValue(barIdx, nil, "enabled") then
				if event == "PLAYER_REGEN_DISABLED" or not ABT:GetValue(barIdx, nil, "inCombat") then
					ABT_Bars[barIdx]:Show()
				end
			end
		end
	end
end

-- if starting pet battle, hide all bars except those chosen to stay up
-- if leaving combat, hide combat only bars
function ABT:HideBars(event)
	if ABT:GetValue(nil, nil, "enable") then
		for barIdx = 1, ABT_MaxBar do
			if ABT:GetValue(barIdx, nil, "enabled") then
				if (event == "PET_BATTLE_OPENING_START" and ABT:GetValue(barIdx, nil, "hideInPetBattles")) 
				or (event == "PLAYER_REGEN_ENABLED"     and ABT:GetValue(barIdx, nil, "inCombat"))
				then
					ABT_Bars[barIdx]:Hide()
				end
			end
			if ABT_Bars[barIdx].needsRefresh then
				ABT:SetBar(barIdx)
			end
		end
	end
end

function ABT:ApplyDefault (event, slot)
--    ABT:DebugPrint ("ApplyDefault called on slot "..ABT:NS(slot))
    if slot == nil then
        return
    end
    -- find buttons using this slot
    local overall_defaults = ABT.ABT_Defaults["overall"]
    for barIdx, buttonIdx in ABT:GetNextButton() do
        local button = ABT_Buttons[barIdx][buttonIdx]
        if slot == button.button:GetAttribute("action") then
            -- found one
            ABT:DebugPrint ("Slot "..slot.." used on bar="..barIdx.." button="..buttonIdx)
			ActionButton_OnEvent(button, event, slot)
            
            local actionType, actionId = GetActionInfo(slot)
            -- only apply defaults if it actually changed
            if (actionType ~= button.actionType or actionId ~= button.actionId) then
                button.actionType = actionType
                button.actionId = actionId
--[===[		setting of default values is not ready for usage
			sunder/devestate issue has to get fixed, probably need to store actionType/actionId info in settings and verify that 
			*those* have really changed (since the button is going to morph on us)
                if actionType == "spell" or actionType == "macro" then
                    local spellName = ABT:GetButtonName(barIdx, buttonIdx)
                    ABT:DebugPrint ("spellName="..ABT:NS(spellName).." id="..ABT:NS(actionId))
                    local options = ABT.ABT_Defaults[actionId]
                    if options == nil then
                        options = ABT.ABT_Defaults[spellName]
                    end
                    if options ~= nil then
                        -- reset the fields to default values
                        if overall_defaults ~= nil then
                            for f, v in pairs(overall_defaults) do
                                ABT:SetValue (barIdx, buttonIdx, f, v)
                            end
                        end
                        -- apply the specific default for this spell
                        ABT:DebugPrint (ABT:NS(options))
                        for f, v in pairs(options) do
                            ABT:DebugPrint ("Applying default field="..ABT:NS(f).." value="..ABT:NS(v))
                            ABT:SetValue (barIdx, buttonIdx, f, v)
                        end
                    end
                end
--]===]
            end
        end
    end
end

function ABT:ButtonUpdate ()
	ABT:GetCooldowns()
	ABT:MarkNeedDebuffs()
end

function ABT:OnDisable()
	ABT:DebugTrace ("OnDisable", true)
    -- Called when the addon is disabled
	self:UnregisterEvent ("UNIT_AURA")
	self:UnregisterEvent ("PLAYER_TOTEM_UPDATE")
	self:UnregisterEvent ("PLAYER_TARGET_CHANGED")
	self:UnregisterEvent ("PLAYER_FOCUS_CHANGED")
	self:UnregisterEvent ("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent ("ACTIONBAR_UPDATE_COOLDOWN")
	self:UnregisterEvent ("ACTIONBAR_UPDATE_USABLE")
	self:UnregisterEvent ("PARTY_MEMBERS_CHANGED")
	self:UnregisterEvent ("RAID_ROSTER_UPDATE")
	self:UnregisterEvent ("ACTIONBAR_SLOT_CHANGED")
	self:UnregisterEvent("PLAYER_REGEN_DISABLED")
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	ABT:DebugTrace ("OnDisable")
end

function ABT:SlashProcessorFunc(input)
	ABT:DebugTrace ("SlashProcessorFunc", true)
  -- Process the slash command ('input' contains whatever follows the slash command)
--	ABT:DebugPrint ("Received command "..input)
	if (input == "reset") then
		for barIdx = 0, ABT_MaxButton do
			local bar = ABT_Bars[barIdx]
			if bar then
				bar:ClearAllPoints()
				bar:SetPoint("CENTER")
			end
		end
	elseif (input == "toggleDebug") then
		if ABT.db.profile.config.showDebug then
			ABT:DebugPrint ("turning debug messages off")
			ABT.db.profile.config.showDebug = false
		else
			ABT.db.profile.config.showDebug = true
			ABT:DebugPrint ("turning debug messages on")
		end
	elseif (input == "toggleTrace") then
		if ABT.db.profile.config.showTrace then
--			ABT:DebugPrint ("turning trace messages off")
			ABT.db.profile.config.showTrace = false
		else
			ABT.db.profile.config.showTrace = true
--			ABT:DebugPrint ("turning trace messages on")
		end
	else
		InterfaceOptionsFrame_OpenToCategory("ButtonTimers")
	end
	ABT:DebugTrace ("SlashProcessorFunc")
end

-- update the bars
ABT.OnUpdate = function(button, elapsed)
	if button:IsShown() and ABT:GetValue(nil, nil, "enable") then
		if button.TimeSinceLastUpdate == nil then 
			button.TimeSinceLastUpdate = elapsed
		end
		button.TimeSinceLastUpdate = button.TimeSinceLastUpdate + elapsed; 	
		if (button.TimeSinceLastUpdate > ABT_UpdateInterval) then
			local currentTime = GetTime()
			button.TimeSinceLastUpdate = 0;
			-- use a flag and implement here so this can only go off a limited frequency
			if (needGetDebuffs and ((currentTime - lastDebuffUpdate) > ABT_DebuffUpdateInterval)) then
				ABT:GetDebuffs()
				needGetDebuffs = false
				lastDebuffUpdate = currentTime
			end
			if button.countdown.expirationTime and button.countdown.expirationTime > currentTime then
				local remaining = button.countdown.expirationTime - currentTime;
				if remaining == math.huge then
					button.countdown:SetText(strInfinity)
				elseif remaining > 10 then
					button.countdown:SetText(format(SecondsToTimeAbbrev(remaining)):gsub("%s+", ""))
				else
					button.countdown:SetFormattedText("%.1f", remaining)
				end
				if button.castTime and button.tex.warnColor and remaining < button.castTime then
					button.tex:SetVertexColor (unpack(button.tex.warnColor))
					if not button.flash:IsShown() then
						button.flash:Show()
					end
				elseif button.flash:IsShown() then
					button.flash:Hide()
				end
				ABT:SetStatusBarRemaining (button, remaining)
				-- fade in next tick predictor
				local fade = button.nextTick.fade
				if fade and fade < 10 then
					fade = fade + 1
					button.nextTick:SetTexture(1, 1, 1, fade * .099) -- should be .1, but floating point error seems to mess it up
					button.nextTick.fade = fade
				end
			else
				button.countdown.expirationTime = nil
				button.countdown:SetText(nil)
				button.nextTick:Hide()
				button.spellName:SetText(nil)
				button.status:Hide()
				button.effect = nil
				button.lastTick = nil
			end
			if button.timer.expirationTime and button.timer.expirationTime > currentTime then
				local remaining = button.timer.expirationTime - currentTime;
				if remaining == math.huge then
					button.timer:SetText(strInfinity)
				elseif remaining > 10 then
					button.timer:SetText(format(SecondsToTimeAbbrev(remaining)):gsub("%s+", ""))
				else
					button.timer:SetFormattedText("%.1f", remaining)
				end
			else
				button.timer.expirationTime = nil
				button.timer:SetText(nil)
			end
			if button.timer.expirationTime == nil and button.countdown.expirationTime == nil then
				button.flash:Hide()
				if button.texture then
					button.texture = nil
					if not button.defaultTexture then
						button.icon:SetTexture(GetActionTexture(button.actionSlot))
					end
				end
			end
			if button.texture or button.defaultTexture then
				button.icon:SetTexture(button.texture or button.defaultTexture)
			end
		end
	end
end

function ABT:GetButtonName (barIdx, buttonIdx)
	local buttonName
	local button = ABT_Buttons[barIdx][buttonIdx]
	local actionSlot = button.button:GetAttribute("action")	
	if actionSlot then
		local actionType, actionId = GetActionInfo(actionSlot)
		-- ABT:DebugPrint ("type="..ABT:NS(actionType).." id="..ABT:NS(actionId))
		if actionType == "spell" then
			buttonName = GetSpellInfo(actionId)
			-- ABT:DebugPrint ("spellName = "..ABT:NS(buttonName))
		elseif actionType == "macro" then
			buttonName = GetActionText(actionSlot)
		elseif actionType == "item" then
			buttonName = GetItemInfo(actionId)
		end
	end
	if buttonName == nil then
		buttonName = "bar"..barIdx.."button"..buttonIdx
	end
	return buttonName
end


local function ABTGetSpellCooldown(spell)
	local charges, maxCharges, start, duration = GetSpellCharges(spell);
	if charges and maxCharges and maxCharges > 1 and maxCharges > charges then
		return start, duration
	else
		return GetSpellCooldown(spell)
	end
end

local function ABTGetActionCooldown(action)
	local charges, maxCharges, start, duration = GetActionCharges(action);
	if charges and maxCharges and maxCharges > 1 and maxCharges > charges then
		return start, duration
	else
		return GetActionCooldown(action)
	end
end

--
-- Help, does this really need to do all buttons for each call?
-- couldn't we just update cooldowns on buttons that gave the action?
function ABT:GetCooldowns (event, arg1)
	ABT:DebugTrace ("GetCooldowns", true)
	for barIdx, buttonIdx in ABT:GetNextButton() do
		local key = "bar"..barIdx.."button"..buttonIdx
		local timerType = ABT:GetValue (barIdx, buttonIdx, "timerType")
		local location = ABT:GetValue(barIdx, nil, "location")
		if timerType == ABT_COOLDOWN or timerType == ABT_BOTH then -- cooldown timer
			local otherSpell = ABT:GetValue (barIdx, buttonIdx, "spell")
			local otherSpellId = tonumber(otherSpell)
			local button = ABT_Buttons[barIdx][buttonIdx]
			local slot = button.button:GetAttribute ("action")
			local useTimer = (timerType == ABT_BOTH or (timerType == ABT_COOLDOWN and location == ABT_ONBUTTONS))
			local useStatusbar = (timerType == ABT_COOLDOWN and location ~= ABT_ONBUTTONS)

			local start, duration
			if otherSpellId then
				start, duration = ABTGetSpellCooldown (otherSpellId)
			elseif otherSpell and otherSpell ~= "" then
				start, duration = ABTGetSpellCooldown (otherSpell)
			elseif (slot) then
				start, duration = ABTGetActionCooldown (slot)
			end
			if start and duration then
				-- we have a cooldown to track
				if start > 0 and duration > 1.5 then
					local add = tonumber(ABT:GetValue (barIdx, buttonIdx, "timerAdjust"))

					if useTimer then
						button.timer.expirationTime = start + duration + (add or 0)
						if (button.timer.expirationTime <= 0) then
							button.timer.expirationTime = nil
						end
					elseif useStatusbar then
						button.countdown.expirationTime = start + duration + (add or 0)
						if (button.countdown.expirationTime <= 0) then
							button.countdown.expirationTime = nil
						else
							if ABT:GetValue (barIdx, nil, "orientation") == ABT_VERTICAL then
								if otherSpell then
									button.spellName:SetText(otherSpell)
								end
								-- find the name of the spell, so we can put it on the timer
								local spellName = ABT:GetButtonName (barIdx, buttonIdx)
								if spellName then
									button.spellName:SetText(spellName)
								end
							else
								button.spellName:SetText(nil)
							end
							local barTime
							if ABT:GetValue (barIdx, buttonIdx, "barType") == ABT_FIXED then
								barTime = ABT:GetValue (barIdx, buttonIdx, "barTime")
							else
								barTime = duration
							end
							button.tex.max = barTime
							button.status:Show()
						end
					end
				-- we have a cooldown timer running, but the cooldown is no longer
				-- active. Reset it. If it's less than the GCD, though, just let it run out.
				elseif useTimer and button.timer.expirationTime and (button.timer.expirationTime - GetTime()) > 1.5 then
					button.timer.expirationTime = nil
				elseif useStatusbar and button.countdown.expirationTime and (button.countdown.expirationTime - GetTime()) > 1.5 then
					button.countdown.expirationTime = nil
				end
			end
		end
	end
	ABT:DebugTrace ("GetCooldowns")
end

function ABT:MarkNeedDebuffs(event, arg1)
--	ABT:DebugPrint ("MarkNeedDebuffs")
	needGetDebuffs = true
end

-- returns name of aura effect generated by this action slot
local function GetActionAura(actionSlot)
	if actionSlot then
		local actionType, actionId = GetActionInfo(actionSlot)
		-- ABT:DebugPrint ("type="..ABT:NS(actionType).." id="..ABT:NS(actionId).." slot="..actionSlot)
		if actionType == "item" then
			 -- print(GetItemInfo(actionId))
			 -- print(GetItemSpell(actionId))
			return GetItemSpell(actionId)
		elseif actionType == "macro" then
			-- print("macro name", (GetMacroInfo(actionId)))
			local itemLink = GetMacroItem(actionId)
			if itemLink then
				return GetItemSpell(itemLink)
			else  -- if not an item, assume a spell
				local spellId = GetMacroSpell(actionId)
				return GetSpellInfo(spellId)
			end
		elseif actionType == "spell" then
			return GetSpellInfo(actionId)	
		end
	end
end

-- These two meta tables are used to snapshot the collection
-- of all buffs and debuffs on a particular unit. Its all done
-- via metatables on first access so if you never check for an
-- aura on the focus target, for example, no work is done.
local tblUnitMeta = { 
	__index = function(t,k)
		-- print("jitting table for", k)
		local newaura = {}
		rawset(t, k, newaura)
		return newaura
	end
}
local tblAurasMeta = {
	__index = function(t,k)
		-- print("jitting table for", k)
		local newunit = setmetatable( {}, tblUnitMeta )
		rawset(t, k, newunit)

		for _,funcAura in ipairs( { UnitDebuff, UnitBuff } ) do
			local index = 1
			repeat
				local name, iconTexture, count, _, duration, expirationTime, caster, _, _, spellID = funcAura(k, index)

				if (duration == 0 and expirationTime == 0) then
					duration = math.huge
					expirationTime = math.huge
				end

				if name then
					local newAura = { name = name, spellID = spellID, iconTexture = iconTexture, count = count, caster = caster, duration = duration, expirationTime = expirationTime }
					tinsert(newunit[name], newAura)
					tinsert(newunit[spellID], newAura)
					index = index + 1
				end
			until not name
		end

		return newunit
	end
}

function ABT:GetDebuffs(event, arg1)
	ABT:DebugTrace ("GetDebuffs", true)
	-- ABT:DebugPrint ("GetDebuffs "..ABT:NS(event).." "..ABT:NS(arg1))

	-- access this table to check for instances of a given aura on a target
	-- tblUnitAuras["target"]["aura"] returns table of instances		
	local tblUnitAuras = setmetatable( {}, tblAurasMeta )

	-- Getting the current time could introduce overhead from having to get it from the system. Just get it once per call.
	local currenttime = GetTime()

	-- loop over buttons looking for aura timer buttons matching the target
	for barIdx, buttonIdx in ABT:GetNextButton() do
		-- ABT:DebugPrint ("bar="..ABT:NS(barIdx).." button="..ABT:NS(buttonIdx))
		local timerType = ABT:GetValue (barIdx, buttonIdx, "timerType")
		if (timerType == ABT_AURA or timerType == ABT_BOTH) then -- aura timer
			local button = ABT_Buttons[barIdx][buttonIdx]
			local target = button.targetUnit or "target"
			local showOthers = ABT:GetValue (barIdx, buttonIdx, "showOthers")
			local showAuraIcon = ABT:GetValue(barIdx, buttonIdx, "showAuraIcon")
			local ignoreButtonAura = ABT:GetValue(barIdx, buttonIdx, "ignoreButtonAura")

			-- build list of all auras sharing this timer
			if not button.auraList or ABT_Bars[barIdx].needsRefresh then
				button.auraList = ABT:parseAuraList(barIdx, buttonIdx, (target == "totem"))
			end

			if not ignoreButtonAura then
				-- have to check actionSlot everytime as macros and certain spells could change
				button.auraList[0] = GetActionAura(button.actionSlot)
			elseif showAuraIcon then
				-- if we're ignoring the actionSlot's aura then use the first aura from the list for icon
				button.defaultTexture = button.auraList[1] and g_iconCache[button.auraList[1]] or "Interface\\Icons\\INV_MISC_QUESTIONMARK"
			end

			-- now look for an aura to show for this button
			local auraFound = nil -- haven't yet found a match for this button
			-- the loops counts down from the last entry in Other Auras box to the first and then the action slot as appropriate
			for i = #button.auraList, (not ignoreButtonAura and button.auraList[0]) and 0 or 1, -1 do
				local effect = button.auraList[i]
				-- ABT:DebugPrint ("Looking for -"..effect.."- on button "..button:GetName().." target="..ABT:NS(target))
				if (target == "totem") then
					for totemId = 1, 4 do
						local _, totemName, startTime, duration, iconTexture = GetTotemInfo(totemId);
						if (totemName == effect) then
							auraFound = { name = totemName, iconTexture = iconTexture, count = 0, caster = "player", duration = duration, expirationTime = (startTime + duration) }
							break
						end
					end
				else
					for _, aura in pairs( tblUnitAuras[target][effect] ) do
						-- the effect was found on the mob, now lets see if it's ours
						-- use the effect if it is ours, or if the anyCaster flag is set and the button 
						-- was not previously found. This will prioritize our own spells for display if multiple
						-- matching effects are found
						g_iconCache[aura.name] = aura.iconTexture
						local isMine = (aura.caster == "player" or aura.caster == "pet" or aura.caster == "vehicle" or (aura.caster == nil and target == "player"))
						if (isMine or (showOthers and not auraFound)) then
							auraFound = aura
						end
					end
				end
			end

			-- now update the UI based on what we found or didn't find
			local location = ABT:GetValue(barIdx, nil, "location")
			local useTimer = (timerType == ABT_AURA and location == ABT_ONBUTTONS)
			local useStatusbar = (timerType == ABT_BOTH or (timerType == ABT_AURA and location ~= ABT_ONBUTTONS))
			
			if not auraFound then
				if useTimer then
					button.timer.expirationTime = nil
				elseif useStatusbar then
					button.countdown.expirationTime = nil
				end
			else
				local tickPrediction = ABT:GetValue(barIdx, buttonIdx, "showTickPrediction")
				local add = tonumber(ABT:GetValue (barIdx, buttonIdx, "timerAdjust")) or 0

				if useTimer then
					button.timer.expirationTime = auraFound.expirationTime + add -- time left on this effect
					if (button.timer.expirationTime <= 0) then
						button.timer.expirationTime = nil
					end
				elseif useStatusbar then
					button.countdown.expirationTime = auraFound.expirationTime + add -- time left on this effect
					if (button.countdown.expirationTime <= 0) then
						button.countdown.expirationTime = nil
						button.effect = nil
					else
						if ABT:GetValue (barIdx, buttonIdx, "barType") == ABT_FIXED then
							button.tex.max = ABT:GetValue (barIdx, buttonIdx, "barTime")
						else
							button.tex.max = auraFound.duration
						end
						if button.tex.timerColor then
							button.tex:SetVertexColor(unpack(button.tex.timerColor))
						end
						if button.tex.warnColor then
							button.castTime = ABT:GetCastTime(button) + (tonumber(ABT:GetValue(barIdx, buttonIdx, "castTimeAdjust")) or 0)
						end
						button.status:Show()
						
						if tickPrediction then
							button.effect = auraFound.name
						end
						local spellText = nil
						if ABT:GetValue (barIdx, nil, "orientation") == ABT_HORIZONTAL then
							if auraFound.count > 1 then
								spellText = "x"..ABT:NS(auraFound.count)
							end
						else -- orientation == ABT_VERTICAL
							spellText = auraFound.name

							if auraFound.count > 1 then
								spellText = spellText.." x"..ABT:NS(auraFound.count)
							end
							if target ~= "target" then
								spellText = spellText..": "..ABT:NS(UnitName(target))
							end
						end
						button.spellName:SetText(spellText)

						if button.tickLength then
							local timeLeft = auraFound.expirationTime - currenttime
							local timeTick = auraFound.duration - button.tickLength 
							if (timeLeft > timeTick) then
								ABT:SetTickTime (button, timeTick)
							elseif timeLeft < button.tickLength then
								button.nextTick:Hide()
							end
						end
					end
				end
				ABT:DebugPrint ("bar"..barIdx.."button"..buttonIdx.."showAuraIcon="..ABT:NS(showAuraIcon).." a="..ABT:NS(button.timer.expirationTime).." b="..ABT:NS(button.countdown.expirationTime))
				if ((button.timer.expirationTime or button.countdown.expirationTime) and showAuraIcon and button.texture ~= auraFound.iconTexture) then
					ABT:DebugPrint ("bar"..barIdx.."button"..buttonIdx.." setting icon to: "..ABT:NS(auraFound.iconTexture))
					button.texture = auraFound.iconTexture
				end
			end
		end
	end
	ABT:DebugTrace ("GetDebuffs")
end

function ABT:GetNextButton()
	local currentBar = 1
	local currentButton = 0
	
	return function()
		while true do
			currentButton = currentButton + 1
			if currentButton > ABT_MaxButton then
				currentBar = currentBar + 1
				currentButton = 1
				if currentBar > ABT_MaxBar then
					return nil, nil
				end
			end
			if not ABT:IsButtonHidden (currentBar, currentButton) then
				return currentBar, currentButton
			end
		end
	end
end

function ABT:StartMoving (self)
	ABT:DebugTrace ("StartMoving", true)
	if (not InCombatLockdown() and not self.locked) then
		self:StartMoving()
	end
	ABT:DebugTrace ("StartMoving")
end

function ABT:StopMoving (self)
	ABT:DebugTrace ("StopMoving", true)
	self:StopMovingOrSizing ()
	local barIdx = self.barIdx
	local attach = { self:GetPoint() }
	ABT:SetValue (barIdx, nil, "attach", attach)
--	ABT:DebugPrint ("stop moving bar="..barIdx.." "..ABT:NS(attach))
	ABT:DebugTrace ("StopMoving", true)
end

function ABT:MakeWidgets()
	ABT:DebugTrace ("MakeWidgets", true)
	for barIdx = 1, ABT_MaxBar do
		local barName = ABT_Widgets.."bar"..barIdx
		local bar = CreateFrame ("Frame", barName, UIParent)
		ABT_Bars[barIdx] = bar
		bar.barIdx = barIdx
		-- this texture is handy for seeing where the frame is to drag it.
		-- only show it if the bar is draggable.
		bar.texture = bar:CreateTexture ()
		bar.texture:SetAllPoints(bar)
		bar.texture:SetColorTexture(1, 1, 1, .1)
		bar.texture:Hide()
		--
		-- setup for dragging
		bar:SetMovable (true)
		bar:SetClampedToScreen (true)
		bar:EnableMouse (true)
		bar:SetScript ("OnMouseDown", function (self) ABT:StartMoving (self) end)
		bar:SetScript ("OnMouseUp", function (self) ABT:StopMoving (self) end)
		bar:SetScript ("OnDragStop", function (self) ABT:StopMoving () end)

		ABT_Buttons[barIdx] = {}
		for buttonIdx = 1, ABT_MaxButton do
			local buttonName = barName.."button"..buttonIdx
			local button = CreateFrame ("Frame", buttonName , bar, "ABTButtonTemplate")

			ABT_Buttons[barIdx][buttonIdx] = button
			button:SetScript ("OnUpdate", ABT.OnUpdate)
			button.barIdx = barIdx
			button.buttonIdx = buttonIdx
			button.icon = _G[buttonName.."ButtonIcon"]
			button.status = _G[buttonName.."ButtonStatusBar"]
			button.tex = _G[buttonName.."ButtonStatusBarTex"]
			button.spellName = _G[buttonName.."ButtonStatusBarSpellName"]
			button.countdown = _G[buttonName.."ButtonStatusBarCountdown"]
			button.timer = _G[buttonName.."ButtonTimer"]
			button.status:Show()
			button.cooldown = _G[buttonName.."ButtonCooldown"]
			button.flash = _G[buttonName.."ButtonTint"]
			button.button = _G[buttonName.."Button"]
			button.nextTick = button.status:CreateTexture(buttonName.."ButtonnextTick", "OVERLAY")
			button.nextTick:SetTexture(1, 1, 1, 1)
			button.nextTick:Hide()
			button.button:HookScript ("OnEnter", 
									function () 
										if ABT:GetValue(barIdx, nil, "hideTooltips") then 
											GameTooltip:Hide() 
										end 
									end)
		end
	end
	ABT:SetAllBars("MakeWidgets")
	ABT:DebugTrace ("MakeWidgets")
end

-- register buttons with Masque
function ABT:RegisterMSQ (event, arg1)
	ABT:DebugTrace ("RegisterMSQ", true)
	if MSQ then
		for barIdx = 1, ABT_MaxBar do
			local group = MSQ:Group("ButtonTimers", "Button Timers Bar"..barIdx)
			for buttonIdx = 1, ABT_MaxButton do
				group:AddButton(ABT_Buttons[barIdx][buttonIdx].button)
			end
		end
	end
	ABT:DebugTrace ("RegisterMSQ")
end

function ABT:SetAllBars (event, arg1, ...)
	self:DebugPrint("ABT:SetAllBars", event)
	for barIdx = 1, ABT_MaxBar do
		ABT:SetBar (barIdx)
	end
end

function ABT:SetBar (barIdx)
	ABT:DebugTrace ("SetBar"..barIdx, true)
	
	if InCombatLockdown() then
		-- we're in combat, don't do anything now, but flag it so we
		-- can do the operation when we leave combat.
		ABT_Bars[barIdx].needsRefresh = true
		return
	end
	local width = 0
	local height = 0

	local buttonCount = ABT:GetUsableButtonCount(barIdx)
	local orientation = ABT:GetValue(barIdx, nil, "orientation")
	local location = ABT:GetValue(barIdx, nil, "location") 
	local scale = ABT:GetValue(barIdx, nil, "scale")
	local length = ABT:GetValue(barIdx, nil, "length")
	local margin = ABT:GetValue(barIdx, nil, "spacing")
	local actionOffset = ABT:GetValue(barIdx, nil, "actionOffset")
	local enabled = ABT:GetValue(barIdx, nil, "enabled") and ABT:GetValue(nil, nil, "enable")
	local locked = ABT:GetValue(barIdx, nil, "locked")
	local showBackground = ABT:GetValue(nil, nil, "showBackground")
	local inCombat = ABT:GetValue(barIdx, nil, "inCombat")
	local barFont = LSM:Fetch ("font", ABT:GetValue (barIdx, nil, "font"))
	local barTexture = LSM:Fetch ("statusbar", ABT:GetValue (barIdx, nil, "texture"))
	
	local bar = ABT_Bars[barIdx]

	-- bar enable
	if enabled then
		bar:Show()
	else
		bar:Hide()
		return
	end
	
	-- bar lockdown
	bar.locked = locked
	
	local attach = ABT:GetValue(barIdx, nil, "attach")

	-- set bar position
	if (attach == nil) then
		attach = {"CENTER", nil, "CENTER", (44 * (barIdx-1)), 0}
		ABT:SetValue (barIdx, nil, "attach", attach)
	end
 	bar:ClearAllPoints()
	bar:SetPoint(unpack(attach))

	-- scale option
	local oldscale = bar:GetScale()
	local newscale = scale  * .6

	if oldscale ~= newscale and attach then
		bar:SetScale(newscale)
		if g_barScaleInited[barIdx] ~= nil then
			local point, parent, relpoint, xOfs, yOfs = unpack(attach)
			xOfs = xOfs * oldscale / newscale
			yOfs = yOfs * oldscale / newscale
			attach = {point, parent, relpoint, xOfs, yOfs}
			ABT:SetValue (barIdx, nil, "attach", attach)
--			ABT:DebugPrint ("scaled DB attach="..ABT:NS(attach))
			bar:ClearAllPoints()
			bar:SetPoint(unpack(attach))
		else
			g_barScaleInited[barIdx] = true		
		end
	end
	
	-- button count, target
	for buttonIdx = 1, ABT_MaxButton do
		local button = ABT_Buttons[barIdx][buttonIdx]
		button.actionSlot = buttonIdx + actionOffset
		button.actionType, button.actionId = GetActionInfo(button.actionSlot)

		if ABT:IsButtonHidden(barIdx, buttonIdx) then
			button:Hide()
		else
			button:Show()
			local targetIdx = ABT:GetValue(barIdx, buttonIdx, "target")
			local useAsSpellTarget = ABT:GetValue(barIdx, buttonIdx, "useAsSpellTarget")
			button.targetUnit = nil
			if targetIdx == ABT_PARTY then
				local playerTarget = ABT:GetValue(barIdx, buttonIdx, "playerTarget")
				button.targetUnit = ABT:FindPlayerUnitId (playerTarget)
			elseif targetIdx == ABT_BOSS then
				local idBoss = ABT:GetValue(barIdx, buttonIdx, "bossTarget")
				button.targetUnit = "boss" .. idBoss
			elseif targetIdx ~= ABT_TARGET then
				button.targetUnit = ABT_TARGET_NAMES[targetIdx]
			else
				button.targetUnit = nil
			end
			if useAsSpellTarget and targetIdx ~= ABT_TOTEM then
				button.button:SetAttribute("unit", button.targetUnit)
			else
				button.button:SetAttribute("unit", nil)
			end

			local statusbarTexture = barTexture or "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
--			ABT:DebugPrint ("statusbarTexture="..statusbarTexture)
			local timerColor = ABT:GetValue (barIdx, buttonIdx, "timerColor")
			local textColor = ABT:GetValue (barIdx, buttonIdx, "textColor")
			local warnColor = ABT:GetValue (barIdx, buttonIdx, "timerWarnColor")
			local colorChange = ABT:GetValue (barIdx, buttonIdx, "colorChange")
			local timerType = ABT:GetValue (barIdx, buttonIdx, "timerType")
			
			button.tex.timerColor = timerColor
			button.tex:SetTexture(statusbarTexture)
			if colorChange and warnColor and (timerType == ABT_AURA or timerType == ABT_BOTH) then
				button.tex.warnColor = warnColor
				button.flash:SetColorTexture (unpack(warnColor))
			else
				button.tex.warnColor = nil
			end
			if timerColor then
				button.tex:SetVertexColor (unpack(timerColor))
			end
			if textColor then
				button.countdown:SetTextColor (unpack(textColor))
				button.spellName:SetTextColor (unpack(textColor))
				button.timer:SetTextColor (unpack(textColor))
			end
	
			button.button:SetAttribute ("action", buttonIdx + actionOffset)
			height = button:GetHeight()
			width = button:GetWidth()

			button.auraList = nil
			button.texture = nil
			button.defaultTexture = nil
			button.icon:SetTexture(GetActionTexture(buttonIdx + actionOffset))

			-- set fonts
			if barFont then
--				ABT:DebugPrint ("font="..ABT:NS(barFont))
				local fontHeight = height / 2
				if orientation == ABT_HORIZONTAL then
					fontHeight = height / 2.8
				end
				button.timer:SetFont (barFont, fontHeight)
				button.countdown:SetFont (barFont, fontHeight)
				button.spellName:SetFont (barFont, fontHeight)
			end
			button.status:ClearAllPoints()
			button.countdown:ClearAllPoints()
			button.tex:ClearAllPoints()
			button.spellName:ClearAllPoints()
			button.cooldown.noCooldownCount = nil -- for OmniCC
			button.timer:SetText(nil)
			button.countdown.expirationTime = nil
			button.timer.expirationTime = nil
			local x, y, statusX, statusY
			if orientation == ABT_VERTICAL then
				x = outer_margin
				y = -1* (buttonIdx-1) * (height+margin) - outer_margin
				button.tex.orientation = "HORIZONTAL"
				button.tex:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1) -- standard texture orientation
				button.status:SetHeight(34)
				button.tex:SetHeight(34)
				button.spellName:SetWidth(length-60) -- field starts 60 pixels to the right
				button.spellName:SetHeight(34) -- don't go into a multiline display
				button.status:SetWidth(length)
				button.spellName:Show()
				if location == ABT_TOPRIGHT then
					button.tex.reverse = false
					button.status:SetPoint("TOPLEFT", button:GetName(), "TOPRIGHT")
					button.tex:SetPoint("LEFT", button.status:GetName(), "LEFT", 3, 0)
					button.countdown:SetPoint("LEFT", button.status:GetName(), "LEFT", 14, 0)
					button.spellName:SetPoint("LEFT", button.status:GetName(), "LEFT", 60, 0)
				elseif location == ABT_BOTTOMLEFT then
					button.tex.reverse = true
					button.status:SetPoint("TOPRIGHT", button:GetName(), "TOPLEFT")
					button.tex:SetPoint("RIGHT", button.status:GetName(), "RIGHT", -4, 0)
					button.countdown:SetPoint("RIGHT", button.status:GetName(), "RIGHT", -14, 0)
					button.spellName:SetPoint("RIGHT", button.status:GetName(), "RIGHT", -60, 0)
				elseif location == ABT_ONBUTTONS or timerType == ABT_BOTH then
					button.cooldown.noCooldownCount = true -- for OmniCC
					button.status:Hide()
				end
			else -- orientation == ABT_HORIZONTAL
				x = (buttonIdx-1) * (width+margin) + outer_margin
				y = -outer_margin
				button.tex.orientation = "VERTICAL"
				button.tex:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0) -- rotate texture 90 degrees for vertical bar
				button.status:SetHeight(length)
				button.status:SetWidth(34)
				button.tex:SetWidth(34)
				button.spellName:SetWidth(68) -- don't truncate the stack counter in this orientation
				button.spellName:Show()
				if ((location == ABT_TOPRIGHT) or (timerType == ABT_BOTH and location == ABT_ONBUTTONS)) then
					button.tex.reverse = false
					button.status:SetPoint("BOTTOMLEFT", button:GetName(), "TOPLEFT")
					button.tex:SetPoint("BOTTOM", button.status:GetName(), "BOTTOM", 0, 3)
					button.countdown:SetPoint("BOTTOM", button.status:GetName(), "BOTTOM", 0, 14)
					button.spellName:SetPoint("BOTTOM", button.status:GetName(), "BOTTOM", 0, 32)
				elseif location == ABT_BOTTOMLEFT then
					button.tex.reverse = true
					button.status:SetPoint("TOPLEFT", button:GetName(), "BOTTOMLEFT")
					button.tex:SetPoint("TOP", button.status:GetName(), "TOP", 0, -4)
					button.countdown:SetPoint("TOPLEFT", button.status:GetName(), "TOPLEFT", 0, -14)
					button.spellName:SetPoint("TOPLEFT", button.status:GetName(), "TOPLEFT", 0, -32)
				elseif location == ABT_ONBUTTONS then
					button.cooldown.noCooldownCount = true -- for OmniCC
					button.status:Hide()
				end
			end
			button:ClearAllPoints()
			button:SetPoint ("TOPLEFT", x, y)

			button.button.Border:Hide();
			button.button.HotKey:Hide();
			button.button.NewActionTexture:Hide();
			button.button.Name:Hide();
			button.button.NormalTexture:Hide();
			button.button.FlyoutBorderShadow:Hide();
			button.button.FlyoutBorder:Hide();
	
			if locked then
				bar.texture:Hide()
			else
				bar.texture:Show()
			end
		end
	end
	
	-- layout
	if width ~= 0 and height ~= 0 then
		local barWidth
		local barHeight
		if orientation == ABT_VERTICAL then -- vertical
			barHeight = (height * buttonCount) + ((buttonCount - 1) * margin) + (outer_margin * 2)
			barWidth = width + (outer_margin * 2)
		else -- horizontal
			barHeight = height + (outer_margin * 2)
			barWidth = (width * buttonCount) + ((buttonCount - 1) * margin) + (outer_margin * 2)
		end
--		ABT:DebugPrint ("barHeight="..barHeight.." barWidth="..barWidth)
		bar:SetHeight(barHeight)
		bar:SetWidth(barWidth)
	end

	if inCombat and not InCombatLockdown() then
		bar:Hide()
	end	
	ABT_Bars[barIdx].needsRefresh = nil
	ABT:ButtonUpdate()
	ABT:DebugTrace ("SetBar")
end

function ABT:UpdatePlayerTargets()
ABT:DebugTrace ("UpdatePlayerTargets", true)
	for barIdx, buttonIdx in ABT:GetNextButton() do
		if (ABT:GetValue(barIdx, buttonIdx, "target") == ABT_PARTY) then
			local playerTarget = ABT:GetValue (barIdx, buttonIdx, "playerTarget")
			local unitId = ABT:FindPlayerUnitId (playerTarget)
			local button = ABT_Buttons[barIdx][buttonIdx]
			button.targetUnit = unitId
			button.button:SetAttribute ("unit", unitId)
		end
	end
	ABT:MarkNeedDebuffs()
	ABT:DebugTrace ("UpdatePlayerTargets")
end

function ABT:FindPlayerUnitId (playerTarget)
	local unitId = nil
--	ABT:DebugPrint ("FindPlayerUnitId looking for: "..ABT:NS(playerTarget))
	if playerTarget ~= nil then
		local group = IsInRaid() and "raid" or "party"
		for i = 1, GetNumGroupMembers() do
			if UnitName(group..i) == playerTarget then
				unitId = group..i
				break
			end
		end
	end
--	ABT:DebugPrint ("FindPlayerUnitId found "..ABT:NS(playerTarget).." as "..ABT:NS(unitId))
	return unitId
end

function ABT:GetPartyList ()
	local _table = {}
	local playerName = nil
	local group = IsInRaid() and "raid" or "party"
	for i = 1, GetNumGroupMembers() do
		playerName = UnitName(group..i)
		if playerName then _table[playerName] = playerName end
	end
	return _table
end

function ABT:SetStatusBarRemaining (button, remaining)
	local value = (button.tex.max == math.huge) and 1 or min(1, remaining / button.tex.max)
	local length = ABT:GetValue(button.barIdx, nil, "length")
	if button.tex.orientation == "VERTICAL" then
		button.tex:SetHeight(value*length)
	else
		button.tex:SetWidth(value*length)
	end
end

function ABT:GetCastTime(button)
	local name, subname, icon, castTime
	local actionSlot = button.button:GetAttribute("action")	
	if actionSlot then
		local actionType, actionId = GetActionInfo(actionSlot)
		if actionType == "spell" and actionId > 0 then
			name, subname, icon, castTime = GetSpellInfo(actionId)
			-- ABT:DebugPrint (ABT:NS(actionSlot).." "..ABT:NS(actionType).." "..ABT:NS(actionId).." "..ABT:NS(name).." Cast time= "..ABT:NS(castTime))
		end
	end

	if type(castTime) ~= "number" or castTime == 0 then
		return 0
	else
		return castTime / 1000
	end
end

local ABT_TICKWIDTH = 2  -- height/width assumes horizontal bar, for vertical swap them
local ABT_TICKHEIGHT = 8
--
-- Position the tick marker for a button's status bar at the time requested.
function ABT:SetTickTime (button, tickTime)
    -- ABT:DebugPrint ("tt="..tickTime.." max="..button.tex.max.." showTicks="..ABT:NS(ABT:GetValue(button.barIdx, button.buttonIdx, "showTickPrediction")))
	if tickTime and tickTime <= button.tex.max and ABT:GetValue(button.barIdx, button.buttonIdx, "showTickPrediction") then
		if tickTime < 0 then
			tickTime = 0
		end
		local length = ABT:GetValue(button.barIdx, nil, "length") -- get length of bar
		local offset
		local location = ABT:GetValue(button.barIdx, nil, "location") 
		if location == ABT_TOPRIGHT then
			offset = tickTime * length / button.tex.max         -- compute position of tick marker in terms of pixel offset from start of bar
		else
			offset = (button.tex.max - tickTime) * length / button.tex.max         -- compute position of tick marker in terms of pixel offset from start of bar
		end
--		ABT:DebugPrint ("length="..ABT:NS(length).." offsetTime="..ABT:NS(tickTimer).." offset="..ABT:NS(offset).." orien="..ABT:NS(button.tex.orientation)).." loc="..ABT:NS(location))
		-- see if it's already up and in place
		if button.nextTick:IsShown() and button.nextTick.offset == offset then
			return
		end
		button.nextTick:Hide()
		button.nextTick.offset = offset
		-- set dimensions and position of tick marker
		button.nextTick:ClearAllPoints()  -- reset position
		if button.tex.orientation == "VERTICAL" then
			button.nextTick:SetWidth(ABT_TICKHEIGHT)
			button.nextTick:SetHeight(ABT_TICKWIDTH)
			if location == ABT_TOPRIGHT then
				button.nextTick:SetPoint("BOTTOMLEFT", button.status:GetName(), "BOTTOMLEFT", 0, offset)
			else
				button.nextTick:SetPoint("BOTTOMLEFT", button.status:GetName(), "BOTTOMLEFT", 0, offset)
			end
		else
			button.nextTick:SetHeight(ABT_TICKHEIGHT)
			button.nextTick:SetWidth(ABT_TICKWIDTH)
			if location == ABT_TOPRIGHT then
				button.nextTick:SetPoint("TOPLEFT", button.status:GetName(), "TOPLEFT", offset, 0)
			else
				button.nextTick:SetPoint("TOPLEFT", button.status:GetName(), "TOPLEFT", offset, 0)
			end
		end
		button.nextTick.fade = 1
		button.nextTick:SetTexture(1, 1, 1, .1)
		button.nextTick:Show()            -- display tick marker
	else
		button.nextTick:Hide()
	end
end

-- look for incoming dot ticks and set the tick marker to the time of the next calculated tick
function ABT:ProcessCombatLogEvent (timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
	-- only look at the player's events
	if UnitGUID("player") == srcGUID then
		-- only look at periodic spell damage
		if (strfind (event, "SPELL_PERIODIC")) then
			local spellName = select (2, ...)
--			ABT:DebugPrint (event.." "..spellName)
			-- loop over buttons
			for barIdx, buttonIdx in ABT:GetNextButton() do
				local button = ABT_Buttons[barIdx][buttonIdx]
				if button.effect ~= nil then
--						ABT:DebugPrint ("checking bar="..barIdx.." button="..buttonIdx.." spell="..ABT:NS(button.effect))
				end
				-- this button is currently showing the effect that matches the damage event
				if button.effect == spellName then
					local target = button.targetUnit or "target"
					-- see if damage target matches the button target
					if (UnitGUID(target) == dstGUID) then
--							ABT:DebugPrint ("tick@"..timestamp.." spell="..spellName.." target="..target.." time="..time().." GetTime="..GetTime())
--							ABT:DebugPrint (" spell="..spellName.." GetTime="..GetTime())
						-- tickLength is the calculated time between dots ticks
						if (button.tickLength) then
							local nextTick = timestamp + button.tickLength -- calculate next tick time
--								ABT:DebugPrint ("nextTick="..nextTick.." tickLength="..button.tickLength.." expTime="..button.countdown.expirationTime)
							-- the timestamp is a value relative to the "time" function. GetTime has a different relative start.
							-- These two times are not compatible :/ Compute the offset based on the expiration time of the timer.
							-- That's going to cause some weirdness in terms of lag, but I don't have a solution right now.
							local offsetTime = 0
							if (button.countdown.expirationTime and button.tickLength) then
								offsetTime = (button.countdown.expirationTime - GetTime() - button.tickLength)
							end
							ABT:SetTickTime (button, offsetTime)
						end
						-- compute the time in between ticks.
						if button.lastTick then
							button.tickLength = timestamp - button.lastTick
--								ABT:DebugPrint ("ticklength="..button.tickLength)
						end
						button.lastTick = timestamp
					end
				end
			end
		end
	end
end
