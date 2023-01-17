-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Roll banners.
--

local Me = DiceMaster4
local Profile = Me.Profile

local options = {
	{
		name = "Combat Begins",
		description = "Combat has officially begun.",
		options = {
			{ icon = "Interface/Icons/VAS_NameChange", name = "Hold Emotes", desc = "Hold posts until the Emote Phase.", details = "Please hold off from posting any emotes at this time. You can still engage in brief dialogue, but save any descriptive emotes for the next Emote Phase, or when combat ends.", },
		},
	},
	{
		name = "Action Phase",
		description = "Choose one of the following:",
		options = {
			{ icon = "Interface/Icons/Garrison_Building_SparringArena", name = "Combat Action", desc = "Attempt a Combat Action.", details = "A Combat Action represents your character's attempt to deal or defend against damage on your turn.|n|nExample: Melee Attack, Ranged Attack, Spell Attack" },
			{ icon = "Interface/Icons/achievement_guild_doctorisin", name = "Skill", desc = "Attempt to use a Skill.", details = "Skills represent some of the most basic, fundamental abilities your character possesses, and most character non-combat actions can be categorised into at least one of the default Skills.|n|nExample: Bluff, Healing, Perception, Spellcraft" },
			{ icon = "Interface/Icons/achievement_guildperk_quick and dead", name = "Trait", desc = "Use an active-use Trait.", details = "Traits represent your character's strengths, weaknesses, and unique abilities. You can choose to use one of your active-use traits this turn.", },
			{ icon = "Interface/Icons/achievement_guildperk_fasttrack_rank2", name = "Move", desc = "Move to another location.", details = "Movement is restricted during combat. You can use your turn to move up to 20 yards in any direction, or reposition yourself.", },
			{ icon = "Interface/Icons/ACHIEVEMENT_GUILDPERK_EVERYONES A HERO", name = "Stand", desc = "Stand still and forego your turn.", details = "You can choose to forfeit your action this turn and stand still.", },
			{ icon = "Interface/Icons/achievement_guildperk_reinforce", name = "Protect", desc = "Grant you or an ally |cFF00FF00+3|r Defence.", details = "You can use your turn to defend yourself or another character, granting the chosen target |cFF00FF00+3|r to their next Defence roll.", },
		},
	},
	{
		name = "Reaction Phase",
		description = "You may be prompted to roll for one of the following:",
		options = {
			{ icon = "Interface/Icons/Garrison_Building_SparringArena", name = "Combat Action", desc = "Attempt a Combat Action.", details = "A Combat Action represents your character's attempt to deal or defend against damage on your turn.|n|nExample: Defence, Spell Defence" },
			{ icon = "Interface/Icons/achievement_guildperk_massresurrection", name = "Saving Throw", desc = "Attempt a Saving Throw.", details = "Generally, when your character is subject to an unusual or magical attack, you are allowed to roll a Saving Throw to avoid or reduce the effect.|n|nExample: Fortitude Save, Reflex Save, Will Save", },
		},
	},
	{
		name = "Emote Phase",
		description = "You may now post your emote in chat.",
		options = {
			{ icon = "Interface/Icons/vas_guildnamechange", name = "Emote", desc = "Post your emote in chat.", details = "You can now post a descriptive emote of your character's actions from the last turn in party or raid chat.", },
		},
	},
	{
		name = "Combat Ends",
		description = "Combat has officially ended.",
		options = {
			{ icon = "Interface/Icons/VAS_NameChange", name = "Hold Emotes", desc = "Continue holding posts for now.", details = "Please hold off from posting any emotes at this time. You can still engage in brief dialogue, but save any descriptive emotes for later.", },
			{ icon = "Interface/Icons/vas_guildnamechange", name = "Emote", desc = "You may resume posting in chat.", details = "You can now post a descriptive emote of your character's actions from the last turn in party or raid chat.", },
		},
	},
	{
		name = "Custom",
		description = "Banner Subtitle",
	},
}

local TIMER_INTERVALS = {
	{name = "1 Minute", time = 60},
	{name = "2 Minutes", time = 120},
	{name = "3 Minutes", time = 180},
	{name = "5 Minutes", time = 300},
	{name = "10 Minutes", time = 600},
	{name = "15 Minutes", time = 900},
	{name = "30 Minutes", time = 1800},
	{name = "45 Minutes", time = 2700},
	{name = "1 Hour", time = 3600},
}

