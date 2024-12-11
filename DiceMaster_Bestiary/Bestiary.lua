-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me      = DiceMaster4
local Profile = Me.Profile

local MAJOR, MINOR = "HereBeDragons-Pins-2.0", 16 
local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")

---------------------------------------------------------

local pinCache = {}
local minimapPins = {}
local worldmapPins = {}
local pinCount = 0

local function recyclePin(pin)
	pin:Hide()
	pinCache[pin] = true
end

local function clearAllPins(t)
	for key, pin in pairs(t) do
		recyclePin(pin)
		t[key] = nil
	end
end

local function getNewPin()
	local pin = next(pinCache)
	if pin then
		pinCache[pin] = nil -- remove it from the cache
		return pin
	end
	-- create a new pin
	pinCount = pinCount + 1
	pin = CreateFrame("Button", "DiceMasterPin"..pinCount, Minimap, "DiceMasterBestiaryMapNodeTemplate")
	pin:SetPoint("CENTER", Minimap, "CENTER")
	pin:SetFrameLevel(5)
	pin:SetMovable(true)
	return pin
end

local pinsHandler = {}

function pinsHandler:OnEnter()
	local tooltip = DiceMasterBestiaryMapNodeTooltip
	
	tooltip:ClearAllPoints()
	tooltip:SetPoint("BOTTOMLEFT", self, "TOPRIGHT")
	SetPortraitTextureFromCreatureDisplayID( tooltip.Portrait, self.unitData.modelID )
	tooltip.Name:SetText( self.unitData.name )
	tooltip.DistanceMeter:SetText( Me.GetDistanceToMapIcon( self ) .. " yd away" )
	if ( self.unitData.raidMarker and self.unitData.raidMarker > 0 ) then
		tooltip.RaidMarker.Icon:SetTexture( "Interface/TargetingFrame/UI-RaidTargetingIcon_"..self.unitData.raidMarker )
	else
		tooltip.RaidMarker.Icon:SetTexture( nil )
	end
	
	if self.unitData.quantity and self.unitData.quantity > 1 then
		tooltip.Quantity:SetText( self.unitData.quantity )
	else
		tooltip.Quantity:SetText( "" )
	end
	
	if self.unitData.health then
		local ratio = self.unitData.health / self.unitData.maxHealth;
		tooltip.ActualHealthBar:SetWidth(max(tooltip.HealthBG:GetWidth() * ratio, 1));
		tooltip.HealthText:SetText( "Health: " .. self.unitData.health .. "/" .. self.unitData.maxHealth )
		tooltip.ActualHealthBar:Show()
		tooltip.HealthText:Show()
		tooltip.HealthBG:Show()
		tooltip.HealthBorder:Show()
		tooltip.Delimiter:SetPoint( "TOP", tooltip.HealthBG, "BOTTOM", 0, -15 )
		tooltip:SetHeight( 230 )
	else
		tooltip.ActualHealthBar:Hide()
		tooltip.HealthText:Hide()
		tooltip.HealthBG:Hide()
		tooltip.HealthBorder:Hide()
		tooltip.Delimiter:SetPoint( "TOP", tooltip.HealthBG, "BOTTOM", 0, 15 )
		tooltip:SetHeight( 200 )
	end
	
	for i = 1, #self.unitData.traits do
		tooltip["TraitIcon"..i]:SetTexture( self.unitData.traits[i].icon )
		tooltip["TraitName"..i]:SetText( self.unitData.traits[i].name )
	end
	tooltip:Show()
	
	Me.ResizeMapPin( self, 0.6 )
end

function pinsHandler:OnLeave()
	local tooltip = DiceMasterBestiaryMapNodeTooltip
	
	tooltip:ClearAllPoints()
	tooltip:Hide()
	
	Me.ResizeMapPin( self, 0.3 )
end

function Me.ResizeMapPin( pin, scale )
	pin:SetSize( 52 * scale, 60 * scale )
	if pin.Icon then
		pin.Icon:SetSize( 24 * scale, 24 * scale )
	end
	pin.Portrait:SetSize( 44 * scale, 44 * scale )
	pin.PortraitRing:SetSize( 62 * scale, 62 * scale )
	pin.PortraitRingCover:SetSize( 59 * scale, 62 * scale )
