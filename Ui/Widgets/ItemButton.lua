-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

Me.MasterLootDropdown = CreateFrame("Frame", "DiceMasterMasterLootDropdown", UIParent, "UIDropDownMenuTemplate")

local ITEM_BIND_TYPES = {
	"Binds when picked up",
	"Binds when equipped",
	"Binds when used",
}

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
	["skill"] = "LearnSkillEditor_LearnSkill",
	["recipe"] = "LearnRecipeEditor_LearnRecipe",
	["pet"] = "LearnPetEditor_LearnPet",
}

local EffectTypes = {
	["book"] 	= "Book";
	["script"]	= "Run Script";
	["message"]	= "Send Message";
	["produce"]	= "Produce Item";
	["consume"]	= "Consume Item";
	["currency"] = "Add/Remove Currency";
	["buff"]	= "Apply Buff";
	["removebuff"]	= "Remove Buff";
	["setdice"]	= "Roll Dice";
	["effect"]	= "Visual Effect";
	["screeneffect"] = "Screen Effect";
	["sound"]	= "Play Sound";
	["health"] = "Add/Remove Health",
	["skill"] = "Learn Skill",
	["recipe"] = "Learn Recipe",
	["pet"] = "Learn Pet",
}

-- tuples for subbing text in description tooltips
local TOOLTIP_DESC_SUBS = {
	-- Icons
	{ "(%d+)%sHealth",      "|cFFFFFFFF%1|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" };  			-- e.g. "1 health"
	{ "(%d+)%sHP",			"|cFFFFFFFF%1|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" };      		-- e.g. "1 hp"
	{ "(%d+)%sArmo[u]*r",   "|cFFFFFFFF%1|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t" };				-- e.g. "1 armour"
	{ "(%d+)%sMana",		"|cFFFFFFFF%1|r|TInterface/AddOns/DiceMaster/Texture/mana-gem:12|t" };  				-- e.g. "1 mana"
	{ "%<food%>",			"|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:0:24:0:24|t" };		-- food icon
	{ "%<wood%>",			"|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:24:48:0:24|t" };		-- wood icon
	{ "%<iron%>",			"|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:48:72:0:24|t" };		-- iron icon
	{ "%<leather%>",		"|TInterface/AddOns/DiceMaster/Texture/resources:16:16:0:0:128:32:72:96:0:24|t" };		-- leather icon
	-- Tags
	{ "(%d*)%s*<HP>",		"|cFFFFFFFF%1|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t" };			-- <HP>
	{ "(%d*)%s*<AR>",		"|cFFFFFFFF%1|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t" };				-- <AR>
	{ "(%d*)%s*<MP>",		"|cFFFFFFFF%1|r|TInterface/AddOns/DiceMaster/Texture/mana-gem:12|t" };				-- <MP>
	{ "<BR>",				"|n" };																					-- Line breaks
	-- Dice
	{ "%s%d*[dD]%d+[+-]?%d*", "|cFFFFFFFF%1|r" };                                                     				-- dice rolls e.g. "1d6" 
}

local function ExecuteEffects( effects, item )
	if not effects then
		return
	end
	
	for i = 1, #effects do
		local handler = EffectHandlers[ effects[i].type ]
		if Me[handler] then
			if effects[i].delay and effects[i].delay > 0 then
				C_Timer.After( effects[i].delay, function() Me[handler]( effects[i], item ) end )
			else
				Me[handler]( effects[i], item )
			end
		end
	end
end

local function SetItemCooldown( guid, cooldown )
	if not guid then return end
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			local itemButton = _G["DiceMasterInventoryFrameItem" .. i];
			CooldownFrame_Set( itemButton.Cooldown, GetTime(), cooldown, 1 );
		end
	end
end

local function ItemIsInShop( guid )
	-- check if it's already in our shop
	local found = false;
	for i = 1, #Me.Profile.shop do
		if Me.Profile.shop[i].guid == guid then
			found = true;
			break
		end
	end
	return found
end

local function ItemIsBeingTraded( slotID )
	-- check if it's being traded
	for slot = 1, 6 do 
		local amount, containerSlotID, stack = Me.GetDMItemFromSlot(slot);
		if stack then
			if containerSlotID == slotID then
				return true
			end
		end
	end
	return false
end

local function CanUseItem( item )
	if item and item.requiredSkill and item.requiredSkill.guid then
		local hasRequiredSkill = false;
		for i = 1, #Me.Profile.skills do
			if Me.Profile.skills[i].type ~= "header" and Me.Profile.skills[i].guid == item.requiredSkill.guid and tonumber(Me.Profile.skills[i].rank) >= tonumber(item.requiredSkill.rank) then
				hasRequiredSkill = true;
				break
			end
		end
		if not ( hasRequiredSkill ) then
			return false;
		end
	end
	
	return true;
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
Me.playerItemTooltipOpen = false
Me.playerItemTooltipName = nil
Me.playerItemTooltipIndex = nil

-------------------------------------------------------------------------------

StaticPopupDialogs["DICEMASTER4_DESTROYCUSTOMITEM"] = {
  text = "Do you want to destroy this item?",
  button1 = "Yes",
  button2 = "No",
  showAlert = true,
  OnShow = function( self, data )
	local item = Me.Profile.inventory[ data ]
	self.text:SetText( "Do you want to destroy " .. item.name .. "?" )
  end,
  OnAccept = function ( self, data )
  
	if not ( Me.Profile.inventory[ data ] ) or ItemIsInShop( Me.Profile.inventory[ data ].guid ) then
		UIErrorsFrame:AddMessage( "You cannot delete an item while it is in your shop.", 1.0, 0.0, 0.0 );
	else
		Me.Profile.inventory[ data ] = nil
	end
	
	local cursorIcon = DiceMasterCursorItemIcon
	-- previous button
	if cursorIcon.prevButton then
		if cursorIcon.prevButton.Update then
			cursorIcon.prevButton:Update()
		end
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	-- clear cursor data
	DiceMasterCursorOverlay:Hide()
	cursorIcon.item:SetTexture( nil )
	cursorIcon.itemID = nil
	cursorIcon.prevButton = nil
	cursorIcon:Hide()
	ResetCursor()
	Me.TraitEditor_UpdateInventory()
  end,
  OnCancel = function( self )
	local cursorIcon = DiceMasterCursorItemIcon
	-- previous button
	if cursorIcon.prevButton then
		if cursorIcon.prevButton.Update then
			cursorIcon.prevButton:Update()
		end
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	-- clear cursor data
	DiceMasterCursorOverlay:Hide()
	cursorIcon.item:SetTexture( nil )
	cursorIcon.itemID = nil
	cursorIcon.prevButton = nil
	cursorIcon:Hide()
	ResetCursor()
	PlaySound( 1203 )
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  exclusive = true,
}

StaticPopupDialogs["DICEMASTER4_CUSTOMITEMBINDONUSE"] = {
  text = "Using this item will bind it to you.",
  button1 = "Okay",
  button2 = "Cancel",
  OnAccept = function ( self, data )
	if not data or not data.itemIndex then
		return
	end  
	local item = Me.Profile.inventory[ data.itemIndex ] or nil
	if not item then
		return
	end
	item.soulbound = true;
	item.lastCastTime = time()
	SetItemCooldown( item.guid, item.cooldown )
	
	if item.effects then
		ExecuteEffects( item.effects, item )
	end
	
	if item.consumeable then
		item.stackCount = item.stackCount - 1
		
		if item.stackCount == 0 then
			Me.Profile.inventory[ data.itemIndex ] = nil;
			GameTooltip:Hide()
		end
		
		data:Update()
	end
	Me.TraitEditor_UpdateInventory()
  end,
  OnCancel = function( self )
	PlaySound( 1203 )
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  exclusive = true,
}

