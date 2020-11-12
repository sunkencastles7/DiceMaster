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
	self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 50)
	
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

function Me.SoundPicker_Refresh()
	local sound = Profile.traits[Me.editing_trait].playsounds or nil
	if not sound then
		sound = {
			soundID = 0;
			soundPath = "";
			range = 0;
			blank = true;
		}
		Profile.traits[Me.editing_trait].playsounds = sound;
		DiceMasterSoundPicker.areaSound:SetChecked( false )
		DiceMasterSoundPicker.range:SetText( 0 )
	else
		if ( sound.range and sound.range > 0 ) then
			DiceMasterSoundPicker.areaSound:SetChecked( true )
		end
		DiceMasterSoundPicker.range:SetText( sound.range or 0 )
		if ( sound.soundID and sound.soundID ~= 0 ) then
			DiceMasterSoundPicker.selectedID = sound.soundID
			DiceMasterSoundPicker.selectedName = sound.soundPath;
		end
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

function Me.SoundPicker_PlaySound( traitIndex )
	local sound = Profile.traits[ traitIndex ].playsounds
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
	Profile.traits[Me.editing_trait].playsounds = nil
	
	PlaySound(840); 
	Me.SoundPicker_Close()
end

function Me.SoundPicker_Save()
	if DiceMasterSoundPicker.soundHandle then
		StopSound( DiceMasterSoundPicker.soundHandle )
	end
	
	if not DiceMasterSoundPicker.selectedID then
		UIErrorsFrame:AddMessage( "You must select a sound file from the list.", 1.0, 0.0, 0.0, 53, 5 );
		return
	end
	
	Profile.traits[Me.editing_trait].playsounds = {
		soundID = DiceMasterSoundPicker.selectedID;
		soundPath = DiceMasterSoundPicker.selectedName;
		range = 0;
		blank = false;
	}
	if DiceMasterSoundPicker.areaSound:GetChecked() then
		local range = DiceMasterSoundPicker.range:GetText() or 0
		Profile.traits[Me.editing_trait].playsounds.range = tonumber( range )
	end
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
		local distance = instance1 == instance2 and ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
		if type( distance )=="number" and tonumber( distance ) <= range and online then
			Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName( "raid"..i ), "NORMAL" )
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
function Me.SoundPicker_Open( frame )
	Me.EffectPicker_Close()
	Me.buffeditor:Hide()
	Me.removebuffeditor:Hide()
	Me.setdiceeditor:Hide()
	if not frame then
		frame = DiceMasterTraitEditor;
	end
	DiceMasterSoundPicker:ClearAllPoints()
	DiceMasterSoundPicker:SetPoint( "LEFT", frame, "RIGHT" )
	filteredList = nil
	
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
 
	if sender == UnitName( "player" ) or not UnitInParty( sender ) or not Me.db.global.allowSounds then
		return
	end
 
	-- sanitize message
	if not data.so then
		return
	end
	
	local soundKitID = tonumber( data.so )
	PlaySound( soundKitID, nil, false )
	
end
