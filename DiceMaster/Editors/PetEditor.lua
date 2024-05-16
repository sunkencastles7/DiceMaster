-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Pet editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local foodTypes = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" }

Me.learnPet = {}

function Me.PetEditorDiet_OnClick(self, arg1, arg2, checked)
	if not Me.learnPet.foodTypes then
		Me.learnPet.foodTypes = {}
	end
	
	if checked then
		for i = 1, #Me.learnPet.foodTypes do
			if Me.learnPet.foodTypes[i] == self:GetName() then
				tremove( Me.learnPet.foodTypes, i )
				break
			end
		end
	else
		tinsert( Me.learnPet.foodTypes, self:GetName() )
	end
	
	local diet = "(None)"
	for i = 1, #Me.learnPet.foodTypes do
		if i == 1 then
			diet = Me.learnPet.foodTypes[i]
		elseif i == #Me.learnPet.foodTypes do
			diet = diet .. ", and " .. Me.learnPet.foodTypes[i]
		else
			diet = diet .. ", " .. Me.learnPet.foodTypes[i]
		end
	end
	UIDropDownMenu_SetText(DiceMasterPetEditor.petDiet, "Diet: " .. diet )
end

function Me.PetEditorDiet_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.text = "|cFFffd100Food Types"
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info)
	info.disabled = false;
	info.notClickable = false;
	for i = 1,#foodTypes do
		info.text = foodTypes[i];
		info.func = Me.PetEditorDiet_OnClick;
		info.notCheckable = false;
		info.tooltipTitle = foodTypes[i];
		info.tooltipText = "Allows this pet to consume " .. foodTypes[i]:lower() .. " items that have the 'Eat Food' action.";
		info.tooltipOnButton = true;
		info.checked = UIDropDownMenu_GetText(DiceMasterPetEditor.petDiet):find( info.text );
		UIDropDownMenu_AddButton(info, level)
	end
end

function Me.PetEditor_Refresh()
	local frame = DiceMasterPetEditor
	
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

local function LearnPet( data )
	if not data or not data.type or not data.item or not data.reagents or data.type ~= "pet" then
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
			UIErrorsFrame:AddMessage( "Already Known", 1.0, 0.0, 0.0, 53, 5 );
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
	
	local frame = DiceMasterPetEditor
	
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
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0, 53, 5 );
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
	
	local frame = DiceMasterPetEditor
	
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
		UIErrorsFrame:AddMessage( "Recipes must include at least one reagent.", 1.0, 0.0, 0.0, 53, 5 );
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
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0, 53, 5 );
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
	
	local frame = DiceMasterPetEditor
	
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
		UIErrorsFrame:AddMessage( "Recipes must include at least one reagent.", 1.0, 0.0, 0.0, 53, 5 );
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
	DiceMasterPetEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the message editor window.
--
function Me.PetEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterPetEditor:ClearAllPoints()
	DiceMasterPetEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterLearnRecipeEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnRecipeEditor_Save()
	end)
	
	Me.LearnRecipeEditor_Refresh()
	DiceMasterPetEditor:Show()
end