StaticPopupDialogs["DICEMASTER4_CUSTOMITEMREQUIRESDMAPPROVAL"] = {
  text = "Using this item requires permission from the Dungeon Master.|n|nWould you like to request permission?",
  button1 = "Request",
  button2 = "Cancel",
  OnAccept = function ( self, data )
	if not data or not data.itemIndex then
		return
	end  
	local item = Me.Profile.inventory[ data.itemIndex ] or nil
	if not item then
		return
	end

	if IsInGroup( LE_PARTY_CATEGORY_HOME ) and not Me.IsLeader( false ) and not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		for i = 1, GetNumGroupMembers(1) do
			local name, rank = GetRaidRosterInfo(i);
			if rank == 2 then
				local msg = Me:Serialize( "ITEMUSE", {
					item = item;
				})
				Me:SendCommMessage( "DCM4", msg, "WHISPER", name, "ALERT" );
				local itemLink = Me.GetItemLink( UnitName("player"), item.guid );
				break
			end
		end
	end
  end,
  OnCancel = function( self )
	PlaySound( 1203 )
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  exclusive = true,
}

-------------------------------------------------------------------------------

function Me.MasterLoot_OnClick(self, arg1, arg2, checked)
	if arg1 and UnitExists(arg1) and UnitIsPlayer(arg1) and UnitIsConnected(arg1) then
		local msg = Me:Serialize( "ITEMML", {
			pn = arg1;
			wi = true;
			item = Me.MasterLootItem;
			amount = Me.MasterLootItem.stackCount;
		});
		Me:SendCommMessage( "DCM4", msg, "RAID", nil, "ALERT" )
		Me.ConsumeItem( Me.MasterLootItem.guid, Me.MasterLootItem.stackCount )
		Me.TraitEditor_UpdateInventory()
	end
	Me.MasterLootItem = nil;
end

function Me.MasterLoot_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	local numGroupMembers = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
	if level == 1 then
		if numGroupMembers > 0 then
			info.justifyH = "LEFT";
			info.isNotRadio = true;
			info.notCheckable = true;
			info.isTitle = true;
			info.text = "Master Loot";
			UIDropDownMenu_AddButton(info, level)
		end
		info.isTitle = false;
		info.notClickable = false;
		info.disabled = false;
		if numGroupMembers <= 5 then
			for i = 1, numGroupMembers do
				local name, _, subgroup, _, _, _, _, online = GetRaidRosterInfo(i)
				if online then
					info.keepShownOnClick = false;
					info.hasArrow = false;
					info.text = name;
					info.arg1 = name;
					info.func = Me.MasterLoot_OnClick;
					UIDropDownMenu_AddButton(info, level)
				end
			end
		elseif numGroupMembers > 5 then
			info.notCheckable = true;
			info.keepShownOnClick = true;
			info.hasArrow = true;
			info.text = "Group 1"
			info.menuList = "1";
			UIDropDownMenu_AddButton(info, level)
			info.text = "Group 2"
			info.menuList = "2";
			UIDropDownMenu_AddButton(info, level)
		end
		if numGroupMembers > 10 then
			info.text = "Group 3"
			info.menuList = "3";
			UIDropDownMenu_AddButton(info, level)
		end
		if numGroupMembers > 15 then
			info.text = "Group 4"
			info.menuList = "4";
			UIDropDownMenu_AddButton(info, level)
		end
		if numGroupMembers > 20 then
			info.text = "Group 5"
			info.menuList = "5";
			UIDropDownMenu_AddButton(info, level)
		end
		if numGroupMembers > 25 then
			info.text = "Group 6"
			info.menuList = "6";
			UIDropDownMenu_AddButton(info, level)
		end
		if numGroupMembers > 30 then
			info.text = "Group 7"
			info.menuList = "7";
			UIDropDownMenu_AddButton(info, level)
		end
		if numGroupMembers > 35 then
			info.text = "Group 8"
			info.menuList = "8";
			UIDropDownMenu_AddButton(info, level)
		end
	elseif menuList then
		for i = 1, numGroupMembers do
			local name, _, subgroup, _, _, _, _, online = GetRaidRosterInfo(i)
			if tostring(subgroup) == menuList and online then
				info.keepShownOnClick = false;
				info.hasArrow = false;
				info.text = name;
				info.arg1 = name;
				info.func = Me.MasterLoot_OnClick;
				UIDropDownMenu_AddButton(info, level)
			end
		end
	end
end

-------------------------------------------------------------------------------

function Me.FormatItemTooltip( text )
	for k, v in ipairs( TOOLTIP_DESC_SUBS ) do
		text = gsub( text, v[1], v[2] )
	end

	-- <img> </img>
	text = gsub( text, "<img>","|T" )
	text = gsub( text, "</img>",":16|t" )

	-- Remove extra spaces/lines at the beginning/end.
	text = gsub( text, "^%s*(.-)%s*$", "%1" )

	return text
end

-------------------------------------------------------------------------------
function Me.UpdateItemTooltip( name, index )
	
	if Me.playerItemTooltipOpen and Me.playerItemTooltipName == name and Me.playerItemTooltipIndex == index then
		Me.OpenItemTooltip( nil, name, index )
	end
end

