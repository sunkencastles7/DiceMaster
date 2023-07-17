-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Trait Editing Panel
--

local Me      = DiceMaster4
local Profile = Me.Profile

Me.editing_trait = 1
Me.statType = nil

local startOffset = 0
local filteredList = nil

local SHOP_ITEMS_PER_PAGE = 12;

local function TraitUpdated()
	local trait = Profile.traits[Me.editing_trait]
	Me.BumpSerial( Me.db.char.traitSerials, Me.editing_trait )
	Me.UpdatePanelTraits()
end

StaticPopupDialogs["DICEMASTER4_REMOVESHOPITEM"] = {
  text = "Are you sure you want to remove this item from your shop?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data)
	local item = Profile.shop[ data ]
	if not item then
		return
	end
	PlaySound(895)
	tremove( Profile.shop, data )
	DiceMasterTraitEditorShopFrame.page = 1
	Me.ShopFrame_Update()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_RESTOCKSHOPITEM"] = {
  text = "Amount to restock:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
	local item = Profile.shop[ data ]
	if not item or not item.numAvailable or item.numAvailable > 0 then
		return
	end
	
	local maxAmount = Me.FindTotalAmount( item.guid ) or 1;
	
    self.editBox:SetText( maxAmount )
	self.editBox:HighlightText()
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
	local item = Profile.shop[ data ]
	if not item or not item.numAvailable or item.numAvailable > 0 then
		return
	end
	PlaySound(895)
	
	local maxAmount = Me.FindTotalAmount( item.guid ) or 1;
	local amount = tonumber( self.editBox:GetText() ) or 1;
	
	if amount > maxAmount then
		return
	end
	
	Me.Profile.shop[ data ].numAvailable = amount
	Me.ShopFrame_Update()
	Me.Inspect_ShareStatusWithParty()
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_EXPORT"] = {
  text = "Copy the following import code:",
  button1 = "Okay",
  OnShow = function (self, data)
    self.editBox:SetText( data )
	self.editBox:HighlightText()
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_IMPORTTRAIT"] = {
  text = "Paste an import code into the field below and select 'Import' to import the trait.|n|nThis will overwrite your currently selected trait!",
  button1 = "Import",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText( "" )
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
	local data = self.editBox:GetText()
	
	if not data or data == nil or data == "" then
		UIErrorsFrame:AddMessage( "Invalid import code.", 1.0, 0.0, 0.0 );
		return
	end
	
	data = Me.Decrypt( data )
	T = nil
	RunScript("T=" .. data);
	
	if T and type( T ) == "table" and T.name and T.usage and T.desc and T.icon then
		Profile.traits[Me.editing_trait] = T;
		Me.PrintMessage( "|T" .. T.icon .. ":16|t " .. T.name .. " has been imported.", "SYSTEM" )
	else
		UIErrorsFrame:AddMessage( "Corrupt trait data found. Unable to import code.", 1.0, 0.0, 0.0 );
	end
	TraitUpdated()
	Me.TraitEditor_StartEditing( Me.editing_trait )
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  showAlert = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_IMPORTITEM"] = {
  text = "Paste an import code into the field below and select 'Import' to import the item.",
  button1 = "Import",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText( "" )
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
	local data = self.editBox:GetText()
	
	if not data or data == nil or data == "" then
		UIErrorsFrame:AddMessage( "Invalid import code.", 1.0, 0.0, 0.0 );
		return
	end
	
	data = Me.Decrypt( data )
	T = nil
	RunScript("T=" .. data);
	
	if T and type( T ) == "table" and T.name and T.stackCount and T.stackSize and T.guid then
		Me.CreateItem( T, T.stackCount )
		local itemLink = Me.GetItemLink( UnitName("player"), T.guid )
		Me.PrintMessage( itemLink .. " has been imported.", "SYSTEM" )
		T.amount = T.stackCount or 1;
		local itemData = Me:Serialize( "ITEM", T );
		Me:SendCommMessage( "DCM4", itemData, "WHISPER", UnitName("player"), "NORMAL" )
	else
		UIErrorsFrame:AddMessage( "Corrupt item data found. Unable to import code.", 1.0, 0.0, 0.0 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  showAlert = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_DELETETRAIT"] = {
  text = "Are you sure you want to delete this trait?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data)
	Me.TraitEditor_SelectIcon( "Interface/Icons/inv_misc_questionmark" )
    Me.editor.scrollFrame.Container.traitName:SetText("Trait Name")
	Me.editor.scrollFrame.Container.descEditor:SetText("Type a description for your trait here.")
	Me.TraitEditor_SaveName()
	Me.TraitEditor_SaveDescription()
	if not Me.editing_trait then return end
	
	Me.PrintMessage( "|T" .. Profile.traits[Me.editing_trait].icon .. ":16|t " .. Profile.traits[Me.editing_trait].name .. " has been deleted.", "SYSTEM" )
	
	if Me.editing_trait == 1 then
		Me.TraitEditor_StartEditing( Me.editing_trait )
	else
		Me.TraitEditor_StartEditing( Me.editing_trait - 1 )
	end
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_UNLEARNSKILL"] = {
  text = "Do you want to unlearn %s, and lose all proficiency in this skill?",
  button1 = "Unlearn",
  button2 = "Cancel",
  OnAccept = function (self, data)
	if not ( Me.Profile.skills[data] ) then
		return
	end
	
	Me.PrintMessage( "|cFFFFFF00You have unlearned " .. Me.Profile.skills[data].name .. ".", "SYSTEM" )
	tremove( Me.Profile.skills, data )
	DiceMasterSkillFrame.statusBarClickedPosition = nil;
	Me.SkillFrame_UpdateSkills()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- TUTORIAL STRINGS

local TRAIT_EDITOR_TUTORIAL = {
	"Left click on a trait to begin editing.",
	"You can choose a custom name, icon, description, and more for your trait in the Trait Editor.",
	"The format bar allows you to insert icons, colours, DiceMaster terms, and more into your trait's description.",
}

local PETS_TUTORIAL = {
	"Toggle whether or not your pet is active, enabling the Pet Frame and allowing other players to inspect your pet on the Inspect Frame.|n|nUse the buttons on the top bar to choose a model for your pet or adjust its scale.",
	"You can choose a custom name, icon, and more for your pet.|n|nThe Pet Item slot is used for items with the 'Learn Pet' action.",
}

local SKILLS_TUTORIAL = {
	"Your custom skills and current progress in those skills are listed here, representing your character's proficiency in a particular area.|n|nYou can learn new skills from custom items, or raise a skill's level by crafting or harvesting custom items of the appropriate level.",
	"Selecting a skill from the list above will display more details about the skill here.|n|nClick the 'Unlearn' button if you wish to unlearn the selected skill.",
	"Click the 'New' button to create a new custom skill.",
	"Choose your character's alignment from the dropdown menu.|n|nYou can export your skills with a unique import code which you can share with other players.",
}

local INVENTORY_TUTORIAL = {
	"Use the search box to search for specific items based on keyword.|n|nClick the Clean Up Inventory button to clean up your bags. It auto-sorts and moves items out of the way to make room for new items.",
	"Custom items occupy a slot in your inventory, up to a maximum of 42 slots.",
	"You can create, edit, copy, inspect, or sell items from your inventory by using these buttons.|n|nDungeon Masters can use the Loot button to allow group members to roll on an item in their inventory.|n|nYou can also export an item with a unique import code which other players can use to import the item.",
	"You can learn to craft items and gain proficiency in a custom skill using the Craft button.|n|nRecipes must be learned from a custom item before they show up in your recipe list.",
	"Right click the currency frame to change which of your custom currencies is displayed, or create a new one.",
}

if Me.PermittedUse() then
	INVENTORY_TUTORIAL[4] = INVENTORY_TUTORIAL[4] .. "|n|nCharacters with the Enchanting skill can use the Disenchant button to extract Arcane Dust from Disenchantable items." 
end

local SHOP_TUTORIAL = {
	"Toggle whether or not your shop is active, allowing other players to access your shop from the Inspect Frame.",
	"You can add items to your shop from your inventory, enabling other players to browse and purchase them using a custom currency.",
	"Right click the currency frame to change which of your custom currencies is displayed, or create a new one.",
}

local BANK_TUTORIAL = {
	"Use the search box to search for specific items based on keyword.|n|nClick the Clean Up Bank button to clean up your bank. It auto-sorts and moves items out of the way to make room for new items.",
	"Custom items stored in your bank can be accessed by all of your characters.|n|nYou can deposit items into your bank from your inventory, or withdraw them by right clicking them.",
	"You can export an item with a unique import code which you can share with other players.",
	"Right click the currency frame to change which of your custom currencies is displayed, or create a new one.",
}

local btype = function(s)
	if s == true then
		return "true";
	elseif s == false then
		return "false";
	else
		return type(s);
	end
end

local function TableToString(t, addCheck, skipNumberIndexes)
	local s = "{";
	for index, value in pairs(t) do
		if value == "!first" then
			index = format("\"%s\"", index);
		end
		if type(index) == "string" then
			index = format("\"%s\"", index);
		end
		if type(value) == "table" then
			if skipNumberIndexes and type(index) == "number" then
				s = format("%s%s,", s, TableToString(value, false, skipNumberIndexes));
			else
				s = format("%s[%s]=%s,", s, index, TableToString(value, false, skipNumberIndexes));
			end
		elseif type(value) == "number" then
			s = format("%s[%s]=%s,", s, index, value);
		elseif type(value) == "nil" then
			s = format("%s[%s]=%s,", s, index, "nil");
		elseif type(value) == "boolean" then
			s = format("%s[%s]=%s,", s, index, btype(value));
		elseif type(value) == "string" then
			value = gsub(value, "\\", "\\\\");
			value = gsub(value, "\n", "\\n");
			value = gsub(value, "\r", "\\r");
			value = gsub(value, "\"", "\\\"");
			s = format("%s[%s]=\"%s\",", s, index, value);
		end
	end
	s = format("%s}", s);

	return s;
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Me.Encrypt( data )
	return ((data:gsub('.', function(x) 
    local r,b='',x:byte()
    for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
    return r;
  end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
    if (#x < 6) then return '' end
    local c=0
    for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
    return b:sub(c+1,c+1)
  end)..({ '', '==', '=' })[#data%3+1])
end

function Me.Decrypt( data )
	data = string.gsub(data, '[^'..b..'=]', '')
  return (data:gsub('.', function(x)
    if (x == '=') then return '' end
    local r,f='',(b:find(x)-1)
    for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
    return r;
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if (#x ~= 8) then return '' end
    local c=0
    for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
    return string.char(c)
  end))
end

function Me.ValidateSkillSheet( sheet )
	-- Iterate through an imported skill sheet to check for errors in the data structure.
	-- We have to be EXTREMELY selective to avoid corrupting the Profile.skills table.
	if not type( sheet ) == "table" then return false end
	for i = 1, #sheet do
		local skill = sheet[i];
		if not type( skill ) == "table" then return false end
		if not type( skill.name ) == "string" or skill.name == "" then return false end
		if skill.desc then
			if not type( skill.desc ) == "string" then return false end
		end
		if skill.type then
			if not type( skill.type ) == "string" then return false end
		end
		if skill.rank then
			if not type( skill.rank ) == "number" then return false end
		end
		if skill.maxRank then
			if not type( skill.maxRank ) == "number" then return false end
		end
		if skill.author then
			if not type( skill.author ) == "string" then return false end
		end
		if skill.skillModifiers then
			if not type( skill.skillModifiers ) == "table" then return false end
			for index = 1, #skill.skillModifiers do
				local modifier = skill.skillModifiers[index];
				if modifier.name then
					if not type(modifier.name) == "string" or modifier.name == ""  then return false end
				end
				if modifier.icon then
					if not type(modifier.icon) == "string" or modifier.icon == "" then return false end
				end
				if modifier.rank then
					if not type(modifier.rank) == "number" then return false end
				end
			end
		end
		if skill.showOnMenu then
			if not type( skill.showOnMenu ) == "boolean" then return false end
		end
		if skill.canEdit then
			if not type( skill.canEdit ) == "boolean" then return false end
		end
	end
	return true
end

function Me.ValidateTrait( trait )
	if not type( trait ) == "table" then return false end
	if not( trait["name"] and type( trait["name"] ) == "string" ) then return end
	if not( trait["icon"] and type( trait["icon"] ) == "string" ) then return end
	if not( trait["desc"] and type( trait["desc"] ) == "string" ) then return end

	local t = {
		{ Me.TRAIT_USAGE_MODES, "usage" },
		{ Me.TRAIT_CAST_TIME_MODES, "castTime" },
		{ Me.TRAIT_RANGE_MODES, "range" },
		{ Me.TRAIT_COOLDOWN_MODES, "cooldown" },
	};
	for i = 1, #t do
		if trait[t[2]] then
			local found = false;
			for k,v in ipairs( t[1] ) do
				if trait[t[2]] == v then
					found = true;
					break
				end
			end
			if not( found ) then return end
		end
	end
	if trait["effects"] then
		for i = 1, #trait["effects"] do
			-- TODO
			-- iterate through effects and make sure they're clean
		end
	end
	return true
end

-------------------------------------------------------------------------------
-- Dropdown handlers for the Currency menu.
--

function Me.TraitEditor_SelectInventoryIcon( texture )
	Me.Profile.inventoryIcon = texture or "Interface/Buttons/Button-Backpack-Up"
	DiceMasterTraitEditorInventoryTab.Icon:SetTexture( texture )
end

function Me.TraitEditor_CurrencyList_OnClick(self, arg1, arg2, checked)
	Me.Profile.currencyActive = arg1
	Me.TraitEditor_UpdateInventory()
	Me.TraitEditor_UpdateBank()
	Me.ShopFrame_Update()
end

function Me.TraitEditor_CurrencyList_OnLoad()
	local info      = UIDropDownMenu_CreateInfo();
    info.text       = "Currencies";
	info.isTitle	= true;
    info.notCheckable = true;
    UIDropDownMenu_AddButton(info);
	   
	local currencies = Me.Profile.currency
	
	for i = 1, #currencies do
       local info      = UIDropDownMenu_CreateInfo();
       info.text       = "|T" .. currencies[i].icon .. ":16|t " .. currencies[i].name;
	   info.arg1	   = i;
	   info.isTitle	   = false;
       info.func       = Me.TraitEditor_CurrencyList_OnClick;
	   info.notCheckable = false;
	   info.checked    = Me.Profile.currencyActive == i;
       UIDropDownMenu_AddButton(info); 
	end
	
	local info      = UIDropDownMenu_CreateInfo();
    info.text       = "|cFF00FF00Create New...|r";
	info.func     = function() DiceMasterCurrencyEditor:Show() end;
    info.notCheckable = true;
    UIDropDownMenu_AddButton(info);
end

local SEARCH_PARAMETERS = { "name", "whiteText1", "whiteText2", "useText", "requirement", "flavorText", "author" }

function Me.TraitEditor_InventoryFilterChanged()
	local filter = DiceMasterTraitEditorInventoryFrame.searchBar:GetText():lower()
	for i = 1, DiceMasterTraitEditorInventoryFrame.size do
		local button = DiceMasterTraitEditorInventoryFrame["Item"..i];
		if #filter > 1 then
			if button.itemIndex and Me.Profile.inventory[button.itemIndex] then
				local item = Me.Profile.inventory[button.itemIndex]
				button.searchOverlay:Show()
				for param = 1, #SEARCH_PARAMETERS do
					local parameter = SEARCH_PARAMETERS[ param ]
					if item[ parameter ] and strfind( ( item[ parameter ]):lower(), filter ) then
						button.searchOverlay:Hide()
					end
				end
			end
		else
			button.searchOverlay:Hide()
		end
	end
end

function Me.TraitEditor_CleanUpInventory()
	local cursorIcon = DiceMasterCursorItemIcon
	-- previous slot
	if cursorIcon.prevButton and cursorIcon.prevButton.itemIndex then
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	-- clear cursor data
	Me.ClearCursorActions( true, true, true )
	
	local tbl = {}
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i] ~= nil then
			table.insert( tbl, Me.Profile.inventory[i] )
		end
	end
	
	local function compare( a, b )
		if a["name"] == b["name"] then
			return a["stackCount"] > b["stackCount"]
		end
		return a["name"] < b["name"]
	end
	
	table.sort( tbl, compare )
	
	Me.Profile.inventory = tbl
	Me.TraitEditor_UpdateInventory()
end

function Me.TraitEditor_UpdateInventory()
	DiceMasterTraitEditorInventoryTab.Icon:SetTexture( Me.Profile.inventoryIcon or "Interface/Buttons/Button-Backpack-Up" )
	local frame = DiceMasterTraitEditorInventoryFrame
	
	if( not frame.slots_initialized ) then
		frame.slots_initialized = true;
		frame.numRow = 7;
		frame.numColumn = 3;
		frame.numSubColumn = 2;
		frame.size = frame.numRow*frame.numColumn*frame.numSubColumn;
		
		for i = 2, frame.size do
			local button = CreateFrame("Button", "DiceMasterInventoryFrameItem"..i, frame, "DiceMasterItemButton");
			button:SetID(i);
			button:SetSize( 37, 37 );
			frame["Item"..i] = button;
			if ((i%6) == 1) then
				button:SetPoint("TOPLEFT", frame["Item"..(i-6)], "BOTTOMLEFT", 0, -7);
			else
				button:SetPoint("TOPLEFT", frame["Item"..(i-1)], "TOPRIGHT", 12, 0);
			end
		end
		for i = 1, frame.size do
			local texture = frame:CreateTexture(nil, "BORDER", "Bank-Slot-BG");
			texture:SetPoint("TOPLEFT", frame["Item"..i], "TOPLEFT", -6, 5);
			texture:SetPoint("BOTTOMRIGHT", frame["Item"..i], "BOTTOMRIGHT", 6, -7);
		end
	end
	
	local button;
	for i=1, frame.size do
		button = frame["Item"..i];
		button:SetPlayerItem( UnitName("player"), i )
		button:Update()
	end
	
	if ( Me.PermittedUse() ) then
		frame.disenchantButton:Show()
	else
		frame.disenchantButton:Hide()
	end
	
	local currencyActive = Me.Profile.currencyActive or 1;
	local currency = Me.Profile.currency[currencyActive]
	DiceMasterTraitEditorInventoryFrameMoneyBgMoney:SetText( currency.value .. "|T" .. currency.icon .. ":12|t" )
	DiceMasterTraitEditorInventoryFrameMoneyBg:SetScript("OnEnter", function( self )
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
		GameTooltip:SetText( currency.name, 1, 1, 1 );
		if currencyActive == 1 then
			GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
		elseif currency.description then
			GameTooltip:AddLine( currency.description, nil, nil, nil, true );
		end
		GameTooltip:AddLine( "|nTotal: |cFFFFFFFF" .. currency.value .. "|r", nil, nil, nil, true );
		GameTooltip:AddLine( "<Right Click to Change>", 0.44, 0.44, 0.44, true )
		if currencyActive > 1 then
			GameTooltip:AddLine( "<Alt+Right Click to Delete>", 0.44, 0.44, 0.44, true );
		end
		GameTooltip:Show();
	end)
end

function Me.TraitEditor_BankFilterChanged()
	local filter = DiceMasterTraitEditorBankFrame.searchBar:GetText():lower()
	for i = 1, 42 do
		local button = DiceMasterTraitEditorBankFrame["Item"..i];
		if #filter > 1 then
			if button.itemIndex and Me.db.global.bank[button.itemIndex] then
				local item = Me.db.global.bank[button.itemIndex]
				button.searchOverlay:Show()
				for param = 1, #SEARCH_PARAMETERS do
					local parameter = SEARCH_PARAMETERS[ param ]
					if item[ parameter ] and strfind( ( item[ parameter ]):lower(), filter ) then
						button.searchOverlay:Hide()
					end
				end
			end
		else
			button.searchOverlay:Hide()
		end
	end
end

function Me.TraitEditor_CleanUpBank()
	local cursorIcon = DiceMasterCursorItemIcon
	-- previous slot
	if cursorIcon.prevButton and cursorIcon.prevButton.itemIndex then
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	-- clear cursor data
	Me.ClearCursorActions( true, true, true )
	
	local tbl = {}
	for i = 1, 42 do
		if Me.db.global.bank[i] and Me.db.global.bank[i] ~= nil then
			table.insert( tbl, Me.db.global.bank[i] )
		end
	end
	
	local function compare( a, b )
		if a["name"] == b["name"] then
			return a["stackCount"] > b["stackCount"]
		end
		return a["name"] < b["name"]
	end
	
	table.sort( tbl, compare )
	
	Me.db.global.bank = tbl
	Me.TraitEditor_UpdateBank()
end

function Me.TraitEditor_UpdateBank()
	local frame = DiceMasterTraitEditorBankFrame
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
					local button = CreateFrame("Button", "DiceMasterBankFrameItem"..id, frame, "DiceMasterItemButton");
					button:SetSize( 37, 37 );
					button:SetID(id);
					button:SetPoint("TOPLEFT", frame["BG"..column], "TOPLEFT", leftOffset, -(3+row*slotOffsetY));
					frame["Item"..id] = button;
					id = id + 1;
				end
				leftOffset = leftOffset + slotOffsetX;
			end
		end
	end
	
	local button;
	for i=1, 42 do
		button = frame["Item"..i];
		button:SetBankItem( i )
		button:Update()
	end
	
	local currencyActive = Me.Profile.currencyActive or 1;
	local currency = Me.Profile.currency[currencyActive]
	DiceMasterTraitEditorBankFrameMoneyBgMoney:SetText( currency.value .. "|T" .. currency.icon .. ":12|t" )
	DiceMasterTraitEditorBankFrameMoneyBg:SetScript("OnEnter", function( self )
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
		GameTooltip:SetText( currency.name, 1, 1, 1 );
		if currencyActive == 1 then
			GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
		elseif currency.description then
			GameTooltip:AddLine( currency.description, nil, nil, nil, true );
		end
		GameTooltip:AddLine( "|nTotal: |cFFFFFFFF" .. currency.value .. "|r", nil, nil, nil, true );
		GameTooltip:AddLine( "<Right Click to Change>", 0.44, 0.44, 0.44, true )
		if currencyActive > 1 then
			GameTooltip:AddLine( "<Alt+Right Click to Delete>", 0.44, 0.44, 0.44, true );
		end
		GameTooltip:Show();
	end)
end

function Me.ShopFrame_SelectIcon( texture )
	Me.Profile.shopIcon = texture or "Interface/Icons/garrison_building_tradingpost"
	DiceMasterTraitEditorShopTab.Icon:SetTexture( texture )
	if not( Me.Profile.shopModel ) then
		SetPortraitToTexture( Me.editor.PortraitContainer.portrait, Me.Profile.shopIcon )
	end
end

function Me.ShopFrame_OnUpdate( self, dt )
	if ( self.update == true ) then
		self.update = false;
		if ( self:IsVisible() ) then
			Me.ShopFrame_UpdateShopInfo()
		end
	end
end

function Me.ShopFrame_OnShow(self)
	local forceUpdate = true;
	
	Me.ShopFrame_Update();
end

function Me.ShopFrame_OnHide(self)
	ResetCursor();
end

function Me.ShopFrame_OnMouseWheel(self, value)
	if ( value > 0 ) then
		if ( DiceMasterTraitEditorShopFramePrevPageButton:IsShown() and DiceMasterTraitEditorShopFramePrevPageButton:IsEnabled() ) then
			Me.ShopFramePrevPageButton_OnClick();
		end
	else
		if ( DiceMasterTraitEditorShopFrameNextPageButton:IsShown() and DiceMasterTraitEditorShopFrameNextPageButton:IsEnabled() ) then
			Me.ShopFrameNextPageButton_OnClick();
		end	
	end
end

function Me.ShopFrame_Update()
	DiceMasterTraitEditorShopTab.Icon:SetTexture( Me.Profile.shopIcon or "Interface/Icons/garrison_building_tradingpost" )	
	local currencyActive = Me.Profile.currencyActive or 1;
	local currency = Me.Profile.currency[currencyActive]
	DiceMasterTraitEditorShopFrameMoneyBgMoney:SetText( currency.value .. "|T" .. currency.icon .. ":12|t" )
	DiceMasterTraitEditorShopFrameMoneyBg:SetScript("OnEnter", function( self )
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
		GameTooltip:SetText( currency.name, 1, 1, 1 );
		if currencyActive == 1 then
			GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
		elseif currency.description then
			GameTooltip:AddLine( currency.description, nil, nil, nil, true );
		end
		GameTooltip:AddLine( "|nTotal: |cFFFFFFFF" .. currency.value .. "|r", nil, nil, nil, true );
		GameTooltip:AddLine( "<Right Click to Change>", 0.44, 0.44, 0.44, true )
		if currencyActive > 1 then
			GameTooltip:AddLine( "<Alt+Right Click to Delete>", 0.44, 0.44, 0.44, true );
		end
		GameTooltip:Show();
	end)
	
	local numMerchantItems = #Me.Profile.shop
	
	DiceMasterTraitEditorShopFramePageText:SetFormattedText(MERCHANT_PAGE_NUMBER, DiceMasterTraitEditorShopFrame.page, math.ceil(numMerchantItems / 12));
	
	--if numMerchantItems == 0 then
		--for i=1, SHOP_ITEMS_PER_PAGE do
			--_G["DiceMasterTraitEditorShopFrameItem"..i]:Hide();
		--end
	--end

	local name, texture, description, quality, price, stackCount, isPurchasable, isUsable;
	for i=1, SHOP_ITEMS_PER_PAGE do
		local index = (((DiceMasterTraitEditorShopFrame.page - 1) * SHOP_ITEMS_PER_PAGE) + i);
		local itemButton = _G["DiceMasterTraitEditorShopFrameItem"..i.."ItemButton"];
		local merchantButton = _G["DiceMasterTraitEditorShopFrameItem"..i];
		local merchantMoney = _G["DiceMasterTraitEditorShopFrameItem"..i.."MoneyFrame"];		
		local removeButton = _G["DiceMasterTraitEditorShopFrameItem"..i.."RemoveButton"];		
		local restockButton = _G["DiceMasterTraitEditorShopFrameItem"..i.."RestockButton"];		
		if ( index <= numMerchantItems ) then
			local item = Me.Profile.shop[index]
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
			
			removeButton:Show()
			restockButton:Hide()

			if ( quality ) then
				merchantButton.Name:SetTextColor(ITEM_QUALITY_COLORS[quality].r, ITEM_QUALITY_COLORS[quality].g, ITEM_QUALITY_COLORS[quality].b);
				SetItemButtonQuality(itemButton, quality);
			end

			itemButton.hasItem = true;
			itemButton:SetID(index);
			itemButton:Show();
			
			itemButton:SetShopItem( UnitName("player"), index )
			
			local canAfford = itemButton:CanAffordShopItem()
			
			local color;
			if (canAfford == false) then
				color = "gray";
			end
			_G["DiceMasterTraitEditorShopFrameItem"..i.."MoneyFrame".."Item1"]:SetNormalFontObject( "NumberFontNormalRightGray" )
			AltCurrencyFrame_Update("DiceMasterTraitEditorShopFrameItem"..i.."MoneyFrame".."Item1", item.currency.icon, price, canAfford);
			_G["DiceMasterTraitEditorShopFrameItem"..i.."MoneyFrame".."Item1"]:SetScript("OnEnter", function( self )
				GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
				GameTooltip:SetText( item.currency.name, 1, 1, 1 );
				if item.currency.guid == 0 then
					GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
				elseif currency.description then
					GameTooltip:AddLine( currency.description, nil, nil, nil, true );
				end
				GameTooltip:Show();
			end)
			_G["DiceMasterTraitEditorShopFrameItem"..i.."MoneyFrame".."Item1"]:Show()
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
				restockButton:Show()
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
			removeButton:Hide()
			SetItemButtonNameFrameVertexColor(merchantButton, 0.5, 0.5, 0.5);
			SetItemButtonSlotVertexColor(merchantButton,0.4, 0.4, 0.4);
			_G["DiceMasterTraitEditorShopFrameItem"..i.."Name"]:SetText("");
			_G["DiceMasterTraitEditorShopFrameItem"..i.."MoneyFrame"]:Hide();
		end
	end

	-- Handle paging buttons
	if ( numMerchantItems > SHOP_ITEMS_PER_PAGE ) then
		if ( DiceMasterTraitEditorShopFrame.page == 1 ) then
			DiceMasterTraitEditorShopFramePrevPageButton:Disable();
		else
			DiceMasterTraitEditorShopFramePrevPageButton:Enable();
		end
		if ( DiceMasterTraitEditorShopFrame.page == ceil(numMerchantItems / SHOP_ITEMS_PER_PAGE) or numMerchantItems == 0) then
			DiceMasterTraitEditorShopFrameNextPageButton:Disable();
		else
			DiceMasterTraitEditorShopFrameNextPageButton:Enable();
		end
		DiceMasterTraitEditorShopFramePageText:Show();
		DiceMasterTraitEditorShopFramePrevPageButton:Show();
		DiceMasterTraitEditorShopFrameNextPageButton:Show();
	else
		DiceMasterTraitEditorShopFramePageText:Hide();
		DiceMasterTraitEditorShopFramePrevPageButton:Hide();
		DiceMasterTraitEditorShopFrameNextPageButton:Hide();
	end

	-- Position merchant items
	MerchantItem3:SetPoint("TOPLEFT", "MerchantItem1", "BOTTOMLEFT", 0, -8);
	MerchantItem5:SetPoint("TOPLEFT", "MerchantItem3", "BOTTOMLEFT", 0, -8);
	MerchantItem7:SetPoint("TOPLEFT", "MerchantItem5", "BOTTOMLEFT", 0, -8);
	MerchantItem9:SetPoint("TOPLEFT", "MerchantItem7", "BOTTOMLEFT", 0, -8);
	
	Me.Inspect_ShareStatusWithParty()
end

function Me.ShopFramePrevPageButton_OnClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	DiceMasterTraitEditorShopFrame.page = DiceMasterTraitEditorShopFrame.page - 1;
	Me.ShopFrame_Update();
end

function Me.ShopFrameNextPageButton_OnClick()
	PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	DiceMasterTraitEditorShopFrame.page = DiceMasterTraitEditorShopFrame.page + 1;
	Me.ShopFrame_Update();
end

function Me.TraitEditor_CopyItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.copyCursor = true;
	SetCursor( "CAST_CURSOR" )
end

function Me.TraitEditor_EditItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.editCursor = true;
	SetCursor( "CAST_CURSOR" )
end

function Me.TraitEditor_InspectItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.inspectCursor = true;
	SetCursor( "INSPECT_CURSOR" )
end

function Me.TraitEditor_SellItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.sellCursor = true;
	SetCursor( "CAST_CURSOR" )
end

function Me.TraitEditor_AddItemToBank()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.bankCursor = true;
	SetCursor( "CAST_CURSOR" )
end

function Me.TraitEditor_GenerateItemExportCode( item )
	if not item then
		return
	end 
	
	local exportData = TableToString( item )
	exportData = Me.Encrypt( exportData )
	StaticPopup_Show( "DICEMASTER4_EXPORT", nil, nil, exportData )
end

function Me.TraitEditor_ExportItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.exportCursor = true;
	SetCursor( "CAST_CURSOR" )
end

function Me.TraitEditor_DisenchantItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.disenchantCursor = true;
	SetCursor( "CAST_CURSOR" )
end

function Me.TraitEditor_FeedPetItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	DiceMasterTraitEditorInventoryTab:Click()
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.feedCursor = true;
	SetCursor( "CAST_CURSOR" )
end

-------------------------------------------------------------------------------
-- Loot dropdown list.
--
--

function Me.TraitEditor_LootOnClick(self, arg1)
	if not arg1 then
		return
	end
	arg1()
end

function Me.TraitEditor_LootOnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.isNotRadio = true;
	info.notCheckable = true;
	info.text = "Loot Options";
	info.isTitle = true;
	UIDropDownMenu_AddButton(info, level);
	info.isTitle = false;
	info.disabled = false; 
	info.func = Me.TraitEditor_LootOnClick;
	info.tooltipOnButton = true;
	info.text = "Master Loot";
	info.arg1 = Me.TraitEditor_MasterLootItem;
	info.tooltipTitle = "Master Loot";
	info.tooltipText = "Distribute an item to a specific player."
	UIDropDownMenu_AddButton(info, level);
	info.text = "Group Loot";
	info.arg1 = Me.TraitEditor_GroupLootItem;
	info.tooltipTitle = "Group Loot";
	if Me.PermittedUse() then
		info.tooltipText = "Allow all group members to roll Need, Greed, Disenchant, or Pass on an item."
	else
		info.tooltipText = "Allow all group members to roll Need, Greed, or Pass on an item."
	end
	UIDropDownMenu_AddButton(info, level);
end

function Me.TraitEditor_GroupLootItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.lootCursor = true;
	cursorIcon.lootType = "GROUPLOOT";
	SetCursor( "CAST_CURSOR" )
end

function Me.TraitEditor_MasterLootItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.lootCursor = true;
	cursorIcon.lootType = "MASTERLOOT";
	SetCursor( "CAST_CURSOR" )
end

-------------------------------------------------------------------------------

local happinessTypes = {
	[1] = { name = "Unhappy", desc = "Your pet is unhappy." },
	[2] = { name = "Content", desc = "Your pet is contented, but not really happy." },
	[3] = { name = "Happy", desc = "Your pet is perfectly happy with you and the world." },
}

function Me.PetEditor_UpdateHappiness()
	-- Calculate pet happiness
	local happiness = 3;
	local tooltipDesc = "";
	if Profile.pet.isHungry then
		happiness = happiness - 1;
		tooltipDesc = tooltipDesc .. "|n|cFFFFFFFFHungry|r|nYour pet is hungry and requires food!|n";
	end
	if Profile.pet.isStinky then
		happiness = happiness - 1;
		tooltipDesc = tooltipDesc .. "|n|cFFFFFFFFStinky|r|nYour pet is filthy and needs a bath!|n";
	end
	if Profile.pet.isTired then
		happiness = happiness - 1;
		tooltipDesc = tooltipDesc .. "|n|cFFFFFFFFSleepy|r|nYour pet is exhausted and requires rest!|n";
	end
	if Profile.pet.isDirty then
		happiness = happiness - 1;
		tooltipDesc = tooltipDesc .. "|n|cFFFFFFFFDirty|r|nYour pet stables could use a good cleaning!|n";
		DiceMasterPetModelFlies:Show();
	else
		DiceMasterPetModelFlies:Hide();
	end
	if Profile.pet.isCold then
		happiness = happiness - 1;
		tooltipDesc = tooltipDesc .. "|n|cFFFFFFFFCold|r|nYour pet needs warmth in order to hatch!|n";
	end
	if Profile.pet.name then
		tooltipDesc = tooltipDesc:gsub( "Your pet", Profile.pet.name );
	end
	DiceMasterPetFrame.petHappiness.tooltipDesc = tooltipDesc;
	happiness = Me.Clamp( happiness, 1, 3);
	Profile.pet.happiness = happiness;
	if ( happiness == 1 ) then
		DiceMasterPetFrame.petHappiness.Texture:SetTexCoord(0.375, 0.5625, 0, 0.359375);
	elseif ( happiness == 2 ) then
		DiceMasterPetFrame.petHappiness.Texture:SetTexCoord(0.1875, 0.375, 0, 0.359375);
	elseif ( happiness == 3 ) then
		DiceMasterPetFrame.petHappiness.Texture:SetTexCoord(0, 0.1875, 0, 0.359375);
	end
end

function Me.PetEditor_Happiness_OnEnter()
	GameTooltip:SetOwner(DiceMasterPetFrame.petHappiness, "ANCHOR_RIGHT");
	GameTooltip_SetTitle(GameTooltip, happinessTypes[ Profile.pet.happiness or 3 ].name, HIGHLIGHT_FONT_COLOR);
	GameTooltip_AddNormalLine(GameTooltip, happinessTypes[ Profile.pet.happiness or 3 ].desc, true);
	if DiceMasterPetFrame.petHappiness.tooltipDesc then
		GameTooltip_AddNormalLine(GameTooltip, DiceMasterPetFrame.petHappiness.tooltipDesc, true);
	end
	GameTooltip:Show();
end

-------------------------------------------------------------------------------
-- Reload pet data and update the UI.
--
function Me.PetEditor_Refresh()
	DiceMasterPetFrame.petIcon:SetTexture( Profile.pet.icon )
	DiceMasterPetFrame.petName:SetText( Profile.pet.name )
	DiceMasterPetFrame.petType:SetText( Profile.pet.type )
	DiceMasterPetModel:SetModelByCreatureDisplayID( Profile.pet.model )
	DiceMasterPetModel:SetScale( Profile.pet.scale or 0.2 )
	DiceMasterPetFrame.enable:SetChecked( Profile.pet.enable )

	if UnitFactionGroup("player") == "Alliance" then
		DiceMasterPetFrameModelBG:SetTexture("Interface/AddOns/DiceMaster/Texture/PetFrameBackgroundAlliance")
	else
		DiceMasterPetFrameModelBG:SetTexture("Interface/AddOns/DiceMaster/Texture/PetFrameBackgroundHorde")
	end

	if Profile.pet.enable and Profile.pet.isComplex then
		local timestamp = time(date("*t"));
		
		if Profile.pet.isEgg then
			-- Egg type pets don't need washing...
			if ( Profile.pet.lastWarmed and Profile.pet.lastWarmed + 86400 <= timestamp ) or not( Profile.pet.lastWarmed ) then
				Profile.pet.isCold = true;
			end
			DiceMasterPetFrame.washButton:Hide()
			DiceMasterPetFrame.cleanUpButton:Hide()
		else
			if ( Profile.pet.lastFed and Profile.pet.lastFed + 604800 <= timestamp ) or not( Profile.pet.lastFed ) then
				Profile.pet.isHungry = true;
			end
			
			if ( Profile.pet.lastBM and Profile.pet.lastBM + 86400 <= timestamp ) or not( Profile.pet.lastBM ) then
				Profile.pet.lastBM = timestamp;
				Profile.pet.isDirty = true;
				if not( Profile.pet.numBMs ) then
					Profile.pet.numBMs = 1;
				else
					Profile.pet.numBMs = Profile.pet.numBMs + 1;
					if #Profile.pet.numBMs > 3 then
						Profile.pet.numBMs = 3;
					end
				end
				for i = 1, Profile.pet.numBMs do
					if not DiceMasterPetFrame.petModelScene["poodad"..i] then
						DiceMasterPetFrame.petModelScene["poodad"..i] = DiceMasterPetFrame.petModelScene:CreateActor("poodad"..i, "DiceMasterPetFrameActorTemplate");
					end
					DiceMasterPetFrame.petModelScene["poodad"..i]:SetModelByFileID(1011411);
					DiceMasterPetFrame.petModelScene["poodad"..i]:SetScale(0.2);
					DiceMasterPetFrame.petModelScene["poodad"..i]:SetPosition(-2, (i - 2), 0);
					DiceMasterPetFrame.petModelScene["poodad"..i]:SetAlpha(1);
					DiceMasterPetFrame.petModelScene["poodad"..i]:Show();
				end
			end
			DiceMasterPetFrame.washButton:Show()
			DiceMasterPetFrame.cleanUpButton:Show()
		end
		
		if ( Profile.pet.lastWash and Profile.pet.lastWash + 259200 <= timestamp ) or not( Profile.pet.lastWash ) then
			Profile.pet.isStinky = true;
		end
		
		Me.PetEditor_UpdateHappiness()
		
		DiceMasterPetFrame.petHappiness:Show()
		DiceMasterPetFrame.feedButton:Show()
		DiceMasterPetFrame.restButton:Show()
		DiceMasterPetFrame.selectModel:Hide()
		DiceMasterPetFrame.increaseScale:Hide()
		DiceMasterPetFrame.decreaseScale:Hide()
		DiceMasterPetFrame.petType:SetEnabled( false );
	else
		DiceMasterPetFrame.petHappiness:Hide()
		DiceMasterPetFrame.washButton:Hide()
		DiceMasterPetFrame.restButton:Hide()
		DiceMasterPetFrame.feedButton:Hide()
		DiceMasterPetFrame.selectModel:Show()
		DiceMasterPetFrame.increaseScale:Show()
		DiceMasterPetFrame.decreaseScale:Show()
		DiceMasterPetFrame.petType:SetEnabled( true );
	end
end

-------------------------------------------------------------------------------
-- Set the icon texture of the pet.
--
-- @param texture Path to texture file to use for the pet.
--
function Me.PetEditor_SelectIcon( texture )
	Profile.pet.icon = texture or "Interface/Icons/inv_misc_questionmark"
	DiceMasterPetFrame.petIcon:SetTexture( texture )
	Me.RefreshPetFrame()
end

-------------------------------------------------------------------------------
-- Handler for when the name editor loses focus.
--
function Me.PetEditor_SaveName()
	Profile.pet.name = DiceMasterPetFrame.petName:GetText()
	Me.RefreshPetFrame()
end

-------------------------------------------------------------------------------
-- Handler for when the type editor loses focus.
--
function Me.PetEditor_SaveType()
	Profile.pet.type = DiceMasterPetFrame.petType:GetText()
	Me.RefreshPetFrame()
end

-------------------------------------------------------------------------------
-- Decrease the scale of the pet.
--
function Me.PetEditor_DecreaseScale()
	local scale = Profile.pet.scale;
	Profile.pet.scale = Me.Clamp( Profile.pet.scale - 0.01, 0, 1 );
	Me.PetEditor_Refresh()
end

-------------------------------------------------------------------------------
-- Increase the scale of the pet.
--
function Me.PetEditor_IncreaseScale()
	local scale = Profile.pet.scale;
	Profile.pet.scale = Me.Clamp( Profile.pet.scale + 0.01, 0, 1 );
	Me.PetEditor_Refresh()
end

-------------------------------------------------------------------------------
-- Handler for feeding the pet an item.
--
local foodTypeVisuals = {
	["Meat"] = 19012,
	["Fruit"] = 20633,
	["Bread"] = 405,
	["Fungus"] = 96790,
	["Fish"] = 94109,
	["Cheese"] = 115629,
}

function Me.PetEditor_FeedPet( item )
	if DiceMasterPetModel:GetModelFileID() == 0 then
		-- we can't feed a pet that doesn't exist...
		return
	end
	
	local found = false;
	if item and item.properties and Profile.pet.foodTypes then
		for foodType = 1, #Profile.pet.foodTypes do
			if item.properties[ Profile.pet.foodTypes[foodType] ] then
				found = Profile.pet.foodTypes[foodType];
				break
			end
		end
	end
	
	if not found then
		UIErrorsFrame:AddMessage( "Your pet doesn't like that food.", 1.0, 0.0, 0.0 );
		return
	end
	
	-- open the pet tab
	DiceMasterTraitEditorTab3:Click()
	
	local timestamp = time(date("*t"));
	Profile.pet.lastFed = timestamp;
	Profile.pet.isHungry = false;
	
	if foodTypeVisuals[ found ] then
		DiceMasterPetModel:SetSpellVisualKit( foodTypeVisuals[ found ], true )
	end
	
	DiceMasterPetModel:SetSpellVisualKit( 232, true ) -- "Food heal" sparkles
	DiceMasterPetModel:SetAnimation( 61 )
	PlaySound( 157742 ) -- Eating sound
	Me.PetEditor_UpdateHappiness()
end

-------------------------------------------------------------------------------
-- Handler for washing the pet.
--
function Me.PetEditor_WashPet()
	if Profile.pet.isStinky then
		DiceMasterPetModel:SetModelByCreatureDisplayID( Profile.pet.model )
		Profile.pet.isStinky = false;
		local timestamp = time(date("*t"));
		Profile.pet.lastWash = timestamp;
	end
	DiceMasterPetModel:SetSpellVisualKit( 110361, true )
	DiceMasterPetModel:SetAnimation( 10 )
	PlaySound( 73126 )
	Me.PetEditor_UpdateHappiness()
end

-------------------------------------------------------------------------------
-- Handler for resting the pet.
--
function Me.PetEditor_RestPet()
	if Profile.pet.isTired then
		DiceMasterPetModel:SetModelByCreatureDisplayID( Profile.pet.model )
		Profile.pet.isTired = false;
		local timestamp = time(date("*t"));
		Profile.pet.lastNap = timestamp;
	end
	DiceMasterPetModel:SetAnimation( 99 )
	DiceMasterPetModel.animation = 100;
	PlaySound( 1509 )
	Me.PetEditor_UpdateHappiness()
end

function Me.PetEditor_EndRest()
	if Profile.pet.isTired then
		DiceMasterPetModel:SetModelByCreatureDisplayID( Profile.pet.model )
		Profile.pet.isTired = false;
		local timestamp = time(date("*t"));
		Profile.pet.lastNap = timestamp;
	end
	DiceMasterPetModel:SetAnimation( 101 )
	DiceMasterPetModel.animation = 0;
	Me.PetEditor_UpdateHappiness()
end

-------------------------------------------------------------------------------
-- Handler for cleaning up after the pet.
--
function Me.PetEditor_CleanPetDroppings()
	if not DiceMasterPetFrame.petModelScene.broom then
		DiceMasterPetFrame.petModelScene.broom = DiceMasterPetFrame.petModelScene:CreateActor("broom", "DiceMasterPetFrameActorTemplate");
		DiceMasterPetFrame.petModelScene.broom.animation = 4;
		DiceMasterPetFrame.petModelScene.broom:SetModelByFileID(123129);
		DiceMasterPetFrame.petModelScene.broom:SetScale(0.2);
		DiceMasterPetFrame.petModelScene.broom:SetYaw(1);
		DiceMasterPetFrame.petModelScene.broom:SetAlpha(1);
	end
	DiceMasterPetFrame.petModelScene.broom:Show();
	DiceMasterPetFrame.petModelScene.broom:SetPosition(-2,-4,0);
	local willPlay, soundHandle = PlaySound(9129);
	
	DiceMasterPetFrame.petModelScene:SetScript("OnUpdate", function( self, elapsed )
		local x, y, z = DiceMasterPetFrame.petModelScene.broom:GetPosition();
		DiceMasterPetFrame.petModelScene.broom:SetPosition(-2, y+0.012, 0);
	end)
	
	if Profile.pet.numBMs then
		local index = 0;
		local ticker = C_Timer.NewTicker( 1, function()
			index = index + 1;
			if DiceMasterPetFrame.petModelScene["poodad"..index] then
				UIFrameFadeOut( DiceMasterPetFrame.petModelScene["poodad"..i], 1, 1, 0 );
			end
		end, Profile.pet.numBMs)
	end
	
	C_Timer.After( 5, function()
		PlaySound(34161);
		if soundHandle then 
			StopSound(soundHandle);
		end
		Profile.pet.numBMs = 0;
		Profile.pet.isDirty = false;
		DiceMasterPetFrame.petModelScene.broom:Hide();
	end);
	Me.PetEditor_UpdateHappiness()
end

-------------------------------------------------------------------------------
-- Handler for warming the pet egg.
--
function Me.TraitEditor_WarmPetEgg()
	if not( Profile.pet.isEgg ) then
		return
	end
	
	local timestamp = time(date("*t"));
	Profile.pet.lastWarmed = timestamp;
	Profile.pet.isCold = false;
	Me.PetEditor_UpdateHappiness()
end

-------------------------------------------------------------------------------
-- Skill Frame
--
function Me.SkillFrame_OnShow()
	Me.SkillFrame_UpdateSkills()
end

function Me.SkillFrame_OnLoad( self )
	DiceMasterSkillListScrollFrameScrollBar:SetValue(0);
	
	self.skillButtons = {};
	self.skillRankBars = {};
	
	for i = 2, 12 do
		self.skillButtons[i] = CreateFrame( "Button", "DiceMasterSkillTypeLabel" .. i, self, "DiceMasterSkillLabelTemplate" )
		self.skillButtons[i]:SetPoint( "LEFT", "DiceMasterSkillTypeLabel" .. ( i - 1 ), 0, -18 )
		
		self.skillRankBars[i] = CreateFrame( "StatusBar", "DiceMasterSkillRankFrame" .. i, self, "DiceMasterSkillStatusBarTemplate" )
		self.skillRankBars[i]:SetMinMaxValues( 0, 1 )
		self.skillRankBars[i]:SetValue( 1 )
		self.skillRankBars[i]:SetID( i )
		self.skillRankBars[i]:SetPoint( "TOPLEFT", "DiceMasterSkillRankFrame" .. ( i - 1 ), "BOTTOMLEFT", 0, -3 )
	end
end

local function GetSkillLineInfo( skillIndex )
	Me.SkillFrame_BuildFilteredList()
	local skill = filteredList[skillIndex];
		
	return skill.name, skill.icon or "Interface/Icons/inv_misc_questionmark", skill.desc, skill.type, skill.rank or 0, skill.maxRank or 0, skill.author, skill.guid, skill.skillModifiers or {}, skill.showOnMenu or nil, skill.canEdit or nil;
end

local function GetSkillLineInfoByPosition( skillPosition )
	local skill = Profile.skills[skillPosition];
		
	return skill.name, skill.icon or "Interface/Icons/inv_misc_questionmark", skill.desc, skill.type, skill.rank or 0, skill.maxRank or 0, skill.author, skill.guid, skill.skillModifiers or {}, skill.showOnMenu or nil, skill.canEdit or nil;
end

function Me.SkillFrame_ExpandAllSkills()
	local list = Me.Profile.skills
	for i = 1, #list do
		if not( list[i].type == "header" ) then
			Me.Profile.skills[i].expanded = true;
		end
	end
	Me.SkillFrame_UpdateSkills()
end

function Me.SkillFrame_CollapseAllSkills()
	local list = Me.Profile.skills
	for i = 1, #list do
		if not( list[i].type == "header" ) then
			Me.Profile.skills[i].expanded = false;
		end
	end
	Me.SkillFrame_UpdateSkills()
end

function Me.SkillFrame_ExpandSkillHeader( skillPosition )
	local list = Me.Profile.skills
	for i = skillPosition + 1, #list do
		if list[i] then
			if list[i].type == "header" then
				-- Stop when we reach another header
				break
			else
				Me.Profile.skills[i].expanded = true;
			end
		end
	end
	Me.SkillFrame_UpdateSkills()
end

function Me.SkillFrame_CollapseSkillHeader( skillPosition )
	local list = Me.Profile.skills
	for i = skillPosition + 1, #list do
		if list[i] then
			if list[i].type == "header" then
				-- Stop when we reach another header
				break
			else
				Me.Profile.skills[i].expanded = false;
			end
		end
	end
	Me.SkillFrame_UpdateSkills()
end

function Me.SkillFrame_IncreaseButton_OnClick( self, button )
	local skillPosition = DiceMasterSkillDetailStatusBarUnlearnButton.skillPosition
	if not( Me.Profile.skills[skillPosition] ) then 
		return
	end
	
	local skillName, skillIcon, skillDescription, skillType, skillRank, skillMaxRank, skillAuthor, skillGUID, skillModifiers, skillShowOnMenu, skillCanEdit = GetSkillLineInfoByPosition(skillPosition)
	if skillAuthor == UnitName("player") or skillCanEdit then
		if IsShiftKeyDown() then
			Me.Profile.skills[skillPosition].maxRank = Me.Clamp( Me.Profile.skills[skillPosition].maxRank + 1, 0, 9999 )
		elseif skillMaxRank > 0 then
			Me.Profile.skills[skillPosition].rank = Me.Clamp( Me.Profile.skills[skillPosition].rank + 1, -1 * Me.Profile.skills[skillPosition].maxRank, Me.Profile.skills[skillPosition].maxRank )
		else
			Me.Profile.skills[skillPosition].rank = Me.Clamp( Me.Profile.skills[skillPosition].rank + 1, -9999, 9999 )
		end
	else
		UIErrorsFrame:AddMessage( "You can't do that.", 1.0, 0.0, 0.0 );
	end
	Me.SkillFrame_UpdateSkills()
end

function Me.SkillFrame_DecreaseButton_OnClick( self, button )
	local skillPosition = DiceMasterSkillDetailStatusBarUnlearnButton.skillPosition
	if not( Me.Profile.skills[skillPosition] ) then 
		return
	end
	
	local skillName, skillIcon, skillDescription, skillType, skillRank, skillMaxRank, skillAuthor, skillGUID, skillModifiers, skillShowOnMenu, skillCanEdit = GetSkillLineInfoByPosition(skillPosition)
	if skillAuthor == UnitName("player") or skillCanEdit then
		if IsShiftKeyDown() then
			Me.Profile.skills[skillPosition].maxRank = Me.Clamp( Me.Profile.skills[skillPosition].maxRank - 1, 0, 9999 )
			if Me.Profile.skills[skillPosition].rank > Me.Profile.skills[skillPosition].maxRank then
				Me.Profile.skills[skillPosition].rank = Me.Profile.skills[skillPosition].maxRank
			end
		elseif skillMaxRank > 0 then
			Me.Profile.skills[skillPosition].rank = Me.Clamp( Me.Profile.skills[skillPosition].rank - 1, -1 * Me.Profile.skills[skillPosition].maxRank, Me.Profile.skills[skillPosition].maxRank )
		else
			Me.Profile.skills[skillPosition].rank = Me.Clamp( Me.Profile.skills[skillPosition].rank - 1, -9999, 9999 )
		end
	else
		UIErrorsFrame:AddMessage( "You can't do that.", 1.0, 0.0, 0.0 );
	end
	Me.SkillFrame_UpdateSkills()
end

function Me.SkillFrame_ShowButton_OnClick( self, button )
	local skillPosition = self:GetParent().skillPosition
	if not( Me.Profile.skills[skillPosition] ) then 
		return
	end
	
	Me.Profile.skills[skillPosition].showOnMenu = not( Me.Profile.skills[skillPosition].showOnMenu );
	self.visible = Me.Profile.skills[skillPosition].showOnMenu;
	Me.SkillFrame_UpdateSkills()
	self:GetScript("OnEnter")( self );
end

function Me.SkillFrame_RollButton_OnClick( self, button )
	local skillPosition = self:GetParent().skillPosition
	if not( Me.Profile.skills[skillPosition] ) then 
		return
	end

	local skill = Profile.skills[skillPosition];
	local dice = DiceMasterPanelDice:GetText();
	local modifiers = Me.GetModifiersFromSkillGUID( skill.guid, true );
	dice = Me.FormatDiceString( dice, modifiers ) or "D20";
	
	Me.Roll( dice, skill.name );
	if not( DiceMasterPanel.ModelScene:IsShown() ) then
		DiceMasterPanel.ModelScene:Show();
	end
	PlaySound(36625);
end

local function CheckForEmptyHeaders()
	for i = 1, #Profile.skills do
		if Profile.skills[i].type == "header" then
			local header = Profile.skills[i];
			if Profile.skills[i + 1] and Profile.skills[i + 1].type == "header" then
				tremove( Profile.skills, i );
			end
		end
	end
end

function Me.SkillFrame_BuildFilteredList()
	CheckForEmptyHeaders()
	filteredList = {}
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].expanded or Me.Profile.skills[i].type == "header" then
			local skill = Me.Profile.skills[i];
			skill.skillPosition = i;
			tinsert( filteredList, skill )
		end
	end
end

function Me.SkillFrame_CreateDefaults()
	Profile.skills = {};
	local skill = {
		name = "Attributes";
		type = "header";
		author = UnitName("player");
	}
	tinsert(Profile.skills, skill)
	
	for k, v in pairs( Me.AttributeList ) do
		local skill = {
			name = k;
			icon = "Interface/Icons/inv_misc_questionmark";
			desc = v.desc;
			type = "Attributes";
			rank = 0;
			maxRank = 5;
			author = UnitName("player");
			expanded = true,
			showOnMenu = false,
			guid = k;
			canEdit = true;
		}
		tinsert(Profile.skills, skill)
	end
	
	for k, v in pairs( Me.RollList ) do
		local skill = {
			name = k;
			type = "header";
			author = UnitName("player");
		}
		tinsert(Profile.skills, skill)
		for i = 1, #v do
			local skill = {
				name = v[i].name;
				icon = "Interface/Icons/inv_misc_questionmark";
				desc = v[i].desc;
				rank = 0;
				maxRank = 5;
				skillModifiers = { v[i].skill };
				author = UnitName("player");
				expanded = true;
				showOnMenu = true;
				guid = Me.GenerateGUID() .. v[i].name;
				canEdit = true;
			}
			tinsert(Profile.skills, skill)
		end
	end
	
	Me.SkillFrame_UpdateSkills();
	DiceMasterTraitEditor.NoSkillsWarning:Hide();
	Me.PrintMessage( "|cFF8080ffYou have gained ".. #Profile.skills .." new skills.|r", "SYSTEM" )
end

local function Placer_OnUpdate(self)
	local cursorX, cursorY = GetCursorPosition();
	local uiScale = UIParent:GetScale();
	self:ClearAllPoints();
	self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cursorX / uiScale, cursorY / uiScale);
end

function Me.SkillFrame_SelectIcon( texture )
	if not( DiceMasterSkillFrame.statusBarClickedPosition ) then
		return
	end

	local skill = Profile.skills[DiceMasterSkillFrame.statusBarClickedPosition];
	skill.icon = texture or "Interface/Icons/inv_misc_questionmark"
	DiceMasterSkillDetailSkillIconButton:SetTexture( texture )
	Me.SkillFrame_UpdateSkills();
end

function Me.SkillFrame_DragStart( button, buttonType )
	local cursorX, cursorY = GetCursorPosition();
	local uiScale = UIParent:GetScale();
	-- button:ClearAllPoints();
	DiceMasterSkillLabelPlacer:SetPoint("TOP", UIParent, "BOTTOMLEFT", cursorX / uiScale, cursorY / uiScale);
	DiceMasterSkillLabelPlacer.skillStatusBar.icon:SetTexture( button:GetParent().icon:GetTexture() )
	DiceMasterSkillLabelPlacer.skillStatusBar.skillName:SetText( button:GetParent().skillName:GetText() )
	DiceMasterSkillLabelPlacer.skillStatusBar.skillName:ClearAllPoints();
	DiceMasterSkillLabelPlacer.skillStatusBar.skillName:SetPoint("LEFT", DiceMasterSkillLabelPlacer.skillStatusBar, "LEFT", 6, 1);
	DiceMasterSkillLabelPlacer.skillStatusBar.skillRank:SetText( button:GetParent().skillRank:GetText() )
	DiceMasterSkillLabelPlacer.skillStatusBar.fillBar:Hide();
	DiceMasterSkillLabelPlacer.skillStatusBar:SetStatusBarColor(0.5, 0.5, 0.5);
	DiceMasterSkillLabelPlacerBackground:SetVertexColor(0.5, 0.5, 0.5, 0.5);
	DiceMasterSkillLabelPlacerBackground:Show();
	DiceMasterSkillLabelPlacer.skillStatusBar:SetMinMaxValues( button:GetParent():GetMinMaxValues() )
	DiceMasterSkillLabelPlacer.skillStatusBar:SetValue( button:GetParent():GetValue() )
	DiceMasterSkillLabelPlacer.skillPosition = button:GetParent().skillPosition;
	DiceMasterSkillLabelPlacer.skillStatusBar:Show();
	DiceMasterSkillLabelPlacer:Show();
	DiceMasterSkillLabelPlacer:EnableMouse(false);
	DiceMasterSkillLabelPlacer:SetScript("OnUpdate", Placer_OnUpdate);
end

function Me.SkillFrame_DragStop( self, button )
	if ( DiceMasterSkillLabelPlacer:IsShown() ) then
		DiceMasterSkillLabelPlacer:Hide();
		
		if GetMouseFocus()~=nil and GetMouseFocus():GetParent()~=nil and GetMouseFocus():GetParent():GetName():find( "DiceMasterSkillRankFrame" ) then
			local newPosition = GetMouseFocus():GetParent().skillPosition;
			local oldPosition = DiceMasterSkillLabelPlacer.skillPosition;
			
			local skillOne = Profile.skills[ newPosition ];
			local skillTwo = Profile.skills[ oldPosition ];
			
			Profile.skills[ oldPosition ] = skillOne;
			Profile.skills[ newPosition ] = skillTwo;
			Me.SkillFrame_UpdateSkills()
		end
	end
end

local function deepCopy( table )
	local t = {}
	for k,v in pairs(table) do
		if type(v) == "table" then
			v = deepCopy(v);
		end
		t[k] = v;
	end
	return t;
end

function Me.SkillFrame_ExportSheet()
	local sheet = {};
	for i = 1, #Profile.skills do 
		sheet[i] = deepCopy(Profile.skills[i]);
		if DiceMasterExportDialog.ExclusionControl:GetChecked() then
			if sheet[i].rank then
				sheet[i].rank = 0;
			end
		end
	end
	
	if not( Me.ValidateSkillSheet(sheet) ) then
		return
	end
	
	sheet = TableToString( sheet );
	sheet = Me.Encrypt( sheet );
	
	DiceMasterExportDialog.titleText = "Export Skills";
	DiceMasterExportDialog:Show();
	DiceMasterExportDialog.ExclusionControl:Show();
	DiceMasterExportDialog.ImportControl.InputContainer.EditBox:SetText( sheet );
	DiceMasterExportDialog.ImportControl.InputContainer:UpdateScrollChildRect();
	DiceMasterExportDialog.ImportControl.InputContainer:SetVerticalScroll(DiceMasterExportDialog.ImportControl.InputContainer:GetVerticalScrollRange());
	DiceMasterExportDialog.ImportControl.InputContainer.EditBox:HighlightText();
	DiceMasterExportDialog.ImportControl.InputContainer.EditBox:SetFocus();
end

function Me.SkillFrame_ImportSheet()
	local text = DiceMasterImportDialog.ImportControl.InputContainer.EditBox:GetText();
	
	if not text or text == nil or text == "" then
		UIErrorsFrame:AddMessage( "Invalid import code.", 1.0, 0.0, 0.0 );
		return
	end
	
	text = Me.Decrypt( text );
	T = nil;
	RunScript( "T=" .. text );
	
	local backup = Profile.skills or nil;
	
	if not( T and Me.ValidateSkillSheet(T)) then 
		if backup then
			Profile.skills = backup;
		end
		UIErrorsFrame:AddMessage( "Invalid import code. 2", 1.0, 0.0, 0.0 );
		return 
	end
	
	Profile.skills = T;
	if #Profile.skills > 10 then
		Me.PrintMessage( "|cFF8080ffYou have gained ".. #Profile.skills .." new skills.|r", "SYSTEM" );
	else
		for i = 1, #Profile.skills do
			local skill = Profile.skills[i];
			if skill.name and not( skill.type == "header" ) then
				Me.PrintMessage( "|cFF8080ffYou have gained the ".. skill.name .." skill.|r", "SYSTEM" );
			end
		end
	end
	Me.SkillFrame_UpdateSkills()
	
	if not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		Me.Inspect_SendSkills( "RAID" )
	end
end

function Me.SkillFrameTemplate_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo();
	info.text = "Skill Templates";
	info.isTitle = true;
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info);
	info.text = "Default Template";
	info.tooltipTitle = "Default";
	info.tooltipText = "A standard set of attributes, skills, and saving throws.";
	info.tooltipOnButton = true;
	info.isTitle = false;
	info.notClickable = false;
	info.func = Me.SkillFrame_CreateDefaults;
	info.disabled = false;
	UIDropDownMenu_AddButton(info);
	info.text = CreateAtlasMarkup("editmode-new-layout-plus") .. " |cFF00FF00Import|r";
	info.tooltipTitle = CreateAtlasMarkup("editmode-new-layout-plus") .. " |cFF00FF00Import|r";
	info.tooltipText = "Use a code to import a template made by another player.";
	info.arg1 = 0;
	info.value = 0;
	info.notCheckable = true;
	info.isTitle = false;
	info.disabled = false;
	info.func = function() DiceMasterImportDialog:Show(); end;
	UIDropDownMenu_AddButton(info, level);
end

function Me.SkillFrameAlignment_OnClick(self, arg1, arg2, checked)
	Me.Profile.alignment = arg1;
	UIDropDownMenu_SetSelectedValue(DiceMasterSkillFrameAlignmentDropdown, arg1, false)
	UIDropDownMenu_SetText( DiceMasterSkillFrameAlignmentDropdown, "|cFFFFD100Alignment:|r " .. Me.Profile.alignment )
end

function Me.SkillFrameAlignment_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo();
	if level == 1 then
		info.text = "Alignments";
		info.isTitle = true;
		info.notClickable = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);
		info.hasArrow = true;
		for k,v in pairs( Me.AlignmentList ) do
			info.text = k;
			info.isTitle = false;
			info.notClickable = false;
			info.disabled = false;
			info.menuList = k;
			UIDropDownMenu_AddButton(info);
		end
		info.text = "(None)";
		info.arg1 = "(None)";
		info.func = Me.SkillFrameAlignment_OnClick;
		info.notCheckable = false;
		info.hasArrow = false;
		info.isTitle = false;
		info.tooltipTitle = "(None)";
		info.tooltipText = "This character has no alignment.";
		info.tooltipOnButton = true;
		info.menuList = nil;
		info.checked = Me.Profile.alignment == info.text;
		UIDropDownMenu_AddButton(info, level);
	elseif menuList then
		for i = 1, #Me.AlignmentList[menuList] do
			info.text = Me.AlignmentList[menuList][i].name;
			info.arg1 = Me.AlignmentList[menuList][i].name;
			info.func = Me.SkillFrameAlignment_OnClick;
			info.notCheckable = false;
			info.isTitle = false;
			info.tooltipTitle = Me.AlignmentList[menuList][i].name;
			info.tooltipText = Me.AlignmentList[menuList][i].desc .. "|n|nExamples: |cFFFFFFFF" .. Me.AlignmentList[menuList][i].examples[1];
			for example = 2, #Me.AlignmentList[menuList][i].examples do
				info.tooltipText = info.tooltipText .. ", " .. Me.AlignmentList[menuList][i]["examples"][example];
			end
			info.tooltipOnButton = true;
			info.checked = Me.Profile.alignment == info.text;
			UIDropDownMenu_AddButton(info, level);
		end
	end
end
 
function Me.SkillFrame_SetStatusBar( statusBarID, skillIndex, numSkills )
	-- Get info
	local skillName, skillIcon, skillDescription, skillType, skillRank, skillMaxRank, skillAuthor, skillGUID, skillModifiers, skillShowOnMenu, skillCanEdit = GetSkillLineInfo(skillIndex);
	local skillRankStart = skillRank;

	-- Skill bar objects
	local statusBar = _G["DiceMasterSkillRankFrame"..statusBarID];
	local statusBarLabel = "DiceMasterSkillRankFrame"..statusBarID;
	local statusBarSkillRank = _G["DiceMasterSkillRankFrame"..statusBarID.."SkillRank"];
	local statusBarName = _G["DiceMasterSkillRankFrame"..statusBarID.."SkillName"];
	local statusBarIcon = _G["DiceMasterSkillRankFrame"..statusBarID.."SkillIcon"];
	local statusBarBorder = _G["DiceMasterSkillRankFrame"..statusBarID.."Border"];
	local statusBarVisibleIcon = _G["DiceMasterSkillRankFrame"..statusBarID.."SkillVisibleIcon"];
	local statusBarBackground = _G["DiceMasterSkillRankFrame"..statusBarID.."Background"];
	local statusBarFillBar = _G["DiceMasterSkillRankFrame"..statusBarID.."FillBar"];

	statusBarFillBar:Hide();

	-- Header objects
	local skillRankFrameBorderTexture = _G["DiceMasterSkillRankFrame"..statusBarID.."Border"];
	local skillTypeLabelText = _G["DiceMasterSkillTypeLabel"..statusBarID];
	
	-- Frame width vars
	local skillRankFrameWidth = 0;

	-- Hide or show skill bar
	if ( skillName == "" ) then
		statusBar:Hide();
		skillTypeLabelText:Hide();
		return;
	end

	-- Is header
	if ( skillType == "header" ) then
		skillTypeLabelText:Show();
		skillTypeLabelText:SetText(skillName);
		skillTypeLabelText.skillIndex = skillIndex;
		skillTypeLabelText.skillPosition = filteredList[skillIndex].skillPosition;
		skillRankFrameBorderTexture:Hide();
		statusBar:Hide();
		local normalTexture = _G["DiceMasterSkillTypeLabel"..statusBarID.."NormalTexture"];
		local isExpanded = ( filteredList[skillIndex+1] and filteredList[skillIndex+1].expanded );
		if ( isExpanded ) then
			skillTypeLabelText:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
		else
			skillTypeLabelText:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
		end
		skillTypeLabelText.isExpanded = isExpanded;
		return;
	else
		skillTypeLabelText:Hide();
		skillRankFrameBorderTexture:Show();
		statusBar:Show();
	end
	
	-- Set skillbar info
	statusBar.skillIndex = skillIndex;
	statusBar.skillPosition = filteredList[skillIndex].skillPosition;
	statusBarName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	statusBarIcon:SetTexture( skillIcon );
	statusBarSkillRank:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	statusBarSkillRank:ClearAllPoints();
	statusBarSkillRank:SetPoint("LEFT", "DiceMasterSkillRankFrame"..statusBarID.."SkillName", "RIGHT", 13, 0);
	statusBarSkillRank:SetJustifyH("LEFT");
	statusBarBorder.skillName = skillName;
	statusBarBorder.skillIcon = skillIcon;
	-- Set skill description text
	if ( skillDescription ) then
		local modifiedSkillRank;
		if ( Me.GetModifiersFromSkillGUID( skillGUID ) ~= 0 ) then
			local modifiers = Me.GetModifiersFromSkillGUID( skillGUID );
			local color = RED_FONT_COLOR_CODE;
			if ( modifiers > 0 ) then
				color = GREEN_FONT_COLOR_CODE.."+"
			end
			modifiedSkillRank = skillRank .." "..color..modifiers..FONT_COLOR_CODE_CLOSE;
		else
			modifiedSkillRank = skillRank;
		end
		if ( skillMaxRank == 0) then
			skillDescription = "|cFFFFFFFFRank " .. modifiedSkillRank .. "|r|n" .. skillDescription;
		else
			skillDescription = skillDescription .. "|n|cFFFFFFFF( " .. modifiedSkillRank .. " / " .. skillMaxRank .. " )|r";
		end
	end
	statusBarBorder.skillDescription = skillDescription;
	local expandedDescription = skillDescription;
	if skillModifiers and #skillModifiers > 0 then
		for i = 1, #skillModifiers do 
			local modifier = Me.GetSkillByGUID( skillModifiers[i] );
			local color = RED_FONT_COLOR_CODE;
			if tonumber( modifier.rank ) > 0 then
				color = GREEN_FONT_COLOR_CODE.."+"
			end
			if tonumber( modifier.rank ) ~= 0 then
				-- Add an extra line if it's the first skill
				if i == 1 then
					expandedDescription = expandedDescription .. "|n|n|cFFFFFFFFModifiers:|r|n"
				end
				if i == #skillModifiers then
					expandedDescription = expandedDescription .. color .. modifier.rank .. "|r " .. "|T" .. modifier.icon .. ":12|t " .. modifier.name;
				else
					expandedDescription = expandedDescription .. color .. modifier.rank .. "|r " .. "|T" .. modifier.icon .. ":12|t " .. modifier.name .. "|n";
				end
			end
		end
	end
	statusBarBorder.expandedDescription = expandedDescription;
	
	-- Anchor the text to the left by default
	statusBarName:ClearAllPoints();
	statusBarName:SetPoint("LEFT", statusBar, "LEFT", 6, 1);

	-- Lock border color if skill is selected
	if (statusBar.skillPosition == DiceMasterSkillFrame.statusBarClickedPosition) then
		statusBarBorder:LockHighlight();
	else
		statusBarBorder:UnlockHighlight();
	end

	-- Default width
	skillRankFrameWidth = 256;

	statusBarName:SetText(skillName);
	
	if skillShowOnMenu then
		statusBarVisibleIcon:GetNormalTexture():SetTexCoord( 0, 0.5, 0, 1 );
		statusBarVisibleIcon.visible = true;
	else
		statusBarVisibleIcon:GetNormalTexture():SetTexCoord( 0.5, 1, 0, 1 );
		statusBarVisibleIcon.visible = false;
	end
	
	statusBarName:SetText(skillName);
	statusBar:SetStatusBarColor(0.0, 0.0, 0.5);
	statusBarBackground:SetVertexColor(0.0, 0.0, 0.75, 0.5);

	if ( skillMaxRank == 0 ) then
		-- If max rank in a skill is 1 assume that its a proficiency
		statusBar:SetMinMaxValues(0, 1);
		statusBar:SetValue(1);
		statusBar:SetStatusBarColor(0.5, 0.5, 0.5);
		if tonumber( skillRank ) < 0 then
			skillRank = RED_FONT_COLOR_CODE .. skillRank .. FONT_COLOR_CODE_CLOSE;
		end
		if ( Me.GetModifiersFromSkillGUID( skillGUID ) ~= 0 ) then
			local modifiers = Me.GetModifiersFromSkillGUID( skillGUID );
			local color = RED_FONT_COLOR_CODE;
			if ( modifiers > 0 ) then
				color = GREEN_FONT_COLOR_CODE.."+"
			end
			statusBarSkillRank:SetText(skillRank.." "..color..modifiers..FONT_COLOR_CODE_CLOSE);
		else
			statusBarSkillRank:SetText(skillRank);
		end
		statusBarFillBar:Hide();
		statusBarBackground:SetVertexColor(1.0, 1.0, 1.0, 0.5);
	elseif ( skillMaxRank > 0 ) then
		statusBar:SetMinMaxValues(0, skillMaxRank);
		statusBar:SetValue(skillRankStart);
		if tonumber( skillRank ) < 0 then
			skillRank = RED_FONT_COLOR_CODE .. skillRank .. FONT_COLOR_CODE_CLOSE;
		end
		if ( Me.GetModifiersFromSkillGUID( skillGUID ) == 0 ) then
			statusBarSkillRank:SetText(skillRank.."/"..skillMaxRank);
			statusBarFillBar:Hide();
		else
			local modifiers = Me.GetModifiersFromSkillGUID( skillGUID );
			local color = RED_FONT_COLOR_CODE;
			statusBarFillBar:Hide();
			if ( modifiers > 0 ) then
				color = GREEN_FONT_COLOR_CODE.."+"
				statusBarFillBar:SetMinMaxValues(0, skillMaxRank);
				statusBarFillBar:SetValue(skillRankStart + modifiers)
				statusBarFillBar:Show();
			end
			statusBarSkillRank:SetText(skillRank.." "..color..modifiers..FONT_COLOR_CODE_CLOSE.."/"..skillMaxRank);
		end
	end
end

function Me.SkillDetailFrame_SetStatusBar( skillPosition )
	if not skillPosition then
		return
	end
	
	-- Get info
	local skillName, skillIcon, skillDescription, skillType, skillRank, skillMaxRank, skillAuthor, skillGUID, skillModifiers, skillShowOnMenu, skillCanEdit = GetSkillLineInfoByPosition(skillPosition);
	local skillRankStart = skillRank;

	-- Skill bar objects
	local statusBar = _G["DiceMasterSkillDetailStatusBar"];
	local statusBarBackground = _G["DiceMasterSkillDetailStatusBarBackground"];
	local statusBarSkillRank = _G["DiceMasterSkillDetailStatusBarSkillRank"];
	local statusBarName = _G["DiceMasterSkillDetailStatusBarSkillName"];
	local statusBarIcon = _G["DiceMasterSkillDetailSkillIconButton"];
	local statusBarIncreaseButton = _G["DiceMasterSkillDetailStatusBarIncreaseButton"];
	local statusBarDecreaseButton = _G["DiceMasterSkillDetailStatusBarDecreaseButton"];
	local statusBarUnlearnButton = _G["DiceMasterSkillDetailStatusBarUnlearnButton"];
	local statusBarFillBar = _G["DiceMasterSkillDetailStatusBarFillBar"];

	-- Frame width vars
	local skillRankFrameWidth = 0;

	-- Hide or show skill bar
	if ( not skillName or skillName == "" ) then
		statusBar:Hide();
		DiceMasterSkillDetailDescriptionText:Hide();
		return;
	else
		statusBar:Show();
		DiceMasterSkillDetailDescriptionText:Show();
	end
	
	if ( skillAuthor == UnitName("player") or skillCanEdit ) then
		statusBarIncreaseButton:Enable();
		statusBarIncreaseButton.skillName = skillName;
		statusBarDecreaseButton:Enable();
		statusBarDecreaseButton.skillName = skillName;
		if not( skillMaxRank == 0 ) then
			statusBarIncreaseButton.canIncreaseMax = true;
			statusBarDecreaseButton.canDecreaseMax = true;
		else
			statusBarIncreaseButton.canIncreaseMax = false;
			statusBarDecreaseButton.canDecreaseMax = false;
		end
	else
		statusBarIncreaseButton:Disable();
		statusBarDecreaseButton:Disable();
	end

	-- Hide or show abandon button
	statusBarUnlearnButton:Show();
	statusBarUnlearnButton.skillName = skillName;
	statusBarUnlearnButton.skillPosition = skillPosition;
		
	-- Set skillbar info
	statusBar.skillPosition = skillPosition;
	statusBarName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	statusBarIcon:SetTexture( skillIcon );
	statusBarSkillRank:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	statusBarSkillRank:ClearAllPoints();
	statusBarSkillRank:SetPoint("LEFT", "DiceMasterSkillDetailStatusBarSkillName", "RIGHT", 13, 0);
	statusBarSkillRank:SetJustifyH("LEFT");

	-- Anchor the text to the left by default
	statusBarName:ClearAllPoints();
	statusBarName:SetPoint("LEFT", statusBar, "LEFT", 6, 1);

	-- Set skill description text
	if skillModifiers and #skillModifiers > 0 then
		for i = 1, #skillModifiers do 
			local modifier = Me.GetSkillByGUID( skillModifiers[i] );
			local color = RED_FONT_COLOR_CODE;
			if tonumber( modifier.rank ) > 0 then
				color = GREEN_FONT_COLOR_CODE.."+"
			end
			if tonumber( modifier.rank ) ~= 0 then
				-- Add an extra line if it's the first skill
				if i == 1 then
					if not( skillDescription ) then
						skillDescription = "|cFFFFD100Modifiers:|r "
					else
						skillDescription = skillDescription .. "|n|n|cFFFFD100Modifiers:|r "
					end
				end
				if i == #skillModifiers then
					skillDescription = skillDescription .. color .. modifier.rank .. " " .. modifier.name .. "|r";
				else
					skillDescription = skillDescription .. color .. modifier.rank .. " " .. modifier.name .. "|r, ";
				end
			end
		end
	end
	if ( skillDescription and skillAuthor ) then
		DiceMasterSkillDetailDescriptionText:SetText(skillDescription .. "|n|n|cFFFFD100Creator:|r "..skillAuthor.."|n");
		DiceMasterSkillDetailDescriptionText:Show();
	elseif skillAuthor then
		DiceMasterSkillDetailDescriptionText:SetText("|cFFFFD100Creator:|r "..skillAuthor.."|n");
		DiceMasterSkillDetailDescriptionText:Show();
	else
		DiceMasterSkillDetailDescriptionText:SetText("");
		DiceMasterSkillDetailDescriptionText:Hide();
	end
	
	-- Default width
	skillRankFrameWidth = 256;

	-- Normal skill
	statusBarName:SetText(skillName);
	statusBar:SetStatusBarColor(0.0, 0.0, 0.5);
	statusBarBackground:SetVertexColor(0.0, 0.0, 0.75, 0.5);

	DiceMasterSkillDetailCostText:Hide();
	
	if ( DiceMasterSkillDetailCostText:IsVisible() ) then
		DiceMasterSkillDetailDescriptionText:SetPoint("TOP", "DiceMasterSkillDetailCostText", "BOTTOM", 0, -20 );
	else
		DiceMasterSkillDetailDescriptionText:SetPoint("TOP", "DiceMasterSkillDetailCostText", "TOP", 0, -10 );
	end

	if ( skillMaxRank == 0 ) then
		-- If max rank in a skill is 0 assume that its a proficiency
		statusBar:SetMinMaxValues(0, 1);
		statusBar:SetValue(1);
		statusBar:SetStatusBarColor(0.5, 0.5, 0.5);
		if tonumber( skillRank ) < 0 then
			skillRank = RED_FONT_COLOR_CODE .. skillRank .. FONT_COLOR_CODE_CLOSE;
		end
		if ( Me.GetModifiersFromSkillGUID( skillGUID ) ~= 0 ) then
			local modifiers = Me.GetModifiersFromSkillGUID( skillGUID );
			local color = RED_FONT_COLOR_CODE;
			if ( modifiers > 0 ) then
				color = GREEN_FONT_COLOR_CODE.."+"
			end
			statusBarSkillRank:SetText(skillRank.." "..color..modifiers..FONT_COLOR_CODE_CLOSE);
		else
			statusBarSkillRank:SetText(skillRank);
		end
		statusBarBackground:SetVertexColor(1.0, 1.0, 1.0, 0.5);
		statusBarFillBar:Hide();
	elseif ( skillMaxRank > 0 ) then
		statusBar:SetMinMaxValues(0, skillMaxRank);
		statusBar:SetValue(skillRank);
		if tonumber( skillRank ) < 0 then
			skillRank = RED_FONT_COLOR_CODE .. skillRank .. FONT_COLOR_CODE_CLOSE;
		end
		if ( Me.GetModifiersFromSkillGUID( skillGUID ) == 0 ) then
			statusBarSkillRank:SetText(skillRank.."/"..skillMaxRank);
			statusBarFillBar:Hide();
		else
			local modifiers = Me.GetModifiersFromSkillGUID( skillGUID );
			local color = RED_FONT_COLOR_CODE;
			if ( modifiers > 0 ) then
				color = GREEN_FONT_COLOR_CODE.."+"
				statusBarFillBar:SetMinMaxValues(0, skillMaxRank);
				statusBarFillBar:SetValue(skillRankStart + modifiers)
				statusBarFillBar:Show();
			end
			statusBarSkillRank:SetText(skillRank.." "..color..modifiers..FONT_COLOR_CODE_CLOSE.."/"..skillMaxRank);
		end
	end
end

function Me.SkillFrame_UpdateSkills()
	Me.SkillFrame_BuildFilteredList()
	local numSkills = #filteredList
	local offset = FauxScrollFrame_GetOffset(DiceMasterSkillListScrollFrame) + 1;

	if numSkills == 0 then
		DiceMasterTraitEditor.NoSkillsWarning:Show();
		DiceMasterSkillFrameExportButton:Disable();
	else
		DiceMasterTraitEditor.NoSkillsWarning:Hide();
		DiceMasterSkillFrameExportButton:Enable();
	end
	
	local index = 1;
	for i=offset,  offset + 12 - 1 do
		if ( i <= numSkills ) then
			Me.SkillFrame_SetStatusBar(index, i, numSkills);
		else
			break;
		end
		index = index + 1;
	end

	-- Update the expand/collapse all button
	DiceMasterSkillFrameCollapseAllButton.isExpanded = 1;
	DiceMasterSkillFrameCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
	for i=1, #Profile.skills do
		local skill = Profile.skills[i];
		if not( skill.type == "header" ) then
			-- If one skill is not expanded then set isExpanded to false and break
			if not( skill.expanded ) then
				DiceMasterSkillFrameCollapseAllButton.isExpanded = nil;
				DiceMasterSkillFrameCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
				break;
			end
		end
	end
	
	-- Update the alignment dropdown button
	UIDropDownMenu_SetText( DiceMasterSkillFrameAlignmentDropdown, "|cFFFFD100Alignment:|r " .. Me.Profile.alignment )

	-- Hide unused bars
	for i=index, 12 do
		_G["DiceMasterSkillRankFrame"..i]:Hide();
		_G["DiceMasterSkillTypeLabel"..i]:Hide();
	end

	-- Update scrollFrame
	FauxScrollFrame_Update(DiceMasterSkillListScrollFrame, numSkills, 12, 15 );
	
	DiceMasterSkillDetailScrollFrame:UpdateScrollChildRect();

	if numSkills > 0 and DiceMasterSkillFrame.statusBarClickedPosition then
		Me.SkillDetailFrame_SetStatusBar( DiceMasterSkillFrame.statusBarClickedPosition );
		DiceMasterSkillDetailScrollFrame:Show();
	else
		DiceMasterSkillDetailScrollFrame:Hide();
	end
end

-------------------------------------------------------------------------------
-- Effects dropdown list.
--
--

local function GetHighlightedText( editbox )

	if not editbox then 
		return nil 
	end
	
	local origText = editbox:GetText();
	if not (origText) then return nil end

	local cPos = editbox:GetCursorPosition();

	editbox:Insert("\127");
	local a = string.find(editbox:GetText(), "\127");
	local dLen = math.max(0,string.len(origText)-(string.len(editbox:GetText())-1));
	editbox:SetText(origText);

	editbox:SetCursorPosition(cPos);
	local hs, he = a - 1, a + dLen - 1;
	if hs < he then
		editbox:HighlightText(hs, he);
		return hs, he;
	end
	
end

function Me.TraitEditor_Insert( text, editbox )
	
	if not editbox then
		editbox = Me.editor.scrollFrame.Container.descEditor;
	end
	
	editbox:Insert( text );
	
end

function Me.TraitEditor_InsertTag( tag, tag2, editbox )

	if not editbox then
		editbox = Me.editor.scrollFrame.Container.descEditor;
	end
	
	local hi1, hi2 = GetHighlightedText( editbox );
	local s;

	local inner = "";
	if hi1 and hi2 then
		inner = string.sub(editbox:GetText(), hi1 + 1, hi2);
	end
	if tag2 then
		s = string.format("<%s>%s</%s>", tag, inner, tag2);
	else
		s = string.format("<%s>%s</%s>", tag, inner, tag);
	end
	editbox:Insert(s);
	
end

-------------------------------------------------------------------------------
-- Terms dropdown list.
--
--

function Me.TraitEditor_TermsOnClick(self, arg1)
	if not arg1 then
		return
	end

	local anchorFrame = UIDROPDOWNMENU_OPEN_MENU:GetName()
	
	if anchorFrame == "DiceMasterDMNotesTermButton" then
		Me.TraitEditor_Insert( "<" .. arg1 .. ">", DiceMasterDMNotesDMNotes.EditBox )
		DiceMasterNotesEditBox_OnTextChanged(DiceMasterDMNotesDMNotes.EditBox)
	else
		Me.TraitEditor_Insert( "<" .. arg1 .. ">" )
		Me.TraitEditor_SaveDescription()
	end
end

function Me.TraitEditor_TermsOnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	if level == 1 then
		info.isNotRadio = true;
		info.notCheckable = true;
		info.hasArrow = true;
		info.keepShownOnClick = true;
		info.menuList = 1;
		info.text = "Effects";
		UIDropDownMenu_AddButton(info, level);
		info.menuList = 2;
		info.text = "Combat Actions";
		UIDropDownMenu_AddButton(info, level);
		info.menuList = 3;
		info.text = "Conditions";
		UIDropDownMenu_AddButton(info, level);
		info.menuList = 4;
		info.text = "Skills";
		UIDropDownMenu_AddButton(info, level);
		info.menuList = 5;
		info.text = "Saving Throws";
		UIDropDownMenu_AddButton(info, level);
		info.isTitle = false;
		info.func = Me.TraitEditor_TermsOnClick;
	elseif menuList == 1 then
		for i = 1, #Me.TermsList["Effects"] do
			local term = Me.TermsList["Effects"][i];
			info.text = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.tooltipText = term.desc;
			info.tooltipOnButton = true;
			if term.altTerm then
				info.arg1 = term.altTerm;
			else
				info.arg1 = term.name;
			end
			info.func = Me.TraitEditor_TermsOnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	elseif menuList == 2 then
		for i = 1, #Me.RollList["Combat Actions"] do
			local term = Me.RollList["Combat Actions"][i];
			info.text = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.tooltipText = term.desc;
			info.tooltipText = gsub( term.desc, "Roll", "An attempt" );
			info.tooltipOnButton = true;
			info.arg1 = term.name;
			info.func = Me.TraitEditor_TermsOnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	elseif menuList == 3 then
		for i = 1, #Me.TermsList["Conditions"] do
			local term = Me.TermsList["Conditions"][i];
			info.text = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.tooltipText = term.desc;
			info.tooltipOnButton = true;
			if term.altTerm then
				info.arg1 = term.altTerm;
			else
				info.arg1 = term.name;
			end
			info.func = Me.TraitEditor_TermsOnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	elseif menuList == 4 then
		for i = 1, #Me.RollList["Skills"] do
			local term = Me.RollList["Skills"][i];
			info.text = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.tooltipText = gsub( term.desc, "Roll", "An attempt" );
			info.tooltipOnButton = true;
			info.arg1 = term.name;
			info.func = Me.TraitEditor_TermsOnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	elseif menuList == 5 then
		for i = 1, #Me.RollList["Saving Throws"] do
			local term = Me.RollList["Saving Throws"][i];
			info.text = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIconForText( term.iconID ) .. " " .. term.name;
			info.tooltipText = gsub( term.desc, "Roll", "An attempt" );
			info.tooltipOnButton = true;
			info.arg1 = term.name;
			info.func = Me.TraitEditor_TermsOnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

-------------------------------------------------------------------------------
-- Effects dropdown list.
--
--
function Me.TraitEditor_EffectsOnClick(self, arg1)
	if arg1 then arg1() end
end

function Me.TraitEditor_EffectsOnLoad(frame, level, menuList)
	local effects = Profile.traits[Me.editing_trait]["effects"]
	
	local info = UIDropDownMenu_CreateInfo()
	info.isNotRadio = true;
	info.notCheckable = false;
	info.func = Me.TraitEditor_EffectsOnClick;
	info.icon = "Interface/Icons/Spell_Holy_WordFortitude"
	info.text = "Apply Buff"
	info.checked = effects["buff"] and effects["buff"].name and effects["buff"].name ~= "";
	info.arg1 = Me.BuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/Spell_Shadow_SacrificialShield"
	info.text = "Remove Buff"
	info.checked = effects["removebuff"] and effects["removebuff"].name and effects["removebuff"].name ~= "";
	info.arg1 = Me.RemoveBuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_drum_01"
	info.text = "Play Sound"
	info.checked = effects["sound"] and effects["sound"].soundID ~= nil;
	info.arg1 = Me.SoundPicker_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/INV_Misc_Dice_01"
	info.text = "Roll Dice"
	info.checked = effects["setdice"] and effects["setdice"].value;
	info.arg1 = Me.SetDiceEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/spell_arcane_blast"
	info.text = "Visual Effect"
	info.checked = effects["effect"] and effects["effect"].effectID;
	info.arg1 = Me.EffectPicker_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_scroll_03"
	info.text = "Run Script"
	info.arg1 = Me.ScriptEditor_Open;
	info.checked = effects["script"] and effects["script"].code;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/AddOns/DiceMaster/Icons/Secret"
	info.text = "Secret"
	info.checked = effects["secret"] and ( effects["secret"].conditions1 or effects["secret"].conditions2 or effects["secret"].conditions3 );
	info.arg1 = Me.SecretEditor_Open;
	UIDropDownMenu_AddButton(info, level)
end

DiceMasterTraitEditorTutorialMixin = {}

function DiceMasterTraitEditorTutorialMixin:OnLoad()
	self.helpInfo = {
		FramePos = { x = 0,	y = -20 },
		FrameSize = { width = 336, height = 430	},
	};
end

function DiceMasterTraitEditorTutorialMixin:OnHide()
	self:CheckAndHideHelpInfo();
end

function DiceMasterTraitEditorTutorialMixin:CheckAndShowTooltip()
	if not HelpPlate:IsShown() then
		HelpPlate_ShowTutorialPrompt(self.helpInfo, self);
	end
end

function DiceMasterTraitEditorTutorialMixin:CheckAndHideHelpInfo()
	if HelpPlate:IsShown() then
		HelpPlate_Hide();
		HelpPlate_TooltipHide();
	end
end

function DiceMasterTraitEditorTutorialMixin:ToggleHelpInfo()
	local traitFrame = DiceMasterTraitEditor;
	for i = 1, #self.helpInfo do
		self.helpInfo[i] = nil;
	end
	if ( DiceMasterTraitsFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 135,	y = 2 }, HighLightBox = { x = 64, y = -2, width = 190, height = 39 },	ToolTipDir = "DOWN", ToolTipText = TRAIT_EDITOR_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 135,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 295, height = 335 },	ToolTipDir = "DOWN", ToolTipText = TRAIT_EDITOR_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 145,	y = -381 }, HighLightBox = { x = 10, y = -385, width = 315, height = 35 },	ToolTipDir = "UP", ToolTipText = TRAIT_EDITOR_TUTORIAL[3] };
	elseif ( DiceMasterPetFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 145,	y = 2 }, HighLightBox = { x = 50, y = -2, width = 275, height = 39 },	ToolTipDir = "DOWN", ToolTipText = PETS_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 145,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 315, height = 348 },	ToolTipDir = "DOWN", ToolTipText = PETS_TUTORIAL[2] };
	elseif ( DiceMasterSkillFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 145,	y = -140 }, HighLightBox = { x = 10, y = -47, width = 315, height = 215 },	ToolTipDir = "DOWN", ToolTipText = SKILLS_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 145,	y = -315 }, HighLightBox = { x = 10, y = -275, width = 315, height = 120 },	ToolTipDir = "UP", ToolTipText = SKILLS_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 210,	y = -388 }, HighLightBox = { x = 205, y = -397, width = 120, height = 24 },	ToolTipDir = "UP", ToolTipText = SKILLS_TUTORIAL[3] };
		self.helpInfo[4] = { ButtonPos = { x = 90,	y = 2 }, HighLightBox = { x = 90, y = -2, width = 236, height = 39 },	ToolTipDir = "DOWN", ToolTipText = SKILLS_TUTORIAL[4] };
	elseif ( DiceMasterTraitEditorInventoryFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 180,	y = -1 }, HighLightBox = { x = 100, y = -9, width = 218, height = 28 },	ToolTipDir = "DOWN", ToolTipText = INVENTORY_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 145,	y = -205 }, HighLightBox = { x = 15, y = -72, width = 303, height = 310 },	ToolTipDir = "DOWN", ToolTipText = INVENTORY_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 145,	y = -31 }, HighLightBox = { x = 15, y = -40, width = 303, height = 28 },	ToolTipDir = "DOWN", ToolTipText = INVENTORY_TUTORIAL[3] };
		self.helpInfo[4] = { ButtonPos = { x = 5,	y = -378 }, HighLightBox = { x = 15, y = -387, width = 80, height = 28 },	ToolTipDir = "UP", ToolTipText = INVENTORY_TUTORIAL[4] };
		self.helpInfo[5] = { ButtonPos = { x = 150,	y = -387 }, HighLightBox = { x = 160, y = -397, width = 175, height = 24 },	ToolTipDir = "UP", ToolTipText = INVENTORY_TUTORIAL[5] };
	elseif ( DiceMasterTraitEditorShopFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 145,	y = 2 }, HighLightBox = { x = 50, y = -2, width = 275, height = 39 },	ToolTipDir = "DOWN", ToolTipText = SHOP_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 145,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 315, height = 348 },	ToolTipDir = "DOWN", ToolTipText = SHOP_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 150,	y = -387 }, HighLightBox = { x = 160, y = -397, width = 175, height = 24 },	ToolTipDir = "UP", ToolTipText = SHOP_TUTORIAL[3] };
	elseif ( DiceMasterTraitEditorBankFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 180,	y = -1 }, HighLightBox = { x = 100, y = -9, width = 218, height = 28 },	ToolTipDir = "DOWN", ToolTipText = BANK_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 145,	y = -205 }, HighLightBox = { x = 15, y = -72, width = 303, height = 310 },	ToolTipDir = "DOWN", ToolTipText = BANK_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 250,	y = -31 }, HighLightBox = { x = 254, y = -40, width = 64, height = 28 },	ToolTipDir = "DOWN", ToolTipText = BANK_TUTORIAL[3] };
		self.helpInfo[4] = { ButtonPos = { x = 150,	y = -387 }, HighLightBox = { x = 160, y = -397, width = 175, height = 24 },	ToolTipDir = "UP", ToolTipText = BANK_TUTORIAL[4] };
	end

	if ( not HelpPlate:IsShown() and traitFrame:IsShown()) then
		HelpPlate_Show(self.helpInfo, traitFrame, self, true);
	else
		HelpPlate_Hide(true);
	end
