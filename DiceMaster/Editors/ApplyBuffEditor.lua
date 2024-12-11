-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Apply Buff editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local BUFF_DURATION_AMOUNTS = {
	{name = "15 sec", time = 15},
	{name = "30 sec", time = 30},
	{name = "45 sec", time = 45},
	{name = "1 min", time = 60},
	{name = "2 min", time = 120},
	{name = "5 min", time = 300},
	{name = "10 min", time = 600},
	{name = "15 min", time = 900},
	{name = "30 min", time = 1800},
	{name = "45 min", time = 2700},
	{name = "1 hour", time = 3600},
	{name = "2 hours", time = 7200},
	{name = "3 hours", time = 10800},
	{name = "1 turn", turns = 1},
	{name = "2 turns", turns = 2},
	{name = "3 turns", turns = 3},
	{name = "4 turns", turns = 4},
	{name = "5 turns", turns = 5},
	{name = "6 turns", turns = 6},
	{name = "7 turns", turns = 7},
	{name = "8 turns", turns = 8},
	{name = "9 turns", turns = 9},
	{name = "10 turns", turns = 10},
}

function Me.BuffButton_FormatTime( seconds )
	local timeRemaining = math.floor( seconds ) .. " seconds"
	if seconds > 86400 then
		seconds = math.ceil( seconds / 86400 )
		timeRemaining = seconds .. " days"
	elseif seconds > 3600 then
		seconds = math.ceil( seconds / 3600 )
		timeRemaining = seconds .. " hours"
	elseif seconds > 60 then
		seconds = math.ceil( seconds / 60 )
		timeRemaining = seconds .. " minutes"
	end
	return timeRemaining
end

