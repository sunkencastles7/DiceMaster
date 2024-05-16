-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
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
	SLASH_DM1 = '/dm';
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
	if string.find( msg:lower(), "(%d*)[dD](%d+)([+-]?)(%d*)" ) then
		dice = msg:lower()
	end
	
	local rollType, modifier;
	for i = 1, #Profile.skills do
		if Profile.skills[i].name:lower() == msg:lower() then
			modifier = Me.GetModifiersFromSkillGUID( Profile.skills[i].guid, true );
			rollType = Profile.skills[i].name;
			break
		end
	end

	dice = Me.FormatDiceString( dice, modifier )
	
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
		
	elseif command == "show" then
	
		Me.ShowPanel( true )
		
	elseif command == "hide" then
	
		Me.ShowPanel( false )
		
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
	elseif command == "range" then
	
		rest = tonumber(rest) or 20;
		if rest then
			if DiceMasterRangeRadar:IsShown() then
				Me.RangeRadar_Hide()
			else
				Me.RangeRadar_Show( rest )
			end
		end
	elseif command == "whatsnew" then
		DiceMasterSplashFrame:Show();
	elseif command == "changelog" then
		DiceMasterChangeLog:Show()
	else
		Me.PrintMessage("- /dicemaster config", "SYSTEM");
		Me.PrintMessage("- /dicemaster whatsnew", "SYSTEM");
		Me.PrintMessage("- /dicemaster changelog", "SYSTEM");
		Me.PrintMessage("- /dicemaster (show || hide)", "SYSTEM");
		Me.PrintMessage("- /dicemaster showraidrolls (true || false)", "SYSTEM");
		Me.PrintMessage("- /dicemaster manager (show || hide)", "SYSTEM");
		Me.PrintMessage("- /dicemaster range (number)", "SYSTEM");
	end
end

-------------------------------------------------------------------------------
-- /dm
--
function SlashCmdList.DM(msg, editbox)
	SlashCmdList.DICEMASTER(msg, editbox)
end