end

-------------------------------------------------------------------------------
-- OnLoad handler
--
-- Be careful in here because it's run before the addon is loaded.
--
function Me.TraitEditor_OnLoad( self )
	Me.editor = self
	
	self:SetClampedToScreen( true )
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	
	self.trait_buttons = {}
	-- create trait buttons
	for i = 1,5 do
		self.trait_buttons[i] = CreateFrame( "DiceMasterTraitButton", "DiceMasterTraitButton" .. i, self )
		local x = 70 + 35*(i-1)
		self.trait_buttons[i]:SetPoint( "TOPLEFT", x, -26 ) 
		self.trait_buttons[i]:SetSize( 32, 32 );
		self.trait_buttons[i]:SetFrameLevel(4)
		self.trait_buttons[i].editable_trait = true
		self.trait_buttons[i]:SetScript( "OnMouseDown", function( self, button )
			Me.TraitEditor_OnTraitClicked( self, button )
		end)
	end
end

-------------------------------------------------------------------------------
-- When a new tab is selected.
--
function Me.TraitEditor_OnTabChanged()
	if DiceMasterTraitEditorShopFrame:IsShown() then
		if Me.Profile.shopModel then
			SetPortraitTextureFromCreatureDisplayID( Me.editor.PortraitContainer.portrait, Me.Profile.shopModel )
		else
			SetPortraitToTexture( Me.editor.PortraitContainer.portrait, Me.Profile.shopIcon )
		end
		if Me.Profile.shopName then
			Me.editor.TitleContainer.TitleText:SetText( Me.Profile.shopName ) 
		end
	elseif DiceMasterTraitEditorInventoryFrame:IsShown() then
		SetPortraitToTexture( Me.editor.PortraitContainer.portrait, Me.Profile.inventoryIcon )
	elseif DiceMasterTraitEditorBankFrame:IsShown() then
		SetPortraitToTexture( Me.editor.PortraitContainer.portrait, "Interface/Icons/achievement_guildperk_mobilebanking" )
	end
	Me.ClearCursorActions( true, true, true )
