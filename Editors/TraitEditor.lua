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

local StatsListEntries = { };

local SHOP_ITEMS_PER_PAGE = 12;

local function FindStatByName( name )
	for i = 1, #Profile.stats do
		if Profile.stats[i].name == name then
			return true
		end
	end
end

StaticPopupDialogs["DICEMASTER4_CREATESTAT"] = {
  text = "Create New Statistic",
  button1 = "Create Statistic",
  button2 = "Cancel",
  button3 = "Create Header",
  OnShow = function (self, data)
    self.editBox:SetText("Statistic")
	self.editBox:HighlightText()
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
    local text = self.editBox:GetText()
	local attribute = Me.statType
	if text == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0, 53, 5 );
	elseif strlen(text) > 20 then
		UIErrorsFrame:AddMessage( "Invalid name: too long.", 1.0, 0.0, 0.0, 53, 5 );
	elseif FindStatByName( text ) then
		UIErrorsFrame:AddMessage( "\"".. text .."\" already exists.", 1.0, 0.0, 0.0, 53, 5 );
	else
		Me.TraitEditor_StatsList_Add( data, text, true, attribute )
	end
  end,
  OnAlt = function (self, data)
    local text = self.editBox:GetText()
	if text == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0, 53, 5 );
	elseif strlen(text) > 20 then
		UIErrorsFrame:AddMessage( "Invalid name: too long.", 1.0, 0.0, 0.0, 53, 5 );
	elseif FindStatByName( text ) then
		UIErrorsFrame:AddMessage( "\"".. text .."\" already exists.", 1.0, 0.0, 0.0, 53, 5 );
	else
		Me.TraitEditor_StatsList_Add( data, text, false )
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_REMOVESHOPITEM"] = {
  text = "Are you sure you want to remove this item from your shop?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data)
	local item = Me.Profile.shop[ data ]
	if not item then
		return
	end
	PlaySound(895)
	tremove( Me.Profile.shop, data )
	DiceMasterTraitEditorShopFrame.page = 1
	Me.ShopFrame_Update()
  end,
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
  text = "Paste an import code into the field below and select 'Import' to import the trait.|n|nThis will add the trait to the end of your traits list.",
  button1 = "Import",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText( "" )
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
	local data = self.editBox:GetText()
	
	if not data or data == nil or data == "" then
		UIErrorsFrame:AddMessage( "Invalid import code.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	data = Me.Decrypt( data )
	T = nil
	RunScript("T=" .. data);
	
	if T and type( T ) == "table" and T.name and T.usage and T.desc and T.icon then
		tinsert( Me.db.global.traitsList, T )
		Me.PrintMessage( "|T" .. T.icon .. ":16|t " .. T.name .. " has been imported.", "SYSTEM" )
		Me.TraitPicker_RefreshScroll()
	else
		UIErrorsFrame:AddMessage( "Corrupt trait data found. Unable to import code.", 1.0, 0.0, 0.0, 53, 5 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  showAlert = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_IMPORTSTATS"] = {
  text = "Paste an import code into the field below and select 'Import' to import the statistics.|n|nThis will overwrite your current statistics!",
  button1 = "Import",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText( "" )
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
	local data = self.editBox:GetText()
	
	if not data or data == nil or data == "" then
		UIErrorsFrame:AddMessage( "Invalid import code.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	data = Me.Decrypt( data )
	T = nil
	RunScript( "T=" .. data )
	
	local backup = Me.Profile.stats or nil
	
	if not T or type( T ) ~= "table" then 
		if backup then
			Me.Profile.stats = backup;
		end
		UIErrorsFrame:AddMessage( "Invalid import code.", 1.0, 0.0, 0.0, 53, 5 );
		return 
	end
	
	local errorsFound = false;
	for i = 1, #T do
		if not T[ i ].name then
			errorsFound = true;
			UIErrorsFrame:AddMessage( "Corrupt statistics data found. Unable to import.", 1.0, 0.0, 0.0, 53, 5 );
			break
		end
	end
	
	if not errorsFound then
		Me.Profile.stats = T;
		Me.PrintMessage( #Me.Profile.stats .. " new statistics have been imported.", "SYSTEM" )
		Me.TraitEditor_StatsList_Update()
	
		if not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
			Me.Inspect_SendStats( "RAID" )
		end
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
	if #Me.db.global.traitsList <= 5 then
		UIErrorsFrame:AddMessage( "You cannot have less than five traits.", 1.0, 0.0, 0.0, 53, 5 ); 
		return
	end
  
	Me.TraitEditor_SelectIcon( "Interface/Icons/inv_misc_questionmark" )
    Me.editor.scrollFrame.Container.traitName:SetText("Trait Name")
	Me.editor.scrollFrame.Container.descEditor:SetText("")
	Me.TraitEditor_SaveName()
	Me.TraitEditor_SaveDescription()
	if not Me.editing_trait then return end
	
	Me.PrintMessage( "|T" .. Me.db.global.traitsList[Me.editing_trait].icon .. ":16|t " .. Me.db.global.traitsList[Me.editing_trait].name .. " has been deleted.", "SYSTEM" )
	tremove( Me.db.global.traitsList, Me.editing_trait );
	
	if #Me.db.global.traitsList < 1 then
		Me.TraitEditor_CreateTrait()
	end
	
	if Me.editing_trait == 1 then
		Me.TraitEditor_StartEditing( Me.editing_trait )
	else
		Me.TraitEditor_StartEditing( Me.editing_trait - 1 )
	end
	Me.TraitPicker_RefreshScroll()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- TUTORIAL STRINGS

local TRAIT_EDITOR_TUTORIAL = {
	"Click the Traits button to see a full list of your characters' traits.",
	"You can choose a custom name, icon, description, and more for your trait in the Trait Editor.",
	"The format bar allows you to insert icons, colours, DiceMaster terms, and more into your trait's description.",
	"Click the Traits button to collapse the traits list.",
	"Left click on a trait from the traits list to edit.|n|nDrag a trait from the traits list to any slot on the Dice Panel to equip that trait.|n|nCreate a new trait by clicking the 'Create a New Trait' icon at the end of the traits list.",
}

local STATS_TUTORIAL = {
	"Your DiceMaster level and experience appears here.|n|nDungeon Masters can grant or remove levels and experience from the DM Manager frame.",
	"Create custom statistics to keep track of character attributes and skills.|n|nUsing the default statistics set up will allow you to use the Roll Wheel on the Dice Panel to roll using the appropriate statistics as modifiers.",
	"You can export all of your custom statistics as a unique import code which other players can use to import your statistics data.",
}

local PETS_TUTORIAL = {
	"Toggle whether or not your pet is active, enabling the Pet Frame and allowing other players to inspect your pet on the Inspect Frame.",
	"You can choose a custom name, icon, and more for your pet.",
	"Click the 'Select Model' button to choose a model for your pet.",
}

local INVENTORY_TUTORIAL = {
	"Use the search box to search for specific items based on keyword.|n|nClick the Clean Up Inventory button to clean up your bags. It auto-sorts and moves items out of the way to make room for new items.",
	"Custom items occupy a slot in your inventory, up to a maximum of 42 slots.",
	"You can create, edit, copy, or sell items from your inventory by using these buttons.",
	"Right click the currency frame to change which of your custom currencies is displayed, or create a new one.",
}

local SHOP_TUTORIAL = {
	"You can add items to your shop from your inventory, enabling other players to browse and purchase them using a custom currency.",
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

StaticPopupDialogs["DICEMASTER4_EDITTRAITDESCRIPTION"] = {
  text = "This trait will lose its officer approval if you edit its description. Are you sure you want to commit these changes?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data)
	Me.TraitEditor_SaveDescription()
  end,
  OnCancel = function (self, data)
	Me.editor.scrollFrame.Container.descEditor:SetText( data )
	Me.TraitEditor_SaveDescription( true )
  end,
  showAlert  = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- Refresh the statistics list.
--
--
function Me.TraitEditor_StatsList_Update()
	if ( not DiceMasterStatsFrame:IsShown() ) then
		return;
	end
	
	if Me.inspectName and Me.inspectName == UnitName("player") then
		Me.StatInspector_Update()
	end
	
	Me.editor.experienceBar.level:SetText(Profile.level or 1)
	Me.editor.experienceBar:SetValue(Profile.experience or 0)

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
	
	if #Profile.stats == 0 then
		DiceMasterTraitEditor.StatsWarning:Show()
	else
		DiceMasterTraitEditor.StatsWarning:Hide()
	end

	-- saved statistics
	for i = 1, #Profile.stats do
		AddButtonInfo(i);
	end

	DiceMasterStatsFrame.totalStatsListEntriesHeight = totalButtonHeight;
	DiceMasterStatsFrame.numStatsListEntries = addButtonIndex;

	Me.TraitEditor_StatsFrame_UpdateStats();
end

-------------------------------------------------------------------------------
-- Update the stat buttons.
--
--
function Me.TraitEditor_StatsFrame_UpdateStats()
	local scrollFrame = DiceMasterStatsFrame;
	
	if not ( scrollFrame:IsShown() ) then
		return
	end
	
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
			local height = Me.TraitEditor_StatsFrame_UpdateStatButton(button)
			button:SetHeight(height);
			usedHeight = usedHeight + height;
			
			if button.value:HasFocus() then
				button.value:ClearFocus()
			end
			
			if index == 1 then
				button.upButton:Disable()
			elseif index == numStatButtons then
				button.downButton:Disable()
			else
				button.upButton:Enable()
				button.downButton:Enable()
			end
			
			button:Show()
		else
			button.index = nil;
			button:Hide();
		end
	end
	HybridScrollFrame_Update(scrollFrame, scrollFrame.totalStatsListEntriesHeight, usedHeight);
end

function Me.TraitEditor_AddStatisticsToValue( stat )
	
	local value = 0
	
	for i = 1,#Profile.buffsActive do
		if Profile.buffsActive[i].statistic and Profile.buffsActive[i].statistic == stat then
			value = value + ( Profile.buffsActive[i].statAmount * Profile.buffsActive[i].count );
		end
	end
	
	return value
end

function Me.TraitEditor_StatsFrame_UpdateStatButton(button)
	local index = button.index;
	button.id = StatsListEntries[index].id;
	local stat = Profile.stats[StatsListEntries[index].id]
	
	-- finish setting up button
	if ( stat ) then
		
		if stat.value then
			local buffValue = Me.TraitEditor_AddStatisticsToValue( stat.name )
			button.name:SetText(stat.name .. ":");
			button.title:SetText("");
			button.value:Show()
			button.value:SetText(stat.value + buffValue);
			button.rollButton:Show()
			
			Me.SetupTooltip( button, nil, stat.name )
			
			if stat.attribute then
				if stat.desc then
					local desc = gsub( stat.desc, "Roll", "An attempt" )
					Me.SetupTooltip( button, nil, stat.name, nil, nil, "|cFFFFD100" .. desc .. "|n|cFF707070(Modified by " .. stat.attribute .. ")|r" )
				else
					Me.SetupTooltip( button, nil, stat.name, nil, nil, "|cFF707070(Modified by " .. stat.attribute .. ")|r" )
				end
			end
			
			local skills = {}
			
			if Me.AttributeList[ stat.name ] then
				for i = 1, #Profile.stats do
					if Profile.stats[i].attribute and Profile.stats[i].attribute == stat.name then
						tinsert( skills, Profile.stats[i].name )
					end
				end
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
			button.rollButton:Hide()
		end
		
		local determiner = "a"
		if stat.name:match("^[AEIOU]") then
			determiner = "an"
		end
		
		Me.SetupTooltip( button.rollButton, nil, "|cFFFFD100Roll "..determiner.." "..stat.name.." Check" )
		button:Show();
	else
		button:Hide();
	end
	return 24;
end

function Me.TraitEditor_StatsList_GetScrollFrameTopButton(offset)
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
-- Shift a stat button up or down.
-- @param direction		Determines the direction to shift the stat,
--						or deletes the stat if omitted.
--
function Me.TraitEditor_StatsList_Move( self, direction )
	local button = self:GetParent()
	local index = button.index
	local stat = Profile.stats[index]
	
	tremove(Profile.stats, index)
	if direction == "up" then
		tinsert(Profile.stats, index - 1, stat)
	elseif direction == "down" then
		tinsert(Profile.stats, index + 1, stat)
	end
	Me.TraitEditor_StatsList_Update()
	
	if not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		Me.Inspect_SendStats( "RAID" )
	end
end

-------------------------------------------------------------------------------
-- Add a new stat.
-- 
--
function Me.TraitEditor_StatsList_Add( button, name, statistic, attribute )
	local index = 0
	if button then 
		index = button.index
	end
	if attribute == "(None)" then
		attribute = nil
	end
	local stat = {
		name = name;
	}
	
	if statistic then 
		stat.value = 0
		stat.attribute = attribute
	end
	
	for k, v in pairs( Me.RollList ) do
		for i = 1, #v do
			if v[i].name == name then
				stat.desc = gsub( v[i].desc, "Roll", "An attempt" )
				break
			end
		end
	end
	
	tinsert(Profile.stats, index + 1, stat)
	
	Me.TraitEditor_StatsList_Update()
	
	if not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		Me.Inspect_SendStats( "RAID" )
	end
end

-------------------------------------------------------------------------------
-- Roll using the stat as a modifier.
-- 
--
function Me.TraitEditor_StatsList_Roll( button )
	local dice = DiceMasterPanelDice:GetText()
	local index = button.index;
	button.id = StatsListEntries[index].id;
	local stat = Profile.stats[StatsListEntries[index].id]
	
	local modifier = stat.value
	
	for i = 1, #Profile.stats do
		if Profile.stats[i].name == stat.attribute then
			modifier = modifier + Profile.stats[i].value;
			break;
		end
	end
	
	for i = 1, #Profile.buffsActive do
		if Profile.buffsActive[i].statistic == stat.name then
			modifier = modifier + Profile.buffsActive[i].statAmount
		end
	end
	
	dice = Me.FormatDiceString( dice, modifier )
	
	Me.Roll( dice, stat.name )
end

function Me.TraitEditor_StatsList_Export()
	local data = Profile.stats
	
	if not data then
		return
	end
	
	data = TableToString( data )
	data = Me.Encrypt( data )
	
	StaticPopup_Show( "DICEMASTER4_EXPORT", nil, nil, data )
end

-------------------------------------------------------------------------------
-- Create default "base stats."
-- 
--
function Me.TraitEditor_StatsList_CreateDefaults()
	
	local stat = {
		name = "Attributes";
	}
	tinsert(Profile.stats, stat)
	
	for k, v in pairs( Me.AttributeList ) do
		local stat = {
			name = k;
			value = 0;
		}
		tinsert(Profile.stats, stat)
	end
	
	for k, v in pairs( Me.RollList ) do
		local stat = {
			name = k;
		}
		tinsert(Profile.stats, stat)
		for i = 1, #v do
			local stat = {
				name = v[i].name;
				desc = v[i].desc;
				attribute = v[i].stat;
				value = 0;
			}
			tinsert(Profile.stats, stat)
		end
	end
	
	Me.TraitEditor_StatsList_Update()
	
	if not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		Me.Inspect_SendStats( "RAID" )
	end
end

-------------------------------------------------------------------------------
-- Handler for when the value editor loses focus.
--
--
function Me.TraitEditor_StatsList_SaveStat( self )
	local button = self:GetParent()
	local index = button.index
	local stat = Profile.stats[index] or nil
	
	if not stat then
		return
	end
	
	if Me.PermittedUse() then
		if tonumber( self:GetText() ) > 5 then
			self:SetText( self.lastValue )
			UIErrorsFrame:AddMessage( "You cannot have more than 5 points in that Statistic!", 1.0, 0.0, 0.0, 53, 5 ); 
		end		
	end
	
	if stat.value then
		stat.value = self:GetText()
	end
	
	if not IsInGroup( LE_PARTY_CATEGORY_INSTANCE ) then
		Me.Inspect_SendStats( "RAID" )
	end
end

-------------------------------------------------------------------------------
-- Dropdown handlers for the Create Stats menu.
--
function Me.TraitEditor_StatsList_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(DiceMasterStatButtonOptionsDropdown, self:GetText())
	Me.statType = self:GetText()
end

function Me.TraitEditor_StatsList_OnLoad()
	local info      = UIDropDownMenu_CreateInfo();
    info.text       = "Attribute";
	info.isTitle	= true;
    info.notCheckable = true;
    UIDropDownMenu_AddButton(info);
	   
	local options = Me.AttributeList
	
	for k,v in pairs(options) do
       local info      = UIDropDownMenu_CreateInfo();
       info.text       = k;
	   info.isTitle	   = false;
       info.func       = Me.TraitEditor_StatsList_OnClick;
	   info.notCheckable = false;
	   info.checked    = Me.statType == k;
       UIDropDownMenu_AddButton(info); 
	end
	
	local info      = UIDropDownMenu_CreateInfo();
    info.text       = "(None)";
	info.func       = Me.TraitEditor_StatsList_OnClick;
    info.checked    = Me.statType == "(None)" or nil;
    UIDropDownMenu_AddButton(info);
end

-------------------------------------------------------------------------------
-- Dropdown handlers for the Currency menu.
--

function Me.TraitEditor_SelectInventoryIcon( texture )
	Me.Profile.inventoryIcon = texture or "Interface/Icons/inv_misc_bag_08"
	DiceMasterTraitEditorInventoryTab.Icon:SetTexture( texture )
end

function Me.TraitEditor_CurrencyList_OnClick(self, arg1, arg2, checked)
	Me.Profile.currencyActive = arg1
	Me.TraitEditor_UpdateInventory()
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
	DiceMasterTraitEditorInventoryTab.Icon:SetTexture( Me.Profile.inventoryIcon or "Interface/Icons/inv_misc_bag_08" )
	local frame = DiceMasterTraitEditorInventoryFrame
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
					local button = CreateFrame("Button", "DiceMasterInventoryFrameItem"..id, frame, "DiceMasterItemButton");
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
	for i=1, frame.size do
		button = frame["Item"..i];
		button:SetPlayerItem( UnitName("player"), i )
		button:Update()
	end
	
	local currencyActive = Me.Profile.currencyActive or 1;
	local currency = Me.Profile.currency[currencyActive]
	DiceMasterTraitEditorInventoryFrameMoneyBgMoney:SetText( currency.value .. "|T" .. currency.icon .. ":12|t" )
	DiceMasterTraitEditorInventoryFrameMoneyBg:SetScript("OnEnter", function( self )
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" );
		GameTooltip:SetText( currency.name, 1, 1, 1 );
		if currencyActive == 1 then
			GameTooltip:AddLine( "A universal currency used by all DiceMaster users.", nil, nil, nil, true );
		end
		GameTooltip:AddLine( "|nTotal: |cFFFFFFFF" .. currency.value .. "|r", nil, nil, nil, true );
		GameTooltip:AddLine( "<Right Click to Change>", 0.44, 0.44, 0.44, true )
		if currencyActive > 1 then
			GameTooltip:AddLine( "<Alt+Right Click to Delete>", 0.44, 0.44, 0.44, true );
		end
		GameTooltip:Show();
	end)
	Me.Inspect_SendStatus( "RAID" )
end

function Me.ShopFrame_SelectIcon( texture )
	Me.Profile.shopIcon = texture or "Interface/Icons/garrison_building_tradingpost"
	DiceMasterTraitEditorShopTab.Icon:SetTexture( texture )
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
	
	Me.Inspect_SendStatus( "RAID" )
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
-------------------------------------------------------------------------------
-- Reload pet data and update the UI.
--
function Me.PetEditor_Refresh()
	DiceMasterPetFrame.petIcon:SetTexture( Profile.pet.icon )
	DiceMasterPetFrame.petName:SetText( Profile.pet.name )
	DiceMasterPetFrame.petType:SetText( Profile.pet.type )
	DiceMasterPetFrame.petModel:SetDisplayInfo( Profile.pet.model )
	DiceMasterPetFrame.enable:SetChecked( Profile.pet.enable )
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
-- Handler for when the model has been updated.
--
function Me.PetEditor_SaveModel()
	if DiceMasterPetFrame.petModel:GetDisplayInfo() == 0 then
		return
	end
	
	Profile.pet.model = DiceMasterPetFrame.petModel:GetDisplayInfo()
	Me.RefreshPetFrame()
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
			info.text = Me.FormatIcon( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIcon( term.iconID ) .. " " .. term.name;
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
			info.text = Me.FormatIcon( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIcon( term.iconID ) .. " " .. term.name;
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
			info.text = Me.FormatIcon( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIcon( term.iconID ) .. " " .. term.name;
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
			info.text = Me.FormatIcon( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIcon( term.iconID ) .. " " .. term.name;
			info.tooltipText = gsub( term.desc, "Roll", "An attempt" );
			info.tooltipOnButton = true;
			info.arg1 = term.name;
			info.func = Me.TraitEditor_TermsOnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	elseif menuList == 5 then
		for i = 1, #Me.RollList["Saving Throws"] do
			local term = Me.RollList["Saving Throws"][i];
			info.text = Me.FormatIcon( term.iconID ) .. " " .. term.name;
			info.notCheckable = true;
			info.tooltipTitle = Me.FormatIcon( term.iconID ) .. " " .. term.name;
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
	local info = UIDropDownMenu_CreateInfo()
	info.isNotRadio = true;
	info.notCheckable = false;
	info.func = Me.TraitEditor_EffectsOnClick;
	info.icon = "Interface/Icons/Spell_Holy_WordFortitude"
	info.text = "Apply Buff"
	info.checked = Me.db.global.traitsList[Me.editing_trait]["effects"]["buff"] and Me.db.global.traitsList[Me.editing_trait]["effects"]["buff"].name and Me.db.global.traitsList[Me.editing_trait]["effects"]["buff"].name ~= "";
	info.arg1 = Me.BuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/Spell_Shadow_SacrificialShield"
	info.text = "Remove Buff"
	info.checked = Me.db.global.traitsList[Me.editing_trait]["effects"]["removebuff"] and Me.db.global.traitsList[Me.editing_trait]["effects"]["removebuff"].name and Me.db.global.traitsList[Me.editing_trait]["effects"]["removebuff"].name ~= "";
	info.arg1 = Me.RemoveBuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_drum_01"
	info.text = "Play Sound"
	info.checked = Me.db.global.traitsList[Me.editing_trait]["effects"]["sound"] and Me.db.global.traitsList[Me.editing_trait]["effects"]["sound"].soundID ~= nil;
	info.arg1 = Me.SoundPicker_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/INV_Misc_Dice_01"
	info.text = "Roll Dice"
	info.checked = Me.db.global.traitsList[Me.editing_trait]["effects"]["setdice"] and Me.db.global.traitsList[Me.editing_trait]["effects"]["setdice"].value;
	info.arg1 = Me.SetDiceEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/spell_arcane_blast"
	info.text = "Visual Effect"
	info.checked = Me.db.global.traitsList[Me.editing_trait]["effects"]["effect"] and Me.db.global.traitsList[Me.editing_trait]["effects"]["effect"].effectID;
	info.arg1 = Me.EffectPicker_Open;
	UIDropDownMenu_AddButton(info, level)
end

DiceMasterTraitEditorTutorialMixin = {}

function DiceMasterTraitEditorTutorialMixin:OnLoad()
	self.helpInfo = {
		FramePos = { x = 0,	y = -20 },
		FrameSize = { width = 336, height = 444	},
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
		if DiceMasterTraitEditorTraitsExpandButton:IsCurrentlyExpanded() then
			self.helpInfo[1] = { ButtonPos = { x = 140,	y = 2 }, HighLightBox = { x = 60, y = -2, width = 120, height = 39 },	ToolTipDir = "DOWN", ToolTipText = TRAIT_EDITOR_TUTORIAL[4] };
			self.helpInfo[2] = { ButtonPos = { x = 330,	y = -202 }, HighLightBox = { x = 194, y = -47, width = 322, height = 338 },	ToolTipDir = "DOWN", ToolTipText = TRAIT_EDITOR_TUTORIAL[2] };
			self.helpInfo[3] = { ButtonPos = { x = 68,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 155, height = 338 },	ToolTipDir = "DOWN", ToolTipText = TRAIT_EDITOR_TUTORIAL[5] };
			self.helpInfo[4] = { ButtonPos = { x = 330,	y = -386 }, HighLightBox = { x = 194, y = -390, width = 322, height = 39 },	ToolTipDir = "UP", ToolTipText = TRAIT_EDITOR_TUTORIAL[3] };
		else
			self.helpInfo[1] = { ButtonPos = { x = 140,	y = 2 }, HighLightBox = { x = 60, y = -2, width = 120, height = 39 },	ToolTipDir = "DOWN", ToolTipText = TRAIT_EDITOR_TUTORIAL[1] };
			self.helpInfo[2] = { ButtonPos = { x = 146,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 320, height = 338 },	ToolTipDir = "DOWN", ToolTipText = TRAIT_EDITOR_TUTORIAL[2] };
			self.helpInfo[3] = { ButtonPos = { x = 146,	y = -386 }, HighLightBox = { x = 10, y = -390, width = 320, height = 39 },	ToolTipDir = "UP", ToolTipText = TRAIT_EDITOR_TUTORIAL[3] };
		end
	elseif ( DiceMasterStatsFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 146,	y = 2 }, HighLightBox = { x = 50, y = -2, width = 280, height = 39 },	ToolTipDir = "DOWN", ToolTipText = STATS_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 146,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 320, height = 352 },	ToolTipDir = "DOWN", ToolTipText = STATS_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 146,	y = -392 }, HighLightBox = { x = 10, y = -403, width = 320, height = 24 },	ToolTipDir = "UP", ToolTipText = STATS_TUTORIAL[3] };
	elseif ( DiceMasterPetFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 146,	y = 2 }, HighLightBox = { x = 50, y = -2, width = 280, height = 39 },	ToolTipDir = "DOWN", ToolTipText = PETS_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 146,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 320, height = 352 },	ToolTipDir = "DOWN", ToolTipText = PETS_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 146,	y = -392 }, HighLightBox = { x = 10, y = -403, width = 320, height = 24 },	ToolTipDir = "UP", ToolTipText = PETS_TUTORIAL[3] };
	elseif ( DiceMasterTraitEditorInventoryFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 95,	y = -2 }, HighLightBox = { x = 100, y = -9, width = 224, height = 32 },	ToolTipDir = "DOWN", ToolTipText = INVENTORY_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 146,	y = -180 }, HighLightBox = { x = 15, y = -47, width = 308, height = 312 },	ToolTipDir = "DOWN", ToolTipText = INVENTORY_TUTORIAL[2] };
		self.helpInfo[3] = { ButtonPos = { x = 146,	y = -358 }, HighLightBox = { x = 10, y = -365, width = 320, height = 32 },	ToolTipDir = "UP", ToolTipText = INVENTORY_TUTORIAL[3] };
		self.helpInfo[4] = { ButtonPos = { x = 150,	y = -392 }, HighLightBox = { x = 160, y = -403, width = 180, height = 24 },	ToolTipDir = "UP", ToolTipText = INVENTORY_TUTORIAL[4] };
	elseif ( DiceMasterTraitEditorShopFrame:IsShown() ) then
		self.helpInfo[1] = { ButtonPos = { x = 146,	y = -202 }, HighLightBox = { x = 10, y = -47, width = 320, height = 352 },	ToolTipDir = "DOWN", ToolTipText = SHOP_TUTORIAL[1] };
		self.helpInfo[2] = { ButtonPos = { x = 150,	y = -392 }, HighLightBox = { x = 160, y = -403, width = 180, height = 24 },	ToolTipDir = "UP", ToolTipText = SHOP_TUTORIAL[2] };
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
	
	-- create icon map
	self.trait_picker_buttons = {}
	local index = 0
	for y = 0,5 do
	  for x = 0,2 do
		index = index + 1
		local btn = CreateFrame( "DiceMasterTraitButton", "DiceMasterTraitPickerButton" .. index, DiceMasterTraitPicker )
		btn.pickerIndex = index
		btn:SetPoint( "TOPLEFT", "DiceMasterTraitPicker", 45*x+14, -45*y-46 )
		btn:SetSize( 42, 42 )
		
		table.insert( self.trait_picker_buttons, btn )
		btn.pickerIndex = #self.trait_picker_buttons
	  end
	end
	 
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
	
--	DiceMasterIconSelect_Hide() todo
	PlaySound(54130)
	
	Me.TraitEditor_Refresh() 
	Me.TraitPicker_RefreshGrid()
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
			
			ChatEdit_InsertLink(
				string.format( "[DiceMaster4:%s:%d:%s]", UnitName("player"), self.traitIndex, name ) ) 
			
		else
			--
		end
	end
end

-------------------------------------------------------------------------------
-- When a trait button is clicked.
--
function Me.TraitPicker_OnTraitClicked( self, button )
	if not self.traitIndex then return end -- this handler is only for the player's traits
	
	if button == "LeftButton" then
		if not self.noteditable then
			Me.TraitEditor_StartEditing( self.traitIndex ) 
			if Me.buffeditor:IsShown() then
				Me.buffeditor:Hide()
			end
			if Me.removebuffeditor:IsShown() then
				Me.removebuffeditor:Hide()
			end
			if Me.setdiceeditor:IsShown() then
				Me.setdiceeditor:Hide()
			end
			if DiceMasterSoundPicker:IsShown() then
				DiceMasterSoundPicker:Hide()
			end
			if DiceMasterEffectPicker:IsShown() then
				DiceMasterEffectPicker:Hide()
			end
		end
	end
end

-------------------------------------------------------------------------------
-- When the mousewheel is used on the trait picker map.
--
function Me.TraitPicker_MouseScroll( delta )

	local a = DiceMasterTraitPicker.scroller:GetValue() - delta
	DiceMasterTraitPicker.scroller:SetValue( a )
end

-------------------------------------------------------------------------------
-- When the scrollbar's value is changed.
--
function Me.TraitPicker_ScrollChanged( value )
	
	-- Our "step" is 3 icons, which is one line.
	startOffset = math.floor(value) * 3
	Me.TraitPicker_RefreshGrid()
end

-------------------------------------------------------------------------------
-- Set the textures of the icon grid from the icons in the list at the
-- current offset.
--
function Me.TraitPicker_RefreshGrid()
	local list = filteredList or Me.db.global.traitsList

	for i = 1, #DiceMasterTraitEditor.trait_picker_buttons do
		local button = DiceMasterTraitEditor.trait_picker_buttons[ i ]
		local trait = list[ startOffset + i ]
		if trait then
			button:Show()
			button:SetCustomTooltip( nil )
			button:SetTrait( trait, true )
			if filteredList then
				button.traitIndex = trait.index
			else
				button.traitIndex = startOffset + i;
			end
			button:SetScript( "OnMouseDown", function( self, button )
				Me.TraitPicker_OnTraitClicked( self, button )
			end)
			button:Select( Me.editing_trait == button.traitIndex )
		elseif ( startOffset + i == #Me.db.global.traitsList + 1 ) then
			button:Show()
			button.traitIndex = nil;
			button:SetTexture("Interface/PaperDollInfoFrame/Character-Plus")
			button:SetCustomTooltip( "Create a New Trait" )
			button:SetScript( "OnMouseDown", function( self, button)
				Me.TraitEditor_CreateTrait()
			end)
			button:Select( false )
		else
			button:SetTrait( nil )
			button.traitIndex = nil;
			button:SetCustomTooltip( nil )
			button:SetScript( "OnMouseDown", nil )
			button:Hide()
		end
	end
end

-------------------------------------------------------------------------------
-- Called when the user types into the search box.
--
function Me.TraitPicker_FilterChanged()
	local filter = DiceMasterTraitPicker.search:GetText():lower()
	if #filter < 3 then
		-- Ignore filters less than three characters
		if filteredList then
			filteredList = nil
			Me.TraitPicker_RefreshScroll()
			Me.TraitPicker_RefreshGrid()
		end
	else
		-- build new list
		filteredList = {}
		for k,v in ipairs( Me.db.global.traitsList ) do
			local name = v.name
			local desc = v.desc
			if name:lower():find( filter ) or desc:lower():find( filter ) then
				v.index = k
				table.insert( filteredList, v )
			end	
		end
		Me.TraitPicker_RefreshScroll()
	end
end

-------------------------------------------------------------------------------
-- When we change the size of the list, update the scroll bar range.
--
-- @param reset Reset the scroll bar to the beginning.
--
function Me.TraitPicker_RefreshScroll( reset )
	local list = filteredList or Me.db.global.traitsList 
	local max = math.floor((#list - 18) / 3) + 1
	if max < 0 then max = 0 end
	DiceMasterTraitPicker.scroller:SetMinMaxValues( 0, max )
	
	if reset then
		DiceMasterTraitPicker.scroller:SetValue( 0 )
	end
	
	Me.TraitPicker_ScrollChanged( DiceMasterTraitPicker.scroller:GetValue() )
end

-------------------------------------------------------------------------------
-- Reload trait data and update the UI.
--
function Me.TraitEditor_Refresh()
	local trait = Me.db.global.traitsList[Me.editing_trait]
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
end

-------------------------------------------------------------------------------
-- Call this after changing a trait's data.
--
local function TraitUpdated()
	local traitsList = Me.db.global.traitsList
	local traits = Me.Profile.traits
	
	for x = 1, #traitsList do
		for y = 1, #traits do
			if traitsList[x].guid == traits[y].guid then
				Me.Profile.traits[y] = traitsList[x];
				Me.Profile.traits[y].guid = traitsList[x].guid;
				Me.Inspect_OnTraitUpdated( UnitName("player"), y )
			end
		end
	end

	-- Me.BumpSerial( Me.db.char.traitSerials, Me.editing_trait )
	Me.UpdatePanelTraits()
end

-------------------------------------------------------------------------------
-- Create a new trait.
--
function Me.TraitEditor_CreateTrait()
	local trait = {
		["name"] = "New Trait";
		["usage"] = Me.TRAIT_USAGE_MODES[1];
		["range"] = Me.TRAIT_RANGE_MODES[1];
		["castTime"] = Me.TRAIT_CAST_TIME_MODES[1];
		["cooldown"] = Me.TRAIT_COOLDOWN_MODES[1];
		["icon"] = "Interface/Icons/inv_misc_questionmark";
		["desc"] = "Type a description for your trait here.";
		["effects"] = {};
		["traitIndex"] = #Me.db.global.traitsList;
	}
	
	-- copy officer approval
	if Me.PermittedUse() then
		trait["approved"] = false;
		trait["officers"] = {};
	end
	
	tinsert( Me.db.global.traitsList, trait )
	Me.editing_trait = #Me.db.global.traitsList
	Me.TraitPicker_RefreshScroll()
	Me.TraitEditor_StartEditing( Me.editing_trait )
end

function Me.TraitEditor_ExportTrait()
	local data = Me.db.global.traitsList[ Me.editing_trait ]
	
	if not data then
		return
	end
	
	-- Remove trait approval
	if data.officers then
		data.officers = nil;
		data.approved = false;
	end
	
	data = TableToString( data )
	data = Me.Encrypt( data )
	
	StaticPopup_Show( "DICEMASTER4_EXPORT", nil, nil, data )
end

-------------------------------------------------------------------------------
-- Change the usage of the currently edited trait
--
-- @param button Mouse button that was pressed
--               "LeftButton" = use next usage
--               "RightButton" = use previous usage
--
function Me.TraitEditor_ChangeUsage( button )
	local trait = Me.db.global.traitsList[Me.editing_trait]
	
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
	local trait = Me.db.global.traitsList[Me.editing_trait]
	
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
	local trait = Me.db.global.traitsList[Me.editing_trait]
	
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
	local trait = Me.db.global.traitsList[Me.editing_trait]
	
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
	local trait = Me.db.global.traitsList[Me.editing_trait]
	trait.icon = texture or "Interface/Icons/inv_misc_questionmark"
	--Me.editor.trait_buttons[Me.editing_trait]:Refresh()
	Me.editor.scrollFrame.Container.traitIcon:SetTexture( texture )
	
	TraitUpdated()
	Me.TraitPicker_RefreshScroll()
end

-------------------------------------------------------------------------------
-- Handler for when the name editor loses focus.
--
function Me.TraitEditor_SaveName()
	local trait = Me.db.global.traitsList[Me.editing_trait]
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

	local trait = Me.db.global.traitsList[Me.editing_trait]
	if trait.approved and trait.approved > 0 and trait.officers and #trait.officers > 0 then
		StaticPopup_Show("DICEMASTER4_EDITTRAITDESCRIPTION", nil, nil, trait.desc)
	else
		Me.TraitEditor_SaveDescription()
	end
end

-------------------------------------------------------------------------------
-- Handler for when the text editor loses focus.
--
function Me.TraitEditor_SaveDescription( noReset )
	local trait = Me.db.global.traitsList[Me.editing_trait]
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
	 
	--get name, race, class
	local charName, charRace, charClass, charColor = Me.GetCharInfo()
	
	SetPortraitTexture( Me.editor.portrait, "player" )
	
	Me.editor.TitleText:SetText( charName )
	
	Me.editor.CloseButton:SetScript("OnClick",Me.TraitEditor_OnCloseClicked)
   
	Me.TraitEditor_Refresh()
	Me.TraitPicker_RefreshScroll( true )
	Me.PetEditor_Refresh()
	Me.TraitEditor_UpdateInventory()
	Me.ShopFrame_Update()			  
	Me.editor:Show()
end
 