-------------------------------------------------------------------------------
-- Setup the tooltip for an item.
--
-- @param texture     Icon to use next to tooltip name.
-- @param name   	  Name of item or generic text at the top.
-- @param binds		  Binding text or generic text under the name.
-- @param slot        Item slot or generic text under binding.
-- @param armorType   Armour type or generic text under the name to the right.
-- @param use    	  Green "Use:" or "Equip:" text.
-- @param requirement Item requirement (displays in white if allowed, red if not).
-- @param flavour	  Gold flavour text or generic tooltip description.
--
function Me.OpenItemTooltip( owner, item, index, isShopItem, isBankItem )
	if isShopItem and type(item) == "string" then
		Me.playerItemTooltipOpen  = true
		Me.playerItemTooltipName  = item
		Me.playerItemTooltipIndex = index
		item = Me.inspectData[item].shop[index]
	elseif isBankItem and type(item) == "string" then
		Me.playerItemTooltipOpen  = true
		Me.playerItemTooltipName  = item
		Me.playerItemTooltipIndex = index
		item = Me.db.global.bank[index]
	elseif type(item) == "string" then
		Me.playerItemTooltipOpen  = true
		Me.playerItemTooltipName  = item
		Me.playerItemTooltipIndex = index
		item = Me.inspectData[item].inventory[index]
	end
	
	if not item then
		return
	end
	
	if owner then
		
		GameTooltip:SetOwner( owner, "ANCHOR_RIGHT" )
	else
		GameTooltip:SetOwner( UIParent, "ANCHOR_CURSOR" )
	end
	
	GameTooltip:ClearLines()
	
	if item.name then
		if item.icon then
			-- icon with name
			DiceMasterTooltipIcon.icon:SetTexture( item.icon )
			DiceMasterTooltipIcon:Show()
		else
			DiceMasterTooltipIcon:Hide()
		end
		DiceMasterTooltipIcon.approved:Hide()
		local color = ITEM_QUALITY_COLORS[ item.quality or 1 ];
		GameTooltip:AddLine( item.name, color.r, color.g, color.b, true )
	end

	if item.properties and item.properties["Cosmetic"] then
		GameTooltip:AddLine( "Cosmetic", 1, 0.5, 1, true );
	end

	if item.properties and item.properties["Crafting Reagent"] then
		GameTooltip:AddLine( "Crafting Reagent", 0.4, 0.733, 1, true );
	end
	 
	if item.soulbound then 
		GameTooltip:AddLine( "Soulbound", 1, 1, 1, true )
	elseif item.itemBind and item.itemBind > 0 then
		GameTooltip:AddLine( ITEM_BIND_TYPES[ item.itemBind ], 1, 1, 1, true )
	end
	
	if item.whiteText1 and item.whiteText2 then
		GameTooltip:AddDoubleLine( item.whiteText1, item.whiteText2, 1, 1, 1, 1, 1, 1, true )
	end
	
	if item.useText and string.len(item.useText)>0 then
		if item.cooldown and item.cooldown > 1 then
			GameTooltip:AddLine( Me.FormatItemTooltip( item.useText ).." ("..SecondsToTime(item.cooldown).." Cooldown)", 0, 1, 0, true )
		else
			GameTooltip:AddLine( Me.FormatItemTooltip( item.useText ), 0, 1, 0, true )
		end
	end
	
	if item.requirement then
		GameTooltip:AddLine( item.requirement, 0, 1, 0, true )
	end
	
	if item.flavorText and item.flavorText~="" then
		GameTooltip:AddLine( "\"".. Me.FormatItemTooltip(item.flavorText) .."\"", 1, 0.81, 0, true )
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
				GameTooltip:AddLine( "Classes: " .. classString, 1, 0, 0, true )
			else
				GameTooltip:AddLine( "Classes: " .. classString, 1, 1, 1, true )
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
				GameTooltip:AddLine( "Requires: " .. rankString, 1, 0, 0, true )
			else
				GameTooltip:AddLine( "Requires: " .. rankString, 1, 1, 1, true )
			end
		end
	end
	
	if item.requiredLevel then
		if Me.Profile.level < item.requiredLevel then
			GameTooltip:AddLine( "Requires Level " .. item.requiredLevel, 1, 0, 0, true )
		else
			GameTooltip:AddLine( "Requires Level" .. item.requiredLevel, 1, 1, 1, true )
		end
	end
	
	if item.requiredSkill and item.requiredSkill.guid then
		hasRequiredSkill = false;
		for i = 1, #Me.Profile.skills do
			if Me.Profile.skills[i].type ~= "header" and Me.Profile.skills[i].guid == item.requiredSkill.guid and tonumber(Me.Profile.skills[i].rank) >= tonumber(item.requiredSkill.rank) then
				hasRequiredSkill = true;
				break;
			end
		end
		if not ( hasRequiredSkill ) then
			GameTooltip:AddLine( "Requires "..item.requiredSkill.name.." ("..item.requiredSkill.rank..")", 1, 0, 0, true )
		else
			GameTooltip:AddLine( "Requires "..item.requiredSkill.name.." ("..item.requiredSkill.rank..")", 1, 1, 1, true )
		end
	end

	if item.requiresDMApproval then
		if Me.IsLeader(false) or ( item.approvedBy and UnitIsGroupLeader( item.approvedBy , 1)) then
			GameTooltip:AddLine( "Requires Dungeon Master Permission", 1, 1, 1, true );
		else
			GameTooltip:AddLine( "Requires Dungeon Master Permission", 1, 0, 0, true );
		end
	end
	
	if RecipeIsKnown( item ) then
		GameTooltip:AddLine( "Already known", 1, 0, 0, true )
	end
	
	if item.author then
		GameTooltip:AddLine( "<Made by " .. item.author .. ">", 0, 1, 0, true )
	end
	
	if Me.PermittedUse() then
		if item.canDisenchant then
			GameTooltip:AddLine( "Disenchantable", 0.53, 0.67, 1.0, true )
		elseif DiceMasterCursorItemIcon.disenchantCursor then
			GameTooltip:AddLine( "Cannot be disenchanted", 1, 0, 0, true )
		end
	end
	
	if owner and owner.InShopIcon and owner.InShopIcon:IsShown() then
		GameTooltip:AddLine( "This item is currently in your shop.", 1, 1, 0, true )
	end
	
	if isBankItem then
		GameTooltip:AddLine( "<Right Click to Withdraw>", 0.44, 0.44, 0.44, true )
	end
	
	if owner and item.cooldown and owner.Cooldown then
		if owner.Cooldown:GetCooldownDuration() > 0 then
			local total, elapsed = owner:GetCooldown()
			
			if elapsed and elapsed < total then
				timeElapsed = string.lower( SecondsToTime( total - elapsed, false ) )
				GameTooltip:AddLine( "Cooldown remaining: " .. timeElapsed, 1, 1, 1, true )
			end
			
			owner:SetScript( "OnUpdate", function( self )
				if GameTooltip:IsOwned( self ) then
					self:GetScript("OnEnter")( self )
				end
			end)
		end
	end
	
	if owner and DiceMasterCursorItemIcon.inspectCursor then
		GameTooltip:AddLine( "|n|cFFFFD100Item GUID:|r " .. item.guid, 1, 1, 1, true )
		if item.effects and #item.effects > 0 then
			GameTooltip:AddLine( "Item Actions:", 1, 0.81, 0, true )
			for i = 1, #item.effects do
				if EffectTypes[item.effects[i].type] then
					GameTooltip:AddLine( "- " .. EffectTypes[item.effects[i].type], 1, 1, 1, true )
				end
			end
		end
		if item.properties and #item.properties > 0 then
			GameTooltip:AddLine( "|nItem Properties:", 1, 0.81, 0, true )
			for k, v in pairs( item.properties ) do
				GameTooltip:AddLine( "- " .. k, 1, 1, 1, true )
			end
		end
	end
	
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
function Me.CloseItemTooltip()
	Me.playerItemTooltipOpen = false
    GameTooltip:Hide()
	DiceMasterTooltipIcon:Hide()
	DiceMasterTooltipIcon.approved:Hide()
	DiceMasterTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Handler for item tooltips.
--
local function OnEnter( self )
	
	if self.customTooltip then
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
		GameTooltip:ClearLines()
		GameTooltip:AddLine( self.customTooltip, 1, 1, 1, true )
		GameTooltip:Show()
		return
	end
	
	if not self.item and not self.itemPlayer and not self.itemShop and not self.itemBank then return end
	
	if self.item then
		Me.OpenItemTooltip( self, self.item )
	elseif self.itemPlayer then
		Me.OpenItemTooltip( self, self.itemPlayer, self.itemIndex )
		local item = Me.Profile.inventory[ self.itemIndex ]
		if item then
			if self.itemPlayer == UnitName( "player" ) then
				if DiceMasterCursorItemIcon.editCursor and ItemIsInShop( item.guid ) then
					SetCursor("CAST_ERROR_CURSOR");
				elseif DiceMasterCursorItemIcon.lootCursor and item.soulbound then
					SetCursor("CAST_ERROR_CURSOR");
				elseif DiceMasterCursorItemIcon.sellCursor and ( ItemIsInShop( item.guid ) or item.soulbound ) then
					SetCursor("CAST_ERROR_CURSOR");
				elseif DiceMasterCursorItemIcon.chooseCursor and item.soulbound then
					SetCursor("CAST_ERROR_CURSOR");
				end
			end
			if DiceMasterCursorItemIcon.copyCursor and ( item.author~=UnitName("player") and not item.copyable ) then
				SetCursor("CAST_ERROR_CURSOR");
			elseif DiceMasterCursorItemIcon.exportCursor and ( item.soulbound and item.author~=UnitName("player") ) then
				SetCursor("CAST_ERROR_CURSOR");
			elseif DiceMasterCursorItemIcon.disenchantCursor and ( not item.canDisenchant ) then
				SetCursor("CAST_ERROR_CURSOR");
			end
		end
	elseif self.itemShop then
		Me.OpenItemTooltip( self, self.itemShop, self.itemIndex, true )
		if ( self:CanAffordShopItem() == false or self:OutOfStock() ) then
			SetCursor("BUY_ERROR_CURSOR");
		else
			SetCursor("BUY_CURSOR");
		end
		self.shopCursor = true;
	elseif self.itemBank then
		Me.OpenItemTooltip( self, UnitName("player"), self.itemIndex, nil, true )
	else
		return
	end
	 
end

local function OnLeave( self )
	if self.itemPlayer then
		Me.playerItemTooltipOpen = false
		if DiceMasterCursorItemIcon.editCursor or DiceMasterCursorItemIcon.sellCursor or DiceMasterCursorItemIcon.chooseCursor or DiceMasterCursorItemIcon.requestCursor or DiceMasterCursorItemIcon.lootCursor or DiceMasterCursorItemIcon.bankCursor or DiceMasterCursorItemIcon.exportCursor or DiceMasterCursorItemIcon.copyCursor or DiceMasterCursorItemIcon.disenchantCursor or DiceMasterCursorItemIcon.feedCursor then
			SetCursor("CAST_CURSOR");
		end
	end
	if self.shopCursor then
		ResetCursor();
		self.shopCursor = false;
	end
    GameTooltip:Hide()
	DiceMasterTooltipIcon:Hide()
	DiceMasterTooltipIcon.approved:Hide()
