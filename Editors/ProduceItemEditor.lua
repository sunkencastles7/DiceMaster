-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Produce Item editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

Me.produceItem = {}

function Me.ProduceItemEditorAmount_OnLoad( self )
	local item = Me.produceItem
	
	if not item then
		self:Disable()
		return
	end
	
	self:Enable()
	self:SetMinMaxValues(1, item.stackSize)
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Amount: "..self:GetValue())
	self.tooltipText = "Set the amount of this item produced."
	DiceMasterProduceItemEditor.itemCount:SetText( self:GetValue() )
end

function Me.ProduceItemEditorAmount_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("|cFFFFD100Amount: "..value)
	Me.produceItem.stackCount = value;
	DiceMasterProduceItemEditor.itemCount:SetText( value )
end

function Me.ProduceItemEditor_ChooseItem()
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

function Me.ProduceItemEditor_LoadItem( itemIndex )
	local item = Me.Profile.inventory[itemIndex]
	
	if not item then
		return
	end
	
	local data = DiceMasterTraitEditorInventoryFrame["Item"..itemIndex]:GetItem();
	local editor = DiceMasterProduceItemEditor
	
	Me.ProduceItemEditorAmount_OnLoad( editor.amount )
	
	editor.Name:SetText( data.name or "" )
	editor.itemIcon:SetTexture( data.icon or "Interface/Icons/inv_misc_questionmark" )
end

function Me.ProduceItemEditor_Refresh()
	DiceMasterProduceItemEditor.Name:SetText("")
	DiceMasterProduceItemEditor.itemIcon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
	DiceMasterProduceItemEditor.itemCount:SetText("")
	DiceMasterProduceItemEditor.delay:SetText("")
	_G["DiceMasterProduceItemEditorAmountText"]:SetText("|cFFFFD100Amount: 1")
	DiceMasterProduceItemEditor.amount:SetValue( 1 )
	DiceMasterProduceItemEditor.amount:Disable()
	
	Me.produceItem = {}
	Me.EffectEditingIndex = nil;
end

function Me.ProduceItemEditor_ProduceItem( data )
	if not data or not data.type or not data.itemData or not data.amount or data.type ~= "produce" then
		return
	end
	
	local item = data.itemData
	item.stackCount = data.amount
	
	tinsert( Me.Profile.inventory, item )
	
	local msg = Me:Serialize( "ITEM", item );
	Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName("player"), "ALERT" )
	Me.TraitEditor_UpdateInventory()
end

function Me.ProduceItemEditor_Load( effectIndex )
	
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
	Me.produceItem = itemData
	Me.produceItem.itemIndex = effect.itemIndex
	
	DiceMasterProduceItemEditor.Name:SetText( itemData.name or "" )
	DiceMasterProduceItemEditor.itemIcon:SetTexture( itemData.icon or "Interface/Icons/inv_misc_questionmark" )
	DiceMasterProduceItemEditor.itemCount:SetText( effect.amount )
	DiceMasterProduceItemEditor.delay:SetText( effect.delay )
	_G["DiceMasterProduceItemEditorAmountText"]:SetText("|cFFFFD100Amount: " .. effect.amount )
	Me.ProduceItemEditorAmount_OnLoad( DiceMasterProduceItemEditor.amount )
	
	DiceMasterProduceItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ProduceItemEditor_SaveEdits()
	end)
end

function Me.ProduceItemEditor_SaveEdits()
	if not Me.ItemEditingIndex or not Me.produceItem.itemIndex or not Me.EffectEditingIndex then
		return
	end
	
	local itemData = Me.produceItem;
	
	if not itemData then
		return
	end
	
	local itemIndex = Me.produceItem.itemIndex
	local amount = Me.produceItem.stackSize
	local delay = tonumber( DiceMasterProduceItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local produceData = {
		type = "produce";
		itemData = itemData;
		itemIndex = itemIndex;
		amount = amount;
		delay = delay;
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = produceData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = produceData
	end
	
	Me.ProduceItemEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.ProduceItemEditor_Save()
	if not Me.ItemEditingIndex or not Me.produceItem.itemIndex then
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	local itemData = DiceMasterTraitEditorInventoryFrame["Item"..Me.produceItem.itemIndex]:GetItem();
	
	if not itemData then
		return
	end
	
	local itemIndex = Me.produceItem.itemIndex
	local amount = Me.produceItem.stackSize
	local delay = tonumber( DiceMasterProduceItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local produceData = {
		type = "produce";
		itemData = itemData;
		itemIndex = itemIndex;
		amount = amount;
		delay = delay;
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, produceData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, produceData )
	end
	
	--tinsert( Me.Profile.inventory[Me.ItemEditingIndex].effects, scriptData )
	Me.ProduceItemEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the message editor window. Use this instead of a direct Hide()
--
function Me.ProduceItemEditor_Close()
	Me.ProduceItemEditor_Refresh()
	DiceMasterProduceItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ProduceItemEditor_Save()
	end)
	PlaySound(840);
	DiceMasterProduceItemEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the message editor window.
--
function Me.ProduceItemEditor_Open( frame )
	Me.EffectPicker_Close()
	Me.SoundPicker_Close()
	Me.AnimationPicker_Close()
	Me.ShopEditor_Close()
	Me.ScriptEditor_Close()
	Me.MessageEditor_Close()
	--Me.ItemEditor_Close()
	Me.ModelPicker_Close()
	Me.CurrencyEditor_Close()
	Me.buffeditor:Hide()
	Me.removebuffeditor:Hide()
	Me.setdiceeditor:Hide()
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterProduceItemEditor:ClearAllPoints()
	DiceMasterProduceItemEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterProduceItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ProduceItemEditor_Save()
	end)
	
	Me.ProduceItemEditor_Refresh()
	DiceMasterProduceItemEditor:Show()
end
