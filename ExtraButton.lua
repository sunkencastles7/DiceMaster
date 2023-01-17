-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Extra button interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local extraButtonSkins = {
	["AirStrike"] = true,
	["ardenweald-extrabutton"] = true,
	["Amber"] = true,
	["bastion-extrabutton"] = true,
	["BrewmoonKeg"] = true,
	["ChampionLight"] = true,
	["Default"] = true,
	["Engineering"] = true,
	["EyeofTerrok"] = true,
	["Fel"] = true,
	["FengBarrier"] = true,
	["FengShroud"] = true,
	["GarrZoneAbility-Armory"] = true,
	["GarrZoneAbility-BarracksAlliance"] = true,
	["GarrZoneAbility-BarracksHorde"] = true,
	["GarrZoneAbility-Inn"] = true,
	["GarrZoneAbility-LumberMill"] = true,
	["GarrZoneAbility-MageTower"] = true,
	["GarrZoneAbility-Stables"] = true,
	["GarrZoneAbility-TradingPost"] = true,
	["GarrZoneAbility-TrainingPit"] = true,
	["GarrZoneAbility-Workshop"] = true,
	["GreenstoneKeg"] = true,
	["HearthofAzeroth-ExtraButton-Active"] = true,
	["HearthofAzeroth-ExtraButton-Disabled"] = true,
	["HozuBar"] = true,
	["LightningKeg"] = true,
	["maldraxxus-extrabutton"] = true,
	["Smash"] = true,
	["SoulCage"] = true,
	["SoulSwap"] = true,
	["Ultraxion"] = true,
	["venthyr-extrabutton"] = true,
	["Ysera"] = true,
}

local methods = {
	---------------------------------------------------------------------------
	-- Add a flyout menu button.
	--
	AddButton = function(self, icon, name, description, callback)
		self.hasFlyoutMenu = true;
		if not ( self.flyoutButtons ) then
			self.flyoutButtons = 1;
		elseif ( self.flyoutButtons < 3 ) then
			self.flyoutButtons = self.flyoutButtons + 1;
		else
			return
		end
		
		self.SpellFlyout["Button"..self.flyoutButtons].icon:SetTexture( icon )
		self.SpellFlyout["Button"..self.flyoutButtons].tooltipIcon = icon;
		self.SpellFlyout["Button"..self.flyoutButtons].tooltipTitle = name;
		self.SpellFlyout["Button"..self.flyoutButtons].tooltipText = description;
		self.SpellFlyout["Button"..self.flyoutButtons]:SetScript("OnEnter", Me.ExtraButton_OnEnter)
		self.SpellFlyout["Button"..self.flyoutButtons]:SetScript("OnLeave", Me.ExtraButton_OnLeave)
		self.SpellFlyout["Button"..self.flyoutButtons]:SetScript("OnClick", callback)
		self.SpellFlyout["Button"..self.flyoutButtons]:Show()
		
		self.SpellFlyout:SetHeight( 18 + ( 28 * ( self.flyoutButtons - 1 ) ) )
		self.FlyoutArrow:Show()
	end;
}

function Me.ExtraButton_OnLoad( self )
	self:SetClampedToScreen( true )
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	self:SetUserPlaced( true )
	
	self:SetAlpha(0)
	for k, v in pairs( methods ) do
		self[k] = v
	end
end

function Me.ExtraButton_OnEnter( self )
	if ( self.tooltipTitle ) then
		if ( self.tooltipIcon ) then
			DiceMasterTooltipIcon.icon:SetTexture( self.tooltipIcon )
			DiceMasterTooltipIcon.elite:Hide()
			DiceMasterTooltipIcon:Show()
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:AddLine( self.tooltipTitle, 1, 1, 1, 1 );
		if ( self.tooltipText ) then
			GameTooltip:AddLine( Me.FormatDescTooltip( self.tooltipText ), 1, 0.82, 0, 1 );
		end
		GameTooltip:Show();
	end
	if ( self.isSanctum ) then
		-- Special handling for Sanctum textures
		self.ArcaneEffectLeft.GrowAnim1:Play()
		self.ArcaneEffectRight.GrowAnim1:Play()
		self.Flash:Show()
	end
