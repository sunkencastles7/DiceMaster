-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Action bar interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local textureList =  {
	"_BG",
	"EndCapL",
	"EndCapR",
	"_Border",
	"Divider1",
	"Divider2",
	"Divider3",
	"EndTurnBG",
	"MicroBGL",
	"MicroBGR",
	"_MicroBGMid",
	"ButtonBGL",
	"ButtonBGR",
	"_ButtonBGMid",
	"PitchOverlay",
	"PitchButtonBG",
	"PitchBG",
	"PitchMarker",
	"PitchUpUp",
	"PitchUpDown",
	"PitchUpHighlight",
	"PitchDownUp",
	"PitchDownDown",
	"PitchDownHighlight",
	"EndTurnUp",
	"EndTurnDown",
	"EndTurnHighlight",
	"HealthBarBG",
	"HealthBarOverlay",
	"PowerBarBG",
	"PowerBarOverlay",
};
local xpBarTextureList = {
	"XpMid",
	"XpL",
	"XpR",
}

local actionIcons = {
	["Movement"] = { 0, 0.25, 0, 0.25 };
	["Action"] = { 0.25, 0.5, 0, 0.25 };
	["Bonus Action"] = { 0.5, 0.75, 0, 0.25 };
	["Bonus Action x2"] = { 0.75, 1.0, 0, 0.25 };
	["Movement Used"] = { 0, 0.25, 0.25, 0.5 };
	["Action Used"] = { 0.25, 0.5, 0.25, 0.5 };
	["Bonus Action Used"] = { 0.5, 0.75, 0.25, 0.5 };
	["Bonus Action x2 Used"] = { 0.75, 1.0, 0.25, 0.5 };
}

local spellSlotIcons = {
	["1/1"] = { 0, 0.25, 0, 0.25 };
	["2/2"] = { 0.25, 0.5, 0, 0.25 };
	["3/3"] = { 0.5, 0.75, 0, 0.25 };
	["4/4"] = { 0.75, 1.0, 0, 0.25 };
	["0/1"] = { 0, 0.25, 0.25, 0.5 };
	["1/2"] = { 0.25, 0.5, 0.25, 0.5 };
	["2/3"] = { 0.5, 0.75, 0.25, 0.5 };
	["3/4"] = { 0.75, 1.0, 0.25, 0.5 };
	-- (empty) = { 0, 0.25, 0.5, 0.75 };
	["0/2"] = { 0.25, 0.5, 0.5, 0.75 };
	["1/3"] = { 0.5, 0.75, 0.5, 0.75 };
	["2/4"] = { 0.75, 1.0, 0.5, 0.75 };
	["4/4"] = { 0, 0.25, 0.75, 1.0 };
	-- (empty) = { 0.25, 0.5, 0.75, 1.0 };
	["0/3"] = { 0.5, 0.75, 0.75, 1.0 };
	["1/4"] = { 0.75, 1.0, 0.75, 1.0 };
}

