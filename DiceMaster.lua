-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Main module.
--

local MAX_MAXHEALTH = 1000

local VERSION = GetAddOnMetadata( "DiceMaster", "Version" )
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
local Sticky = LibStub("LibSimpleSticky-1.0")

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
	"USE1", "USE2", "USE3", "PASSIVE", 
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
	{ "%<food%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:0:24:0:24|t" };			-- food icon
	{ "%<wood%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:24:48:0:24|t" };			-- wood icon
	{ "%<iron%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:48:72:0:24|t" };			-- iron icon
	{ "%<leather%>",      "|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:72:96:0:24|t" };		-- leather icon
	-- Tags
	{ "<rule>",		" |TInterface/COMMON/UI-TooltipDivider:4:220|t" };									-- <rule>
	{ "(%s)(%d*)%s*<HP>",		"%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" };						-- <HP>
	{ "(%s)(%d*)%s*<AR>",		"%1|cFFFFFFFF%2|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t" };							-- <AR>
	{ "%<%*%>",		"|TInterface/Transmogrify/transmog-tooltip-arrow:8|t" };									-- <*>
	-- Dice
	{ "%s?[+]%d+",           "|cFF00FF00%1|r" };                                                        -- e.g. "+1"
	{ "%s?[-]%d+",           "|cFFFF0000%1|r" };                                                        -- e.g. "-3"
	{ "%s%d*[dD]%d+[+-]?%d*", "|cFFFFFFFF%1|r" };                                                      -- dice rolls e.g. "1d6" 
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
	if Me.OutOfRange( text, 0, data.healthMax ) then
		return
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
		DiceMasterTooltipIcon.elite:Hide()
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
	["CHARGE1"] = "1 &cs"; ["CHARGE2"] = "2 &cp"; ["CHARGE3"] = "3 &cp";
	["CHARGE4"] = "4 &cp"; ["CHARGE5"] = "5 &cp"; ["CHARGE6"] = "6 &cp";
	["CHARGE7"] = "7 &cp"; ["CHARGE8"] = "8 &cp"; ["CHARGE9"] = "9 &cp"; ["CHARGE10"] = "10 &cp"; ["NONE"] = "(None)"
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
-- Convert icon name into path.
--
-- @param iconID 	Index of the icon in the texture.
--

function Me.FormatIcon( iconID )
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
function Me.FormatDescTooltip( text )
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
	
	-- Remove extra spaces/lines at the beginning/end.
	text = gsub( text, "^%s*(.-)%s*$", "%1" )

	return text
end

-------------------------------------------------------------------------------
-- Setup the trait buttons on the dice panel.
--

function Me.UpdatePanelTraits()
	local traits = DiceMasterPanel.traits
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
	local ratio = healthValue / healthMax;
	local startInset = 0.12
	local endInset = 0.05
	local fillAmount = startInset + ratio * ((1 - endInset) - startInset);
	self.fill:SetWidth(max(self:GetWidth() * fillAmount, 1));
	self.fill:SetTexCoord(0, fillAmount, 0.5, 0.75);
	
	self.text:SetText( healthValue.."/"..healthMax )
	
	if armorValue and armorValue > 0 then
		self.text:SetText( healthValue.." (+"..armorValue..")/"..healthMax )
	
		armorValue = healthValue + armorValue
		ratio = armorValue / healthMax;
		fillAmount = startInset + ratio * ((1 - endInset) - startInset);
		self.armor:SetWidth(max(self:GetWidth() * fillAmount, 1));
		self.armor:SetTexCoord(0, fillAmount, 0.75, 1);
		self.armor:Show()
	else
		self.armor:Hide()
	end
	
	if healthValue >= healthMax and ( armorValue and armorValue > 0 ) then
		self.spark:Hide()
		self.barGlow:Show()
	elseif healthValue < healthMax and healthValue > 0 then
		self.spark:Show()
		self.barGlow:Hide()
	else
		self.spark:Hide()
		self.barGlow:Hide()
	end
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
				DiceMasterChargesFrame.healthbar:SetPoint("CENTER", 0, 20)
				DiceMasterChargesFrame.bar:SetPoint("CENTER", 0, 0)
				DiceMasterChargesFrame.bar2:SetPoint("CENTER", 0, -10)
			else
				DiceMasterChargesFrame.healthbar:SetPoint("CENTER", 0, 0)
				DiceMasterChargesFrame.bar:SetPoint("CENTER", 0, 35)
				DiceMasterChargesFrame.bar2:SetPoint("CENTER", 0, 30)
			end
		else
			DiceMasterChargesFrame.bar:Hide()
			DiceMasterChargesFrame.bar2:Hide()
			DiceMasterChargesFrame.healthbar:SetPoint("CENTER", 0, 0)
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
		--DiceMasterPetChargesFrame.Texture:SetTexture( Profile.pet.icon )
		SetPortraitTextureFromCreatureDisplayID( DiceMasterPetChargesFrame.Texture, Profile.pet.model )
		Me.SetupTooltip( DiceMasterPetChargesFrame.portrait, Profile.pet.icon, Profile.pet.name, Profile.pet.type )
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

