-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Main module.
--

local MAX_MAXHEALTH = 1000

local VERSION = C_AddOns.GetAddOnMetadata( "DiceMaster", "Version" )
DiceMaster4 = LibStub("AceAddon-3.0"):NewAddon( "DiceMaster", 
	             		  "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0" ) 
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
local EditModeExpanded = LibStub:GetLibrary("EditModeExpanded-1.0")
Me.EditModeFrames = {};

-------------------------------------------------------------------------------
-- Constants/Options
--

-- Guilds that may use this addon
local GUILDS_ALLOWED = {
	["The League of Lordaeron"] = true;
}

-------------------------------------------------------------------------------
-- Trait.usage modes.
--
local TRAIT_USAGE_MODES = {
	"USE1", "USE2", "USE3", "PASSIVE", "MANA1", "MANA2", "MANA3", "MANA4", "MANA5", "MANA6", "MANA7", "MANA8", "MANA9", "MANA10",
	"CHARGE1", "CHARGE2", "CHARGE3", "CHARGE4", "CHARGE5", "CHARGE6", "CHARGE7", "CHARGE8", "CHARGE9", "CHARGE10", "NONE"
}

-------------------------------------------------------------------------------
-- Trait.castTime modes.
--
local TRAIT_CAST_TIME_MODES = {
	"INSTANT", "CHANNELED", "TURN1", "TURN2", "TURN3", "TURN4", "TURN5"
}

-------------------------------------------------------------------------------
-- Trait.range modes.
--
local TRAIT_RANGE_MODES = {
	"NONE", "MELEE", "10YD", "20YD", "30YD", "40YD", "50YD", "60YD", "70YD", "80YD", "90YD", "100YD", "UNLIMITED"
}

-------------------------------------------------------------------------------
-- Trait.cooldown modes.
--
local TRAIT_COOLDOWN_MODES = {
	"NONE", "15S", "20S", "30S", "1M", "2M", "3M", "4M", "5M", "10M", "15M", "20M", "30M", "1H", "2H", "3H", "4H", "5H", "1D", "2D", "3D", "4D", "5D", "1W", "1T", "2T", "3T", "4T", "5T", "6T"
}

-- tuples for subbing text in description tooltips
local TOOLTIP_DESC_SUBS = {
	-- Icons
	{ "(%s)(%d+)%sHealth",      "%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" };  		-- e.g. "1 health"
	{ "(%s)(%d+)%sHP",      "%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" };      		-- e.g. "1 hp"
	{ "(%s)(%d+)%sArmo[u]*r",      "%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t" };		-- e.g. "1 armour"
	{ "(%s)(%d+)%sMana",      "%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/mana-gem:12|t" };  			-- e.g. "1 mana"
	{ "%<food%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:0:24:0:24|t" };			-- food icon
	{ "%<wood%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:24:48:0:24|t" };			-- wood icon
	{ "%<iron%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:48:72:0:24|t" };			-- iron icon
	{ "%<leather%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:72:96:0:24|t" };		-- leather icon
	-- Tags
	{ "<rule>",		" |n|TInterface/RAIDFRAME/Raid-HSeparator:8:220|t" };												-- <rule>
	{ "(%s)(%d*)%s*<HP>",		"%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" };		-- <HP>
	{ "(%s)(%d*)%s*<AR>",		"%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t" };			-- <AR>
	{ "(%s)(%d*)%s*<MP>",		"%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/mana-gem:12|t" };			-- <MP>
	{ "%<%*%>",		"|TInterface/Transmogrify/transmog-tooltip-arrow:8|t" };										-- <*>
	-- Dice
	{ "%s?[+]%d+",           "|cFF00FF00%1|r" };                                                        			-- e.g. "+1"
	{ "%s?[-]%d+",           "|cFFFF0000%1|r" };                                                       				-- e.g. "-3"
	{ "%s%d*[dD]%d+[+-]?%d*", "|cFFFFFFFF%1|r" };                                                     				-- dice rolls e.g. "1d6" 
}

StaticPopupDialogs["DICEMASTER4_SETHEALTHVALUE"] = {
  text = "Set Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(data.health)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or data.health
	text = math.floor( text )
	if Me.OutOfRange( text, 0, data.healthMax ) then
		return
	end
	if text > data.health then
		Me.SecretEditor_OnEvent( "PLAYER_HEALED" )
	end
	data.health = text
	local frame = DiceMasterChargesFrame
	if data == Profile.pet then
		frame = DiceMasterPetChargesFrame
	end
	Me.RefreshHealthbarFrame( frame.healthbar, data.health, data.healthMax, data.armor )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty() 
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_SETHEALTHMAX"] = {
  text = "Set maximum Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(data.healthMax)
	self.editBox:SetNumeric()
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or data.healthMax
	text = math.floor( text )
	if Me.OutOfRange( text, 1, 1000 ) then
		return
	end
	data.healthMax = text
	if data.health > data.healthMax then 
		data.health = data.healthMax 
	end
	local frame = DiceMasterChargesFrame
	if data == Profile.pet then
		frame = DiceMasterPetChargesFrame
	end
	Me.RefreshHealthbarFrame( frame.healthbar, data.health, data.healthMax, data.armor )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty() 
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_SETMANAVALUE"] = {
  text = "Set Mana value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
	local manaType = Profile.manaType or "Mana";
	if manaType == "RunicPower" then manaType = "Runic Power" end
	self.text:SetText( "Set " .. manaType .. " value:" );
    self.editBox:SetText(data.mana)
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or data.mana
	text = math.floor( text )
	if Me.OutOfRange( text, 0, data.manaMax ) then
		return
	end
	data.mana = text
	local frame = DiceMasterChargesFrame
	Me.RefreshManabarFrame( frame.manabar, data.mana, data.manaMax )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty() 
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_SETMANAMAX"] = {
  text = "Set maximum Mana value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
	local manaType = Profile.manaType or "Mana";
	if manaType == "RunicPower" then manaType = "Runic Power" end
	self.text:SetText( "Set maximum " .. manaType .. " value:" );
    self.editBox:SetText(data.manaMax)
	self.editBox:SetNumeric()
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tonumber(self.editBox:GetText()) or data.manaMax
	text = math.floor( text )
	if Me.OutOfRange( text, 1, 1000 ) then
		return
	end
	data.manaMax = text
	if data.mana > data.manaMax then 
		data.mana = data.manaMax 
	end
	local frame = DiceMasterChargesFrame
	if data == Profile.pet then
		frame = DiceMasterPetChargesFrame
	end
	Me.RefreshManabarFrame( frame.manabar, data.mana, data.manaMax )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty() 
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}
 
