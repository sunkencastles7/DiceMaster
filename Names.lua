-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4
 
-------------------------------------------------------------------------------
-- Get info about the character.
--
-- @returns name, race, class, class color
--
function Me.GetCharInfo()
	
	local name  = UnitName( "player" )
	local race  = UnitRace( "player" )
	local class, classID = UnitClass( "player" )
	local class_color = RAID_CLASS_COLORS[ classID ].colorStr
	
	if TRP3_API then
		-- Player is using TRP3.
		TRP3_API.events.listenToEvent(TRP3_API.events["REGISTER_PROFILES_LOADED"], function()
			name = msp.my["NA"] or name;
			DiceMasterChargesFrame.Name:SetText( name );
		end);
	elseif AddOn_XRP then
		-- Player is using XRP.
		
		name = AddOn_XRP.Characters.byName[UnitName("player")]["NA"] or UnitName("player")
		race = AddOn_XRP.Characters.byName[UnitName("player")]["RA"] or UnitRace("player")
		class = AddOn_XRP.Characters.byName[UnitName("player")]["RC"] or UnitClass("player")
	elseif mrp then
		-- 2019 and still using mrp? x)))
		
		local data = msp.char[UnitName("player")].field
		if data.NA and data.NA ~= "" then name = data.NA end
		if data.RA and data.RA ~= "" then race = data.RA end
		if data.RC and data.RC ~= "" then class = data.RC end
	end
	
	name = name:gsub( "|c%x%x%x%x%x%x%x%x", "" )
	name = name:gsub( "|r", "" )
	
	return name, race, class, class_color
end

function Me.GetTargetCharInfo( target )
	
	local name  = target or UnitName( "target" )
	local realm = GetRealmName()
	realm = realm:gsub( "[ -]", "" )
	
	if TRP3_API then
		-- Player is using TRP3.
		
		name = TRP3_API.chat.getFullnameForUnitUsingChatMethod( name.."-"..realm ) or name
		
	elseif AddOn_XRP then
		-- Player is using XRP.
		
		name = AddOn_XRP.Characters.byName[ name ]["NA"] or name
	elseif mrp then
		-- 2019 and still using mrp? x)))
		
		local data = msp.char[ name ].field
		if data.NA and data.NA ~= "" then name = data.NA end
		if data.RA and data.RA ~= "" then race = data.RA end
		if data.RC and data.RC ~= "" then class = data.RC end
	end
	
	-- strip colour escape sequences
	name = name:gsub( "|c%x%x%x%x%x%x%x%x", "" )
	name = name:gsub( "|r", "" )
	
	return name
end
