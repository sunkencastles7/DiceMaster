-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Skill Editing Panel
--

local Me      = DiceMaster4
local Profile = Me.Profile

local function GetHeaderPositionByName( headerName )
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type == "header" and Me.Profile.skills[i].name == headerName then
			return i;
		end
	end
	return nil;
end

local function GetSkillHeaderName( skillGUID )
	local headerName = "Miscellaneous";
	local possibleHeader;
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type == "header" then
			possibleHeader = Me.Profile.skills[i].name;
		elseif Me.Profile.skills[i].guid == skillGUID and possibleHeader then
			return possibleHeader;
		end
	end
	return headerName;
end

local function GetSkillNameFromGUID( skillGUID )

	for i = 1, #Me.Profile.skills do 
		if Me.Profile.skills[i].guid == skillGUID then
			return Me.Profile.skills[i].name;
		end
	end
	
	return false;
	
end

local function GetSkillIndexFromGUID( skillGUID )
	
	for i = 1, #Me.Profile.skills do 
		if Me.Profile.skills[i].guid == skillGUID then
			return i;
		end
	end
	
	return false;
	
end

-------------------------------------------------------------------------------
-- Get the list of all of a skill's modifiers as a string.
--

local function GetModifiersListFromSkillGUID( skillGUID )
	local skillIndex = GetSkillIndexFromGUID( skillGUID );
	
	local modifiersList = "";	
	for s = 1, #Me.Profile.skills do
		for m = 1, #Me.Profile.skills[skillIndex].skillModifiers do
			if Me.Profile.skills[s].guid == Me.Profile.skills[skillIndex].skillModifiers[m] then
				if modifiersList == "" then
					modifiersList = Me.Profile.skills[s].name;
				else
					modifiersList = modifiersList .. ", " .. Me.Profile.skills[s].name;
				end
			end
		end
	end
	
	return modifiersList;
end

-------------------------------------------------------------------------------
-- Get the total sum of all of a skill's modifiers.
--

local function GetModifiersTotalFromSkillIndex( skillIndex )
	if not Me.Profile.skills[skillIndex] then
		return 0;
	end
	
	local modifiersTotal = 0;	
	for s = 1, #Me.Profile.skills do
		for m = 1, #Me.Profile.skills[skillIndex].skillModifiers do
			if Me.Profile.skills[s].guid == Me.Profile.skillModifiers[m] then
				modifiersTotal = modifiersTotal + Me.Profile.skills[s].rank;
			end
		end
	end
	
	return modifiersTotal;
end
		

StaticPopupDialogs["DICEMASTER4_CREATESKILLHEADER"] = {
  text = "Skill Category Name:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText( "" )
	self.editBox:SetFocus()
  end,
  OnAccept = function (self, data)
	local data = self.editBox:GetText()
	
	if not data or data == nil or data == "" or string.len(data) > 150 then
		UIErrorsFrame:AddMessage( "Invalid name.", 1.0, 0.0, 0.0 );
		return
	end
	
	if GetHeaderPositionByName( data ) then
		UIErrorsFrame:AddMessage( "A skill category with that name already exists.", 1.0, 0.0, 0.0 );
		return
	end
	
	local header = {
		name = data;
		type = "header";
		author = UnitName("player");
	};
	tinsert( Me.Profile.skills, header )
	Me.SkillFrame_UpdateSkills()
	
	UIDropDownMenu_SetSelectedValue(DiceMasterSkillEditor.SkillType, data, false)
	UIDropDownMenu_SetText( DiceMasterSkillEditor.SkillType, "|cFFFFD100Skill Category:|r " .. data )
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 1,
}

local SkillEditorModifiers = {};

function Me.SkillEditorType_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetSelectedValue(DiceMasterSkillEditor.SkillType, arg1, false)
	UIDropDownMenu_SetText( DiceMasterSkillEditor.SkillType, "|cFFFFD100Skill Category:|r " .. arg1 )
end