end

function Me.ClearCursorActions( clearItem, hideCursor, hideOverlay )
	local cursorIcon = DiceMasterCursorItemIcon
	
	if clearItem then
		cursorIcon.item:SetTexture( nil )
		cursorIcon.itemID = nil;
	end
	
	cursorIcon.prevButton = nil;
	
	cursorIcon.copyCursor = nil;
	cursorIcon.copyItem = nil;
	cursorIcon.copyAmount = nil;
	
	cursorIcon.editCursor = nil;
	
	cursorIcon.inspectCursor = nil;
	
	cursorIcon.sellCursor = nil;
	
	cursorIcon.exportCursor = nil;
	
	cursorIcon.lootCursor = nil;
	cursorIcon.lootType = nil;
	
	cursorIcon.splitItem = nil;
	cursorIcon.splitAmount = nil;
	
	cursorIcon.chooseCursor = nil;
	
	cursorIcon.bankCursor = nil;
	
	cursorIcon.disenchantCursor = nil;
	cursorIcon.feedCursor = nil;
	
	if hideCursor then
		cursorIcon:Hide()
	else
		cursorIcon:Show()
	end
	
	if hideOverlay then
		DiceMasterCursorOverlay:Hide()
	else
		DiceMasterCursorOverlay:Show()
	end
	
	ResetCursor();
	ClearCursor();
end;


local function CheckEditBoxShown()
	local isShown = false
	for i = 1, NUM_CHAT_WINDOWS do
		local frame = _G["ChatFrame" .. i .. "EditBox"]
		if ( frame:IsShown() and frame:HasFocus() ) then
			isShown = true
			break
		end
	end
	return isShown
end

local function AddItemToBank( item, itemID )
	if not item or not itemID then
		return
	end
	
	if Me.FindTotalEmptyBankSlots() < 1 then
		UIErrorsFrame:AddMessage( "Bank is full.", 1.0, 0.0, 0.0 ); 
		return
	end
	
	local itemLink = Me.GetItemLink( UnitName("player"), item.guid )
	
	if item.stackCount > 1 then
		Me.PrintMessage( "|cFFFFFF00" .. itemLink .. "x" .. item.stackCount .. " has been added to your bank.|r", "SYSTEM" )
	else
		Me.PrintMessage( "|cFFFFFF00" .. itemLink .. " has been added to your bank.|r", "SYSTEM" )
	end
	PlaySound(895)
	tinsert( Me.db.global.bank, item)
	Me.Profile.inventory[itemID] = nil;
	
	DiceMasterItemAnim.animIcon:SetTexture( item.icon );
	DiceMasterItemAnim:SetPoint( "CENTER", DiceMasterTraitEditorBankTab, 0, 0 )
	DiceMasterItemAnim:Show()
	
	Me.TraitEditor_UpdateBank()
	Me.TraitEditor_UpdateInventory()
end

local function RemoveItemFromBank( item, itemID )
	if not item or not itemID then
		return
	end
	
	if Me.FindTotalEmptySlots() < 1 then
		UIErrorsFrame:AddMessage( "Inventory is full.", 1.0, 0.0, 0.0 ); 
		return
	end
	
	local itemLink = Me.GetItemLink( UnitName("player"), item.guid )
	
	if item.stackCount > 1 then
		Me.PrintMessage( "|cFFFFFF00" .. itemLink .. "x" .. item.stackCount .. " has been added to your inventory.|r", "SYSTEM" )
	else
		Me.PrintMessage( "|cFFFFFF00" .. itemLink .. " has been added to your inventory.|r", "SYSTEM" )
	end
	PlaySound(895)
	tinsert( Me.Profile.inventory, item)
	Me.db.global.bank[itemID] = nil;
	
	DiceMasterItemAnim.animIcon:SetTexture( item.icon );
	DiceMasterItemAnim:SetPoint( "CENTER", DiceMasterTraitEditorInventoryTab, 0, 0 )
	DiceMasterItemAnim:Show()
	
	Me.TraitEditor_UpdateBank()
	Me.TraitEditor_UpdateInventory()
end