function Me.TraitButtonClicked( traitButton, button )
	if button == "LeftButton" then
		Me.TraitEditor_Open()
		DiceMasterTraitEditorTab1:Click()
		DiceMaster4.TraitEditor_StartEditing( traitButton.traitIndex )
	elseif button == "RightButton" then
		local cooldown = Profile.traits[ traitButton.traitIndex ].cooldown or "NONE";
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
				
				DiceMaster4.BuffFrame_RemoveBuff( traitButton.traitIndex ) 	
				DiceMaster4.BuffFrame_CastBuff( traitButton.traitIndex ) 
				DiceMaster4.SoundPicker_PlaySound( traitButton.traitIndex )
				DiceMaster4.BuffFrame_RollDice( traitButton.traitIndex )
				DiceMaster4.EffectPicker_PlayEffect( traitButton.traitIndex )
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
			DiceMaster4.BuffFrame_RemoveBuff( traitButton.traitIndex ) 	
			DiceMaster4.BuffFrame_CastBuff( traitButton.traitIndex ) 
			DiceMaster4.SoundPicker_PlaySound( traitButton.traitIndex )
			DiceMaster4.BuffFrame_RollDice( traitButton.traitIndex )
			DiceMaster4.EffectPicker_PlayEffect( traitButton.traitIndex )
			PlaySound(80)
		else
			updateTraitUses( traitButton )
			PlaySound(1428)
		end
	end
end

-------------------------------------------------------------------------------

function Me.GetModifierFromStatistic( statistic )
	if not statistic then
		return 0;
	end

	local modifier = 0;
	local stat = nil
	local statistic = statistic:lower()
	
	-- Look for the attribute from our stats.
	for i = 1,#Me.Profile.stats do
		if Me.Profile.stats[i].name:lower() == statistic then
			modifier = Profile.stats[i].value
			if Me.Profile.stats[i].attribute then
				stat = Me.Profile.stats[i].attribute
			end
			break
		end
	end
	
	-- If no attribute, check the RollList next.
	if not stat then
		for i = 1,#Me.db.char.rollOptions do
			if Me.db.char.rollOptions[i].name == self then
				stat = Me.db.char.rollOptions[i].stat or nil
				break
			end
		end
	end
	
	if stat then
		for i = 1,#Profile.stats do
			if Profile.stats[i] and ( Profile.stats[i].name == stat ) then
				modifier = modifier + Profile.stats[i].value
			end
		end
	end
	
	-- Find any buffs that are boosting this stat
	for i = 1,#Profile.buffsActive do
		if Profile.buffsActive[i].statistic and Profile.buffsActive[i].statistic:lower() == statistic then
			modifier = modifier + ( Profile.buffsActive[i].statAmount * Profile.buffsActive[i].count );
		end
	end
	
	return modifier
