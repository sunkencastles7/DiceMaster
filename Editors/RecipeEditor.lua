-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Learn Recipe editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

Me.learnRecipe = {}

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

function Me.RecipeEditorGrantSkill_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetSelectedValue(DiceMasterLearnRecipeEditor.GrantSkillName, arg1, false)
end

function Me.RecipeEditorGrantSkill_OnLoad(frame, level, menuList)
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
		info.text = "(None)"
		info.arg1 = 0;
		info.value = 0;
		info.func = Me.RecipeEditorGrantSkill_OnClick;
		info.checked = UIDropDownMenu_GetText(DiceMasterLearnRecipeEditor.GrantSkillName) == info.text;
		UIDropDownMenu_AddButton(info)
	elseif menuList then
		for i = 1,#skillsList[menuList] do
			info.text = skillsList[menuList][i].name
			info.arg1 = skillsList[menuList][i].guid
			info.value = skillsList[menuList][i].guid
			info.func = Me.RecipeEditorGrantSkill_OnClick;
			info.notCheckable = false;
			info.tooltipTitle = skillsList[menuList][i].name;
			if skillsList[menuList][i].skill then
				info.tooltipText = skillsList[menuList][i].desc;
			end
			info.tooltipOnButton = true;
			info.checked = UIDropDownMenu_GetText(DiceMasterLearnRecipeEditor.GrantSkillName) == info.text;
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Me.RecipeEditorRequiredSkill_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetSelectedValue(DiceMasterLearnRecipeEditor.RequiredSkillName, arg1, false)
end

function Me.RecipeEditorRequiredSkill_OnLoad(frame, level, menuList)
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
		info.text = "(None)"
		info.arg1 = 0;
		info.value = 0;
		info.func = Me.RecipeEditorRequiredSkill_OnClick;
		info.checked = UIDropDownMenu_GetText(DiceMasterLearnRecipeEditor.RequiredSkillName) == info.text;
		UIDropDownMenu_AddButton(info)
	elseif menuList then
		for i = 1,#skillsList[menuList] do
			info.text = skillsList[menuList][i].name
			info.arg1 = skillsList[menuList][i].guid
			info.value = skillsList[menuList][i].guid
			info.func = Me.RecipeEditorRequiredSkill_OnClick;
			info.notCheckable = false;
			info.tooltipTitle = skillsList[menuList][i].name;
			if skillsList[menuList][i].skill then
				info.tooltipText = skillsList[menuList][i].desc;
			end
			info.tooltipOnButton = true;
			info.checked = UIDropDownMenu_GetText(DiceMasterLearnRecipeEditor.RequiredSkillName) == info.text;
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Me.LearnRecipeEditor_ChooseReagent( id )
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.chooseCursor = true;
	cursorIcon.chooseID = id;
	SetCursor( "CAST_CURSOR" )
end

function Me.LearnRecipeEditor_ChooseRequiredTool()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.chooseCursor = true;
	cursorIcon.chooseID = "REQUIREDTOOL";
	SetCursor( "CAST_CURSOR" )
end

function Me.LearnRecipeEditor_ChooseItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.chooseCursor = true;
	cursorIcon.chooseID = "CRAFTEDITEM";
	SetCursor( "CAST_CURSOR" )
end

function Me.LearnRecipeEditor_LoadReagent( itemIndex, id )	
	local item = Me.GetItemInfo( Me.Profile.inventory[itemIndex].guid )
	
	if not item then
		return
	end
	
	if Me.learnRecipe.item and item.guid == Me.learnRecipe.item.guid then
		UIErrorsFrame:AddMessage( "Crafted items cannot use themselves as a reagent.", 1.0, 0.0, 0.0 );
		return
	end
	
	if Me.learnRecipe.reagents then
		for i = 1,#Me.learnRecipe.reagents do
			if Me.learnRecipe.reagents[i].guid == item.guid then
				UIErrorsFrame:AddMessage( "That reagent is already being used.", 1.0, 0.0, 0.0 );
				return
			end
		end
	else
		Me.learnRecipe.reagents = {};
	end
	
	Me.learnRecipe.reagents[id] = item
	
	local reagent = _G["DiceMasterLearnRecipeEditorReagent"..id]
	local name = _G["DiceMasterLearnRecipeEditorReagent"..id.."Name"];
	local amount = _G["DiceMasterLearnRecipeEditorReagent"..id.."Amount"];
	
	SetItemButtonTexture(reagent, item.icon or "Interface/Icons/inv_misc_questionmark");
	name:SetText(item.name or "");
	amount:SetText(item.count or 1);
