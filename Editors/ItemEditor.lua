-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Item Editing Panel
--

local Me      = DiceMaster4
local Profile = Me.Profile

Me.newItem = {};
Me.newItem.effects = {};

local ITEM_QUALITIES = {
	"Poor",
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Artifact",
	"Heirloom",
}

local ITEM_STACK_SIZES = {
	1,
	5,
	10,
	20,
	100,
	200,
}

local ITEM_COOLDOWNS = {
	{name = "0 sec", time = 0},
	{name = "1 sec", time = 1},
	{name = "10 sec", time = 10},
	{name = "15 sec", time = 15},
	{name = "20 sec", time = 20},
	{name = "30 sec", time = 30},
	{name = "45 sec", time = 45},
	{name = "1 min", time = 60},
	{name = "2 min", time = 120},
	{name = "5 min", time = 300},
	{name = "10 min", time = 600},
	{name = "15 min", time = 900},
	{name = "20 min", time = 1200},
	{name = "30 min", time = 1800},
	{name = "45 min", time = 2700},
	{name = "1 hour", time = 3600},
	{name = "2 hours", time = 7200},
	{name = "3 hours", time = 10800},
	{name = "4 hours", time = 10800},
	{name = "5 hours", time = 18000},
	{name = "6 hours", time = 21600},
	{name = "12 hours", time = 43200},
	{name = "1 day", time = 86400},
}

local ITEM_BIND_TYPES = {
	"Binds when picked up",
	"Binds when equipped",
	"Binds when used",
}

local ITEM_PROPERTIES = {
	["Food Types"] = {
		"Meat",
		"Bread",
		"Fish",
		"Fruit",
		"Fungus",
		"Cheese",
	};
	["Other"] = {
		"Cosmetic",
		"Crafting Reagent",
	}
}

local function GetUnitGUID( unit )
	local guid = UnitGUID( unit )
	if not( guid ) then
		return;
	end
	if not( string.find( guid, "-" ) ) then
		return guid;
	end
	
	local guidType, realmID, unitID = strsplit( "-", guid );
	return unitID;
end;

local function GenerateGUID()
	local lastTime;
	local guid;
	
	if not (guid) then
		guid = string.gsub(string.gsub(GetUnitGUID("player"), "0x..", ""), "00[0]*", "")
	end

	local t = time();
	if t == 0 and not(lastTime) then
		t = random(100000);
	else
		t = t - 1315000000;
	end

	if lastTime and t <= lastTime then
		t = lastTime + 1;
	end
	lastTime = t;

	local hashTime = string.format("%X", t)
	
	return guid .. "_" .. hashTime;
end

local escapes = {
    ["|c%x%x%x%x%x%x%x%x"] = "", -- color start
    ["|r"] = "", -- color end
}
local function unescape(str)
    for k, v in pairs(escapes) do
        str = gsub(str, k, v)
    end
    return str
end

local function GetQualityIDFromName( qualityName )
	local quality = 1
	qualityName = unescape( qualityName )
	for i = 1, #ITEM_QUALITIES do
		if qualityName:find( ITEM_QUALITIES[i] ) then
			quality = i - 1
		end
	end
	return quality
end

function Me.ItemEditorNewAction_OnClick(self, arg1, arg2, checked)
	if arg1 then arg1( DiceMasterItemEditor ) end
end

function Me.ItemEditorNewAction_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	info.isNotRadio = true;
	info.notCheckable = true;
	info.func = Me.ItemEditorNewAction_OnClick;
	info.icon = "Interface/Icons/Spell_Holy_WordFortitude"
	info.text = "Apply Buff"
	info.arg1 = Me.BuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/Spell_Shadow_SacrificialShield"
	info.text = "Remove Buff"
	info.arg1 = Me.RemoveBuffEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_book_09"
	info.text = "Book"
	info.arg1 = Me.BookEditor_AddBook;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_drum_01"
	info.text = "Play Sound"
	info.arg1 = Me.SoundPicker_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/INV_Misc_Dice_01"
	info.text = "Roll Dice"
	info.arg1 = Me.SetDiceEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/spell_arcane_blast"
	info.text = "Visual Effect"
	info.arg1 = Me.EffectPicker_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/spell_nature_astralrecal"
	info.text = "Screen Effect"
	info.arg1 = Me.ScreenEffectEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/Spell_ChargePositive"
	info.text = "Produce Item"
	info.arg1 = Me.ProduceItemEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/Spell_ChargeNegative"
	info.text = "Consume Item"
	info.arg1 = Me.ConsumeItemEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/achievement_guildperk_cashflow_rank2"
	info.text = "Add/Remove Currency"
	info.arg1 = Me.ProduceCurrencyEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/petbattle_health"
	info.text = "Add/Remove Health"
	info.arg1 = Me.AdjustHealthEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_scroll_03"
	info.text = "Run Script"
	info.arg1 = Me.ScriptEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_note_04"
	info.text = "Send Message"
	info.arg1 = Me.MessageEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_note_02"
	info.text = "Learn Skill"
	info.arg1 = Me.LearnSkillEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_misc_note_01"
	info.text = "Learn Recipe"
	info.arg1 = Me.LearnRecipeEditor_Open;
	UIDropDownMenu_AddButton(info, level)
	info.icon = "Interface/Icons/inv_box_petcarrier_01"
	info.text = "Learn Pet"
	info.arg1 = Me.LearnPetEditor_Open;
	UIDropDownMenu_AddButton(info, level)
