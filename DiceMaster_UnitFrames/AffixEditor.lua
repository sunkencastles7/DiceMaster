-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Affix editor interface.
--

local Me = DiceMaster4

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
}

Me.DICEMASTER_BACKDROP_ZONES = {
	["Eastern Kingdoms"] = {
		"Arathi Highlands",
		"Badlands",
		"Blasted Lands",
		"Burning Steppes",
		"Deadwind Pass",
		"Dun Morogh",
		"Duskwood",
		"Eastern Plaguelands",
		"Elwynn Forest",
		"Eversong Woods",
		"Ghostlands",
		"Gilneas",
		"Hillsbrad Foothills",
		"Hinterlands",
		"Isle of Quel'Danas",
		"Loch Modan",
		"Redridge Mountains",
		"Searing Gorge",
		"Silverpine Forest",
		"Stranglethorn Vale",
		"Swamp of Sorrows",
		"Tirisfal Glades",
		"Tol Barad",
		"Twilight Highlands",
		"Vashj'ir",
		"Western Plaguelands",
		"Westfall",
		"Wetlands",
	},
	["Kalimdor"] = {
		"Ahn'Qiraj",
		"Ashenvale",
		"Azshara",
		"Azuremyst Isle",
		"Barrens",
		"Bloodmyst Isle",
		"Darkshore",
		"Desolace",
		"Durotar",
		"Dustwallow Marsh",
		"Echo Isles",
		"Felwood",
		"Feralas",
		"Moonglade",
		"Mount Hyjal",
		"Mulgore",
		"Silithus",
		"Stonetalon Mountains",
		"Tanaris",
		"Teldrassil",
		"Thousand Needles",
		"Uldum",
		"Un'goro Crater",
		"Winterspring",
	},
	["Outland"] = {
		"Blade's Edge Mountains",
		"Hellfire Peninsula",
		"Nagrand",
		"Netherstorm",
		"Shadowmoon Valley",
		"Terokkar Forest",
		"Zangarmarsh",
	},
	["Northrend"] = {
		"Borean Tundra",
		"Crystalsong Forest",
		"Dragonblight",
		"Grizzly Hills",
		"Howling Fjord",
		"Icecrown",
		"Sholazar Basin",
		"Storm Peaks",
		"Zul'Drak",
	},
	["Pandaria"] = {
		"Dread Wastes",
		"Krasarang Wilds",
		"Kun-Lai Summit",
		"Jade Forest",
		"Townlong Steppes",
		"Vale of Eternal Blossoms",
		"Valley of the Four Winds",
	},
	["Draenor"] = {
		"Frostfire Ridge",
		"Gorgrond",
		"Shadowmoon Valley",
		"Spires of Arak",
		"Talador",
		"Tanaan Jungle",
	},
	["Broken Isles"] = {
		"Argus",
		"Azsuna",
		"Broken Shore",
		"Dalaran",
		"Highmountain",
		"Stormheim",
		"Suramar",
		"Val'sharah",
	},
	["Kul Tiras/Zandalar"] = {
		"Boralus",
		"Drustvar",
		"Stormsong Valley",
		"Tiragarde Sound",
		"Dazar'alor",
		"Mechagon",
		"Nazjatar",
		"Nazmir",
		"Ny'alotha",
		"Vol'dun",
		"Zuldazar",
	},
	["Shadowlands"] = {
		"Ardenweald",
		"Bastion",
		"Maldraxxus",
		"The Maw",
		"Revendreth",
		"Torghast",
	},
	["Other"] = {
		"Default (None)",
		"Abyssal Maw",
		"Deepholm",
		"Emerald Dream",
		"Emerald Nightmare",
		"Firelands",
		"Kezan",
		"Maelstrom",
		"Skywall",
		"Wandering Isle",
	},
}

-------------------------------------------------------------------------------
-- StaticPopupDialogs
--