local CURRENT_COMBAT_ROUND = 1;

function Me.RollBannerDropDown_OnClick(self, arg1)
	if arg1 then
		UIDropDownMenu_SetSelectedID(DiceMasterBannerPromptDialog.OptionsDropdown, arg1)
		UIDropDownMenu_SetText(DiceMasterBannerPromptDialog.OptionsDropdown, options[arg1].name)
		
		if options[arg1].name == "Custom" then
			DiceMasterBannerPromptDialog.BannerTitle:SetText("Banner Title")
		else
			DiceMasterBannerPromptDialog.BannerTitle:SetText(options[arg1].name)
		end
		
		DiceMasterBannerPromptDialog.BannerSubtitle:SetText(options[arg1].description)
		DiceMasterBannerPromptDialog.Desc2:SetText("")
		
		-- Update the checkboxes
		local checkboxes = DiceMasterBannerPromptDialog.checkboxes
		for i = 1, #checkboxes do
			checkboxes[i]:SetChecked( false )
			checkboxes[i]:Hide()
			DiceMasterBannerPromptDialog:SetHeight( 220 )
		end
		
		if options[arg1].options then
			DiceMasterBannerPromptDialog.Desc2:SetText("Select which options are available to players:")
			local checkOptions = options[arg1].options
			for i = 1, #checkOptions do
				checkboxes[i]:Show()
				_G["DiceMasterBannerPromptDialogCheckbox"..i.."Text"]:SetText( "|T" .. checkOptions[i].icon .. ":16|t |cFFFFD100" .. checkOptions[i].name .. ":|r " ..  checkOptions[i].desc .. "|r")
				DiceMasterBannerPromptDialog:SetHeight( 250 + 20*i )
			end
		end
		
		if arg1 == 1 or arg1 == 5 then
			DiceMasterBannerPromptDialog.AdvanceTurn:Disable()
			DiceMasterBannerPromptDialog.AdvanceTurn:SetChecked( false )
			_G["DiceMasterBannerPromptDialogAdvanceTurnText"]:SetTextColor( 0.5, 0.5, 0.5 )
			DiceMasterBannerPromptDialog.TurnTimer:Disable()
			DiceMasterBannerPromptDialog.TurnTimer:SetChecked( false )
			_G["DiceMasterBannerPromptDialogTurnTimerText"]:SetTextColor( 0.5, 0.5, 0.5 )
		else
			DiceMasterBannerPromptDialog.AdvanceTurn:Enable()
			_G["DiceMasterBannerPromptDialogAdvanceTurnText"]:SetTextColor( 1, 1, 1 )
			DiceMasterBannerPromptDialog.TurnTimer:Enable()
			_G["DiceMasterBannerPromptDialogTurnTimerText"]:SetTextColor( 1, 1, 1 )
		end
	end
end

function Me.RollBannerDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	
	info.text = "|cFFffd100Combat Phases:"
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info, level)
	info.notClickable = false;
	info.disabled = false;
	
	for i = 1, #options do
	   info.text = options[i].name;
	   info.arg1 = i;
	   info.notCheckable = true;
	   info.func = Me.RollBannerDropDown_OnClick;
	   UIDropDownMenu_AddButton(info, level)
	end
end

function Me.RollBannerTimerDropDown_OnClick(self, arg1)
	if arg1 then
		UIDropDownMenu_SetSelectedID( DiceMasterBannerPromptDialog.Timer, arg1 )
		UIDropDownMenu_SetText( DiceMasterBannerPromptDialog.Timer, TIMER_INTERVALS[ arg1 ].name )
	end
end

function Me.RollBannerTimerDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.notClickable = false;
	info.disabled = false;
	
	for i = 1, #TIMER_INTERVALS do
	   info.text = TIMER_INTERVALS[i].name;
	   info.arg1 = i;
	   info.notCheckable = true;
	   info.func = Me.RollBannerTimerDropDown_OnClick;
	   UIDropDownMenu_AddButton(info, level)
	end
end