function Me.ActionBar_OnLoad( self )
	-- Overriding is shown so that it returns false if the frame is animating out as well
	self.IsShownBase = self.IsShown;
	self.IsShown = self.IsShownOverride;

	-- Setup action categories
	local actionCategories = { "Movement", "Action", "Bonus Action", "1/1", "2/3", "4/4", "1/3" };
	for i = 1, #actionCategories do
		local tab = CreateFrame( "Button", "DiceMasterActionBarTab"..i, self.tabsFrame, "PanelTopTabButtonTemplate");
		tab:SetPoint( "LEFT", self.tabsFrame, "LEFT", 32*i-32, 6 );
		tab:SetSize( 32, 32 );
		local icon;
		if actionIcons[actionCategories[i]] then
			local coord = actionIcons[actionCategories[i]];
			icon = CreateTextureMarkup("Interface/AddOns/DiceMaster/Texture/action-icons", 128, 128, 28, 28, coord[1], coord[2], coord[3], coord[4]);
		elseif spellSlotIcons[actionCategories[i]] then
			local coord = spellSlotIcons[actionCategories[i]];
			icon = CreateTextureMarkup("Interface/AddOns/DiceMaster/Texture/spell-slot-icons", 128, 128, 28, 28, coord[1], coord[2], coord[3], coord[4]);
			tab.slotRank = tab:CreateFontString( nil, "OVERLAY", "GameFontHighlightOutline" );
			tab.slotRank:SetPoint( "TOP", 0, -3 );
			tab.slotRank:SetText( "I" );
		end
		tab:SetText( icon );
		tab:SetID(i);
		tab:SetScript("OnClick", function()
			PanelTemplates_SetTab(DiceMasterActionBar, i);
			PlaySound(841);
		end);
		tab:SetScript("OnEnter", function()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText( "Edit Pet" )
		end);
	end
	self.tabsFrame:SetWidth( 72 * #actionCategories );
	self.tabsFrame:SetPoint("BOTTOM", self, "TOP");
	PanelTemplates_SetNumTabs(self, #actionCategories);
	PanelTemplates_SetTab(self, 1);

	--Setup the XP bar
	local divWidth = self.xpBar.XpMid:GetWidth()/19;
	local xpos = 6;	
	for i=1,19 do
		local texture = self.xpBar:CreateTexture("DiceMasterActionBarXpDiv"..i, "ARTWORK", nil, 2);
		texture:SetSize(7, 14);
		texture:SetTexCoord(0.2773438, 0.2910156, 0.390625, 0.4179688);
		self.xpBar["XpDiv"..i] = texture;
		xpBarTextureList[#xpBarTextureList + 1] = "XpDiv"..i;
		xpos = xpos + divWidth;
	end

	-- Add buttons
	self.buttons = {};
	for y = 1,2 do
        for x = 1,11 do
			local btn = CreateFrame( "DiceMasterTraitButton", "DiceMasterActionBar" .. y .. "Button" .. x, self )
			btn:SetPoint( "TOPLEFT", 32*x+204, -32*y+7 );

			btn:SetSize( 32, 32 );
			btn:SetScript( "OnMouseDown", function( self, button )
				-- TODO
			end)
			tinsert( self.buttons, btn );
		end
	end

	--Add End Turn Button Textures
	self["EndTurnUp"] = self.EndTurnButton:GetNormalTexture();
	self["EndTurnDown"] = self.EndTurnButton:GetPushedTexture();
	self["EndTurnHighlight"] = self.EndTurnButton:GetHighlightTexture();

	--Add PitchUp button Textures
	self["PitchUpUp"] = self.PitchUpButton:GetNormalTexture();
	self["PitchUpDown"] = self.PitchUpButton:GetPushedTexture();
	self["PitchUpHighlight"] = self.PitchUpButton:GetHighlightTexture();

	--Add PitchDown button Textures
	self["PitchDownUp"] = self.PitchDownButton:GetNormalTexture();
	self["PitchDownDown"] = self.PitchDownButton:GetPushedTexture();
	self["PitchDownHighlight"] = self.PitchDownButton:GetHighlightTexture();
	self:RegisterEvent("VEHICLE_ANGLE_UPDATE");
	self:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player");
	self:RegisterUnitEvent("UNIT_ENTERING_VEHICLE", "player");
	self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player");

	Me.ActionBar_SetSkin( self, "ALLIANCE" );
end

function Me.ActionBar_OnEvent( self, event, ... )
	local arg1 = ...;
	if ( event == "PLAYER_LEVEL_UP" ) then
		self:UpdateXpBar(arg1);
	elseif ( event == "PLAYER_XP_UPDATE" ) then
		self:UpdateXpBar();
	elseif ( event == "UNIT_ENTERED_VEHICLE" ) then
		self:UpdateSkin();
	elseif ( event == "UNIT_ENTERING_VEHICLE" ) then
		self.HasExit, self.HasPitch = select(6, ...);
	elseif ( event == "UNIT_EXITED_VEHICLE") then
		self.HasExit = nil;
		self.HasPitch = nil;
		if GetOverrideBarSkin() then
			Me.ActionBar_CalcSize( self );
		end
	end
end

local actionBars = { 
	"MainMenuBar", "MultiBarBottomLeft", "MultiBarBottomRight", "MultiBarLeft", "MultiBarRight", "MultiBar5", "MultiBar6", "MultiBar7"
};

function Me.ActionBar_OnShow( self )
	if EditModeManagerFrame:IsEditModeActive() then
		HideUIPanel(EditModeManagerFrame);
	end

	UIParentBottomManagedFrameContainer:UpdateManagedFramesAlphaState();
	UIParentRightManagedFrameContainer:UpdateManagedFramesAlphaState();

	for i = 1, #actionBars do
        bar = _G[actionBars[i]];
        if bar and bar:IsVisible() and bar.actionButtons then
			bar.prevAlpha = bar:GetAlpha() or 1;
			UIFrameFadeOut( bar, 1, bar.prevAlpha, 0);
		end
	end

	EditModeManagerFrame:BlockEnteringEditMode(self);
	EditModeManagerFrame:UpdateBottomActionBarPositions();

	self:ClearAllPoints();
	self:SetPoint("BOTTOM", 0, -180);
	self.slideIn:Play();

	self.PlayerStartPosition = { UnitPosition("player") };
	DiceMasterMovementTracker:SetScript("OnUpdate", function()
		local y, x, _, instance = unpack(self.PlayerStartPosition);
		local y2, x2, _, instance2 = UnitPosition( "player" );
		local distance = instance == instance2 and ((x2 - x) ^ 2 + (y2 - y) ^ 2) ^ 0.5
		if distance > 1 then
			DiceMasterMovementTracker.Text:SetText( floor(distance) .. " yds");
		else
			DiceMasterMovementTracker.Text:SetText( "0 yds");
		end
	end)
	DiceMasterMovementTracker:Show();
end

function Me.ActionBar_OnHide( self )
	UIParentBottomManagedFrameContainer:UpdateManagedFramesAlphaState();
	UIParentRightManagedFrameContainer:UpdateManagedFramesAlphaState();

	for i = 1, #actionBars do
        bar = _G[actionBars[i]];
        if bar and bar:IsVisible() and bar.actionButtons then
			if bar.prevAlpha then
				UIFrameFadeIn( bar, 1, 0, bar.prevAlpha );
			else
				UIFrameFadeIn( bar, 1, 0, 1 );
			end
		end
	end

	UIParent_ManageFramePositions();

	EditModeManagerFrame:UnblockEnteringEditMode(self);
end

function Me.ActionBar_UpdateSkin( self )
	-- For now, a vehicle has precedence over override bars (hopefully designers make it so these never conflict)
	if ( HasVehicleActionBar() ) then
		Me.ActionBar_Setup(self, UnitVehicleSkin("player"), GetVehicleBarIndex());
	else
		Me.ActionBar_Setup(self, GetOverrideBarSkin(), GetOverrideBarIndex());
	end
end

function Me.ActionBar_SetSkin( self, skin )
	local textureFile = "Interface/PLAYERACTIONBARALT/" .. skin;
	for _,tex in pairs(textureList) do
		self[tex]:SetTexture(textureFile, strsub(tex, 1, 1) == "_", strsub(tex, 1, 1) == "|");
	end
	for _,tex in pairs(xpBarTextureList) do
		self.xpBar[tex]:SetTexture(textureFile, strsub(tex, 1, 1) == "_", strsub(tex, 1, 1) == "|");
	end
end


function Me.ActionBar_CalcSize( self )
	self:SetWidth(1020);
	self.xpBar.XpMid:SetWidth(580);
	self.xpBar:SetWidth(596);
	self.Divider2:SetPoint("BOTTOM", 103, 0);
	self.SpellButton1:SetPoint("BOTTOM", -234, 17);

	local divWidth = self.xpBar.XpMid:GetWidth()/19;
	local xpos = divWidth-15;
	for i=1,19 do
		local texture = self.xpBar["XpDiv"..i];
		texture:SetPoint("LEFT", self.xpBar.XpMid, "LEFT", floor(xpos), 10);
		xpos = xpos + divWidth;
	end
	--self:UpdateXpBar();

	--UnitFrameHealthBar_Update(OverrideActionBarHealthBar, "vehicle");
	--UnitFrameManaBar_Update(OverrideActionBarPowerBar, "vehicle");
end

function Me.ActionBar_StatusBars_ShowTooltip(self)
	if ( GetMouseFocus() == self ) then
		local value = self:GetValue();
		local _, valueMax = self:GetMinMaxValues();
		if ( valueMax > 0 ) then
			local text = format("%s/%s (%s%%)", BreakUpLargeNumbers(value), BreakUpLargeNumbers(valueMax), tostring(math.ceil((value / valueMax) * 100)));
			GameTooltip:SetOwner(self, self.tooltipAnchorPoint);
			if ( self.prefix ) then
				GameTooltip:AddLine(self.prefix);
			end
			GameTooltip:AddLine(text, 1.0,1.0,1.0 );
			GameTooltip:Show();
		end
	end
end

function Me.ActionBar_Setup( self, skin, barIndex )
	Me.ActionBar_SetSkin(skin);
	Me.ActionBar_CalcSize( self );
	self:SetAttribute("actionpage", barIndex);

	for k=1,MAX_ALT_SPELLBUTTONS do
		local button = self["SpellButton"..k];
		button:UpdateAction();
		button:Update();
		local _, spellID = GetActionInfo(button.action);
		if spellID and spellID > 0 then
			button:SetAttribute("statehidden", false);
			button:Show();
		else
			button:SetAttribute("statehidden", true);
			button:Hide();
		end
	end

	local shouldShowHealthBar;
	local shouldShowManaBar;
	--vehicles always show both bars, override bars check their flags
	shouldShowHealthBar = true;
	shouldShowManaBar = true;

	if shouldShowHealthBar then
		OverrideActionBarHealthBar:Show();
	else
		OverrideActionBarHealthBar:Hide();
	end

	if shouldShowManaBar then
		OverrideActionBarPowerBar:Show();
	else
		OverrideActionBarPowerBar:Hide();
	end

	Me.ActionBar_UpdateXpBar();
end

local TIMER_BAR_TEXCOORD_LEFT = 0.56347656;
local TIMER_BAR_TEXCOORD_RIGHT = 0.89453125;
local TIMER_BAR_TEXCOORD_TOP = 0.00195313;
local TIMER_BAR_TEXCOORD_BOTTOM = 0.03515625;

function Me.ActionBar_TurnTimer_OnUpdate( self, elapsed )
	if ( ( C_PetBattles.GetBattleState() ~= Enum.PetbattleState.WaitingPreBattle ) and
		 ( C_PetBattles.GetBattleState() ~= Enum.PetbattleState.RoundInProgress ) and
		 ( C_PetBattles.GetBattleState() ~= Enum.PetbattleState.WaitingForFrontPets ) ) then
		self.Bar:SetAlpha(0);
		self.TimerText:SetText("");
	elseif ( self.turnExpires ) then
		local timeRemaining = self.turnExpires - GetTime();

		--Deal with variable lag from the server without looking weird
		if ( timeRemaining <= 0.01 ) then
			timeRemaining = 0.01;
		end

		local timeRatio = 1.0;
		if ( self.turnTime > 0.0 ) then
			timeRatio = timeRemaining / self.turnTime;
		end
		local usableSpace = 337;

		self.Bar:SetWidth(timeRatio * usableSpace);
		self.Bar:SetTexCoord(TIMER_BAR_TEXCOORD_LEFT, TIMER_BAR_TEXCOORD_LEFT + (TIMER_BAR_TEXCOORD_RIGHT - TIMER_BAR_TEXCOORD_LEFT) * timeRatio, TIMER_BAR_TEXCOORD_TOP, TIMER_BAR_TEXCOORD_BOTTOM);

		if ( C_PetBattles.IsWaitingOnOpponent() ) then
			self.Bar:SetAlpha(0.5);
			self.TimerText:SetText(PET_BATTLE_WAITING_FOR_OPPONENT);
		else
			self.Bar:SetAlpha(1);
			if ( self.turnTime > 0.0 ) then
				self.TimerText:SetText(ceil(timeRemaining));
			else
				self.TimerText:SetText("")
			end
		end
	else
		self.Bar:SetAlpha(0);
		if ( self.IsWaitingOnOpponent ) then
			self.TimerText:SetText(PET_BATTLE_WAITING_FOR_OPPONENT);
		else
			self.TimerText:SetText(PET_BATTLE_SELECT_AN_ACTION);
		end
	end
end

function Me.ActionBar_TurnTimer_UpdateValues( self )
	local timeRemaining, turnTime = C_PetBattles.GetTurnTimeInfo(); 
	self.turnExpires = GetTime() + timeRemaining;
	self.turnTime = turnTime;
end

function Me.ActionBar_StartTimerBar( self, duration )
	if ( IsLevelAtEffectiveMaxLevel(level) or IsXPUserDisabled() ) then
		self.TurnTimer:Hide();
	else
		self.TurnTimer:Show();
		self.TurnTimer:SetMinMaxValues( 0, duration );
		self.TurnTimer:SetValue( duration );
		self.Timer = C_Timer.NewTicker( 1, function()
			local secondsLeft = self.TurnTimer:GetValue();
			if secondsLeft > 0 then
				self.TurnTimer:SetValue( secondsLeft - 1 );
			else
				self.Timer:Cancel();
			end
		end, duration);
	end
end

function Me.ActionBar_EndTurn()
	PlaySound(32052);
	DiceMasterActionBar.hideOnFinish = true;
	DiceMasterActionBar.slideOut:Play();
end

function Me.ActionBar_IsShownOverride( self )
	return self:IsShownBase() and (not self.slideOut:IsPlaying() or self.slideOut:IsReverse());
end