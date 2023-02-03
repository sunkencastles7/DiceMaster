-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

-------------------------------------------------------------------------------
local MAJOR, MINOR = "HereBeDragons-Pins-2.0", 16 
local HBD = LibStub("HereBeDragons-2.0")
local HBDPins = LibStub("HereBeDragons-Pins-2.0")

---------------------------------------------------------

local pinCache = {}
local mapPins = {}
local pinCount = 0;

local function recyclePin(pin)
	pin.Ping:Finish()
	pin:Hide()
	pinCache[pin] = true
end

local function clearAllPins()
	for key, pin in pairs(mapPins) do
		recyclePin(pin)
		t[key] = nil
	end
end

local function getNewMapPin( i )
	local pin = next(pinCache)
	if pin then
		pinCache[pin] = nil -- remove it from the cache
		return pin
	end
	-- create a new pin
	pinCount = pinCount + 1
	pin = CreateFrame("Button", "DiceMasterMapPin"..i, Minimap, "DiceMasterMapNodeTemplate")
	pin:SetPoint("CENTER", Minimap, "CENTER")
	pin:SetFrameLevel(5)
	pin:SetMovable(true)
	pin:Hide()
	return pin
end

local function getNewMinimapPin( i )
	local pin = next(pinCache)
	if pin then
		pinCache[pin] = nil -- remove it from the cache
		return pin
	end
	-- create a new pin
	pin = CreateFrame("Button", "DiceMasterMinimapPin"..i, Minimap, "DiceMasterMapNodeTemplate")
	pin:SetPoint("CENTER", Minimap, "CENTER")
	pin:SetFrameLevel(5)
	pin:SetMovable(true)
	pin:Hide()
	return pin
end

-- Handler for node tooltips.
--
local function OnEnter( self )
	GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
	GameTooltip:ClearLines()
	GameTooltip:AddLine( self.title, 1, 1, 1, true )
	GameTooltip:AddLine( self:GetDistanceToMapIcon() .. " yd away", 1, 1, 1, true )
	GameTooltip:AddLine( Me.FormatDescTooltip( self.description ), 1, 0.81, 0, true )
	
	if self.isWorldMapPin then
		if Me.IsLeader( false ) then
			GameTooltip:AddLine( "<Left Click to Drag>", 0.44, 0.44, 0.44, true )
			GameTooltip:AddLine( "<Right Click to Edit>", 0.44, 0.44, 0.44, true )
		end
		GameTooltip:AddLine( "<Shift+Click to Link to Chat>", 0.44, 0.44, 0.44, true )
	end
	GameTooltip:Show()
	
	self:ResizeMapIcon( 1 )
	self:SetFrameStrata( "HIGH" )
end

local function OnLeave( self )
    GameTooltip:Hide()
	DiceMasterTooltipIcon:Hide()
	DiceMasterTooltipIcon.approved:Hide()
	
	self:ResizeMapIcon( 0.7 )
	self:SetFrameStrata( "HIGH" )
end