local function OnClick( self, button )
	local item = Me.Profile.inventory[self.itemIndex]
	local cursorIcon = DiceMasterCursorItemIcon
	local total, elapsed = self:GetCooldown()
	StaticPopup_Hide("DICEMASTER4_DESTROYCUSTOMITEM")
	
	if self.hasItem then 
		if Me.ItemIsBeingLooted( item.guid ) then
			UIErrorsFrame:AddMessage( "You cannot interact with an item while it is being rolled for.", 1.0, 0.0, 0.0 );
			return
		elseif ItemIsBeingTraded( self.itemIndex ) then
			UIErrorsFrame:AddMessage( "You cannot interact with an item while it is being traded.", 1.0, 0.0, 0.0 );
			return
		end
	end
	
	if cursorIcon.inspectCursor then
		Me.ClearCursorActions( true, true, true )
		return
	end
	
	if ( button == "LeftButton" ) then
		if cursorIcon.editCursor and self.hasItem then
			-- check if it's our item first!
			if item.author ~= UnitName("player") then
				UIErrorsFrame:AddMessage( "You don't have permission to edit that item.", 1.0, 0.0, 0.0 );
				return
			elseif ItemIsInShop( item.guid ) then
				UIErrorsFrame:AddMessage( "You cannot edit an item while it is in your shop.", 1.0, 0.0, 0.0 );
				return
			end
			Me.ClearCursorActions( true, true, true )
			Me.ItemEditor_Open( DiceMasterTraitEditor )
			Me.ItemEditor_LoadEditItem( self.itemIndex )
		elseif cursorIcon.chooseCursor and self.hasItem then
			if DiceMasterProduceItemEditor:IsShown() then
				-- check if it's our item first!
				if item.author ~= UnitName("player") then
					UIErrorsFrame:AddMessage( "You can't produce items created by other players.", 1.0, 0.0, 0.0 );
					return
				elseif Me.ItemEditing and Me.ItemEditingIndex == self.itemIndex then
					UIErrorsFrame:AddMessage( "Items cannot produce themselves.", 1.0, 0.0, 0.0 );
					return
				elseif item.soulbound then
					UIErrorsFrame:AddMessage( "You can't produce a soulbound item.", 1.0, 0.0, 0.0 );
					return
				end
				Me.ClearCursorActions( true, true, true )
				Me.ProduceItemEditor_LoadItem( self.itemIndex )
			elseif DiceMasterConsumeItemEditor:IsShown() then
				-- check if it's our item first!
				if item.author ~= UnitName("player") then
					UIErrorsFrame:AddMessage( "You can't consume items created by other players.", 1.0, 0.0, 0.0 );
					return
				elseif Me.ItemEditing and Me.ItemEditingIndex == self.itemIndex then
					UIErrorsFrame:AddMessage( "Items cannot consume themselves.", 1.0, 0.0, 0.0 );
					return
				elseif item.soulbound then
					UIErrorsFrame:AddMessage( "You can't consume a soulbound item.", 1.0, 0.0, 0.0 );
					return
				end
				Me.ClearCursorActions( true, true, true )
				Me.ConsumeItemEditor_LoadItem( self.itemIndex )
			elseif DiceMasterLearnRecipeEditor:IsShown() then
				-- TODO
				if ( cursorIcon.chooseID == "CRAFTEDITEM" ) then
					if item.author ~= UnitName("player") then
						UIErrorsFrame:AddMessage( "Recipes cannot craft items created by other players.", 1.0, 0.0, 0.0 );
						return
					elseif Me.ItemEditing and Me.ItemEditingIndex == self.itemIndex then
						UIErrorsFrame:AddMessage( "Recipes cannot craft themselves.", 1.0, 0.0, 0.0 );
						return
					elseif item.soulbound then
						UIErrorsFrame:AddMessage( "You can't craft a soulbound item.", 1.0, 0.0, 0.0 );
						return
					else
						Me.ClearCursorActions( true, true, true )
						Me.LearnRecipeEditor_LoadItem( self.itemIndex )
					end
				elseif ( cursorIcon.chooseID == "REQUIREDTOOL" ) then
					if Me.ItemEditing and Me.ItemEditingIndex == self.itemIndex then
						UIErrorsFrame:AddMessage( "Recipes cannot use themselves as a required tool.", 1.0, 0.0, 0.0 );
						return
					else
						Me.ClearCursorActions( true, true, true )
						Me.LearnRecipeEditor_LoadRequiredTool( self.itemIndex )
					end
				elseif type( cursorIcon.chooseID ) == "number" then
					if Me.ItemEditing and Me.ItemEditingIndex == self.itemIndex then
						UIErrorsFrame:AddMessage( "Recipes cannot use themselves as a reagent.", 1.0, 0.0, 0.0 );
						return
					else
						Me.ClearCursorActions( true, true, true )
						Me.LearnRecipeEditor_LoadReagent( self.itemIndex, cursorIcon.chooseID )
					end
				end
			elseif DiceMasterBookFrame:IsShown() and DiceMasterBookFrame.bookData then
				Me.ClearCursorActions( true, true, true )
				Me.BookEditor_InsertLink( UnitName("player"), item.guid )
			end
		elseif cursorIcon.copyCursor and self.hasItem then
			-- check if it's our item or copyable first!
			if not item.copyable and item.author ~= UnitName("player")  then
				UIErrorsFrame:AddMessage( "You don't have permission to copy that item.", 1.0, 0.0, 0.0 );
				return;
			end
			
			Me.ClearCursorActions( true, false, true )
			self.SplitStack = function( button, amount )
				DiceMasterCursorOverlay:Show()
				cursorIcon.item:SetTexture( self.icon:GetTexture() );
				cursorIcon.itemID = self.itemIndex;
				cursorIcon.copyItem = true;
				cursorIcon.copyAmount = amount;
				cursorIcon:Show()
				SetCursor( "ITEM_CURSOR" )
			end
			StackSplitFrame:OpenStackSplitFrame( item.stackSize, self, "BOTTOMLEFT", "TOPLEFT" );
		elseif cursorIcon.sellCursor and self.hasItem then
			-- check if it's our item first!
			if item.author ~= UnitName("player") then
				UIErrorsFrame:AddMessage( "You don't have permission to sell that item.", 1.0, 0.0, 0.0 );
				return
			elseif item.soulbound then
				UIErrorsFrame:AddMessage( "You cannot sell a soulbound item.", 1.0, 0.0, 0.0 );
				return
			elseif ItemIsInShop( item.guid ) then
				UIErrorsFrame:AddMessage( "You are already selling that item.", 1.0, 0.0, 0.0 );
				return
			end
			Me.ClearCursorActions( true, true, true )
			Me.ShopEditor_Open( DiceMasterTraitEditor )
			Me.ShopEditor_LoadItem( self.itemIndex )
		elseif cursorIcon.exportCursor and self.hasItem then
			-- check if it's our item first!
			if not item.copyable and item.author ~= UnitName("player")  then
				UIErrorsFrame:AddMessage( "You don't have permission to export that item.", 1.0, 0.0, 0.0 );
				return
			elseif item.soulbound then
				UIErrorsFrame:AddMessage( "You cannot export a soulbound item.", 1.0, 0.0, 0.0 );
				return
			end
			Me.ClearCursorActions( true, true, true )	
			Me.TraitEditor_GenerateItemExportCode( item )
		elseif cursorIcon.lootCursor and self.hasItem then
			-- check if it's our item first!
			if item.author ~= UnitName("player") then
				UIErrorsFrame:AddMessage( "You don't have permission to distribute that item.", 1.0, 0.0, 0.0 );
				return
			elseif item.soulbound then
				UIErrorsFrame:AddMessage( "You cannot distribute a soulbound item.", 1.0, 0.0, 0.0 );
				return
			end
			if cursorIcon.lootType == "GROUPLOOT" then
				Me.GroupLootFrame_GroupLoot( item, self )
			elseif cursorIcon.lootType == "MASTERLOOT" then
				Me.MasterLootItem = item;
				UIDropDownMenu_SetAnchor(Me.MasterLootDropdown, 0, 0, "TOPLEFT", self, "BOTTOMLEFT") 
				UIDropDownMenu_SetWidth(Me.MasterLootDropdown, 120, 5)
				UIDropDownMenu_Initialize(Me.MasterLootDropdown, Me.MasterLoot_OnLoad, "MENU")
				ToggleDropDownMenu(nil, nil, Me.MasterLootDropdown, self)
			end
			Me.ClearCursorActions( true, true, true )
		elseif cursorIcon.bankCursor and self.hasItem then			
			AddItemToBank( item, self.itemIndex )
		elseif cursorIcon.disenchantCursor and self.hasItem and Me.PermittedUse() then
			-- check if it can be disenchanted
			if not item.canDisenchant then
				UIErrorsFrame:AddMessage( "Item cannot be disenchanted", 1.0, 0.0, 0.0 );
				return
			end
			Me.Disenchant_DisenchantItem( self.itemIndex, self )
			Me.ClearCursorActions( true, true, true )
		elseif cursorIcon.feedCursor and self.hasItem then
			Me.PetEditor_FeedPet( item )
			Me.ClearCursorActions( true, true, true )
			if item.consumeable then
				item.stackCount = item.stackCount - 1
				
				if item.stackCount == 0 then
					Me.Profile.inventory[self.itemIndex] = nil;
					GameTooltip:Hide()
				end
				
				self:Update()
			end
		elseif cursorIcon.itemID then
			if self.hasItem then
				local itemOne = Me.Profile.inventory[self.itemIndex]
				local itemTwo = Me.Profile.inventory[cursorIcon.itemID]
				
				if itemOne.guid == itemTwo.guid then
					-- merge items into one slot.
					if cursorIcon.copyItem then
						itemOne.stackCount = itemOne.stackCount + cursorIcon.copyAmount
						if itemOne.stackCount > itemOne.stackSize then
							local remainder = itemOne.stackCount - itemOne.stackSize
							itemOne.stackCount = itemOne.stackSize;
							local leftOver = _G["DiceMasterTraitEditorInventoryFrameItem"..self.itemIndex]:GetItem();
							leftOver.stackCount = remainder
							tinsert( Me.Profile.inventory, leftOver )
							Me.TraitEditor_UpdateInventory()
						end
					elseif itemOne.stackCount == itemTwo.stackCount then
						-- items have the same stack size (or are the same item) so we don't do anything...
					else
						itemOne.stackCount = itemOne.stackCount + itemTwo.stackCount;
						if itemOne.stackCount > itemOne.stackSize then
							itemTwo.stackCount = itemOne.stackCount - itemOne.stackSize; 
							itemOne.stackCount = itemOne.stackSize;
						else
							Me.Profile.inventory[cursorIcon.itemID] = nil;
						end
					end
				elseif cursorIcon.copyItem then
					UIErrorsFrame:AddMessage( "Couldn't merge those items.", 1.0, 0.0, 0.0 );
				else
					-- swap two items slots					
					Me.Profile.inventory[cursorIcon.itemID] = itemOne;
					Me.Profile.inventory[self.itemIndex] = itemTwo;
				end
			else
				if cursorIcon.copyItem then
					-- place a copied item
					Me.Profile.inventory[self.itemIndex] = DiceMasterTraitEditorInventoryFrame["Item"..cursorIcon.itemID]:GetItem()
					Me.Profile.inventory[self.itemIndex].stackCount = cursorIcon.copyAmount;
				elseif cursorIcon.splitItem then
					-- place a split stack
					Me.Profile.inventory[self.itemIndex] = DiceMasterTraitEditorInventoryFrame["Item"..cursorIcon.itemID]:GetItem()
					Me.Profile.inventory[self.itemIndex].stackCount = cursorIcon.splitAmount;
					Me.Profile.inventory[cursorIcon.itemID].stackCount = Me.Profile.inventory[cursorIcon.itemID].stackCount - cursorIcon.splitAmount;
					
					if Me.Profile.inventory[cursorIcon.itemID].stackCount == 0 then
						Me.Profile.inventory[cursorIcon.itemID] = nil;
					end
				else
					-- move to an empty slot
					Me.Profile.inventory[self.itemIndex] = Me.Profile.inventory[cursorIcon.itemID]
					Me.Profile.inventory[cursorIcon.itemID] = nil;
				end
			end
			
			self:Update()
			
			if self:GetScript("OnEnter") then
				self:GetScript("OnEnter")( self )
			end
			
			-- previous slot
			if cursorIcon.prevButton and cursorIcon.prevButton.itemIndex then
				if cursorIcon.prevButton.Update then
					cursorIcon.prevButton:Update()
				end
				SetItemButtonDesaturated( cursorIcon.prevButton, false );
			end
			
			-- clear cursor data
			Me.ClearCursorActions( true, true, true )
			PlaySound( 1203 )
		elseif self.hasItem and IsShiftKeyDown() and CheckEditBoxShown() then
			-- shift click link
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
			-- Me.Inspect_SendStatus( dist, channel )
			Me.Inspect_SendItemSlot( self.itemIndex, false, dist, channel )
			-- Create chat link.
			
			-- We convert item names' spaces to U+00A0 No-Break Space
			-- so that chat addons that split up messages see the link as 
			-- a whole word and have a lesser chance to screw up
			--
			-- We could use something another symbol that would be more secure
			-- but then people without the addon would see that ugly symbol
			--
			local name = Me.Profile.inventory[self.itemIndex].name:gsub( " ", " " )
			--                                                       |    |
			--                                                space -'    |
			--                                            no-break-space -'
			
			ChatEdit_InsertLink(
				string.format( "[DiceMaster4Item:%s:%s:%s]", UnitName("player"), item.guid, name ) ) 
			
		elseif self.hasItem and IsShiftKeyDown() and item.stackCount > 1 then
			-- split item stackCount
			Me.ClearCursorActions( true, false, true )
			self.SplitStack = function( button, amount )
				DiceMasterCursorOverlay:Show()
				cursorIcon.item:SetTexture( self.icon:GetTexture() );
				cursorIcon.itemID = self.itemIndex;
				cursorIcon.splitItem = true;
				cursorIcon.splitAmount = amount;
				cursorIcon.prevButton = self;
				cursorIcon:Show()
				SetCursor( "ITEM_CURSOR" )
			end
			StackSplitFrame:OpenStackSplitFrame( item.stackSize, self, "BOTTOMLEFT", "TOPLEFT" );
		elseif self.hasItem then
			-- pick up item
			DiceMasterCursorOverlay:Show()
			cursorIcon.item:SetTexture( self.icon:GetTexture() );
			cursorIcon.itemID = self.itemIndex
			cursorIcon.prevButton = self;
			cursorIcon:Show()
			SetItemButtonDesaturated( self, true );
			ClearCursor()
			SetCursor( "ITEM_CURSOR" )
			PlaySound( 1186 )
			if item.effects then
				for i = 1, #item.effects do
					if item.effects[i].type == "pet" then
						-- open the pet tab
						DiceMasterTraitEditorTab3:Click()
						break
					end
				end
			end
		end
	elseif ( button == "RightButton" ) then
		if TradeFrame:IsShown() then
			for slot = 1, 6 do 
				if not( GetTradePlayerItemInfo(slot) and true ) then
					local itemButton = _G["TradePlayerItem" .. slot .. "ItemButton"];
					Me.SetDMItemInSlot(slot, item.stackCount, self.itemIndex, _G["DiceMasterTraitEditorInventoryFrameItem"..self.itemIndex]:GetItem());
					break;
				end
			end
			return
		end
		if cursorIcon.copyCursor or cursorIcon.editCursor or cursorIcon.sellCursor or cursorIcon.chooseCursor or cursorIcon.lootCursor or cursorIcon.bankCursor or cursorIcon.exportCursor or cursorIcon.requestCursor then
			Me.ClearCursorActions( true, true, true )
		elseif cursorIcon.itemID then
			self:Update()
			
			-- previous slot
			if cursorIcon.prevButton.Update then
				cursorIcon.prevButton:Update()
			end
			SetItemButtonDesaturated( cursorIcon.prevButton, false );
			
			-- clear cursor data
			Me.ClearCursorActions( true, true, true )
			PlaySound( 1203 )
		elseif elapsed then
			-- item is on cooldown
			UIErrorsFrame:AddMessage( "Item is not ready yet.", 1.0, 0.0, 0.0 ); 
		elseif item then
			-- use item
			if item.requiresDMApproval and not( Me.IsLeader(false)) then
				if not( item.approvedBy and UnitIsGroupLeader( item.approvedBy , 1)) then
					StaticPopup_Show( "DICEMASTER4_CUSTOMITEMREQUIRESDMAPPROVAL", nil, nil, self )
					return
				end
			end

			if item.itemBind and item.itemBind == 3 and not item.soulbound then
				StaticPopup_Show( "DICEMASTER4_CUSTOMITEMBINDONUSE", nil, nil, self )
				return
			end
			
			if not( CanUseItem( item )) then
				UIErrorsFrame:AddMessage( "You can't use that item.", 1.0, 0.0, 0.0 );
				return
			end
			
			item.lastCastTime = time()
			SetItemCooldown( item.guid, item.cooldown );
			
			if item.effects then
				ExecuteEffects( item.effects, item )
			end
			
			if item.consumeable then
				item.stackCount = item.stackCount - 1
				
				if item.stackCount == 0 then
					Me.Profile.inventory[self.itemIndex] = nil;
					GameTooltip:Hide()
				end
				
				self:Update()
			end
		end
	end