-------------------------------------------------------------------------------
 
Me.traitCount  = 5
Me.TRAIT_USAGE_MODES = TRAIT_USAGE_MODES
Me.TRAIT_CAST_TIME_MODES = TRAIT_CAST_TIME_MODES
Me.TRAIT_RANGE_MODES = TRAIT_RANGE_MODES
Me.TRAIT_COOLDOWN_MODES = TRAIT_COOLDOWN_MODES
 
-------------------------------------------------------------------------------
-- Misc helper functions
-------------------------------------------------------------------------------
function Me.Clamp( a, min, max )
	return math.min( math.max( a, min ), max )
end

-------------------------------------------------------------------------------
function Me.OutOfRange( a, min, max )
	return a < min or a > max
end

---------------------------------------------------------------------------
-- Get the GUID identifier for a given unit.
--

local function GetUnitGUID( unit )
	local guid = UnitGUID( unit )
	if not( guid ) then
		return;
	end
	if not( string.find( guid, "-" ) ) then
		return guid;
	end
	
	local guidType, realmID, unitID = strsplit( "-", guid );
	return unitID;
end

---------------------------------------------------------------------------
-- Generate a unique GUID identifier.
--

function Me.GenerateGUID()
	local lastTime;
	local guid;
	
	if not (guid) then
		guid = string.gsub(string.gsub(GetUnitGUID("player"), "0x..", ""), "00[0]*", "")
	end

	local t = time();
	if t == 0 and not(lastTime) then
		t = random(100000);
	else
		t = t - 1315000000;
	end

	if lastTime and t <= lastTime then
		t = lastTime + 1;
	end
	lastTime = t;

	local hashTime = string.format("%X", t)
	
	return guid .. "_" .. hashTime;
end

-------------------------------------------------------------------------------
-- Check to see if the player is in the League of Lordaeron.
--
-- @returns true if the player is in the League.
--
function Me.PermittedUse() 
	
	if Me.backdoor then 
		-- if you're reading this, you can probably bypass this just as easily :)
		return true 
	end
	
	local guildName = GetGuildInfo("player")
	if GUILDS_ALLOWED[guildName] then
		return true
	end
end

-------------------------------------------------------------------------------
-- Check to see if the player is an officer.
--
-- @returns true if the player is an officer.
--
function Me.IsOfficer()
	local guildName, guildRankName, guildRankIndex = GetGuildInfo( "player" )
	
	if Me.PermittedUse() and guildRankIndex < 4 then
		return true
	end
	return false
end

-------------------------------------------------------------------------------
-- Check to see if the player is the group leader.
--
-- @returns true if the player is the leader.
--
function Me.IsLeader( allowAssistant )
	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		return true
	end
	
	if allowAssistant and ( UnitIsGroupAssistant("player", 1) ) then
		return true
	end
	
	if UnitIsGroupLeader("player", 1) then
		return true
	end
end

-------------------------------------------------------------------------------
-- Print a "system" message in all chat frames with the designated channel.
--
-- @param msg		Message to print.
-- @param channel	Required chat channel to check for.
--					(nil if all chat frames should be used)
--
function Me.PrintMessage( msg, channel )

	local info = ChatTypeInfo["SYSTEM"]
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i]
		
		if frame then
		
			-- well this seems fairly nasty
			local registered = {GetChatWindowMessages(i)}
			 
			for _,v in ipairs(registered) do
				if not channel or v == channel then
				 
					frame:AddMessage( msg, info.r, info.g, info.b )
					break;
				end
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Handler for showing tooltips for frames that have used SetupTooltip.
--
local function OnEnterTippedButton(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

	-- Standard DICEMASTER tooltip layout:
	--
	-- [Icon] Name
	--
	-- Cost         Range
	--
	-- Cast Time		Cooldown
	--
	-- Description
	--
	
    if self.tooltipTexture then
		-- icon with name
        DiceMasterTooltipIcon.icon:SetTexture( self.tooltipTexture )
		DiceMasterTooltipIcon:Show()
    else
        DiceMasterTooltipIcon:Hide()
    end
	
	GameTooltip:AddLine(self.tooltipText, 1, 1, 1, true)
	 
    GameTooltip:AddDoubleLine(self.tooltipText2a, self.tooltipText2b, 1, 1, 1, 1, 1, 1, true)
	 
    GameTooltip:AddDoubleLine(self.tooltipText3, self.tooltipText3b, 1, 1, 1, 1, 1, 1, true)
	 
	if self.tooltipText4 then
		GameTooltip:AddLine( Me.FormatDescTooltip( self.tooltipText4 ), 1, 0.81, 0, true)
	end
	
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- "Leave" handler for tool tipped frame.
--
local function OnLeaveTippedButton()
	DiceMasterTooltipIcon:Hide()
    GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Setup the enter/leave scripts for a frame.
--
-- @param texture     Icon to use next to tooltip name.
-- @param spellname   Name of spell or generic text at the top.
-- @param cost        Cost of spell or generic text under the name.
-- @param range       Range of spell or generic text under the name to the right.
-- @param casttime    Cast time of spell or generic text under cost.
-- @param cooldown    Cooldown time of spell or generic text to the right.
-- @param description Description of spell or generic tooltip description.
--
-- In essence, the tooltip is layed out like a normal spell tooltip.
--
function Me.SetupTooltip(self, texture, spellname, cost, range, 
                        casttime, cooldown, description)
						
    if spellname then
	
        self.tooltipTexture = texture
        self.tooltipText = spellname
        self.tooltipText2a = cost
        self.tooltipText2b = range
        self.tooltipText3 = casttime
        self.tooltipText3b = cooldown
        self.tooltipText4 = description
        self:SetScript( "OnEnter", OnEnterTippedButton )
        self:SetScript( "OnLeave", OnLeaveTippedButton )
    else
        self:SetScript("OnEnter", nil)
        self:SetScript("OnLeave", nil)
    end
end

-------------------------------------------------------------------------------
-- Increment a serial number.
--
-- @param table Table that houses the serial, e.g. Me or a trait
-- @param key   Name of the serial number, e.g. "serial" or "statusSerial"
--
function Me.BumpSerial( table, key )
	table[key] = (table[key] % 32768) + 1
end


-------------------------------------------------------------------------------
-- Convert trait usage number into text.
--
-- @param usage Usage index.
-- @param name  Name of person this is associated to. It's used to get the name
--              of their charges. Default=player's name
--
local TRAIT_USAGE = {
	["USE1"] = "1 Use"; ["USE2"] = "2 Uses"; ["USE3"] = "3 Uses";
	["PASSIVE"] = "Passive";
	["MANA1"] = "1 Mana"; ["MANA2"] = "2 Mana"; ["MANA3"] = "3 Mana";
	["MANA4"] = "4 Mana"; ["MANA5"] = "5 Mana"; ["MANA6"] = "6 Mana";
	["MANA7"] = "7 Mana"; ["MANA8"] = "8 Mana"; ["MANA9"] = "9 Mana";
	["MANA10"] = "10 Mana";
	["CHARGE1"] = "1 &cs"; ["CHARGE2"] = "2 &cp"; ["CHARGE3"] = "3 &cp";
	["CHARGE4"] = "4 &cp"; ["CHARGE5"] = "5 &cp"; ["CHARGE6"] = "6 &cp";
	["CHARGE7"] = "7 &cp"; ["CHARGE8"] = "8 &cp"; ["CHARGE9"] = "9 &cp"; 
	["CHARGE10"] = "10 &cp";
	["NONE"] = "(None)"
}

function Me.FormatUsage( usage, name )
	name = name or UnitName("player")
	
	local text = TRAIT_USAGE[usage] or "<Unknown Usage>"
	
	local plural_charges, singular_charges = Me.inspectData[name].charges.name:match( "^%s*(.*)/(.*)%s*$" )
	if not singular_charges then
		plural_charges   = Me.inspectData[name].charges.name
		singular_charges = plural_charges
		singular_charges = singular_charges:gsub( "[Ss]$", "" ) -- clip off an S :)
	end
	-- sub charges
	text = text:gsub( "&cs", singular_charges )
	text = text:gsub( "&cp", plural_charges )
	
	local manaType = Profile.manaType or "Mana";
	if manaType == "RunicPower" then manaType = "Runic Power" end
	-- sub mana
	text = text:gsub( "Mana", manaType );
	return text
