-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Shop Editing Panel
--

local Me      = DiceMaster4
local Profile = Me.Profile

Me.newShopItem = {};

local function GetTotalNumberOfItem( itemIndex )
	local total = 0
	for i = 1, 42 do
		if Me.Profile.inventory[ i ] and Me.Profile.inventory[ i ].guid == Me.Profile.inventory[ itemIndex ].guid then
			total = total + Me.Profile.inventory[ i ].stackCount
		end
	end
	return total
end

function Me.ShopEditorAmount_OnLoad( self )
	local item = DiceMasterTraitEditorInventoryFrame["Item"..Me.newShopItem.itemIndex]:GetItem();
	
	if not item then
		return
	end
	
	local maxStack = 0
	for i = 1, 42 do
		if Me.Profile.inventory[ i ] and Me.Profile.inventory[ i ].guid == item.guid then
			maxStack = maxStack + Me.Profile.inventory[ i ].stackCount
		end
		if maxStack == item.stackSize then
			break
		end
	end
	
	self:SetMinMaxValues(1, maxStack)
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Amount: "..self:GetValue())
	self.tooltipText = "Set the amount of this item available for purchase."
	DiceMasterShopEditor.itemStock:SetText( "(" .. self:GetValue() .. ")" )
end

function Me.ShopEditorAmount_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Amount: "..value)
	DiceMasterShopEditor.itemStock:SetText( "(" .. value .. ")" )
	if DiceMasterShopEditor.limitedSupplyCheckBox:GetChecked() then
		DiceMasterShopEditor.itemStock:Show()
		Me.newShopItem.limited = true;
	else
		DiceMasterShopEditor.itemStock:Hide()
		Me.newShopItem.limited = false;
	end
end

local ITEM_STACK_SIZES = {
	1,
	5,
	10,
	20,
	100,
	200,
}

function Me.ShopEditorStackSize_OnLoad( self )
	local item = DiceMasterTraitEditorInventoryFrame["Item"..Me.newShopItem.itemIndex]:GetItem();
	
	if not item then
		return
	end
	
	local maxSize = GetTotalNumberOfItem( Me.newShopItem.itemIndex )
	local maxStack = 1
	for i = 1, #ITEM_STACK_SIZES do
		if ( item.stackSize >= ITEM_STACK_SIZES[i] ) and ( ITEM_STACK_SIZES[i] <= maxSize ) then
			maxStack = i
		else
			break
		end
	end
	
	self:SetMinMaxValues(1, maxStack)
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Stack Size: "..ITEM_STACK_SIZES[self:GetValue()])
	self.tooltipText = "Set the stack size for this item."
	DiceMasterShopEditor.itemCount:SetText( "" )
	DiceMasterShopEditor.itemCount:Hide()
end

function Me.ShopEditorStackSize_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Stack Size: "..ITEM_STACK_SIZES[value])
	Me.newShopItem.stackSize = ITEM_STACK_SIZES[value];
	if value > 1 then
		DiceMasterShopEditor.itemCount:SetText( Me.newShopItem.stackSize )
		DiceMasterShopEditor.itemCount:Show()
	else
		DiceMasterShopEditor.itemCount:SetText( "" )
		DiceMasterShopEditor.itemCount:Hide()
	end
end

function Me.ShopEditorCurrency_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetSelectedValue(DiceMasterShopEditor.itemCurrency, arg1, false)
	local currency = Me.Profile.currency[arg1]
	Me.newShopItem.currencyName = currency.name;
	Me.newShopItem.currencyIcon = currency.icon;
	Me.newShopItem.currencyGUID = currency.guid;
	local price = DiceMasterShopEditor.itemPrice:GetText() or 0;
	if price == nil or price == "" then
		price = 0
	end
	AltCurrencyFrame_Update("DiceMasterShopEditorMoneyFrameItem1", currency.icon, price, true);
end

function Me.ShopEditorCurrency_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	local currencies = Me.Profile.currency
	
	for i = 1, #currencies do	
		info.text = "|T" .. currencies[i].icon .. ":16|t " .. currencies[i].name;
		info.arg1 = i
		info.value = i
		info.checked = UIDropDownMenu_GetText(DiceMasterShopEditor.itemCurrency) == info.text;
		info.notCheckable = false;
		info.func = Me.ShopEditorCurrency_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end
