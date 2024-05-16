-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Chat link code.
--
-- Custom link format: [DiceMaster4:<user>:<traitIndex>:<traitName>]
-- Chat link format: |cff71d5ff|HDiceMaster4:<user>:<traitIndex>|h<traitName>|h|r
--

local Me = DiceMaster4
local Profile = Me.Profile

-------------------------------------------------------------------------------
-- Which events we want to hook for filtering chat links.
--
local chat_events = { 
	"SAY";
	"YELL";
	"EMOTE";
	"GUILD";
	"OFFICER";
	"PARTY";
	"PARTY_LEADER";
	"RAID";
	"RAID_LEADER";
	"RAID_WARNING";
	"BATTLEGROUND";
	"BATTLEGROUND_LEADER";
	"WHISPER";
	"WHISPER_INFORM";
	"BN_WHISPER";
	"BN_WHISPER_INFORM";
	"BN_CONVERSATION"; 
	"CHANNEL";
}

local club_events = {
	"COMMUNITIES_CHANNEL";
}

-------------------------------------------------------------------------------
-- For public events, we have to request chat link data manually.
-- Otherwise, it's sent by the addon instantly along with the message
--   over the same channel.
--
local public_events = {
	["CHAT_MSG_SAY"] = true;
	["CHAT_MSG_YELL"] = true;
	["CHAT_MSG_EMOTE"] = true;
}

local function CheckTooltipForTerms( text )
	DiceMasterItemRefTooltip:Hide()
	local termsTable = {}
	for k, v in pairs( Me.RollList ) do
		for i = 1, #v do
			local matchFound = string.match( text, v[i].subName )
			if matchFound then
				local desc = gsub( v[i].desc, "Roll", "An attempt" )
				local termsString = Me.FormatIconForText( v[i].iconID ) .. " |cFFFFFFFF" .. v[i].name .. "|r|n|cFFffd100" .. desc .. "|r|n|cFF707070(Modified by " .. v[i].skill .. " + " .. v[i].name .. ")|r"
				
				if not tContains( termsTable, termsString ) then
					tinsert( termsTable, termsString )
				end
			end
		end
	end
	for k, v in pairs( Me.TermsList ) do
		for i = 1, #v do
			local matchFound = string.match( text, "<" .. v[i].subName .. ">" )
			if matchFound then
				local termsString = Me.FormatIconForText( v[i].iconID ) .. " |cFFFFFFFF" .. v[i].name .. "|r|n|cFFffd100" .. v[i].desc .. "|r"
				if not tContains( termsTable, termsString ) then
					tinsert( termsTable, termsString )
				end
			end
		end
	end
	if #termsTable > 0 then
		table.sort( termsTable )
		local tooltip = termsTable[1]
		for i = 2, #termsTable do
			tooltip = tooltip .. "|n|n" .. termsTable[i]
		end
		DiceMasterItemRefTooltip.TextLeft1:SetText( tooltip )
		DiceMasterItemRefTooltip:Show()
		ItemRefTooltip:HookScript("OnHide", function() DiceMasterItemRefTooltip:Hide() end )
	end
end

local function RecipeIsKnown( item )
	-- check if we already know a recipe for this item
	local itemData
	if item and item.effects then
		for i = 1, #item.effects do
			if item.effects[i].type == "recipe" and item.effects[i].item then
				itemData = item.effects[i].item;
				break;
			end
		end
	end
	
	-- Find duplicate recipes
	if itemData then
		for i = 1, #Me.Profile.recipes do
			local recipe = Me.Profile.recipes[i]
			if recipe and recipe.item and recipe.item.guid == itemData.guid then
				return true;
			end
		end
	end

	return false
end