end

-------------------------------------------------------------------------------
-- Convert trait cast time number into text.
--
-- @param castTime 	Cast Time index.
--
local TRAIT_CAST_TIME = {
	["INSTANT"] = "Instant"; ["CHANNELED"] = "Channeled"; ["TURN1"] = "1 turn cast"; ["TURN2"] = "2 turns cast"; ["TURN3"] = "3 turns cast"; ["TURN4"] = "4 turns cast"; ["TURN5"] = "5 turns cast";
}

function Me.FormatCastTime( castTime )
	local text = TRAIT_CAST_TIME[castTime] or "Instant"
	return text
end

-------------------------------------------------------------------------------
-- Convert trait range number into text.
--
-- @param range 	Range index.
--
local TRAIT_RANGE = {
	["NONE"] = "(None)"; ["MELEE"] = "Melee Range";  ["10YD"] = "10 yd range"; ["20YD"] = "20 yd range"; ["30YD"] = "30 yd range"; ["40YD"] = "40 yd range"; ["50YD"] = "50 yd range"; ["60YD"] = "60 yd range"; ["70YD"] = "70 yd range"; ["80YD"] = "80 yd range"; ["90YD"] = "90 yd range"; ["100YD"] = "100 yd range"; ["UNLIMITED"] = "Unlimited range"; 
}

function Me.FormatRange( range )	
	local text = TRAIT_RANGE[range] or ""
	return text
end

-------------------------------------------------------------------------------
-- Convert trait cooldown number into text.
--
-- @param cooldown 		Cooldown index.
--
local TRAIT_COOLDOWN = {
	["NONE"] = "(None)"; ["15S"] = "15 sec"; ["20S"] = "20 sec"; ["30S"] = "30 sec"; ["1M"] = "1 min"; ["2M"] = "2 min"; ["3M"] = "3 min"; ["4M"] = "4 min"; ["5M"] = "5 min"; ["10M"] = "10 min"; ["15M"] = "15 min"; ["20M"] = "20 min"; ["30M"] = "30 min"; ["1H"] = "1 hour"; ["2H"] = "2 hour"; ["3H"] = "3 hour"; ["4H"] = "4 hour"; ["5H"] = "5 hour"; ["1D"] = "1 day"; ["2D"] = "2 day"; ["3D"] = "3 day"; ["4D"] = "4 day"; ["5D"] = "5 day"; ["1W"] = "1 week"; ["1T"] = "1 turn"; ["2T"] = "2 turn"; ["3T"] = "3 turn"; ["4T"] = "4 turn"; ["5T"] = "5 turn"; ["6T"] = "6 turn";
}

function Me.FormatCooldown( cooldown )	
	local text = TRAIT_COOLDOWN[cooldown] or ""
	if ( cooldown ~= "NONE" and text ~= "" ) then
		text = text .. " cooldown"
	end
	return text
end

-------------------------------------------------------------------------------
-- Get the texture coordinates for an icon by id.
--
-- @param iconID 	Index of the icon in the texture.
--

function Me.GetIconTexCoord( iconID )
	if not iconID then
		return 0, 0, 0, 0;
	end

	local columns = 8
	local l = mod(iconID, columns) * 32
	local r = l + 32
	local t = floor(iconID/columns) * 32
	local b = t + 32
	return l/256, r/256, t/256, b/256;
end

-------------------------------------------------------------------------------
-- Convert icon id into path (for text).
--
-- @param iconID 	Index of the icon in the texture.
--

function Me.FormatIconForText( iconID )
	if not iconID then
		return "";
	end

	local columns = 8
	local l = mod(iconID, columns) * 32
	local r = l + 32
	local t = floor(iconID/columns) * 32
	local b = t + 32
	local path = "|TInterface/AddOns/DiceMaster/Texture/conditions:16:16:0:0:256:256:"..l..":"..r..":"..t..":"..b.."|t"
	return path;
end

-------------------------------------------------------------------------------
-- Add color codes to a trait description tooltip.
--
-- @param text Text to format.
-- @returns formatted text.
--
function Me.FormatDescTooltip( text, name, traitIndex )
	name = name or UnitName("player")
	traitIndex = traitIndex or nil
	
	for k, v in pairs( Me.RollList ) do
		for i = 1, #v do
			if v[i].subName then
				text = gsub( text, "<(" .. v[i].subName .. ")>", "|cFFFFFFFF%1|r" )
			end
		end
	end
	
	for k, v in pairs( Me.TermsList ) do
		for i = 1, #v do
			if v[i].subName then
				text = gsub( text, "<(" .. v[i].subName .. ")>", "|cFFFFFFFF%1|r" )
			end
		end
	end

	for k, v in ipairs( TOOLTIP_DESC_SUBS ) do
		text = gsub( text, v[1], v[2] )
	end
	
	-- <img> </img>
	text = gsub( text, "<img>","|T" )
	text = gsub( text, "</img>",":16|t" )
	
	-- <color=rrggbb> </color>
	text = gsub( text, "<color=(.-)>","|cFF%1" )
	text = gsub( text, "</color>","|r" )
	
	-- Secrets!
	for i = 1,3 do
		if ( Me.PermittedUse() and Me.IsOfficer() ) or name == UnitName("player") or ( traitIndex and Me.inspectData[name].traits[traitIndex]["secret"..tostring(i).."Active"] ) then
			text = gsub( text, "<secret"..tostring(i)..">(.-)</secret"..tostring(i)..">","|TInterface/AddOns/DiceMaster/Texture/secret-icon:12|t |cFFFFFFFFSecret!|r |cFFFF7EFF%1|r" )
		else
			text = gsub( text, "<secret"..tostring(i)..">.-</secret"..tostring(i)..">","|TInterface/AddOns/DiceMaster/Texture/secret-icon:12|t |cFFFFFFFFSecret!|r |cFF707070This secret is revealed when activated by a specific condition.|r" )
		end
	end
	
	-- Remove extra spaces/lines at the beginning/end.
	text = gsub( text, "^%s*(.-)%s*$", "%1" )

	return text
