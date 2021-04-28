-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Chat commands.
--

local Me = DiceMaster4
local Profile = Me.Profile

-------------------------------------------------------------------------------
function Me.Console_Init()
	SLASH_DICE1       = '/dice';
	SLASH_DICEMASTER1 = '/dicemaster';
end

-------------------------------------------------------------------------------
-- /dice
--
function SlashCmdList.DICE( msg, editBox )
	
	if msg == "" then
		Me.PrintMessage("/dice (rollType or XDY[+/-]Z)", "SYSTEM");
		Me.PrintMessage("- X is how many dice to roll.", "SYSTEM");
		Me.PrintMessage("- Y is how many sides those dice have.", "SYSTEM");
		Me.PrintMessage("- Z is how much you add/subtract from the total after adding up all the dice.", "SYSTEM");
		return
	end
	
	local dice = DiceMasterPanelDice:GetText()
	local stat = nil
	local modifier = Me.GetModifierFromStatistic( msg:lower() )
	dice = Me.FormatDiceString( dice, modifier )
	
	local rollType
	for i = 1, #Me.Profile.stats do
		if Me.Profile.stats[i].name:lower() == msg:lower() then
			rollType = Me.Profile.stats[i].name;
			break
		end
	end
	
	Me.Roll( dice, rollType ) 
end 

-------------------------------------------------------------------------------
-- /dicemaster
--
function SlashCmdList.DICEMASTER(msg, editbox)
	local command, rest = msg:match("^(%S*)%s*(.-)$");
	command = command:lower()
	
	
	if command == "config" then
	
		Me.OpenConfig()
		
	elseif command == "scale" then
	
		rest = tonumber(rest)
		if rest then
			rest = Me.Clamp( rest, 0.25, 10 )
			Me.db.char.uiScale = rest
			Me.ApplyUiScale() 
		end
		
	elseif command == "show" then
	
		Me.ShowPanel( true )
		
	elseif command == "hide" then
	
		Me.ShowPanel( false )
		
	elseif command == "lock" then
	
		Me.LockFrames()
		
	elseif command == "unlock" then
	
		Me.UnlockFrames()
		
	elseif command == "charges" then
	
		if rest:lower() == "show" then
			Profile.charges.enable = true;
			Me.OnChargesChanged()
		elseif rest:lower() == "hide" then
			Profile.charges.enable = false;
			Me.OnChargesChanged()
		end
		
	elseif command == "chargesname" and rest ~= "" then
	
		Profile.charges.name = rest
		Me.OnChargesChanged()
		
		Me.TraitEditor_Refresh()
		
	elseif command == "maxcharges" then
		
		rest = tonumber(rest)
		if not rest or rest < 1 or rest > 8 then return end
		
		Profile.charges.max = rest
		Profile.charges.count = math.min( Profile.charges.count, Profile.charges.max )
		Me.OnChargesChanged()
		 
	elseif command == "chargescolor" then
	
		local r, g, b = string.match( rest, "(%d+%.?%d*)%s+(%d+%.?%d*)%s+(%d+%.?%d*)")
		r = tonumber(r)
		g = tonumber(g)
		b = tonumber(b)
		
		if r and g and b then
			Profile.charges.color = { r, g, b }
			Me.OnChargesChanged()
		end
	elseif command == "showraidrolls" then
		if rest:lower() == "true" then
			Me.db.char.showRaidRolls = true
		else
			Me.db.char.showRaidRolls = false
		end
	elseif command == "manager" then
	
		if rest:lower() == "show" then
			Me.db.global.hideTracker = true
			DiceMasterRollFrame:Show()
		elseif rest:lower() == "hide" then
			Me.db.global.hideTracker = false
			DiceMasterRollFrame:Hide()
		elseif DiceMasterRollFrame:IsShown() then
			Me.db.global.hideTracker = false
			DiceMasterRollFrame:Hide()
		else
			Me.db.global.hideTracker = true
			DiceMasterRollFrame:Show()
		end
	elseif command == "managerscale" then
	
		rest = tonumber(rest)
		if rest then
			rest = Me.Clamp( rest, 0.25, 10 )
			Me.db.char.trackerScale = rest
			Me.ApplyUiScale() 
		end
	elseif command == "progressbar" then
	
		if rest:lower() == "show" then
			Me.db.profile.morale.enable = true; 
			Me.RefreshMoraleFrame() 
		elseif rest:lower() == "hide" then
			Me.db.profile.morale.enable = false; 
			Me.RefreshMoraleFrame() 
		end
		Me.ApplyUiScale() 
	elseif command == "unitframes" then
		
		if not IsAddOnLoaded("DiceMaster_UnitFrames") then
			Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t DiceMaster Unit Frames module not found. Enable the module from your AddOns list.", "SYSTEM")
			return
		end
		
		if rest:lower() == "show" then
			Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Unit Frames enabled.", "SYSTEM")
			Me.ShowUnitPanel( true )
		elseif rest:lower() == "hide" then
			Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Unit Frames disabled.", "SYSTEM")
			Me.ShowUnitPanel( false )
		end
	elseif command == "range" then
	
		rest = tonumber(rest) or 20;
		if rest then
			if DiceMasterRangeRadar:IsShown() then
				Me.RangeRadar_Hide()
			else
				Me.RangeRadar_Show( rest )
			end
		end
	else
		Me.PrintMessage("- /dicemaster config", "SYSTEM");
		Me.PrintMessage("- /dicemaster scale (number)", "SYSTEM");
		Me.PrintMessage("- /dicemaster (show || hide)", "SYSTEM");
		Me.PrintMessage("- /dicemaster charges (show || hide)", "SYSTEM");
		Me.PrintMessage("- /dicemaster chargesname (name)", "SYSTEM");
		Me.PrintMessage("- /dicemaster maxcharges (number)", "SYSTEM");
		Me.PrintMessage("- /dicemaster chargescolor (r g b)", "SYSTEM");
		Me.PrintMessage("- /dicemaster showraidrolls (true || false)", "SYSTEM");
		Me.PrintMessage("- /dicemaster manager (show || hide)", "SYSTEM");
		Me.PrintMessage("- /dicemaster managerscale (number)", "SYSTEM");
		Me.PrintMessage("- /dicemaster progressbar (show || hide)", "SYSTEM");
		Me.PrintMessage("- /dicemaster range (number)", "SYSTEM");
		if IsAddOnLoaded("DiceMaster_UnitFrames") then
			Me.PrintMessage("- /dicemaster unitframes (show || hide)", "SYSTEM");
		end
		Me.PrintMessage("- /dicemaster (lock || unlock)", "SYSTEM");
	end
end 
