-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Trait Editing Panel
--

local Me      = DiceMaster4
local Profile = Me.Profile

local StatsListEntries = { };

local SHOP_ITEMS_PER_PAGE = 12;

-------------------------------------------------------------------------------
-- Refresh the statistics list.
--
--
function Me.StatInspector_Update()

	if Me.inspectName then
		Me.statInspectName = Me.inspectName
		SetPortraitTexture( Me.statinspector.portrait, "target" )
		Me.statinspector.TitleText:SetText( Me.GetTargetCharInfo() )
	end
	
	if not Me.statInspectName then
		return
	end
	
	--SetPortraitTexture( Me.statinspector.portrait, "target" )
	--Me.statinspector.TitleText:SetText( UnitName("target") )
	
	local store = Me.inspectData[Me.statInspectName]
	local stats = store.stats

	if ( not Me.statinspector:IsShown() ) then
		return;
	end
	
	Me.statinspector.experienceBar.level:SetText(store.level or 1)
	Me.statinspector.experienceBar:SetValue(store.experience or 0)

	local addButtonIndex = 0;
	local totalButtonHeight = 0;
	local function AddButtonInfo(id)
		addButtonIndex = addButtonIndex + 1;
		if ( not StatsListEntries[addButtonIndex] ) then
			StatsListEntries[addButtonIndex] = { };
		end
		StatsListEntries[addButtonIndex].id = id;
		totalButtonHeight = totalButtonHeight + 24
	end
	
	if #stats == 0 then
		Me.statinspector.scrollFrame.totals:Show()
	else
		Me.statinspector.scrollFrame.totals:Hide()
	end

	-- saved statistics
	for i = 1, #stats do
		AddButtonInfo(i);
	end

	Me.statinspector.scrollFrame.totalStatsListEntriesHeight = totalButtonHeight;
	Me.statinspector.scrollFrame.numStatsListEntries = addButtonIndex;

	Me.StatInspector_UpdateStats();
	
end

-------------------------------------------------------------------------------
-- Refresh the pet tab.
--
--
function Me.StatInspector_UpdatePet()
	
	if Me.inspectName and Me.inspectData[Me.inspectName] and Me.inspectData[Me.inspectName].pet and Me.inspectData[Me.inspectName].pet.enable then
		local pet = Me.inspectData[Me.inspectName].pet
		Me.statinspector.petFrame.petIcon:SetTexture( pet.icon )
		Me.statinspector.petFrame.petName:SetText( pet.name )
		Me.statinspector.petFrame.levelText:SetText( pet.type )
		Me.statinspector.petFrame.petModel:SetDisplayInfo( pet.model )
		PanelTemplates_EnableTab(DiceMasterStatInspector, 2)
	else
		if PanelTemplates_GetSelectedTab(DiceMasterStatInspector) == 2 then
			PanelTemplates_SetTab(DiceMasterStatInspector, 1);
			DiceMasterStatInspectorStatsFrame:Show();
			DiceMasterStatInspectorPetFrame:Hide();
			PlaySound(841)
		end
		PanelTemplates_DisableTab(DiceMasterStatInspector, 2)
	end
	
end

function Me.StatInspector_RequestItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.requestCursor = true;
	SetCursor( "CAST_CURSOR" )
end

local function RecycleInventorySlots()
	local tbl = {}
	for i = 1, #Me.inspectData[Me.statInspectName].inventory do
		if Me.inspectData[Me.statInspectName].inventory[i] ~= nil then
			table.insert( tbl, Me.inspectData[Me.statInspectName].inventory[i] )
		end
	end
	Me.inspectData[Me.statInspectName].inventory = tbl
end

