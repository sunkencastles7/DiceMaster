-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Sound picker interface.
--

local Me = DiceMaster4

local filteredList = nil

function Me.SoundPicker_OnLoad(self)
	self.Inset:SetPoint("TOPLEFT", self, "TOPLEFT", 3, -32)
	self.Inset:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 100)

	for i = 2, 15 do
		local button = CreateFrame("Button", "DiceMasterSoundPickerButton"..i, DiceMasterSoundPicker, "DiceMasterSoundPickerButtonTemplate");
		button:SetID(i)
		button:SetPoint("TOP", _G["DiceMasterSoundPickerButton"..(i-1)], "BOTTOM");
	end
	
	Me.SoundPicker_Update()
end

function Me.SoundPickerButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		DiceMasterSoundPicker.selected = self.soundIndex
		Me.SoundPicker_Update()
	end
end

function Me.SoundPicker_Update()
	local id, name;
	local list = filteredList or Me.soundList;
	local soundOffset = FauxScrollFrame_GetOffset(DiceMasterSoundPickerScrollFrame);
	
	for i=1,15,1 do
		soundIndex = soundOffset + i;
		local button = _G["DiceMasterSoundPickerButton"..i];
		button.soundIndex = soundIndex
		local info = list[soundIndex];
		if ( info ) then
			id 	 = info.id;
			name = info.name;
		end
		--local buttonText = _G["DiceMasterSoundPickerButton"..i.."ID"];
		--buttonText:SetText(id)
		local buttonText = _G["DiceMasterSoundPickerButton"..i.."Name"];
		buttonText:SetText(name)
		
		-- Highlight the correct who
		if ( DiceMasterSoundPicker.selected == soundIndex ) then
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
	
	if DiceMasterSoundPicker.selected then
		DiceMasterSoundPicker.selectedName = Me.soundList[DiceMasterSoundPicker.selected].name;
	end
	
	FauxScrollFrame_Update(DiceMasterSoundPickerScrollFrame, #list, 15, 14, nil, nil, nil, nil, nil, nil, true );
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

function Me.SoundPicker_StopSound()
	if DiceMasterSoundPicker.soundHandle then
		StopSound( DiceMasterSoundPicker.soundHandle )
	end
end

function Me.SoundPicker_BindSound( self, sound )
	local list = filteredList or Me.soundList;
	if list[ DiceMasterSoundPicker.selected ].id then
		self:SetText( list[ DiceMasterSoundPicker.selected ].name )
		Me.UnitEditing.sounds[ sound ] = list[ DiceMasterSoundPicker.selected ];
	end
end

function Me.SoundPicker_UpdateBindings()
	if Me.UnitEditing and Me.UnitEditing.sounds then
		for k, v in pairs( Me.UnitEditing.sounds ) do
			if _G["DiceMasterSoundPicker"..k.."Sound"] then
				local button = _G["DiceMasterSoundPicker"..k.."Sound"]
				button:SetText( v.name )
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
	Me.SoundEditing = nil;
	DiceMasterSoundPicker:Hide()
end
    
-------------------------------------------------------------------------------
-- Open the sound picker window.
--
function Me.SoundPicker_Open( frame )
	Me.ModelPicker_Close()
	DiceMasterSoundPicker:ClearAllPoints()
	DiceMasterSoundPicker:SetPoint( "LEFT", frame, "RIGHT" )
	filteredList = nil
	
	DiceMasterSoundPicker.search:SetText("")
	DiceMasterSoundPicker:Show()
	
	Me.SoundPicker_UpdateBindings()
end