end

function Me.LearnRecipeEditor_RemoveReagent( id )
	tremove( Me.learnRecipe.reagents, id )
	
	local reagent = _G["DiceMasterLearnRecipeEditorReagent"..id]
	local name = _G["DiceMasterLearnRecipeEditorReagent"..id.."Name"];
	local amount = _G["DiceMasterLearnRecipeEditorReagent"..id.."Amount"];
	
	SetItemButtonTexture(reagent, "Interface/Icons/inv_misc_questionmark");
	name:SetText("");
	amount:SetText(1);
end

function Me.LearnRecipeEditor_LoadRequiredTool( itemIndex )	
	local item = Me.GetItemInfo( Me.Profile.inventory[itemIndex].guid )
	
	if not item then
		return
	end
	
	if Me.learnRecipe.item and item.guid == Me.learnRecipe.item.guid then
		UIErrorsFrame:AddMessage( "Crafted items cannot use themselves as a required tool.", 1.0, 0.0, 0.0 );
		return
	end
	
	if Me.learnRecipe.reagents then
		for i = 1,#Me.learnRecipe.reagents do
			if Me.learnRecipe.reagents[i].guid == item.guid then
				UIErrorsFrame:AddMessage( "That reagent is already being used.", 1.0, 0.0, 0.0 );
				return
			end
		end
	end
	
	Me.learnRecipe.requiredTool = item
	
	local frame = DiceMasterLearnRecipeEditor
	
	SetItemButtonTexture(frame.ToolIcon, item.icon or "Interface/Icons/inv_misc_questionmark" );
	DiceMasterLearnRecipeEditorToolIconName:SetText( item.name or "")
end

function Me.LearnRecipeEditor_LoadItem( itemIndex )	
	local item = Me.GetItemInfo( Me.Profile.inventory[itemIndex].guid )
	
	if not item then
		return
	end
	
	if Me.learnRecipe.reagents then
		for i = 1,#Me.learnRecipe.reagents do
			if Me.learnRecipe.reagents[i].guid == item.guid then
				UIErrorsFrame:AddMessage( "That reagent is already being used.", 1.0, 0.0, 0.0 );
				return
			end
		end
	end
	
	Me.learnRecipe.item = item
	
	local frame = DiceMasterLearnRecipeEditor
	
	SetItemButtonTexture(frame.SkillIcon, item.icon or "Interface/Icons/inv_misc_questionmark");
	DiceMasterLearnRecipeEditorSkillIconName:SetText( item.name or "" )
end

function Me.LearnRecipeEditor_Refresh()
	local frame = DiceMasterLearnRecipeEditor
	
	-- Reset skill button
	SetItemButtonTexture(frame.SkillIcon, "Interface/Icons/inv_misc_questionmark");
	DiceMasterLearnRecipeEditorSkillIconName:SetText("")
	DiceMasterLearnRecipeEditorSkillIconCount:SetText("")
	frame.SkillIcon.minAmount:SetText("1")
	frame.SkillIcon.maxAmount:SetText("1")
	frame.Description.EditBox:SetText("")
	UIDropDownMenu_SetText( frame.GrantSkillName, "(None)" )
	frame.GrantSkillAmount:SetText("1")
	
	-- Reset tool button
	SetItemButtonTexture(frame.ToolIcon, "Interface/Icons/inv_misc_questionmark");
	DiceMasterLearnRecipeEditorToolIconName:SetText("")
	DiceMasterLearnRecipeEditorToolIconCount:SetText("")
	
	-- Reset required skill
	UIDropDownMenu_SetText( frame.RequiredSkillName, "(None)" )
	frame.RequiredSkillAmount:SetText("1")
	
	-- Reset reagent buttons
	for i = 1, 8 do
		local reagent = _G["DiceMasterLearnRecipeEditorReagent"..i]
		local name = _G["DiceMasterLearnRecipeEditorReagent"..i.."Name"];
		local amount = _G["DiceMasterLearnRecipeEditorReagent"..i.."Amount"];
		SetItemButtonTexture(reagent, "Interface/Icons/inv_misc_questionmark");
		name:SetText("");
		amount:SetText("1");
	end
	
	Me.learnRecipe = {}
	Me.EffectEditingIndex = nil;
end