function Me.StatInspector_UpdateInventory()
	DiceMasterStatInspectorInventoryTab.Icon:SetTexture( Me.inspectData[ Me.statInspectName ].inventoryIcon or "Interface/Buttons/Button-Backpack-Up" )
	local frame = Me.statinspector.inventoryFrame
	if( not frame.slots_initialized ) then
		frame.slots_initialized = true;
		frame.numRow = 7;
		frame.numColumn = 3;
		frame.numSubColumn = 2;
		frame.size = frame.numRow*frame.numColumn*frame.numSubColumn;
		
		-- setup slot backgrounds and shadows
		for column = 2, frame.numColumn do
			local texture = frame:CreateTexture(nil, "ARTWORK");
			frame["BG"..(column)] = texture;
			texture:SetPoint("TOPLEFT", frame["BG"..(column-1)], "TOPRIGHT", 5, 0);
			texture:SetAtlas("bank-slots", true);
			--texture:SetSize( 78, 247 );
			local shadow = frame:CreateTexture(nil, "BACKGROUND");
			shadow:SetPoint("CENTER", frame["BG"..(column)], "CENTER", 0, 0);
			shadow:SetAtlas("bank-slots-shadow", true);
			--shadow:SetSize( 85, 256 );
		end
		
		-- the item slots
		local slotOffsetX = 49;
		local slotOffsetY = 44;
		local id = 1;
		for column = 1, frame.numColumn do
			local leftOffset = 6;
			for subColumn = 1, frame.numSubColumn do
				for row = 0, frame.numRow-1 do
					local button = CreateFrame("Button", "DiceMasterStatInspectorInventoryFrameItem"..id, frame, "DiceMasterItemButton");
					button:SetSize( 37, 37 );
					button:SetID(id);
					button:SetPoint("TOPLEFT", frame["BG"..column], "TOPLEFT", leftOffset, -(1+row*slotOffsetY));
					frame["Item"..id] = button;
					id = id + 1;
				end
				leftOffset = leftOffset + slotOffsetX;
			end
		end
	end
	
	local button;
	for i=1, frame.size do
		button = frame["Item"..i];
		button:SetPlayerItem( Me.statInspectName or nil, i );
		button:Update()
	end
	
	local currencyActive = Me.inspectData[Me.statInspectName].currencyActive or 1;
	local currency = Me.inspectData[Me.statInspectName].currency[currencyActive]
	
	if not currency then
		currency = {
			name = "DiceMaster Coins";
			icon = "Interface/AddOns/DiceMaster/Texture/token";
			value = 0;
			guid = 0;
		}
	end
	
	DiceMasterStatInspectorInventoryFrameMoneyBgMoney:SetText( currency.value .. "|T" .. currency.icon .. ":12|t" )
	DiceMasterStatInspectorInventoryFrameMoneyBg:SetScript("OnEnter", function( self )
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
		GameTooltip:SetText( currency.name, 1, 1, 1 );
		if currencyActive == 1 then
			GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
		end
		GameTooltip:AddLine( "|nTotal: |cFFFFFFFF" .. currency.value .. "|r", nil, nil, nil, true );
		GameTooltip:Show();
	end)
end

function Me.StatInspectorShopFrame_OnUpdate( self, dt )
	if ( self.update == true ) then
		self.update = false;
		if ( self:IsVisible() ) then
			--Me.ShopFrame_UpdateShopInfo()
		end
	end
end

function Me.StatInspectorShopFrame_OnShow(self)
	local forceUpdate = true;
	
	Me.StatInspectorShopFrame_Update();
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN);
end

function Me.StatInspectorShopFrame_OnHide(self)
	ResetCursor();
	PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE);
end

function Me.StatInspectorShopFrame_OnMouseWheel(self, value)
	if ( value > 0 ) then
		if ( DiceMasterStatInspectorShopFramePrevPageButton:IsShown() and DiceMasterStatInspectorShopFramePrevPageButton:IsEnabled() ) then
			Me.StatInspectorShopFramePrevPageButton_OnClick();
		end
	else
		if ( DiceMasterStatInspectorShopFrameNextPageButton:IsShown() and DiceMasterStatInspectorShopFrameNextPageButton:IsEnabled() ) then
			Me.StatInspectorShopFrameNextPageButton_OnClick();
		end	
	end
end