end

-------------------------------------------------------------------------------
-- Setup the trait buttons on the dice panel.
--

function Me.UpdatePanelTraits()
	local traits = DiceMasterChargesFrame.traits
	for i=1,#traits do
		traits[i]:SetPlayerTrait( UnitName( "player" ), i )
	end
	DiceMasterPanelDice:SetText(Profile.dice)
end

-------------------------------------------------------------------------------
-- Setup the enter/leave scripts for a trait button.
--
function Me.SetupTraitTooltip( button, trait, editable )
	button.tooltip_trait = trait
	button.tooltip_trait_edit = true
	button:SetScript( "OnEnter", OnEnterTraitButton )
	button:SetScript( "OnLeave", OnLeaveTippedButton )
end

-------------------------------------------------------------------------------
-- When the healthbar frame is clicked.
--
function Me.OnHealthClicked( button, isPet )
	local store = Profile
	local frame = DiceMasterChargesFrame
	if isPet then
		store = Profile.pet
		frame = DiceMasterPetChargesFrame
	end
	
	local delta = 0
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	  	
	if IsShiftKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETHEALTHMAX", nil, nil, store)
	elseif IsControlKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETHEALTHVALUE", nil, nil, store)
	elseif IsAltKeyDown() then
		if Me.OutOfRange( store.armor+delta, 0, 1000 ) then
			return
		end
		store.armor = store.armor + delta;
	else
		if delta == 1 then
			Me.SecretEditor_OnEvent( "PLAYER_HEALED" )
		end
		if Me.OutOfRange( store.health+delta, 0, store.healthMax ) then
			return
		end
		store.health = Me.Clamp( store.health + delta, 0, store.healthMax )
	end
	
    Me.RefreshHealthbarFrame( frame.healthbar, store.health, store.healthMax, store.armor )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

-------------------------------------------------------------------------------
-- Update the UI for the healthbar frame.
--
function Me.RefreshHealthbarFrame( self, healthValue, healthMax, armorValue )
	self:SetMinMaxValues( 0, healthMax );
	self:SetValue( healthValue );
	
	self.Text:SetText( healthValue.." / "..healthMax )
	
	if self:GetParent() == DiceMasterChargesFrame then
		Me.RefreshHealthbarFrameAlt( healthValue, healthMax, armorValue )
	end
	
	if armorValue and armorValue > 0 then
		self.Text:SetText( healthValue.." (+"..armorValue..") / "..healthMax )
		
		local maxWidth = self:GetWidth() - 2;
		local adjustedValue = Me.Clamp( armorValue + healthValue, 0, healthMax );
		local barSize = ( adjustedValue / healthMax ) * maxWidth
		self.Armor:SetWidth( barSize );
		self.ArmorOverlay:SetWidth( barSize );
		self.Armor:Show();
		self.ArmorOverlay:Show();
	else
		self.Armor:Hide()
		self.ArmorOverlay:Hide()
	end
	
	if armorValue and armorValue > 0 and armorValue + healthValue > healthMax then
		self.ArmorGlow:Show()
	else
		self.ArmorGlow:Hide()
	end
	
	if self == DiceMasterChargesFrame.healthbar and healthValue == 0 then
		Me.SecretEditor_OnEvent( "PLAYER_KNOCKOUT" )
	end
end

-------------------------------------------------------------------------------
-- Update the UI for the /ALT/ healthbar frame.
--
function Me.RefreshHealthbarFrameAlt( healthValue, healthMax, armorValue )
	-- if Me.db.global.healthIcons then
		-- DiceMasterChargesFrameAlt.text:SetText( healthValue )
		
		-- if healthValue < healthMax then
			-- DiceMasterChargesFrameAlt.text:SetTextColor( 1, 0, 0 )
		-- else
			-- DiceMasterChargesFrameAlt.text:SetTextColor( 1, 1, 1 )
		-- end
		
		-- if armorValue and armorValue > 0 then
			-- DiceMasterChargesFrameAlt.armour:Show()
			-- DiceMasterChargesFrameAlt.armourText:SetText( armorValue )
		-- else
			-- DiceMasterChargesFrameAlt.armour:Hide()
			-- DiceMasterChargesFrameAlt.armourText:SetText( "" )
		-- end
		-- DiceMasterChargesFrameAlt:Show();
	-- else
		DiceMasterChargesFrameAlt:Hide();
	-- end
end

-------------------------------------------------------------------------------
-- When the manabar frame is clicked.
--
function Me.OnManaClicked( button )
	local store = Profile
	local frame = DiceMasterChargesFrame
	
	local delta = 0
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	  	
	if IsShiftKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETMANAMAX", nil, nil, store)
	elseif IsControlKeyDown() and button == "LeftButton" then
		-- Open dialog for custom value.
		StaticPopup_Show("DICEMASTER4_SETMANAVALUE", nil, nil, store)
	else
		if Me.OutOfRange( store.mana+delta, 0, store.manaMax ) then
			return
		end
		store.mana = Me.Clamp( store.mana + delta, 0, store.manaMax )
	end
	
    Me.RefreshManabarFrame( frame.manabar, store.mana, store.manaMax )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

-------------------------------------------------------------------------------
-- Update the UI for the manabar frame.
--
function Me.RefreshManabarFrame( self, manaValue, manaMax )
	self:SetMinMaxValues( 0, manaMax );
	self:SetValue( manaValue );
	
	self.Text:SetText( manaValue.." / "..manaMax )
	
	if self:GetParent() == DiceMasterChargesFrame then
		Me.RefreshManabarFrameAlt( manaValue, manaMax )
	end
end