end

function Me.ShopEditorGuildRank_OnClick(self, arg1, arg2, checked)
	if not Me.newShopItem.requiredRank then
		Me.newShopItem.requiredRank = {}
	end
	
	if checked then
		Me.newShopItem.requiredRank[ arg2 ] = true;
	else
		Me.newShopItem.requiredRank[ arg2 ] = nil;
	end
	
	local ranksList = nil
	local count = 0
	for k, v in pairs( Me.newShopItem.requiredRank ) do
		if k then
			count = count + 1
		end
		if count == 1 then
			ranksList = k
		else
			ranksList = ranksList .. ", " .. k
		end
	end
	UIDropDownMenu_SetText( DiceMasterShopEditor.guildRankDropdown, ranksList or "(None)" )
end

function Me.ShopEditorGuildRank_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	
	if not IsInGuild() then
		return
	end

	for i = 1, GuildControlGetNumRanks() do
		local rankName = GuildControlGetRankName(i)
		info.text = rankName
		info.arg1 = i
		info.arg2 = rankName
		info.value = i
		info.isNotRadio = true;
		info.keepShownOnClick = true;
		info.checked = function()
			if Me.newShopItem.requiredRank then
				if Me.newShopItem.requiredRank[rankName] then
					return true
				end
			end
			return false
		end;
		info.notCheckable = false;
		info.func = Me.ShopEditorGuildRank_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end
end

function Me.ShopEditorClass_OnClick(self, arg1, arg2, checked)
	if not Me.newShopItem.requiredClass then
		Me.newShopItem.requiredClass = {}
	end
	
	if checked then
		Me.newShopItem.requiredClass[ arg2 ] = true;
	else
		Me.newShopItem.requiredClass[ arg2 ] = nil;
	end
	
	local classesList = nil
	local count = 0
	for k, v in pairs( Me.newShopItem.requiredClass ) do
		if k then
			count = count + 1
		end
		if count == 1 then
			classesList = k
		else
			classesList = classesList .. ", " .. k
		end
	end
	UIDropDownMenu_SetText( DiceMasterShopEditor.classDropdown, classesList or "(None)" )
end

function Me.ShopEditorClass_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	
	for i = 1, GetNumClasses() do
		local className, classFile, classID = GetClassInfo(i)
		local r, g, b, hex = GetClassColor( classFile )
		info.text = className
		info.colorCode = "|c" .. hex
		info.arg1 = i
		info.arg2 = className
		info.value = i
		info.isNotRadio = true;
		info.keepShownOnClick = true;
		info.checked = function()
			if Me.newShopItem.requiredClass then
				if Me.newShopItem.requiredClass[className] then
					return true
				end
			end
			return false
		end;
		info.notCheckable = false;
		info.func = Me.ShopEditorClass_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end 
end

function Me.ShopEditor_SavePrice()
	local price = DiceMasterShopEditor.itemPrice:GetText()
	if price == nil or price == "" then
		price = 0
	end
	Me.newShopItem.price = price;
	
	local currency = Me.newShopItem.currencyIcon or Me.Profile.currency[1].icon
	
	AltCurrencyFrame_Update("DiceMasterShopEditorMoneyFrameItem1", currency, price, true);
end

function Me.ShopEditor_SaveDMLevel()
	local level = DiceMasterShopEditor.dmLevel:GetText()
	level = tonumber( level ) or 0
	
	if level == nil or level == "" or level == 0 then
		return
	end
	
	Me.newShopItem.requiredLevel = level;
end

function Me.ShopEditor_LoadItem( itemIndex )
	local item = Me.Profile.inventory[itemIndex]
	Me.newShopItem.itemIndex = itemIndex;
	
	if not item then
		return
	end
	
	local data = DiceMasterTraitEditorInventoryFrame["Item"..itemIndex]:GetItem();
	local editor = DiceMasterShopEditor
	
	Me.ShopEditorAmount_OnLoad( DiceMasterShopEditor.amount )
	Me.ShopEditorStackSize_OnLoad( DiceMasterShopEditor.stackSize )
	
	editor.Name:SetText( data.name or "" )
	editor.itemIcon:SetTexture( data.icon or "Interface/Icons/inv_misc_questionmark" )
	
	local currencyActive = Me.Profile.currencyActive or 1;
	local currency = Me.Profile.currency[currencyActive]
	
	AltCurrencyFrame_Update("DiceMasterShopEditorMoneyFrameItem1", currency.icon, 0, true);