-------------------------------------------------------------------------------
-- Chat filter for processing DiceMaster4 links.
--
local function ChatFilter( self, event, msg, sender, ... )
	local sender_short = Ambiguate( sender, "all" )
	
	local found_links = false
	
	local clean = string.gsub(msg, "%[DiceMaster4:(.-):(.-):(.-)%]", function(name, guid, ability)
		
		found_links = true
		
		-- remove the special spaces that were inserted 
		-- (See trait editor code for a better explanation.)
		ability = ability:gsub( " ", " " )
		
		local icon = Me.inspectData[name].traits[tonumber(guid)].icon
		
		-- convert into chat link
        return string.format("|T"..icon..":16|t |cff71d5ff|HDiceMaster4:"..name..":"..guid.."|h[%s]|h|r", ability);
	end);
	
	clean = string.gsub(clean, "%[DiceMaster4Item:(.-):(.-):(.-)%]", function(name, guid, item)
		
		found_links = true
		
		-- remove the special spaces that were inserted 
		-- (See trait editor code for a better explanation.)
		item = item:gsub( " ", " " )
		
		local found_item = false;
	
		for i = 1, 42 do
			if Me.inspectData[name].inventory[i] and Me.inspectData[name].inventory[i].guid == guid then
				found_item = i;
				break
			end
		end
		
		if not found_item then
			return "|TInterface/Icons/inv_misc_questionmark:16|t |cffffffff[Unknown Item]|r";
		end
		
		local icon = Me.inspectData[name].inventory[found_item].icon
		local colorHex = ITEM_QUALITY_COLORS[ Me.inspectData[name].inventory[found_item].quality ].hex or "|cffffffff";
		
		-- convert into chat link
        return string.format("|T"..icon..":16|t "..colorHex.."|HDiceMaster4Item:"..name..":"..guid.."|h[%s]|h|r", item);
	end);
	
	if public_events[event] and found_links then
		
		-- if we received this over a public channel; request inspect data
		Me.Inspect_UpdatePlayer( sender_short )
	end

	clean = string.gsub(clean, "%[DiceMaster4Roll:(.-)%]", function( skill )

		-- convert into chat link
		return "|cffffd100|HDiceMaster4Roll:"..skill.."|h[|TInterface/AddOns/DiceMaster/Texture/logo:12|t Roll " .. skill .. "]|h|r";
	end);
	
	clean = string.gsub(clean, "%[DiceMaster4Icon:(.-)%]", function( path )
		
		if not strfind( path, "%/Icons%/" ) or not Me.db.global.allowIcons then
			return "";
		end
		
		-- convert into chat link
		return "|T" .. path .. ":16|t";
	end);
	
	clean = string.gsub(clean, "%[DiceMaster4Pin:(%d-)%]", function( pin )
		
		if not pin then return end
		
		pin = tonumber( pin )
		
		local mapNodes = Me.Profile.mapNodes
		
		if IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.IsLeader( false ) and not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) and Me.db.global.enableMapNodes then
			for i = 1, GetNumGroupMembers(1) do
				local name, rank = GetRaidRosterInfo(i)
				if rank == 2 then
					if Me.inspectData[ name ].mapNodes then
						mapNodes = Me.inspectData[ name ].mapNodes
					end
					break
				end
			end
		end
		
		if not mapNodes or not mapNodes[pin] then return end
		
		local icon = mapNodes[pin].icon
		local name = mapNodes[pin].title
		
		if type( icon ) == "table" then
			icon = icon[10]
		else
			icon = "|T" .. icon .. ":16|t";
		end
		
		-- convert into chat link
		return "|cffffd100|HDiceMaster4Pin:"..pin.."|h["..icon.." "..name.."]|h|r";
	end);
	
	return false, clean, sender, ...;
end


Me.itemRefOpen   = nil -- we have control over the itemreftooltip
Me.itemRefTrait  = nil -- trait table pointer
Me.itemRefItem  = nil  -- item table pointer
Me.itemRefIndex  = nil -- index of the trait
Me.itemRefPlayer = nil -- player name that owns the trait