-------------------------------------------------------------------------------
-- Update the UI for the /ALT/ manabar frame.
--
function Me.RefreshManabarFrameAlt( manaValue, manaMax )
	-- if Me.db.global.healthIcons then
		-- DiceMasterManaFrameAlt.text:SetText( manaValue )
		-- DiceMasterManaFrameAlt:Show();
	-- else
		DiceMasterManaFrameAlt:Hide();
	-- end
end

-------------------------------------------------------------------------------
-- When the charges frame is clicked.
--
function Me.OnChargesClicked( button )
	if button == "LeftButton" then
		if Profile.charges.count == Profile.charges.max then return end
		Profile.charges.count = Profile.charges.count + 1
	elseif button == "RightButton" then
		if Profile.charges.count == 0 then return end
		Profile.charges.count = Profile.charges.count - 1
	end
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	
	Me.RefreshChargesFrame()
	Me.Inspect_ShareStatusWithParty() 
end

-------------------------------------------------------------------------------
-- Update the UI for the charges frame.
--
function Me.RefreshChargesFrame( tooltip, color )
	
	if not Me.db.char.hidepanel then
		DiceMasterChargesFrame:Show()
		if Profile.charges.enable then
			if not Profile.charges.symbol:find("charge") then
				DiceMasterChargesFrame.bar:Hide()
				DiceMasterChargesFrame.bar2:Show()
			else
				DiceMasterChargesFrame.bar:Show()
				DiceMasterChargesFrame.bar2:Hide()
			end
			-- Check charges position setting:
			if Profile.charges.pos then
				DiceMasterChargesFrame:SetHeight( 120 );
				DiceMasterChargesFrame.bar:SetPoint("BOTTOM", 0, -50)
				DiceMasterChargesFrame.bar2:SetPoint("BOTTOM", 0, -50)
			else
				DiceMasterChargesFrame:SetHeight( 120 );
				DiceMasterChargesFrame.bar:SetPoint("BOTTOM", 0, 170)
				DiceMasterChargesFrame.bar2:SetPoint("BOTTOM", 0, 80)
			end
		else
			DiceMasterChargesFrame.bar:Hide()
			DiceMasterChargesFrame.bar2:Hide()
		end
	else
		DiceMasterChargesFrame:Hide()
	end
	
	if tooltip then
		local chargesPlural = Profile.charges.name:gsub( "/.*", "" )
		Me.SetupTooltip( DiceMasterChargesFrame.bar, nil, chargesPlural, 
			nil, nil, nil, nil,
			Profile.charges.tooltip.."|n|cFF707070<Left Click to Add "..chargesPlural..">|n"
			.."<Right Click to Remove "..chargesPlural..">")
	end
	
	if color then
		DiceMasterChargesFrame.bar:SetTexture( 
			"Interface/AddOns/DiceMaster/Texture/"..Profile.charges.symbol or "Interface/AddOns/DiceMaster/Texture/charge-orb", 
			Profile.charges.color[1], Profile.charges.color[2], Profile.charges.color[3] )
	end
	
	-- Check for an Interface path.
	if not Profile.charges.symbol:find("charge") then
		local chargesPlural = Profile.charges.name:gsub( "/.*", "" )
		DiceMasterChargesFrame.bar2:SetMinMaxPower( 0, Profile.charges.max )
		DiceMasterChargesFrame.bar2:ApplyTextures( Profile.charges.symbol, Profile.charges.name, Profile.charges.tooltip .. "|n|cFF707070<Left Click to Add " .. chargesPlural .. ">|n" .. "<Right Click to Remove " .. chargesPlural .. ">", Profile.charges.count, Profile.charges.color, Profile.charges.flash )
		DiceMasterChargesFrame.bar2.text:SetText( Profile.charges.count .. "/" .. Profile.charges.max )
	end
	
	if Profile.manaType then
		local statusBarTexture = DiceMasterChargesFrame.manabar:GetStatusBarTexture()
		if Profile.manaType == "None" then
			DiceMasterChargesFrame.manabar:Hide();
		else
			statusBarTexture:SetAtlas( "UI-HUD-UnitFrame-Player-PortraitOff-Bar-" .. Profile.manaType );
			DiceMasterChargesFrame.manabar:Show();
		end
	end
	
	DiceMasterChargesFrame.bar:SetMax( Profile.charges.max ) 
	DiceMasterChargesFrame.bar:SetFilled( Profile.charges.count ) 
	
	DiceMasterChargesFrame.bar2:UpdateFill();
end

-------------------------------------------------------------------------------
-- Update the UI for the pet frame.
--
function Me.RefreshPetFrame()
	if Profile.pet.enable and not Me.db.char.hidepanel then
		DiceMasterPetChargesFrame.Name:SetText( Profile.pet.name )
		SetPortraitTextureFromCreatureDisplayID( DiceMasterPetChargesFrame.Portrait, Profile.pet.model )
		Me.SetupTooltip( DiceMasterPetChargesFrame, Profile.pet.icon, Profile.pet.name, Profile.pet.type )
		DiceMasterPetChargesFrame:Show()
	else
		DiceMasterPetChargesFrame:Hide()
	end
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
end

-------------------------------------------------------------------------------

local TRAIT_COOLDOWN_TIMES = {
	["15S"] = 15; ["20S"] = 20; ["30S"] = 30; ["1M"] = 60; ["2M"] = 120; ["3M"] = 180; ["4M"] = 240; ["5M"] = 300; ["10M"] = 600; ["15M"] = 900; ["20M"] = 1200; ["30M"] = 1800; ["1H"] = 3600; ["2H"] = 7200; ["3H"] = 10800; ["4H"] = 14400; ["5H"] = 18000; ["1D"] = 86400; ["2D"] = 172800; ["3D"] = 259200; ["4D"] = 345600; ["5D"] = 432000; ["1W"] = 604800;
}

local function updateTraitUses( traitButton )
	local traitIndex = traitButton.traitIndex
	local trait = Profile.traits[ traitIndex ]
	local usage = trait.usage or "PASSIVE";
	
	if usage == "PASSIVE" or traitButton.cooldown:GetCooldownDuration() > 0 or traitButton.cooldown.text:IsShown() or not Me.db.global.showUses then
		return
	end
	
	if usage:find("USE") then
		local usesTotal = usage:gsub("USE", "")
		local usesLeft = traitButton.count:GetText() or 0
		usesLeft = tonumber( usesLeft )
		if usesLeft > 0 then
			usesLeft = usesLeft - 1
			traitButton.count:SetText( usesLeft )
		end
		if usesLeft == 0 then
			traitButton.icon:SetVertexColor( 0.5, 0.5, 0.5 )
			traitButton.notCastable = true;
		end
	elseif usage:find("CHARGE") then
		local chargesSpent = usage:gsub("CHARGE", "")
		chargesSpent = tonumber( chargesSpent )
		if Profile.charges.count >= chargesSpent then
			Profile.charges.count = Profile.charges.count - chargesSpent
			
			Me.BumpSerial( Me.db.char, "statusSerial" )
			
			Me.RefreshChargesFrame()
			Me.Inspect_ShareStatusWithParty()
		end
	end
