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
	DiceMasterAdjustHealthEditor.delay:SetText("")
	
	Me.EffectEditingIndex = nil;
end

function Me.AdjustHealthEditor_AdjustHealth( data )
	if not data or not data.type or not data.health or data.type ~= "health" then
		return
	end
	
	Me.Profile.health = Me.Clamp( Me.Profile.health + data.health, 0, Me.Profile.healthMax )
	
	if data.armour then
		Me.Profile.armor = Me.Clamp( Me.Profile.armor + data.armour, 0, 1000 )
	end
	
	if Me.db.global.allowEffects then
		Me.ResetFullscreenEffect()
		local model = DiceMasterFullscreenEffectFrame.Model
		-- check if we're gaining or losing health
		if data.health > 0 then
			model:ApplySpellVisualKit( 29077, true )
			PlaySound( 32877 )
			Me.SecretEditor_OnEvent( "PLAYER_HEALED" )
		elseif data.health < 0 then
			model:ApplySpellVisualKit( 29078, true )
			PlaySound( 32878 )
		elseif data.armour > 0 then
			model:ApplySpellVisualKit( 30834, true )
			PlaySound( 32882 )
		elseif data.armour < 0 then
			model:ApplySpellVisualKit( 29938, true )
			PlaySound( 32881 )
		end
	end
	
	if data.health > 0 then
		Me.PrintMessage( "You have gained |cFFFFFFFF" .. data.health .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
	elseif data.health < 0 then
		Me.PrintMessage( "You have lost |cFFFFFFFF" .. data.health .. "|r|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t!", "RAID" )
	end
	
	if data.armour > 0 then
		Me.PrintMessage( "You have gained |cFFFFFFFF" .. data.armour .. "|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t!", "RAID" )
	elseif data.armour < 0 then
		Me.PrintMessage( "You have lost |cFFFFFFFF" .. data.armour .. "|r|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t!", "RAID" )
	end
	
	Me.RefreshHealthbarFrame( DiceMasterChargesFrame.healthbar, Profile.health, Profile.healthMax, Profile.armor )
	
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
	local delay = tonumber( DiceMasterAdjustHealthEditor.delay:GetText() )
	
	health = math.floor( health )
	armour = math.floor( armour )
	
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
	
	local messageData = {
		type = "health";
		health = health;
		armour = armour;
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
	local delay = tonumber( DiceMasterAdjustHealthEditor.delay:GetText() )
	
	health = math.floor( health )
	armour = math.floor( armour )
	
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
	
	local messageData = {
		type = "health";
		health = health;
		armour = armour;
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
