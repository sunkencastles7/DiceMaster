-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Effect picker interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

Me.effectList = {
	-- id = SpellVisualKitID
	-- name = shorthand name
	-- icon = icon path
	{ id=65218, name="Phoenix", icon=526578 },
	{ id=83901, name="Blast", icon=237582 },
	{ id=69530, name="Dragon\'s Breath", icon=134153 }, 
	{ id=24397, name="Frost Nova", icon=135848 },
	{ id=122099, name="Light Explosion", icon=571554 },
    { id=122498, name="Water Explosion 1", icon=893777 },
	{ id=24512, name="Water Explosion 2", icon=538567 },
	{ id=98061, name="Water Splash", icon=463570 },
	{ id=122391, name="Rising Rock", icon=646672 },
	{ id=108411, name="Star Swirl", icon=236168 },
	{ id=124180, name="Blood Explosion 1", icon=236305 },
	{ id=124281, name="Blood Explosion 2", icon=1029738 },
	{ id=69120, name="Charged Up", icon=839979 },
	{ id=68661, name="Teleport", icon=237509 },
	{ id=122453, name="Azerite Acquired", icon=2065618 },
	{ id=122748, name="Azerite Blast", icon=2032580 },
	{ id=122436, name="Azerite Shockwave", icon=2967103 },
	{ id=123851, name="Level Up", icon=1360764 },
	{ id=79517, name="Fel Explosion", icon=841219 },
	{ id=69659, name="Shimmer", icon=135739 },
	{ id=85900, name="Shapeshift", icon=254857 },
	{ id=43028, name="Fireball Impact", icon=525023 },
	{ id=121932, name="Void Blast", icon=1728724 },
	{ id=119093, name="Starfall", icon=1033487 },
	{ id=104956, name="Hearts", icon=236709 },
	{ id=107847, name="Arcane Blast", icon=135735 },
	{ id=85318, name="Arcane Blast 2", icon=135735 },
	{ id=106452, name="Flash of Light", icon=135915 },
	{ id=117010, name="Time Warp", icon=458224 },
	{ id=85113, name="Blink", icon=135736 },
	{ id=90913, name="Drust Blast 1", icon=1778228 },
	{ id=90905, name="Drust Blast 2", icon=1778229 },
	{ id=91067, name="Drust Explosion", icon=1778230 },
	{ id=59926, name="Arcane Explosion", icon=136116 },
	{ id=87895, name="Supernova", icon=1033912 },
	{ id=59418, name="Blood Aura", icon=135966 },
	{ id=88767, name="Holy Light", icon=135920 },
	{ id=88432, name="Raise Dead", icon=136119 },
	{ id=88399, name="Curse", icon=136162 },
	{ id=87050, name="Pet Battle Speed", icon=648208 },
	{ id=87320, name="Holy Nova", icon=135922 },
	{ id=87402, name="Frost Explosion", icon=135849 },
	{ id=87947, name="Resurrection", icon=135955 },
	{ id=87223, name="Shadow Explosion", icon=132851 },
	{ id=86727, name="Poison Burst", icon=132108 },
	{ id=86584, name="Reverse Time", icon=136106 },
	{ id=86961, name="Fel Explosion", icon=135799 },
	{ id=86034, name="Arcane Halo", icon=632353 },
	{ id=85815, name="Bats", icon=136128 },
	{ id=85441, name="Sleep", icon=136090 },
	{ id=85746, name="Steam", icon=132837 },
	{ id=85059, name="Paralyse", icon=629534 },
	{ id=84319, name="Broken Heart", icon=135767 },
	{ id=84116, name="Explosion", icon=133035 },
	{ id=84184, name="Music Notes", icon=237540 },
	{ id=84201, name="Shadow Transform", icon=237563 },
	{ id=84557, name="Focus", icon=878211 },
	{ id=83408, name="Blood Spray", icon=1029738 },
	{ id=83064, name="Blood Nova", icon=1394887 },
	{ id=82386, name="Vanish", icon=132331 },
	--{ id=, name=, icon= },
}

local filteredList = nil

function Me.EffectPicker_OnLoad(self)
	self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -48)
	self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 90)
	
	if self.NineSlice then
		self.NineSlice:SetFrameLevel(1)
	end

	for i = 2, 14 do
		local button = CreateFrame("Button", "DiceMasterEffectPickerButton"..i, DiceMasterEffectPicker, "DiceMasterEffectPickerButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterEffectPickerButton"..(i-1)], "BOTTOM");
	end
	
	Me.EffectPicker_Update()
end

function Me.EffectPickerButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		local list = filteredList or Me.effectList;
		DiceMasterEffectPicker.customEffect:SetChecked( false )
		DiceMasterEffectPicker.selectedID = list[ self.effectIndex ].id
		DiceMasterEffectPicker.selectedName = list[ self.effectIndex ].name
		Me.EffectPicker_Update()
	end
