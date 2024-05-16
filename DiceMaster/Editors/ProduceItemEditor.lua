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
	local item = Me.produceItem.item
	
	if not item then
		self:Disable()
		return
	end
	
	self:Enable()
	self:SetMinMaxValues(1, ( item.stackSize or 1 ) * 5 )
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
	
	Me.produceItem.item = item
	Me.produceItem.guid = item.guid
	
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
	if not data or not data.type or not data.item or not data.guid or not data.amount or data.type ~= "produce" then
		return
	end
	
	local item = data.item
	local stacks = Me.FindAllStacks( data.guid );
	
	if Me.FindTotalStacks( data.guid ) > 0 then
		Me.ProduceItem( data.guid, data.amount )
	else
		if item then
			Me.CreateItem( item, data.amount )
		else
			UIErrorsFrame:AddMessage( "Error producing item.", 1.0, 0.0, 0.0 );
			return
		end
	end
	
	item.amount = data.amount
	local msg = Me:Serialize( "ITEM", item );
	Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName("player"), "NORMAL" )
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
	Me.produceItem.item = effect.item
	Me.produceItem.guid = effect.guid or nil
	
	local item = effect.item
	-- find the item by the guid
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == Me.produceItem.guid then
			item = Me.Profile.inventory[i];
			break
		end
	end
	
	if not item then
		Me.ProduceItemEditor_Refresh()
		return
	end
	
	DiceMasterProduceItemEditor.Name:SetText( item.name or "" )
	DiceMasterProduceItemEditor.itemIcon:SetTexture( item.icon or "Interface/Icons/inv_misc_questionmark" )
	Me.ProduceItemEditorAmount_OnLoad( DiceMasterProduceItemEditor.amount )
	DiceMasterProduceItemEditor.itemCount:SetText( effect.amount or 1 )
	DiceMasterProduceItemEditor.delay:SetText( effect.delay or 0 )
	_G["DiceMasterProduceItemEditorAmountText"]:SetText("|cFFFFD100Amount: " .. effect.amount or 1 )
	
	DiceMasterProduceItemEditorSaveButton:SetScript( "OnClick", function()
		Me.ProduceItemEditor_SaveEdits()
	end)
end

function Me.ProduceItemEditor_SaveEdits()
	if not Me.produceItem.guid or not Me.EffectEditingIndex then
		return
	end
	
	local guid = Me.produceItem.guid
	local amount = tonumber( DiceMasterProduceItemEditor.itemCount:GetText() )
	local delay = tonumber( DiceMasterProduceItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local item
	-- find the item by the guid
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == Me.produceItem.guid then
			item = Me.Profile.inventory[i];
			break
		end
	end
	
	local produceData = {
		type = "produce";
		item = item;
		guid = guid;
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
	if not Me.produceItem.guid then
		UIErrorsFrame:AddMessage( "Invalid item.", 1.0, 0.0, 0.0 );
		return
	end
	
	local guid = Me.produceItem.guid
	local amount = tonumber( DiceMasterProduceItemEditor.itemCount:GetText() )
	local delay = tonumber( DiceMasterProduceItemEditor.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local item
	-- find the item by the guid
	for i = 1, 42 do
		if Me.Profile.inventory[i] and Me.Profile.inventory[i].guid == Me.produceItem.guid then
			item = Me.Profile.inventory[i];
			break
		end
	end
	
	local produceData = {
		type = "produce";
		item = item;
		guid = guid;
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
	DiceMasterProduceItemEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the message editor window.
--
function Me.ProduceItemEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
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
