--[[
    ButtonTimers defaults:

    this file contains a database of default settings for various spells. If
    you have ideas for settings to be added to this file. Send a message to
    Misen on wow.curse.com or post on the ButtonTimers page on curse.com.

    The spells can be indexed either by spellName or by spellId

    available options to be set are:

        ["target"] = ABT_TARGET, ABT_FOCUS, ABT_PLAYER], ABT_PARTY, ABT_PET, ABT_VEHICLE
        ["timerType"] =  ABT_AURA, ABT_COOLDOWN, ABT_BOTH
        ["useAsSpellTarget"] = true or false
        ["barType"] = ABT_FULL, ABT_FIXED
        ["barTime"] = 20 -- number of seconds
        ["showOthers"] = true or false
        ["showTickPrediction"] = true or false
        ["auras"] = "" -- comma separated list of spells or spell-ids (for aura type only)
        ["showAuraIcon"] = true or false
        ["spell"] = nil -- spell name (for cooldown type only)
        ["colorChange"] = true or false
        ["timerColor"] = { r, g, b, a } -- red, green, blue, alpha
        ["textColor"] = { r, g, b, a } -- red, green, blue, alpha
        ["timerWarnColor"] = { r, g, b, a } -- red, green, blue, alpha
        ["timerAdjust] = 0 -- number of seconds (signed)
]]

ABT.ABT_Defaults = {}

--=========================================================================--
-- upvalues
--=========================================================================--
local ABT_Defaults, pairs = ABT.ABT_Defaults, pairs
local ABT_TARGET = 1
local ABT_PLAYER = 3
local ABT_AURA = 1
local ABT_COOLDOWN = 2
local ABT_BOTH = 4


-- lists of mutually exclusive raid buffs/debuffs that we may want to use for more than one spell
local armor_debuff = "Faerie Fire, Expose Armor, Sunder Armor, Tear Armor, Corrosive Spit"
local stamina_buff = "Power Word: Fortitude, Blood Pact, Commanding Shout, Qiraji Fortitude"
local str_agi_buff = "Horn of Winter, Strength of Earth, Battle Shout, Roar of Courage"
local crit_buff = "Leader of the Pack, Honor Among Thieves, Elemental Oath, Rampage, Furious Howl, Terrifying Roar"
local damage_done_buff = " Arcane Tactics, Communion, Ferocious Inspiration"
local spell_haste_buff = "Moonkin Aura, Mind Quickening, Wrath of Air Totem"
local spell_power_buff = "Totemic Wrath, Demonic Pact, Arcane Brilliance, Dalaran Brilliance, Flame Tongue Totem"
local weapon_speed_buff = "Improved Icy Talons, Windfury Totem, Hunting Party"
local atk_pwr_buff = "Abomination's Might, Blessing of Might, Unleashed Rage, Trueshot Aura"
local atk_pwr_debuffs = "Scarlet Fever, Demoralizing Roar, Vindication, Curse of Weakness, Demoralizing Shout, Demoralizing Screech"
local atk_spd_debuffs = "Frost Fever, Infected Wounds, Judgements of the Just, Earth Shock, Thunder Clap, Tailspin, Dust Cloud"
local major_haste_buff = "Time Warp, Bloodlust, Heroism, Ancient Hysteria"
local stats_and_resists_buff = "Mark of the Wild, Blessing of Kings, Embrace of the Shale Spider"
local physical_damage_taken_debuff = "Brittle Bones, Savage Combat, Blood Frenzy, Ravage, Acid Spit"
local spell_damage_taken_debuff = "Ebon Plague, Earth and Moon, Master Poisoner, Curse of Elements, Jinx: Curse of the Elements, Fire Breath, Lightning Breath"
local spell_crit_taken_debuff = "Critical Mass, Shadow Mastery"
local spell_speed_debuff = "Necrotic Strike, Slow, Mind-Numbing Poison, Curse of Tongues, Spore Cloud, Lava Breath"
local healing_received_debuff = "Permafrost, Mind Trauma, Wound Poison, Legion Strike, Mortal Strike, Furious Attacks, Widow Venom, Monstrous Bite"
local physical_damage_taken_buff = "Inspiriation, Ancestral Fortitude"
local armor_buff = "Devotion Aura, Stoneskin"
local spell_resistance = "Resistance Aura, Shadow Protection, Elemental Resistance, Aspect of the Wild"
local spell_pushback_reduction = "Concentration Aura, Tranquil Mind"
local bleed_damage_debuff = "Mangle, Hemorrhage, Trauma, Gore, Tendon Rip, Stampede"
local max_mana_buff = "Arcane Brilliance, Dalaran Brilliance, Fel Intelligence"
local mp5_buff = "Blessing of Might, Mana Spring, Fel Intelligence"
local replenishment = "Revitalize, Enduring Winter, Communion, Vampiric Touch, Soul Leech"
local mana_restoration = "Innervate, Hymn of Hope, Mana Tide"
local reflective_damage_buff = "Thorns, Retribution Aura"