end

-------------------------------------------------------------------------------
-- When the trait editor's close button is pressed.
--
function Me.TraitEditor_OnCloseClicked() 
	PlaySound(840); 
	Me.editor:Hide()
	Me.CloseAllEditors( nil, nil, true )
end

-------------------------------------------------------------------------------
-- Change current trait being edited.
--
function Me.TraitEditor_StartEditing( index )
	EditBox_ClearFocus( Me.editor.scrollFrame.Container.descEditor )
	EditBox_ClearFocus( Me.editor.scrollFrame.Container.traitName )
	Me.editing_trait = index
	
	PlaySound(54130)
	
	Me.TraitEditor_Refresh() 
	Me.buffeditor:Hide()
	Me.removebuffeditor:Hide()
	Me.setdiceeditor:Hide()
	DiceMasterSoundPicker:Hide()
	DiceMasterEffectPicker:Hide()
end

-------------------------------------------------------------------------------
-- When a trait button is clicked.
--
function Me.TraitEditor_OnTraitClicked( self, button )
	if not self.traitIndex then return end -- this handler is only for the player's traits
	
	if button == "LeftButton" then
		if IsShiftKeyDown() then
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
			Me.Inspect_SendTrait( self.traitIndex, dist, channel )
			-- Create chat link.
			
			-- We convert ability names' spaces to U+00A0 No-Break Space
			-- so that chat addons that split up messages see the link as 
			-- a whole word and have a lesser chance to screw up
			--
			-- We could use something another symbol that would be more secure
			-- but then people without the addon would see that ugly symbol
			--
			local name = Profile.traits[self.traitIndex].name:gsub( " ", " " )
			--                                                       |    |
			--                                                space -'    |
			--                                            no-break-space -'
			ChatEdit_InsertLink( string.format( "[DiceMaster4:%s:%d:%s]", UnitName("player"), self.traitIndex, name ) ) 
			
		else
			if not self.noteditable then
				Me.TraitEditor_StartEditing( self.traitIndex )
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Reload trait data and update the UI.
--
function Me.TraitEditor_Refresh()
	local trait = Profile.traits[Me.editing_trait]
	local scrollFrame = Me.editor.scrollFrame.Container
	
	scrollFrame.traitIcon:SetTexture( trait.icon )
	scrollFrame.traitName:SetText( trait.name )
	scrollFrame.traitUsage.text:SetText( Me.FormatUsage( trait.usage ) )
	scrollFrame.traitUsage:SetWidth(scrollFrame.traitUsage.text:GetStringWidth())
	
	if not ( trait.usage == "PASSIVE" ) then
		scrollFrame.traitRange.text:SetText( Me.FormatRange( trait.range ) )
		scrollFrame.traitRange:SetWidth(scrollFrame.traitRange.text:GetStringWidth())
		scrollFrame.traitCastTime.text:SetText( Me.FormatCastTime( trait.castTime ) )
		scrollFrame.traitCastTime:SetWidth(scrollFrame.traitCastTime.text:GetStringWidth())
		scrollFrame.traitCooldown.text:SetText( Me.FormatCooldown( trait.cooldown ) )
		scrollFrame.traitCooldown:SetWidth(scrollFrame.traitCooldown.text:GetStringWidth())
		scrollFrame.traitRange:Show()
		scrollFrame.traitCastTime:Show()
		scrollFrame.traitCooldown:Show()
	else
		scrollFrame.traitRange:Hide()
		scrollFrame.traitCastTime:Hide()
		scrollFrame.traitCooldown:Hide()
	end
	
	scrollFrame.descEditor:SetText( trait.desc )
	
	if trait.approved and trait.approved > 0 and trait.officers and #trait.officers > 0 then
		DiceMasterTraitsFrame.ModelScene:Show();
	else
		DiceMasterTraitsFrame.ModelScene:Hide();
	end
	
	for i = 1, 5 do
		Me.editor.trait_buttons[i]:Refresh()
		Me.editor.trait_buttons[i]:Select( false )
	end
	Me.editor.trait_buttons[Me.editing_trait]:Select( true )