end

local function OnPlayerInventoryClick( self, button )
	local item = Me.inspectData[self.itemPlayer].inventory[self.itemIndex]
	local cursorIcon = DiceMasterCursorItemIcon
	if ( button == "LeftButton" ) then
		if self.hasItem and IsShiftKeyDown() and CheckEditBoxShown() then
			-- shift click link
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
			-- Me.Inspect_SendStatus( dist, channel )
			Me.Inspect_SendItemSlot( self.itemIndex, false, dist, channel )
			-- Create chat link.
			
			-- We convert item names' spaces to U+00A0 No-Break Space
			-- so that chat addons that split up messages see the link as 
			-- a whole word and have a lesser chance to screw up
			--
			-- We could use something another symbol that would be more secure
			-- but then people without the addon would see that ugly symbol
			--
			local name = Me.inspectData[self.itemPlayer].inventory[self.itemIndex].name:gsub( " ", " " )
			--                                                       |    |
			--                                                space -'    |
			--                                            no-break-space -'
			
			ChatEdit_InsertLink(
				string.format( "[DiceMaster4Item:%s:%s:%s]", self.itemPlayer, item.guid, name ) ) 
		end
	end
end

local function PurchaseItem( item, amount )
	if Me.inspectData[item.itemShop].shop[item.itemIndex] then
		local data = {}
		
		for k, v in pairs( Me.inspectData[item.itemShop].shop[item.itemIndex] ) do
			data[k] = v;
		end
		
		if not amount then
			amount = 1;
		end
		
		if ( data.numAvailable and data.numAvailable == 0 ) then
			return
		end
		
		-- Find the right currency
		local currency = nil
		for i = 1, #Me.Profile.currency do
			if Me.Profile.currency[i].guid == data.currency.guid then
				currency = Me.Profile.currency[i]
				break;
			end
		end
		
		if #Me.Profile.inventory >= 42 then
			UIErrorsFrame:AddMessage( "Inventory is full.", 1.0, 0.0, 0.0 ); 
			return
		end
		
		if data.price * amount > tonumber( currency.value ) then
			UIErrorsFrame:AddMessage( "You don't have enough " .. currency.name .. ".", 1.0, 0.0, 0.0 );
			return
		end
		
		if item:OutOfStock() then
			UIErrorsFrame:AddMessage( "You do not have the required items for that purchase.", 1.0, 0.0, 0.0 );
			return
		end
		
		if data.requiredRank and ( next(data.requiredRank) ~= nil ) then
			local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
			if not data.requiredRank[ guildRankName ] then
				local ranks = {}
				for k, v in pairs( data.requiredRank ) do
					tinsert( ranks, k )
				end
				table.sort( ranks )
				local rankString = ranks[1]
				if #ranks > 1 then
					for i = 2, #ranks do
						rankString = rankString .. ", " .. ranks[i]
					end
				end
				UIErrorsFrame:AddMessage( "Requires " .. rankString, 1.0, 0.0, 0.0 );
				return
			end
		end
		
		if data.requiredClass and ( next(data.requiredClass) ~= nil ) then
			if not data.requiredClass[ UnitClass("player") ] then
				UIErrorsFrame:AddMessage( "That item can't be used by players of your class!", 1.0, 0.0, 0.0 );
				return
			end
		end
		
		if data.requiredLevel then
			if Me.Profile.level < item.requiredLevel then
				UIErrorsFrame:AddMessage( "Requires Level " .. data.requiredLevel, 1.0, 0.0, 0.0 );
				return
			end
		end
		
		-- Send purchase approval.
		local msg = Me:Serialize( "ITEMBUY", {
			itemId = item.itemIndex;
			amount = amount * data.stackCount;
		})
			
		Me:SendCommMessage( "DCM4", msg, "WHISPER", item.itemShop, "ALERT" )
	end
