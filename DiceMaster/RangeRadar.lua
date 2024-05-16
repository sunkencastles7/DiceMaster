-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Range radar interface.
--

local Me = DiceMaster4
local updater
local activeDots = 0;
local activeRange = 0;
local dots = {}
local unitList = {}
local max, sin, cos, pi, pi2 = math.max, math.sin, math.cos, math.pi, math.pi * 2
local GetBestMapForUnit = C_Map.GetBestMapForUnit

local CLASS_TEX_COORDS = {
	["WARRIOR"]		 = { 0, 0.125, 0.5, 0.75 },
	["PALADIN"]		 = { 0.125, 0.25, 0.5, 0.75 },
	["HUNTER"]		 = { 0.25, 0.375, 0.5, 0.75 },
	["ROGUE"]		 = { 0.375, 0.5, 0.5, 0.75 },
	["PRIEST"]		 = { 0.5, 0.625, 0.5, 0.75 },
	["DEATHKNIGHT"]	 = { 0.625, 0.75, 0.5, 0.75 },
	["SHAMAN"]		 = { 0.75, 0.875, 0.5, 0.75 },
	["MAGE"]		 = { 0.875, 1, 0.5, 0.75 },
	["WARLOCK"]		 = { 0, 0.125, 0.75, 1 },
	["DRUID"]		 = { 0.25, 0.375, 0.75, 1 },
	["MONK"]		 = { 0.125, 0.25, 0.75, 1 },
	["DEMONHUNTER"]	 = { 0.375, 0.5, 0.75, 1 },
}

local function SetCompatibleRestrictedRange(range)
	if range <= 5 then
		range = 5
	elseif range <= 10 then
		range = 10
	elseif range <= 15 then
		range = 15
	elseif range <= 20 then
		range = 20
	elseif range <= 25 then
		range = 25
	elseif range <= 30 then
		range = 30
	elseif range <= 40 then
		range = 40
	elseif range <= 50 then
		range = 50
	elseif range <= 60 then
		range = 60
	elseif range <= 70 then
		range = 70
	elseif range <= 80 then
		range = 80
	elseif range <= 90 then
		range = 90
	elseif range <= 100 then
		range = 100
	elseif range > 100 then
		range = 100
	end
	return range
end

local function setDot(id, sinTheta, cosTheta)
	local dot = dots[id]
	local x = dots[id].x
	local y = dots[id].y
	local range = dots[id].range
	if range < ( activeRange * 1.05 ) then -- if person is in range, show the dot. Else hide it
		local dx = ((x * cosTheta) - (-y * sinTheta)) * pixelsperyard -- Rotate the X,Y based on player facing
		local dy = ((x * sinTheta) + (-y * cosTheta)) * pixelsperyard
		dot:ClearAllPoints()
		dot:SetPoint("CENTER", DiceMasterRangeRadar, "CENTER", dx, dy)
		if not dot:IsShown() then
			dot:Show()
		end
	elseif dot:IsShown() then
		dot:Hide()
	end
end

local function updateIcon()
	numPlayers = GetNumGroupMembers()
	activeDots = max(numPlayers, activeDots)
	for i = 1, activeDots do
		local dot = dots[i]
		if i <= numPlayers then
			unitList[i] = IsInRaid() and "raid"..i or "party"..i
			local uId = unitList[i]
			local _, class = UnitClass(uId)
			local icon = GetRaidTargetIndex(uId)
			dot.class = class
			class = class or "PRIEST"
			local c = RAID_CLASS_COLORS[ class ]
			dot.icon:SetTexture( 249183 )
			dot.icon:SetTexCoord( CLASS_TEX_COORDS[class][1], CLASS_TEX_COORDS[class][2], CLASS_TEX_COORDS[class][3], CLASS_TEX_COORDS[class][4] )
			dot:SetSize( 24, 24 )
			dot.icon:SetDrawLayer( "OVERLAY", 0 )
			dot.playerClass = c
			dot.playerName = UnitName( uId )
		elseif dot:IsShown() then
			dot:Hide()
		end
	end
end

