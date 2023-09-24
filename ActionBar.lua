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

function Me.ActionBar_OnLoad( self )
	-- Overriding is shown so that it returns false if the frame is animating out as well
	self.IsShownBase = self.IsShown;
	self.IsShown = self.IsShownOverride;

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

	Me.ActionBar_SetSkin( self, "NATURAL" );
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

function Me.ActionBar_OnShow( self )
	if EditModeManagerFrame:IsEditModeActive() then
		HideUIPanel(EditModeManagerFrame);
	end

	UIParentBottomManagedFrameContainer:UpdateManagedFramesAlphaState();
	UIParentRightManagedFrameContainer:UpdateManagedFramesAlphaState();

	EditModeManagerFrame:BlockEnteringEditMode(self);
	EditModeManagerFrame:UpdateBottomActionBarPositions();
end

function Me.ActionBar_OnHide( self )
	UIParentBottomManagedFrameContainer:UpdateManagedFramesAlphaState();
	UIParentRightManagedFrameContainer:UpdateManagedFramesAlphaState();

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
	self:UpdateXpBar();

	UnitFrameHealthBar_Update(OverrideActionBarHealthBar, "vehicle");
	UnitFrameManaBar_Update(OverrideActionBarPowerBar, "vehicle");
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

function Me.ActionBar_UpdateXpBar( self, newLevel )
	local level = newLevel or UnitLevel("player");
	if ( IsLevelAtEffectiveMaxLevel(level) or IsXPUserDisabled() ) then
		self.xpBar:Hide();
	else
		local currXP = UnitXP("player");
		local nextXP = UnitXPMax("player");
		self.xpBar:Show();
		self.xpBar:SetMinMaxValues(min(0, currXP), nextXP);
		self.xpBar:SetValue(currXP);
	end
end

function Me.ActionBar_IsShownOverride( self )
	return self:IsShownBase() and (not self.slideOut:IsPlaying() or self.slideOut:IsReverse());
end