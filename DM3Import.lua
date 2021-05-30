-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Import methods for DiceMaster3 data
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.ImportDM3Saved()
	Me.Profile.buffsActive = {}
	if not Me.Profile.buffs then Me.Profile.buffs = {} end
	if not Me.Profile.removebuffs then Me.Profile.removebuffs = {} end
	if Me.db.char.dm3Imported then return end
	
	local traits = { DiceMaster_TraitOne, DiceMaster_TraitTwo, DiceMaster_TraitThree, DiceMaster_TraitFour, DiceMaster_TraitFive }
	
	local usages = {
		["1 Use"]   = "USE1";
		["2 Uses"]  = "USE2";
		["3 Uses"]  = "USE3";
		["Passive"] = "PASSIVE"; 
		-- x charges is handled in a special way
		--  especially since "Charges" isn't a constant
	}
	
	for i = 1, 5 do
		if traits[i] then
			
			local usage = usages[traits[i][2]]
			if not usage then
				usage = tostring(traits[i][2]):sub(1,1)
				if not tonumber(usage) then
					usage = "USE1"
				else
					-- X charges
					usage = "CHARGES"..usage
				end
			end
			
			Profile.traits[i].icon  = traits[i][4]
			Profile.traits[i].name  = traits[i][1]
			Profile.traits[i].usage = usage
			Profile.traits[i].desc  = traits[i][3]
			
		end
	end
	
	Profile.charges.enable = DiceMaster_Charges or Profile.charges.enable
	Profile.charges.name   = DiceMaster_ChargesName or Profile.charges.name
	Profile.charges.max    = DiceMaster_ChargesMax or Profile.charges.max
	
	if DiceMaster_ChargesColor then
		
		local r,g,b = string.match( DiceMaster_ChargesColor,"(%d+%.?%d*) (%d+%.?%d*) (%d+%.?%d*)" )
		
		Profile.charges.color = { tonumber(r), tonumber(g), tonumber(b) }
	end
	
	Me.db.char.dm3Imported = true
end

function Me.ImportDM4Saved()
	if Me.db.char.dm4Imported then 
		return
	end
	
	for i = 1, 5 do
		if Profile.traits[i] then
			Profile.traits[i]["effects"] = {
				["buff"] = Profile.buffs[i];
				["removebuff"] = Profile.removebuffs[i];
				["sound"] = Profile.playsounds[i];
				["setdice"] = Profile.setdice[i];
				["effect"] = Profile.visualeffects[i];
			};
		end
	end
	
	Me.db.char.dm4Imported = true
end