end

local function OnShopClick( self, button )
	if ( button == "LeftButton" ) then	
		-- TODO
		if IsShiftKeyDown() and CheckEditBoxShown() then
			-- shift click link
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
			-- Me.Inspect_SendStatus( dist, channel )
			Me.Inspect_SendItemSlot( self.itemIndex, false, dist, channel )
			-- Create chat link.
			
			-- We convert item names' spaces to U+00A0 No-Break Space
			-- so that chat addons that split up messages see the link as 
			-- a whole word and have a lesser chance to screw up
			--
			-- We could use something another symbol that would be more secure
			-- but then people without the addon would see that ugly symbol
			--
			local name = Me.inspectData[self.itemShop].inventory[self.itemIndex].name:gsub( " ", " " )
			--                                                       |    |
			--                                                space -'    |
			--                                            no-break-space -'
			
			ChatEdit_InsertLink(
				string.format( "[DiceMaster4Item:%s:%s:%s]", self.itemShop, Me.inspectData[self.itemShop].shop[self.itemIndex].guid, name ) )
		elseif IsShiftKeyDown() then
			Me.ClearCursorActions( true, false, true )
			self.SplitStack = function( button, amount )
				PurchaseItem( self, amount )
			end
			StackSplitFrame:OpenStackSplitFrame( Me.inspectData[self.itemShop].shop[self.itemIndex].stackSize, self, "BOTTOMLEFT", "TOPLEFT" );
		end
	elseif ( button == "RightButton" ) then
		PurchaseItem( self )
	end
end

local function OnShopModifiedClick( self, button )
	local item = Me.inspectData[self.itemShop].shop[self.itemIndex]
	if ( HandleModifiedItemClick( item.name ) ) then
		return;
	end
	if ( IsModifiedClick("SPLITSTACK")) then
		local maxStack = item.stackSize;
		local price = item.price;
		local stackCount = item.stackCount;
		
		-- Find the right currency
		local currency = nil
		for i = 1, #Me.Profile.currency do
			if Me.Profile.currency[i].guid == item.currency.guid then
				currency = Me.Profile.currency[i]
				break;
			end
		end
		
		local canAfford;
		if (currency and price and price > 0) then
			canAfford = floor( tonumber( currency.value ) / (price / stackCount) );
		else
			canAfford = maxStack;
		end

		if ( maxStack > 1 ) then
			local maxPurchasable = min(maxStack, canAfford);
			StackSplitFrame:OpenStackSplitFrame(maxPurchasable, self, "BOTTOMLEFT", "TOPLEFT", stackCount);
		end
		return;
	end
end

local function OnBankClick( self, button )
	local item = Me.db.global.bank[self.itemIndex]
	local cursorIcon = DiceMasterCursorItemIcon
	StaticPopup_Hide("DICEMASTER4_DESTROYCUSTOMITEM")
	
	if ( button == "LeftButton" ) then
		if cursorIcon.exportCursor and self.hasItem then
			-- check if it's our item first!
			if not item.copyable and item.author ~= UnitName("player")  then
				UIErrorsFrame:AddMessage( "You don't have permission to export that item.", 1.0, 0.0, 0.0 );
				return
			elseif item.soulbound then
				UIErrorsFrame:AddMessage( "You cannot export a soulbound item.", 1.0, 0.0, 0.0 );
				return
			end
			Me.ClearCursorActions( true, true, true )	
			Me.TraitEditor_GenerateItemExportCode( item )
		elseif cursorIcon.itemID then
			if self.hasItem then
				local itemOne = Me.db.global.bank[self.itemIndex]
				local itemTwo = Me.db.global.bank[cursorIcon.itemID]
				
				if itemOne.guid == itemTwo.guid then
					-- merge items into one slot.
					if itemOne.stackCount == itemTwo.stackCount then
						-- items have the same stack size (or are the same item) so we don't do anything...
					else
						itemOne.stackCount = itemOne.stackCount + itemTwo.stackCount;
						if itemOne.stackCount > itemOne.stackSize then
							itemTwo.stackCount = itemOne.stackCount - itemOne.stackSize; 
							itemOne.stackCount = itemOne.stackSize;
						else
							Me.db.global.bank[cursorIcon.itemID] = nil;
						end
					end
				else
					-- swap two items slots					
					Me.db.global.bank[cursorIcon.itemID] = itemOne;
					Me.db.global.bank[self.itemIndex] = itemTwo;
				end
			else
				if cursorIcon.splitItem then
					-- place a split stack
					Me.db.global.bank[self.itemIndex] = DiceMasterTraitEditorBankFrame["Item"..cursorIcon.itemID]:GetItem()
					Me.db.global.bank[self.itemIndex].stackCount = cursorIcon.splitAmount;
					Me.db.global.bank[cursorIcon.itemID].stackCount = Me.db.global.bank[cursorIcon.itemID].stackCount - cursorIcon.splitAmount;
					
					if Me.db.global.bank[cursorIcon.itemID].stackCount == 0 then
						Me.db.global.bank[cursorIcon.itemID] = nil;
					end
				else
					-- move to an empty slot
					Me.db.global.bank[self.itemIndex] = Me.db.global.bank[cursorIcon.itemID]
					Me.db.global.bank[cursorIcon.itemID] = nil;
				end
			end
			
			self:Update()
			
			if self:GetScript("OnEnter") then
				self:GetScript("OnEnter")( self )
			end
			
			-- previous slot
			if cursorIcon.prevButton and cursorIcon.prevButton.itemIndex then
				if cursorIcon.prevButton.Update then
					cursorIcon.prevButton:Update()
				end
				SetItemButtonDesaturated( cursorIcon.prevButton, false );
			end
			
			-- clear cursor data
			Me.ClearCursorActions( true, true, true )
			PlaySound( 1203 )
		elseif self.hasItem and IsShiftKeyDown() and item.stackCount > 1 then
			-- split item stackCount
			Me.ClearCursorActions( true, false, true )
			self.SplitStack = function( button, amount )
				DiceMasterCursorOverlay:Show()
				cursorIcon.item:SetTexture( self.icon:GetTexture() );
				cursorIcon.itemID = self.itemIndex;
				cursorIcon.splitItem = true;
				cursorIcon.splitAmount = amount;
				cursorIcon.prevButton = self;
				cursorIcon:Show()
				SetCursor( "ITEM_CURSOR" )
			end
			StackSplitFrame:OpenStackSplitFrame( item.stackSize, self, "BOTTOMLEFT", "TOPLEFT" );
		elseif self.hasItem then
			-- pick up item
			DiceMasterCursorOverlay:Show()
			cursorIcon.item:SetTexture( self.icon:GetTexture() );
			cursorIcon.itemID = self.itemIndex
			cursorIcon.prevButton = self;
			cursorIcon:Show()
			SetItemButtonDesaturated( self, true );
			ClearCursor()
			SetCursor( "ITEM_CURSOR" )
			PlaySound( 1186 )
		end
	elseif ( button == "RightButton" ) then
		if cursorIcon.copyCursor or cursorIcon.editCursor or cursorIcon.sellCursor or cursorIcon.chooseCursor or cursorIcon.lootCursor or cursorIcon.bankCursor or cursorIcon.exportCursor or cursorIcon.requestCursor then
			Me.ClearCursorActions( true, true, true )
		elseif cursorIcon.itemID then
			self:Update()
			
			-- previous slot
			if cursorIcon.prevButton.Update then
				cursorIcon.prevButton:Update()
			end
			SetItemButtonDesaturated( cursorIcon.prevButton, false );
			
			-- clear cursor data
			Me.ClearCursorActions( true, true, true )
			PlaySound( 1203 )
		elseif self.hasItem then
			RemoveItemFromBank( item, self.itemIndex )
		end
	end
