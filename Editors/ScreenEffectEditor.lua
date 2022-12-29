-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Screen effect editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local function GetIDFromTextureName( texture )
	for k, v in pairs ( Me.textureList ) do
		for i = 1, #v do
			if v[i].file == texture then
				return v[i].id, v[i].orientation
			end
		end
	end
	return nil
end

function Me.ScreenEffectEditorTexture_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText( DiceMasterScreenEffectEditor.textureDropdown, self:GetText() )
	local orientation = Me.textureList[arg1][arg2].orientation or "HORIZONTAL"
	if ( orientation == "HORIZONTAL" ) then
		DiceMasterScreenEffectEditor.previewTextureTop:SetTexture( Me.textureList[arg1][arg2].id )
		DiceMasterScreenEffectEditor.previewTextureLeft:SetTexture( nil )
		DiceMasterScreenEffectEditor.previewTextureRight:SetTexture( nil )
	elseif ( orientation == "VERTICAL" ) then
		DiceMasterScreenEffectEditor.previewTextureTop:SetTexture( nil )
		DiceMasterScreenEffectEditor.previewTextureLeft:SetTexture( Me.textureList[arg1][arg2].id )
		DiceMasterScreenEffectEditor.previewTextureRight:SetTexture( Me.textureList[arg1][arg2].id )
		DiceMasterScreenEffectEditor.previewTextureLeft:SetTexCoord( 1, 0, 0, 1 );
	end
end

function Me.ScreenEffectEditorTexture_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	if level == 1 then
		info.text = "|cFFffd100Textures"
		info.notClickable = true;
		info.notCheckable = true;
		UIDropDownMenu_AddButton(info)
		info.disabled = false;
		info.notClickable = false;
		info.hasArrow = true;
		for k,v in pairs( Me.textureList ) do
			info.text = k
			info.menuList = k
			UIDropDownMenu_AddButton(info)
		end
	elseif menuList then
		for i = 1, #Me.textureList[menuList] do
			info.text = Me.textureList[menuList][i].file
			info.arg1 = menuList;
			info.arg2 = i;
			info.notCheckable = false;
			info.checked = UIDropDownMenu_GetText( DiceMasterScreenEffectEditor.textureDropdown ) == info.text;
			info.func = Me.ScreenEffectEditorTexture_OnClick;
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Me.ScreenEffectEditor_Refresh()
	DiceMasterScreenEffectEditor.sendToTarget:SetChecked( false )
	DiceMasterScreenEffectEditor.delay:SetText("")
	UIDropDownMenu_SetText( DiceMasterScreenEffectEditor.textureDropdown, Me.textureList["Mage"][1].file )
	DiceMasterScreenEffectEditor.previewTextureTop:SetTexture( nil )
	DiceMasterScreenEffectEditor.previewTextureLeft:SetTexture( Me.textureList["Mage"][1].id )
	DiceMasterScreenEffectEditor.previewTextureLeft:SetTexCoord( 1, 0, 0, 1 );
	DiceMasterScreenEffectEditor.previewTextureRight:SetTexture( Me.textureList["Mage"][1].id )
	
	Me.EffectEditingIndex = nil;
end

function Me.ScreenEffectEditor_PlayEffect( data )
	if not data or not data.type or not data.texture or data.type ~= "screeneffect" then
		return
	end
	
	local id, orientation = GetIDFromTextureName( data.texture )
	
	if data.target and ( UnitExists("target") and UnitIsPlayer("target") and UnitIsFriend("target", "player") and UnitIsSameServer("target") and UnitIsConnected("target") )then
		local data = Me:Serialize( "SCEFFECT", {
			type = "screeneffect";
			texture = data.texture;
		})
		Me:SendCommMessage( "DCM4", data, "WHISPER", UnitName("target"), "NORMAL" )
		return
	end
	
	if id and orientation then
		if orientation == "HORIZONTAL" then
			SpellActivationOverlay_ShowOverlay( DiceMasterScreenEffectFrame, id, id, "TOP", 1, 255, 255, 255, false, false )
		elseif orientation == "VERTICAL" then
			SpellActivationOverlay_ShowOverlay( DiceMasterScreenEffectFrame, id, id, "LEFT", 1, 255, 255, 255, false, false )
			SpellActivationOverlay_ShowOverlay( DiceMasterScreenEffectFrame, id, id, "RIGHT", 1, 255, 255, 255, false, true )
		end
		C_Timer.After( 5, function()
			SpellActivationOverlay_HideOverlays( DiceMasterScreenEffectFrame, id )
		end)
	end