function Me.SkillEditorType_OnLoad(frame, level, menuList)
	local skillsList = {};
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type == "header" then
			tinsert( skillsList, Me.Profile.skills[i] )
		end
	end
	
	local info = UIDropDownMenu_CreateInfo()
	info.isNotRadio = true;
	info.notCheckable = true;
	info.text = "Skill Categories";
	info.isTitle = true;
	UIDropDownMenu_AddButton(info, level);
	for i = 1, #skillsList do	
		info.text = skillsList[i].name;
		info.arg1 = skillsList[i].name;
		info.value = skillsList[i].name;
		info.checked = UIDropDownMenu_GetSelectedValue(DiceMasterSkillEditor.SkillType) == info.value;
		info.notCheckable = false;
		info.isNotRadio = false;
		info.isTitle = false;
		info.disabled = false;
		info.func = Me.SkillEditorType_OnClick;
		UIDropDownMenu_AddButton(info, level);
	end
	info.text = "|cFF00FF00Create New...|r";
	info.arg1 = 0;
	info.value = 0;
	info.notCheckable = true;
	info.isTitle = false;
	info.disabled = false;
	info.func = function() StaticPopup_Show( "DICEMASTER4_CREATESKILLHEADER" ) end;
	UIDropDownMenu_AddButton(info, level);
end

function Me.SkillEditorModifiers_OnClick(self, arg1, arg2, checked)
	for i = 1, #SkillEditorModifiers do
		if SkillEditorModifiers[i] == arg1 then
			tremove( SkillEditorModifiers, i );
			break
		end
	end
	
	if checked then
		tinsert( SkillEditorModifiers, arg1 )
	end
	
	local modifiersList = "(None)";
	for i = 1, #SkillEditorModifiers do
		if modifiersList == "(None)" then
			modifiersList = GetSkillNameFromGUID( SkillEditorModifiers[i] );
		else
			modifiersList = modifiersList .. ", ".. GetSkillNameFromGUID( SkillEditorModifiers[i] );
		end
	end
	UIDropDownMenu_SetText( DiceMasterSkillEditor.SkillModifiers, "|cFFFFD100Skill Modifiers:|r " .. modifiersList )
end

function Me.SkillEditorModifiers_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo();
	
	local skillList = {}
	local lastCategory
	
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type == "header" then
			skillList[ Me.Profile.skills[i].name ] = {}
			lastCategory = Me.Profile.skills[i].name;
		else
			if not ( lastCategory ) then
				skillList[ "Miscellaneous" ] = {}
				lastCategory = "Miscellaneous";
			end
			tinsert( skillList[ lastCategory ], Me.Profile.skills[i] )
		end
	end
	
	if level == 1 then
		info.text = "Skills";
		info.isTitle = true;
		info.notClickable = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info);
		info.hasArrow = true;
		for k,v in pairs( skillList ) do
			info.text = k;
			info.isTitle = false;
			info.notClickable = false;
			info.disabled = false;
			info.menuList = k;
			UIDropDownMenu_AddButton(info);
		end
	elseif menuList then
		for i = 1, #skillList[menuList] do
			info.text = skillList[menuList][i].name;
			info.arg1 = skillList[menuList][i].guid;
			info.func = Me.SkillEditorModifiers_OnClick;
			info.notCheckable = false;
			info.keepShownOnClick = true;
			info.isNotRadio = true;
			info.isTitle = false;
			info.tooltipTitle = skillList[menuList][i].name;
			info.tooltipText = skillList[menuList][i].desc or "";
			if skillList[menuList][i].skillModifiers then
				info.tooltipText = info.tooltipText .. "|n|cFF707070(Modified by "..GetModifiersListFromSkillGUID( info.arg1 )..")|r";
			end
			info.tooltipOnButton = true;
			info.checked = false;
			for i = 1,#SkillEditorModifiers do
				if SkillEditorModifiers[i] == info.arg1 then
					info.checked = true;
					break;
				end
			end
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

