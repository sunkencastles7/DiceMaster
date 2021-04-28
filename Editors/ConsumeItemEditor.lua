-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Consume Item editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

Me.consumeItem = {}

local FindAllStacks = function( guid )
	local t = {}
	for i = 1, #Me.Profile.inventory do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == guid then
			tinsert( t, i );
		end
	end
	return t;
end

function Me.ConsumeItemEditorAmount_OnLoad( self )
	local item = Me.consumeItem
	
	if not item then
		self:Disable()
		return
	end
	
	self:Enable()
	self:SetMinMaxValues(1, item.stackSize or 1)
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
	Me.consumeItem.stackCount = value;
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
	
	Me.consumeItem = item
	Me.consumeItem.itemIndex = itemIndex
	
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
	if not data or not data.type or not data.itemData or not data.amount or data.type ~= "consume" then
		return
	end
	
	local item = data.itemData
	local amount = data.amount
	
	local stacks = FindAllStacks( item.guid );
	for k,v in pairs( stacks ) do
		local deltaAmount = math.min( amount, Me.Profile.inventory[ v ].stackCount )
		Me.Profile.inventory[ v ].stackCount = Me.Profile.inventory[ v ].stackCount - deltaAmount
		if Me.Profile.inventory[ v ].stackCount == 0 then
			Me.Profile.inventory[ v ] = nil;
		end
		amount = amount - deltaAmount;
		if amount <= 0 then
			break;
		end
	end
	
	Me.TraitEditor_UpdateInventory()
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
	
	local itemData = effect.itemData
	Me.consumeItem = itemData
	Me.consumeItem.itemIndex = effect.itemIndex
	
	DiceMasterConsumeItemEditor.Name:SetText( itemData.name or "" )
	DiceMasterConsumeItemEditor.itemIcon:SetTexture( itemData.icon or "Interface/Icons/inv_misc_questionmark" )
	DiceMasterConsumeItemEditor.itemCount:SetText( effect.amount )
	DiceMasterConsumeItemEditor.delay:SetText( effect.delay )
	_G["DiceMasterConsumeItemEditorAmountText"]:SetText("|cFFFFD100Amount: " .. effect.amount )
	Me.ConsumeItemEditorAmount_OnLoad( DiceMasterConsumeItemEditor.amount )
	
	DiceMasterConsumeItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ConsumeItemEditor_SaveEdits()
	end)
end

function Me.ConsumeItemEditor_SaveEdits()
	if not Me.ItemEditingIndex or not Me.consumeItem.itemIndex or not Me.EffectEditingIndex then
		return
	end
	
	local itemData = Me.consumeItem;
	
	if not itemData then
		return
	end
	
	local itemIndex = Me.consumeItem.itemIndex
	local amount = tonumber( DiceMasterConsumeItemEditor.itemCount:GetText() )
	local delay = tonumber( DiceMasterConsumeItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local consumeData = {
		type = "consume";
		itemData = itemData;
		itemIndex = itemIndex;
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
	if not Me.ItemEditingIndex or not Me.consumeItem.itemIndex then
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	local itemData = DiceMasterTraitEditorInventoryFrame["Item"..Me.consumeItem.itemIndex]:GetItem();
	
	if not itemData then
		return
	end
	
	local itemIndex = Me.consumeItem.itemIndex
	local amount = tonumber( DiceMasterConsumeItemEditor.itemCount:GetText() )
	local delay = tonumber( DiceMasterConsumeItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local consumeData = {
		type = "consume";
		itemData = itemData;
		itemIndex = itemIndex;
		amount = amount;
		delay = delay;
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, consumeData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, consumeData )
	end
	
	--tinsert( Me.Profile.inventory[Me.ItemEditingIndex].effects, scriptData )
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
