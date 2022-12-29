-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Produce Item editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

Me.produceCurrency = {}

-------------------------------------------------------------------------------
-- Remove Buff Editor
--

function Me.ProduceCurrencyEditor_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText( DiceMasterProduceCurrencyEditor.currencyName, "")
	if self:GetText() ~= "" then
		UIDropDownMenu_SetText( DiceMasterProduceCurrencyEditor.currencyName, self:GetText() )
		Me.produceCurrency.name = Me.Profile.currency[ arg1 ].name
		Me.produceCurrency.guid = Me.Profile.currency[ arg1 ].guid
		Me.produceCurrency.icon = Me.Profile.currency[ arg1 ].icon
		Me.produceCurrency.author = Me.Profile.currency[ arg1 ].author
	end
end

function Me.ProduceCurrencyEditor_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	local currencies = Me.Profile.currency
	
	for i = 1, #currencies do
		if currencies[i] and ( not currencies[i].author or currencies[i].author == UnitName("player") ) then
		   info.text       = "|T" .. currencies[i].icon .. ":16|t " .. currencies[i].name;
		   info.arg1	   = i;
		   info.isTitle	   = false;
		   info.func       = Me.ProduceCurrencyEditor_OnClick;
		   info.notCheckable = true
		   UIDropDownMenu_AddButton(info); 
		end
	end
	
	UIDropDownMenu_SetText(frame, "")
end

function Me.ProduceCurrencyEditor_ProduceCurrency( data )
	if not data or not data.type or not data.name or not data.count or not data.guid or data.type ~= "currency" then
		return
	end
	
	-- check if currency exists
	local currencies = Me.Profile.currency
	local found = false; 
	
	for i = 1, #currencies do
		if currencies[i] and currencies[i].guid == data.guid then
			Me.Profile.currency[i].value = tonumber( Me.Profile.currency[i].value ) + tonumber( data.count );
			if tonumber( Me.Profile.currency[i].value ) < 0 then
				Me.Profile.currency[i].value = 0
			end
			found = true;
			break
		end
	end
	
	if tonumber( data.count ) > 0 then
		if not found then
			local currency = {
				name = data.name;
				icon = data.icon;
				description = data.description;
				value = tonumber( data.count );
				author = data.author;
				guid = data.guid;
			}
			tinsert( Me.Profile.currency, currency )
		end
		
		if data.guid == 0 then
			Me.PrintMessage( "|cFFFFFF00You loot |cFFFFFFFF" .. data.count .. "|r|T" .. data.icon .. ":16|t.|r", "SYSTEM" )
		else
			Me.PrintMessage( "|cFF00aa00You receive currency: |cFFFFFFFF[" .. data.name .. "]|rx" .. data.count .. ".|r", "SYSTEM" )
		end
	end
	
	PlaySound(120)
	
	Me.TraitEditor_UpdateInventory()
end

function Me.ProduceCurrencyEditor_Refresh( effectIndex )
	local produceData
	if DiceMasterProduceCurrencyEditor.parent and effectIndex then
		if Me.ItemEditing then
			produceData = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			produceData = Me.newItem.effects[ effectIndex ]
		end
		
		if produceData then
			DiceMasterProduceCurrencyEditorSaveButton:SetScript( "OnClick", function()
				Me.ProduceCurrencyEditor_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	end
	if not produceData then
		produceData = {
			name = "",
			count = 1,
		}
	else
		Me.produceCurrency.guid = produceData.guid;
	end
	UIDropDownMenu_SetText( DiceMasterProduceCurrencyEditor.currencyName, produceData.name )
	DiceMasterProduceCurrencyEditor.currencyCount:SetText( produceData.count )
end

function Me.ProduceCurrencyEditor_Save()
	if not UIDropDownMenu_GetText( DiceMasterProduceCurrencyEditor.currencyName ) then
		UIErrorsFrame:AddMessage( "You must select a currency from the dropdown.", 1.0, 0.0, 0.0 );
		return
	end
	local produceData = {
		type = "currency";
		name = Me.produceCurrency.name;
		icon = Me.produceCurrency.icon;
		description = Me.produceCurrency.description;
		author = Me.produceCurrency.author;
		guid = Me.produceCurrency.guid;
		count = tonumber( DiceMasterProduceCurrencyEditor.currencyCount:GetText() );
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, produceData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, produceData )
	end
	
	Me.ItemEditorEffectsList_Update()
	Me.ProduceCurrencyEditor_OnCloseClicked()
end

function Me.ProduceCurrencyEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if not UIDropDownMenu_GetText( DiceMasterProduceCurrencyEditor.currencyName ) then
		UIErrorsFrame:AddMessage( "You must select a currency from the dropdown.", 1.0, 0.0, 0.0 );
		return
	end
	
	local produceData = {
		type = "currency";
		name = Me.produceCurrency.name;
		icon = Me.produceCurrency.icon;
		description = Me.produceCurrency.description;
		author = Me.produceCurrency.author;
		guid = Me.produceCurrency.guid;
		count = tonumber( DiceMasterProduceCurrencyEditor.currencyCount:GetText() );
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = produceData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = produceData
	end
	
	Me.ProduceCurrencyEditor_OnCloseClicked()
	Me.ItemEditorEffectsList_Update()
end

function Me.ProduceCurrencyEditor_OnCloseClicked()
	Me.ProduceCurrencyEditor_Refresh()
	DiceMasterProduceCurrencyEditorSaveButton:SetScript( "OnClick", function()
		Me.ProduceCurrencyEditor_Save()
	end)
	DiceMasterProduceCurrencyEditor:Hide()
end

function Me.ProduceCurrencyEditor_Open( parent )
	Me.CloseAllEditors( nil, nil, true )
	if parent then
		DiceMasterProduceCurrencyEditor.parent = parent
		DiceMasterProduceCurrencyEditor:ClearAllPoints()
		DiceMasterProduceCurrencyEditor:SetPoint( "LEFT", parent, "RIGHT" )
	else
		DiceMasterProduceCurrencyEditor.parent = nil
	end
	
	DiceMasterProduceCurrencyEditorSaveButton:SetScript( "OnClick", function()
		Me.ProduceCurrencyEditor_Save()
	end)
   
	Me.ProduceCurrencyEditor_Refresh()
	DiceMasterProduceCurrencyEditor:Show()
end

-------------------------------------------------------------------------------
