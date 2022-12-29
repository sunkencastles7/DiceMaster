-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Sound picker interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local filteredList = nil

function Me.SoundPicker_OnLoad(self)
	self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -48)
	self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 70)
	
	if self.NineSlice then
		self.NineSlice:SetFrameLevel(1)
	end

	for i = 2, 14 do
		local button = CreateFrame("Button", "DiceMasterSoundPickerButton"..i, DiceMasterSoundPicker, "DiceMasterSoundPickerButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterSoundPickerButton"..(i-1)], "BOTTOM");
	end
	
	Me.SoundPicker_Update()
end

function Me.SoundPickerButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		local list = filteredList or Me.soundList;
		DiceMasterSoundPicker.selectedID = list[ self.soundIndex ].id
		DiceMasterSoundPicker.selectedName = list[ self.soundIndex ].name
		Me.SoundPicker_Update()
	end
end

function Me.SoundPicker_Refresh( effectIndex )
	local sound
	if DiceMasterSoundPicker.parent and effectIndex then
		if Me.ItemEditing then
			sound = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			sound = Me.newItem.effects[ effectIndex ]
		end
		
		if sound then
			DiceMasterSoundPickerSaveButton:SetScript( "OnClick", function()
				Me.SoundPicker_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		sound = Profile.traits[Me.editing_trait]["effects"]["sound"] or nil
	end
	if not sound then
		sound = {
			soundID = 0;
			soundPath = "";
			range = 0;
		}
		if not DiceMasterSoundPicker.parent then
			Profile.traits[Me.editing_trait]["effects"]["sound"] = sound;
		end
		DiceMasterSoundPicker.areaSound:SetChecked( false )
		DiceMasterSoundPicker.range:SetText( 0 )
		DiceMasterSoundPicker.delay:SetText( 0 )
	else
		if ( sound.range and sound.range > 0 ) then
			DiceMasterSoundPicker.areaSound:SetChecked( true )
		end
		DiceMasterSoundPicker.range:SetText( sound.range or 0 )
		if ( sound.soundID and sound.soundID ~= 0 ) then
			DiceMasterSoundPicker.selectedID = sound.soundID
			DiceMasterSoundPicker.selectedName = sound.soundPath;
		end
		DiceMasterSoundPicker.delay:SetText( sound.delay )
	end
	Me.SoundPicker_Update()
end

function Me.SoundPicker_Update()
	local id, name;
	local list = filteredList or Me.soundList;
	local soundOffset = FauxScrollFrame_GetOffset(DiceMasterSoundPickerScrollFrame);
	
	for i=1,14,1 do
		soundIndex = soundOffset + i;
		local button = _G["DiceMasterSoundPickerButton"..i];
		button.soundIndex = soundIndex
		local info = list[soundIndex];
		if ( info ) then
			id 	 = info.id;
			name = info.name;
		end
		local buttonText = _G["DiceMasterSoundPickerButton"..i.."Name"];
		buttonText:SetText(name)
		
		-- Highlight the correct who
		if ( DiceMasterSoundPicker.selectedName == name ) then
			button:LockHighlight();
		else
			button:UnlockHighlight();
		end
		
		if ( soundIndex > #list ) then
			button:Hide();
		else
			button:Show();
		end
		
	end
	
	FauxScrollFrame_Update(DiceMasterSoundPickerScrollFrame, #list, 14, 16, nil, nil, nil, nil, nil, nil, true );
end

function Me.SoundPicker_TestSound( self )
	local list = filteredList or Me.soundList;
	-- Stop playing any current sounds.
	Me.SoundPicker_StopSound()
	-- Play the new sound.
	if list[self.soundIndex].id then
		local willPlay, soundHandle = PlaySound( list[self.soundIndex].id, nil, false )
		-- Save the new soundHandle.
		if willPlay then
			DiceMasterSoundPicker.soundHandle = soundHandle;
		end
	end
end

function Me.SoundPicker_PlaySound( data )
	local sound 
	if type( data ) == "table" and data.type and data.type == "sound" then
		sound = data
	else
		sound = Profile.traits[ data ]["effects"]["sound"]
	end
	
	if not sound then
		return
	end
	
	if ( sound and sound.range and sound.soundID ) then
		local range = sound.range or 0
		local soundKitID = sound.soundID;
		
		PlaySound( soundKitID, nil, false )
		if range ~= 0 then
			Me.SoundPicker_SendAreaSound( range, soundKitID )
		end
	end
end

function Me.SoundPicker_StopSound()
	if DiceMasterSoundPicker.soundHandle then
		StopSound( DiceMasterSoundPicker.soundHandle )
	end
end

function Me.SoundPicker_Delete()
	if not DiceMasterSoundPicker.parent then
		Profile.traits[Me.editing_trait]["effects"]["sound"] = nil
	end
	
	PlaySound(840); 
	Me.SoundPicker_Close()
end

function Me.SoundPicker_Save()
	if DiceMasterSoundPicker.soundHandle then
		StopSound( DiceMasterSoundPicker.soundHandle )
	end
	
	if not DiceMasterSoundPicker.selectedID then
		UIErrorsFrame:AddMessage( "You must select a sound file from the list.", 1.0, 0.0, 0.0 );
		return
	end
	
	local delay = tonumber( DiceMasterSoundPicker.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	if DiceMasterSoundPicker.parent then
		local sound = {
			type = "sound";
			soundID = DiceMasterSoundPicker.selectedID;
			soundPath = DiceMasterSoundPicker.selectedName;
			range = 0;
			delay = delay;
		}
		if DiceMasterSoundPicker.areaSound:GetChecked() then
			sound.range = tonumber( DiceMasterSoundPicker.range:GetText() ) or 0
		end
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, sound )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, sound )
		end
		Me.ItemEditorEffectsList_Update()
	else
		Profile.traits[Me.editing_trait]["effects"]["sound"] = {
			soundID = DiceMasterSoundPicker.selectedID;
			soundPath = DiceMasterSoundPicker.selectedName;
			range = 0;
			delay = delay;
		}
		if DiceMasterSoundPicker.areaSound:GetChecked() then
			local range = DiceMasterSoundPicker.range:GetText() or 0
			Profile.traits[Me.editing_trait]["effects"]["sound"].range = tonumber( range )
		end
	end
	Me.SoundPicker_Close()
end

function Me.SoundPicker_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if DiceMasterSoundPicker.soundHandle then
		StopSound( DiceMasterSoundPicker.soundHandle )
	end
	
	if not DiceMasterSoundPicker.selectedID then
		UIErrorsFrame:AddMessage( "You must select a sound file from the list.", 1.0, 0.0, 0.0 );
		return
	end
	
	local delay = tonumber( DiceMasterSoundPicker.delay:GetText() )
	
	if not delay or type( delay ) ~= "number" or delay <= 0 then
		delay = 0;
	end
	
	local sound = {
		type = "sound";
		soundID = DiceMasterSoundPicker.selectedID;
		soundPath = DiceMasterSoundPicker.selectedName;
		range = 0;
		delay = delay;
	}
	
	if DiceMasterSoundPicker.areaSound:GetChecked() then
		sound.range = tonumber( DiceMasterSoundPicker.range:GetText() ) or 0
	end
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = sound
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = sound
	end
	
	Me.ItemEditorEffectsList_Update()
	Me.SoundPicker_Close()
end

function Me.SoundPicker_SendAreaSound( range, soundKitID )

	if not IsInGroup( LE_PARTY_CATEGORY_HOME ) or not range or not soundKitID then 
		return 
	end
	
	local msg = Me:Serialize( "SOUND", {
		so = tonumber( soundKitID );
	})
	
	local y1, x1, _, instance1 = UnitPosition( "player" )
	for i = 1, GetNumGroupMembers( 1 ) do
		local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
		local y2, x2, _, instance2 = UnitPosition( "raid" .. i )
		if not( IsInRaid( 1 ) ) then
			y2, x2, _, instance2 = UnitPosition( "party" .. i )
		end
		local distance = instance1 == instance2 and ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
		if type( distance )=="number" and tonumber( distance ) <= range and online then
			if IsInRaid( 1 ) then
				Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName( "raid"..i ), "NORMAL" )
			else
				Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName( "party" .. i ), "NORMAL" )
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Called when the user types into the search box.
--
function Me.SoundPicker_FilterChanged()
	local filter = DiceMasterSoundPicker.search:GetText():lower()
	-- searches must be at least 3 characters long
	if #filter < 3 then
		filteredList = nil;
		Me.SoundPicker_Update()
		return
	end
	-- build new list
	filteredList = {}
	for i = 1, #Me.soundList do
		if strfind( Me.soundList[i].name:lower(), filter ) then 
			tinsert( filteredList, Me.soundList[i] )
		end
	end
	Me.SoundPicker_Update()