local function GetHeaderPositionByName( headerName )
	for i = 1, #Me.Profile.recipes do
		if Me.Profile.recipes[i].type == "header" and Me.Profile.recipes[i].name == headerName then
			return i;
		end
	end
	return nil;
end

local function LearnRecipe( data )
	if not data or not data.type or not data.item or not data.reagents or data.type ~= "recipe" then
		return
	end
	
	local item = data.item or nil;
	
	if not item then
		return
	end
	
	local header;
	if ( data.skill and data.skill.name ) then
		header = data.skill.name;
	else
		header = "Miscellaneous";
	end
	local headerPosition = GetHeaderPositionByName( header )
	-- we assume the end of this subclass is the end of the recipe list until it can be found.
	local headerEndPosition = #Me.Profile.recipes
	
	local noHeader = true;
	for i = 1, #Me.Profile.recipes do
		local recipe = Me.Profile.recipes[i]
		if recipe.type and recipe.type == "header" and recipe.name == header then
			headerPosition = i;
			data.expanded = Me.Profile.recipes[i].expanded;
			noHeader = false;
		elseif recipe.type and recipe.type == "recipe" and data.item.name < recipe.item.name then
			-- find the recipe position alphabetically
			headerEndPosition = i - 1;
			break;
		elseif recipe.type and recipe.type == "header" then
			-- continue iterating until we reach the end of this subclass.
			headerEndPosition = i;
			break;
		end
	end
	
	if ( headerPosition ) then
		if ( noHeader ) then
			local newHeader = {
				type = "header";
				name = header;
				expanded = true;
			}
			tinsert( Me.Profile.recipes, headerEndPosition, newHeader );
		end
		tinsert( Me.Profile.recipes, headerEndPosition + 1, data )
		Me.NewRecipeLearnedAlertFrame_SetUp( headerEndPosition + 1 )
	else
		if ( noHeader ) then
			local newHeader = {
				type = "header";
				name = header;
				expanded = true;
			}
			tinsert( Me.Profile.recipes, newHeader );
		end
		tinsert( Me.Profile.recipes, data )
		Me.NewRecipeLearnedAlertFrame_SetUp( #Me.Profile.recipes )
	end
	
	Me.TradeSkillFrame_Update()
	
	Me.PrintMessage( "You have learned how to create a new item: "..data.item.name..".", "SYSTEM" )
end

function Me.LearnRecipeEditor_LearnRecipe( data )
	if not data or not data.type or not data.item or not data.reagents or data.type ~= "recipe" then
		return
	end
	
	local item = data.item or nil;
	
	if not item then
		return
	end
	
	-- Find duplicate recipes
	for i = 1, #Me.Profile.recipes do
		local recipe = Me.Profile.recipes[i]
		if recipe.item and recipe.item.guid == item.guid then
			UIErrorsFrame:AddMessage( "Already Known", 1.0, 0.0, 0.0 );
			return
		end
	end

	Dismount()
	Me.CastBar( "cast", "Learning", nil, 3, false, 11562 )
	DiceMasterCastingBarFrame["OnFinished"] = function() 		
		LearnRecipe( data )
	end
end

function Me.LearnRecipeEditor_Load( effectIndex )
	
	local effect = nil
	if Me.ItemEditing then
		effect = Me.ItemEditing.effects[ effectIndex ]
	elseif Me.newItem then
		effect = Me.newItem.effects[ effectIndex ]
	end
	
	if not effect then
		return
	end
	
	Me.EffectEditingIndex = effectIndex
	Me.learnRecipe.item = effect.item
	Me.learnRecipe.requiredTool = effect.requiredTool or nil
	Me.learnRecipe.reagents = effect.reagents or nil
	
	local item = Me.FindFirstStack( Me.learnRecipe.item.guid ) or nil;
	
	if not item then
		Me.LearnRecipeEditor_Refresh()
		return
	end
	
	local frame = DiceMasterLearnRecipeEditor
	
	-- Set skill button
	SetItemButtonTexture(frame.SkillIcon, effect.item.icon or "Interface/Icons/inv_misc_questionmark");
	DiceMasterLearnRecipeEditorSkillIconName:SetText( effect.item.name or "" )
	if effect.yieldMax and ( effect.yieldMax > 1 ) then
		if ( effect.yieldMin == effect.yieldMax ) then
			DiceMasterLearnRecipeEditorSkillIconCount:SetText(effect.yieldMin);
		else
			DiceMasterLearnRecipeEditorSkillIconCount:SetText(effect.yieldMin.."-"..effect.yieldMax);
		end
		if ( DiceMasterLearnRecipeEditorSkillIconCount:GetWidth() > 39 ) then
			DiceMasterLearnRecipeEditorSkillIconCount:SetText("~"..floor((effect.yieldMin + effect.yieldMax)/2));
		end
	else
		DiceMasterLearnRecipeEditorSkillIconCount:SetText("");
	end
	frame.SkillIcon.minAmount:SetText( effect.yieldMin or 1 )
	frame.SkillIcon.maxAmount:SetText( effect.yieldMax or 1 )
	frame.Description.EditBox:SetText( effect.description or "" )
	if ( effect.skill and effect.skill.guid ) then
		UIDropDownMenu_SetSelectedValue( frame.GrantSkillName, effect.skill.guid or 0 )
		UIDropDownMenu_SetText( frame.GrantSkillName, effect.skill.name or "(None)" )
	else
		UIDropDownMenu_SetText( frame.GrantSkillName, "(None)" )
	end
	if ( effect.skill and effect.skill.amount ) then 
		frame.GrantSkillAmount:SetText( effect.skill.amount or 1 )
	else
		frame.GrantSkillAmount:SetText( 1 )
	end
	if ( effect.requiredSkill and effect.requiredSkill.guid ) then
		UIDropDownMenu_SetSelectedValue( frame.RequiredSkillName, effect.requiredSkill.guid or 0 )
		UIDropDownMenu_SetText( frame.RequiredSkillName, effect.requiredSkill.name or "(None)" )
	else
		UIDropDownMenu_SetText( frame.RequiredSkillName, "(None)" )
	end
	if ( effect.requiredSkill and effect.requiredSkill.rank ) then
		frame.RequiredSkillAmount:SetText( effect.requiredSkill.amount or 1 )
	else
		frame.RequiredSkillAmount:SetText( 1 )
	end
	
	-- Set tool button
	if effect.requiredTool then
		SetItemButtonTexture(frame.ToolIcon, effect.requiredTool.icon or "Interface/Icons/inv_misc_questionmark" );
		DiceMasterLearnRecipeEditorToolIconName:SetText( effect.requiredTool.name or "")
	else
		SetItemButtonTexture(frame.ToolIcon, "Interface/Icons/inv_misc_questionmark" );
		DiceMasterLearnRecipeEditorToolIconName:SetText( "" )
	end
	DiceMasterLearnRecipeEditorToolIconCount:SetText( "" )
	
	-- Set reagent buttons
	for i = 1, #effect.reagents do
		local reagent = effect.reagents[i]
		local reagentName, reagentTexture, reagentCount = effect.reagents[i].name, effect.reagents[i].icon, effect.reagents[i].count or 1;
		local reagent = _G["DiceMasterLearnRecipeEditorReagent"..i]
		local name = _G["DiceMasterLearnRecipeEditorReagent"..i.."Name"];
		local amount = _G["DiceMasterLearnRecipeEditorReagent"..i.."Amount"];
		if ( not reagentName or not reagentTexture ) then
			SetItemButtonTexture(reagent, "Interface/Icons/inv_misc_questionmark");
			name:SetText("");
			amount:SetText("1");
		else
			SetItemButtonTexture(reagent, reagentTexture);
			name:SetText(reagentName);
			amount:SetText(reagentCount);
		end
	end
	
	DiceMasterLearnRecipeEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnRecipeEditor_SaveEdits()
	end)