end

function Me.ExtraButton_OnLeave( self )
	DiceMasterTooltipIcon.icon:SetTexture( nil )
	DiceMasterTooltipIcon.elite:Hide()
	DiceMasterTooltipIcon:Hide()
	GameTooltip:Hide();
	if ( self.isSanctum ) then
		-- Special handling for Sanctum textures
		self.ArcaneEffectLeft.GrowAnim1:Stop()
		self.ArcaneEffectRight.GrowAnim1:Stop()
		self.Flash:Hide()
	end
end

function Me.ExtraButton_Show(texture, icon, name, description, callback)
	local frame = DiceMasterExtraButtonFrame
	
	if frame.flyoutButtons then
		for i = 1, frame.flyoutButtons do
			frame.SpellFlyout["Button"..i].icon:SetTexture( nil )
			frame.SpellFlyout["Button"..i].tooltipIcon = nil;
			frame.SpellFlyout["Button"..i].tooltipTitle = nil;
			frame.SpellFlyout["Button"..i].tooltipText = nil;
			frame.SpellFlyout["Button"..i]:SetScript("OnClick", nil)
			frame.SpellFlyout["Button"..i]:Hide()
		end
	end
	
	frame.flyoutButtons = nil;
	frame.hasFlyoutMenu = false;
	
	if ( texture == "Sanctum" ) then
		-- Special handling for Sanctum textures
		frame.Border:SetTexture( "Interface/AddOns/DiceMaster/Texture/ExtraButton/sanctum" );
		frame.ArcaneEffectLeft:Show()
		frame.ArcaneEffectRight:Show()
		frame.isSanctum = true;
	elseif ( extraButtonSkins[texture] ) then
		frame.Border:SetTexture( "Interface/ExtraButton/"..texture );
		frame.ArcaneEffectLeft:Hide()
		frame.ArcaneEffectRight:Hide()
		frame.isSanctum = false;
	else
		return
	end
	
	frame.Icon:SetTexture( icon );
	frame.tooltipIcon = icon;
	frame.tooltipTitle = name;
	frame.tooltipText = description;
	frame:SetScript("OnClick", callback)
	frame:Show();
	
	frame.FlyoutArrow:Hide()
	frame.SpellFlyout:Hide()
	
	if ( frame:GetAlpha() < 1 ) then
		frame.outro:Stop();
		frame.intro:Play();
	end
end

function Me.ExtraButton_Reset()
	local frame = DiceMasterExtraButtonFrame
	
	frame.Border:SetTexture( nil );
	frame.ArcaneEffectLeft:Hide()
	frame.ArcaneEffectRight:Hide()
	frame.isSanctum = false;
	frame.Icon:SetTexture( nil );
	frame.tooltipTitle = nil;
	frame.tooltipText = nil;
	
	for i = 1, frame.flyoutButtons do
		frame.SpellFlyout["Button"..i].icon:SetTexture( nil )
		frame.SpellFlyout["Button"..i].tooltipIcon = nil;
		frame.SpellFlyout["Button"..i].tooltipTitle = nil;
		frame.SpellFlyout["Button"..i].tooltipText = nil;
		frame.SpellFlyout["Button"..i]:SetScript("OnClick", nil)
		frame.SpellFlyout["Button"..i]:Hide()
	end
	frame.flyoutButtons = nil;
	frame.hasFlyoutMenu = false;
end

function Me.ExtraButton_Hide()
	if ( DiceMasterExtraButtonFrame:IsShown() ) then
		DiceMasterExtraButtonFrame.intro:Stop()
		DiceMasterExtraButtonFrame.outro:Play()
	end
end