end


function Me.RollWheelDropDown_OnClick( self, arg1, arg2, checked )
	
	for i = 1, #Me.db.char.rollOptions do
		if Me.db.char.rollOptions[i].name == Me.RollWheelList[arg1][arg2].name then
			tremove( Me.db.char.rollOptions, i )
			break
		end
	end
	
	if checked then
	
		if #Me.db.char.rollOptions < 8 then
			tinsert( Me.db.char.rollOptions, Me.RollWheelList[arg1][arg2] )
		else
			UIErrorsFrame:AddMessage( "Only 8 roll options can be used at a time.", 1.0, 0.0, 0.0, 53, 5 ); 
			CloseDropDownMenus()
		end
		
	end
end

function Me.RollWheelDropDown_OnLoad( frame, level, menuList )
	local info = UIDropDownMenu_CreateInfo()
	
	Me.RollWheelList = {}
	local lastCategory
	
	for i = 1, #Me.Profile.stats do
		if not Me.Profile.stats[i].value then
			Me.RollWheelList[ Me.Profile.stats[i].name ] = {}
			lastCategory = Me.Profile.stats[i].name;
		else
			if not ( lastCategory ) then
				Me.RollWheelList[ "Uncategorised" ] = {}
				lastCategory = "Uncategorised";
			end
			tinsert( Me.RollWheelList[ lastCategory ], Me.Profile.stats[i] )
		end
	end
	
	if level == 1 then
		info.text = "|cFFffd100Roll Options"
		info.notClickable = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info)
		info.disabled = false;
		info.notClickable = false;
		info.hasArrow = true;
		for k,v in pairs( Me.RollWheelList ) do
			info.text = k
			info.menuList = k
			UIDropDownMenu_AddButton(info)
		end
		info.text = "|cFFFF0000Clear All Options"
		info.notClickable = false;
		info.hasArrow = nil;
		info.func = function() Me.db.char.rollOptions = {} end
		info.menuList = nil
		UIDropDownMenu_AddButton(info)
	elseif menuList then
		for i = 1,#Me.RollWheelList[menuList] do
			info.text = Me.RollWheelList[menuList][i].name
			info.arg1 = menuList
			info.arg2 = i
			info.func = Me.RollWheelDropDown_OnClick;
			info.notCheckable = false;
			info.keepShownOnClick = true;
			info.isNotRadio = true;
			info.tooltipTitle = Me.RollWheelList[menuList][i].name;
			info.tooltipText = Me.RollWheelList[menuList][i].desc;
			if Me.RollWheelList[menuList][i].stat then
				info.tooltipText = Me.RollWheelList[menuList][i].desc .. "|n|cFF707070(Modified by "..Me.RollWheelList[menuList][i].stat.." + "..info.text..")|r";
			end
			
			for i = 1, #Profile.stats do
				if Profile.stats[i].name == info.text then
					if Profile.stats[i].attribute and Profile.stats[i].desc then
						info.tooltipText = Profile.stats[i].desc .. "|n|cFF707070(Modified by " .. Profile.stats[i].attribute .. ")|r";
					end
					break
				end
			end
			
			info.tooltipOnButton = true;
			info.checked = false;
			for i = 1,#Me.db.char.rollOptions do
				if Me.db.char.rollOptions[i].name == info.text then
					info.checked = true;
					break;
				end
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

-------------------------------------------------------------------------------
function Me.RollButtonClicked()
	Me.Roll( DiceMasterPanelDice:GetText() ) 
	if DiceMasterPanelDice:HasFocus() then
		DiceMasterPanelDice:ClearFocus()
	end
end

