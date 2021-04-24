-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
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
		
		local data = TRP3_API.profile.getData("player").characteristics
		if data.FN and data.FN ~= "" then
			name = data.FN
			if data.LN and data.LN ~= "" then
				name = name .. " " .. data.LN
			end
		end
		if data.RA and data.RA ~= "" then race = data.RA end
		if data.CL and data.CL ~= "" then class = data.CL end
		if data.CH and data.CH ~= "" then class_color = "ff" .. data.CH:lower() end
		
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

function Me.GetTargetCharInfo()
	
	local name  = UnitName( "target" )
	local realm = GetRealmName()
	realm = realm:gsub( "[ -]", "" )
	
	if TRP3_API then
		-- Player is using TRP3.
		
		name = TRP3_API.chat.getFullnameForUnitUsingChatMethod( name.."-"..realm ) or UnitName("target")
		
	elseif AddOn_XRP then
		-- Player is using XRP.
		
		name = AddOn_XRP.Characters.byName[UnitName("target")]["NA"] or UnitName("target")
	elseif mrp then
		-- 2019 and still using mrp? x)))
		
		local data = msp.char[UnitName("target")].field
		if data.NA and data.NA ~= "" then name = data.NA end
		if data.RA and data.RA ~= "" then race = data.RA end
		if data.RC and data.RC ~= "" then class = data.RC end
	end
	
	-- strip colour escape sequences
	name = name:gsub( "|c%x%x%x%x%x%x%x%x", "" )
	name = name:gsub( "|r", "" )
	
	return name
end
