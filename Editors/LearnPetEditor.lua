-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Learn pet editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local foodTypes = { "Bread", "Cheese", "Fish", "Fruit", "Fungus", "Meat" };

Me.learnPet = {
	["1"] = {};
	["2"] = {};
	["3"] = {};
}

function Me.LearnPetEditorDiet_OnClick(self, arg1, arg2, checked)
	if not Me.learnPet[arg1].foodTypes then
		Me.learnPet[arg1].foodTypes = {}
	end
	
	for i = 1, #Me.learnPet[arg1].foodTypes do
		if Me.learnPet[arg1].foodTypes[i] == arg2 then
			tremove( Me.learnPet[arg1].foodTypes, i )
			break
		end
	end
	if checked then
		tinsert( Me.learnPet[arg1].foodTypes, arg2 )
	end
	
	local diet = "(None)"
	for i = 1, #Me.learnPet[arg1].foodTypes do
		if i == 1 then
			diet = Me.learnPet[arg1].foodTypes[i];
		elseif i == #Me.learnPet[arg1].foodTypes then
			diet = diet .. ", and " .. Me.learnPet[arg1].foodTypes[i];
		else
			diet = diet .. ", " .. Me.learnPet[arg1].foodTypes[i];
		end
	end
	_G["DiceMasterLearnPetEditorInset"..arg1.."PetDietText"]:SetText("|cFFFFD100Diet:|r " .. diet );
end

function Me.LearnPetEditorDiet_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.text = "|cFFffd100Food Types"
	info.notClickable = true;
	info.notCheckable = true;
	UIDropDownMenu_AddButton(info)
	info.disabled = false;
	info.notClickable = false;
	for i = 1,#foodTypes do
		info.text = foodTypes[i];
		info.arg1 = frame:GetParent().stage;
		info.arg2 = foodTypes[i];
		info.func = Me.LearnPetEditorDiet_OnClick;
		info.notCheckable = false;
		info.isNotRadio = true;
		info.keepShownOnClick = true;
		info.tooltipTitle = foodTypes[i];
		info.tooltipText = "Allows this pet to consume " .. foodTypes[i]:lower() .. " items.";
		info.tooltipOnButton = true;
		info.checked = UIDropDownMenu_GetText(frame) and UIDropDownMenu_GetText(frame):find( info.text );
		UIDropDownMenu_AddButton(info, level)
	end
end

function Me.LearnPetEditor_Refresh()
	-- Reset each stage
	for i = 1, 3 do
		_G["DiceMasterLearnPetEditorInset"..i]:DesaturateHierarchy(0);
		_G["DiceMasterLearnPetEditorInset"..i]["ModelScene"]:GetActorAtIndex(1):SetModelByCreatureDisplayID(31);
		_G["DiceMasterLearnPetEditorInset"..i]["ModelScene"]:GetActorAtIndex(1):SetScale(0.2);
		_G["DiceMasterLearnPetEditorInset"..i]["ModelScene"]["decreaseScale"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i]["ModelScene"]["increaseScale"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i]["ModelScene"]["selectModel"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i.."PetEnable"]:SetChecked( true );
		_G["DiceMasterLearnPetEditorInset"..i.."PetEnable"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i.."PetName"]:SetText("");
		_G["DiceMasterLearnPetEditorInset"..i.."PetName"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i.."PetIcon"]:SetTexture("Interface/Icons/inv_misc_questionmark");
		_G["DiceMasterLearnPetEditorInset"..i.."PetIcon"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i.."PetDietText"]:SetText("|cFFFFD100Diet:|r (None)");
		_G["DiceMasterLearnPetEditorInset"..i.."PetDietButton"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i.."PetRequireWash"]:SetChecked( true );
		_G["DiceMasterLearnPetEditorInset"..i.."PetRequireWash"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i.."PetRequireCleanUp"]:SetChecked( true );
		_G["DiceMasterLearnPetEditorInset"..i.."PetRequireCleanUp"]:Enable();
		_G["DiceMasterLearnPetEditorInset"..i.."PetRequireRest"]:SetChecked( true );
		_G["DiceMasterLearnPetEditorInset"..i.."PetRequireRest"]:Enable();
	end

	-- Reset both timers
	DiceMasterLearnPetEditorTimerOne.Cooldown.Duration = 0;
	DiceMasterLearnPetEditorTimerOne.Cooldown:SetCooldownUNIX(time()-864000, 864000);
	DiceMasterLearnPetEditorTimerOne.Cooldown:Pause();
	DiceMasterLearnPetEditorTimerOne.Text:SetText("10 d");
	DiceMasterLearnPetEditorTimerTwo.Cooldown.Duration = 0;
	DiceMasterLearnPetEditorTimerTwo.Cooldown:SetCooldownUNIX(time()-864000, 864000);
	DiceMasterLearnPetEditorTimerTwo.Cooldown:Pause();
	DiceMasterLearnPetEditorTimerTwo.Text:SetText("10 d");
	
	Me.learnPet = {}
	Me.EffectEditingIndex = nil;
