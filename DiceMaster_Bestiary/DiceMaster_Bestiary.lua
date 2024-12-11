-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Main module.
--

local VERSION = C_AddOns.GetAddOnMetadata( "DiceMaster_Bestiary", "Version" )
DiceMaster4_Bestiary = LibStub("AceAddon-3.0"):NewAddon( "DiceMaster_Bestiary", 
	             		  "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0" ) 
local Me = DiceMaster4_Bestiary
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

function Me:OnEnable()
	Me.SetupDB()
end