StaticPopupDialogs["DICEMASTER4_SENDTALKINGHEAD"] = {
  text = "Send Talking Head Dialogue",
  button1 = "Send",
  button2 = "Cancel",
  OnAccept = function (self, data)
    local text = self.editBox:GetText()
	DiceMasterTalkingHeadFrame_Init( text, Me.talkingHeadTextureKit, data )
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_OVERWRITEUNIT"] = {
  text = "A unit with this name already exists. Are you sure you want to overwrite it?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self)
	Me.AffixEditor_SaveUnit()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_DELETEUNIT"] = {
  text = "Are you sure you want to delete this unit?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function (self, data)
	Me.AffixEditor_DeleteUnit( data )
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- UIDropDownMenu for Roll Types
--

function Me.RollTypePickerDropDown_OnClick( self, arg1, arg2, checked )
	UIDropDownMenu_SetText( DiceMasterAffixEditor.rollType, self:GetText() )
	CloseDropDownMenus()
end

function Me.RollTypePickerDropDown_OnLoad( frame, level, menuList )
	local info = UIDropDownMenu_CreateInfo()
	
	if level == 1 then
		info.notCheckable = true;
		info.text = "Combat Actions"
		info.disabled = false;
		info.notClickable = false;
		info.hasArrow = true;
		info.menuList = "Combat Actions"
		UIDropDownMenu_AddButton(info)
		info.text = "Skills"
		info.menuList = "Skills"
		UIDropDownMenu_AddButton(info)
		info.text = "Saving Throws"
		info.menuList = "Saving Throws"
		UIDropDownMenu_AddButton(info)
		info.notCheckable = false;
		info.hasArrow = false;
		info.text = "(None)"
		info.menuList = nil;
		info.arg1 = "(None)"
		info.func = Me.RollTypePickerDropDown_OnClick;
		info.checked = false;
		if UIDropDownMenu_GetText( frame ) == info.text then
			info.checked = true;
		end
		UIDropDownMenu_AddButton(info)
	elseif menuList then
		for i = 1,#Me.RollList[menuList] do
			info.text = Me.RollList[menuList][i].name
			info.arg1 = Me.RollList[menuList][i].name
			info.func = Me.RollTypePickerDropDown_OnClick;
			info.notCheckable = false;
			info.tooltipTitle = Me.RollList[menuList][i].name;
			info.tooltipText = Me.RollList[menuList][i].desc;
			info.tooltipOnButton = true;
			info.checked = false;
			if UIDropDownMenu_GetText( frame ) == info.text then
				info.checked = true;
			end
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

-------------------------------------------------------------------------------
-- UIDropDownMenu for Backdrops
--

function Me.BackdropPickerDropDown_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(DiceMasterAffixEditor.backdrop, self:GetText())
	Me.UnitEditing.zone = self:GetText()
	Me.UnitEditing.continent = arg1
	Me.AffixEditor_Save()
end

local function CreateContinentMenu(dropdown, level, continent)
	local info = UIDropDownMenu_CreateInfo();
	info.text = continent;
	info.notCheckable = true;
	info.hasArrow = true;
	info.keepShownOnClick = true;
	info.menuList = continent;
	UIDropDownMenu_AddButton(info, level);
end


function Me.BackdropPickerDropDown_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()

	if level == 1 then
		CreateContinentMenu(self, level, "Eastern Kingdoms");
		CreateContinentMenu(self, level, "Kalimdor");
		CreateContinentMenu(self, level, "Outland");
		CreateContinentMenu(self, level, "Northrend");
		CreateContinentMenu(self, level, "Pandaria");
		CreateContinentMenu(self, level, "Draenor");
		CreateContinentMenu(self, level, "Broken Isles");
		CreateContinentMenu(self, level, "Kul Tiras/Zandalar");
		CreateContinentMenu(self, level, "Shadowlands");
		CreateContinentMenu(self, level, "Other");
		if Me.DICEMASTER_CUSTOM_UNIT_TEXTURES then
			for k, v in pairs( Me.DICEMASTER_CUSTOM_UNIT_TEXTURES ) do
				CreateContinentMenu(self, level, k);
			end
		end
	elseif menuList then
		for i = 1, #Me.DICEMASTER_BACKDROP_ZONES[ menuList ] do
			local info = UIDropDownMenu_CreateInfo();
			info.text = Me.DICEMASTER_BACKDROP_ZONES[ menuList ][i];
			
			if info.text == "Shadowmoon Valley" then
				info.text = info.text .. " (" .. menuList .. ")";
			end
			
			info.func = Me.BackdropPickerDropDown_OnClick;
			info.checked = Me.UnitEditing.zone == info.text;
			info.arg1 = menuList;
			UIDropDownMenu_AddButton(info, level);
		end
	end
end

-------------------------------------------------------------------------------
-- When the model has been changed.
--
function Me.AffixEditor_UpdateModel()
	local model = DiceMasterAffixEditor.Model
	local framedata = Me.UnitEditing:GetData()
	
	model.animation = framedata.animations["PreAggro"].id or 0
	if framedata.healthCurrent == 0 then
		model:SetAnimation( Me.UnitEditing.animations["Dead"].id or 6 )
	elseif model:HasAnimation( model.animation ) then
		model:SetAnimation( model.animation )
	else
		--UIDropDownMenu_SetText(DiceMasterAffixEditor.animation, "Stand")
		model.animation = Me.UnitEditing.animations["PreAggro"].id or 0
		model:SetAnimation( Me.UnitEditing.animations["PreAggro"].id or 0 )
	end
	
	model.rotation = framedata.modelData.ro
	model.zoomLevel = framedata.modelData.zl
	model.cameraX = framedata.modelData.px
	model.cameraY = framedata.modelData.py
	model.cameraZ = framedata.modelData.pz
	
	model:SetRotation( model.rotation )
	model:SetPosition( model.cameraX, model.cameraY, model.cameraZ )
	model:SetPortraitZoom( model.zoomLevel )
	
	if Me.UnitSlot then
		Me.UnitSlot.Model:SetDisplayInfo( model:GetDisplayInfo() )
	end
	
	DiceMasterAffixEditor.unitSymbol.State = framedata.symbol
	
	Me.AffixEditor_Save()
end

-------------------------------------------------------------------------------
-- Refresh the affix editor window.
--
function Me.AffixEditor_Refresh()
	local editor = DiceMasterAffixEditor
	
	local framedata = Me.UnitEditing:GetData()
	
	editor.unitName:SetText( framedata.name )
	editor.enable:SetChecked( framedata.state )
	editor.showCastBar:SetChecked( framedata.castEnabled )
	editor.Model:SetDisplayInfo( framedata.model )
	
	if framedata.healthCurrent == 0 then
		editor.Model:SetAnimation( Me.UnitEditing.animations["Dead"].id or 6 )
		editor.Model.animation = Me.UnitEditing.animations["Dead"].id or 6
		--UIDropDownMenu_SetText(editor.animation, "Dead")
	else
		editor.Model:SetAnimation( framedata.animations["PreAggro"].id or 0)
		editor.Model.animation = Me.UnitEditing.animations["PreAggro"].id or 0
	end
	
	UIDropDownMenu_SetText(editor.backdrop, framedata.zone)
	
	editor.unitSymbol.State = framedata.symbol
	if framedata.symbol < 9 then
		editor.unitSymbol:SetNormalTexture( "Interface/TARGETINGFRAME/UI-RaidTargetingIcon_" .. framedata.symbol )
	else
		editor.unitSymbol:SetNormalTexture( "Interface/Vehicles/UI-VEHICLES-RAID-ICON" )
	end
end

-------------------------------------------------------------------------------
-- Save the unit.
--
function Me.AffixEditor_SaveUnit()
	local editor = DiceMasterAffixEditor
	if not editor.Model:GetDisplayInfo() then return end
	local data = {}
	
	data.na = editor.unitName:GetText()
	data.md = editor.Model:GetDisplayInfo()
	data.an = {
		["PreAggro"] = { id = 0, anim = "Stand" },
		["Aggro"] = { id = 127, anim = "Birth" },
		["Melee Attack"] = { id = 16, anim = "AttackUnarmed" },
		["Ranged Attack"] = { id = 29, anim = "ReadyBow" },
		["Spell Attack"] = { id = 53, anim = "SpellCastDirected" },
		["Wound"] = { id = 8, anim = "StandWound" },
		["Death"] = { id = 1, anim = "Death" },
		["Dead"] = { id = 6, anim = "Dead" },
	}
	if Me.UnitEditing.animations then
		for k, v in pairs( Me.UnitEditing.animations ) do
			if data.an[k] then
				data.an[k] = v;
			end
		end
	end
	data.sy = editor.unitSymbol.State
	data.hc = Me.UnitEditing.healthCurrent
	if data.hc == 0 then
		data.an["Dead"] = { id = 6, name = "Dead" }
	end
	data.hm = Me.UnitEditing.healthMax
	data.ar = Me.UnitEditing.armor
	data.ce = Me.UnitEditing.castEnabled
	data.ct = Me.UnitEditing.castText
	data.cc = Me.UnitEditing.castCurrent
	data.cm = Me.UnitEditing.castMax
	data.ch = Me.UnitEditing.castType
	data.mx = {}
	data.mx.px, data.mx.py, data.mx.pz = editor.Model:GetPosition()
	data.mx.ro = editor.Model.rotation
	data.mx.zl = editor.Model.zoomLevel or editor.Model.minZoom
	data.st = editor.enable:GetChecked()
	data.ba = Me.db.global.allowBuffs
	data.bl = Me.db.global.bloodEffects
	--data.buffs = Me.UnitEditing.buffsActive or {}
	data.vs = true;
	data.zo = Me.UnitEditing.zone
	data.co = Me.UnitEditing.continent
	data.ra = Me.db.global.allowAssistantTalkingHeads
	
	DiceMaster4UF_Saved.SavedUnits[data.na] = data
	if data.sy < 9 then
		Me.PrintMessage("|TInterface/TARGETINGFRAME/UI-RaidTargetingIcon_"..data.sy..":16|t "..data.na.." saved.", "SYSTEM");
	else
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:16|t "..data.na.." saved.", "SYSTEM");
	end
end

-------------------------------------------------------------------------------
-- Delete the unit.
--
function Me.AffixEditor_DeleteUnit( unit )
	
	Me.UnitEditing:Reset()
	Me.AffixEditor_Refresh()
	Me.AffixEditor_RefreshSlots()
	
	if DiceMaster4UF_Saved.SavedUnits[unit] then
		if DiceMaster4UF_Saved.SavedUnits[unit].sy then
			Me.PrintMessage("|TInterface/TARGETINGFRAME/UI-RaidTargetingIcon_"..DiceMaster4UF_Saved.SavedUnits[unit].sy..":16|t "..unit.." saved.", "SYSTEM");
		else
			Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:16|t "..unit.." saved.", "SYSTEM");
		end
		DiceMaster4UF_Saved.SavedUnits[unit] = nil;
	end
end

-------------------------------------------------------------------------------
-- Save changes made to the unit frame.
--
function Me.AffixEditor_Save()
	
	if not Me.UnitEditing then return end

	local editor = DiceMasterAffixEditor
	local data = {}
	
	data.na = editor.unitName:GetText()
	data.md = editor.Model:GetDisplayInfo()
	data.an = editor.Model.animation or 0
	data.an = {
		["PreAggro"] = { id = 0, anim = "Stand" },
		["Aggro"] = { id = 127, anim = "Birth" },
		["Melee Attack"] = { id = 16, anim = "AttackUnarmed" },
		["Ranged Attack"] = { id = 29, anim = "ReadyBow" },
		["Spell Attack"] = { id = 53, anim = "SpellCastDirected" },
		["Wound"] = { id = 8, anim = "StandWound" },
		["Death"] = { id = 1, anim = "Death" },
		["Dead"] = { id = 6, anim = "Dead" },
	}
	if Me.UnitEditing.animations then
		for k, v in pairs( Me.UnitEditing.animations ) do
			if data.an[k] then
				data.an[k] = v;
			end
		end
	end
	data.sy = editor.unitSymbol.State
	data.hc = Me.UnitEditing.healthCurrent
	if data.hc == 0 then
		data.an["Dead"] = { id = 6, name = "Dead" }
	end
	data.hm = Me.UnitEditing.healthMax
	data.ar = Me.UnitEditing.armor
	data.ce = Me.UnitEditing.castEnabled
	data.ct = Me.UnitEditing.castText
	data.cc = Me.UnitEditing.castCurrent
	data.cm = Me.UnitEditing.castMax
	data.ch = Me.UnitEditing.castType
	data.mx = {}
	data.mx.px, data.mx.py, data.mx.pz = editor.Model:GetPosition()
	data.mx.ro = editor.Model.rotation
	data.mx.zl = editor.Model.zoomLevel or editor.Model.minZoom
	data.st = editor.enable:GetChecked()
	data.ba = Me.db.global.allowBuffs
	data.bl = Me.db.global.bloodEffects
	data.buffs = Me.UnitEditing.buffsActive or {}
	data.ra = Me.db.global.allowAssistantTalkingHeads
	
	Me.UnitEditing:SetData( data )
	Me.UpdateUnitFrames()
end

-------------------------------------------------------------------------------
-- Dropdown handlers for the Talking Heads menu.
--
function Me.AffixEditorTalkingHeads_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText(DiceMasterTalkingHeadOptionsDropdown, self:GetText())
	Me.talkingHeadTextureKit = self:GetText()
end

function Me.AffixEditorTalkingHeads_OnLoad()
	local options = {
		"Normal",
		"Alliance",
		"Horde",
		"Neutral",
	}
	
	for i = 1, #options do
       local info      = UIDropDownMenu_CreateInfo();
       info.text       = options[i];
       info.func       = Me.AffixEditorTalkingHeads_OnClick;
	   info.checked    = Me.talkingHeadTextureKit == options[i];
       UIDropDownMenu_AddButton(info); 
	end
end

-------------------------------------------------------------------------------
-- Dropdown handlers for the load affixes menu.
--
function Me.AffixEditorLoadDropDown_OnClick(self, arg1, arg2, checked)
	Me.UnitEditing:SetData( arg1 )
	Me.AffixEditor_Refresh()
	Me.AffixEditor_RefreshSlots()
end

function Me.AffixEditorLoadDropDown_OnLoad()
	for k,v in pairs(DiceMaster4UF_Saved.SavedUnits) do
       local info      = UIDropDownMenu_CreateInfo();
	   info.checked	   = false;
	   if v.symbol and v.symbol < 9 then
		info.icon	   = "Interface/TARGETINGFRAME/UI-RaidTargetingIcon_"..v.symbol;
	   end
       info.text       = k;
       info.value      = 1;
	   info.notCheckable = true;
	   info.arg1	   = v;
       info.func       = Me.AffixEditorLoadDropDown_OnClick;
       UIDropDownMenu_AddButton(info); 
	end
end
    
-------------------------------------------------------------------------------
-- Close the affix editor window. Use this instead of a direct Hide()
--
function Me.AffixEditor_Close( noSound )
	Me.AffixEditor_Save()
	Me.UnitEditing = nil;
	if not noSound then
		PlaySound(680)
	end
	Me.ModelPicker_Close()
	Me.AnimationPicker_Close()					  
	DiceMasterUnitFramesBuffEditor:Hide()
	DiceMasterAffixEditor:Hide()
end

-------------------------------------------------------------------------------
-- Refresh the unit frame slots.
--
function Me.AffixEditor_RefreshSlots()
	for i = 1, 6 do
		local framedata = DiceMasterUnitsPanel.unitframes[i]:GetData()
		local activeUnit = _G["DiceMasterAffixEditorActiveUnit".. i]
		
		if framedata.visible then
			activeUnit.Model:SetDisplayInfo( framedata.model )
			activeUnit.UnitName:SetText( framedata.name )
			activeUnit:Enable()
		else
			activeUnit.Model:SetDisplayInfo( 1 )
			activeUnit.UnitName:SetText( nil )
			activeUnit:Disable()
		end
		
		if DiceMasterUnitsPanel.unitframes[i] == Me.UnitEditing then
			activeUnit.Model.Selected:Show()
			Me.UnitSlot = activeUnit
		else
			activeUnit.Model.Selected:Hide()
		end
	end
end
    
-------------------------------------------------------------------------------
-- Open the affix editor window.
--
function Me.AffixEditor_Open( frame, noSound )
	if DiceMasterAffixEditor:IsShown() then
		Me.AffixEditor_Close( true )
	end
	
	Me.UnitEditing = frame or nil;
	Me.AffixEditor_Refresh()
	Me.AffixEditor_RefreshSlots()
	
	DiceMasterAffixEditor.CloseButton:SetScript("OnClick",Me.AffixEditor_Close)

	DiceMaster4UF_Saved.SavedUnits = DiceMaster4UF_Saved.SavedUnits or {}
	if not noSound then
		PlaySound(679)
	end
	DiceMasterAffixEditor:Show()
end