end

function Me.ItemEditorEffectsList_OnClick( self, button )
	if ( button == "LeftButton" ) then
		if DiceMasterItemEditor.selected and DiceMasterItemEditor.selected == self.effectIndex then
			DiceMasterItemEditor.selected = nil
		else
			DiceMasterItemEditor.selected = self.effectIndex
		end
		Me.ItemEditorEffectsList_Update()
	end
end

local EffectHandlers = {
	["script"]	= { "ScriptEditor_Open", "ScriptEditor_Refresh" };
	["message"]	=  { "MessageEditor_Open", "MessageEditor_Load" };
	["produce"]	= { "ProduceItemEditor_Open", "ProduceItemEditor_Load" };
	["consume"]	= { "ConsumeItemEditor_Open", "ConsumeItemEditor_Load" };
	["currency"] = { "ProduceCurrencyEditor_Open", "ProduceCurrencyEditor_Refresh" };
	["buff"] = { "BuffEditor_Open", "BuffEditor_Refresh" };
	["removebuff"] = { "RemoveBuffEditor_Open", "RemoveBuffEditor_Refresh" };
	["setdice"] = { "SetDiceEditor_Open", "SetDiceEditor_Refresh" };
	["effect"] = { "EffectPicker_Open", "EffectPicker_Refresh" };
	["screeneffect"] = { "ScreenEffectEditor_Open", "ScreenEffectEditor_Load" };
	["sound"] = { "SoundPicker_Open", "SoundPicker_Refresh" };
	["health"] = { "AdjustHealthEditor_Open", "AdjustHealthEditor_Load" };
	["skill"] = { "LearnSkillEditor_Open", "LearnSkillEditor_Refresh" };
	["skillsheet"] = { "LearnSkillSheetEditor_Open", "LearnSkillSheetEditor_Refresh" };
	["recipe"] = { "LearnRecipeEditor_Open", "LearnRecipeEditor_Load" };
	["pet"] = { "LearnPetEditor_Open", "LearnPetEditor_Load" };
}

function Me.ItemEditorEffects_Edit()
	if not DiceMasterItemEditor.selected then
		return
	end
	
	local effectType = nil
	if Me.ItemEditing then
		effectType = Me.ItemEditing.effects[ DiceMasterItemEditor.selected ].type
	elseif Me.newItem then
		effectType = Me.newItem.effects[ DiceMasterItemEditor.selected ].type
	end
	
	if effectType == "book" then
		return
	end
	
	local handlerOpen = EffectHandlers[ effectType ][1]
	local handlerLoad = EffectHandlers[ effectType ][2]
	if Me[handlerOpen] then
		Me[handlerOpen]( DiceMasterItemEditor )
	end
	if Me[handlerLoad] then
		Me[handlerLoad]( DiceMasterItemEditor.selected )
	end
end

function Me.ItemEditorEffects_Delete()
	if not DiceMasterItemEditor.selected then
		return
	end
	
	if Me.ItemEditing then
		tremove( Me.ItemEditing.effects, DiceMasterItemEditor.selected )
	elseif Me.newItem then
		tremove( Me.newItem.effects, DiceMasterItemEditor.selected )
	end
	
	Me.TraitEditor_UpdateInventory()
	Me.ItemEditorEffectsList_Update()
end

function Me.ItemEditorEffects_Sort( self, reversed, sortKey )
	local sort_func = function( a,b ) if not a then a = 0 end if not b then b = 0 end return tostring( a[sortKey] ) < tostring( b[sortKey] ) end
	if not reversed then
		self.reversed = true
	else
		sort_func = function( a,b ) if not a then a = 0 end if not b then b = 0 end return tostring( a[sortKey] ) > tostring( b[sortKey] ) end
		self.reversed = false
	end
	--table.sort( Me.SavedRolls, sort_func)
	DiceMasterItemEditor.selected = nil
	
	Me.ItemEditorEffectsList_Update()
end

function Me.ItemEditorEffectsList_OnLoad( self )
	
	for i = 2, 15 do
		local button = CreateFrame("Button", "DiceMasterItemEditorEffectButton"..i, DiceMasterItemEditor.Inset2, "DiceMasterItemEditorEffectButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterItemEditorEffectButton"..(i-1)], "BOTTOM");
	end

	Me.ItemEditorEffectsList_Update()
	
end