end

local function LearnPet( data )
	if not data or not data.type or data.type ~= "pet" then
		return
	end
	
	-- Sanitise the data.

	local stage = data.currentStage or 1;
	local name = tostring( data.stages[stage].name );
	local type = tostring( data.stages[stage].type );
	local icon = tostring( data.stages[stage].icon );
	local model = tonumber( data.stages[stage].model );
	local scale = tonumber( data.stages[stage].scale );
	local health = tonumber( data.stages[stage].health );
	local healthMax = tonumber( data.stages[stage].healthMax );
	local armor = tonumber( data.stages[stage].armor );
	local happiness = tonumber( data.stages[stage].happiness );
	local foodTypes = {};
	for i = 1, #data.stages[stage].foodTypes do
		tinsert( foodTypes, data.stages[stage].foodTypes[i] );
	end

	Profile.pet.isComplex = true;
	Profile.pet.name = name;
	Profile.pet.type = type;
	Profile.pet.icon = icon;
	Profile.pet.model = model;
	Profile.pet.scale = scale;
	Profile.pet.health = health;
	Profile.pet.healthMax = healthMax;
	Profile.pet.armor = armor;
	Profile.pet.happiness = happiness;
	Profile.pet.foodTypes = foodTypes;
	
	if data.isEgg then
		local lastWarmed = tonumber( data.stages[stage].lastWarmed );

		Profile.pet.isEgg = true;
		Profile.pet.lastWarmed = lastWarmed;
	else
		local lastWash = tonumber( data.stages[stage].lastWash );
		local lastFed = tonumber( data.stages[stage].lastFed );
		local lastBM = tonumber( data.stages[stage].lastBM );
		local lastNap = tonumber( data.stages[stage].lastNap );

		Profile.pet.isEgg = false;
		Profile.pet.lastWash = lastWash;
		Profile.pet.lastFed = lastFed;
		Profile.pet.lastBM = lastBM;
		Profile.pet.lastNap = lastNap;
	end

	Me.PetEditor_Refresh();
end

function Me.LearnPetEditor_Load( effectIndex )
	
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

	-- TODO
	
	DiceMasterLearnPetEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnPetEditor_SaveEdits()
	end)
end

function Me.LearnPetEditor_SaveEdits()
	local petData = {
	};

	-- TODO
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = petData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = petData
	end
	
	Me.LearnPetEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.LearnPetEditor_Save()
	local frame = DiceMasterLearnPetEditor
	
	local name = frame["Inset"..i].petName:GetText();
	local icon = frame["Inset"..i].petIcon:GetTexture();
	local model = frame["Inset"..i].petIcon:GetTexture();
	
	-- TODO
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, petData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, petData )
	end
	
	Me.LearnPetEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the message editor window. Use this instead of a direct Hide()
--
function Me.LearnPetEditor_Close()
	Me.LearnPetEditor_Refresh()
	DiceMasterLearnPetEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnPetEditor_Save()
	end)
	DiceMasterLearnPetEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the message editor window.
--
function Me.LearnPetEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterLearnPetEditor:ClearAllPoints()
	DiceMasterLearnPetEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterLearnRecipeEditorSaveButton:SetScript( "OnClick", function()
		Me.LearnPetEditor_Save()
	end)
	
	Me.LearnPetEditor_Refresh()
	DiceMasterLearnPetEditor:Show()
end