end

function Me.EffectPicker_Refresh( effectIndex )
	local effect
	if DiceMasterEffectPicker.parent and effectIndex then
		if Me.ItemEditing then
			effect = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			effect = Me.newItem.effects[ effectIndex ]
		end
		
		if effect then
			DiceMasterEffectPickerSaveButton:SetScript( "OnClick", function()
				Me.EffectPicker_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		effect = Profile.traits[Me.editing_trait]["effects"]["effect"] or nil
	end
	if not effect then
		effect = {
			effectID = 0;
			effectName = "";
			target = false;
		}
		if not DiceMasterEffectPicker.parent then
			Profile.traits[Me.editing_trait]["effects"]["effect"] = effect;
		end
		DiceMasterEffectPicker.delay:SetText( 0 )
	else
		if ( effect.effectName and effect.effectName == "" ) then
			-- this is a custom effect
			DiceMasterEffectPicker.customEffect:SetChecked( true )
			DiceMasterEffectPicker.customEffectID:SetText( effect.effectID )
		end
		if ( effect.effectID and effect.effectID ~= 0 ) then
			DiceMasterEffectPicker.selectedID = effect.effectID
			DiceMasterEffectPicker.selectedName = effect.effectName;
		end
		DiceMasterEffectPicker.delay:SetText( effect.delay or 0 )
	end
	if effect.target then
		DiceMasterEffectPicker.sendToTarget:SetChecked( true )
	else
		DiceMasterEffectPicker.sendToTarget:SetChecked( false )
	end
	Me.EffectPicker_Update()
end

function Me.EffectPicker_Update()
	local id, name, icon;
	local list = filteredList or Me.effectList;
	local effectOffset = FauxScrollFrame_GetOffset(DiceMasterEffectPickerScrollFrame);
	
	for i=1,14,1 do
		effectIndex = effectOffset + i;
		local button = _G["DiceMasterEffectPickerButton"..i];
		button.effectIndex = effectIndex
		local info = list[effectIndex];
		if ( info ) then
			id 	 = info.id;
			name = info.name;
			icon = info.icon;
		end
		local buttonText = _G["DiceMasterEffectPickerButton"..i.."Name"];
		buttonText:SetText( name )
		local buttonIcon = _G["DiceMasterEffectPickerButton"..i.."Icon"];
		buttonIcon:SetTexture( icon )
		
		-- Highlight the correct who
		if ( DiceMasterEffectPicker.selectedName == name ) then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end
		
		if ( effectIndex > #list ) then
			button:Hide();
		else
			button:Show();
		end
		
	end
	
	FauxScrollFrame_Update(DiceMasterEffectPickerScrollFrame, #list, 14, 16, nil, nil, nil, nil, nil, nil, true );
end

function Me.EffectPicker_TestEffect( self, spellVisualKitID )
	local list = filteredList or Me.effectList;
	-- Stop playing any current effects.
	Me.ResetFullscreenEffect()
	
	if self then
		if list[self.effectIndex].id then
			DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( list[self.effectIndex].id, true );
		end
	elseif spellVisualKitID then
		DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( spellVisualKitID, true );
	end
end

function Me.EffectPicker_PlayEffect( data )
	local effect
	if type( data ) == "table" and data.type and data.type == "effect" then
		effect = data
	else
		effect = Profile.traits[ data ]["effects"]["effect"]
	end
	
	if not effect then
		return
	end
	
	Me.ResetFullscreenEffect()
	if ( effect and effect.effectID ) then
		if effect.target and ( UnitExists("target") and UnitIsPlayer("target") and UnitIsFriend("target", "player") and UnitIsSameServer("target") and UnitIsConnected("target") )then
			local data = Me:Serialize( "EFFECT", {
				sv = tonumber( effect.effectID );
			})
			Me:SendCommMessage( "DCM4", data, "WHISPER", UnitName("target"), "NORMAL" )
		else
			DiceMasterFullscreenEffectFrame.Model:ApplySpellVisualKit( effect.effectID, true );
		end
	end
end

function Me.EffectPicker_Delete()
	if not DiceMasterEffectPicker.parent then
		Profile.traits[Me.editing_trait]["effects"]["effect"] = nil
	end
	
	PlaySound(840); 
	Me.EffectPicker_Close()
end

function Me.EffectPicker_Save()
	if not DiceMasterEffectPicker.selectedID and DiceMasterEffectPicker.customEffectID:GetText() == "" then
		UIErrorsFrame:AddMessage( "You must select an effect from the list or use a custom SpellVisualKit.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	local delay = tonumber( DiceMasterEffectPicker.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local effect
	if DiceMasterEffectPicker.parent then
		if DiceMasterEffectPicker.customEffect:GetChecked() then
			effect = {
				type = "effect";
				effectID = DiceMasterEffectPicker.customEffectID:GetText();
				effectName = "";
				target = DiceMasterEffectPicker.sendToTarget:GetChecked();
				delay = delay;
			}
		else	
			effect = {
				type = "effect";
				effectID = DiceMasterEffectPicker.selectedID;
				effectName = DiceMasterEffectPicker.selectedName;
				target = DiceMasterEffectPicker.sendToTarget:GetChecked();
				delay = delay;
			}
		end
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, effect )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, effect )
		end
		Me.ItemEditorEffectsList_Update()
	else
		if DiceMasterEffectPicker.customEffect:GetChecked() then
			Profile.traits[Me.editing_trait]["effects"]["effect"] = {
				effectID = DiceMasterEffectPicker.customEffectID:GetText();
				effectName = "";
				target = DiceMasterEffectPicker.sendToTarget:GetChecked();
				delay = delay;
			}
		else	
			Profile.traits[Me.editing_trait]["effects"]["effect"] = {
				effectID = DiceMasterEffectPicker.selectedID;
				effectName = DiceMasterEffectPicker.selectedName;
				target = DiceMasterEffectPicker.sendToTarget:GetChecked();
				delay = delay;
			}
		end
	end
	Me.EffectPicker_Close()
end

function Me.EffectPicker_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if not DiceMasterEffectPicker.selectedID and DiceMasterEffectPicker.customEffectID:GetText() == "" then
		UIErrorsFrame:AddMessage( "You must select an effect from the list or use a custom SpellVisualKit.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	local delay = tonumber( DiceMasterEffectPicker.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local effect
	if DiceMasterEffectPicker.customEffect:GetChecked() then
		effect = {
			type = "effect";
			effectID = DiceMasterEffectPicker.customEffectID:GetText();
			effectName = "";
			target = DiceMasterEffectPicker.sendToTarget:GetChecked();
			delay = delay;
		}
	else	
		effect = {
			type = "effect";
			effectID = DiceMasterEffectPicker.selectedID;
			effectName = DiceMasterEffectPicker.selectedName;
			target = DiceMasterEffectPicker.sendToTarget:GetChecked();
			delay = delay;
		}
	end
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = effect
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = effect
	end
	
	Me.ItemEditorEffectsList_Update()
	Me.EffectPicker_Close()
end

-------------------------------------------------------------------------------
-- Called when the user types into the search box.
--
function Me.EffectPicker_FilterChanged()
	local filter = DiceMasterEffectPicker.search:GetText():lower()
	-- searches must be at least 3 characters long
	if #filter < 3 then
		filteredList = nil;
		Me.EffectPicker_Update()
		return
	end
	-- build new list
	filteredList = {}
	for i = 1, #Me.effectList do
		if strfind( Me.effectList[i].name:lower(), filter ) then 
			tinsert( filteredList, Me.effectList[i] )
		end
	end
	Me.EffectPicker_Update()
end
    
-------------------------------------------------------------------------------
-- Close the effect picker window. Use this instead of a direct Hide()
--
function Me.EffectPicker_Close()
	DiceMasterEffectPicker.customEffect:SetChecked( false )
	DiceMasterEffectPicker.sendToTarget:SetChecked( false )
	DiceMasterEffectPicker.selectedID = nil
	DiceMasterEffectPicker.selectedName = nil
	
	DiceMasterEffectPicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the effect picker window.
--
function Me.EffectPicker_Open( parent )
	if parent then
		Me.CloseAllEditors( nil, nil, true )
		DiceMasterEffectPicker.parent = parent
		DiceMasterEffectPicker:ClearAllPoints()
		DiceMasterEffectPicker:SetPoint( "LEFT", parent, "RIGHT" )
		DiceMasterEffectPickerSaveButton:ClearAllPoints()
		DiceMasterEffectPickerSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterEffectPickerDeleteButton:ClearAllPoints()
		DiceMasterEffectPickerDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterEffectPickerDeleteButton:SetText( "Cancel" )
	else
		Me.CloseAllEditors()
		DiceMasterEffectPicker.parent = nil
		DiceMasterEffectPicker:ClearAllPoints()
		DiceMasterEffectPicker:SetPoint( "LEFT", DiceMasterTraitEditor, "RIGHT" )
		DiceMasterEffectPickerSaveButton:ClearAllPoints()
		DiceMasterEffectPickerSaveButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterEffectPickerDeleteButton:ClearAllPoints()
		DiceMasterEffectPickerDeleteButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterEffectPickerDeleteButton:SetText( "Delete" )
	end
	filteredList = nil
	
	DiceMasterEffectPickerSaveButton:SetScript( "OnClick", function()
		Me.EffectPicker_Save()
	end)
	
	DiceMasterEffectPicker.selectedID = nil
	DiceMasterEffectPicker.selectedName = nil
	
	Me.EffectPicker_Refresh()
	
	DiceMasterEffectPicker.search:SetText("")
	DiceMasterEffectPicker:Show()
end