local function RefreshItemRef()
	
	local trait = Me.itemRefTrait
	local item = Me.itemRefItem
	
	if trait then
		if trait.icon then
			-- icon with name
			DiceMasterItemRefIcon.icon:SetTexture( trait.icon )
			DiceMasterItemRefIcon:Show()
		else
			DiceMasterItemRefIcon:Hide()
			DiceMasterItemRefIcon.approved:Hide()
		end
		
		ItemRefTooltip:ClearLines();
		ItemRefTooltip:AddLine( trait.name, 1,1,1,1 )
		
		if trait.usage then
			local usage = Me.FormatUsage( trait.usage, Me.itemRefPlayer )
			
			if trait.usage ~= "PASSIVE" and trait.range and trait.range ~= "NONE" then
				local range = Me.FormatRange( trait.range )
				ItemRefTooltip:AddDoubleLine( usage, range, 1, 1, 1, 1, 1, 1, true )
			else
				ItemRefTooltip:AddDoubleLine( usage, nil, 1, 1, 1, 1, 1, 1, true )
			end
			
			if trait.usage ~= "PASSIVE" and trait.castTime then
				local castTime = Me.FormatCastTime( trait.castTime )
				local cooldown = Me.FormatCooldown( trait.cooldown )
				if trait.cooldown and trait.cooldown ~= "NONE" then
					ItemRefTooltip:AddDoubleLine( castTime, cooldown, 1, 1, 1, 1, 1, 1, true )
				else
					ItemRefTooltip:AddDoubleLine( castTime, nil, 1, 1, 1, 1, 1, 1, true )
				end
			end
		end
		
		local desc = Me.FormatDescTooltip( trait.desc, Me.itemRefIndex )
		
		if trait.desc then
			if Me.db.global.hideTips then
				CheckTooltipForTerms( trait.desc )
			end
			local desc = Me.FormatDescTooltip( trait.desc, Me.itemRefIndex )
			ItemRefTooltip:AddLine( desc, 1,0.82,0,1 )
		end
		
		if trait.approved and trait.approved > 0 and Me.PermittedUse() then
			if trait.approved == 1 then
				DiceMasterItemRefIcon.approved:SetTexCoord( 0, 0.5, 0.5, 1 )
			elseif trait.approved == 2 then
				DiceMasterItemRefIcon.approved:SetTexCoord( 0, 0.5, 0, 0.5 )
			end
			DiceMasterItemRefIcon.approved:Show()
		else
			DiceMasterItemRefIcon.approved:Hide()
		end
		
		if trait.officers and Me.PermittedUse() then
			local approval
			if trait.officers[2] then
				approval = "|TInterface/AddOns/DiceMaster/Texture/trait-approved:14:14:0:0:32:32:2:14:2:14|t Approved by " .. trait.officers[1] .. " and " .. trait.officers[2]
				ItemRefTooltip:AddLine( approval, 0, 1, 0, true )
			elseif trait.officers[1] then
				approval = "|TInterface/AddOns/DiceMaster/Texture/trait-approved:14:14:0:0:32:32:2:14:18:30|t Approved by " .. trait.officers[1]
				ItemRefTooltip:AddLine( approval, 1, 1, 0, true )
			end
		end
	elseif item then
		if item.icon then
			-- icon with name
			DiceMasterItemRefIcon.icon:SetTexture( item.icon )
			DiceMasterItemRefIcon:Show()
		else
			DiceMasterItemRefIcon:Hide()
		end
		
		DiceMasterItemRefIcon.approved:Hide()
		
		ItemRefTooltip:ClearLines();
		
		if item.name then
			local color = ITEM_QUALITY_COLORS[ item.quality ]
			ItemRefTooltip:AddLine( item.name, color.r, color.g, color.b, 1 )
		end

		if item.properties["Cosmetic"] then
			ItemRefTooltip:AddLine( "Cosmetic", 1, 0.5, 1, 1 );
		end

		if item.properties["Crafting Reagent"] then
			ItemRefTooltip:AddLine( "Crafting Reagent", 0.4, 0.733, 1, 1 );
		end
		
		if item.soulbound then
			ItemRefTooltip:AddLine( "Binds when picked up", 1, 1, 1, true )
		end
		
		if item.whiteText1 and item.whiteText2 then
			ItemRefTooltip:AddDoubleLine( item.whiteText1, item.whiteText2, 1, 1, 1, 1, 1, 1, true )
		end
		
		if item.useText then
			ItemRefTooltip:AddLine( Me.FormatItemTooltip( item.useText ), 0, 1, 0, true )
		end
		
		if item.requirement then
			ItemRefTooltip:AddLine( item.requirement, 0, 1, 0, true )
		end
		
		if item.flavorText and item.flavorText~="" then
			ItemRefTooltip:AddLine( "\"".. Me.FormatItemTooltip(item.flavorText) .."\"", 1, 0.81, 0, true )
		end
		
		if item.requiredClass then
			if ( next(item.requiredClass) ~= nil ) then
				local classes = {}
				for k, v in pairs( item.requiredClass ) do
					tinsert( classes, k )
				end
				table.sort( classes )
				local classFile = classes[1]:gsub( " ", "" )
				local r, g, b, hex = GetClassColor( string.upper( classFile ) )
				local classString = "|c" .. hex .. classes[1] .. "|r"
				if #classes > 1 then
					for i = 2, #classes do
						classFile = classes[i]:gsub( " ", "" )
						r, g, b, hex = GetClassColor( string.upper( classFile ) )
						classString = classString .. ", |c" .. hex .. classes[i] .. "|r"
					end
				end
				if not item.requiredClass[ UnitClass("player") ] then
					classString = classString:gsub( "|c%x%x%x%x%x%x%x%x", "" )
					classString = classString:gsub( "|r", "" )
					ItemRefTooltip:AddLine( "Classes: " .. classString, 1, 0, 0, true )
				else
					ItemRefTooltip:AddLine( "Classes: " .. classString, 1, 1, 1, true )
				end
			end
		end
		
		if item.requiredRank then
			if ( next(item.requiredRank) ~= nil ) then
				local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
				local ranks = {}
				for k, v in pairs( item.requiredRank ) do
					tinsert( ranks, k )
				end
				table.sort( ranks )
				local rankString = ranks[1]
				if #ranks > 1 then
					for i = 2, #ranks do
						rankString = rankString .. ", " .. ranks[i]
					end
				end
				if not guildRankName or not item.requiredRank[ guildRankName ] then
					ItemRefTooltip:AddLine( "Requires: " .. rankString, 1, 0, 0, true )
				else
					ItemRefTooltip:AddLine( "Requires: " .. rankString, 1, 1, 1, true )
				end
			end
		end
		
		if item.requiredLevel then
			if Me.Profile.level < item.requiredLevel then
				ItemRefTooltip:AddLine( "Requires Level " .. item.requiredLevel, 1, 0, 0, true )
			else
				ItemRefTooltip:AddLine( "Requires Level" .. item.requiredLevel, 1, 1, 1, true )
			end
		end
		
		if item.requiredSkill and item.requiredSkill.name then
			hasRequiredSkill = false;
			for i = 1, #Me.Profile.skills do
				if Me.Profile.skills[i].type ~= "header" and Me.Profile.skills[i].name == item.requiredSkill.name and Me.Profile.skills[i].rank >= item.requiredSkill.rank then
					hasRequiredSkill = true;
					break;
				end
			end
			if not ( hasRequiredSkill ) then
				ItemRefTooltip:AddLine( "Requires "..item.requiredSkill.name.." ("..item.requiredSkill.rank..")", 1, 0, 0, true )
			else
				ItemRefTooltip:AddLine( "Requires: "..item.requiredSkill.name.." ("..item.requiredSkill.rank..")", 1, 1, 1, true )
			end
		end

		if item.requiresDMApproval then
			if item.approvedBy and UnitIsGroupLeader( item.approvedBy , 1) then
				-- GameTooltip:AddLine( "Requires Dungeon Master Permission", 1, 1, 1, true );
			else
				GameTooltip:AddLine( "Requires Dungeon Master Permission", 1, 0, 0, true );
			end
		end
		
		if RecipeIsKnown( item ) then
			ItemRefTooltip:AddLine( "Already known", 1, 0, 0, true )
		end
		
		if item.author then
			ItemRefTooltip:AddLine( "<Made by " .. item.author .. ">", 0, 1, 0, true )
		end
	end
	
	ItemRefTooltip:Show();
