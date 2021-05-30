-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Main module.
--

local VERSION = GetAddOnMetadata( "DiceMaster", "Version" )
local Me = DiceMaster4
Me.version = VERSION
Me.Profile = {}

-------------------------------------------------------------------------------
-- Profile is a shortcut to Me.db.profile
setmetatable( Me.Profile, { 

	__index = function( table, key ) 
		return Me.db.profile[key]
	end;
	
	__newindex = function( table, key, value )
		Me.db.profile[key] = value
	end;
})

local Profile = Me.Profile

------------------------------------------------------------------------

local frame = CreateFrame("FRAME");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("GROUP_ROSTER_UPDATE");
frame:RegisterEvent("PARTY_LEADER_CHANGED");
frame:RegisterEvent("GROUP_LEFT");

function frame:OnEvent(event, arg1, ...)
	if event == "ADDON_LOADED" and arg1 == "DiceMaster_UnitFrames" then
		DiceMaster4UF_Saved = DiceMaster4UF_Saved or {}
		if DiceMaster4UF_Saved.VisibleFrames == 0 then DiceMaster4UF_Saved.VisibleFrames = 1 end
	end
	
	if IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		return
	end
	
	if event == "PARTY_LEADER_CHANGED" and IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.db.char.unitframes.enable then
		if Me.IsLeader( false ) then
			DiceMasterUnitsPanel:Show()
		else
			DiceMasterUnitsPanel:Hide()
		end
		Me.UpdateUnitFrames()
	end
	if event == "GROUP_ROSTER_UPDATE" and IsInGroup( LE_PARTY_CATEGORY_HOME ) and UnitIsGroupLeader("player") and not Me.db.char.unitframes.enable then
		Me.UpdateUnitFrames()
	end
	if event == "GROUP_LEFT" and not IsInGroup( LE_PARTY_CATEGORY_HOME ) and Me.IsLeader( false ) and not Me.db.char.unitframes.enable then
		local unitframes = DiceMasterUnitsPanel.unitframes
		for i=1,#unitframes do
			unitframes[i]:ClearModel()
			unitframes[i]:Reset()
			unitframes[i]:Hide()
		end
		DiceMasterUnitsPanel:Show()
		Me.UpdateUnitFrames(1)
	end
end

frame:SetScript("OnEvent", frame.OnEvent);

function Me.ApplyUiScaleUF()
	DiceMasterUnitsPanel:SetScale( Me.db.char.unitframes.scale * 1.4 )
	DiceMasterAffixEditor:SetScale( Me.db.char.uiScale * 1.4 )
	DiceMasterUnitFramesBuffEditor:SetScale( Me.db.char.uiScale * 1.4 )
	
	for i = 1,#DiceMasterUnitsPanel.unitframes do
		DiceMasterUnitsPanel.unitframes[i]:Collapse( Me.db.global.miniFrames )
	end
end

function Me.ShowUnitPanel( show )
	
	Me.db.char.unitframes.enable = not show
	
	if not show then
		DiceMasterUnitsPanel:Hide()
	else
		DiceMasterUnitsPanel:Show()
		if IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.IsLeader( false ) then
			for i=1, MAX_RAID_MEMBERS do
				local name, rank = GetRaidRosterInfo(i)
				if UnitIsGroupLeader( name ) then
					local msg = Me:Serialize( "UFREQ", "request")
					Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "ALERT" )
					break
				end
			end
		else
			Me.UpdateUnitFrames(1)
		end
	end

end
