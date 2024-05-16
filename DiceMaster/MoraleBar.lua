-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Morale bar interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.MoraleBar_OnClick(self, button)

	if not Me.IsLeader( true ) then
		return
	end

	local delta = 0
	if button == "LeftButton" then
		delta = Profile.morale.step
	elseif button == "RightButton" then
		delta = -1 * ( Profile.morale.step )
	else
		return
	end

	if Me.OutOfRange( self.displayedValue + delta, 0, 100 ) then
		return
	end
	self.displayedValue = self.displayedValue + delta
	self.text:SetText(self.powerName.." "..self.displayedValue.."%")
	
	self:UpdateFill();
	Me.MoraleBar_ShareStatusWithParty()
end

function Me.MoraleBar_OnEnter( self )
	if not self.powerName then return end
	GameTooltip:SetOwner(self.fill, "ANCHOR_RIGHT")
	GameTooltip:SetText(self.powerName, 1, 1, 1);
	GameTooltip:AddLine(self.powerTooltip, nil, nil, nil, true);
	if Me.IsLeader( true ) then
		GameTooltip:AddLine("|cFF707070<Left/Right Click to Add/Remove "..self.powerName..">")
	end
	GameTooltip:Show();
	self.text:SetText(self.powerName.." "..self.displayedValue.."%")
	self.text:Show()
end

-------------------------------------------------------------------------------
-- Update the UI for the morale bar frame.
--
function Me.RefreshMoraleFrame( reset )
	
	if not Me.db.char.hidepanel and Profile.morale.enable then
		DiceMasterMoraleBar:Show()
	else
		DiceMasterMoraleBar:Hide()
	end
	
	if Me.IsLeader( false ) then
		DiceMasterMoraleBar:ApplyTextures(Profile.morale.symbol, Profile.morale.name, Profile.morale.tooltip, reset, Profile.morale.color, true)
		Me.MoraleBar_ShareStatusWithParty()
	end
end

function Me.MoraleBar_SetUp( self )
	self.Title = "Progress Bar"
	self:SetClampedToScreen( true )
	self:SetMovable(true)
	self:EnableMouse(true)
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	self:SetUserPlaced( true )
	self:RegisterEvent( "GROUP_ROSTER_UPDATE" )
	self:SetScript( "OnEvent", function( self, event )
		if event and Me.IsLeader( false ) then
			Me.MoraleBar_ShareStatusWithParty()
		end
	end)
		
	self:SetMinMaxPower( 0, 100 )
	
	self.isPercentage = true;
	
	if IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.IsLeader( false ) and not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		for i = 1, GetNumGroupMembers(1) do
			local name, rank = GetRaidRosterInfo(i)
			if rank == 2 then
				local msg = Me:Serialize( "MORREQ", {
					me = true;
				})
				Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "NORMAL" )
				break
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Send a MORALE message to the party.
--
function Me.MoraleBar_ShareStatusWithParty()
	if not Me.IsLeader( true ) or not IsInGroup( LE_PARTY_CATEGORY_HOME ) or IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	if Me.IsLeader( false ) then
		-- This is from the raid leader.
		local msg = Me:Serialize( "MORALE", {
			me = Profile.morale.enable;
			mn = Profile.morale.name;
			mv = DiceMasterMoraleBar.displayedValue;
			mt = Profile.morale.tooltip;
			ms = Profile.morale.symbol;
			mc = Profile.morale.color;
		})
		Me:SendCommMessage( "DCM4", msg, "RAID", nil, "NORMAL" )
	elseif DiceMasterMoraleBar:IsShown() then
		-- This is from a raid assistant.
		local msg = Me:Serialize( "MORALE", {
			me = true;
			mv = DiceMasterMoraleBar.displayedValue;
		})
		Me:SendCommMessage( "DCM4", msg, "RAID", nil, "NORMAL" )
	end
end

---------------------------------------------------------------------------
-- Received MORALE data.
-- 

function Me.MoraleBar_OnStatusMessage( data, dist, sender )

	-- Ignore our own data.
	if sender == UnitName( "player" ) then return end
 
	if data.me and data.mv then
		DiceMasterMoraleBar.displayedValue = tonumber(data.mv or 0);
		DiceMasterMoraleBar:UpdateFill();
	end
	
	-- sanitize message
	if not data.mn or not data.mv or not data.mt or not data.ms or not data.mc then
	   
		-- cover all those bases . . .
		return 
	end
	
	data.me = data.me or false; -- enabled
	data.mn = tostring(data.mn) -- name
	data.mv = tonumber(data.mv) -- value
	data.mt = tostring(data.mt) -- tooltip
	data.ms = tostring(data.ms) -- texture
	if #data.mc ~= 3 then data.mc = {1, 1, 1} end -- colour
	
	if not data.mn or not data.mv or not data.mt or not data.ms or not data.mc then
	   
		-- cover all those bases . . .
		return 
	end
	
	if data.me then
		Profile.morale.enable = true
		if not Me.db.char.hidepanel then
			DiceMasterMoraleBar:Show()
		end
	else
		Profile.morale.enable = false
		DiceMasterMoraleBar:Hide()
	end
	
	DiceMasterMoraleBar:ApplyTextures(data.ms, data.mn, data.mt, data.mv, data.mc, true)
end

---------------------------------------------------------------------------
-- Received MORREQ data.
-- 

function Me.MoraleBar_OnStatusRequest( data, dist, sender )

	-- Ignore our own data.
	if sender == UnitName( "player" ) then return end
 
	if Me.IsLeader( false ) then
		local msg = Me:Serialize( "MORALE", {
			me = Profile.morale.enable;
			mn = Profile.morale.name;
			mv = DiceMasterMoraleBar.displayedValue;
			mt = Profile.morale.tooltip;
			ms = Profile.morale.symbol;
			mc = Profile.morale.color;
		})
		Me:SendCommMessage( "DCM4", msg, "WHISPER", sender, "NORMAL" )
	end
end