end

function Me.ShopEditor_SellItem()
	if not Me.newShopItem.itemIndex then
		return
	end

	local item = DiceMasterTraitEditorInventoryFrame["Item"..Me.newShopItem.itemIndex]:GetItem();
	
	if not item then
		return
	end
	
	item.price = Me.newShopItem.price or 0;
	item.stackCount = Me.newShopItem.stackSize or 1;
	--item.stackSize = Me.newShopItem.stackSize or 1;
	if Me.newShopItem.limited then
		item.numAvailable = item.amount;
	else
		item.numAvailable = false;
	end
	item.currency = {
		name = Me.newShopItem.currencyName or Me.Profile.currency[1].name;
		icon = Me.newShopItem.currencyIcon or Me.Profile.currency[1].icon;
		guid = Me.newShopItem.currencyGUID or Me.Profile.currency[1].guid;
	};
	item.requiredRank = Me.newShopItem.requiredRank or {};
	item.requiredClass = Me.newShopItem.requiredClass or {};
	item.requiredLevel = Me.newShopItem.requiredLevel or nil;
	
	local itemLink = Me.GetItemLink( UnitName("player"), item.guid )
	
	if item.stackCount > 1 then
		Me.PrintMessage( "|cFFFFFF00" .. itemLink .. "x" .. item.stackCount .. " has been added to your shop.|r", "SYSTEM" )
	else
		Me.PrintMessage( "|cFFFFFF00" .. itemLink .. " has been added to your shop.|r", "SYSTEM" )
	end
	PlaySound(895)
	tinsert( Me.Profile.shop, item)
	
	DiceMasterItemAnim.animIcon:SetTexture( item.icon );
	DiceMasterItemAnim:SetPoint( "CENTER", DiceMasterTraitEditorShopTab, 0, 0 )
	DiceMasterItemAnim:Show()
	
	Me.ShopFrame_Update()
	Me.TraitEditor_UpdateInventory()
	Me.ShopEditor_Close()
end

function Me.ShopEditor_ClearAllFields()
	local editor = DiceMasterShopEditor
	
	editor.Name:SetText( "" )
	editor.itemIcon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
	editor.itemCount:SetText( "" )
	editor.itemStock:SetText( "" )
	editor.itemPrice:SetText( "0" )
	
	local currencyActive = Me.Profile.currencyActive or 1;
	local currency = Me.Profile.currency[currencyActive]
	UIDropDownMenu_SetSelectedValue(editor.itemCurrency, currencyActive, false)
	AltCurrencyFrame_Update("DiceMasterShopEditorMoneyFrameItem1", currency.icon, 0, true);
	
	editor.limitedSupplyCheckBox:SetChecked( false )
	UIDropDownMenu_SetText( DiceMasterShopEditor.guildRankDropdown,"(None)" )
	UIDropDownMenu_SetText( DiceMasterShopEditor.classDropdown,"(None)" )
	
	editor.dmLevel:SetText( "0" )
	
	editor.amount:SetValue( 1 )
	editor.stackSize:SetValue( 1 )
	
	Me.newShopItem = {}
end

-------------------------------------------------------------------------------
-- Close the shop editor window. Use this instead of a direct Hide()
--
function Me.ShopEditor_Close()
	Me.ShopEditor_ClearAllFields()
	DiceMasterShopEditor:Hide()
	ResetCursor();
end
    
-------------------------------------------------------------------------------
-- Open the shop editor window.
--
function Me.ShopEditor_Open( frame )
	Me.CloseAllEditors()
	DiceMasterShopEditor:ClearAllPoints()
	DiceMasterShopEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterShopEditor:Show()
end

---------------------------------------------------------------------------
--  Receive a shop purchase request.