end

function Me.TraitEditor_ExportTrait()
	local trait = deepCopy( Profile.traits[ Me.editing_trait ] );
	
	if not( Me.ValidateTrait(trait) ) then
		return
	end
	
	-- Remove trait approval
	if trait.officers then
		trait.officers = nil;
		trait.approved = false;
	end
	
	trait = TableToString( trait );
	trait = Me.Encrypt( trait );
	
	DiceMasterExportDialog.titleText = "Export Trait";
	DiceMasterExportDialog:Show();
	DiceMasterExportDialog.ExclusionControl:Hide();
	DiceMasterExportDialog.ImportControl.InputContainer.EditBox:SetText( trait );
	DiceMasterExportDialog.ImportControl.InputContainer:UpdateScrollChildRect();
	DiceMasterExportDialog.ImportControl.InputContainer:SetVerticalScroll(DiceMasterExportDialog.ImportControl.InputContainer:GetVerticalScrollRange());
	DiceMasterExportDialog.ImportControl.InputContainer.EditBox:HighlightText();
	DiceMasterExportDialog.ImportControl.InputContainer.EditBox:SetFocus();
end

-------------------------------------------------------------------------------
-- Change the usage of the currently edited trait
--
-- @param button Mouse button that was pressed
--               "LeftButton" = use next usage
--               "RightButton" = use previous usage
--
function Me.TraitEditor_ChangeUsage( button )
	local trait = Profile.traits[Me.editing_trait]
	
	local delta
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	
	local usage_index
	for k,v in ipairs( Me.TRAIT_USAGE_MODES ) do
		if trait.usage == v then
			usage_index = k
			break
		end
	end

	if not usage_index then
		-- reset
		usage_index = 1
		
	else 
		-- find a new valid usage...
		while true do
			usage_index = usage_index + delta
			
			if not Me.TRAIT_USAGE_MODES[usage_index] then
				-- past the boundary
				if delta == 1 then
					usage_index = 1
				else
					usage_index = #Me.TRAIT_USAGE_MODES
				end
			end
			
			if Profile.charges.enable then
				break
			elseif not Me.TRAIT_USAGE_MODES[usage_index]:find( "CHARGE" ) then
				break
			end
			
			-- infinite loops always scare me
		end 
	end
	
	trait.usage = Me.TRAIT_USAGE_MODES[usage_index]
	
	if trait.usage == "PASSIVE" then
		Me.editor.scrollFrame.Container.traitRange:Hide()
		Me.editor.scrollFrame.Container.traitCastTime:Hide()
		Me.editor.scrollFrame.Container.traitCooldown:Hide()
		trait.range = "NONE"
		trait.castTime = "NONE"
		trait.cooldown = "NONE"
	else
		Me.editor.scrollFrame.Container.traitRange:Show()
		Me.editor.scrollFrame.Container.traitRange.text:SetText( Me.FormatRange( trait.range or Me.TRAIT_RANGE_MODES[1] ) )
		Me.editor.scrollFrame.Container.traitRange:SetWidth(Me.editor.scrollFrame.Container.traitRange.text:GetStringWidth())
		Me.editor.scrollFrame.Container.traitCastTime:Show()
		Me.editor.scrollFrame.Container.traitCastTime.text:SetText( Me.FormatCastTime( trait.castTime or Me.TRAIT_CAST_TIME_MODES[1] ) )
		Me.editor.scrollFrame.Container.traitCastTime:SetWidth(Me.editor.scrollFrame.Container.traitCastTime.text:GetStringWidth())
		Me.editor.scrollFrame.Container.traitCooldown:Show()
		Me.editor.scrollFrame.Container.traitCooldown.text:SetText( Me.FormatCooldown( trait.cooldown or Me.TRAIT_COOLDOWN_MODES[1] ) )
		Me.editor.scrollFrame.Container.traitCooldown:SetWidth(Me.editor.scrollFrame.Container.traitCooldown.text:GetStringWidth())
	end
	
	-- update text
	Me.editor.scrollFrame.Container.traitUsage.text:SetText( Me.FormatUsage( trait.usage ) )
	TraitUpdated()
