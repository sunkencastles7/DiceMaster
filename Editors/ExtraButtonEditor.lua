-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Extra Button editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.ExtraButtonEditor_Refresh( effectIndex )
	local extrabutton
	if Me.ExtraButtonEditor.parent and effectIndex then
		if Me.ItemEditing then
			extrabutton = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			extrabutton = Me.newItem.effects[ effectIndex ]
		end
		
		if extrabutton then
			DiceMasterExtraButtonEditorSaveButton:SetScript( "OnClick", function()
				Me.ExtraButtonEditor_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		extrabutton = Profile.traits[Me.editing_trait]["effects"]["extrabutton"] or nil
	end
	if not extrabutton then
		extrabutton = {
			icon = "Interface/Icons/inv_misc_questionmark",
			title = "",
			desc = "",
			stat = "",
		}
		if not Me.ExtraButtonEditor.parent then
			Profile.traits[Me.editing_trait]["effects"]["extrabutton"] = extrabutton
		end
	end
	Me.ExtraButtonEditor.buffIcon:SetTexture( extrabutton.icon )
	Me.ExtraButtonEditor.buffTitle:SetText( extrabutton.title )
	Me.ExtraButtonEditor.buffDesc.EditBox:SetText( extrabutton.desc )
	Me.ExtraButtonEditor.buffStatName:SetText( extrabutton.stat or "" )
end

function Me.ExtraButtonEditor_DeleteBuff()
	if not Me.ExtraButtonEditor.parent then
		Profile.traits[Me.editing_trait]["effects"]["buff"] = nil
	end
	
	Me.IconPicker_Close()
	Me.ExtraButtonEditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.ExtraButtonEditor_Save()
	if Me.ExtraButtonEditor.buffName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	local extrabutton
	if Me.ExtraButtonEditor.parent then
		extrabutton = {
			type = "extrabutton";
		}
	else
		extrabutton = Profile.traits[Me.editing_trait]["effects"]["buff"]
	end
	extrabutton.title = Me.ExtraButtonEditor.buffTitle:GetText()
	extrabutton.icon = Me.ExtraButtonEditor.buffIcon.icon:GetTexture()
	extrabutton.desc = Me.ExtraButtonEditor.buffDesc.EditBox:GetText()
	extrabutton.stat = Me.ExtraButtonEditor.buffStatName:GetText()
	
	if Me.ExtraButtonEditor.parent then
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, extrabutton )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, extrabutton )
		end
		Me.ItemEditorEffectsList_Update()
	else
		Profile.traits[Me.editing_trait]["effects"]["extrabutton"] = extrabutton
	end
end

function Me.ExtraButtonEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if Me.ExtraButtonEditor.buffName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	local extrabutton = {
		type = "extrabutton";
	}
	extrabutton.title = Me.ExtraButtonEditor.buffTitle:GetText()
	extrabutton.icon = Me.ExtraButtonEditor.buffIcon.icon:GetTexture()
	extrabutton.desc = Me.ExtraButtonEditor.buffDesc.EditBox:GetText()
	extrabutton.stat = Me.ExtraButtonEditor.buffStatName:GetText()
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = extrabutton
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = extrabutton
	end
	
	Me.ExtraButtonEditor_OnCloseClicked()
	Me.ItemEditorEffectsList_Update()
end

function Me.ExtraButtonEditor_SelectIcon( texture )
	if not Me.ExtraButtonEditor.parent then
		Profile.traits[Me.editing_trait]["effects"]["extrabutton"]["icon"] = texture
	end
	DiceMasterExtraButtonEditor.buffIcon:SetTexture( texture )
end

function Me.ExtraButtonEditor_OnCloseClicked()
	Me.IconPicker_Close()
	Me.ExtraButtonEditor_Refresh()
	Me.ExtraButtonEditor.parent = nil
	Me.ExtraButtonEditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.ExtraButtonEditor_Open( parent )
	if parent then
		Me.CloseAllEditors( nil, nil, true )
		Me.ExtraButtonEditor.parent = parent
		Me.ExtraButtonEditor:SetPoint( "LEFT", parent, "RIGHT" )
		DiceMasterExtraButtonEditorSaveButton:ClearAllPoints()
		DiceMasterExtraButtonEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterExtraButtonEditorDeleteButton:ClearAllPoints()
		DiceMasterExtraButtonEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterExtraButtonEditorDeleteButton:SetText( "Cancel" )
	else
		Me.CloseAllEditors()
		Me.ExtraButtonEditor.parent = nil
		Me.ExtraButtonEditor:SetPoint( "LEFT", DiceMasterTraitEditor, "RIGHT" )
		DiceMasterExtraButtonEditorSaveButton:ClearAllPoints()
		DiceMasterExtraButtonEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterExtraButtonEditorDeleteButton:ClearAllPoints()
		DiceMasterExtraButtonEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterExtraButtonEditorDeleteButton:SetText( "Delete" )
	end
	
	DiceMasterExtraButtonEditorSaveButton:SetScript( "OnClick", function()
		Me.ExtraButtonEditor_Save()
		Me.ExtraButtonEditor_OnCloseClicked()
	end)
   
	Me.ExtraButtonEditor_Refresh()
	Me.ExtraButtonEditor:Show()
end

-------------------------------------------------------------------------------