end

function Me.LearnRecipeEditor_SaveEdits()
	if not Me.learnRecipe.item or not Me.EffectEditingIndex then
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0 );
		return
	end
	
	local item = Me.FindFirstStack( Me.learnRecipe.item.guid ) or nil;
	local requiredTool 
	if Me.learnRecipe.requiredTool then
		requiredTool = Me.FindFirstStack( Me.learnRecipe.requiredTool.guid )
	end
	
	if not item then
		return
	end
	
	local frame = DiceMasterLearnRecipeEditor
	
	local description = frame.Description.EditBox:GetText() or "";
	local yieldMin = tonumber( frame.SkillIcon.minAmount:GetText() ) or 1;
	local yieldMax = tonumber( frame.SkillIcon.maxAmount:GetText() ) or 1;
	local reagents = Me.learnRecipe.reagents or nil
	local skill = GetSkillFromGUID( UIDropDownMenu_GetSelectedValue( frame.GrantSkillName ))
	if ( skill and skill.name ) then
		skill.amount = frame.GrantSkillAmount:GetText() or 1;
	end
	local requiredSkill = GetSkillFromGUID( UIDropDownMenu_GetSelectedValue( frame.RequiredSkillName ))
	if ( requiredSkill and requiredSkill.name ) then
		requiredSkill.rank = frame.RequiredSkillAmount:GetText() or 1;
	end
	
	if not( reagents ) or type(reagents)~="table" or #reagents < 1 then
		UIErrorsFrame:AddMessage( "Recipes must include at least one reagent.", 1.0, 0.0, 0.0 );
		return
	end
	
	local recipeData = {
		type = "recipe";
		item = item;
		description = description;
		lastCastTime = 0;
		cooldown = 0;
		skill = skill or nil;
		yieldMin = yieldMin;
		yieldMax = yieldMax;
		reagents = {};
		requiredTool = requiredTool or nil;
		requiredSkill = requiredSkill or nil;
	}
	
	for i = 1, #reagents do
		recipeData.reagents[i] = reagents[i];
		recipeData.reagents[i].count = tonumber( _G["DiceMasterLearnRecipeEditorReagent"..i.."Amount"]:GetText() ) or 1;
	end
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = recipeData
		Me.ItemEditing.requiredSkill = requiredSkill or nil;
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = recipeData
		Me.newItem.requiredSkill = requiredSkill or nil;
	end
	
	Me.LearnRecipeEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.LearnRecipeEditor_Save()
	if not Me.learnRecipe.item then
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0 );
		return
	end
	
	local item = Me.FindFirstStack( Me.learnRecipe.item.guid ) or nil;
	local requiredTool 
	if Me.learnRecipe.requiredTool then
		requiredTool = Me.FindFirstStack( Me.learnRecipe.requiredTool.guid )
	end
	
	if not item then
		return
	end
	
	local frame = DiceMasterLearnRecipeEditor
	
	local description = frame.Description.EditBox:GetText() or "";
	local yieldMin = tonumber( frame.SkillIcon.minAmount:GetText() ) or 1;
	local yieldMax = tonumber( frame.SkillIcon.maxAmount:GetText() ) or 1;
	local reagents = Me.learnRecipe.reagents or nil
	local skill = GetSkillFromGUID( UIDropDownMenu_GetSelectedValue( frame.GrantSkillName ))
	if ( skill and skill.name ) then
		skill.amount = frame.GrantSkillAmount:GetText() or 1;
	end
	local requiredSkill = GetSkillFromGUID( UIDropDownMenu_GetSelectedValue( frame.RequiredSkillName ))
	if ( requiredSkill and requiredSkill.name ) then
		requiredSkill.rank = frame.RequiredSkillAmount:GetText() or 1;
	end
	
	if not( reagents ) or type(reagents)~="table" or #reagents < 1 then
		UIErrorsFrame:AddMessage( "Recipes must include at least one reagent.", 1.0, 0.0, 0.0 );
		return
	end
	
	local recipeData = {
		type = "recipe";
		item = item;
		description = description;
		lastCastTime = 0;
		cooldown = 0;
		skill = skill or nil;
		yieldMin = yieldMin;
		yieldMax = yieldMax;
		reagents = {};
		requiredTool = requiredTool or nil;
		requiredSkill = requiredSkill or nil;
	}
	
	for i = 1, #reagents do
		recipeData.reagents[i] = reagents[i];
		recipeData.reagents[i].count = tonumber( _G["DiceMasterLearnRecipeEditorReagent"..i.."Amount"]:GetText() ) or 1;
	end
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, recipeData )
		Me.ItemEditing.requiredSkill = requiredSkill or nil;
	elseif Me.newItem then
		tinsert( Me.newItem.effects, recipeData )
		Me.newItem.requiredSkill = requiredSkill or nil;
	end
	
	Me.LearnRecipeEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the message editor window. Use this instead of a direct Hide()
--
function Me.LearnRecipeEditor_Close()
	Me.LearnRecipeEditor_Refresh()
	DiceMasterLearnRecipeEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnRecipeEditor_Save()
	end)
	DiceMasterLearnRecipeEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the message editor window.
--
function Me.LearnRecipeEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterLearnRecipeEditor:ClearAllPoints()
	DiceMasterLearnRecipeEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterLearnRecipeEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnRecipeEditor_Save()
	end)
	
	Me.LearnRecipeEditor_Refresh()
	DiceMasterLearnRecipeEditor:Show()
end