function Me.SkillEditor_CreateSkill()
	
	local name = DiceMasterSkillEditor.Name:GetText();
	local icon = DiceMasterSkillEditorIconButton.icon:GetTexture();
	local description = DiceMasterSkillEditor.Desc.EditBox:GetText();
	local skillType = UIDropDownMenu_GetSelectedValue( DiceMasterSkillEditor.SkillType ) or "Miscellaneous";
	local maxRank = tonumber( DiceMasterSkillEditor.MaxRank:GetText() ) or 0;
	local canEdit = DiceMasterSkillEditor.Editable:GetChecked();

	if not name or name == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	if description == "" then
		description = nil
	end
	
	-- Search for duplicates
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type ~= "header" and Me.Profile.skills[i].name and Me.Profile.skills[i].name == name then
			UIErrorsFrame:AddMessage( "A skill with that name already exists.", 1.0, 0.0, 0.0 );
			return
		end
	end
	
	local headerPosition = GetHeaderPositionByName( skillType )

	local skill = {
		name = name;
		icon = icon;
		desc = description;
		type = skillType;
		rank = 1;
		maxRank = maxRank;
		skillModifiers = {};
		author = UnitName("player");
		expanded = true,
		showOnMenu = true,
		guid = Me.GenerateGUID();
		canEdit = canEdit;
	}

	for i = 1, #SkillEditorModifiers do
		tinsert( skill.skillModifiers, SkillEditorModifiers[i])
	end

	local header = {
		name = "Miscellaneous";
		type = "header";
		author = UnitName("player");
	}
	
	if ( headerPosition ) then
		tinsert( Me.Profile.skills, headerPosition + 1, skill )
	else
		tinsert( Me.Profile.skills, header )
		tinsert( Me.Profile.skills, skill )
	end
	
	Me.PrintMessage( "|cFF8080ffYou have gained the "..name.." skill.|r", "SYSTEM" )
	
	Me.SkillFrame_UpdateSkills()
	Me.SkillEditor_Close()
	DiceMasterTraitEditor.NoSkillsWarning:Hide();
end

function Me.SkillEditor_SelectIcon( texture )
	DiceMasterSkillEditorIconButton:SetTexture( texture )
end

function Me.SkillEditor_ClearAllFields()
	local editor = DiceMasterSkillEditor
	
	DiceMasterSkillEditorIconButton:SetTexture("Interface/Icons/inv_misc_questionmark")
	editor.Name:SetText( "" )
	editor.Desc.EditBox:SetText( "" )
	UIDropDownMenu_SetText( editor.SkillType, "|cFFFFD100Skill Category:|r Miscellaneous" )
	UIDropDownMenu_SetText( editor.SkillModifiers, "|cFFFFD100Skill Modifiers:|r (None)" )
	SkillEditorModifiers = {};
	editor.MaxRank:SetText( 100 )
	
	-- Find first valid category
	-- if it exists
	local skillsList = {};
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type == "header" then
			UIDropDownMenu_SetSelectedValue(DiceMasterSkillEditor.SkillType, Me.Profile.skills[i].name, false)
			UIDropDownMenu_SetText( DiceMasterSkillEditor.SkillType, "|cFFFFD100Skill Category:|r " .. Me.Profile.skills[i].name )
			break;
		end
	end
	
end

-------------------------------------------------------------------------------
-- Close the skill editor window. Use this instead of a direct Hide()
--
function Me.SkillEditor_Close()
	Me.SkillEditor_ClearAllFields()
	DiceMasterSkillEditor:Hide()
	ResetCursor();
end
    
-------------------------------------------------------------------------------
-- Open the skill editor window.
--
function Me.SkillEditor_Open( frame )
	Me.CloseAllEditors()
	if not ( frame ) then
		frame = DiceMasterTraitEditor;
	end
	DiceMasterSkillEditor:ClearAllPoints()
	DiceMasterSkillEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterSkillEditor:Show()
end

-------------------------------------------------------------------------------
-- Learn Skill Editor
--

local function GetSkillFromGUID( skillGUID )
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type ~= "header" and Me.Profile.skills[i].guid == skillGUID then
			local data = {}
			for k, v in pairs( Me.Profile.skills[i] ) do
				data[k] = v;
			end
			return data;
		end
	end
	return nil;