end

-------------------------------------------------------------------------------
local methods = {
	---------------------------------------------------------------------------
	-- Set a static texture for this button.
	--
	-- Overrides SetItem.
	--
	SetTexture = function( self, tex )
		self.item       = nil
		self.itemPlayer = nil
		self.itemIndex  = nil
		self.icon:SetTexture( tex )
	end;
	---------------------------------------------------------------------------
	-- Hook this button up to a direct item.
	--
	SetItem = function( self, item )
		self.item = item
		self:RegisterForDrag("LeftButton")
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		self:Update()
	end;
	---------------------------------------------------------------------------
	-- Hook this button up to a direct item.
	--
	SetShopItem = function( self, player, index )
		self.item = nil
		self.itemShop = player
		self.itemIndex = index
		
		self:RegisterForDrag("LeftButton")
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		self:SetScript( "OnClick", OnShopClick )
		
		self.SplitStack = function( button, split )
			if ( split > 0 ) then
				--TODO
				--PurchaseItem( self.itemShop, self.itemIndex, split )
			end
		end
		
		self:Update()
	end;
	
	---------------------------------------------------------------------------
	-- Hook this button up to a player item.
	--
	SetPlayerItem = function( self, player, index )
		self.item = nil
		self.itemPlayer = player
		self.itemIndex  = index
		
		if player == UnitName("player") then
			self:RegisterForDrag("LeftButton")
			self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			self:SetScript( "OnClick", OnClick )
			self:SetScript( "OnDragStart", function( self ) OnClick( self, "LeftButton" ) end )
			self:SetScript( "OnReceiveDrag", function( self ) OnClick( self, "LeftButton" ) end )
		else
			self:RegisterForDrag( nil )
			self:SetScript( "OnClick", OnPlayerInventoryClick )
			self:SetScript( "OnDragStart", nil )
			self:SetScript( "OnReceiveDrag", nil )
		end
		
		self:Update()
	end;
	
	---------------------------------------------------------------------------
	-- Hook this button up to a bank item.
	--
	SetBankItem = function( self, index )
		self.item = nil
		self.itemBank = true;
		self.itemIndex  = index
		
		self:RegisterForDrag("LeftButton")
		self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		self:SetScript( "OnClick", OnBankClick )
		self:SetScript( "OnDragStart", function( self ) OnBankClick( self, "LeftButton" ) end )
		self:SetScript( "OnReceiveDrag", function( self ) OnBankClick( self, "LeftButton" ) end )
		
		self:Update()
	end;
	
	---------------------------------------------------------------------------
	-- Get item data.
	--
	-- Returns as a complete table.
	--
	GetItem = function( self, isShopItem, isBankItem )
		local data = {}
		
		if isShopItem then
			for k, v in pairs( Me.inspectData[self.itemShop].shop[self.itemIndex] ) do
				data[k] = v;
			end
		elseif isBankItem then	
			for k, v in pairs( Me.db.global.bank[self.itemIndex] ) do
				data[k] = v;
			end
		else
			for k, v in pairs( Me.Profile.inventory[self.itemIndex] ) do
				data[k] = v;
			end
		end
		
		return data;
	end;
	---------------------------------------------------------------------------
	-- Get item data.
	--
	-- Returns as a complete table.
	--
	GetPlayerItem = function( self, playerName )
		local data = {}
		
		for k, v in pairs( Me.inspectData[self.itemPlayer].inventory[self.itemIndex] ) do
			data[k] = v;
		end
		
		return data;
	end;
	---------------------------------------------------------------------------
	-- Refresh after an item changes.
	--
	Update = function( self )
		local texture = self.icon;
		local item;
		
		if self.itemPlayer then
			item = Me.inspectData[self.itemPlayer].inventory[self.itemIndex] or nil
		elseif self.itemShop then
			item = Me.inspectData[self.itemShop].shop[self.itemIndex] or nil
		elseif self.itemBank then
			item = Me.db.global.bank[self.itemIndex] or nil
		else
			item = Me.Profile.inventory[self.itemIndex] or nil
		end
		
		self.hasItem =  nil;
		self.showCD = nil;

		self.InShopIcon:Hide()
		
		if ( item ) then
			texture:SetTexture( item.icon );
			texture:Show();
			SetItemButtonCount( self, item.stackCount );
			SetItemButtonQuality( self, item.quality );
			self.hasItem = 1;
			if not self.itemShop then
				self.showCD = true;
				-- set up item cooldown
				local total, elapsed = self:GetCooldown()
				
				if not(elapsed) or elapsed > total then
					self.Cooldown:Hide();
				else
					CooldownFrame_Set( self.Cooldown, GetTime() - (elapsed), total, 1 );
				end
				if self:GetParent() ~= Me.statinspector.inventoryFrame then
					if ItemIsInShop( item.guid ) then
						self.InShopIcon:Show()
					end
					SetItemButtonDesaturated( self, Me.ItemIsBeingLooted( item.guid ) )
				end
			end
		else
			texture:Hide();
			SetItemButtonCount( self, 0 );
			SetItemButtonQuality( self, nil );
			CooldownFrame_Set( self.Cooldown, GetTime(), 0, 1 );
		end
	end;
	
	SetCustomTooltip = function( self, text )
		self.customTooltip = text
	end;
	
	GetCooldown = function( self )
		local item;
		if self.itemPlayer then
			item = Me.inspectData[self.itemPlayer].inventory[self.itemIndex] or nil
		elseif self.itemBank then
			item = Me.db.global.bank[self.itemIndex] or nil
		end
		
		if not item then
			return 0;
		end
		
		local lastCastTime = item.lastCastTime
		local cooldown = item.cooldown
		if time() - lastCastTime < cooldown then
			return cooldown, time() - lastCastTime;
		end
		return cooldown;
	end;
	
	SplitStack = function( button, split )
		if ( split > 0 ) then
			Me.ShopFrame_PurchaseItem( self.itemIndex, split )
		end
	end;
	
	OutOfStock = function( self )
		if Me.inspectData[self.itemShop].shop[self.itemIndex] then
			local item = Me.inspectData[self.itemShop].shop[self.itemIndex]
			
			if not item.numAvailable or item.numAvailable > 0 then
				return false;
			end
		end
		return true;
	end;
	
	CanAffordShopItem = function( self, amount )
		if Me.inspectData[self.itemShop].shop[self.itemIndex] then
			local item = Me.inspectData[self.itemShop].shop[self.itemIndex]
			
			-- Find the right currency
			local currency = nil
			for i = 1, #Me.Profile.currency do
				if Me.Profile.currency[i].guid == item.currency.guid then
					currency = Me.Profile.currency[i]
					break;
				end
			end
			if not currency then
				return false;
			end
			if not amount then
				amount = 1
			end
			if item.price * amount <= tonumber( currency.value ) then
				return true;
			end
		end
		return false;
	end;
}

-------------------------------------------------------------------------------
-- Initialize a new item button.
--
function Me.ItemButton_Init( self )

	for k, v in pairs( methods ) do
		self[k] = v
	end
	 
	self:SetScript( "OnEnter", OnEnter )
	self:SetScript( "OnLeave", OnLeave ) 
	self:SetScript( "OnUpdate", function( self )
		if ( GameTooltip:IsOwned(self) ) then
			OnEnter( self )
		end
	end)
end