end

-------------------------------------------------------------------------------
-- Change the range of the currently edited trait
--
-- @param button Mouse button that was pressed
--               "LeftButton" = use next range
--               "RightButton" = use previous range
--
function Me.TraitEditor_ChangeRange( button )
	local trait = Profile.traits[Me.editing_trait]
	
	local delta
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	
	local range_index
	for k,v in ipairs( Me.TRAIT_RANGE_MODES ) do
		if trait.range == v then
			range_index = k
			break
		end
	end
	
	if not range_index then
		range_index = 1;
	else
		range_index = range_index + delta
	end
	
	if range_index > #Me.TRAIT_RANGE_MODES then
		range_index = 1;
	elseif range_index <= 0 then
		range_index = #Me.TRAIT_RANGE_MODES;
	end
	
	trait.range = Me.TRAIT_RANGE_MODES[range_index]
	
	-- update text
	Me.editor.scrollFrame.Container.traitRange.text:SetText( Me.FormatRange( trait.range ) )
	TraitUpdated()
end

-------------------------------------------------------------------------------
-- Change the cast time of the currently edited trait
--
-- @param button Mouse button that was pressed
--               "LeftButton" = use next cast time
--               "RightButton" = use previous cast time
--
function Me.TraitEditor_ChangeCastTime( button )
	local trait = Profile.traits[Me.editing_trait]
	
	local delta
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	
	local cast_index
	for k,v in ipairs( Me.TRAIT_CAST_TIME_MODES ) do
		if trait.castTime == v then
			cast_index = k
			break
		end
	end
	
	if not cast_index then
		cast_index = 1;
	else
		cast_index = cast_index + delta
	end
	
	if cast_index > #Me.TRAIT_CAST_TIME_MODES then
		cast_index = 1;
	elseif cast_index <= 0 then
		cast_index = #Me.TRAIT_CAST_TIME_MODES;
	end
	
	trait.castTime = Me.TRAIT_CAST_TIME_MODES[cast_index]
	
	-- update text
	Me.editor.scrollFrame.Container.traitCastTime.text:SetText( Me.FormatCastTime( trait.castTime ) )
	TraitUpdated()