function Me.StatInspectorShopFrame_Update()
	
	if not Me.statInspectName then
		return
	end
	
	DiceMasterStatInspectorShopTab.Icon:SetTexture( Me.inspectData[ Me.statInspectName ].shopIcon or "Interface/Icons/garrison_building_tradingpost" )

	local currencyActive = Me.inspectData[ Me.statInspectName ].currencyActive or 1;
	local currency = Me.inspectData[ Me.statInspectName ].currency[currencyActive]
	
	if not currency then
		currency = Me.Profile.currency[1]
	end
	
	-- Find the right currency
	local amount = 0;
	for i = 1, #Me.Profile.currency do
		if Me.Profile.currency[i].guid == currency.guid then
			amount = Me.Profile.currency[i].value
			break;
		end
	end
	
	DiceMasterStatInspectorShopFrameMoneyBgMoney:SetText( amount .. "|T" .. currency.icon .. ":12|t" )
	DiceMasterStatInspectorShopFrameMoneyBg:SetScript("OnEnter", function( self )
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
		GameTooltip:SetText( currency.name, 1, 1, 1 );
		if currencyActive == 1 then
			GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
		end
		GameTooltip:AddLine( "|nTotal: |cFFFFFFFF" .. amount .. "|r", nil, nil, nil, true );
		GameTooltip:Show();
	end)
	
	local numMerchantItems = #Me.inspectData[ Me.statInspectName ].shop
	
	DiceMasterStatInspectorShopFramePageText:SetFormattedText(MERCHANT_PAGE_NUMBER, DiceMasterStatInspectorShopFrame.page, math.ceil(numMerchantItems / 12));

	local name, texture, description, quality, price, stackCount, isPurchasable, isUsable;
	for i=1, SHOP_ITEMS_PER_PAGE do
		local index = (((DiceMasterStatInspectorShopFrame.page - 1) * SHOP_ITEMS_PER_PAGE) + i);
		local itemButton = _G["DiceMasterStatInspectorShopFrameItem"..i.."ItemButton"];
		local merchantButton = _G["DiceMasterStatInspectorShopFrameItem"..i];
		local merchantMoney = _G["DiceMasterStatInspectorShopFrameItem"..i.."MoneyFrame"];		
		local removeButton = _G["DiceMasterStatInspectorShopFrameItem"..i.."RemoveButton"];
		removeButton:Hide()
		
		if ( index <= numMerchantItems ) then
			local item = Me.inspectData[ Me.statInspectName ].shop[index]
			name = item.name
			texture = item.icon
			whiteText1 = item.whiteText1
			whiteText2 = item.whiteText2
			useText = item.useText
			flavorText = item.flavorText
			consumeable = item.consumeable
			soulbound = item.soulbound
			quality = item.quality
			price = item.price
			stackCount = item.stackSize
			requiredRank = item.requiredRank
			requiredClass = item.requiredClass
			requiredLevel = item.requiredLevel
			isPurchasable = true;
			isUsable = true;
			numAvailable = item.numAvailable or nil;
			
			-- Check purchase requirements
			-- Guild Rank
			if ( requiredRank ) and ( next(requiredRank) ~= nil ) then
				local guildName, guildRankName, guildRankIndex, realm = GetGuildInfo("player");
				if not guildRankName or not requiredRank[ guildRankName ] then
					isPurchasable = false;
				end
			end
			-- Class
			if ( requiredClass ) and ( next(requiredClass) ~= nil ) and not ( requiredClass[ UnitClass("player") ] ) then
				isPurchasable = false;
			end
			-- Level
			if ( requiredLevel ) and Me.Profile.level < requiredLevel then
				isPurchasable = false;
			end
			
			merchantButton.Name:SetText(name);
			SetItemButtonStock(itemButton, numAvailable or 0);
			SetItemButtonTexture(itemButton, texture);
			
			itemButton.price = price;
			itemButton.name = name;
			itemButton.texture = texture;
			itemButton.description = description

			if ( quality ) then
				merchantButton.Name:SetTextColor(ITEM_QUALITY_COLORS[quality].r, ITEM_QUALITY_COLORS[quality].g, ITEM_QUALITY_COLORS[quality].b);
				SetItemButtonQuality(itemButton, quality);
			end

			itemButton.hasItem = true;
			itemButton:SetID(index);
			itemButton:Show();
			
			itemButton:SetShopItem( Me.statInspectName, index )
			
			local canAfford = itemButton:CanAffordShopItem()
			
			local color;
			if (canAfford == false) then
				color = "gray";
			end
			_G["DiceMasterStatInspectorShopFrameItem"..i.."MoneyFrame".."Item1"]:SetNormalFontObject( "NumberFontNormalRightGray" )
			AltCurrencyFrame_Update("DiceMasterStatInspectorShopFrameItem"..i.."MoneyFrame".."Item1", item.currency.icon, price, canAfford);
			_G["DiceMasterStatInspectorShopFrameItem"..i.."MoneyFrame".."Item1"]:SetScript("OnEnter", function( self )
				GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
				GameTooltip:SetText( item.currency.name, 1, 1, 1 );
				if item.currency.guid == 0 then
					GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
				end
				GameTooltip:Show();
			end)
			_G["DiceMasterStatInspectorShopFrameItem"..i.."MoneyFrame".."Item1"]:Show()
			merchantMoney:Show();

			local tintRed = not isPurchasable or (not isUsable);

			if ( numAvailable and numAvailable == 0 ) then
				-- If not available and not usable
				if ( tintRed ) then
					SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0, 0);
					SetItemButtonSlotVertexColor(merchantButton, 0.5, 0, 0);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0, 0);
					SetItemButtonNormalTextureVertexColor(itemButton, 0.5, 0, 0);
				else
					SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
					SetItemButtonSlotVertexColor(merchantButton, 0.5, 0.5, 0.5);
					SetItemButtonTextureVertexColor(itemButton, 0.5, 0.5, 0.5);
					SetItemButtonNormalTextureVertexColor(itemButton,0.5, 0.5, 0.5);
				end
			elseif ( tintRed ) then
				SetItemButtonNameFrameVertexColor(merchantButton, 1.0, 0, 0);
				SetItemButtonSlotVertexColor(merchantButton, 1.0, 0, 0);
				SetItemButtonTextureVertexColor(itemButton, 0.9, 0, 0);
				SetItemButtonNormalTextureVertexColor(itemButton, 0.9, 0, 0);
			else
				SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
				SetItemButtonSlotVertexColor(merchantButton, 1.0, 1.0, 1.0);
				SetItemButtonTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
				SetItemButtonNormalTextureVertexColor(itemButton, 1.0, 1.0, 1.0);
			end
		else
			itemButton.price = nil;
			itemButton.hasItem = nil;
			itemButton.name = nil;
			itemButton:Hide();
			SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
			SetItemButtonSlotVertexColor(merchantButton,0.4, 0.4, 0.4);
			_G["DiceMasterStatInspectorShopFrameItem"..i.."Name"]:SetText("");
			_G["DiceMasterStatInspectorShopFrameItem"..i.."MoneyFrame"]:Hide();
		end
	end

	-- Handle paging buttons
	if ( numMerchantItems > SHOP_ITEMS_PER_PAGE ) then
		if ( DiceMasterStatInspectorShopFrame.page == 1 ) then
			DiceMasterStatInspectorShopFramePrevPageButton:Disable();
		else
			DiceMasterStatInspectorShopFramePrevPageButton:Enable();
		end
		if ( DiceMasterStatInspectorShopFrame.page == ceil(numMerchantItems / SHOP_ITEMS_PER_PAGE) or numMerchantItems == 0) then
			DiceMasterStatInspectorShopFrameNextPageButton:Disable();
		else
			DiceMasterStatInspectorShopFrameNextPageButton:Enable();
		end
		DiceMasterStatInspectorShopFramePageText:Show();
		DiceMasterStatInspectorShopFramePrevPageButton:Show();
		DiceMasterStatInspectorShopFrameNextPageButton:Show();
	else
		DiceMasterStatInspectorShopFramePageText:Hide();
		DiceMasterStatInspectorShopFramePrevPageButton:Hide();
		DiceMasterStatInspectorShopFrameNextPageButton:Hide();
	end

	-- Position merchant items
	MerchantItem3:SetPoint("TOPLEFT", "MerchantItem1", "BOTTOMLEFT", 0, -8);
	MerchantItem5:SetPoint("TOPLEFT", "MerchantItem3", "BOTTOMLEFT", 0, -8);
	MerchantItem7:SetPoint("TOPLEFT", "MerchantItem5", "BOTTOMLEFT", 0, -8);
	MerchantItem9:SetPoint("TOPLEFT", "MerchantItem7", "BOTTOMLEFT", 0, -8);
