-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Skill Inspector Frame
--

local Me      = DiceMaster4
local Profile = Me.Profile

Me.filteredInspectList = {};

local SHOP_ITEMS_PER_PAGE = 12;

local function GetSkillLineInfo( skillIndex )
	local skill = Me.filteredInspectList[skillIndex];
		
	return skill.name, skill.icon or "Interface/Icons/inv_misc_questionmark", skill.desc, skill.type, skill.rank or 0, skill.maxRank or 0, skill.author, skill.guid, skill.skillModifiers or {}, skill.showOnMenu or nil, skill.canEdit or nil;
end

local function GetSkillLineInfoByPosition( skillPosition )
	if not Me.inspectData[Me.statInspectName].skills then
		return
	end 

	local skill = Me.inspectData[Me.statInspectName].skills[skillPosition];
		
	return skill.name, skill.icon or "Interface/Icons/inv_misc_questionmark", skill.desc, skill.type, skill.rank or 0, skill.maxRank or 0, skill.author, skill.guid, skill.skillModifiers or {}, skill.showOnMenu or nil, skill.canEdit or nil;
end

local function GetSkillByGUID( guid )
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i].guid == guid then
			return Me.Profile.skills[i];
		end
	end
	return
end

local function GetModifierNamesFromSkillGUID( guid )
	if not guid then
		return
	end

	local skill = GetSkillByGUID( guid )

	if not( skill and skill.skillModifiers and #skill.skillModifiers > 0 ) then
		return
	end

	local modifiers = "(Modified by " .. GetSkillByGUID( skill.skillModifiers[1] )["name"];
	
	-- Grab values from skills in the modifiers table
	-- by GUID
	for skillIndex = 2,#skill.skillModifiers do
		for i = 1, #Me.inspectData[Me.statInspectName].skills do
			if Me.inspectData[Me.statInspectName].skills[i].guid == skill.skillModifiers[skillIndex] then
				modifiers = modifiers .. ", " .. Me.inspectData[Me.statInspectName].skills[i].name;
			end
		end
	end
	
	-- Find any buffs that are also boosting this skill...
	for i = 1,#Me.inspectData[Me.statInspectName].buffsActive do
		if Me.inspectData[Me.statInspectName].buffsActive[i].skill and Me.inspectData[Me.statInspectName].buffsActive[i].skill == guid then
			modifiers = modifiers .. ", " .. Me.inspectData[Me.statInspectName].buffsActive[i].name;
		end
	end

	modifiers = modifiers .. ")"
	
	return modifiers
end

local function GetModifiersFromSkillGUID( guid )
	if not guid then
		return 0;
	end

	local skill = GetSkillByGUID( guid );

	if not( skill and skill.skillModifiers ) then
		return 0;
	end

	local modifiers = 0;
	
	-- Grab values from skills in the modifiers table
	-- by GUID
	for skillIndex = 1, #skill.skillModifiers do
		for i = 1, #Me.inspectData[Me.statInspectName].skills do
			if Me.inspectData[Me.statInspectName].skills[i].guid == skill.skillModifiers[skillIndex] then
				modifiers = modifiers + Me.inspectData[Me.statInspectName].skills[i].rank;
			end
		end
	end
	
	-- Find any buffs that are also boosting this skill...
	for i = 1,#Profile.buffsActive do
		if Me.inspectData[Me.statInspectName].buffsActive[i].skill and Me.inspectData[Me.statInspectName].buffsActive[i].skill == guid then
			modifiers = modifiers + ( Me.inspectData[Me.statInspectName].buffsActive[i].skillRank * Me.inspectData[Me.statInspectName].buffsActive[i].count );
		end
	end
	
	return modifiers;
end

function Me.StatInspector_ExpandAllSkills()
	local list = Me.inspectData[Me.statInspectName].skills
	for i = 1, #list do
		if not( list[i].type == "header" ) then
			Me.inspectData[Me.statInspectName].skills[i].expanded = true;
		end
	end
	Me.StatInspector_Update()
end

function Me.StatInspector_ExpandSkillHeader( skillPosition )
	local list = Me.inspectData[Me.statInspectName].skills
	for i = skillPosition + 1, #list do
		if list[i] then
			if list[i].type == "header" then
				-- Stop when we reach another header
				break
			else
				Me.inspectData[Me.statInspectName].skills[i].expanded = true;
			end
		end
	end
	Me.StatInspector_Update()
end

function Me.StatInspector_CollapseSkillHeader( skillPosition )
	local list = Me.inspectData[Me.statInspectName].skills
	for i = skillPosition + 1, #list do
		if list[i] then
			if list[i].type == "header" then
				-- Stop when we reach another header
				break
			else
				Me.inspectData[Me.statInspectName].skills[i].expanded = false;
			end
		end
	end
	Me.StatInspector_Update()
end

function Me.StatInspector_CollapseAllSkills()
	local list = Me.inspectData[Me.statInspectName].skills
	for i = 1, #list do
		if not( list[i].type == "header" ) then
			Me.inspectData[Me.statInspectName].skills[i].expanded = false;
		end
	end
	Me.StatInspector_Update()
end

function Me.StatInspector_BuildFilteredList()
	if not( Me.statInspectName and Me.inspectData[Me.statInspectName].skills ) then
		return
	end
	for i = 1, #Me.inspectData[Me.statInspectName].skills do
		if Me.inspectData[Me.statInspectName].skills[i].expanded or Me.inspectData[Me.statInspectName].skills[i].type == "header" then
			local skill = Me.inspectData[Me.statInspectName].skills[i];
			skill.skillPosition = i;
			tinsert( Me.filteredInspectList, skill );
		end
	end
end

function Me.StatInspector_SetStatusBar( statusBarID, skillIndex, numSkills )
	-- Get info
	local skillName, skillIcon, skillDescription, skillType, skillRank, skillMaxRank, skillAuthor, skillGUID, skillModifiers, skillShowOnMenu, skillCanEdit = GetSkillLineInfo(skillIndex);
	skillRankStart = skillRank;
	
	-- Skill bar objects
	local statusBar = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID];
	local statusBarLabel = "DiceMasterStatInspectorSkillRankFrame"..statusBarID;
	local statusBarSkillRank = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID.."SkillRank"];
	local statusBarName = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID.."SkillName"];
	local statusBarIcon = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID.."SkillIcon"];
	local statusBarBorder = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID.."Border"];
	local statusBarBackground = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID.."Background"];
	local statusBarFillBar = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID.."FillBar"];

	statusBarFillBar:Hide();

	-- Header objects
	local skillRankFrameBorderTexture = _G["DiceMasterStatInspectorSkillRankFrame"..statusBarID.."Border"];
	local skillTypeLabelText = _G["DiceMasterStatInspectorSkillTypeLabel"..statusBarID];
	
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
		skillTypeLabelText.skillPosition = Me.filteredInspectList[skillIndex].skillPosition;
		skillRankFrameBorderTexture:Hide();
		statusBar:Hide();
		local normalTexture = _G["DiceMasterStatInspectorSkillTypeLabel"..statusBarID.."NormalTexture"];
		local isExpanded = ( Me.filteredInspectList[skillIndex+1] and Me.filteredInspectList[skillIndex+1].expanded );
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
	statusBar.skillPosition = Me.filteredInspectList[skillIndex].skillPosition;
	statusBarName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	statusBarIcon:SetTexture( skillIcon );
	statusBarSkillRank:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	statusBarSkillRank:ClearAllPoints();
	statusBarSkillRank:SetPoint("LEFT", "DiceMasterStatInspectorSkillRankFrame"..statusBarID.."SkillName", "RIGHT", 13, 0);
	statusBarSkillRank:SetJustifyH("LEFT");
	statusBarBorder.skillName = skillName;
	statusBarBorder.skillIcon = skillIcon;
	-- Set skill description text
	if ( skillDescription ) then
		local modifiedSkillRank;
		if ( GetModifiersFromSkillGUID( skillGUID ) ~= 0 ) then
			local modifiers = GetModifiersFromSkillGUID( skillGUID );
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
			local modifier = GetSkillByGUID( skillModifiers[i] );
			local color = RED_FONT_COLOR_CODE;
			if modifier and tonumber( modifier.rank ) > 0 then
				color = GREEN_FONT_COLOR_CODE.."+"
			end
			if modifier and tonumber( modifier.rank ) ~= 0 then
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
	if (statusBar.skillPosition == DiceMasterStatInspectorSkillFrame.statusBarClickedPosition) then
		statusBarBorder:LockHighlight();
	else
		statusBarBorder:UnlockHighlight();
	end

	-- Default width
	skillRankFrameWidth = 256;

	statusBarName:SetText(skillName);
	
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
		if ( GetModifiersFromSkillGUID( skillGUID ) ~= 0 ) then
			local modifiers = GetModifiersFromSkillGUID( skillGUID );
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
		if ( GetModifiersFromSkillGUID( skillGUID ) == 0 ) then
			statusBarSkillRank:SetText(skillRank.."/"..skillMaxRank);
			statusBarFillBar:Hide();
		else
			local modifiers = GetModifiersFromSkillGUID( skillGUID );
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