-- this default is only applied if a specific default exists below. This just gives a baseline 
-- of sorts so you don't need to fill every field in when making your default, only the fields
-- that differ from this definition.
ABT_Defaults["overall"] = {
    ["target"]=ABT_TARGET,
    ["timerType"] = ABT_AURA,
    ["showOthers"]=false,
    ["showAuraIcon"]=false,
    ["auras"]="",
    ["useAsSpellTarget"] = false,
    ["showTickPrediction"] = true,
    ["spell"] = nil,
    ["colorChange"] = true,
    ["timerAdjust"] = 0,
}

function ABT:CreateDefault (prototype, ...)
    local newDefault = {}
    if prototype then
        for f, v in pairs(prototype) do
            newDefault[f] = v
        end
    end
    if ... then
        for f, v in pairs(...) do
            newDefault[f] = v
        end
    end
    return newDefault
end

-- generic types, used to build defaults
local cooldown = { ["timerType"] = ABT_COOLDOWN }
local debuff = { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA }
local raid_debuff =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true }

-- General, make a macro with the name to use these
--ABT_Defaults["BleedDebuff"] = { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]=bleed_damage_debuff }
ABT_Defaults["BleedDebuff"] = ABT:CreateDefault (raid_debuff, { ["auras"]=bleed_damage_debuff} )
ABT_Defaults["HealDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= healing_received_debuff}
ABT_Defaults["ArmorDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= armor_debuff}
ABT_Defaults["AtkPwrDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= atk_pwr_debuffs}
--ABT_Defaults["AtkSpeedDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= atk_spd_debuffs}
ABT_Defaults["AtkSpeedDebuff"] =  ABT:CreateDefault (raid_debuff, { ["auras"]= atk_spd_debuffs} )
ABT_Defaults["DamageTakenDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= physical_damage_taken_debuff}
ABT_Defaults["SpellDamageTakenDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= spell_damage_taken_debuff}
ABT_Defaults["SpellCritTakenDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= spell_crit_taken_debuff}
ABT_Defaults["SpellSpeedDebuff"] =  { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]= spell_speed_debuff}

-- Death Knight
ABT_Defaults["Icy Touch"] = { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["auras"]="Frost Fever" }
ABT_Defaults["Plague Strike"] = { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["auras"]="Blood Plague" }
ABT_Defaults["Outbreak"] = { ["target"]=ABT_TARGET, ["timerType"] = ABT_BOTH, ["auras"]="Frost Fever, Blood Plague" }
ABT_Defaults["Bone Shield"] = { ["target"]=ABT_PLAYER, ["timerType"] = ABT_BOTH }
ABT_Defaults["Death and Decay"] = cooldown

-- Druid
-- Hunter
-- Mage
-- Paladin
-- Priest
-- Rogue
-- Shaman
-- Warlock

-- Warrior
ABT_Defaults["Revenge"] = cooldown
ABT_Defaults["Shield Slam"] = cooldown
ABT_Defaults["Charge"] = cooldown
ABT_Defaults["Taunt"] = cooldown
ABT_Defaults["Heroic Strike"] = cooldown
ABT_Defaults["Shield Bash"] = { ["timerType"] = ABT_BOTH, ["auras"]="Gag Order"  }
ABT_Defaults["Pummel"] = cooldown
ABT_Defaults["Cleave"] = cooldown
ABT_Defaults["Berserker Rage"] = cooldown
ABT_Defaults["Heroic Throw"] = { ["timerType"] = ABT_BOTH, ["auras"]="Gag Order" }
ABT_Defaults["Heroic Leap"] = cooldown
ABT_Defaults["Recklessness"] = cooldown
ABT_Defaults["Spell Reflection"] = { ["target"]=ABT_PLAYER, ["timerType"] = ABT_BOTH }
ABT_Defaults["Shield Block"] = { ["target"]=ABT_PLAYER, ["timerType"] = ABT_BOTH }
ABT_Defaults["Enraged Regeneration"] = cooldown
ABT_Defaults["Inner Rage"] = cooldown
ABT_Defaults["Rend"] = debuff
ABT_Defaults["Hamstring"] = debuff
ABT_Defaults["Disarm"] = cooldown
ABT_Defaults["Intimidating Shout"] = cooldown
ABT_Defaults["Intervene"] = cooldown
ABT_Defaults["Shattering Throw"] = cooldown
ABT_Defaults["Colossus Smash"] = cooldown
ABT_Defaults["Devastate"] = { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]=armor_debuff } -- devastate
ABT_Defaults["Sunder Armor"]= { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]=armor_debuff } -- sunder armor
ABT_Defaults["Battle Shout"]= { ["target"]=ABT_PLAYER, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]=str_agi_buff } -- battle shout
ABT_Defaults["Commanding Shout"]= { ["target"]=ABT_PLAYER, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]=stamina_buff } -- commanding shout
ABT_Defaults["Demoralizing Shout"]= { ["target"]=ABT_TARGET, ["timerType"] = ABT_AURA, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]=atk_pwr_debuff } -- demoralizing shout
ABT_Defaults["Thunder Clap"]= { ["target"]=ABT_TARGET, ["timerType"] = ABT_BOTH, ["showOthers"]=true, ["showAuraIcon"]=true, ["auras"]=atk_spd_debuff } -- thunder clap