end
 
-------------------------------------------------------------------------------
-- Hook for clicking links.
--
local SetHyperlink = ItemRefTooltip.SetHyperlink
function ItemRefTooltip:SetHyperlink(link)
	
	if strsub(link, 1, 16) == "DiceMaster4Item:" then
		if IsModifiedClick("CHATLINK") then
			-- shift-clicked
			--ChatEdit_InsertLink("["..link.."]")
			-- this doesn't work anyway.
			-- this might be a TODO job.
			-- we need to hook the chatbox code for copying links
		else
			local linkType, name, guid = strsplit(":", link)
			if not guid then return end
			
			local slot = Me.FindFirstStackSlot( guid, name )
			
			if not slot then
				return
			end
			
			Me.itemRefOpen   = true
			Me.itemRefItem  = Me.inspectData[ name ].inventory[ slot ]
			Me.itemRefTrait  = nil
			Me.itemRefIndex  = guid
			Me.itemRefPlayer = name
			 
			--ShowUIPanel(ItemRefTooltip); -- todo: test without this
			if not ItemRefTooltip:IsVisible() then
				ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
			end
			
			RefreshItemRef()
			
			-- if trait data isn't loaded yet, the tooltip will be updated
			-- automatically
		end
    elseif strsub(link, 1, 12) == "DiceMaster4:" then
		if IsModifiedClick("CHATLINK") then
			-- shift-clicked
			--ChatEdit_InsertLink("["..link.."]")
			-- this doesn't work anyway.
			-- this might be a TODO job.
			-- we need to hook the chatbox code for copying links
		else
			local linkType, name, guid = strsplit(":", link)
			guid = tonumber(guid) 
			if not guid or guid < 1 or guid > Me.traitCount then return end
			
			Me.itemRefOpen   = true
			Me.itemRefTrait  = Me.inspectData[ name ].traits[guid]
			Me.itemRefItem   = nil
			Me.itemRefIndex  = guid
			Me.itemRefPlayer = name
			 
			--ShowUIPanel(ItemRefTooltip); -- todo: test without this
			if not ItemRefTooltip:IsVisible() then
				ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
			end
			
			RefreshItemRef()
			
			-- if trait data isn't loaded yet, the tooltip will be updated
			-- automatically
		end
	elseif strsub(link, 1, 16) == "DiceMaster4Roll:" then
	
		local linkType, msg = strsplit( ":", link )
				
		if not msg then return end
		
		local dice = DiceMasterPanelDice:GetText()
		for i = 1,#Profile.skills do
			if Profile.skills[i].name == msg and not( Profile.skills[i].type == "header" ) then
				local modifiers = Me.GetModifiersFromSkillGUID( Profile.skills[i].guid, true )
				dice = Me.FormatDiceString( dice, modifiers ) or "D20"
				Me.Roll( dice, Profile.skills[i].name )
				if not( DiceMasterPanel.ModelScene:IsShown() ) then
					DiceMasterPanel.ModelScene:Show();
				end
				PlaySound(36625);
				break
			end
		end
	elseif strsub(link, 1, 15) == "DiceMaster4Pin:" then
		local linkType, msg = strsplit( ":", link )
		pinIndex = tonumber( msg ) or nil
		if not pinIndex then return end
		
		local mapNodes = Me.Profile.mapNodes
		
		if IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.IsLeader( false ) and not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) and Me.db.global.enableMapNodes then
			for i = 1, GetNumGroupMembers(1) do
				local name, rank = GetRaidRosterInfo(i)
				if rank == 2 then
					if Me.inspectData[ name ].mapNodes then
						mapNodes = Me.inspectData[ name ].mapNodes
					end
					break
				end
			end
		end
		
		if not mapNodes or not mapNodes[ pinIndex ] then return end
		
		local info = mapNodes[ pinIndex ]
		local mapID = info.mapID;
		
		OpenWorldMap( mapID )
    else
	
		-- release control over the tooltip if something else is clicked
		-- so that when we receive inspect data, we dont update over what
		-- theyre viewing
		if Me.itemRefOpen and not IsModifiedClick("CHATLINK") then
			Me.itemRefOpen = false
			ItemRefTooltip:Hide()
			DiceMasterItemRefIcon:Hide()
			DiceMasterItemRefIcon.approved:Hide()
		end
        SetHyperlink(self, link)
    end