end

function Me.ScreenEffectEditor_Load( effectIndex )
	
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
	
	DiceMasterScreenEffectEditor.sendToTarget:SetChecked( effect.target )
	DiceMasterScreenEffectEditor.delay:SetText( effect.delay )
	UIDropDownMenu_SetText( DiceMasterScreenEffectEditor.textureDropdown, effect.texture )
	
	local id, orientation = GetIDFromTextureName( effect.texture )
	if id and orientation then
		if ( orientation == "HORIZONTAL" ) then
			DiceMasterScreenEffectEditor.previewTextureTop:SetTexture( id )
			DiceMasterScreenEffectEditor.previewTextureLeft:SetTexture( nil )
			DiceMasterScreenEffectEditor.previewTextureRight:SetTexture( nil )
		elseif ( orientation == "VERTICAL" ) then
			DiceMasterScreenEffectEditor.previewTextureTop:SetTexture( nil )
			DiceMasterScreenEffectEditor.previewTextureLeft:SetTexture( id )
			DiceMasterScreenEffectEditor.previewTextureRight:SetTexture( id )
			DiceMasterScreenEffectEditor.previewTextureLeft:SetTexCoord( 1, 0, 0, 1 );
		end
	end
	
	DiceMasterScreenEffectEditorSaveButton:SetScript( "OnClick", function()
		Me.ScreenEffectEditor_SaveEdits()
	end)	
end

function Me.ScreenEffectEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	local target = DiceMasterScreenEffectEditor.sendToTarget:GetChecked()
	local texture = UIDropDownMenu_GetText( DiceMasterScreenEffectEditor.textureDropdown )
	local delay = tonumber( DiceMasterScreenEffectEditor.delay:GetText() )
	
	if not texture or type( texture ) ~= "string" then
		texture = Me.textureList["Mage"][1].file
	end
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local effectData = {
		type = "screeneffect";
		target = target;
		texture = texture;
		delay = delay;
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = effectData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = effectData
	end
	
	Me.ScreenEffectEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.ScreenEffectEditor_Save()
	local target = DiceMasterScreenEffectEditor.sendToTarget:GetChecked()
	local texture = UIDropDownMenu_GetText( DiceMasterScreenEffectEditor.textureDropdown )
	local delay = tonumber( DiceMasterScreenEffectEditor.delay:GetText() )
	
	if not texture or type( texture ) ~= "string" then
		texture = Me.textureList["Mage"][1].file
	end
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local effectData = {
		type = "screeneffect";
		target = target;
		texture = texture;
		delay = delay;
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, effectData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, effectData )
	end
	
	Me.ScreenEffectEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the screen effect editor window. Use this instead of a direct Hide()
--
function Me.ScreenEffectEditor_Close()
	Me.ScreenEffectEditor_Refresh()
	DiceMasterScreenEffectEditorSaveButton:SetScript( "OnClick", function()
		Me.ScreenEffectEditor_Save()
	end)	
	DiceMasterScreenEffectEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the screen effect editor window.
--
function Me.ScreenEffectEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterScreenEffectEditor:ClearAllPoints()
	DiceMasterScreenEffectEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterScreenEffectEditorSaveButton:SetScript( "OnClick", function()
		Me.ScreenEffectEditor_Save()
	end)	
	
	Me.ScreenEffectEditor_Refresh()
	DiceMasterScreenEffectEditor:Show()
end