local function updateRangeFrame()
	activeRange = DiceMasterRangeRadar.range
	if ( prevRange ~= activeRange ) then
		prevRange = activeRange
		pixelsperyard = min(DiceMasterRangeRadar:GetWidth(), DiceMasterRangeRadar:GetHeight()) / (activeRange * 3.7)
		DiceMasterRangeRadar.text:SetText( "Range Radar (" .. activeRange .. " yd)" )
	end

	local playerMapId = GetBestMapForUnit("player") or 0
	local rotation = pi2 - (GetPlayerFacing() or 0)
	local sinTheta = sin(rotation)
	local cosTheta = cos(rotation)
	local closePlayer = 0
	local closestRange = nil
	local closetName = nil
	for i = 1, numPlayers do
		local uId = unitList[i]
		local dot = dots[i]
		local mapId = GetBestMapForUnit(uId) or 0
		if UnitExists(uId) and playerMapId == mapId and not UnitIsUnit(uId, "player") and not UnitIsDeadOrGhost(uId) and UnitIsConnected(uId) then
			local range--Just set to a number in case any api fails and returns nil
			if restricted then--API restrictions are in play, so pretend we're back in BC
				print( "FAILED" )
				return
			else
				range = UnitDistanceSquared(uId) ^ 0.5
			end
			local inRange = false
			if range < ( activeRange ) then
				closePlayer = closePlayer + 1
				inRange = true
				if not closestRange then
					closestRange = range
				elseif range < closestRange then
					closestRange = range
				end
				if not closetName then closetName = UnitName( uId ) end
			end
			local playerX, playerY = UnitPosition( "player" )
			local x, y = UnitPosition( uId )
			if not x and not y then
				DiceMasterRangeRadar:Hide(true)
				return
			end
			local cy = x - playerX
			local cx = y - playerY
			dot.x = -cx
			dot.y = -cy
			dot.range = range
			setDot(i, sinTheta, cosTheta)
		elseif dot:IsShown() then
			dot:Hide()
		end
	end
end

function Me.RangeRadar_OnLoad( self )
	self:SetClampedToScreen( true )
	self:SetMovable( true )
	self:EnableMouse( true )
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	self:SetUserPlaced( true )
	
	updater = self:CreateAnimationGroup()
	updater:SetLooping("REPEAT")
	local anim = updater:CreateAnimation()
	anim:SetDuration(0.05)
	
	self:SetScript("OnEvent", function(self, event, ...)
		if event == "GROUP_ROSTER_UPDATE" or event == "RAID_TARGET_UPDATE" then
			updateIcon()
		end
	end)
	
	for i = 1, 40 do
		local dot = CreateFrame("Frame", "DiceMasterRangeRadarDot" .. i, self, nil)
		local dotImg = dot:CreateTexture( nil, "OVERLAY" )
		dot:SetSize( 24, 24 )
		dot:SetScript("OnEnter", function( self )
			GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
			GameTooltip:ClearLines()
			GameTooltip:AddLine( self.playerName or "", dot.playerClass.r or 1, dot.playerClass.g or 1, dot.playerClass.b or 1, true )
			GameTooltip:AddLine( ( math.floor( self.range ) or ">1000" ) .. " yd away", 1, 1, 1, true )
			GameTooltip:Show()
		end)
		dot:SetScript("OnLeave", function( self )
			GameTooltip:Hide()
		end)
		dot:SetScript( "OnUpdate", function( self )
			if GameTooltip:IsOwned( self ) then
				self:GetScript("OnEnter")( self )
			end
		end)
		dot.playerName = nil;
		dotImg:SetPoint("CENTER")
		dotImg:SetSize( 24, 24 )
		dotImg:SetTexture( 249183 )
		dot.icon = dotImg	   
		dot:Hide()
		dots[i] = dot
	end
end

function Me.RangeRadar_Show( range )
	range = SetCompatibleRestrictedRange( range )
	if not DiceMasterRangeRadar:IsShown() then
		DiceMasterRangeRadar:Show()
	end
	DiceMasterRangeRadar.range = range
	if not DiceMasterRangeRadar.eventRegistered then
		updateIcon()
		DiceMasterRangeRadar.eventRegistered = true;
		DiceMasterRangeRadar:RegisterEvent("GROUP_ROSTER_UPDATE")
		DiceMasterRangeRadar:RegisterEvent("RAID_TARGET_UPDATE")
	end
	updater:SetScript("OnLoop", updateRangeFrame)
	updater:Play()
end

function Me.RangeRadar_Hide()
	updater:Stop()
	activeRange = 0
	if DiceMasterRangeRadar.eventRegistered then
		DiceMasterRangeRadar.eventRegistered = nil
		DiceMasterRangeRadar:UnregisterAllEvents()
	end
	DiceMasterRangeRadar:Hide()
end