end

-------------------------------------------------------------------------------
-- Event handler for when we receive trait data from a player.
--
function Me.UpdateTraitItemRef( name, index )
	if Me.itemRefOpen and name == Me.itemRefPlayer and index == Me.itemRefIndex then
		Me.itemRefTrait = Me.inspectData[ name ].traits[index]
		RefreshItemRef()
	end
end

-------------------------------------------------------------------------------
-- This is called when we send traits to a public channel.
--
-- For example, if we send a message with links to traits 1 and 3 to the party,
--  then we also add addon data for those traits with our chat message so
--  people have the data immediately rather than having to make a request.
--
-- If we send to /say or something, then they make the request via WHISPER
--  to refresh the trait data, and it should usually be done before they can
--  click the link (unless there is some traffic going on and the trait's
--  description is somewhat sizeable.)
--
local function SendTraits( traits, dist, channel )
	for k,v in pairs( traits ) do
		Me.Inspect_SendTrait( k, dist, channel )
	end
end

-------------------------------------------------------------------------------
-- Channels that trigger the SendTraits call.
--
local BROADCAST_CHAT_TYPES = {
	["BATTLEGROUND"] = "BATTLEGROUND";
	["GUILD"]		 = "GUILD";
	["OFFICER"]      = "OFFICER";
	["PARTY"]        = "PARTY";
	["RAID"]         = "RAID";
	["RAID_WARNING"] = "RAID"; -- map raid warning to raid channel
	["WHISPER"]      = "WHISPER";
	["CHANNEL"]      = "CHANNEL";
}