function Me.RollBanner_OnLoad( self )
	self:SetScale( 0.8 )

	for i = 2, 6 do
		local button = CreateFrame("Frame", "DiceMasterRollBannerOptionFrame"..i, self, "DiceMasterRollBannerOptionFrameTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterRollBannerOptionFrame"..(i-1)], "BOTTOM", 0, -2);
		button:SetScript( "OnShow", function( self ) self.Anim:Play() end)
	end	
	
end

function Me.RollBanner_UpdateOptions( id, data )

	if not id or not data then
		DiceMasterRollBanner:SetHeight( 180 )
		return
	end
	
	for i = 1, 6 do
		local button = _G[ "DiceMasterRollBannerOptionFrame" .. i ]
		
		if data[i] then
			button.Icon:SetTexture( data[i].icon )
			button.Title:SetText( data[i].name )
			button.Description:SetText( data[i].desc )
			button.IconHitBox.details = data[i].details
			button:Show()
			
			DiceMasterRollBanner:SetHeight( 180 + 45*i )
		else
			button.Icon:SetTexture( nil )
			button.Title:SetText( "" )
			button.Description:SetText( "" )
			button.IconHitBox.details = nil
			button:Hide()
		end
	end
	
end

function Me.RollBanner_OnMouseEnter( self, button )
	
	DiceMasterRollBanner.MouseIsOver = true;
	
	if DiceMasterRollBanner.AnimOut:IsPlaying() then
		DiceMasterRollBanner.AnimOut:Stop()
	end
	
end

function Me.RollBanner_OnMouseLeave( self, button )
	
	DiceMasterRollBanner.MouseIsOver = false;
	
	if DiceMasterRollBanner:IsShown() and not ( DiceMasterRollBanner.AnimIn:IsPlaying() or DiceMasterRollBanner.AnimOut:IsPlaying() ) then
		DiceMasterRollBanner.AnimOut:Play()
	end
	
end

function Me.RollBanner_SendBanner()
	
	if DiceMasterRollBanner:IsShown() then
		UIErrorsFrame:AddMessage( "A banner is already playing.", 1.0, 0.0, 0.0 );
		return
	end
	
	if DiceMasterBannerPromptDialog.BannerTitle:GetText() == "" then
		UIErrorsFrame:AddMessage( "Enter a title for this banner.", 1.0, 0.0, 0.0 );
		return
	end
	
	local type = UIDropDownMenu_GetSelectedID(DiceMasterBannerPromptDialog.OptionsDropdown)
	local data = {}
	
	-- Collect options data.
	if type and options[type].options then
		local checkboxes = DiceMasterBannerPromptDialog.checkboxes
		local checkOptions = options[type].options
		for i = 1, 6 do
			if checkboxes[i]:IsShown() and checkboxes[i]:GetChecked() then
				tinsert( data, checkOptions[i] )
			end
		end
	end
	
	-- Collect Turn Tracker data.
	local turnHasChanged = false;
	
	if DiceMasterBannerPromptDialog.AdvanceTurn:GetChecked() then
		CURRENT_COMBAT_ROUND = CURRENT_COMBAT_ROUND + 1;
		turnHasChanged = true;
	end
	
	if type == 5 then
		CURRENT_COMBAT_ROUND = 1;
		turnHasChanged = true;
	end
	
	local timer = DiceMasterBannerPromptDialog.TurnTimer:GetChecked()
	if timer then
		timer = TIMER_INTERVALS[ UIDropDownMenu_GetSelectedID( DiceMasterBannerPromptDialog.Timer ) ].time
	end
	
	local channel = "RAID";
	local name = nil;
	
	if DiceMasterBannerPromptDialog.target ~= "RAID" then
		channel = "WHISPER";
		name = DiceMasterBannerPromptDialog.target
	end
	
	if GetNumGroupMembers() == 0 then
		channel = "WHISPER";
		name = UnitName("player")
	end

	local msg = Me:Serialize( "BANNER", {
		na = tostring( UnitName("player") );
		id = tonumber( type );
		ti = tostring( DiceMasterBannerPromptDialog.BannerTitle:GetText() );
		su = tostring( DiceMasterBannerPromptDialog.BannerSubtitle:GetText() );
		op = data;
		cr = CURRENT_COMBAT_ROUND;
		tc = turnHasChanged;
		tm = timer;
	})
	Me:SendCommMessage( "DCM4", msg, channel, name or nil, "ALERT" )