end

-------------------------------------------------------------------------------
-- Change the cooldown time of the currently edited trait
--
-- @param button Mouse button that was pressed
--               "LeftButton" = use next cooldown
--               "RightButton" = use previous cooldown
--
function Me.TraitEditor_ChangeCooldown( button )
	local trait = Profile.traits[Me.editing_trait]
	
	local delta
	if button == "LeftButton" then
		delta = 1
	elseif button == "RightButton" then
		delta = -1
	else
		return
	end
	
	local cooldown_index
	for k,v in ipairs( Me.TRAIT_COOLDOWN_MODES ) do
		if trait.cooldown == v then
			cooldown_index = k
			break
		end
	end
	
	if not cooldown_index then
		cooldown_index = 1;
	else
		cooldown_index = cooldown_index + delta
	end
	
	if cooldown_index > #Me.TRAIT_COOLDOWN_MODES then
		cooldown_index = 1;
	elseif cooldown_index <= 0 then
		cooldown_index = #Me.TRAIT_COOLDOWN_MODES;
	end
	
	trait.cooldown = Me.TRAIT_COOLDOWN_MODES[cooldown_index]
	
	-- update text
	Me.editor.scrollFrame.Container.traitCooldown.text:SetText( Me.FormatCooldown( trait.cooldown ) )
	TraitUpdated()
