-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Set Dice editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.SetDiceEditor_Refresh( effectIndex )
	local setdice
	if Me.setdiceeditor.parent and effectIndex then
		if Me.ItemEditing then
			setdice = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			setdice = Me.newItem.effects[ effectIndex ]
		end
		
		if setdice then
			DiceMasterSetDiceEditorSaveButton:SetScript( "OnClick", function()
				Me.SetDiceEditor_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		setdice = Profile.traits[Me.editing_trait].effects["setdice"] or nil
	end
	if not setdice then
		setdice = {
			value = "D20";
			skill = "";
			blank = true,
		}
		if not Me.setdiceeditor.parent then
			Profile.traits[Me.editing_trait].effects["setdice"] = dice
		end
	end
	Me.setdiceeditor.diceValue:SetText( setdice.value )
	Me.setdiceeditor.skillName:SetText( setdice.skill )
end

function Me.SetDiceEditor_Save()
	if not Me.FormatDiceString( Me.setdiceeditor.diceValue:GetText() ) then
		Me.setdiceeditor.diceValue:SetText("D20")
	end
	
	local setdice 
	if Me.setdiceeditor.parent then
		setdice = {
			type = "setdice";
			value = Me.setdiceeditor.diceValue:GetText();
			skill = Me.setdiceeditor.skillName:GetText();
			blank = false,
		}
	else
		setdice = {
			value = Me.setdiceeditor.diceValue:GetText();
			skill = Me.setdiceeditor.skillName:GetText();
			blank = false,
		}
	end
	if Me.setdiceeditor.parent then
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, setdice )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, setdice )
		end
		Me.ItemEditorEffectsList_Update()
	else
		Profile.traits[Me.editing_trait].effects["setdice"] = setdice
	end
end

function Me.SetDiceEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if not Me.FormatDiceString( Me.setdiceeditor.diceValue:GetText() ) then
		Me.setdiceeditor.diceValue:SetText("D20")
	end
	
	local setdice = {
		type = "setdice";
		value = Me.setdiceeditor.diceValue:GetText();
		skill = Me.setdiceeditor.skillName:GetText();
		blank = false,
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = setdice
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = setdice
	end
	
	Me.SetDiceEditor_OnCloseClicked()
	Me.ItemEditorEffectsList_Update()
end

function Me.SetDiceEditor_Delete()
	if not Me.setdiceeditor.parent then
		Profile.traits[Me.editing_trait].effects["setdice"] = nil
	end
	
	Me.setdiceeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.SetDiceEditor_OnCloseClicked()
	Me.RemoveBuffEditor_Refresh()
	Me.setdiceeditor.parent = nil
	Me.setdiceeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.SetDiceEditor_Open( parent )
	if parent then
		Me.CloseAllEditors( nil, nil, true )
		Me.setdiceeditor.parent = parent
		Me.setdiceeditor:SetPoint( "LEFT", parent, "RIGHT" )
		DiceMasterSetDiceEditorSaveButton:ClearAllPoints()
		DiceMasterSetDiceEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterSetDiceEditorDeleteButton:ClearAllPoints()
		DiceMasterSetDiceEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterSetDiceEditorDeleteButton:SetText( "Cancel" )
	else
		Me.CloseAllEditors()
		Me.setdiceeditor.parent = nil
		Me.setdiceeditor:SetPoint( "LEFT", DiceMasterTraitEditor, "RIGHT" )
		DiceMasterSetDiceEditorSaveButton:ClearAllPoints()
		DiceMasterSetDiceEditorSaveButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterSetDiceEditorDeleteButton:ClearAllPoints()
		DiceMasterSetDiceEditorDeleteButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterSetDiceEditorDeleteButton:SetText( "Delete" )
	end
	
	DiceMasterSetDiceEditorSaveButton:SetScript( "OnClick", function()
		Me.SetDiceEditor_Save()
		Me.SetDiceEditor_OnCloseClicked()
	end)
   
	Me.RemoveBuffEditor_Refresh()
	Me.setdiceeditor:Show()
end

-------------------------------------------------------------------------------