end

function Me.TurnTracker_StartTimer()
	if DiceMasterTurnTracker.Timer then
		DiceMasterTurnTracker.Timer:Cancel()
	end
	
	DiceMasterTurnTracker.Timer = C_Timer.NewTicker( 1 , function()
		local statusBar = DiceMasterTurnTracker.Bar
		local timeLeft = DiceMasterTurnTracker.TimeLeft
		if statusBar:GetValue() > 0 then
			statusBar:SetValue( statusBar:GetValue() - 1 )
			timeLeft:SetText( date("%M:%S", statusBar:GetValue()) )
			
			if statusBar:GetValue() == 0 then
				PlaySound(25478, nil, false)
			elseif statusBar:GetValue() <= 10 then
				timeLeft:SetTextColor( 1, 0, 0 )
				statusBar:SetStatusBarColor( 1, 0, 0 )
				PlaySound(25477, nil, false)
			else
				timeLeft:SetTextColor( 1, 1, 1 )
				statusBar:SetStatusBarColor( 0.26, 0.42, 1 )
			end
		else
			DiceMasterTurnTracker.Timer:Cancel()
		end
	end)
end

---------------------------------------------------------------------------
-- Received a banner request.
--  na = name							string
--  id = index							number
--	ti = title							string
--  su = subtitle						string
--  op = options						table
--  cr = current combat round			number
--  tc = turn has changed				boolean
--  tm = timer							number