-------------------------------------------------------------------------------
function Me.RollWheel_Update()
	for i = 1, 8 do
		local frame = _G["DiceMasterPanelRollWheelQ"..i]
		local rollOptions = Me.db.char.rollOptions
		
		if rollOptions and rollOptions[i] then
			local name = rollOptions[i].name
			
			frame:Enable()
			frame.Value = name
			frame.Desc = rollOptions[i].desc or "Roll."
			frame.Stat = rollOptions[i].stat or nil
			
			for i = 1, #Profile.stats do
				if Profile.stats[i].name == name then
					if Profile.stats[i].attribute and Profile.stats[i].desc then
						frame.Desc = Profile.stats[i].desc
						frame.Stat = Profile.stats[i].attribute
					end
					break
				end
			end
			
			if rollOptions[i].wheelName then
				name = rollOptions[i].wheelName
			end
			
			frame.Text:SetText(name)
			frame.Text:SetTextColor( 1, 1, 1 )
		else
			frame:Disable()
			frame.Value = nil
			frame.Desc = nil
			frame.Stat = nil
			frame.Text:SetText("(none)")
			frame.Text:SetTextColor( 0.5, 0.5, 0.5 )
		end
	end	
end

-------------------------------------------------------------------------------
function Me.RollWheel_OnEnter( self, rotation )
	DiceMasterPanel.rollWheel.selected = self.Value
	self.Text:SetTextColor( 1, 0.81, 0 )
	DiceMasterPanel.rollWheel.Highlight:SetRotation( rotation )
	DiceMasterPanel.rollWheel.Highlight:Show()
	
	local dice = DiceMasterPanelDice:GetText()
	local modifier = Me.GetModifierFromStatistic( self.Value )
	dice = Me.FormatDiceString( dice, modifier )
	
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine( self.Value, 1, 1, 1 )
	
	local desc = self.Desc:gsub( "Roll", "Roll "..dice )
	
	GameTooltip:AddLine( desc, 1, 0.81, 0, true )
	
	if self.Stat then
		GameTooltip:AddLine( "(Modified by "..self.Stat.." + "..self.Value..")", 0.44, 0.44, 0.44, true )
	end
	
	if #Profile.buffsActive > 0 then
		for i = 1,#Profile.buffsActive do
			if Profile.buffsActive[i].statistic and Profile.buffsActive[i].statistic == self.Value then
				if Profile.buffsActive[i].statAmount > 0 then
					GameTooltip:AddLine( "(Modified by |cFF00FF00+".. ( Profile.buffsActive[i].statAmount * Profile.buffsActive[i].count ) .."|r from |T".. Profile.buffsActive[i].icon .. ":16|t |cFFFFFFFF" .. Profile.buffsActive[i].name .. "|r)", 0.44, 0.44, 0.44, false )
				else
					GameTooltip:AddLine( "(Modified by |cFFFF0000-".. ( Profile.buffsActive[i].statAmount * Profile.buffsActive[i].count ) .."|r from |T".. Profile.buffsActive[i].icon .. ":16|t |cFFFFFFFF" .. Profile.buffsActive[i].name .. "|r)", 0.44, 0.44, 0.44, false )
				end
			end
		end
	end
	
	GameTooltip:Show()
	
	PlaySound(823)
end

-------------------------------------------------------------------------------
function Me.RollWheel_OnClick( self )	
	local dice = DiceMasterPanelDice:GetText()
	local modifier = Me.GetModifierFromStatistic( self )
	dice = Me.FormatDiceString( dice, modifier ) or "D20"
	
	Me.Roll( dice, self )
end

-------------------------------------------------------------------------------
function Me.BarOnDragStart( self )
	if Me.db.global.snapping then
		local offset = 0
		Sticky:StartMoving(self, Me.snapBars, offset, offset, offset, offset)
	else
		self:StartMoving()
	end
	self.isMoving = true
end

-------------------------------------------------------------------------------
function Me.BarOnDragStop( self )
	if self.isMoving then
		if Me.db.global.snapping then
			local sticky, stickTo = Sticky:StopMoving(self)
		else
			self:StopMovingOrSizing()
		end
		self.isMoving = nil
	end
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
	end
	if not ( notItems ) then
		Me.ItemEditor_Close()
		Me.ShopEditor_Close()
	end
end

