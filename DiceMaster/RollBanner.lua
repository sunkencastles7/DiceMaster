-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Roll banners.
--

local Me = DiceMaster4
local Profile = Me.Profile

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

local collectFunc = function()
	local banner = {};
	banner.name = DiceMasterBannerPromptDialog.BannerTitle:GetText();
	banner.desc = DiceMasterBannerPromptDialog.BannerSubtitle:GetText();
	banner.advanceTurn = DiceMasterBannerPromptDialog.AdvanceTurn:GetChecked();
	if DiceMasterBannerPromptDialog.TurnTimer:GetChecked() then
		banner.timer = TIMER_INTERVALS[ UIDropDownMenu_GetSelectedID( DiceMasterBannerPromptDialog.Timer ) ].time;
	end
	banner.options = {};
	-- Collect options data.
	for checkbox in DiceMasterBannerPromptDialog.checkboxes:EnumerateActive() do
		local option = {
			icon = checkbox.Icon.icon:GetTexture();
			name = checkbox.Title:GetText();
			desc = checkbox.Description:GetText();
		};
		tinsert( banner.options, option );
	end

	return banner;
end

local returnFunc = function( bannerData )
	if not( bannerData ) then
		return
	end

	DiceMasterBannerPromptDialog.BannerTitle:SetText( bannerData.name );
	DiceMasterBannerPromptDialog.BannerSubtitle:SetText( bannerData.desc );
	DiceMasterBannerPromptDialog.AdvanceTurn:SetChecked( bannerData.advanceTurn );
	DiceMasterBannerPromptDialog.TurnTimer:SetChecked( bannerData.timer )
	if bannerData.timer then
		UIDropDownMenu_SetSelectedID( bannerData.timer );
	end
	if bannerData.options then
		DiceMasterBannerPromptDialog.options = bannerData.options
	else
		DiceMasterBannerPromptDialog.options = {}
		local option = {
			icon = "Interface/Icons/inv_misc_questionmark";
			name = "Title";
			desc = "Description";
		};
		tinsert( DiceMasterBannerPromptDialog.options, option );
	end
	Me.RollBannerPromptDialog_UpdateOptions()
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

function Me.RollBannerPromptDialog_OnLoad( self )
	self:SetClampedToScreen( true )
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	self:SetUserPlaced( true )
				
	self.target = "RAID";
				
	-- create check buttons
	self.checkboxes = CreateFramePool("Frame", self, "DiceMasterRollBannerPromptOptionFrameTemplate")

	self.options = {};
	for i = 1, 3 do
		local option = {
			icon = "Interface/Icons/inv_misc_questionmark";
			name = "Title";
			desc = "Description";
		};
		tinsert( self.options, option );
	end
	--Me.RollBannerPromptDialog_UpdateOptions()
end

function Me.RollBannerPromptDialog_SelectIcon( texture, optionFrame )
	DiceMasterBannerPromptDialog.options[ optionFrame:GetID() ].icon = texture;
	optionFrame.Icon:SetTexture( texture );
end

function Me.RollBannerPromptDialog_UpdateOptions()
	DiceMasterBannerPromptDialog.checkboxes:ReleaseAll();
	local options = DiceMasterBannerPromptDialog.options;
	for i = 1, #options do
		local checkbox = DiceMasterBannerPromptDialog.checkboxes:Acquire();
		checkbox:SetPoint("TOPLEFT", 14, -170 -28*i);
		--checkbox.Title:SetText( "Option " .. i );
		checkbox:SetID(i);
		checkbox:Show();
		checkbox.Title:SetText( options[i].name );
		checkbox.Description:SetText( options[i].desc );
		checkbox.Icon:SetTexture( options[i].icon );
		checkbox.CheckBox:SetChecked( true );
		DiceMasterBannerPromptDialog:SetHeight( 270 + (28*i) );
	end

	DiceMasterBannerPromptDialog.LoadDropdown:SetCollection(nil, "Banners", collectFunc, nil, returnFunc);
end

function Me.RollBannerPromptDialog_AddOption()
	if #DiceMasterBannerPromptDialog.options < 10 then
		local option = {
			icon = "Interface/Icons/inv_misc_questionmark";
			name = "Title";
			desc = "Description";
		};
		tinsert( DiceMasterBannerPromptDialog.options, option );
	end
	Me.RollBannerPromptDialog_UpdateOptions();
end

function Me.RollBannerPromptDialog_RemoveOption( index )
	if #DiceMasterBannerPromptDialog.options > 1 then
		tremove( DiceMasterBannerPromptDialog.options, index );
	end
	Me.RollBannerPromptDialog_UpdateOptions();
end

function Me.RollBanner_OnLoad( self )
	self:SetScale( 0.8 )

	for i = 2, 10 do
		local button = CreateFrame("Frame", "DiceMasterRollBannerOptionFrame"..i, self, "DiceMasterRollBannerOptionFrameTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterRollBannerOptionFrame"..(i-1)], "BOTTOM", 0, -2);
		button:SetScript( "OnShow", function( self ) self.Anim:Play() end)
	end	
end

function Me.RollBanner_UpdateOptions( data )

	DiceMasterRollBanner:SetHeight( 180 );
	for i = 1, 10, 1 do
		local button = _G[ "DiceMasterRollBannerOptionFrame" .. i ];
		
		if data[i] then
			button.Icon:SetTexture( data[i].icon );
			button.Title:SetText( data[i].name );
			button.Description:SetText( data[i].desc );
			button.IconHitBox.details = data[i].details;
			button:Show();
			
			DiceMasterRollBanner:SetHeight( 180 + 45*i );
		else
			button.Icon:SetTexture( nil );
			button.Title:SetText( "" );
			button.Description:SetText( "" );
			button.IconHitBox.details = nil;
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
	
	local data = {}
	-- Collect options data.
	for checkbox in DiceMasterBannerPromptDialog.checkboxes:EnumerateActive() do
		if checkbox.CheckBox:GetChecked() then
			local option = {
				icon = checkbox.Icon.icon:GetTexture();
				name = checkbox.Title:GetText();
				desc = checkbox.Description:GetText();
			};
			tinsert( data, option );
		end
	end
	
	-- Collect Turn Tracker data.
	local turnHasChanged = false;
	
	if DiceMasterBannerPromptDialog.AdvanceTurn:GetChecked() then
		CURRENT_COMBAT_ROUND = CURRENT_COMBAT_ROUND + 1;
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
	if not data.na or not data.ti then
	   
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
		Me.RollBanner_UpdateOptions( data.op )
		
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t "..data.ti.."|cFFFFFFFF "..data.su.."|r" , "RAID")
		
		DiceMasterRollBanner.AnimIn:Play()
		
		local timer = C_Timer.NewTimer(8, function()
			if DiceMasterRollBanner:IsShown() and not DiceMasterRollBanner.MouseIsOver then
				Me.RollBanner_OnMouseLeave( self, button )
			end
		end)
		
	end
end