local DICEMASTER_ITEM_EFFECTS = {
	["buff"] = {
		name = "Apply Buff";
		icon = "Interface/Icons/spell_holy_wordfortitude";
		detail = "name";
	},
	["book"] = {
		name = "Book";
		icon = "Interface/Icons/inv_misc_book_09";
		detail = "title";
	},
	["currency"] = {
		name = "Add/Remove Currency";
		icon = "Interface/Icons/achievement_guildperk_cashflow_rank2";
		detail = "name";
	},
	["effect"] = {
		name = "Visual Effect";
		icon = "Interface/Icons/spell_arcane_blast";
		detail = "effectID"
	},
	["screeneffect"] = {
		name = "Screen Effect";
		icon = "Interface/Icons/spell_nature_astralrecal";
		detail = "texture"
	},
	["message"] = {
		name = "Send Message";
		icon = "Interface/Icons/inv_misc_note_04";
		detail = "message";
	},
	["produce"] = {
		name = "Produce Item";
		icon = "Interface/Icons/Spell_ChargePositive";
		detail = "item";
	},
	["consume"] = {
		name = "Consume Item";
		icon = "Interface/Icons/Spell_ChargeNegative";
		detail = "item";
	},
	["removebuff"] = {
		name = "Remove Buff";
		icon = "Interface/Icons/spell_shadow_sacrificialshield";
		detail = "name";
	},
	["script"] = {
		name = "Run Script";
		icon = "Interface/Icons/inv_scroll_03";
		detail = "code";
	},
	["sound"] = {
		name = "Play Sound";
		icon = "Interface/Icons/inv_misc_drum_01";
		detail = "soundPath";
	},
	["setdice"] = {
		name = "Roll Dice";
		icon = "Interface/Icons/inv_misc_dice_01";
		detail = "value";
	},
	["health"] = {
		name = "Add/Remove Health";
		icon = "Interface/Icons/petbattle_health";
		detail = "health";
	},
	["skill"] = {
		name = "Learn Skill";
		icon = "Interface/Icons/inv_misc_note_02";
		detail = "name";
	},
	["recipe"] = {
		name = "Learn Recipe";
		icon = "Interface/Icons/inv_misc_note_01";
		detail = "item";
	},
	["pet"] = {
		name = "Learn Pet";
		icon = "Interface/Icons/inv_box_petcarrier_01";
		detail = "name";
	},
}

