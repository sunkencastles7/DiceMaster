-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Health editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

function Me.AdjustHealthEditor_Refresh()
	DiceMasterAdjustHealthEditor.health:SetText("")
	DiceMasterAdjustHealthEditor.armour:SetText("")
	DiceMasterAdjustHealthEditor.mana:SetText("")
	DiceMasterAdjustHealthEditor.delay:SetText("")
	
	Me.EffectEditingIndex = nil;
end

function Me.AdjustHealthEditor_AdjustHealth( data )
	if not data or not data.type or not data.health or data.type ~= "health" then
		return
	end
	
	local prevHealth, prevArmour, prevMana = Profile.health, Profile.armor, Profile.mana;

	Profile.health = Me.Clamp( Profile.health + data.health, 0, Profile.healthMax )
	
	if data.armour then
		Profile.armor = Me.Clamp( Profile.armor + data.armour, 0, 1000 )
	end

	if data.mana then
		Profile.mana = Me.Clamp( Profile.mana + data.mana, 0, Profile.manaMax )
	end
	
	if Profile.health ~= prevHealth then
		if data.health > 0 then
			Me.PrintMessage( "You have gained |cFFFFFFFF" .. (Profile.health - prevHealth) .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
			Me.SecretEditor_OnEvent( "PLAYER_HEALED" )
			if Me.db.global.allowEffects then
				Me.ResetFullscreenEffect();
				DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( 29077, true )
				PlaySound( 32877 )
			end
		elseif data.health < 0 then
			Me.PrintMessage( "You have lost |cFFFFFFFF" .. (Profile.health - prevHealth) .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
			if Me.db.global.allowEffects then
				Me.ResetFullscreenEffect();
				DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( 29078, true )
				PlaySound( 32878 )
			end
		end
	end
	
	if Profile.armor ~= prevArmour then
		if data.armour > 0 then
			Me.PrintMessage( "You have gained |cFFFFFFFF" .. (Profile.armor - prevArmour) .. "|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t!", "RAID" )
			if Me.db.global.allowEffects then
				Me.ResetFullscreenEffect();
				DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( 30834, true )
				PlaySound( 32882 )
			end
		elseif data.armour < 0 then
			Me.PrintMessage( "You have lost |cFFFFFFFF" .. (Profile.armor - prevArmour) .. "|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t!", "RAID" )
			if Me.db.global.allowEffects then
				Me.ResetFullscreenEffect();
				DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( 29938, true )
				PlaySound( 32881 )
			end
		end
	end

	if Profile.mana ~= prevMana then
		if data.mana > 0 then
			Me.PrintMessage( "You have gained |cFFFFFFFF" .. (Profile.mana - prevMana) .. "|r|TInterface/AddOns/DiceMaster/Texture/mana-icon-2:12|t!", "RAID" )
		elseif data.mana < 0 then
			Me.PrintMessage( "You have lost |cFFFFFFFF" .. (Profile.mana - prevMana) .. "|r|TInterface/AddOns/DiceMaster/Texture/mana-icon-2:12|t!", "RAID" )
		end
	end
	
	Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Profile.health, Profile.healthMax, Profile.armor )
	Me.RefreshManabarFrame( DiceMasterChargesFrame.manabar, Profile.mana, Profile.manaMax )
	
	Me.BumpSerial( Me.db.char, "statusSerial" )
	Me.Inspect_ShareStatusWithParty()
	Me.DiceMasterRollDetailFrame_Update()
	Me.DMRosterFrame_Update()
end

function Me.AdjustHealthEditor_Load( effectIndex )
	
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
	
	DiceMasterAdjustHealthEditor.health:SetText( effect.health )
	DiceMasterAdjustHealthEditor.armour:SetText( effect.armour or 0 )
	DiceMasterAdjustHealthEditor.mana:SetText( effect.mana or 0 )
	DiceMasterAdjustHealthEditor.delay:SetText( effect.delay )
	
	DiceMasterAdjustHealthEditorSaveButton:SetScript( "OnClick", function()
		Me.AdjustHealthEditor_SaveEdits()
	end)	
end

function Me.AdjustHealthEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	local health = tonumber( DiceMasterAdjustHealthEditor.health:GetText() ) or 0;
	local armour = tonumber( DiceMasterAdjustHealthEditor.armour:GetText() ) or 0;
	local mana = tonumber( DiceMasterAdjustHealthEditor.mana:GetText() ) or 0;
	local delay = tonumber( DiceMasterAdjustHealthEditor.delay:GetText() )
	
	health = math.floor( health )
	armour = math.floor( armour )
	mana = math.floor( mana )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not health or type( health ) ~= "number" then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
		return
	end
	
	if not armour or type( armour ) ~= "number" then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
		return
	end

	if not mana or type( mana ) ~= "number" then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
		return
	end
	
	local messageData = {
		type = "health";
		health = health;
		armour = armour;
		mana = mana;
		delay = delay;
	}
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = messageData
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = messageData
	end
	
	Me.AdjustHealthEditor_Close()
	Me.ItemEditorEffectsList_Update()
end

function Me.AdjustHealthEditor_Save()
	local health = tonumber( DiceMasterAdjustHealthEditor.health:GetText() ) or 0
	local armour = tonumber( DiceMasterAdjustHealthEditor.armour:GetText() ) or 0
	local mana = tonumber( DiceMasterAdjustHealthEditor.mana:GetText() ) or 0
	local delay = tonumber( DiceMasterAdjustHealthEditor.delay:GetText() )
	
	health = math.floor( health )
	armour = math.floor( armour )
	mana = math.floor( mana )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if not health or type( health ) ~= "number" then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
		return
	end
	
	if not armour or type( armour ) ~= "number" then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
		return
	end

	if not mana or type( mana ) ~= "number" then
		UIErrorsFrame:AddMessage( "Invalid amount.", 1.0, 0.0, 0.0 );
		return
	end
	
	local messageData = {
		type = "health";
		health = health;
		armour = armour;
		mana = mana;
		delay = delay;
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, messageData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, messageData )
	end
	
	Me.AdjustHealthEditor_Close()
	Me.ItemEditorEffectsList_Update()
end
    
-------------------------------------------------------------------------------
-- Close the adjust health editor window. Use this instead of a direct Hide()
--
function Me.AdjustHealthEditor_Close()
	Me.AdjustHealthEditor_Refresh()
	DiceMasterAdjustHealthEditorSaveButton:SetScript( "OnClick", function()
		Me.AdjustHealthEditor_Save()
	end)	
	DiceMasterAdjustHealthEditor:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the adjust health editor window.
--
function Me.AdjustHealthEditor_Open( frame )
	Me.CloseAllEditors( nil, nil, true )
	if not frame then
		frame = DiceMasterItemEditor;
	end
	DiceMasterAdjustHealthEditor:ClearAllPoints()
	DiceMasterAdjustHealthEditor:SetPoint( "LEFT", frame, "RIGHT" )
	
	DiceMasterAdjustHealthEditorSaveButton:SetScript( "OnClick", function()
		Me.AdjustHealthEditor_Save()
	end)	
	
	Me.AdjustHealthEditor_Refresh()
	DiceMasterAdjustHealthEditor:Show()
end