function Me.ShopEditor_BuyItem( data, dist, sender )	 
	-- sanitize message
	
	if not data.itemId or not data.amount then
	   
		return
	end
	
	local item = Me.Profile.shop[ data.itemId ];
	
	if not item then
		-- item doesn't exist/is no longer available for whatever reason
		return
	end
	
	if ( item.numAvailable and item.numAvailable == 0 ) then
		return
	end
	
	-- Send purchase approval.
	local msg = Me:Serialize( "ITEMGET", {
		itemId = data.itemId;
		amount = data.amount;
	})
		
	Me:SendCommMessage( "DCM4", msg, "WHISPER", sender, "ALERT" )
	
	-- Find the right currency
	local currency = nil
	for i = 1, #Me.Profile.currency do
		if Me.Profile.currency[i].guid == item.currency.guid then
			currency = Me.Profile.currency[i]
			break;
		end
	end
	
	currency.value = currency.value + item.price
	
	PlaySound(120)
	
	local itemLink = Me.GetItemLink( UnitName("player"), item.guid )
	
	if item.stackCount > 1 then
		Me.PrintMessage( "|cFFFFFF00" .. sender .. " has purchased " .. itemLink .. "x" .. item.stackCount .. " from your shop.|r", "SYSTEM" )
	else
		Me.PrintMessage( "|cFFFFFF00" .. sender .. " has purchased " .. itemLink .. " from your shop.|r", "SYSTEM" )
	end
	if currency.guid == 0 then
		Me.PrintMessage( "|cFFFFFF00You receive |cFFFFFFFF" .. item.price .. "|r|T" .. currency.icon .. ":16|t.|r", "SYSTEM" )
	else
		Me.PrintMessage( "|cFF00aa00You receive currency: |cFFFFFFFF[" .. currency.name .. "]|rx" .. item.price .. ".|r", "SYSTEM" )
	end
	
	if item.numAvailable then
		item.numAvailable = item.numAvailable - data.amount
		if item.numAvailable == 0 then
			Me.PrintMessage( "|cFFFFFF00" .. itemLink .. " is out of stock in your shop!|r", "SYSTEM" )
			C_Timer.After( 3, function() 
				--tremove( Me.Profile.shop, data.itemId )
				Me.ShopFrame_Update()
			end )
		end
	end
	
	Me.ShopFrame_Update()
	Me.TraitEditor_UpdateInventory()
end

---------------------------------------------------------------------------
--  Receive a shop purchase item.

function Me.ShopEditor_ReceiveItem( data, dist, sender )	 
	-- sanitize message
	
	if not data.itemId or not data.amount or not Me.inspectData[ sender ] or not Me.inspectData[ sender ].shop or not Me.inspectData[ sender ].shop[ data.itemId ] then
	   
		return
	end
	
	local item = {}
	for k, v in pairs( Me.inspectData[ sender ].shop[ data.itemId ] ) do
		item[k] = v;
	end
	
	if not data.amount then
		data.amount = 1;
	end
	
	-- Find the right currency
	local currency = nil
	for i = 1, #Me.Profile.currency do
		if Me.Profile.currency[i].guid == item.currency.guid then
			currency = Me.Profile.currency[i]
			break;
		end
	end
	
	if not currency then
		return
	end
	
	if tonumber( item.price ) > currency.value then
		return
	end
	
	if item.requiredRank and ( next(item.requiredRank) ~= nil ) then
		local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
		if not item.requiredRank[ guildRankName ] then
			return
		end
	end
	
	if item.requiredClass and ( next(item.requiredClass) ~= nil ) then
		if not item.requiredClass[ UnitClass("player") ] then
			return
		end
	end
	
	if item.requiredLevel then
		if Me.Profile.level < item.requiredLevel then
			return
		end
	end
	
	local stacks = Me.FindAllStacks( item.guid );
	
	if Me.FindTotalStacks( item.guid ) > 0 then
		Me.ProduceItem( item.guid, data.amount )
	else
		if item then
			Me.CreateItem( item, data.amount )
		else
			UIErrorsFrame:AddMessage( "Error producing item.", 1.0, 0.0, 0.0 );
			return
		end
	end
	
	currency.value = currency.value - tonumber( item.price )
	
	item.amount = data.amount
	local msg = Me:Serialize( "ITEM", item );
	Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName("player"), "NORMAL" )
	
	if item.numAvailable then
		C_Timer.After( 3, function() 
			Me.StatInspectorShopFrame_Update()
		end )
	end
	Me.ShopFrame_Update()
	Me.TraitEditor_UpdateInventory()
	
	PlaySound(120)
end