-------------------------------------------------------------------------------
local function OnSendChatMessage( text, chatType, lang, channel )
	chatType = chatType:upper()
	
	-- misspelled should really find a way to remove their stupid color codes
	-- BEFORE allowing sendchatmessage to fire
	if Misspelled then
		text = Misspelled:RemoveHighlighting( text )
	end
	
	local traits = nil
	local name = UnitName("player")
	for t in text:gmatch( "%[DiceMaster4:"..name..":(%d+):.-%]" ) do
		t = tonumber(t)
		
		if t and t >= 1 and t <= Me.traitCount then
			traits = traits or {}
			traits[t] = true
		end
	end
	
	if not traits then 
		-- no traits in this message
		-- nothing to worry about
		return 
	end 
	
	local bc = BROADCAST_CHAT_TYPES[chatType]
	if bc then
		SendTraits( traits, bc, channel )
	end
end

-- separate handling for 8.0
-- big thanks to Silvz - Moon Guard (US) for helping with this fix!! <3
-- 

local streamTypeTable = {
	[0] = "GENERAL",
	[1] = "GUILD",
	[2] = "OFFICER",
	[3] = "CLUB_CHANNEL"
}

local function OnSendClubMessage(clubId, streamId, message)
	local streamInfo = C_Club.GetStreamInfo(clubId, streamId)
		
	local channel = nil
    local chatType = streamTypeTable[streamInfo["streamType"]]
    if(chatType == "CLUB_CHANNEL") then
        channelName = string.format("Community:%s:%s", clubId, streamId)
        channelId, channelName, instanceId = GetChannelName(channelName)
        if(channelId) then
            chatType = "CHANNEL"
            channel = tonumber(channelId)
        end
    end
	
	OnSendChatMessage(message, chatType, nil, channel)
end

-------------------------------------------------------------------------------
-- ADDON_LOADED handler
--
function Me.ChatLinks_Init()
	
	-- We really want to wait until we're setup before we accept anything
	-- so we hook stuff in here
	
	hooksecurefunc( "SendChatMessage", OnSendChatMessage )
	for i, event in ipairs(chat_events) do
		ChatFrame_AddMessageEventFilter( "CHAT_MSG_" .. event, ChatFilter );
	end
	
	-- for 8.0, adds support for clubs
	if( C_Club ) then
		hooksecurefunc( C_Club, "SendMessage", OnSendClubMessage )
		for i, event in ipairs(club_events) do
			ChatFrame_AddMessageEventFilter( "CHAT_MSG_" .. event, ChatFilter );
		end
	end
end

