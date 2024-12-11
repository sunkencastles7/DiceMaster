-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Unit Details Info Frame.
--

local Me = DiceMaster4

local UNIT_BANNER_COLOURS = {
	{ r = 1, g = 1, b = 0 };				-- [Yellow Star]
	{ r = 1, g = 0.5, b = 0.25 };			-- [Orange Circle]
	{ r = 0.64, g = 0.21, b = 0.94 };		-- [Purple Diamond]
	{ r = 0.12, g = 1, b = 0 };				-- [Green Triangle]
	{ r = 0.667, g = 0.667, b = 0.867 };	-- [Silver Moon]
	{ r = 0, g = 0.44, b = 0.867 };			-- [Blue Square]
	{ r = 1, g = 0.125, b = 0.125 };		-- [Red X]
	{ r = 1, g = 1, b = 1 };				-- [White Skull]
}

DiceMasterUnitDetailsFrameMixin = { };

function DiceMasterUnitDetailsFrameMixin:UpdatedBannerColor(bannerColor)
	self.Banner:SetVertexColor(bannerColor.r, bannerColor.g, bannerColor.b);
end

function DiceMasterUnitDetailsFrameMixin:SetFrameText(name, raidMarker, description)
	if raidMarker and raidMarker > 0 then
		self.TitleContainer.TitleText:SetText( "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. raidMarker .. ":12|t " .. name );
		self.UnitInfoFrame.UnitName:SetText( "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. raidMarker .. ":12|t " .. name );
	else
		self.TitleContainer.TitleText:SetText( name );
		self.UnitInfoFrame.UnitName:SetText( name );
	end
	
	--self.UnitInfoFrame.ScrollFrame.Child.Distance:SetText( "10 yd away" )
	self.UnitInfoFrame.ScrollFrame.Child.DescriptionFrame.description:SetText(description);
end

function DiceMasterUnitDetailsFrameMixin:SetFrameHealth(currentHealth, maxHealth, currentArmour)
	if currentHealth then
		self.HealthBar:SetMax( maxHealth )
		self.HealthBar:SetValue( currentHealth )
		self.HealthBar:SetArmour( currentArmour )
		self.HealthBar:SetFrameLevel( 502 )
		self.HealthBar:Show()
	else
		self.HealthBar:Hide()
	end
end

function DiceMasterUnitDetailsFrameMixin:LoadUnitData(unitData)

	if( not unitData) then
		return;
	end

	self.unitData = unitData;
	
	self.coordX = Me.UnitViewing.coordX
	self.coordY = Me.UnitViewing.coordY
	self.Instance = Me.UnitViewing.Instance
	
	self:UpdateModel(unitData.modelID);
	self:SetFrameText(unitData.name, unitData.raidMarker, unitData.description)
	self:SetFrameHealth(unitData.health, unitData.maxHealth, unitData.armour)
	
	SetPortraitTextureFromCreatureDisplayID(DiceMasterUnitDetailsFramePortrait, unitData.modelID);
	if ( unitData.raidMarker and unitData.raidMarker > 0 ) then 
		self:UpdatedBannerColor( UNIT_BANNER_COLOURS[unitData.raidMarker] );
	else
		self:UpdatedBannerColor( { r = 1, g = 0.82, b = 0 }  );
	end
	
	Me.UnitInfo_UpdateStatisticsFrame( unitData.statistics, self.UnitInfoFrame.ScrollFrame.Child.StatisticsFrame )
	Me.UnitInfo_UpdateTraitsFrame( unitData.traits, self.UnitInfoFrame.ScrollFrame.Child.TraitsFrame )
	Me.UnitInfo_UpdateDescriptionFrame( unitData.description, self.UnitInfoFrame.ScrollFrame.Child.DescriptionFrame )
end

function DiceMasterUnitDetailsFrameMixin:OnShow()
	self.Inset:Hide();
	self:LoadUnitData(Me.UnitViewing.unitData)
	PlaySound(679)
end

function DiceMasterUnitDetailsFrameMixin:UpdateModel(modelID)
	self.ModelFrame.Model:SetModelByCreatureDisplayID(modelID);
end

function DiceMasterUnitDetailsFrameMixin:OnLoad()
	self:SetClampedToScreen( true )
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	self:SetUserPlaced( true )
	
	tinsert(UISpecialFrames, self:GetName());

	self.UnitInfoFrame.ScrollFrame.Child.TraitsFrame.bulletPool = CreateFramePool("DiceMasterUnitInfoTraitTemplate", self.UnitInfoFrame.ScrollFrame.Child);
	self.UnitInfoFrame.ScrollFrame.Child.StatisticsFrame.bulletPool = CreateFramePool("DiceMasterUnitInfoStatisticsTemplate", self.UnitInfoFrame.ScrollFrame.Child);
	self.TopTileStreaks:Hide();
	self.UnitInfoFrame.UnitName:SetFontObjectsToTry("Fancy32Font", "Fancy30Font", "Fancy27Font", "Fancy24Font", "Fancy24Font", "Fancy18Font", "Fancy16Font");
	
	self.UnitInfoFrame.ScrollFrame.Child.usedHeaders = { self.UnitInfoFrame.ScrollFrame.Child.StatisticsFrame, self.UnitInfoFrame.ScrollFrame.Child.TraitsFrame, self.UnitInfoFrame.ScrollFrame.Child.DescriptionFrame }
	
	--self:LoadUnitData(UNIT_DATA_TEST)
end

function DiceMasterUnitDetailsFrameMixin:OnHide()
	self.UnitViewing = nil;
	PlaySound(680)
end