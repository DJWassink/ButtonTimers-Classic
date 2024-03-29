local L = LibStub("AceLocale-3.0"):NewLocale("ButtonTimers", "koKR")
if not L then return end

--[==[
Incorrect or untranslated phrases can be updated through the localization tool 
for this addon at http://www.curseforge.com/addons/buttontimers/localization/.
Please notify the author, stencil, by private message after making any updates 
so that a new build will get released containing the new translations.

잘못되거나 번역되지 않은 문장이 http://www.curseforge.com/addons/buttontimers/localization/
에서이 부가위한 현지화 도구를 통해 업데이트 할 수 있습니다.
새로운 빌드가 새로운 번역을 포함하는 발표하게 ​​될 수 있도록 업데이트를 한 후 
비공개 메시지에서 저자, stencil을 알려 주시기 바랍니다.
--]==]

--[[Translation missing --]]
--[[ L["Action Offset"] = "Action Offset"--]] 
--[[Translation missing --]]
--[[ L["Add any additional aura names or spellIds as a comma separated list."] = "Add any additional aura names or spellIds as a comma separated list."--]] 
--[[Translation missing --]]
--[[ L["Adjust Cast Time"] = "Adjust Cast Time"--]] 
--[[Translation missing --]]
--[[ L["Adjust Timer"] = "Adjust Timer"--]] 
--[[Translation missing --]]
--[[ L["Allows you to scale the bar size"] = "Allows you to scale the bar size"--]] 
--[[Translation missing --]]
--[[ L["Aura"] = "Aura"--]] 
--[[Translation missing --]]
--[[ L["Bar Color"] = "Bar Color"--]] 
--[[Translation missing --]]
--[[ L["Bar color for timers"] = "Bar color for timers"--]] 
--[[Translation missing --]]
--[[ L["Bar color for timers when remaining time < cast time"] = "Bar color for timers when remaining time < cast time"--]] 
--[[Translation missing --]]
--[[ L["Bar Enabled"] = "Bar Enabled"--]] 
--[[Translation missing --]]
--[[ L["Bar Font"] = "Bar Font"--]] 
--[[Translation missing --]]
--[[ L["Bar Length"] = "Bar Length"--]] 
--[[Translation missing --]]
--[[ L["Bar Locked"] = "Bar Locked"--]] 
--[[Translation missing --]]
--[[ L["Bar Scale"] = "Bar Scale"--]] 
--[[Translation missing --]]
--[[ L["Bar Time"] = "Bar Time"--]] 
--[[Translation missing --]]
--[[ L["Boss"] = "Boss"--]] 
--[[Translation missing --]]
--[[ L["Boss #1"] = "Boss #1"--]] 
--[[Translation missing --]]
--[[ L["Boss #2"] = "Boss #2"--]] 
--[[Translation missing --]]
--[[ L["Boss #3"] = "Boss #3"--]] 
--[[Translation missing --]]
--[[ L["Boss #4"] = "Boss #4"--]] 
--[[Translation missing --]]
--[[ L["Boss #5"] = "Boss #5"--]] 
--[[Translation missing --]]
--[[ L["Both"] = "Both"--]] 
--[[Translation missing --]]
--[[ L["Button Count"] = "Button Count"--]] 
--[[Translation missing --]]
--[[ L["Button Spacing"] = "Button Spacing"--]] 
--[[Translation missing --]]
--[[ L["Change the bar color when timer < cast time."] = "Change the bar color when timer < cast time."--]] 
--[[Translation missing --]]
--[[ L["Choose full time to see the full length of the timer, choose fixed time to see a set maximum time."] = "Choose full time to see the full length of the timer, choose fixed time to see a set maximum time."--]] 
--[[Translation missing --]]
--[[ L["Cooldown"] = "Cooldown"--]] 
--[[Translation missing --]]
--[[ L["Cooldown Spell"] = "Cooldown Spell"--]] 
--[[Translation missing --]]
--[[ L["Display the aura's icon on the button in place of the spell icon."] = "Display the aura's icon on the button in place of the spell icon."--]] 
--[[Translation missing --]]
--[[ L["Do not show timer for the aura applied by the spell on the action button."] = "Do not show timer for the aura applied by the spell on the action button."--]] 
--[[Translation missing --]]
--[[ L["Enable"] = "Enable"--]] 
--[[Translation missing --]]
--[[ L["Enable this bar"] = "Enable this bar"--]] 
--[[Translation missing --]]
--[[ L["Enables / disables the addon"] = "Enables / disables the addon"--]] 
--[[Translation missing --]]
--[[ L["First button on bar is action slot:"] = "First button on bar is action slot:"--]] 
--[[Translation missing --]]
--[[ L["Fixed time"] = "Fixed time"--]] 
--[[Translation missing --]]
--[[ L["Focus"] = "Focus"--]] 
--[[Translation missing --]]
--[[ L["Fonts to use for this bar"] = "Fonts to use for this bar"--]] 
--[[Translation missing --]]
--[[ L["Full time"] = "Full time"--]] 
--[[Translation missing --]]
--[[ L["Hide in pet battles"] = "Hide in pet battles"--]] 
--[[Translation missing --]]
--[[ L["Hide out of combat"] = "Hide out of combat"--]] 
--[[Translation missing --]]
--[[ L["Hide this bar during pet battles"] = "Hide this bar during pet battles"--]] 
--[[Translation missing --]]
--[[ L["Hide Tooltips"] = "Hide Tooltips"--]] 
--[[Translation missing --]]
--[[ L["Hide tooltips on buttons"] = "Hide tooltips on buttons"--]] 
--[[Translation missing --]]
--[[ L["Horizontal"] = "Horizontal"--]] 
--[[Translation missing --]]
--[[ L["If set, target will be the spell target as well as the target to monitor for the selected aura."] = "If set, target will be the spell target as well as the target to monitor for the selected aura."--]] 
--[[Translation missing --]]
--[[ L["If you would like to see the cooldown for a spell other than the one on the button, enter the name or spellId here."] = "If you would like to see the cooldown for a spell other than the one on the button, enter the name or spellId here."--]] 
--[[Translation missing --]]
--[[ L["Ignore Button Aura"] = "Ignore Button Aura"--]] 
--[[Translation missing --]]
--[[ L["Left/Bottom"] = "Left/Bottom"--]] 
--[[Translation missing --]]
--[[ L["Length of bar in pixels"] = "Length of bar in pixels"--]] 
--[[Translation missing --]]
--[[ L["Lock bar in place"] = "Lock bar in place"--]] 
--[[Translation missing --]]
--[[ L["Max time displayed on bar"] = "Max time displayed on bar"--]] 
--[[Translation missing --]]
--[[ L["Move this slider to change which action slots are shown on the bar."] = "Move this slider to change which action slots are shown on the bar."--]] 
--[[Translation missing --]]
--[[ L["None"] = "None"--]] 
--[[Translation missing --]]
--[[ L["Number of Buttons on bar"] = "Number of Buttons on bar"--]] 
--[[Translation missing --]]
--[[ L["Number of seconds to add to cast time (can be negative)."] = "Number of seconds to add to cast time (can be negative)."--]] 
--[[Translation missing --]]
--[[ L["Number of seconds to add to timer (can be negative)."] = "Number of seconds to add to timer (can be negative)."--]] 
--[[Translation missing --]]
--[[ L["Orientation"] = "Orientation"--]] 
--[[Translation missing --]]
--[[ L["Other Auras"] = "Other Auras"--]] 
--[[Translation missing --]]
--[[ L["Party/Raid Member"] = "Party/Raid Member"--]] 
--[[Translation missing --]]
--[[ L["Pet"] = "Pet"--]] 
--[[Translation missing --]]
--[[ L["Player"] = "Player"--]] 
--[[Translation missing --]]
--[[ L["Primary"] = "Primary"--]] 
--[[Translation missing --]]
--[[ L["Raid boss to target"] = "Raid boss to target"--]] 
--[[Translation missing --]]
--[[ L["Right/Top"] = "Right/Top"--]] 
--[[Translation missing --]]
--[[ L["Secondary"] = "Secondary"--]] 
--[[Translation missing --]]
--[[ L["Show Aura Icon"] = "Show Aura Icon"--]] 
--[[Translation missing --]]
--[[ L["Show background bar"] = "Show background bar"--]] 
--[[Translation missing --]]
--[[ L["Show debug messages"] = "Show debug messages"--]] 
--[[Translation missing --]]
--[[ L["Show estimate of next dot tick time."] = "Show estimate of next dot tick time."--]] 
--[[Translation missing --]]
--[[ L["Show others spells"] = "Show others spells"--]] 
--[[Translation missing --]]
--[[ L["Show this bar only when in combat"] = "Show this bar only when in combat"--]] 
--[[Translation missing --]]
--[[ L["Show this spell on the target even if someone else cast it."] = "Show this spell on the target even if someone else cast it."--]] 
--[[Translation missing --]]
--[[ L["Show tick prediction"] = "Show tick prediction"--]] 
--[[Translation missing --]]
--[[ L["Show trace messages"] = "Show trace messages"--]] 
--[[Translation missing --]]
--[[ L["ShowBackground"] = "ShowBackground"--]] 
--[[Translation missing --]]
--[[ L["ShowDebug"] = "ShowDebug"--]] 
--[[Translation missing --]]
--[[ L["ShowTrace"] = "ShowTrace"--]] 
--[[Translation missing --]]
--[[ L["Statusbar texture"] = "Statusbar texture"--]] 
--[[Translation missing --]]
--[[ L["Target"] = "Target"--]] 
--[[Translation missing --]]
--[[ L["Target to monitor for Auras."] = "Target to monitor for Auras."--]] 
--[[Translation missing --]]
--[[ L["Text Color"] = "Text Color"--]] 
--[[Translation missing --]]
--[[ L["Text color for timers"] = "Text color for timers"--]] 
--[[Translation missing --]]
--[[ L["Texture of the status bar"] = "Texture of the status bar"--]] 
--[[Translation missing --]]
--[[ L["The party / raid member to target"] = "The party / raid member to target"--]] 
--[[Translation missing --]]
--[[ L["The space between the buttons"] = "The space between the buttons"--]] 
--[[Translation missing --]]
--[[ L["Timer Location"] = "Timer Location"--]] 
--[[Translation missing --]]
--[[ L["Timer Type"] = "Timer Type"--]] 
--[[Translation missing --]]
--[[ L["Timers on Buttons"] = "Timers on Buttons"--]] 
--[[Translation missing --]]
--[[ L["Totem"] = "Totem"--]] 
--[[Translation missing --]]
--[[ L["Type"] = "Type"--]] 
--[[Translation missing --]]
--[[ L["Use as spell target"] = "Use as spell target"--]] 
--[[Translation missing --]]
--[[ L["Vehicle"] = "Vehicle"--]] 
--[[Translation missing --]]
--[[ L["Vertical"] = "Vertical"--]] 
--[[Translation missing --]]
--[[ L["Warn < cast time."] = "Warn < cast time."--]] 
--[[Translation missing --]]
--[[ L["Warning Bar Color"] = "Warning Bar Color"--]] 

