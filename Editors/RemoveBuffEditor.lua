-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Remove Buff editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.RemoveBuffEditor_Refresh( effectIndex )
	local removebuff
	if Me.removebuffeditor.parent and effectIndex then
		if Me.ItemEditing then
			removebuff = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			removebuff = Me.newItem.effects[ effectIndex ]
		end
		
		if removebuff then
			DiceMasterRemoveBuffEditorSaveButton:SetScript( "OnClick", function()
				Me.RemoveBuffEditor_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		removebuff = Profile.traits[Me.editing_trait]["effects"]["removebuff"] or nil
	end
	if not removebuff then
		removebuff = {
			name = "",
			count = 1,
		}
		if not Me.removebuffeditor.parent then
			Profile.traits[Me.editing_trait]["effects"]["removebuff"] = removebuff
		end
	end
	Me.removebuffeditor.buffName:SetText( removebuff.name )
	Me.removebuffeditor.buffCount:SetText( removebuff.count )
end

function Me.RemoveBuffEditor_Save()
	if Me.removebuffeditor.buffName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	local removebuff 
	if Me.removebuffeditor.parent then
		removebuff = {
			type = "removebuff";
			name = Me.removebuffeditor.buffName:GetText();
			count = Me.removebuffeditor.buffCount:GetText();
		}
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, removebuff )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, removebuff )
		end
		Me.ItemEditorEffectsList_Update()
	else
		removebuff = {
			name = Me.removebuffeditor.buffName:GetText();
			count = Me.removebuffeditor.buffCount:GetText();
		}
		Profile.traits[Me.editing_trait]["effects"]["removebuff"] = removebuff
	end
	Me.RemoveBuffEditor_OnCloseClicked()
end

function Me.RemoveBuffEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if Me.removebuffeditor.buffName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	local removebuff = {
		type = "removebuff";
		name = Me.removebuffeditor.buffName:GetText();
		count = Me.removebuffeditor.buffCount:GetText();
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = removebuff
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = removebuff
	end
	
	Me.RemoveBuffEditor_OnCloseClicked()
	Me.ItemEditorEffectsList_Update()
end

function Me.RemoveBuffEditor_DeleteBuff()
	if not Me.removebuffeditor.parent then
		Profile.traits[Me.editing_trait]["effects"]["removebuff"] = nil
	end
	
	Me.removebuffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.RemoveBuffEditor_OnCloseClicked()
	Me.RemoveBuffEditor_Refresh()
	Me.removebuffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.RemoveBuffEditor_Open( parent )
	if parent then
		Me.CloseAllEditors( nil, nil, true )
		Me.removebuffeditor.parent = parent
		Me.removebuffeditor:SetPoint( "LEFT", parent, "RIGHT" )
		DiceMasterRemoveBuffEditorSaveButton:ClearAllPoints()
		DiceMasterRemoveBuffEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterRemoveBuffEditorDeleteButton:ClearAllPoints()
		DiceMasterRemoveBuffEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterRemoveBuffEditorDeleteButton:SetText( "Cancel" )
	else
		Me.CloseAllEditors()
		Me.removebuffeditor.parent = nil
		Me.removebuffeditor:SetPoint( "LEFT", DiceMasterTraitEditor, "RIGHT" )
		DiceMasterRemoveBuffEditorSaveButton:ClearAllPoints()
		DiceMasterRemoveBuffEditorSaveButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterRemoveBuffEditorDeleteButton:ClearAllPoints()
		DiceMasterRemoveBuffEditorDeleteButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterRemoveBuffEditorDeleteButton:SetText( "Delete" )
	end
	
	DiceMasterRemoveBuffEditorSaveButton:SetScript( "OnClick", function()
		Me.RemoveBuffEditor_Save()
	end)
   
	Me.RemoveBuffEditor_Refresh()
	Me.removebuffeditor:Show()
end

-------------------------------------------------------------------------------