end

local function BuildSkillsList()
	local skillsList = {}
	local lastCategory
	
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].type == "header" then
			skillsList[ Me.Profile.skills[i].name ] = {}
			lastCategory = Me.Profile.skills[i].name;
		elseif Me.Profile.skills[i].author and Me.Profile.skills[i].author == UnitName("player") then
			if not ( lastCategory ) then
				skillsList[ "Miscellaneous" ] = {}
				lastCategory = "Miscellaneous";
			end
			tinsert( skillsList[ lastCategory ], Me.Profile.skills[i] )
		end
	end
	
	return skillsList;
end

function Me.LearnSkillEditorSkill_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetSelectedValue(DiceMasterLearnSkillEditor.SkillName, arg1, true);
	UIDropDownMenu_SetText( DiceMasterLearnSkillEditor.SkillName, GetSkillNameFromGUID( arg1 ) )
end

function Me.LearnSkillEditorSkill_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	local skillsList = BuildSkillsList()
	
	if level == 1 then
		info.text = "|cFFffd100Skills"
		info.notClickable = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info)
		info.disabled = false;
		info.notClickable = false;
		info.hasArrow = true;
		for k,v in pairs( skillsList ) do
			info.text = k
			info.menuList = k
			UIDropDownMenu_AddButton(info)
		end
		info.hasArrow = nil;
		info.menuList = nil
	elseif menuList then
		for i = 1,#skillsList[menuList] do
			info.text = skillsList[menuList][i].name
			info.arg1 = skillsList[menuList][i].guid
			info.value = skillsList[menuList][i].guid
			info.func = Me.LearnSkillEditorSkill_OnClick;
			info.notCheckable = false;
			info.tooltipTitle = skillsList[menuList][i].name;
			if skillsList[menuList][i].stat then
				info.tooltipText = skillsList[menuList][i].desc;
			end
			info.tooltipOnButton = true;
			info.checked = UIDropDownMenu_GetText(DiceMasterLearnSkillEditor.SkillName) == info.text;
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Me.LearnSkillEditor_Refresh( effectIndex )
	local effect
	if Me.ItemEditing then
		effect = Me.ItemEditing.effects[ effectIndex ]
	elseif Me.newItem then
		effect = Me.newItem.effects[ effectIndex ]
	end

	Me.EffectEditingIndex = effectIndex
	
	if effect then
		DiceMasterLearnSkillEditorSaveButton:SetScript( "OnClick", function()
			Me.LearnSkillEditor_SaveEdits()
		end)
		UIDropDownMenu_SetSelectedValue(DiceMasterLearnSkillEditor.SkillName, effect.guid, true);
		UIDropDownMenu_SetText( DiceMasterLearnSkillEditor.SkillName, GetSkillNameFromGUID( effect.guid ) )
		DiceMasterLearnSkillEditor.Rank:SetText( effect.rank )
		return
	end
	UIDropDownMenu_SetText( DiceMasterLearnSkillEditor.SkillName, "(None)" )
	DiceMasterLearnSkillEditor.Rank:SetText( 0 )
end

function Me.LearnSkillEditor_LearnSkill( data )
	if not data or not data.type or data.type ~= "skill" or not data.name or not data.skillType or not data.guid or not data.author or not data.rank then
		return
	end
	
	-- Search for duplicates
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].guid and Me.Profile.skills[i].guid == data.guid then
			UIErrorsFrame:AddMessage( "Already Known", 1.0, 0.0, 0.0 );
			return
		elseif Me.Profile.skills[i].type ~= "header" and Me.Profile.skills[i].name and Me.Profile.skills[i].name == data.name then
			UIErrorsFrame:AddMessage( "Already Known", 1.0, 0.0, 0.0 );
			return
		end
	end

	if data.rank > data.maxRank then data.rank = data.maxRank end
	
	local headerPosition = GetHeaderPositionByName( data.skillType )

	local skill = {
		name = data.name;
		icon = data.icon;
		desc = data.description or nil;
		rank = data.rank or 1;
		maxRank = data.maxRank or 100;
		skillModifiers = data.skillModifiers or {};
		author = data.author;
		expanded = true;
		showOnMenu = true;
		canEdit = data.canEdit or false;
		guid = data.guid;
	}

	local header = {
		name = "Miscellaneous";
		type = "header";
		author = data.author;
	}
	
	if ( headerPosition ) then
		tinsert( Me.Profile.skills, headerPosition + 1, skill )
	else
		tinsert( Me.Profile.skills, header )
		tinsert( Me.Profile.skills, skill )
	end
	
	Me.PrintMessage( "|cFF8080ffYou have gained the "..data.name.." skill.|r", "SYSTEM" )
	
	Me.SkillFrame_UpdateSkills()