function Me.BuffEditor_Refresh( effectIndex )
	local buff
	if Me.buffeditor.parent and effectIndex then
		if Me.ItemEditing then
			buff = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			buff = Me.newItem.effects[ effectIndex ]
		end
		
		if buff then
			DiceMasterBuffEditorSaveButton:SetScript( "OnClick", function()
				Me.BuffEditor_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		buff = Profile.traits[Me.editing_trait]["effects"]["buff"] or nil
	end
	if not buff then
		buff = {
			icon = "Interface/Icons/inv_misc_questionmark",
			name = "",
			desc = "",
			skill = "",
			skillRank = 0,
			cancelable = true,
			duration = 1,
			target = true,
			aoe = false,
			range = 0,
			stackable = false,
			blank = true,
		}
		if not Me.buffeditor.parent then
			Profile.traits[Me.editing_trait]["effects"]["buff"] = buff
		end
	end
	Me.buffeditor.buffIcon:SetTexture( buff.icon )
	Me.buffeditor.buffName:SetText( buff.name )
	Me.buffeditor.buffDesc.EditBox:SetText( buff.desc )
	Me.buffeditor.buffSkillName:SetText( buff.skill or "" )
	Me.buffeditor.buffSkillRank:SetText( buff.skillRank or 0 )
	Me.buffeditor.buffCancelable:SetChecked( buff.cancelable )
	if buff.cancelable then
		DiceMasterBuffEditorBuffDuration:Disable()
		DiceMasterBuffEditorBuffDurationText:SetTextColor( 0.4, 0.4, 0.4 )
	else
		DiceMasterBuffEditorBuffDuration:Enable()
		DiceMasterBuffEditorBuffDurationText:SetTextColor( 1, 0.82, 0 )
	end
	Me.buffeditor.buffDuration:SetValue( buff.duration or 1 )
	Me.buffeditor.buffTarget:SetChecked( buff.target )
	Me.buffeditor.buffAOE:SetChecked( buff.aoe )
	Me.buffeditor.buffRange:SetText( buff.range or 0 )
	Me.buffeditor.buffStackable:SetChecked( buff.stackable )
end


function Me.BuffEditor_GetBuffData()
	if not Me.buffeditor.buffIcon.icon:GetTexture() then 
		UIErrorsFrame:AddMessage( "You can't save a buff without an icon.", 1.0, 0.0, 0.0 );
		return
	end

	local buff = {
		icon = Me.buffeditor.buffIcon.icon:GetTexture();
		name = Me.buffeditor.buffName:GetText();
		desc = Me.buffeditor.buffDesc.EditBox:GetText();
		skill = Me.buffeditor.buffSkillName:GetText();
		skillRank = Me.buffeditor.buffSkillRank:GetText();
		cancelable = true;
		duration = 1;
		aoe = Me.buffeditor.buffAOE:GetChecked();
		stackable = Me.buffeditor.buffStackable:GetChecked();
	}
	
	if not Me.buffeditor.buffCancelable:GetChecked() then
		buff.duration = Me.buffeditor.buffDuration:GetValue()
	end

	if buff.name == "" then
		UIErrorsFrame:AddMessage( "You can't save a buff without a name.", 1.0, 0.0, 0.0 );
		return 
	end
	
	return buff;
end

function Me.BuffEditor_SetBuffData( buffData )
	if not( buffData ) then
		return
	end
	Me.buffeditor.buffIcon:SetTexture( buffData.icon )
	Me.buffeditor.buffName:SetText( buffData.name )
	Me.buffeditor.buffDesc.EditBox:SetText( buffData.desc )
	if buffData.skill then
		Me.buffeditor.buffSkillName:SetText( buffData.skill )
		Me.buffeditor.buffSkillRank:SetText( buffData.skillRank )
	else
		Me.buffeditor.buffSkillName:SetText( "" )
		Me.buffeditor.buffSkillRank:SetText( "" )
	end
	if not( buffData.cancelable ) then
		Me.buffeditor.buffCancelable:SetChecked( false )
		Me.buffeditor.buffDuration:SetValue( buffData.duration )
	else
		Me.buffeditor.buffCancelable:SetChecked( true )
		Me.buffeditor.buffDuration:SetValue( 1 )
	end
	Me.buffeditor.buffAOE:SetChecked( buffData.aoe or false )
	Me.buffeditor.buffStackable:SetChecked( buffData.stackable );
end

function Me.BuffEditor_DeleteBuff()
	if not Me.buffeditor.parent then
		Profile.traits[Me.editing_trait]["effects"]["buff"] = nil
	end
	
	Me.IconPicker_Close()
	Me.buffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.BuffEditor_Save()
	if Me.buffeditor.buffName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	local buff
	if Me.buffeditor.parent then
		buff = {
			type = "buff";
		}
	else
		buff = Profile.traits[Me.editing_trait]["effects"]["buff"]
	end
	buff.name = Me.buffeditor.buffName:GetText()
	buff.icon = Me.buffeditor.buffIcon.icon:GetTexture()
	buff.desc = Me.buffeditor.buffDesc.EditBox:GetText()
	buff.skill = Me.buffeditor.buffSkillName:GetText()
	buff.skillRank = Me.buffeditor.buffSkillRank:GetText()
	buff.cancelable = Me.buffeditor.buffCancelable:GetChecked()	
	if not buff.cancelable then
		buff.duration = Me.buffeditor.buffDuration:GetValue()
	else
		buff.duration = 0
	end
	buff.target = Me.buffeditor.buffTarget:GetChecked()
	buff.aoe = Me.buffeditor.buffAOE:GetChecked()
	if buff.aoe then 
		buff.range = Me.buffeditor.buffRange:GetText()
	else
		buff.range = 0
	end
	buff.stackable = Me.buffeditor.buffStackable:GetChecked()
	if Me.buffeditor.parent then
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, buff )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, buff )
		end
		Me.ItemEditorEffectsList_Update()
	else
		Profile.traits[Me.editing_trait]["effects"]["buff"] = buff
	end
end

function Me.BuffEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if Me.buffeditor.buffName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	local buff = {
		type = "buff";
	}
	buff.name = Me.buffeditor.buffName:GetText()
	buff.icon = Me.buffeditor.buffIcon.icon:GetTexture()
	buff.desc = Me.buffeditor.buffDesc.EditBox:GetText()
	buff.skill = Me.buffeditor.buffSkillName:GetText()
	buff.skillRank = Me.buffeditor.buffSkillRank:GetText()
	buff.cancelable = Me.buffeditor.buffCancelable:GetChecked()	
	if not buff.cancelable then
		buff.duration = Me.buffeditor.buffDuration:GetValue()
	else
		buff.duration = 0
	end
	buff.target = Me.buffeditor.buffTarget:GetChecked()
	buff.aoe = Me.buffeditor.buffAOE:GetChecked()
	if buff.aoe then 
		buff.range = Me.buffeditor.buffRange:GetText()
	else
		buff.range = 0
	end
	buff.stackable = Me.buffeditor.buffStackable:GetChecked()
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = buff
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = buff
	end
	
	Me.BuffEditor_OnCloseClicked()
	Me.ItemEditorEffectsList_Update()
end

function Me.BuffEditor_SelectIcon( texture )
	if not Me.buffeditor.parent then
		Profile.traits[Me.editing_trait]["effects"]["buff"]["icon"] = texture
	end
	DiceMasterBuffEditor.buffIcon:SetTexture( texture )