function Me.StatInspectorDetailFrame_SetStatusBar( skillPosition )
	if not skillPosition then
		return
	end 
	
	-- Get info
	local skillName, skillIcon, skillDescription, skillType, skillRank, skillMaxRank, skillAuthor, skillGUID, skillModifiers, skillShowOnMenu, skillCanEdit = GetSkillLineInfoByPosition(skillPosition);
	skillRankStart = skillRank;

	-- Skill bar objects
	local statusBar = _G["DiceMasterStatInspectorSkillDetailStatusBar"];
	local statusBarBackground = _G["DiceMasterStatInspectorSkillDetailStatusBarBackground"];
	local statusBarSkillRank = _G["DiceMasterStatInspectorSkillDetailStatusBarSkillRank"];
	local statusBarName = _G["DiceMasterStatInspectorSkillDetailStatusBarSkillName"];
	local statusBarIcon = _G["DiceMasterStatInspectorSkillDetailStatusBarSkillIcon"];
	local statusBarFillBar = _G["DiceMasterStatInspectorSkillDetailStatusBarFillBar"];

	-- Frame width vars
	local skillRankFrameWidth = 0;

	-- Hide or show skill bar
	if ( not skillName or skillName == "" ) then
		statusBar:Hide();
		DiceMasterStatInspectorSkillDetailDescriptionText:Hide();
		return;
	else
		statusBar:Show();
		DiceMasterStatInspectorSkillDetailDescriptionText:Show();
	end
		
	-- Set skillbar info
	statusBarName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	statusBarIcon:SetTexture( skillIcon );
	statusBarSkillRank:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	statusBarSkillRank:ClearAllPoints();
	statusBarSkillRank:SetPoint("LEFT", "DiceMasterStatInspectorSkillDetailStatusBarSkillName", "RIGHT", 13, 0);
	statusBarSkillRank:SetJustifyH("LEFT");

	-- Anchor the text to the left by default
	statusBarName:ClearAllPoints();
	statusBarName:SetPoint("LEFT", statusBar, "LEFT", 6, 1);

	-- Set skill description text
	if skillModifiers and #skillModifiers > 0 then
		for i = 1, #skillModifiers do 
			local modifier = GetSkillByGUID( skillModifiers[i] );
			local color = RED_FONT_COLOR_CODE;
			if modifier.rank > 0 then
				color = GREEN_FONT_COLOR_CODE.."+"
			end
			if modifier.rank ~= 0 then
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
		DiceMasterStatInspectorSkillDetailDescriptionText:SetText(skillDescription .. "|n|n|cFFFFD100Creator:|r "..skillAuthor.."|n");
		DiceMasterStatInspectorSkillDetailDescriptionText:Show();
	elseif skillAuthor then
		DiceMasterStatInspectorSkillDetailDescriptionText:SetText("|cFFFFD100Creator:|r "..skillAuthor.."|n");
		DiceMasterStatInspectorSkillDetailDescriptionText:Show();
	else
		DiceMasterStatInspectorSkillDetailDescriptionText:SetText("");
		DiceMasterStatInspectorSkillDetailDescriptionText:Hide();
	end
	
	-- Default width
	skillRankFrameWidth = 256;

	-- Normal skill
	statusBarName:SetText(skillName);
	statusBar:SetStatusBarColor(0.0, 0.0, 0.5);
	statusBarBackground:SetVertexColor(0.0, 0.0, 0.75, 0.5);

	DiceMasterStatInspectorSkillDetailCostText:Hide();
	
	if ( DiceMasterStatInspectorSkillDetailCostText:IsVisible() ) then
		DiceMasterStatInspectorSkillDetailDescriptionText:SetPoint("TOP", "DiceMasterStatInspectorSkillDetailCostText", "BOTTOM", 0, -20 );
	else
		DiceMasterStatInspectorSkillDetailDescriptionText:SetPoint("TOP", "DiceMasterStatInspectorSkillDetailCostText", "TOP", 0, -10 );
	end

	if ( skillMaxRank == 0 ) then
		-- If max rank in a skill is 0 assume that its a proficiency
		statusBar:SetMinMaxValues(0, 1);
		statusBar:SetValue(1);
		statusBar:SetStatusBarColor(0.5, 0.5, 0.5);
		if tonumber( skillRank ) < 0 then
			skillRank = RED_FONT_COLOR_CODE .. skillRank .. FONT_COLOR_CODE_CLOSE;
		end
		if ( GetModifiersFromSkillGUID( skillGUID ) ~= 0 ) then
			local modifiers = GetModifiersFromSkillGUID( skillGUID );
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
		statusBar:SetValue(skillRankStart);
		if tonumber( skillRank ) < 0 then
			skillRank = RED_FONT_COLOR_CODE .. skillRank .. FONT_COLOR_CODE_CLOSE;
		end
		if ( GetModifiersFromSkillGUID( skillGUID ) == 0 ) then
			statusBarSkillRank:SetText(skillRank.."/"..skillMaxRank);
		else
			local modifiers = GetModifiersFromSkillGUID( skillGUID );
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