function Me.RollBanner_OnBanner( data, dist, sender )	
	-- Only the party leader can send us these.
	if not UnitIsGroupLeader(sender, 1) and not Me.IsLeader( false ) then return end
 
	-- sanitize message
	if not data.na or not data.id or not data.ti then
	   
		return
	end
	
	-- The turn has changed, so we need to update any turn-based buffs.
	if data.tc and #Profile.buffsActive > 0 then
		for i = 1, #Profile.buffsActive do
			local buff = Profile.buffsActive[i]
			if buff.turns and buff.turns > 0 then
				buff.turns = buff.turns - 1
				if buff.turns <= 0 then
					tremove( Profile.buffsActive, i )
				end
			end		
		end
		Me.SkillFrame_UpdateSkills()
		Me.BumpSerial( Me.db.char, "statusSerial" )
		Me.BuffFrame_Update()
		Me.Inspect_ShareStatusWithParty()
		Me.Inspect_SendSkills( "RAID" )
	end
	
	if data.tc then
		local traits = DiceMasterChargesFrame.traits
		for i=1,#traits do
			local cooldown = traits[i].cooldown.text:GetText()
			if cooldown and cooldown:match("%dT") then
				cooldown = cooldown:gsub( "T", "" )
				cooldown = cooldown - 1
				if cooldown == 0 then
					traits[i].cooldown.text:SetText("")
					traits[i].cooldown.text:Hide()
					traits[i].cooldown:SetCooldown( 0, 0 )
				else
					traits[i].cooldown.text:SetText( cooldown .. "T" )
					traits[i].cooldown.text:Show()
				end
			end
		end
	end
	
	if not DiceMasterRollBanner:IsShown() then
		
		-- if banners are off, just show the message.
		if not Me.db.global.enableRoundBanners then
			Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t "..data.ti , "RAID")
			return
		end
		
		-- Look for punctuation at the end of the string
		if not data.ti:match("%p$") then
			data.ti = data.ti.."!"
		end
		
		-- Combat Turn Tracker
		if Me.db.global.enableTurnTracker then
			if UnitFactionGroup("player") == "Alliance" then
				DiceMasterTurnTracker.BG:SetAtlas("AllianceScenario-TrackerHeader", true)
			elseif UnitFactionGroup("player") == "Horde" then
				DiceMasterTurnTracker.BG:SetAtlas("HordeScenario-TrackerHeader", true)
			end
			-- if this is a "Combat Ends" phase, hide the frame.
			if data.id == 5 then
				DiceMasterTurnTracker:Hide()
			else
				DiceMasterTurnTracker:Show()
				DiceMasterTurnTracker.TurnTitle:SetText( data.ti )
				Me.SetupTooltip( DiceMasterTurnTracker, nil, "|cFFffd100"..data.ti )
				
				if data.cr then
					DiceMasterTurnTracker.TurnTotal:SetText( "Round " .. data.cr )
				end
				
				if data.tm then
					DiceMasterTurnTracker.TimeLeftLabel:Show()
					DiceMasterTurnTracker.TimeLeft:SetText( date("%M:%S", data.tm) )
					DiceMasterTurnTracker.TimeLeftLabel:Show()
					DiceMasterTurnTracker.TimeLeft:Show()
					DiceMasterTurnTracker.TimeLeft:SetTextColor( 1, 1, 1 )
					DiceMasterTurnTracker.Bar:Show()
					DiceMasterTurnTracker.Bar:SetMinMaxValues( 0, data.tm )
					DiceMasterTurnTracker.Bar:SetValue( data.tm )
					DiceMasterTurnTracker.Bar:SetStatusBarColor( 0.26, 0.42, 1 )
					Me.TurnTracker_StartTimer()
				else
					DiceMasterTurnTracker.TimeLeftLabel:Hide()
					DiceMasterTurnTracker.TimeLeft:Hide()
					DiceMasterTurnTracker.Bar:Hide()
				end
				
			end
		elseif DiceMasterTurnTracker:IsShown() then
			DiceMasterTurnTracker:Hide()
		end
		
		-- Set the banner skin.
		if not Me.PermittedUse() then
			if UnitFactionGroup("player") == "Alliance" then
				DiceMasterRollBanner.BannerTop:SetTexture("Interface/AddOns/DiceMaster/Texture/alliance-banner")
				DiceMasterRollBanner.BannerTopGlow:SetTexture("Interface/AddOns/DiceMaster/Texture/alliance-banner")
				DiceMasterRollBanner.BannerBottom:SetTexture("Interface/AddOns/DiceMaster/Texture/alliance-banner")
				DiceMasterRollBanner.BannerBottomGlow:SetTexture("Interface/AddOns/DiceMaster/Texture/alliance-banner")
				DiceMasterRollBanner.SkullCircle:SetTexture("Interface/AddOns/DiceMaster/Texture/alliance-banner")
				DiceMasterRollBanner.RedFlash:SetTexture("Interface/AddOns/DiceMaster/Texture/alliance-banner")
				DiceMasterRollBanner.Title:SetTextColor( 1, 0.82, 0 )
			elseif UnitFactionGroup("player") == "Horde" then
				DiceMasterRollBanner.BannerTop:SetTexture("Interface/AddOns/DiceMaster/Texture/horde-banner")
				DiceMasterRollBanner.BannerTopGlow:SetTexture("Interface/AddOns/DiceMaster/Texture/horde-banner")
				DiceMasterRollBanner.BannerBottom:SetTexture("Interface/AddOns/DiceMaster/Texture/horde-banner")
				DiceMasterRollBanner.BannerBottomGlow:SetTexture("Interface/AddOns/DiceMaster/Texture/horde-banner")
				DiceMasterRollBanner.SkullCircle:SetTexture("Interface/AddOns/DiceMaster/Texture/horde-banner")
				DiceMasterRollBanner.RedFlash:SetTexture("Interface/AddOns/DiceMaster/Texture/horde-banner")
				DiceMasterRollBanner.Title:SetTextColor( 1, 0, 0 )
			end
		end
		
		DiceMasterRollBanner.Title:ClearAllPoints()
		DiceMasterRollBanner.Title:SetPoint( "TOP", DiceMasterRollBanner.BannerTop, 0, -47 )
		DiceMasterRollBanner.SubTitle:ClearAllPoints()
		DiceMasterRollBanner.SubTitle:SetPoint( "TOP", DiceMasterRollBanner.Title, "BOTTOM", 0, 0 )
		
		DiceMasterRollBanner.Title:SetText( data.ti )
		DiceMasterRollBanner.SubTitle:SetText( data.su )
		Me.RollBanner_UpdateOptions( data.id, data.op )
		
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t "..data.ti , "RAID")
		
		DiceMasterRollBanner.AnimIn:Play()
		
		local timer = C_Timer.NewTimer(8, function()
			if DiceMasterRollBanner:IsShown() and not DiceMasterRollBanner.MouseIsOver then
				Me.RollBanner_OnMouseLeave( self, button )
			end
		end)
		
	end
end