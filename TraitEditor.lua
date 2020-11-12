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
	Me.TraitEditor_StatsList_UpdatePointsTotal()
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
	
	Me.TraitEditor_StatsList_UpdatePointsTotal()
end

-------------------------------------------------------------------------------
-- Handler for calculating the points totals.
--
--
function Me.TraitEditor_StatsList_UpdatePointsTotal()

	if not Me.PermittedUse() or not Profile.stats then
		return
	end

	local stats = Profile.stats
	local attributePoints = 3
	local skillPoints = 9
	
	for k, v in pairs( Me.AttributeList ) do
		for i = 1, #stats do
			if stats[i].name == k and stats[i].value then
				attributePoints = attributePoints - stats[i].value
			end
		end
	end
	
	for i = 1, #Me.RollList["Skills"] do
		for s = 1, #stats do
			if stats[s].name == Me.RollList["Skills"][i].name and stats[s].value then
				skillPoints = skillPoints - stats[s].value
			end
		end
	end
	
	DiceMasterTraitEditor.StatsPointCounter.AttributeCount:SetText( attributePoints )
	DiceMasterTraitEditor.StatsPointCounter.SkillCount:SetText( skillPoints )
	
	if attributePoints < 0 then
		DiceMasterTraitEditor.StatsPointCounter.AttributeCount:SetTextColor( 1, 0, 0 )
	else
		DiceMasterTraitEditor.StatsPointCounter.AttributeCount:SetTextColor( 1, 1, 1 )
	end
	
	if skillPoints < 0 then
		DiceMasterTraitEditor.StatsPointCounter.SkillCount:SetTextColor( 1, 0, 0 )
	else
		DiceMasterTraitEditor.StatsPointCounter.SkillCount:SetTextColor( 1, 1, 1 )
	end
	
	Me.SetupTooltip( DiceMasterTraitEditor.StatsPointCounter, nil, "Remaining Points", nil, nil, nil, "You have "..attributePoints.." remaining Attribute points and "..skillPoints.." remaining Skill points to spend." )
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
	info.checked = Me.db.global.traitsList[Me.editing_trait].buffs and Me.db.global.traitsList[Me.editing_trait].buffs.blank == false;
	info.arg1 = Me.BuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/Spell_Shadow_SacrificialShield"
	info.text = "Remove Buff"
	info.checked = Me.db.global.traitsList[Me.editing_trait].removebuffs and Me.db.global.traitsList[Me.editing_trait].removebuffs.name and not Me.db.global.traitsList[Me.editing_trait].removebuffs.blank;
	info.arg1 = Me.RemoveBuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_drum_01"
	info.text = "Play Sound"
	info.checked = Me.db.global.traitsList[Me.editing_trait].playsounds and Me.db.global.traitsList[Me.editing_trait].playsounds.soundID and not Me.db.global.traitsList[Me.editing_trait].playsounds.blank;
	info.arg1 = Me.SoundPicker_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/INV_Misc_Dice_01"
	info.text = "Roll Dice"
	info.checked = Me.db.global.traitsList[Me.editing_trait].setdice and Me.db.global.traitsList[Me.editing_trait].setdice.value and not Me.db.global.traitsList[Me.editing_trait].setdice.blank;
	info.arg1 = Me.SetDiceEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/spell_arcane_blast"
	info.text = "Visual Effect"
	info.checked = Me.db.global.traitsList[Me.editing_trait].visualeffects and Me.db.global.traitsList[Me.editing_trait].visualeffects.effectID and not Me.db.global.traitsList[Me.editing_trait].visualeffects.blank;
	info.arg1 = Me.EffectPicker_Open;
	UIDropDownMenu_AddButton(info, level)
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

		local x = 170 + 35*(i-1)

		self.trait_buttons[i]:SetPoint( "TOPLEFT", x, -26 ) 
		self.trait_buttons[i]:SetFrameLevel(4)
		self.trait_buttons[i].editable_trait = true
	  
		self.trait_buttons[i]:SetScript( "OnMouseDown", function( self, button )
			Me.TraitEditor_OnTraitClicked( self, button )
		end)
	end
	
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
	Me.IconPicker_Close()
	Me.ModelPicker_Close()
	Me.ColourPicker_Close()
	Me.editor:Hide()
	Me.buffeditor:Hide()
	Me.removebuffeditor:Hide()
	Me.setdiceeditor:Hide()
	DiceMasterSoundPicker:Hide()
	DiceMasterEffectPicker:Hide()
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
	for i = 1, #DiceMasterTraitEditor.trait_picker_buttons do
		local button = DiceMasterTraitEditor.trait_picker_buttons[ i ]
		local trait = Me.db.global.traitsList[ startOffset + i ]
		if trait then
			button:Show()			
			button:SetTrait( trait, true )
			button.traitIndex = startOffset + i;
			button:SetScript( "OnMouseDown", function( self, button )
				Me.TraitPicker_OnTraitClicked( self, button )
			end)
			button:Select( Me.editing_trait == button.traitIndex )
		elseif ( startOffset + i == #Me.db.global.traitsList + 1 ) then
			button:Show()
			button.traitIndex = nil;
			button:SetTexture("Interface/PaperDollInfoFrame/Character-Plus")
			--Me.SetupTooltip( button, nil, "Create New Trait" )
			button:SetScript( "OnMouseDown", function( self, button)
				Me.TraitEditor_CreateTrait()
			end)
			button:Select( false )
		else
			button:SetTrait( nil )
			button.traitIndex = nil;
			button:Hide()
		end
	end
end

-------------------------------------------------------------------------------
-- When we change the size of the list, update the scroll bar range.
--
-- @param reset Reset the scroll bar to the beginning.
--
function Me.TraitPicker_RefreshScroll( reset )
	local list = Me.db.global.traitsList 
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
	
	local buff = Me.db.global.traitsList[Me.editing_trait].buffs or nil
	if buff and buff.blank == false then
		scrollFrame.applyBuff:Show()
		scrollFrame.applyBuff.Icon:SetTexture(buff.icon)
		scrollFrame.applyBuff.Name:SetText(buff.name)
		scrollFrame.removeBuff:SetPoint("TOPLEFT", scrollFrame.applyBuff, "BOTTOMLEFT", 0, -20)
		Me.SetupTooltip( scrollFrame.applyBuff, nil, "|cFFffd100"..buff.name, nil, nil, Me.FormatDescTooltip( buff.desc or "" ) )
	else
		scrollFrame.applyBuff:Hide()
		scrollFrame.removeBuff:SetPoint("TOPLEFT", scrollFrame.descEditor, "BOTTOMLEFT", 0, -30)
	end
	
	local debuff = Me.db.global.traitsList[Me.editing_trait].removebuffs or nil
	if debuff and debuff.blank == false then
		scrollFrame.removeBuff:Hide()
		scrollFrame.removeBuff.Name:SetText(debuff.name)
		scrollFrame.removeBuff.Icon:SetTexture("Interface/Icons/Spell_Shadow_SacrificialShield")
		
		if not Me.db.global.traitsList[Me.editing_trait].buffs then return end
		
		for i = 1,5 do
			if Me.db.global.traitsList[i].buffs and Me.db.global.traitsList[i].buffs.name == debuff.name then
				scrollFrame.removeBuff.Icon:SetTexture(Me.db.global.traitsList[i].buffs.icon)
				scrollFrame.removeBuff:Show()
				Me.SetupTooltip( scrollFrame.removeBuff, nil, "|cFFffd100"..Me.db.global.traitsList[i].buffs.name, nil, nil, Me.FormatDescTooltip( Me.db.global.traitsList[i].buffs.desc or "" ) )
				break
			end
		end
	else
		scrollFrame.removeBuff:Hide()
	end
end

-------------------------------------------------------------------------------
-- Call this after changing a trait's data.
--
local function TraitUpdated()

	local trait = Me.db.global.traitsList[Me.editing_trait]
	-- TODO
	-- Me.BumpSerial( Me.db.char.traitSerials, Me.editing_trait )
	Me.Inspect_OnTraitUpdated( UnitName("player"), Me.editing_trait )
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
		buffs			 = {};
		removebuffs 	 = {};
		playsounds  	 = {};
		setdice     	 = {};
		visualeffects	 = {};
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
		Me.editor.scrollFrame.Container.traitCastTime:Show()
		Me.editor.scrollFrame.Container.traitCooldown:Show()
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
	Me.editor.trait_buttons[Me.editing_trait]:Refresh()
	Me.editor.scrollFrame.Container.traitIcon:SetTexture( texture )
	
	TraitUpdated()
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
	
	for i = 1,5 do
		Me.editor.trait_buttons[i]:SetPlayerTrait( UnitName( "player" ), i ) 
	end
	 
	--get name, race, class
	local charName, charRace, charClass, charColor = Me.GetCharInfo()
	
	SetPortraitTexture( Me.editor.portrait, "player" )
	
	Me.editor.TitleText:SetText( charName )
	
	Me.editor.CloseButton:SetScript("OnClick",Me.TraitEditor_OnCloseClicked)
   
	Me.TraitEditor_Refresh()
	Me.TraitPicker_RefreshScroll( true )
	Me.PetEditor_Refresh()
	Me.editor:Show()
end
 