end

function Me.BuffDuration_OnLoad( self )
	self:SetMinMaxValues(1, #BUFF_DURATION_AMOUNTS)
	self:SetObeyStepOnDrag( true )
	self:SetValueStep( 1 )
	self:SetValue(1)
	_G[self:GetName().."Low"]:Hide()
	_G[self:GetName().."High"]:Hide()
	_G[self:GetName().."Text"]:SetText("Buff Duration: "..BUFF_DURATION_AMOUNTS[self:GetValue()].name)
	self.tooltipText = "Set the duration for this buff."
end

function Me.BuffDuration_OnValueChanged( self, value, userInput )
	_G[self:GetName().."Text"]:SetText("Buff Duration: "..BUFF_DURATION_AMOUNTS[ value ].name)
end

function Me.BuffEditor_OnCloseClicked()
	Me.IconPicker_Close()
	Me.BuffEditor_Refresh()
	Me.buffeditor.parent = nil
	Me.buffeditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.BuffEditor_Open( parent )
	if parent then
		Me.CloseAllEditors( nil, nil, true )
		Me.buffeditor.parent = parent
		Me.buffeditor:SetPoint( "LEFT", parent, "RIGHT" )
		DiceMasterBuffEditorSaveButton:ClearAllPoints()
		DiceMasterBuffEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterBuffEditorDeleteButton:ClearAllPoints()
		DiceMasterBuffEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterBuffEditorDeleteButton:SetText( "Cancel" )
	else
		Me.CloseAllEditors()
		Me.buffeditor.parent = nil
		Me.buffeditor:SetPoint( "LEFT", DiceMasterTraitEditor, "RIGHT" )
		DiceMasterBuffEditorSaveButton:ClearAllPoints()
		DiceMasterBuffEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterBuffEditorDeleteButton:ClearAllPoints()
		DiceMasterBuffEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterBuffEditorDeleteButton:SetText( "Delete" )
	end
	
	DiceMasterBuffEditorSaveButton:SetScript( "OnClick", function()
		Me.BuffEditor_Save()
		Me.BuffEditor_OnCloseClicked()
	end)

	Me.buffeditor.LoadDropdown:SetCollection(nil, "Buffs", Me.BuffEditor_GetBuffData, nil, Me.BuffEditor_SetBuffData);
   
	Me.BuffEditor_Refresh()
	Me.buffeditor:Show()
end

-------------------------------------------------------------------------------

--
-- DM Apply Buff editor interface.
-- 
-- For directly buffing players, DM utility, etc.
--


function Me.DMBuffEditor_Refresh( effectIndex )
	Me.dmbuffeditor.buffIcon:SetTexture( "Interface/Icons/inv_misc_questionmark" )
	Me.dmbuffeditor.buffName:SetText( "" )
	Me.dmbuffeditor.buffDesc.EditBox:SetText( "" )
	Me.dmbuffeditor.buffSkillName:SetText( "" )
	Me.dmbuffeditor.buffSkillRank:SetText( 0 )
	Me.dmbuffeditor.buffCancelable:SetChecked( true )
	DiceMasterDMBuffEditorBuffDuration:Disable()
	DiceMasterDMBuffEditorBuffDurationText:SetTextColor( 0.4, 0.4, 0.4 )
	Me.dmbuffeditor.buffDuration:SetValue( 1 )
	Me.dmbuffeditor.buffAOE:SetChecked( false )
	Me.dmbuffeditor.buffRange:SetText( 0 )
	Me.dmbuffeditor.buffStackable:SetChecked( false )
	Me.dmbuffeditor.collectionName = nil;
end

function Me.DMBuffEditor_GetBuffData()
	if not Me.dmbuffeditor.buffIcon.icon:GetTexture() then 
		UIErrorsFrame:AddMessage( "You can't save a buff without an icon.", 1.0, 0.0, 0.0 );
		return
	end

	local buff = {
		icon = Me.dmbuffeditor.buffIcon.icon:GetTexture();
		name = Me.dmbuffeditor.buffName:GetText();
		desc = Me.dmbuffeditor.buffDesc.EditBox:GetText();
		skill = Me.dmbuffeditor.buffSkillName:GetText();
		skillRank = Me.dmbuffeditor.buffSkillRank:GetText();
		cancelable = true;
		duration = 1;
		aoe = Me.dmbuffeditor.buffAOE:GetChecked();
		stackable = Me.dmbuffeditor.buffStackable:GetChecked();
	}
	
	if not Me.dmbuffeditor.buffCancelable:GetChecked() then
		buff.duration = Me.dmbuffeditor.buffDuration:GetValue()
	end

	if buff.name == "" then
		UIErrorsFrame:AddMessage( "You can't save a buff without a name.", 1.0, 0.0, 0.0 );
		return 
	end
	
	return buff;
end

function Me.DMBuffEditor_SetBuffData( buffData )
	if not( buffData ) then
		return
	end
	Me.dmbuffeditor.buffIcon:SetTexture( buffData.icon )
	Me.dmbuffeditor.buffName:SetText( buffData.name )
	Me.dmbuffeditor.buffDesc.EditBox:SetText( buffData.desc )
	if buffData.skill then
		Me.dmbuffeditor.buffSkillName:SetText( buffData.skill )
		Me.dmbuffeditor.buffSkillRank:SetText( buffData.skillRank )
	else
		Me.dmbuffeditor.buffSkillName:SetText( "" )
		Me.dmbuffeditor.buffSkillRank:SetText( "" )
	end
	if not( buffData.cancelable ) then
		Me.dmbuffeditor.buffCancelable:SetChecked( false )
		Me.dmbuffeditor.buffDuration:SetValue( buffData.duration )
	else
		Me.dmbuffeditor.buffCancelable:SetChecked( true )
		Me.dmbuffeditor.buffDuration:SetValue( 1 )
	end
	Me.dmbuffeditor.buffAOE:SetChecked( buffData.aoe or false )
	Me.dmbuffeditor.buffStackable:SetChecked( buffData.stackable );
end

function Me.DMBuffEditor_Cast()
	if not Me.dmbuffeditor.buffIcon.icon:GetTexture() then return end
	
	local buff = {
		type = "buff";
		icon = Me.dmbuffeditor.buffIcon.icon:GetTexture();
		name = Me.dmbuffeditor.buffName:GetText();
		desc = Me.dmbuffeditor.buffDesc.EditBox:GetText();
		skill = Me.dmbuffeditor.buffSkillName:GetText();
		skillRank = Me.dmbuffeditor.buffSkillRank:GetText();
		cancelable = Me.dmbuffeditor.buffCancelable:GetChecked();
		duration = 0;
		aoe = Me.dmbuffeditor.buffAOE:GetChecked();
		stackable = Me.dmbuffeditor.buffStackable:GetChecked();
	}
	
	if not Me.dmbuffeditor.buffCancelable:GetChecked() then
		buff.duration = Me.dmbuffeditor.buffDuration:GetValue()
	end
	
	Me.BuffFrame_CastBuff( buff )
end

function Me.DMBuffEditor_SelectIcon( texture )
	Me.dmbuffeditor.buffIcon:SetTexture( texture )
end

function Me.DMBuffEditor_UpdateCastButton()
	if UnitIsUnit("target", "player") or not( UnitExists( "target" )) or not( UnitIsPlayer( "target" )) or not( IsInGroup( LE_PARTY_CATEGORY_HOME )) then
		DiceMasterDMBuffEditorCastButton:SetText( "Apply to Self" )
		Me.SetupTooltip( DiceMasterDMBuffEditorCastButton, nil,  "|cFFFFD100Click to apply this buff to yourself.")
	else
		DiceMasterDMBuffEditorCastButton:SetText( "Apply to: " .. UnitName("target") )
		Me.SetupTooltip( DiceMasterDMBuffEditorCastButton, nil,  "|cFFFFD100Click to apply this buff to " .. UnitName("target") .. ".")
	end
end

function Me.DMBuffEditor_OnCloseClicked()
	Me.dmbuffeditor:Hide()
end

function Me.DMBuffEditor_Open()
	if Me.db.global.trackerAnchor == "RIGHT" then
		Me.dmbuffeditor:ClearAllPoints()
		Me.dmbuffeditor:SetPoint( "LEFT", DiceMasterRollFrame, "RIGHT" )
	else
		Me.dmbuffeditor:ClearAllPoints()
		Me.dmbuffeditor:SetPoint( "RIGHT", DiceMasterRollFrame, "LEFT" )
	end

	Me.dmbuffeditor.LoadDropdown:SetCollection(nil, "Buffs", Me.DMBuffEditor_GetBuffData, nil, Me.DMBuffEditor_SetBuffData);

	Me.dmbuffeditor:Show()
	Me.DMBuffEditor_UpdateCastButton()
end

-------------------------------------------------------------------------------