-------------------------------------------------------------------------------
-- Refresh the skills list.
--
--
function Me.StatInspector_Update()

	if Me.inspectName and Me.inspectData[Me.inspectName].hasDM4 then
		Me.statInspectName = Me.inspectName
		Me.StatInspector_OnTabChanged()
	end
	
	Me.filteredInspectList = {};
	Me.StatInspector_BuildFilteredList()
	local numSkills = #Me.filteredInspectList;
	local offset = FauxScrollFrame_GetOffset(DiceMasterStatInspectorSkillListScrollFrame) + 1;

	local index = 1;
	for i=offset,  offset + 12 - 1 do
		if ( i <= numSkills ) then
			Me.StatInspector_SetStatusBar(index, i, numSkills);
		else
			break;
		end
		index = index + 1;
	end
	
	-- Update the expand/collapse all button
	DiceMasterStatInspectorSkillFrameCollapseAllButton.isExpanded = 1;
	DiceMasterStatInspectorSkillFrameCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
	if numSkills > 0 then
		for i=1, #Me.inspectData[Me.statInspectName].skills do
			local skill = Me.inspectData[Me.statInspectName].skills[i];
			if not( skill.type == "header" ) then
				-- If one skill is not expanded then set isExpanded to false and break
				if not( skill.expanded ) then
					DiceMasterStatInspectorSkillFrameCollapseAllButton.isExpanded = nil;
					DiceMasterStatInspectorSkillFrameCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
					break;
				end
			end
		end
	end
	
	local store = Me.inspectData[Me.statInspectName];

	if store and store.alignment then
		UIDropDownMenu_SetText( DiceMasterStatInspectorSkillFrameAlignmentDropdown, "|cFFFFD100Alignment:|r " .. store.alignment )
	end

	-- Hide unused bars
	for i=index, 12 do
		_G["DiceMasterStatInspectorSkillRankFrame"..i]:Hide();
		_G["DiceMasterStatInspectorSkillTypeLabel"..i]:Hide();
	end

	-- Update scrollFrame
	FauxScrollFrame_Update(DiceMasterStatInspectorSkillListScrollFrame, numSkills, 12, 15 );
	
	DiceMasterStatInspectorSkillDetailScrollFrame:UpdateScrollChildRect();

	if DiceMasterStatInspectorSkillFrame.statusBarClickedPosition then
		Me.StatInspectorDetailFrame_SetStatusBar( DiceMasterStatInspectorSkillFrame.statusBarClickedPosition );
		DiceMasterStatInspectorSkillDetailScrollFrame:Show();
	else
		DiceMasterStatInspectorSkillDetailScrollFrame:Hide();
	end
	
	if store and store.hideShop then
		DiceMasterStatInspectorShopTab.Icon:SetDesaturated( true )
		DiceMasterStatInspectorShopTab:SetChecked( false )
		DiceMasterStatInspectorShopTab:Disable()
	else
		DiceMasterStatInspectorShopTab.Icon:SetDesaturated( false )
		DiceMasterStatInspectorShopTab:Enable()
	end
	
	Me.StatInspector_UpdatePet()
	Me.StatInspectorShopFrame_Update()