end

function Me.GetDistanceToMapIcon( pin )
	local y1, x1, instance1 = pin.coordY, pin.coordX, pin.Instance
	local y2, x2, _, instance2 = UnitPosition( "player" )
	local distance = instance1 == instance2 and ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
	
	if ( distance and distance <= 1000 ) then
		distance = math.floor( distance )
	else
		distance = ">1000"
	end
	
	return distance;
end

function Me.DeleteDuplicateMapIcons( unitData )
	for i = 1, pinCount do
		if _G["DiceMasterPin" .. i] then
			local pin = _G["DiceMasterPin"..i];
			if pin.unitData == unitData then
				-- World Map icons are even; Minimap icons are odd.
				if (i % 2 == 0) then
					HBDPins:RemoveWorldMapIcon( "DiceMasterMapIcon", pin )
				else
					HBDPins:RemoveMinimapIcon( "DiceMasterMapIcon", pin )
				end
			end
		end
	end
end

function Me.AddWorldMapIconMap( index, unitData, coordX, coordY, mapID )
	
	if not ( unitData ) then
		return;
	end
	
	-- Check for duplicates and remove them.
	
	Me.DeleteDuplicateMapIcons( unitData )

	-- Create the Minimap pin.
	
	local frameLevel = Minimap:GetFrameLevel() + 1
	local frameStrata = Minimap:GetFrameStrata()

	local icon = getNewPin();
	icon:SetParent(Minimap);
	icon:SetFrameStrata(frameStrata);
	icon:SetFrameLevel(frameLevel);
	icon.unitData = unitData
	icon.coordY, icon.coordX, _, icon.Instance = UnitPosition( "player" )
	if ( coordX and coordY and mapID ) then
		icon.coordX, icon.coordY, icon.Instance = HBD:GetWorldCoordinatesFromZone( coordX, coordY, mapID )
	end
	icon:SetScript("OnEnter", pinsHandler.OnEnter)
	icon:SetScript("OnLeave", pinsHandler.OnLeave)
	SetPortraitTextureFromCreatureDisplayID( icon.Portrait, icon.unitData.modelID )
	if ( icon.unitData.raidMarker and icon.unitData.raidMarker > 0 ) then
		icon.Icon:SetTexture( "Interface/TargetingFrame/UI-RaidTargetingIcon_" .. icon.unitData.raidMarker )
	else
		icon.Icon:SetTexture( nil )
	end
	Me.ResizeMapPin( icon, 0.3 )
	
	local x, y, map = HBD:GetPlayerZonePosition( true );
	if coordX and coordY then
		x = coordX;
		y = coordY;
		map = mapID;
	end
	
	HBDPins:AddMinimapIconMap("DiceMasterMapIcon", icon, map, x, y, true)
	
	-- Create the World Map Frame pin.
	
	local icon = getNewPin()
	icon:SetParent(WorldMapFrame.ScrollContainer.Child)
	icon.unitData = unitData
	icon.coordY, icon.coordX, _, icon.Instance = UnitPosition( "player" )
	if ( coordX and coordY and mapID ) then
		icon.coordX, icon.coordY, icon.Instance = HBD:GetWorldCoordinatesFromZone( coordX, coordY, mapID )
	end
	icon:SetScript("OnEnter", pinsHandler.OnEnter)
	icon:SetScript("OnLeave", pinsHandler.OnLeave)
	SetPortraitTextureFromCreatureDisplayID( icon.Portrait, icon.unitData.modelID )
	icon.Icon:SetTexture( "Interface/TargetingFrame/UI-RaidTargetingIcon_" .. icon.unitData.raidMarker )
	Me.ResizeMapPin( icon, 0.3 )
	
	HBDPins:AddWorldMapIconMap("DiceMasterMapIcon", icon, map, x, y, 1)
end

function Me.CalculateMapCoordsFromCursorPosition()
	local x, y = WorldMapFrame.ScrollContainer:GetNormalizedCursorPosition();
	local mapID = WorldMapFrame:GetMapID();
	if ( x > 0  and y > 0 and x < 1 and y < 1 ) then
		return x, y, mapID;
	end
end