end

function Me.StatInspectorShopFramePrevPageButton_OnClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	DiceMasterStatInspectorShopFrame.page = DiceMasterStatInspectorShopFrame.page - 1;
	Me.StatInspectorShopFrame_Update();
end

function Me.StatInspectorShopFrameNextPageButton_OnClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	DiceMasterStatInspectorShopFrame.page = DiceMasterStatInspectorShopFrame.page + 1;
	Me.StatInspectorShopFrame_Update();
end
-------------------------------------------------------------------------------
-- Update the stat buttons.
--
--
function Me.StatInspector_UpdateStats()
	local scrollFrame = Me.statinspector.scrollFrame;
	local offset = HybridScrollFrame_GetOffset(scrollFrame);
	local buttons = scrollFrame.buttons;
	local numButtons = #buttons;
	local numStatButtons = scrollFrame.numStatsListEntries;

	local usedHeight = 0;

	for i = 1, numButtons do
		local button = buttons[i];
		local index = offset + i;
		if ( index <= numStatButtons ) then
			button.index = index;
			local height = Me.StatInspector_UpdateStatButton(button)
			button:SetHeight(height);
			usedHeight = usedHeight + height;
			
			button:Show()
		else
			button.index = nil;
			button:Hide();
		end
	end
	HybridScrollFrame_Update(scrollFrame, scrollFrame.totalStatsListEntriesHeight, usedHeight);
