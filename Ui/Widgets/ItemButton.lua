-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

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
	Me.Profile.inventory[ data ] = nil
	local cursorIcon = DiceMasterCursorItemIcon
	-- previous button
	cursorIcon.prevButton:Update()
	SetItemButtonDesaturated( cursorIcon.prevButton, false );
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
	cursorIcon.prevButton:Update()
	SetItemButtonDesaturated( cursorIcon.prevButton, false );
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

-------------------------------------------------------------------------------

function Me.FormatItemTooltip( text )
	name = name or UnitName("player")
	
	local plural_charges, singular_charges = Me.inspectData[name].charges.name:match( "^%s*(.*)/(.*)%s*$" )
	if not singular_charges then
		plural_charges   = Me.inspectData[name].charges.name
		singular_charges = plural_charges
		singular_charges = singular_charges:gsub( "[Ss]$", "" ) -- clip off an S :)
	end
	-- sub charges
	text = text:gsub( "&cs", singular_charges )
	text = text:gsub( "&cp", plural_charges )
	text = Me.FormatDescTooltip( text )
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
function Me.OpenItemTooltip( owner, item, index, isShopItem )
	
	if isShopItem and type(item) == "string" then
		Me.playerItemTooltipOpen  = true
		Me.playerItemTooltipName  = item
		Me.playerItemTooltipIndex = index
		item = Me.inspectData[item].shop[index]
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
		DiceMasterTooltipIcon.elite:Hide()
		local color = ITEM_QUALITY_COLORS[ item.quality ];
		GameTooltip:AddLine( item.name, color.r, color.g, color.b, true )
	end
	 
	if item.soulbound then
		GameTooltip:AddLine( "Binds when picked up", 1, 1, 1, true )
	end
	
	if item.whiteText1 and item.whiteText2 then
		GameTooltip:AddDoubleLine( item.whiteText1, item.whiteText2, 1, 1, 1, 1, 1, 1, true )
	end
	
	if item.useText then
		GameTooltip:AddLine( item.useText, 0, 1, 0, true )
	end
	
	if item.requirement then
		GameTooltip:AddLine( item.requirement, 0, 1, 0, true )
	end
	
	if item.flavorText and item.flavorText~="" then
		GameTooltip:AddLine( "\""..item.flavorText.."\"", 1, 0.81, 0, true )
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
			GameTooltip:AddLine( "Requires Level" .. item.requiredLevel, 1, 0, 0, true )
		end
	end
	
	if owner.InShopIcon and owner.InShopIcon:IsShown() then
		GameTooltip:AddLine( "This item is currently in your shop.", 1, 1, 0, true )
	end
	
	if item.cooldown and owner.Cooldown then
		if owner.Cooldown:GetCooldownDuration() > 0 then
			local currentTime = GetTime()
			local startTime, duration = owner:GetCooldown()
			
			local timeElapsed = math.ceil( duration - ( currentTime - startTime ) )
			timeElapsed = string.lower( SecondsToTime( timeElapsed, false ) )
			if timeElapsed and timeElapsed ~= "" then
				GameTooltip:AddLine( "Cooldown remaining: " .. timeElapsed, 1, 1, 1, true )
			end
			
			owner:SetScript( "OnUpdate", function( self )
				if GameTooltip:IsOwned( self ) then
					self:GetScript("OnEnter")( self )
				end
			end)
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
	DiceMasterTooltipIcon.elite:Hide()
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
	
	if not self.item and not self.itemPlayer and not self.itemShop then return end
	
	if self.item then
		Me.OpenItemTooltip( self, self.item )
	elseif self.itemPlayer then 
		Me.OpenItemTooltip( self, self.itemPlayer, self.itemIndex )
	elseif self.itemShop then
		Me.OpenItemTooltip( self, self.itemShop, self.itemIndex, true )
		if ( self:CanAffordShopItem() == false ) then
			SetCursor("BUY_ERROR_CURSOR");
		else
			SetCursor("BUY_CURSOR");
		end
		self.shopCursor = true;
	else
		return
	end
	 
end

local function OnLeave( self )
	if self.itemPlayer then
		Me.playerItemTooltipOpen = false
	end
	if self.shopCursor then
		ResetCursor();
		self.shopCursor = false;
	end
    GameTooltip:Hide()
	DiceMasterTooltipIcon:Hide()
	DiceMasterTooltipIcon.approved:Hide()
	DiceMasterTooltipIcon.elite:Hide()
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
	
	cursorIcon.sellCursor = nil;
	
	cursorIcon.splitItem = nil;
	cursorIcon.splitAmount = nil;
	
	cursorIcon.chooseCursor = nil;
	
	cursorIcon.requestCursor = nil;
	cursorIcon.requestItem = nil;
	
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