end

local function updateMana( traitButton )
	local traitIndex = traitButton.traitIndex
	local trait = Profile.traits[ traitIndex ]
	local usage = trait.usage or "PASSIVE";
	
	if usage:find("MANA") then
		local manaSpent = usage:gsub("MANA", "")
		manaSpent = tonumber( manaSpent )
		Profile.mana = Me.Clamp( Profile.mana - manaSpent, 0, Profile.manaMax )
		local frame = DiceMasterChargesFrame
		Me.RefreshManabarFrame( frame.manabar, Profile.mana, Profile.manaMax )
		
		Me.BumpSerial( Me.db.char, "statusSerial" )
		Me.Inspect_ShareStatusWithParty() 
	end
end

local EffectHandlers = {
	["book"] 	= "BookFrame_Show";
	["script"]	= "ScriptEditor_RunScript";
	["message"]	= "MessageEditor_SendMessage";
	["produce"]	= "ProduceItemEditor_ProduceItem";
	["consume"]	= "ConsumeItemEditor_ConsumeItem";
	["currency"] = "ProduceCurrencyEditor_ProduceCurrency";
	["buff"]	= "BuffFrame_CastBuff";
	["removebuff"]	= "BuffFrame_RemoveBuff";
	["setdice"]	= "BuffFrame_RollDice";
	["effect"]	= "EffectPicker_PlayEffect";
	["screeneffect"] = "ScreenEffectEditor_PlayEffect";
	["sound"]	= "SoundPicker_PlaySound";
	["health"] = "AdjustHealthEditor_AdjustHealth",
	["secret"] = "SecretEditor_EnableSecret",
}

local function ExecuteEffects( effects, traitIndex )
	if not effects then
		return
	end
	
	for key, effect in pairs( effects ) do
		local handler = EffectHandlers[key]
		if Me[handler] then
			if effect.delay and effect.delay > 0 then
				C_Timer.After( effect.delay, function() Me[handler]( traitIndex ) end )
			else
				Me[handler]( traitIndex )
			end
		end
	end
	
	Me.SecretEditor_OnEvent( "PLAYER_USE_TRAIT", Profile.traits[traitIndex].name )
end

function Me.TraitButtonClicked( traitButton, button )
	if button == "LeftButton" then
		Me.TraitEditor_Open()
		DiceMasterTraitEditorTab1:Click()
		DiceMaster4.TraitEditor_StartEditing( traitButton.traitIndex )
	elseif button == "RightButton" then
		local cooldown = Profile.traits[ traitButton.traitIndex ].cooldown or "NONE";
		local hasCost = string.find( Profile.traits[ traitButton.traitIndex ].usage, "MANA" )
		
		if ( hasCost ) then
			local cost = gsub( Profile.traits[ traitButton.traitIndex ].usage, "MANA", "" )
			cost = tonumber( cost )
			if cost > Profile.mana then
				updateTraitUses( traitButton )
				PlaySound(1428)
				UIErrorsFrame:AddMessage( "Not enough mana", 1.0, 0.0, 0.0 ); 
				return
			else
				updateMana( traitButton )
			end
		end
		
		if cooldown ~= "NONE" then
			if traitButton.cooldown:GetCooldownDuration() == 0 and not traitButton.cooldown.text:IsShown() and not traitButton.notCastable then
				updateTraitUses( traitButton )
				local buttonCooldown = TRAIT_COOLDOWN_TIMES[cooldown] or 0
				traitButton.cooldown.StartTime = GetTime()
				traitButton.cooldown:SetCooldown( GetTime(), buttonCooldown )
				traitButton.cooldown:SetHideCountdownNumbers( false )
				
				if buttonCooldown == 0 then
					traitButton.cooldown.text:SetText( cooldown )
					traitButton.cooldown.text:Show()
				else
					traitButton.cooldown.text:SetText("")
					traitButton.cooldown.text:Hide()
				end
				
				ExecuteEffects( Profile.traits[traitButton.traitIndex]["effects"], traitButton.traitIndex )
				traitButton:GetScript("OnEnter")( traitButton )
				PlaySound(80)
			else
				PlaySound(1428)
			end
		elseif not traitButton.notCastable then
			updateTraitUses( traitButton )
			traitButton.cooldown:SetCooldown( 0, 0 )
			traitButton.cooldown.text:SetText("")
			traitButton.cooldown.text:Hide()
			traitButton:GetScript("OnEnter")( traitButton )
			ExecuteEffects( Profile.traits[traitButton.traitIndex]["effects"], traitButton.traitIndex )
			PlaySound(80)
		else
			updateTraitUses( traitButton )
			PlaySound(1428)
			UIErrorsFrame:AddMessage( "Trait is not ready yet.", 1.0, 0.0, 0.0 ); 
		end
	end
end

function Me.GetSkillByGUID( guid )
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].guid == guid then
			return Me.Profile.skills[i];
		end
	end
	return
end