end

-------------------------------------------------------------------------------
-- Refresh the pet tab.
--
--
function Me.StatInspector_UpdatePet()
	
	if Me.inspectName and Me.inspectData[Me.inspectName] and Me.inspectData[Me.inspectName].pet and Me.inspectData[Me.inspectName].pet.enable then
		if UnitFactionGroup(Me.inspectName) == "Alliance" then
			DiceMasterStatInspectorPetFrameModelBG:SetTexture("Interface/AddOns/DiceMaster/Texture/PetFrameBackgroundAlliance")
		else
			DiceMasterStatInspectorPetFrameModelBG:SetTexture("Interface/AddOns/DiceMaster/Texture/PetFrameBackgroundHorde")
		end
		local pet = Me.inspectData[Me.inspectName].pet
		Me.statinspector.petFrame.petIcon:SetTexture( pet.icon )
		Me.statinspector.petFrame.petName:SetText( pet.name )
		Me.statinspector.petFrame.levelText:SetText( pet.type )
		DiceMasterStatInspectorPetModel:SetModelByCreatureDisplayID( pet.model )
		DiceMasterStatInspectorPetModel:SetScale( pet.scale or 0.2 )
		PanelTemplates_EnableTab(DiceMasterStatInspector, 2)
	else
		if PanelTemplates_GetSelectedTab(DiceMasterStatInspector) == 2 then
			PanelTemplates_SetTab(DiceMasterStatInspector, 1);
			DiceMasterStatInspectorSkillFrame:Show();
			DiceMasterStatInspectorPetFrame:Hide();
			PlaySound(841)
		end
		PanelTemplates_DisableTab(DiceMasterStatInspector, 2);
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
		elseif currency.description then
			GameTooltip:AddLine( currency.description, nil, nil, nil, true );
		end
		GameTooltip:AddLine( "|nTotal: |cFFFFFFFF" .. amount .. "|r", nil, nil, nil, true );
		GameTooltip:Show();
	end)

	local shop = Me.inspectData[ Me.statInspectName ].shop
	
	if Me.inspectData[Me.statInspectName].hideShop then
		shop = {}
		if DiceMasterStatInspectorShopFrame:IsShown() then
			DiceMasterStatInspectorTab1:Click()
		end
	end
	
	local numMerchantItems = #shop
	
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
			local item = shop[index]
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
				elseif currency.description then
					GameTooltip:AddLine( currency.description, nil, nil, nil, true );
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
-- OnLoad handler
--
-- Be careful in here because it's run before the addon is loaded.
--
function Me.StatInspector_OnLoad( self )
	Me.statinspector = self
	local scrollFrame = DiceMasterStatInspectorSkillFrame
	
	DiceMasterStatInspectorSkillListScrollFrameScrollBar:SetValue(0);
	
	scrollFrame.skillButtons = {};
	scrollFrame.skillRankBars = {};
	
	for i = 2, 12 do
		scrollFrame.skillButtons[i] = CreateFrame( "Button", "DiceMasterStatInspectorSkillTypeLabel" .. i, scrollFrame, "DiceMasterStatInspectorSkillLabelTemplate" )
		scrollFrame.skillButtons[i]:SetPoint( "LEFT", "DiceMasterStatInspectorSkillTypeLabel" .. ( i - 1 ), 0, -18 )
		
		scrollFrame.skillRankBars[i] = CreateFrame( "StatusBar", "DiceMasterStatInspectorSkillRankFrame" .. i, scrollFrame, "DiceMasterStatInspectorSkillStatusBarTemplate" )
		scrollFrame.skillRankBars[i]:SetMinMaxValues( 0, 1 )
		scrollFrame.skillRankBars[i]:SetValue( 1 )
		scrollFrame.skillRankBars[i]:SetID( i )
		scrollFrame.skillRankBars[i]:SetPoint( "TOPLEFT", "DiceMasterStatInspectorSkillRankFrame" .. ( i - 1 ), "BOTTOMLEFT", 0, -3 )
	end
		
	self:SetClampedToScreen( true )
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )	 
end

-------------------------------------------------------------------------------
-- When a new tab is selected.
--
function Me.StatInspector_OnTabChanged()
	if Me.statInspectName then
		SetPortraitTexture( Me.statinspector.PortraitContainer.portrait, Me.statInspectName or "none" )
		Me.statinspector.TitleContainer.TitleText:SetText( Me.GetTargetCharInfo( Me.statInspectName ) )
	else
		return
	end
	
	if DiceMasterStatInspectorShopFrame:IsShown() then
		if Me.inspectData[Me.statInspectName].shopModel then
			SetPortraitTextureFromCreatureDisplayID( Me.statinspector.PortraitContainer.portrait, Me.inspectData[Me.statInspectName].shopModel )
		end
		if Me.inspectData[Me.statInspectName].shopName then
			Me.statinspector.TitleContainer.TitleText:SetText( Me.inspectData[Me.statInspectName].shopName ) 
		end
	end
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
	DiceMasterStatInspectorTab1:Click()
	
	Me.statinspector.CloseButton:SetScript("OnClick",Me.StatInspector_OnCloseClicked)

	Me.statinspector:Show()
	Me.StatInspector_Update()
end