function Me.ItemEditorEffectsList_Update()
	local effectTable = nil
	if Me.ItemEditingIndex then
		effectTable = Me.Profile.inventory[Me.ItemEditingIndex].effects or {}
	else
		effectTable = Me.newItem.effects or {}
	end
	
	local icon, name, details;
	local effectIndex;
	if #effectTable > 0 then
		DiceMasterItemEditorEffectTotals:Hide()
	else
		DiceMasterItemEditorEffectTotals:Show()
		DiceMasterItemEditorEffectTotals:SetText("No Actions")
		DiceMasterItemEditor.selected = nil
	end
	
	local effectOffset = FauxScrollFrame_GetOffset(DiceMasterItemEditor.actionsScrollFrame);
	
	for i=1,15,1 do
		effectIndex = effectOffset + i;
		local button = _G["DiceMasterItemEditorEffectButton"..i];
		button.effectIndex = effectIndex
		local info = effectTable[effectIndex];
		if ( info ) then
			icon		= DICEMASTER_ITEM_EFFECTS[ info.type ].icon;
			name		= DICEMASTER_ITEM_EFFECTS[ info.type ].name;
			details		= info[ DICEMASTER_ITEM_EFFECTS[ info.type ].detail ];
		end
		
		if type( details ) == "table" then
			details = details.name;
		end
		
		local buttonText = _G["DiceMasterItemEditorEffectButton"..i.."Icon"]
		buttonText:SetTexture( icon )
		local buttonText = _G["DiceMasterItemEditorEffectButton"..i.."Effect"]
		buttonText:SetText( name )
		local buttonText = _G["DiceMasterItemEditorEffectButton"..i.."Details"]
		buttonText:SetText( details )
		
		-- Highlight the correct who
		if ( DiceMasterItemEditor.selected == effectIndex ) then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end
		
		if ( effectIndex > #effectTable ) then
			button:Hide();
		else
			button:Show();
		end
		
	end
	
	FauxScrollFrame_Update(DiceMasterItemEditor.actionsScrollFrame, 15, 15, 15, nil, nil, nil, nil, nil, nil, true );
end

function Me.ItemEditorQuality_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(DiceMasterItemEditor.itemQuality, "|cFFFFD100Quality:|r " .. ITEM_QUALITY_COLORS[ arg1 ].hex .. self:GetText())
	DiceMasterItemEditorPreviewTooltipTextLeft1:SetTextColor( ITEM_QUALITY_COLORS[ arg1 ].r, ITEM_QUALITY_COLORS[ arg1 ].g, ITEM_QUALITY_COLORS[ arg1 ].b )
	Me.newItem.quality = arg1;
end

function Me.ItemEditorQuality_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for i=1, #ITEM_QUALITIES do	
		info.text = ITEM_QUALITY_COLORS[i - 1].hex .. ITEM_QUALITIES[i]
		info.arg1 = i - 1
		info.checked = UIDropDownMenu_GetText(DiceMasterItemEditor.itemQuality) == info.text;
		info.notCheckable = false;
		info.func = Me.ItemEditorQuality_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end
end

function Me.ItemEditorStackSize_OnLoad( self )
	self:SetMinMaxValues(1, #ITEM_STACK_SIZES)
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Stack Size: "..ITEM_STACK_SIZES[self:GetValue()])
	self.tooltipText = "Set the stack size for this item."
end

function Me.ItemEditorStackSize_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Stack Size: "..ITEM_STACK_SIZES[value])
	Me.newItem.stackSize = ITEM_STACK_SIZES[value];
end

function Me.ItemEditorCooldown_OnLoad( self )
	self:SetMinMaxValues(1, #ITEM_COOLDOWNS)
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Cooldown: "..ITEM_COOLDOWNS[self:GetValue()].name)
	self.tooltipText = "Set the cooldown time for this item."
end

function Me.ItemEditorCooldown_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Cooldown: "..ITEM_COOLDOWNS[value].name)
	Me.newItem.cooldown = ITEM_COOLDOWNS[value].time;
	
	local text = DiceMasterItemEditor.useText:GetText()
	if string.len(text)> 0 and DiceMasterItemEditor.cooldown:GetValue() > 1 then
		DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( Me.FormatItemTooltip(text).." ("..SecondsToTime(ITEM_COOLDOWNS[ DiceMasterItemEditor.cooldown:GetValue() ].time or 1).." Cooldown)" )
	else
		DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( Me.FormatItemTooltip(text) )
	end
end

function Me.ItemEditorProperties_OnClick(self, arg1, arg2, checked)
	local propertiesTable = {};
	if Me.ItemEditing then
		if not Me.ItemEditing.properties then
			Me.ItemEditing.properties = {}
		end
		if checked then
			Me.ItemEditing.properties[ arg2 ] = true;
		else
			Me.ItemEditing.properties[ arg2 ] = nil;
		end
		propertiesTable = Me.ItemEditing.properties;
	elseif Me.newItem then
		if not Me.newItem.properties then
			Me.newItem.properties = {}
		end
		if checked then
			Me.newItem.properties[ arg2 ] = true;
		else
			Me.newItem.properties[ arg2 ] = nil;
		end
		propertiesTable = Me.newItem.properties;
	end

	local text = DiceMasterItemEditor.whiteText1:GetText();
	if propertiesTable["Crafting Reagent"] then
		text = "|cFF66bbffCrafting Reagent|r|n" .. text;
	end
	if propertiesTable["Cosmetic"] then
		text = "|cFFff80ffCosmetic|r|n" .. text;
	end
	DiceMasterItemEditorPreviewTooltipTextLeft3:SetText( text );
	
	local propertiesList = nil
	local count = 0
	for k, v in pairs( propertiesTable ) do
		if k then
			count = count + 1
		end
		if count == 1 then
			propertiesList = k
		else
			propertiesList = propertiesList .. ", " .. k
		end
	end
	UIDropDownMenu_SetText( DiceMasterItemEditor.itemProperties, "|cFFFFD100Item Properties:|r ".. (propertiesList or "(None)") )
end

function Me.ItemEditorProperties_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	if level == 1 then
		for k, v in pairs( ITEM_PROPERTIES ) do	
			info.text = k;
			info.notCheckable = true;
			info.notClickable = false;
			info.hasArrow = true;
			info.menuList = k;
			UIDropDownMenu_AddButton(info, level)
		end
	elseif menuList then
		for i = 1, #ITEM_PROPERTIES[menuList] do
			info.text = ITEM_PROPERTIES[menuList][i];
			info.arg2 = ITEM_PROPERTIES[menuList][i];
			info.isNotRadio = true;
			info.hasArrow = false;
			info.menuList = nil;
			info.keepShownOnClick = true;
			info.checked = function()
				if Me.ItemEditing then
					if Me.ItemEditing.properties then
						if Me.ItemEditing.properties[ITEM_PROPERTIES[menuList][i]] then
							return true;
						end
					end
				elseif Me.newItem then
					if Me.newItem.properties then
						if Me.newItem.properties[ITEM_PROPERTIES[menuList][i]] then
							return true;
						end
					end
				end
				return false;
			end;
			info.notCheckable = false;
			info.func = Me.ItemEditorProperties_OnClick;
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

-------------------------------------------------------------------------------
-- Handler for when the name editor loses focus.
--
function Me.ItemEditor_SaveName()
	local text = DiceMasterItemEditor.itemName:GetText()
	DiceMasterItemEditorPreviewTooltipTextLeft1:SetText( text )
	Me.newItem.name = text;
end

-------------------------------------------------------------------------------
-- Set the texture of the currently edited item.
--
-- @param texture Path to texture file to use for the current item.
--
function Me.ItemEditor_SelectIcon( texture )
	local icon = texture or "Interface/Icons/inv_misc_questionmark"
	DiceMasterItemEditor.itemIcon:SetTexture( icon )
	Me.newItem.icon = icon;
end

-------------------------------------------------------------------------------
-- Handler for when the white text 1 editor loses focus.
--
function Me.ItemEditor_SaveWhiteText1()
	local text = DiceMasterItemEditor.whiteText1:GetText()
	DiceMasterItemEditorPreviewTooltipTextLeft3:SetText( text )
	Me.newItem.whiteText1 = text;
end

-------------------------------------------------------------------------------
-- Handler for when the white text 2 editor loses focus.
--
function Me.ItemEditor_SaveWhiteText2()
	local text = DiceMasterItemEditor.whiteText2:GetText()
	DiceMasterItemEditorPreviewTooltipTextRight3:SetText( text )
	Me.newItem.whiteText2 = text;
end

-------------------------------------------------------------------------------
-- Handler for when the use text editor loses focus.
--
function Me.ItemEditor_SaveUseText()
	local text = DiceMasterItemEditor.useText:GetText()
	if string.len(text)> 0 and DiceMasterItemEditor.cooldown:GetValue() > 1 then
		DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( Me.FormatItemTooltip(text).." ("..SecondsToTime(ITEM_COOLDOWNS[ DiceMasterItemEditor.cooldown:GetValue() ].time or 1).." Cooldown)" )
	else
		DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( Me.FormatItemTooltip(text) )
	end
	DiceMasterItemEditorPreviewTooltipTextLeft4:SetTextColor( 0, 1, 0 )
	Me.newItem.useText = text;
end

-------------------------------------------------------------------------------
-- Handler for when the flavour text editor loses focus.
--
function Me.ItemEditor_SaveFlavorText()
	local text = DiceMasterItemEditor.flavorText:GetText()
	if text and text~= "" then
		DiceMasterItemEditorPreviewTooltipTextLeft5:SetText( "\"" .. Me.FormatItemTooltip(text) .. "\"" )
	else
		DiceMasterItemEditorPreviewTooltipTextLeft5:SetText( "" )
	end
	DiceMasterItemEditorPreviewTooltipTextLeft5:SetTextColor( 1, 0.81, 0 )
	Me.newItem.flavorText = text;
end

-------------------------------------------------------------------------------
-- Handler for when the flavour text editor loses focus.
--
function Me.ItemEditor_SaveConsumeable()
	local consumeable = DiceMasterItemEditor.consumeable:GetChecked()
	Me.newItem.consumeable = consumeable;
end

-------------------------------------------------------------------------------
-- Handler for when the flavour text editor loses focus.
--
function Me.ItemEditor_SaveBinding()
	local itemBind = 0;
	if DiceMasterItemEditor.itemBind:GetChecked() then
		itemBind = 3;
	end
	if itemBind and itemBind > 0 then
		DiceMasterItemEditorPreviewTooltipTextLeft2:SetText( ITEM_BIND_TYPES[ itemBind ] )
	else
		DiceMasterItemEditorPreviewTooltipTextLeft2:SetText( nil )
	end
	Me.newItem.itemBind = itemBind;
end

-------------------------------------------------------------------------------
-- Save copyable.
--
function Me.ItemEditor_SaveCopyable()
	local copyable = DiceMasterItemEditor.copyable:GetChecked()
	Me.newItem.copyable = copyable;
end

-------------------------------------------------------------------------------
-- Save requires DM Approval.
--
function Me.ItemEditor_SaveRequiresDMApproval()
	local requiresDMApproval = DiceMasterItemEditor.requiresDMApproval:GetChecked()
	Me.newItem.requiresDMApproval = requiresDMApproval;
end

-------------------------------------------------------------------------------
-- Handler for when the flavour text editor loses focus.
--
function Me.ItemEditor_SaveDisenchantable()
	local canDisenchant = DiceMasterItemEditor.canDisenchant:GetChecked()
	Me.newItem.canDisenchant = canDisenchant;
end

-------------------------------------------------------------------------------
-- Handler for when the flavour text editor loses focus.
--
function Me.ItemEditor_CreateItem()
	
	if Me.FindTotalEmptySlots() < 1 then
		UIErrorsFrame:AddMessage( "Inventory is full.", 1.0, 0.0, 0.0 ); 
		return
	end
	
	local item = {
		name = Me.newItem.name or "Item";
		icon = Me.newItem.icon or "Interface/Icons/inv_misc_questionmark";
		quality = Me.newItem.quality or 1;
		itemBind = Me.newItem.itemBind or false;
		soulbound = false;
		whiteText1 = Me.newItem.whiteText1 or "";
		whiteText2 = Me.newItem.whiteText2 or "";
		useText = Me.newItem.useText or "";
		flavorText = Me.newItem.flavorText or nil;
		stackSize = Me.newItem.stackSize or 1;
		stackCount = Me.newItem.stackSize or 1;
		cooldown = Me.newItem.cooldown or 1;
		lastCastTime = 0;
		consumeable = Me.newItem.consumeable or false;
		copyable = Me.newItem.copyable or false;
		requiresDMApproval = Me.newItem.requiresDMApproval or false;
		canDisenchant = Me.newItem.canDisenchant or false;
		author = UnitName("player");
		guid = GenerateGUID();
		effects = Me.newItem.effects or {};
		properties = Me.newItem.properties or {};
	}
	
	tinsert( Me.Profile.inventory, item)
	item.amount = Me.newItem.stackSize or 1;
	local data = Me:Serialize( "ITEM", item );
	Me:SendCommMessage( "DCM4", data, "WHISPER", UnitName("player"), "NORMAL" )
	Me.TraitEditor_UpdateInventory()
	Me.ItemEditor_Close()
end

-------------------------------------------------------------------------------
-- Handler for when the flavour text editor loses focus.
--
function Me.ItemEditor_SaveItemEdits()

	if not Me.ItemEditing or not Me.ItemEditingIndex then
		return
	end

	local editor = DiceMasterItemEditor
	local item = {
		name = editor.itemName:GetText() or "Item";
		icon = editor.itemIcon.icon:GetTexture() or "Interface/Icons/inv_misc_questionmark";
		quality = GetQualityIDFromName( UIDropDownMenu_GetText(editor.itemQuality) ) or 1;
		itemBind = 0;
		soulbound = Me.ItemEditing.soulbound or false;
		whiteText1 = editor.whiteText1:GetText() or "";
		whiteText2 = editor.whiteText2:GetText() or "";
		useText = editor.useText:GetText() or "";
		flavorText = editor.flavorText:GetText() or "";
		stackSize = ITEM_STACK_SIZES[ editor.stackSize:GetValue() ] or 1;
		stackCount = Me.ItemEditing.stackCount or 1; -- don't change the stack count
		cooldown = ITEM_COOLDOWNS[ editor.cooldown:GetValue() ].time or 1;
		lastCastTime = Me.ItemEditing.lastCastTime; -- don't change the remaining cooldown time
		consumeable = editor.consumeable:GetChecked() or false;
		copyable = editor.copyable:GetChecked() or false;
		requiresDMApproval = editor.requiresDMApproval:GetChecked() or false;
		canDisenchant = editor.canDisenchant:GetChecked() or false;
		author = UnitName("player");
		guid = Me.ItemEditing.guid; -- we don't generate a new GUID since it's the same item
		effects = Me.ItemEditing.effects or {};
		properties = Me.ItemEditing.properties or {};
	}
	
	if editor.itemBind:GetChecked() then
		item.itemBind = 3
	else
		item.soulbound = false;
	end
	
	-- Reset the cooldown if we changed the cooldown
	if Me.ItemEditing.cooldown ~= ITEM_COOLDOWNS[ editor.cooldown:GetValue() ].time then
		item.lastCastTime = 0
	end
	
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == Me.ItemEditing.guid then
			for k, v in pairs( item ) do
				if Me.Profile.inventory[i][k] ~= item[k] and k~="stackCount" then
					Me.Profile.inventory[i][k] = item[k]
				end
			end
			if Me.Profile.inventory[i].stackCount > item.stackSize then
				Me.Profile.inventory[i].stackCount = item.stackSize
			end
		end
	end
	
	Me.TraitEditor_UpdateInventory()
	Me.ItemEditor_Close()
end

-------------------------------------------------------------------------------
-- Handler for when the flavour text editor loses focus.
--
function Me.ItemEditor_LoadEditItem( itemIndex )
	local item = Me.Profile.inventory[itemIndex]
	
	if not item then
		return
	end
	
	Me.ItemEditing = item
	Me.ItemEditingIndex = itemIndex
	
	local data = DiceMasterTraitEditorInventoryFrame["Item"..itemIndex]:GetItem();
	local editor = DiceMasterItemEditor
	
	editor.itemName:SetText( data.name or "" )
	editor.itemIcon:SetTexture( data.icon or "Interface/Icons/inv_misc_questionmark" )
	editor.whiteText1:SetText( data.whiteText1 or "" )
	editor.whiteText2:SetText( data.whiteText2 or "" )
	editor.useText:SetText( data.useText or "" )
	editor.flavorText:SetText( data.flavorText or "" )
	
	editor.consumeable:SetChecked( data.consumeable or false )
	
	if data.itemBind and data.itemBind == 3 then
		editor.itemBind:SetChecked( true )
	else
		editor.itemBind:SetChecked( false )
	end
	
	editor.copyable:SetChecked( data.copyable or false )
	editor.requiresDMApproval:SetChecked( data.requiresDMApproval or false )
	editor.canDisenchant:SetChecked( data.canDisenchant or false )
	
	-- set quality
	UIDropDownMenu_SetText(editor.itemQuality, "|cFFFFD100Quality:|r " .. ITEM_QUALITY_COLORS[ data.quality ].hex .. ITEM_QUALITIES[ data.quality + 1 ])
	DiceMasterItemEditorPreviewTooltipTextLeft1:SetTextColor( ITEM_QUALITY_COLORS[ data.quality ].r, ITEM_QUALITY_COLORS[ data.quality ].g, ITEM_QUALITY_COLORS[ data.quality ].b )
	
	-- set properties
	local propertiesList = nil
	local count = 0
	if data.properties then
		for k, v in pairs( data.properties ) do
			if k then
				count = count + 1
			end
			if count == 1 then
				propertiesList = k
			else
				propertiesList = propertiesList .. ", " .. k
			end
		end
	end
	UIDropDownMenu_SetText( DiceMasterItemEditor.itemProperties, "|cFFFFD100Item Properties:|r ".. (propertiesList or "(None)") );

	-- set stack size
	for i = 1, #ITEM_STACK_SIZES do
		if data.stackSize == ITEM_STACK_SIZES[i] then
			_G["DiceMasterItemEditorStackSizeText"]:SetText("|cFFFFD100Stack Size: "..ITEM_STACK_SIZES[ i ])
			editor.stackSize:SetValue( i )
			break
		end
	end
	
	-- set cooldown
	for i = 1, #ITEM_COOLDOWNS do
		if data.cooldown == ITEM_COOLDOWNS[i].time then
			_G["DiceMasterItemEditorCooldownText"]:SetText("|cFFFFD100Cooldown: "..ITEM_COOLDOWNS[ i ].name)
			editor.cooldown:SetValue( i )
			break
		end
	end
	
	DiceMasterItemEditorPreviewTooltipTextLeft1:SetText( data.name )
	local whiteText1 = data.whiteText1 or "";
	if data.properties and data.properties["Crafting Reagent"] then
		whiteText1 = "|cFF66bbffCrafting Reagent|r|n" .. whiteText1;
	end
	if data.properties and data.properties["Cosmetic"] then
		whiteText1 = "|cFFff80ffCosmetic|r|n" .. whiteText1;
	end
	DiceMasterItemEditorPreviewTooltipTextLeft3:SetText( whiteText1 );
	DiceMasterItemEditorPreviewTooltipTextRight3:SetText( data.whiteText2 or "" )
	if data.useText and string.len(data.useText)>0 then
		if data.cooldown and data.cooldown > 1 then
			DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( Me.FormatItemTooltip(data.useText).." ("..SecondsToTime(data.cooldown).." Cooldown)" )
		else
			DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( Me.FormatItemTooltip(data.useText) )
		end
	else
		DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( "" )
	end
	DiceMasterItemEditorPreviewTooltipTextLeft4:SetTextColor( 0, 1, 0 )
	if data.flavorText and string.len(data.flavorText)>0 then
		DiceMasterItemEditorPreviewTooltipTextLeft5:SetText( "\"" .. Me.FormatItemTooltip(data.flavorText) .. "\"" )
	else
		DiceMasterItemEditorPreviewTooltipTextLeft5:SetText( "" )
	end
	DiceMasterItemEditorPreviewTooltipTextLeft5:SetTextColor( 1, 0.81, 0 )
	if data.soulbound then
		DiceMasterItemEditorPreviewTooltipTextLeft2:SetText( "Soulbound" )
	elseif data.itemBind and data.itemBind == 3 then
		DiceMasterItemEditorPreviewTooltipTextLeft2:SetText( "Binds when used" )
	else
		DiceMasterItemEditorPreviewTooltipTextLeft2:SetText( nil )
	end
	
	DiceMasterItemEditor.createButton:Hide()
	DiceMasterItemEditor.saveEditsButton:Show()
	
	Me.ItemEditorEffectsList_Update()
end

function Me.ItemEditor_ClearAllFields()
	local editor = DiceMasterItemEditor
	
	editor.itemName:SetText( "" )
	editor.itemIcon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
	editor.whiteText1:SetText( "" )
	editor.whiteText2:SetText( "" )
	editor.useText:SetText( "" )
	editor.flavorText:SetText( "" )
	
	editor.consumeable:SetChecked( false )
	editor.itemBind:SetChecked( false )
	editor.copyable:SetChecked( false )
	editor.requiresDMApproval:SetChecked( false )
	editor.canDisenchant:SetChecked( false )
	
	UIDropDownMenu_SetText(editor.itemQuality, "|cFFFFD100Quality:|r " .. ITEM_QUALITY_COLORS[ 1 ].hex .. ITEM_QUALITIES[ 2 ])
	UIDropDownMenu_SetText( DiceMasterItemEditor.itemProperties, "|cFFFFD100Item Properties:|r (None)" )
	
	editor.stackSize:SetValue( 1 )
	editor.cooldown:SetValue( 1 )
	
	DiceMasterItemEditorPreviewTooltipTextLeft1:SetTextColor( 1, 1, 1 )
	DiceMasterItemEditorPreviewTooltipTextLeft1:SetText( nil )
	DiceMasterItemEditorPreviewTooltipTextLeft3:SetText( nil )
	DiceMasterItemEditorPreviewTooltipTextRight3:SetText( nil )
	DiceMasterItemEditorPreviewTooltipTextLeft4:SetText( nil )
	DiceMasterItemEditorPreviewTooltipTextLeft5:SetText( nil )
	DiceMasterItemEditorPreviewTooltipTextLeft2:SetText( nil )
	
	Me.ItemEditing = nil;
	Me.ItemEditingIndex = nil;
	
	Me.newItem = {}
	Me.newItem.effects = {}
	Me.ItemEditorEffectsList_Update()
end

-------------------------------------------------------------------------------
-- Close the item editor window. Use this instead of a direct Hide()
--
function Me.ItemEditor_Close()
	Me.ItemEditor_ClearAllFields()
	
	DiceMasterItemEditor.createButton:Show()
	DiceMasterItemEditor.saveEditsButton:Hide()
	
	DiceMasterItemEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the item editor window.
--
function Me.ItemEditor_Open( frame )
	Me.ModelPicker_Close()
	Me.SoundPicker_Close()
	Me.ShopEditor_Close()
	Me.CurrencyEditor_Close()
	Me.buffeditor:Hide()
	Me.removebuffeditor:Hide()
	Me.setdiceeditor:Hide()
	DiceMasterItemEditor:ClearAllPoints()
	DiceMasterItemEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterItemEditor.createButton:Show()
	DiceMasterItemEditor.saveEditsButton:Hide()
	
	if Me.PermittedUse() then
		DiceMasterItemEditor.canDisenchant:Show()
		DiceMasterItemEditor.canDisenchant:Enable()
	else
		DiceMasterItemEditor.canDisenchant:Hide()
		DiceMasterItemEditor.canDisenchant:Disable()
	end
	
	DiceMasterItemEditor:Show()
	Me.ItemEditorEffectsList_Update()
end

-- CURRENCY

StaticPopupDialogs["DICEMASTER4_DESTROYCUSTOMCURRENCY"] = {
  text = "Do you want to delete this currency?",
  button1 = "Accept",
  button2 = "Cancel",
  showAlert = true,
  OnShow = function( self, data )
	local currency = Me.Profile.currency[ data ].name
	local currencyIcon = "|T"..Me.Profile.currency[data].icon..":16|t"
	if Me.Profile.currency[ data ].author == UnitName("player") then
		self.text:SetText( "Do you want to delete " .. currencyIcon .. " [" .. currency .. "]?|n|nOther players that have earned this currency will keep any amount they have already earned, but you will be unable to create any more." )
	else
		self.text:SetText( "Do you want to delete " .. currencyIcon .. " [" .. currency .. "]?" )
	end
  end,
  OnAccept = function ( self, data )
	tremove( Me.Profile.currency, data )
	if data > 1 then
		Me.Profile.currencyActive = data - 1
	else
		Me.Profile.currencyActive = 1
	end
	Me.TraitEditor_UpdateInventory()
  end,
  OnCancel = function( self )
	PlaySound( 1203 )
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  exclusive = true,
}

-------------------------------------------------------------------------------
-- Set the texture of the currently edited currency.
--
-- @param texture Path to texture file to use for the current currency.
--
function Me.CurrencyEditor_SelectIcon( texture )
	local icon = texture or "Interface/Icons/inv_misc_questionmark"
	DiceMasterCurrencyEditor.currencyIcon:SetTexture( icon )
end

function Me.CurrencyEditor_CreateCurrency()
	local currency = {
		name = DiceMasterCurrencyEditor.currencyName:GetText() or ( "Currency "..(#Me.Profile.currency + 1) );
		icon = DiceMasterCurrencyEditor.currencyIcon.icon:GetTexture() or "Interface/Icons/inv_misc_questionmark";
		description = DiceMasterCurrencyEditor.currencyDesc.EditBox:GetText() or nil;
		value = 0;
		author = UnitName("player");
		guid = GenerateGUID();
	}
	
	tinsert( Me.Profile.currency, currency )
	Me.PrintMessage("|T".. currency.icon ..":16|t |cFFFFFFFF[".. currency.name .."]|r created.", "SYSTEM");
	Me.TraitEditor_UpdateInventory()
	Me.CurrencyEditor_Close()
end

function Me.CurrencyEditor_ClearAllFields()
	DiceMasterCurrencyEditor.currencyName:SetText( "" )
	DiceMasterCurrencyEditor.currencyIcon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
	DiceMasterCurrencyEditor.currencyDesc.EditBox:SetText( "" )
end

-------------------------------------------------------------------------------
-- Close the currency editor window. Use this instead of a direct Hide()
--
function Me.CurrencyEditor_Close()
	Me.CurrencyEditor_ClearAllFields()
	DiceMasterCurrencyEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the currency editor window.
--
function Me.CurrencyEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	DiceMasterCurrencyEditor:ClearAllPoints()
	DiceMasterCurrencyEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterCurrencyEditor:Show()
end