local EffectHandlers = {
	["book"] 	= "BookFrame_Show";
	["script"]	= "ScriptEditor_RunScript";
	["message"]	= "MessageEditor_SendMessage";
	["produce"]	= "ProduceItemEditor_ProduceItem";
	["currency"] = "ProduceCurrencyEditor_ProduceCurrency";
	["buff"]	= "BuffFrame_CastBuff";
	["removebuff"]	= "BuffFrame_RemoveBuff";
	["setdice"]	= "BuffFrame_RollDice";
	["effect"]	= "EffectPicker_PlayEffect";
	["sound"]	= "SoundPicker_PlaySound";
}

local function ExecuteEffects( effects )
	if not effects then
		return
	end
	
	for i = 1, #effects do
		local handler = EffectHandlers[ effects[i].type ]
		if Me[handler] then
			if effects[i].delay and effects[i].delay > 0 then
				C_Timer.After( effects[i].delay, function() Me[handler]( effects[i] ) end )
			else
				Me[handler]( effects[i] )
			end
		end
	end
end

local function OnClick( self, button )
	local item = Me.Profile.inventory[self.itemIndex]
	local cursorIcon = DiceMasterCursorItemIcon
	local startTime, duration = self:GetCooldown()
	StaticPopup_Hide("DICEMASTER4_DESTROYCUSTOMITEM")
	if ( button == "LeftButton" ) then
		-- TODO
		if cursorIcon.editCursor and self.hasItem then
			-- check if it's our item first!
			if item.author ~= UnitName("player") then
				UIErrorsFrame:AddMessage( "You don't have permission to edit that item.", 1.0, 0.0, 0.0, 53, 5 );
				return
			end
			Me.ClearCursorActions( true, true, true )
			Me.ItemEditor_Open( DiceMasterTraitEditor )
			Me.ItemEditor_LoadEditItem( self.itemIndex )
		elseif cursorIcon.chooseCursor and self.hasItem then
			-- check if it's our item first!
			if item.author ~= UnitName("player") then
				UIErrorsFrame:AddMessage( "You can't produce items created by other players.", 1.0, 0.0, 0.0, 53, 5 );
				return
			elseif Me.ItemEditing and Me.ItemEditingIndex == self.itemIndex then
				UIErrorsFrame:AddMessage( "Items cannot produce themselves.", 1.0, 0.0, 0.0, 53, 5 );
				return
			end
			Me.ClearCursorActions( true, true, true )
			--Me.ProduceItemEditor_Open( DiceMasterItemEditor )
			Me.ProduceItemEditor_LoadItem( self.itemIndex )
		elseif cursorIcon.copyCursor and self.hasItem then
			-- check if it's our item or copyable first!
			if not item.copyable and item.author ~= UnitName("player")  then
				UIErrorsFrame:AddMessage( "You don't have permission to copy that item.", 1.0, 0.0, 0.0, 53, 5 );
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
				UIErrorsFrame:AddMessage( "You don't have permission to sell that item.", 1.0, 0.0, 0.0, 53, 5 );
				return
			end
			-- check if it's already in our shop
			local found = false;
			for i = 1, #Me.Profile.shop do
				if Me.Profile.shop[i].guid == item.guid then
					found = true;
					break
				end
			end
			if found then
				UIErrorsFrame:AddMessage( "You are already selling that item.", 1.0, 0.0, 0.0, 53, 5 );
				return
			end
			Me.ClearCursorActions( true, true, true )
			Me.ShopEditor_Open( DiceMasterTraitEditor )
			Me.ShopEditor_LoadItem( self.itemIndex )
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
							local leftOver = _G["DiceMasterStatInspectorInventoryFrameItem"..self.itemIndex]:GetItem();
							leftOver.stackCount = remainder
							tinsert( Me.Profile.inventory, leftOver )
							Me.TraitEditor_UpdateInventory()
						end
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
					UIErrorsFrame:AddMessage( "Couldn't merge those items.", 1.0, 0.0, 0.0, 53, 5 );
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
				cursorIcon.prevButton:Update()
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
			Me.Inspect_SendStatus( dist, channel )
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
				string.format( "[DiceMaster4Item:%s:%d:%s]", UnitName("player"), self.itemIndex, name ) ) 
			
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
		if cursorIcon.copyCursor or cursorIcon.editCursor or cursorIcon.sellCursor or cursorIcon.chooseCursor then
			Me.ClearCursorActions( true, true, true )
		elseif cursorIcon.itemID then
			self:Update()
			
			-- previous slot
			cursorIcon.prevButton:Update()
			SetItemButtonDesaturated( cursorIcon.prevButton, false );
			
			-- clear cursor data
			Me.ClearCursorActions( true, true, true )
			PlaySound( 1203 )
		elseif duration > 0 then
			-- item is on cooldown
			UIErrorsFrame:AddMessage( "Item is not ready yet.", 1.0, 0.0, 0.0, 53, 5 ); 
		elseif item then
			-- use item
			item.lastCastTime = GetTime()
			CooldownFrame_Set( self.Cooldown, GetTime(), item.cooldown, 1 )
			
			if item.effects then
				ExecuteEffects( item.effects )
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
		-- TODO
		if cursorIcon.requestCursor and self.hasItem then
			Me.ClearCursorActions( true, true, true )
			-- Request the item.
			local msg = Me:Serialize( "ITEMREQ", {
				itemId = self.itemIndex;
			})
				
			Me:SendCommMessage( "DCM4", msg, "WHISPER", self.itemPlayer, "ALERT" )
			
			local icon = item.icon
			local colorHex = ITEM_QUALITY_COLORS[ item.quality ].hex or "|cffffffff";
			local itemLink = string.format("|T" .. icon .. ":16|t " .. colorHex .. "|HDiceMaster4Item:" .. self.itemPlayer .. ":" .. self.itemIndex .. "|h[%s]|h|r", item.name );
			
			if item.stackCount > 1 then
				Me.PrintMessage( "|cFFFFFF00You have requested " .. itemLink .. "x" .. item.stackCount .. " from " .. self.itemPlayer .. ".|r", "SYSTEM" )
			else
				Me.PrintMessage( "|cFFFFFF00You have requested " .. itemLink .. " from " .. self.itemPlayer .. ".|r", "SYSTEM" )
			end
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
			Me.Inspect_SendStatus( dist, channel )
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
				string.format( "[DiceMaster4Item:%s:%d:%s]", self.itemPlayer, self.itemIndex, name ) ) 
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
			UIErrorsFrame:AddMessage( "Inventory is full.", 1.0, 0.0, 0.0, 53, 5 ); 
			return
		end
		
		if data.price * amount > currency.value then
			UIErrorsFrame:AddMessage( "You do not have the required items for that purchase.", 1.0, 0.0, 0.0, 53, 5 );
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
				UIErrorsFrame:AddMessage( "Requires " .. rankString, 1.0, 0.0, 0.0, 53, 5 );
				return
			end
		end
		
		if data.requiredClass and ( next(data.requiredClass) ~= nil ) then
			if not data.requiredClass[ UnitClass("player") ] then
				UIErrorsFrame:AddMessage( "That item can't be used by players of your class!", 1.0, 0.0, 0.0, 53, 5 );
				return
			end
		end
		
		if data.requiredLevel then
			if Me.Profile.level < item.requiredLevel then
				UIErrorsFrame:AddMessage( "Requires Level " .. data.requiredLevel, 1.0, 0.0, 0.0, 53, 5 );
				return
			end
		end
		
		-- Send purchase approval.
		local msg = Me:Serialize( "ITEMBUY", {
			itemId = item.itemIndex;
			amount = amount * data.stackSize;
		})
			
		Me:SendCommMessage( "DCM4", msg, "WHISPER", item.itemShop, "ALERT" )
	end