end

-------------------------------------------------------------------------------
-- Set the texture of the currently edited trait.
--
-- @param texture Path to texture file to use for the current trait.
--
function Me.TraitEditor_SelectIcon( texture )
	local trait = Profile.traits[Me.editing_trait]
	trait.icon = texture or "Interface/Icons/inv_misc_questionmark"
	Me.editor.trait_buttons[Me.editing_trait]:Refresh()
	Me.editor.scrollFrame.Container.traitIcon:SetTexture( texture )
	
	TraitUpdated()
end

-------------------------------------------------------------------------------
-- Handler for when the name editor loses focus.
--
function Me.TraitEditor_SaveName()
	local trait = Profile.traits[Me.editing_trait]
	trait.name = Me.editor.scrollFrame.Container.traitName:GetText()
	TraitUpdated()
end

-------------------------------------------------------------------------------
-- Handler for when the text editor gains focus.
--
function Me.TraitEditor_EditDescription()
	if not Me.PermittedUse() then
		Me.TraitEditor_SaveDescription()
		return
	end

	local trait = Profile.traits[Me.editing_trait]
	Me.TraitEditor_SaveDescription()
end

-------------------------------------------------------------------------------
-- Handler for when the text editor loses focus.
--
function Me.TraitEditor_SaveDescription( noReset )
	local trait = Profile.traits[Me.editing_trait]
	trait.desc = Me.editor.scrollFrame.Container.descEditor:GetText()
	if not noReset then
		trait.approved = 0;
		trait.officers = nil;
	end
	TraitUpdated()
end

-------------------------------------------------------------------------------
-- Show the trait editor.
--
function Me.TraitEditor_Open()
	for i = 1,5 do
		Me.editor.trait_buttons[i]:SetPlayerTrait( UnitName( "player" ), i ) 
	end
	
	Me.editor.PortraitContainer.portrait:SetTexture( "Interface/AddOns/DiceMaster/Texture/TraitFrameIcon" )
	
	Me.editor.TitleContainer.TitleText:SetText( "Traits" )
	
	Me.editor.CloseButton:SetScript("OnClick",Me.TraitEditor_OnCloseClicked)
   
	Me.TraitEditor_Refresh()
	Me.PetEditor_Refresh()
	Me.TraitEditor_UpdateInventory()
	Me.TraitEditor_UpdateBank()
	Me.ShopFrame_Update()			  
	Me.editor:Show()
end
 
