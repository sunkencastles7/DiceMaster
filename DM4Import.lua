-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Import methods for DiceMaster4 data
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.ImportDM4Saved()

	if Me.db.global.dm4Imported then return end
	
	Me.db.global.traitsList = {}
	
	for k, v in pairs( Me.db["profiles"] ) do
		if Me.db["profiles"][ k ]["traits"] then
			local traits = Me.db["profiles"][ k ]["traits"]
			for i = 1, #traits do
				if traits[ i ] then
					
					local trait = {
						["name"] = traits[ i ]["name"] or "Trait " .. i;
						["usage"] = traits[ i ]["usage"] or Me.TRAIT_USAGE_MODES[1];
						["range"] = traits[ i ]["range"] or Me.TRAIT_RANGE_MODES[1];
						["castTime"] = traits[ i ]["castTime"] or Me.TRAIT_CAST_TIME_MODES[1];
						["cooldown"] = traits[ i ]["cooldown"] or Me.TRAIT_COOLDOWN_MODES[1];
						["icon"] = traits[ i ]["icon"] or "Interface/Icons/inv_misc_questionmark";
						["desc"] = traits[ i ]["desc"] or "Type a description for your trait here.";
						["effects"] = {};
					}
					
					-- copy trait effects
					local OLD_EFFECT_TYPES = {
						"buffs", "removebuffs", "playsounds", "setdice", "visualeffects"
					}
					
					local NEW_EFFECT_TYPES = {
						"buff", "removebuff", "sound", "setdice", "effect"
					}
					
					for effect = 1, #OLD_EFFECT_TYPES do
						local effectType = OLD_EFFECT_TYPES[ effect ]
						if Me.db["profiles"][ k ][effectType] and Me.db["profiles"][ k ][effectType][ i ] then
							local effectData = Me.db["profiles"][ k ][effectType][ i ];
							trait["effects"][ NEW_EFFECT_TYPES[ effect ] ] = effectData;
						end
					end
					
					-- copy officer approval
					if Me.PermittedUse() then
						trait["approved"] = traits[ i ]["approved"] or false;
						trait["officers"] = traits[ i ]["officers"] or {};
					end
					
					tinsert( Me.db.global.traitsList, trait )
					
				end
			end
		end
	end	
	
	Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Thank you for downloading DiceMaster version 5.1.5 (Alpha)! Please refer to the official DiceMaster Discord Server for information and updates. Happy testing!", "SYSTEM");
	
	Me.db.global.dm4Imported = true
end