local function OnDragStart( self, button )
	if not Me.IsLeader( false ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	if self.isWorldMapPin then
		if self.mapID == WorldMapFrame:GetMapID() then
			isMoving = true
			self:StartMoving()
		end
	end
end

local function OnDragStop( self, button )
	if isMoving then
		isMoving = false
		self:StopMovingOrSizing()
		local x, y = self:GetCenter()
		local s = self:GetEffectiveScale() / WorldMapFrame.ScrollContainer.Child:GetEffectiveScale()
		x = x * s - WorldMapFrame.ScrollContainer.Child:GetLeft()
		y = y * s - WorldMapFrame.ScrollContainer.Child:GetTop()
		
		-- Get the new coordinate
		x = x / WorldMapFrame.ScrollContainer.Child:GetWidth()
		y = -y / WorldMapFrame.ScrollContainer.Child:GetHeight()
		
		-- Move the button back into the map if it was dragged outside
		if x < 0.001 then x = 0.001 end
		if x > 0.999 then x = 0.999 end
		if y < 0.001 then y = 0.001 end
		if y > 0.999 then y = 0.999 end
		
		Me.Profile.mapNodes[ self.id ].coordX = x;
		Me.Profile.mapNodes[ self.id ].coordY = y;
		
		Me.UpdateAllMapNodes()
		Me.RollTracker_ShareMapNodesWithParty()
	end
end

local function OnUpdate( self )
	
	if GameTooltip:IsShown() and GameTooltip:GetOwner() == self then
		self:GetScript( "OnEnter" )( self )
	end

end

local function OnClick( self, button )
	if button == "LeftButton" and IsShiftKeyDown() then
		local channels = {
			"PARTY",
			"RAID",
			"GUILD",
			"WHISPER",
		}
		local channelName = tostring(LAST_ACTIVE_CHAT_EDIT_BOX:GetAttribute("chatType")) or nil
		local dist = "GUILD"
		for i = 1, #channels do
			if channels[i] == channelName then
				dist = channels[i]
				break;
			end
		end
		local channel = nil
		if dist == "WHISPER" then
			channel = ACTIVE_CHAT_EDIT_BOX:GetAttribute("tellTarget") or nil
		end
		
		if Me.IsLeader( false ) then
			Me.RollTracker_ShareMapNodesWithParty()
		end
		
		ChatEdit_InsertLink( "[DiceMaster4Pin:" .. self.id .. "]" ) 
		
		return
	end

	if not Me.IsLeader( false ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	if button == "RightButton" then
		DiceMasterRollFrame:Show()
		DiceMasterRollFrameTab4:Click()
		DiceMasterMapNodes.selected = self.id
		Me.DiceMasterMapNodes_Update()
	end
end

local methods = {
	GetDistanceToMapIcon = function( self )
		local y1, x1, instance1 = self.coordY, self.coordX, self.Instance
		local y2, x2, _, instance2 = UnitPosition( "player" )
		local distance = instance1 == instance2 and ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
		
		if ( distance and distance <= 1000 ) then
			distance = math.floor( distance )
		else
			distance = ">1000"
		end
		
		return distance;
	end;
	
	ResizeMapIcon = function( self, scale )
		self.Icon:SetSize( self.iconWidth * scale, self.iconHeight * scale )
		self.Highlight:SetSize( self.iconWidth * scale, self.iconHeight * scale )
	end;	
}

function Me.DeleteDuplicateMapIcons()
	for i = 1, pinCount do
		if _G["DiceMasterMapPin" .. i] then
			local pin = _G["DiceMasterMapPin"..i];
			HBDPins:RemoveWorldMapIcon( "DiceMasterMapIcon", pin )
		end
		if _G["DiceMasterMinimapPin" .. i] then
			local pin = _G["DiceMasterMinimapPin"..i];
			HBDPins:RemoveMinimapIcon( "DiceMasterMapIcon", pin )
		end
	end
end

function Me.UpdateAllMapNodes()
	
	HBDPins:RemoveAllWorldMapIcons("DiceMasterMapIcon")
	HBDPins:RemoveAllMinimapIcons("DiceMasterMapIcon")
	clearAllPins()
	
	local mapNodes = Me.Profile.mapNodes
	
	local uiMapID = WorldMapFrame:GetMapID()
	if not uiMapID then return end
	
	if IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.IsLeader( false ) and not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) and Me.db.global.enableMapNodes then
		for i = 1, GetNumGroupMembers(1) do
			local name, rank = GetRaidRosterInfo(i)
			if name and rank == 2 then
				if Me.inspectData[ name ] and Me.inspectData[ name ].mapNodes then
					mapNodes = Me.inspectData[ name ].mapNodes
				end
				break
			end
		end
	end
	
	if not mapNodes then return end

	-- Create the Minimap pin.
	
	local frameLevel = Minimap:GetFrameLevel() + 5

	for i = 1, #mapNodes do
		local iconData = mapNodes[i]
		local icon = getNewMinimapPin( i );
		icon:SetParent(Minimap);
		icon:SetFrameStrata( "HIGH" );
		icon:SetFrameLevel(frameLevel);
		icon.coordY, icon.coordX, _, icon.Instance = UnitPosition( "player" )
		if ( iconData.coordX and iconData.coordY and iconData.mapID ) then
			icon.coordX, icon.coordY, icon.Instance = HBD:GetWorldCoordinatesFromZone( iconData.coordX, iconData.coordY, iconData.mapID )
		end
		
		if not( type(iconData.icon) == "string") then
			iconData.icon = "Object"
		end

		local atlasInfo = C_Texture.GetAtlasInfo( iconData.icon )
		if atlasInfo then
			icon.iconWidth = atlasInfo.width;
			icon.iconHeight = atlasInfo.height;
			icon.Highlight:SetAtlas( iconData.icon )
			icon.Icon:SetAtlas( iconData.icon )
		else
			icon.iconWidth = 32;
			icon.iconHeight = 32;
			icon.Icon:SetTexCoord( 0, 1, 0, 1 )
			icon.Icon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
			icon.Highlight:SetTexCoord( 0, 1, 0, 1 )
			icon.Highlight:SetTexture( "Interface/Icons/inv_misc_questionmark" )
		end
		
		icon:ResizeMapIcon( 0.7 )
		
		local x, y, map = HBD:GetPlayerZonePosition( true );
		if iconData.coordX and iconData.coordY then
			x = iconData.coordX;
			y = iconData.coordY;
			map = iconData.mapID;
		end
		
		icon.id = i;
		icon.title = iconData.title;
		icon.icon = iconData.icon;
		icon.iconName = iconData.iconName;
		icon.description = iconData.description;
		icon.mapID = map;
		icon.zone = zone;
		
		HBDPins:AddMinimapIconMap("DiceMasterMapIcon", icon, map, x, y, true)
		
		-- Create the World Map Frame pin.
		
		local icon = getNewMapPin( i )
		icon:SetParent(WorldMapFrame.ScrollContainer.Child)
		icon.coordY, icon.coordX, _, icon.Instance = UnitPosition( "player" )
		if ( iconData.coordX and iconData.coordY and iconData.mapID ) then
			icon.coordX, icon.coordY, icon.Instance = HBD:GetWorldCoordinatesFromZone( iconData.coordX, iconData.coordY, iconData.mapID )
		end

		if not( type(iconData.icon) == "string") then
			iconData.icon = "Object"
		end
		
		local atlasInfo = C_Texture.GetAtlasInfo( iconData.icon )
		if atlasInfo then
			icon.iconWidth = atlasInfo.width;
			icon.iconHeight = atlasInfo.height;
			icon.Highlight:SetAtlas( iconData.icon )
			icon.Icon:SetAtlas( iconData.icon )
		else
			icon.iconWidth = 32;
			icon.iconHeight = 32;
			icon.Icon:SetTexCoord( 0, 1, 0, 1 )
			icon.Icon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
			icon.Highlight:SetTexCoord( 0, 1, 0, 1 )
			icon.Highlight:SetTexture( "Interface/Icons/inv_misc_questionmark" )
		end
		
		icon:ResizeMapIcon( 0.7 )
		
		icon.id = i;
		icon.title = iconData.title;
		icon.icon = iconData.icon;
		icon.iconName = iconData.iconName;
		icon.description = iconData.description;
		icon.mapID = map;
		icon.zone = zone;
		icon.isWorldMapPin = true;
		
		HBDPins:AddWorldMapIconMap("DiceMasterMapIcon", icon, map, x, y, 1)
	end
end

-------------------------------------------------------------------------------
-- Initialize a new item button.
--
function Me.MapNode_Init( self )

	for k, v in pairs( methods ) do
		self[k] = v
	end
	 
	self:SetScript( "OnEnter", OnEnter )
	self:SetScript( "OnLeave", OnLeave ) 
	self:SetScript( "OnUpdate", OnUpdate )
	self:SetScript( "OnClick", OnClick )
	self:SetScript( "OnDragStart", OnDragStart )
	self:SetScript( "OnDragStop", OnDragStop )
	
	self:RegisterForDrag("LeftButton")
	self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
end