-------------------------------------------------------------------------------
function Me.UnlockFrames()
	DiceMasterUnlockDialog:Show()
	if Me.db.global.hideTypeTracker then
		if DiceMasterPostTrackerFrame.Message:GetText() ~= nil then
			DiceMasterPostTrackerFrame.Message:SetText("No one is typing.")
		end
		DiceMasterPostTrackerFrame.Message:Show()
		DiceMasterPostTrackerFrame.Background:Show()
		DiceMasterPostTrackerFrameDragFrame:Show()
	end
	if IsAddOnLoaded("DiceMaster_UnitFrames") and not Me.db.char.unitframes.enable then
		DiceMasterUnitsPanelDragFrame:Show()
	end
	DiceMasterPanelDragFrame:Show()
	DiceMasterInspectFrame:Show()
	DiceMasterInspectFrameDragFrame:Show()
	DiceMasterStatInspectButton:Show()
	DiceMasterStatInspectButtonDragFrame:Show()
	DiceMasterBuffFrameDragFrame:Show()
	DiceMasterInspectBuffFrameDragFrame:Show()
	DiceMasterInspectPetFrameDragFrame:Show()
	DiceMasterChargesFrameDragFrame:Show()
	DiceMasterPetChargesFrameDragFrame:Show()
	DiceMasterMoraleBarDragFrame:Show()
end

-------------------------------------------------------------------------------
function Me.LockFrames()
	DiceMasterUnlockDialog:Hide()
	if DiceMaster4.db.global.hideTypeTracker then
		DiceMasterPostTrackerFrameDragFrame:Hide()
		if #DiceMaster4.WhoIsTyping == 0 then
			DiceMasterPostTrackerFrame.Message:Hide()
			DiceMasterPostTrackerFrame.Background:Hide()
		end
	end
	if IsAddOnLoaded("DiceMaster_UnitFrames") and not Me.db.char.unitframes.enable then
		DiceMasterUnitsPanelDragFrame:Hide()
	end
	DiceMasterPanelDragFrame:Hide()
	DiceMasterInspectFrameDragFrame:Hide()
	DiceMasterStatInspectButtonDragFrame:Hide()
	DiceMaster4.Inspect_Open( UnitName("target") )
	DiceMasterBuffFrameDragFrame:Hide()
	DiceMasterInspectBuffFrameDragFrame:Hide()
	DiceMasterInspectPetFrameDragFrame:Hide()
	DiceMasterChargesFrameDragFrame:Hide()
	DiceMasterPetChargesFrameDragFrame:Hide()
	DiceMasterMoraleBarDragFrame:Hide()
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
	
	if IsAddOnLoaded("DiceMaster_UnitFrames") then
		Me.ApplyUiScaleUF()
		Me.ShowUnitPanel( not Me.db.char.unitframes.enable )
	end
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
		if IsAddOnLoaded("DiceMaster_UnitFrames") then
			DiceMasterUnitsPanel:Hide()
		end
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
		if IsAddOnLoaded("DiceMaster_UnitFrames") and not Me.db.char.unitframes.enable then
			DiceMasterUnitsPanel:Show()
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
	--Me.ItemTrade_Init()
	Me.MinimapButton:OnLoad()
	Me.ImportDM3Saved()
	
	Me.ApplyKeybindings()
	Me.ApplyUiScale()
	Me.ShowPanel( not Me.db.char.hidepanel )
	
	Me.UpdatePanelTraits()
	 
	Me.RefreshChargesFrame( true, true ) 
	Me.RefreshPetFrame()
	Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Profile.health, Profile.healthMax, Profile.armor )
	Me.RefreshHealthbarFrame( DiceMasterPetChargesFrame.healthbar, Profile.pet.health, Profile.pet.healthMax, Profile.pet.armor )
	Me.RefreshMoraleFrame( Me.db.profile.morale.count )
	
	Me.Inspect_ShareStatusWithParty()
	
	Me.UpdateAllMapNodes()
	
	Me.SetupWorldClickDetection()
end