-------------------------------------------------------------------------------
-- Return a list (string) of all modifiers for a skill by GUID.
--
function Me.GetModifierNamesFromSkillGUID( guid )
	if not guid then
		return
	end

	local skill = Me.GetSkillByGUID( guid )

	if not( skill and skill.skillModifiers and #skill.skillModifiers > 0 ) then
		return
	end

	local modifiers = "|cFFFFD100Modifiers:|r " .. Me.GetSkillByGUID( skill.skillModifiers[1] )["name"];
	
	-- Grab values from skills in the modifiers table
	-- by GUID
	for skillIndex = 2,#skill.skillModifiers do
		for i = 1, #Me.Profile.skills do
			if Me.Profile.skills[i].guid == skill.skillModifiers[skillIndex] then
				local modifierTotals = Me.GetModifiersFromSkillGUID( skillGUID );
				local color = RED_FONT_COLOR_CODE;
				if ( modifierTotals > 0 ) then
					color = GREEN_FONT_COLOR_CODE.."+"
				end
				modifiers = modifiers .. ", " .. color .. modifierTotals .. " " .. Me.Profile.skills[i].name;

				-- Find any buffs that are also boosting this skill...
				for index = 1,#Profile.buffsActive do
					if Profile.buffsActive[index].skill and Profile.buffsActive[index].skill == Me.Profile.skills[i].name then
						modifiers = modifiers .. ", " .. Profile.buffsActive[index].name;
					end
				end
			end
		end
	end
	
	-- Find any buffs that are also boosting this skill...
	for i = 1,#Profile.buffsActive do
		if Profile.buffsActive[i].skill and Profile.buffsActive[i].skill == skill.name then
			modifiers = modifiers .. ", " .. Profile.buffsActive[i].name;
		end
	end
	
	return modifiers
end

-------------------------------------------------------------------------------
-- Return total modifiers value for a skill by GUID.
--
function Me.GetModifiersFromSkillGUID( guid, includeSelf )
	if not guid then
		return 0;
	end

	local skill = Me.GetSkillByGUID( guid );

	-- Start with the value of the skill itself.
	local modifiers = 0;

	if skill and includeSelf then
		modifiers = skill.rank;
	end

	-- Find any buffs that are boosting this skill...
	for i = 1,#Profile.buffsActive do
		if Profile.buffsActive[i].skill and Profile.buffsActive[i].skill == skill.name then
			modifiers = modifiers + ( Profile.buffsActive[i].skillRank * Profile.buffsActive[i].count );
		end
	end

	if not( skill and skill.skillModifiers ) then
		return modifiers;
	end
	
	-- Grab values from skills in the modifiers table
	-- by GUID
	for skillIndex = 1, #skill.skillModifiers do
		for i = 1, #Me.Profile.skills do
			if Me.Profile.skills[i].guid == skill.skillModifiers[skillIndex] then
				modifiers = modifiers + Me.GetModifiersFromSkillGUID( Me.Profile.skills[i].guid, true )
			end
		end
	end
	
	return modifiers;
end

-------------------------------------------------------------------------------
-- When the dice button is right-clicked.
-- 
-- (Expands a radial menu of skills.)
--
function Me.DiceButton_ExpandMenu( self )
	if not(Me.Profile.skills) or #Me.Profile.skills == 0 then
		return
	end
	
	local skillsList = {};
	for i = 1, #Me.Profile.skills do
		if not( Me.Profile.skills[i].type == "header" ) and Me.Profile.skills[i].showOnMenu then
			tinsert( skillsList, Me.Profile.skills[i] )
		end
	end
	local numSkills = #skillsList;
	local radius = 42 + ( 2 * numSkills );
	local index = 0;

	if not( self.FadeIn ) then
		self.FadeIn = C_Timer.NewTicker( 0.05, function()
			index = index + 1;
			if not( self.menuItems[index] ) then
				self.menuItems[index] = CreateFrame( "Button", "DiceMasterPanelMenuItem"..index, self, "DiceMasterPanelSlotButtonTemplate" )
			end
			local x = radius * math.cos(((index-1)/numSkills) * (2*math.pi)); 
			local y = radius * math.sin(((index-1)/numSkills) * (2*math.pi)); 
			self.menuItems[index]:SetPoint( "CENTER", self, "CENTER", x, y );
			self.menuItems[index].index = index;
			self.menuItems[index].guid = skillsList[index].guid;
			self.menuItems[index].tooltipIcon = skillsList[index].icon;
			self.menuItems[index].tooltipTitle = skillsList[index].name;
			self.menuItems[index].tooltipText = skillsList[index].desc;
			self.menuItems[index].tooltipDetail = Me.GetModifierNamesFromSkillGUID( skillsList[index].guid );
			_G[ self.menuItems[index]:GetName() .. "Icon" ]:SetTexture( skillsList[index].icon )
			
			if self.menuItems[index].FlyOut:IsPlaying() then
				self.menuItems[index].FlyOut:Stop();
			end
			self.menuItems[index].FlyIn:Play();
			if index == numSkills then 
				self.FadeIn:Cancel();
				self.FadeIn = nil; 
				self.menuIsShown = true; 
			end
		end, numSkills)
	end
end

-------------------------------------------------------------------------------

function Me.RollButtonClicked()
	Me.Roll( DiceMasterPanelDice:GetText() ) 
	if DiceMasterPanelDice:HasFocus() then
		DiceMasterPanelDice:ClearFocus()
	end
	Me.UIInteractFX( DiceMasterPanelRollButton, "holy", 0, 0, 2)
end

-------------------------------------------------------------------------------
function Me.RollMenu_OnClick( self )	
	local dice = DiceMasterPanelDice:GetText()
	local modifiers = Me.GetModifiersFromSkillGUID( self.guid, true )
	dice = Me.FormatDiceString( dice, modifiers ) or "D20"
	
	Me.Roll( dice, self.tooltipTitle )
	if not( DiceMasterPanel.ModelScene:IsShown() ) then
		DiceMasterPanel.ModelScene:Show();
	end
	PlaySound(36625);
end

-------------------------------------------------------------------------------

function Me.CloseAllEditors( notPickers, notEditors, notItems )
	if not ( notPickers ) then
		Me.ColourPicker_Close()
		Me.SoundPicker_Close()
		Me.EffectPicker_Close()
		Me.ModelPicker_Close()
		Me.IconPicker_Close()
		Me.TexturePicker_Close()
	end
	if not ( notEditors ) then
		Me.BuffEditor_OnCloseClicked()
		Me.RemoveBuffEditor_OnCloseClicked()
		Me.SetDiceEditor_OnCloseClicked()
		Me.MessageEditor_Close()
		Me.ScriptEditor_Close()
		Me.ProduceItemEditor_Close()
		Me.ConsumeItemEditor_Close()
		Me.CurrencyEditor_Close()
		Me.ScreenEffectEditor_Close()
		Me.AdjustHealthEditor_Close()
	end
	if not ( notItems ) then
		Me.ItemEditor_Close()
		Me.ShopEditor_Close()
	end
end

-------------------------------------------------------------------------------
function Me.ApplyKeybindings()
	if Me.db.char.trackerKeybind and Me.db.char.trackerKeybind~="" then
		SetBindingClick(Me.db.char.trackerKeybind, DiceMasterRollFrameOpen:GetName())
	elseif GetBindingKey("CLICK DiceMasterRollFrameOpen:LeftButton") then
		SetBinding(GetBindingKey("CLICK DiceMasterRollFrameOpen:LeftButton"), nil)
	end
end

-------------------------------------------------------------------------------
function Me.ApplyUiScale()
	DiceMasterPanel:SetScale( Me.db.char.uiScale * 1.4 )
	DiceMasterTraitEditor:SetScale( 1 )
	DiceMasterStatInspector:SetScale( 1 )
	DiceMasterRangeRadar:SetScale( Me.db.char.uiScale * 1.4 )
	DiceMasterInspectFrame:SetScale( Me.db.char.uiScale * 1.2 )
	DiceMasterStatInspectButton:SetScale( Me.db.char.uiScale * 1.2 )
	DiceMasterBuffEditor:SetScale( 1 )
	DiceMasterRemoveBuffEditor:SetScale( 1 )
	DiceMasterSetDiceEditor:SetScale( 1 )
	DiceMasterChargesFrame:SetScale( Me.db.char.uiScale * 1.2 )
	DiceMasterPetChargesFrame:SetScale( Me.db.char.uiScale * 1.2 )
	DiceMasterRollFrame:SetScale( 1 )
	DiceMasterMoraleBar:SetScale( Me.db.profile.morale.scale * 1.2 )
end

-------------------------------------------------------------------------------
function Me.ShowPanel( show )
	Me.db.char.hidepanel = not show
	
	if not show then
		DiceMasterPanel:Hide()
		DiceMasterChargesFrame:Hide()
		DiceMasterPetChargesFrame:Hide()
		DiceMasterRollFrame:Hide()
		DiceMasterMoraleBar:Hide()
	else
		DiceMasterPanel:Show()
		DiceMasterChargesFrame:Show()
		if Me.db.global.hideTracker then
			DiceMasterRollFrame:Show()
		end
		if Profile.morale.enable then
			DiceMasterMoraleBar:Show()
		end
		if Profile.pet.enable then
			DiceMasterPetChargesFrame:Show()
		end
	end
	
	Me.RefreshChargesFrame( true, true )
	Me.RefreshPetFrame()
	Me.Inspect_Open( UnitName( "target" ))
end

-------------------------------------------------------------------------------
-- Call when you change the charges settings.
--
function Me.OnChargesChanged()
	Me.RefreshChargesFrame( true, true )
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.Inspect_Open( UnitName( "target" ))
end

-------------------------------------------------------------------------------
function Me.OnWorldClicked()
	if DiceMasterPanelDice:HasFocus() then
		DiceMasterPanelDice:ClearFocus()
	end
end

-------------------------------------------------------------------------------
function Me.SetupWorldClickDetection()
	
	WorldFrame:HookScript( "OnMouseDown", function()
		Me.OnWorldClicked()
		
	end)
end

-------------------------------------------------------------------------------
-- Display a flash effect over a given UI element.
--
-- @param parent	The parent frame.
-- @param type		The type of effect (arcane, shadow, holy, or frost)
-- @param offsetX	The x offset relative to the parent frame.
-- @param offsetY	The y offset relative to the parent frame.
-- @param noSound	Supress the sound effect. Optional.
--

function Me.UIInteractFX( parent, type, offsetX, offsetY, offsetZ, noSound, animation)
	if not( parent ) then
		return
	end
	if not( offsetZ ) then
		offsetZ = 1;
	end
	DiceMasterUIInteractFX:ClearAllPoints();
	DiceMasterUIInteractFX:SetPoint( "CENTER", parent, offsetX, offsetY );
	DiceMasterUIInteractFX:Show();
	
	local sound = 56356;
	if type == "holy" then
		sound = 54129;
		DiceMasterUIInteractFXActor:SetModelByFileID(4381160);
	elseif type == "shadow" then
		sound = 177182;
		DiceMasterUIInteractFXActor:SetModelByFileID(4381159);
	elseif type == "frost" then
		sound = 54080;
		DiceMasterUIInteractFXActor:SetModelByFileID(4381161);
	else
		DiceMasterUIInteractFXActor:SetModelByFileID(4381158);
	end
	DiceMasterUIInteractFXActor:SetAnimation(159);
	DiceMasterUIInteractFXActor:SetPosition(4*offsetZ, 0, 0.5);
	if not( noSound ) then
		PlaySound(sound);
	end
end

-------------------------------------------------------------------------------
Me.frame = Me.frame or CreateFrame( "Frame" )
Me.frame:UnregisterAllEvents()

function Me:OnEnable()
	Me.SetupDB()
	Me.MinimapButton_Init()
	
	-- Load settings and initialize stuff
	Me.Events_Init()
	Me.Inspect_Init()
	Me.Console_Init()
	Me.ChatLinks_Init()
	Me.Dice_Init()
	Me.Comm_Init()
	Me.ItemTrade_Init()
	Me.MinimapButton:OnLoad()
	Me.ImportDM5Saved()
	Me.Emoji_Init()
	Me.PostTracker_Init()
	
	Me.ApplyKeybindings()
	Me.ApplyUiScale()
	Me.ShowPanel( not Me.db.char.hidepanel )

	for i = 1, 42 do
		if Profile.inventory[i] then
			Profile.inventory[i].approvedBy = nil;
		end
	end
	
	for i = 1,#Profile.traits do
		Profile.traits[i].secret1Active = false;
		Profile.traits[i].secret1Enabled = false;
		Profile.traits[i].secret2Active = false;
		Profile.traits[i].secret2Enabled = false;
		Profile.traits[i].secret3Active = false;
		Profile.traits[i].secret3Enabled = false;
	end
	
	for i = 1, #DiceMaster4.EditModeFrames do
		local frame = DiceMaster4.EditModeFrames[i];
		if not Me.Profile.framePositions[frame.Title] then
			local anchorPoint, anchorTo, relativePoint, x, y = frame:GetPoint();
			Me.Profile.framePositions[frame.Title] = {
				defaultX = x;
				defaultY = y;
			};
		end
		EditModeExpanded:RegisterFrame( frame, "|TInterface/AddOns/DiceMaster/Texture/logo:12|t " .. frame.Title, Me.Profile.framePositions[frame.Title] );
	end
	
	if not( Me.db.global.lastSplashShown ) or not( Me.db.global.lastSplashShown == "5.1.9" ) then
		-- If we haven't seen the splash frame for the latest version, show it.
		DiceMasterSplashFrame:Show();
		Me.db.global.lastSplashShown = "5.1.9";
	end
	
	Me.UpdatePanelTraits()
	 
	Me.RefreshChargesFrame( true, true ) 
	Me.RefreshPetFrame()
	Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Profile.health, Profile.healthMax, Profile.armor )
	Me.RefreshManabarFrame( DiceMasterChargesFrame.manabar, Profile.mana, Profile.manaMax )
	Me.RefreshHealthbarFrame( DiceMasterPetChargesFrame.healthbar, Profile.pet.health, Profile.pet.healthMax, Profile.pet.armor )
	Me.RefreshMoraleFrame( Me.db.profile.morale.count )
	
	Me.Inspect_ShareStatusWithParty()
	
	Me.UpdateAllMapNodes()
	
	Me.SetupWorldClickDetection()
end