end
    
-------------------------------------------------------------------------------
-- Close the sound picker window. Use this instead of a direct Hide()
--
function Me.SoundPicker_Close()
	DiceMasterSoundPicker.selectedID = nil
	DiceMasterSoundPicker.selectedName = nil
	
	DiceMasterSoundPicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the sound picker window.
--
function Me.SoundPicker_Open( parent )
	if parent then
		Me.CloseAllEditors( nil, nil, true )
		DiceMasterSoundPicker.parent = parent
		DiceMasterSoundPicker:SetPoint( "LEFT", parent, "RIGHT" )
		DiceMasterSoundPickerSaveButton:ClearAllPoints()
		DiceMasterSoundPickerSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterSoundPickerDeleteButton:ClearAllPoints()
		DiceMasterSoundPickerDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterSoundPickerDeleteButton:SetText( "Cancel" )
	else
		Me.CloseAllEditors()
		DiceMasterSoundPicker.parent = nil
		DiceMasterSoundPicker:SetPoint( "LEFT", DiceMasterTraitEditor, "RIGHT" )
		DiceMasterSoundPickerSaveButton:ClearAllPoints()
		DiceMasterSoundPickerSaveButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterSoundPickerDeleteButton:ClearAllPoints()
		DiceMasterSoundPickerDeleteButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterSoundPickerDeleteButton:SetText( "Delete" )
	end
	filteredList = nil
	
	DiceMasterSoundPickerSaveButton:SetScript( "OnClick", function()
		Me.SoundPicker_Save()
	end)
	
	DiceMasterSoundPicker.selectedID = nil
	DiceMasterSoundPicker.selectedName = nil
	
	Me.SoundPicker_Refresh()
	
	DiceMasterSoundPicker.search:SetText("")
	DiceMasterSoundPicker:Show()
end

---------------------------------------------------------------------------
-- Received an area sound message.
--	so = soundKitID				number

function Me.SoundPicker_OnSoundMessage( data, dist, sender )	
 
	if sender == UnitName( "player" ) or ( not UnitInRaid( sender ) and not UnitInParty( sender ) ) or not Me.db.global.allowSounds then
		return
	end
 
	-- sanitize message
	if not data.so then
		return
	end
	
	local soundKitID = tonumber( data.so )
	PlaySound( soundKitID, nil, false )
	
end