end

local function OnShopClick( self, button )
	if ( button == "LeftButton" ) then	
		-- TODO
	elseif ( button == "RightButton" ) then
		-- TODO
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
			canAfford = floor( currency.value / (price / stackCount) );
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
		
		if player == UnitName("player") and self:GetParent() ~= Me.statinspector.inventoryFrame then
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
	-- Get item data.
	--
	-- Returns as a complete table.
	--
	GetItem = function( self, isShopItem )
		local data = {}
		
		if isShopItem then
			for k, v in pairs( Me.inspectData[self.itemShop].shop[self.itemIndex] ) do
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
				local startTime, duration = self:GetCooldown()
				CooldownFrame_Set( self.Cooldown, startTime, duration, 1 );
				if self:GetParent() ~= Me.statinspector.inventoryFrame then
					for i = 1, #Me.Profile.shop do
						if Me.Profile.shop[i].guid == item.guid then
							self.InShopIcon:Show()
							break
						end
					end
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
		local item = Me.inspectData[self.itemPlayer].inventory[self.itemIndex] or nil
		
		if not item then
			return GetTime(), 0;
		end
		
		local lastCastTime = item.lastCastTime
		local cooldown = item.cooldown
		if GetTime() - lastCastTime < cooldown then
			return lastCastTime, cooldown;
		end
		return GetTime(), 0;
	end;
	
	SplitStack = function( button, split )
		if ( split > 0 ) then
			Me.ShopFrame_PurchaseItem( self.itemIndex, split )
		end
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
			if item.price * amount <= currency.value then
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