end

function Me.LearnSkillEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	local skill = GetSkillFromGUID( UIDropDownMenu_GetSelectedValue( DiceMasterLearnSkillEditor.SkillName ))
	local rank = tonumber( DiceMasterLearnSkillEditor.Rank:GetText() ) or 1
	
	if not rank or type( rank ) ~= "number" or rank < -9999 or rank > 9999 then
		rank = 1;
	end
	
	if not skill or not skill.name or not skill.guid or not skill.rank or not skill.author then
		UIErrorsFrame:AddMessage( "You must select a valid skill.", 1.0, 0.0, 0.0 );
		return
	end
	
	local skillData = {
		type = "skill";
		name = skill.name;
		icon = skill.icon;
		skillType = GetSkillHeaderName( skill.guid );
		desc = skill.desc or nil;
		guid = skill.guid;
		rank = rank;
		maxRank = skill.maxRank or 0;
		skillModifiers = skill.skillModifiers or {};
		author = skill.author;
		expanded = skill.expanded;
		showOnMenu = skill.showOnMenu;
		canEdit = skill.canEdit or false;
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = skillData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = skillData
	end
	
	Me.LearnSkillEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.LearnSkillEditor_Save()	
	local skill = GetSkillFromGUID( UIDropDownMenu_GetSelectedValue( DiceMasterLearnSkillEditor.SkillName ))
	local rank = tonumber( DiceMasterLearnSkillEditor.Rank:GetText() ) or 1
	
	if not rank or type( rank ) ~= "number" or rank < -9999 or rank > 9999 then
		rank = 1;
	end
	
	if not skill or not skill.name or not skill.guid or not skill.rank or not skill.author then
		UIErrorsFrame:AddMessage( "You must select a valid skill.", 1.0, 0.0, 0.0 );
		return
	end
	
	local skillData = {
		type = "skill";
		name = skill.name;
		icon = skill.icon;
		skillType = GetSkillHeaderName( skill.guid );
		desc = skill.desc or nil;
		guid = skill.guid;
		rank = rank;
		maxRank = skill.maxRank or 0;
		skillModifiers = skill.SkillModifiers or {};
		author = skill.author;
		expanded = skill.expanded;
		showOnMenu = skill.showOnMenu;
		canEdit = skill.canEdit or false;
	}
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, skillData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, skillData )
	end
	Me.ItemEditorEffectsList_Update()
	
	Me.LearnSkillEditor_Close()
end

-------------------------------------------------------------------------------
-- Close the skill editor window. Use this instead of a direct Hide()
--
function Me.LearnSkillEditor_Close()
	Me.LearnSkillEditor_Refresh()
	DiceMasterLearnSkillEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnSkillEditor_Save()
	end)
	DiceMasterLearnSkillEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the skill editor window.
--
function Me.LearnSkillEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not ( frame ) then
		frame = DiceMasterTraitEditor
	end
	DiceMasterLearnSkillEditor.parent = frame
	DiceMasterLearnSkillEditor:ClearAllPoints()
	DiceMasterLearnSkillEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterLearnSkillEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnSkillEditor_Save()
	end)
	
	Me.LearnSkillEditor_Refresh()
	DiceMasterLearnSkillEditor:Show()
end