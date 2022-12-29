-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Consume Item editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

Me.consumeItem = {}

local GetItemName = function( guid )
	local name = "Unknown Item"
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			local name = Me.Profile.inventory[i].name
			return name;
		end
	end
	return name;
end

function Me.ConsumeItemEditorAmount_OnLoad( self )
	local guid = Me.consumeItem.guid
	local totalAmount = Me.FindTotalStacks( guid )
	
	if not guid then
		self:Disable()
		return
	end
	
	self:Enable()
	self:SetMinMaxValues(1, math.max( totalAmount, 1 ) )
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Amount: "..self:GetValue())
	self.tooltipText = "Set the amount of this item consumed."
	DiceMasterConsumeItemEditor.itemCount:SetText( self:GetValue() )
end

function Me.ConsumeItemEditorAmount_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Amount: "..value)
	DiceMasterConsumeItemEditor.itemCount:SetText( value )
end

function Me.ConsumeItemEditor_ChooseItem()
	local cursorIcon = DiceMasterCursorItemIcon
	
	if cursorIcon.itemID then
		-- previous slot
		cursorIcon.prevButton:Update()
		SetItemButtonDesaturated( cursorIcon.prevButton, false );
	end
	
	Me.ClearCursorActions( true, true, false )
	DiceMasterCursorOverlay:Show()
	cursorIcon.chooseCursor = true;
	SetCursor( "CAST_CURSOR" )
end

function Me.ConsumeItemEditor_LoadItem( itemIndex )
	
	local item = Me.Profile.inventory[itemIndex]
	
	if not item then
		return
	end
	
	Me.consumeItem.item = item
	Me.consumeItem.guid = item.guid
	
	local data = DiceMasterTraitEditorInventoryFrame["Item"..itemIndex]:GetItem();
	local editor = DiceMasterConsumeItemEditor
	
	Me.ConsumeItemEditorAmount_OnLoad( editor.amount )
	
	editor.Name:SetText( data.name or "" )
	editor.itemIcon:SetTexture( data.icon or "Interface/Icons/inv_misc_questionmark" )
end

function Me.ConsumeItemEditor_Refresh()
	DiceMasterConsumeItemEditor.Name:SetText("")
	DiceMasterConsumeItemEditor.itemIcon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
	DiceMasterConsumeItemEditor.itemCount:SetText("")
	DiceMasterConsumeItemEditor.delay:SetText("")
	_G["DiceMasterConsumeItemEditorAmountText"]:SetText("|cFFFFD100Amount: 1")
	DiceMasterConsumeItemEditor.amount:SetValue( 1 )
	DiceMasterConsumeItemEditor.amount:Disable()
	
	Me.consumeItem = {}
	Me.EffectEditingIndex = nil;
end

function Me.ConsumeItemEditor_ConsumeItem( data )
	if not data or not data.type or not data.guid or not data.amount or data.type ~= "consume" then
		return
	end
	
	local stacks = Me.FindAllStacks( data.guid );
	
	Me.ConsumeItem( data.guid, data.amount )
end

function Me.ConsumeItemEditor_Load( effectIndex )
	
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
	Me.consumeItem.item = effect.item
	Me.consumeItem.guid = effect.guid or nil
	
	local item
	-- find the item by the guid
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == Me.consumeItem.guid then
			item = Me.Profile.inventory[i];
			break
		end
	end
	
	if not item then
		Me.ConsumeItemEditor_Refresh()
		return
	end
	
	DiceMasterConsumeItemEditor.Name:SetText( item.name or "" )
	DiceMasterConsumeItemEditor.itemIcon:SetTexture( item.icon or "Interface/Icons/inv_misc_questionmark" )
	Me.ConsumeItemEditorAmount_OnLoad( DiceMasterConsumeItemEditor.amount )
	DiceMasterConsumeItemEditor.itemCount:SetText( effect.amount or 1 )
	DiceMasterConsumeItemEditor.delay:SetText( effect.delay or 0 )
	_G["DiceMasterConsumeItemEditorAmountText"]:SetText("|cFFFFD100Amount: " .. effect.amount or 0 )
	
	DiceMasterConsumeItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ConsumeItemEditor_SaveEdits()
	end)
end

function Me.ConsumeItemEditor_SaveEdits()
	if not Me.consumeItem.guid or not Me.EffectEditingIndex then
		return
	end
	
	local guid = Me.consumeItem.guid
	local amount = tonumber( DiceMasterConsumeItemEditor.itemCount:GetText() )
	local delay = tonumber( DiceMasterConsumeItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local item
	-- find the item by the guid
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == Me.consumeItem.guid then
			item = Me.Profile.inventory[i];
			break
		end
	end
	
	local consumeData = {
		type = "consume";
		item = item;
		guid = guid;
		amount = amount;
		delay = delay;
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = consumeData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = consumeData
	end
	
	Me.ConsumeItemEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.ConsumeItemEditor_Save()
	if not Me.consumeItem.guid then
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0 );
		return
	end
	
	local guid = Me.consumeItem.guid
	local amount = tonumber( DiceMasterConsumeItemEditor.itemCount:GetText() )
	local delay = tonumber( DiceMasterConsumeItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local item
	-- find the item by the guid
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == Me.consumeItem.guid then
			item = Me.Profile.inventory[i];
			break
		end
	end
	
	local consumeData = {
		type = "consume";
		item = item;
		guid = guid;
		amount = amount;
		delay = delay;
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, consumeData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, consumeData )
	end
	
	Me.ConsumeItemEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the message editor window. Use this instead of a direct Hide()
--
function Me.ConsumeItemEditor_Close()
	Me.ConsumeItemEditor_Refresh()
	DiceMasterConsumeItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ConsumeItemEditor_Save()
	end)
	DiceMasterConsumeItemEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the message editor window.
--
function Me.ConsumeItemEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterConsumeItemEditor:ClearAllPoints()
	DiceMasterConsumeItemEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterConsumeItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ConsumeItemEditor_Save()
	end)
	
	Me.ConsumeItemEditor_Refresh()
	DiceMasterConsumeItemEditor:Show()
end