end

function Me.StatInspector_UpdateStatButton(button)
	local index = button.index;
	button.id = StatsListEntries[index].id;
	local stats = Me.inspectData[Me.statInspectName].stats
	local stat = stats[StatsListEntries[index].id]
	
	-- finish setting up button if it's not a header
	if ( stat ) then
	
		if stat.value then
		
			button.name:SetText(stat.name .. ":");
			button.title:SetText("");
			button.value:Show()
			button.value:SetText(stat.value);
			
			if Me.statInspectName == UnitName("player") then
				local buffValue = Me.TraitEditor_AddStatisticsToValue( stat.name )
				button.value:SetText(stat.value + buffValue);
			end
			
			Me.SetupTooltip( button, nil, stat.name )
			
			local skills = {}
			
			for i = 1, #stats do
				if stat.attribute then
					local desc = ""
					if stat.desc then
						desc = gsub( stat.desc, "Roll", "An attempt" )
						Me.SetupTooltip( button, nil, stat.name, nil, nil, "|cFFFFD100" .. desc .. "|n|cFF707070(Modified by " .. stat.attribute .. ")|r" )
					else
						Me.SetupTooltip( button, nil, stat.name, nil, nil, "|cFF707070(Modified by " .. stat.attribute .. ")|r" )
					end
				end
				if stats[i].attribute and stats[i].attribute == stat.name then
					tinsert( skills, stats[i].name )
				end
			end
			
			if Me.AttributeList[ stat.name ] then
				local skillsList = "|n|cFF707070(Modifies "
				for i = 1, #skills do
					if i > 1 and i == #skills then
						skillsList = skillsList .. ", and "
					elseif i > 1 then
						skillsList = skillsList .. ", "
					end
					skillsList = skillsList .. skills[i]
				end
				Me.SetupTooltip( button, nil, stat.name, nil, nil, "|cFFFFD100" .. Me.AttributeList[stat.name].desc .. skillsList .. ")|r" )
			end
			
		else
			Me.SetupTooltip( button, nil )
			button.name:SetText("");
			button.title:SetText(stat.name);
			button.value:Hide()
		end
		
		button:Show();
	else
		button:Hide();
	end
	return 24;
end

function Me.StatInspector_GetScrollFrameTopButton(offset)
	local usedHeight = 0;
	for i = 1, #StatsListEntries do
		local buttonHeight = 24
		if ( usedHeight + buttonHeight >= offset ) then
			return i - 1, offset - usedHeight;
		else
			usedHeight = usedHeight + buttonHeight;
		end
	end
end

-------------------------------------------------------------------------------
-- OnLoad handler
--
-- Be careful in here because it's run before the addon is loaded.
--
function Me.StatInspector_OnLoad( self )
	Me.statinspector = self
		
	self:SetClampedToScreen( true )
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )	 
end

-------------------------------------------------------------------------------
-- When the stat inspector's close button is pressed.
--
function Me.StatInspector_OnCloseClicked() 
	PlaySound(840); 
	DiceMasterStatInspector:Hide()
end

-------------------------------------------------------------------------------
-- Show the stat inspector.
--
function Me.StatInspector_Open()	
	--SetPortraitTexture( Me.statinspector.portrait, "target" )
	
	--Me.statinspector.TitleText:SetText( UnitName( "target" ) )
	
	Me.statinspector.CloseButton:SetScript("OnClick",Me.StatInspector_OnCloseClicked)

	Me.StatInspector_Update()
	Me.StatInspector_UpdatePet()
	Me.StatInspector_UpdateInventory()
	Me.StatInspectorShopFrame_Update()
	Me.statinspector:Show()
end