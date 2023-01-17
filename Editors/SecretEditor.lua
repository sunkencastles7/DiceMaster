-------------------------------------------------------------------------------
-- Dice Master (C) 2021 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Secret editor interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local TRIGGER_CONDITIONS = {
	"...I roll for...",
	"...I roll a critical success for...",
	"...I roll a critical failure for...",
	"...the DM rolls for...",
	"...the DM rolls a critical success for...",
	"...the DM rolls a critical failure for...",
	"...anyone rolls for...",
	"...anyone rolls a critical success for...",
	"...anyone rolls a critical failure for...",
	"...I use the trait...",
	"...I reach 0 health.",
	"...I heal myself or am healed.",
}

local TRIGGER_EVENTS = {
	"PLAYER_ROLL",
	"PLAYER_ROLL_CRITICAL_SUCCESS",
	"PLAYER_ROLL_CRITICAL_FAILURE",
	"DM_ROLL",
	"DM_ROLL_CRITICAL_SUCCESS",
	"DM_ROLL_CRITICAL_FAILURE",
	"ROLL",
	"ROLL_CRITICAL_SUCCESS",
	"ROLL_CRITICAL_FAILURE",
	"PLAYER_USE_TRAIT",
	"PLAYER_KNOCKOUT",
	"PLAYER_HEALED",
}

local function GetConditionsList()
	if not Me.SecretEditor.conditionsList then
		return "(None)"
	end
	
	local conditionsList = nil
	local count = 0
	for k, v in pairs( Me.SecretEditor.conditionsList ) do
		if k then
			count = count + 1
		end
		k = k:gsub( "%.", "" )
		if count == 1 then
			conditionsList = k
		else
			conditionsList = conditionsList .. ", " .. k
		end
	end
	return conditionsList
end

local function TriggerSecret( secret, secretIndex, traitIndex )
	if not secret or not secretIndex or type(secretIndex)~="number" or secretIndex < 1 or secretIndex > 3 or not traitIndex or type(traitIndex)~="number" or traitIndex > 5 or traitIndex < 1 then return end
	
	local desc = secret.desc1
	local secretButton = "one"
	if secretIndex == 2 then
		desc = secret.desc2
		secretButton = "two"
	elseif secretIndex == 3 then
		desc = secret.desc3
		secretButton = "three"
	end
	
	if not( DiceMasterChargesFrame.traits[traitIndex].secret[secretButton]:IsShown() ) then
		return
	end
	
	local msg = Me:Serialize( "SECRET", {
		de = tostring( desc );
		si = tonumber( secretIndex );
		ti = tonumber( traitIndex );
	})
	
	DiceMasterChargesFrame.traits[traitIndex].secret[secretButton]:Hide()
	Profile.traits[traitIndex]["secret"..tostring(secretIndex).."Enabled"] = false;
	
	if IsInRaid( LE_PARTY_CATEGORY_HOME ) then
		Me:SendCommMessage( "DCM4", msg, "RAID", nil, "NORMAL" )
	elseif IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		Me:SendCommMessage( "DCM4", msg, "PARTY", nil, "NORMAL" )
	else
		Me:SendCommMessage( "DCM4", msg, "WHISPER", UnitName("player"), "NORMAL" )
	end
	Me.TraitEditor_Refresh()
end

function Me.SecretEditor_EnableSecret( traitIndex )
	local secret = Profile.traits[ traitIndex ]["effects"]["secret"]
	DiceMasterChargesFrame.traits[ traitIndex ].secret:Show()
	
	if not Profile.traits[ traitIndex ].secret1Enabled or not Profile.traits[ traitIndex ].secret2Enabled or not Profile.traits[ traitIndex ].secret3Enabled then
		Me.PrintMessage("|cFFFFFF00You have enabled |cFF67BCFF["..Profile.traits[ traitIndex ].name.."]|r's |TInterface/AddOns/DiceMaster/Texture/secret-icon:12|t |cFFFFFFFFSecret!|r|r", "SYSTEM")
	end
	
	Profile.traits[ traitIndex ].secret1Active = false;
	Profile.traits[ traitIndex ].secret2Active = false;
	Profile.traits[ traitIndex ].secret3Active = false;
	
	if secret.conditions1 and next(secret.conditions1)~=nil then
		Profile.traits[ traitIndex ].secret1Enabled = true;
		DiceMasterChargesFrame.traits[ traitIndex ].secret.one:Show()
	end
	if secret.conditions2 and next(secret.conditions2)~=nil then
		Profile.traits[ traitIndex ].secret2Enabled = true;
		DiceMasterChargesFrame.traits[ traitIndex ].secret.two:Show()
	end
	if secret.conditions3 and next(secret.conditions3)~=nil then
		Profile.traits[ traitIndex ].secret3Enabled = true;
		DiceMasterChargesFrame.traits[ traitIndex ].secret.three:Show()
	end
	
	Me.TraitEditor_Refresh()
	if IsInRaid( LE_PARTY_CATEGORY_HOME ) then
		Me.Inspect_SendTraits( "RAID", nil )
	elseif IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		Me.Inspect_SendTraits( "PARTY", nil )
	end
end

function Me.SecretEditor_OnEvent( event, arg1, arg2 )
	local triggerCondition = nil
	for i = 1, #TRIGGER_EVENTS do
		if TRIGGER_EVENTS[i] == event then
			triggerCondition = TRIGGER_CONDITIONS[i]:gsub("%.","")
		end
	end
	
	for i = 1,#Profile.traits do
		local secret = Profile.traits[i]["effects"]["secret"]
		if secret then
			for var = 1, 3 do
				local conditions = secret["conditions"..tostring(var)]
				if conditions and type(conditions)=="table" then
					for k,v in pairs(conditions) do
						if k:find(triggerCondition) then
							if event:find("ROLL") then
								local rollType = strmatch(k, "for (.*)")
								if arg1 == rollType then
									TriggerSecret( secret, var, i )
								end
							elseif event == "PLAYER_USE_TRAIT" then
								local trait = strmatch(k, "trait (.*)")
								if arg1 == trait then
									TriggerSecret( secret, var, i )
								end
							elseif event == "PLAYER_KNOCKOUT" or event == "PLAYER_HEALED" then
								TriggerSecret( secret, var, i )
							end
						end
					end
				end
			end
		end
	end
end

function Me.SecretEditorCondition_OnClick(self, arg1, arg2, checked)
	local conditionsList = Me.SecretEditor.conditionsList1
	if UIDROPDOWNMENU_OPEN_MENU == Me.SecretEditor.conditions2 then
		conditionsList = Me.SecretEditor.conditionsList2
	elseif UIDROPDOWNMENU_OPEN_MENU == Me.SecretEditor.conditions3 then
		conditionsList = Me.SecretEditor.conditionsList3
	end
	
	arg1 = arg1:gsub("%.","")
	if checked then
		if arg2 then
			conditionsList[arg1.." "..arg2] = true;
		else
			conditionsList[arg1] = true;
		end
	else
		if arg2 then
			conditionsList[arg1.." "..arg2] = nil;
		else
			conditionsList[arg1] = nil;
		end
	end
end

function Me.SecretEditorCondition_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	
	local conditionsList = Me.SecretEditor.conditionsList1
	if frame == Me.SecretEditor.conditions2 then
		conditionsList = Me.SecretEditor.conditionsList2
	elseif frame == Me.SecretEditor.conditions3 then
		conditionsList = Me.SecretEditor.conditionsList3
	end
	
	local skillsList = {}
	local lastCategory
	
	for i = 1, #Me.Profile.skills do
		if not Me.Profile.skills[i].rank then
			skillsList[ Me.Profile.skills[i].name ] = {}
			lastCategory = Me.Profile.skills[i].name;
		else
			if not ( lastCategory ) then
				skillsList[ "Uncategorised" ] = {}
				lastCategory = "Uncategorised";
			end
			tinsert( skillsList[ lastCategory ], Me.Profile.skills[i] )
		end
	end

	if level == 1 then
		for i = 1, #TRIGGER_CONDITIONS do
			info.text = TRIGGER_CONDITIONS[i]
			info.notCheckable = true;
			info.keepShownOnClick = true;
			info.value = TRIGGER_CONDITIONS[i]
			if i <= 10 then
				info.hasArrow = true;
				if i <= 9 then
					info.menuList = "Skills";
				elseif i == 10 then
					info.menuList = "Traits";
				end
			else
				info.isNotRadio = true;
				info.hasArrow = false;
				info.arg1 = TRIGGER_CONDITIONS[i]
				info.notCheckable = false;
				info.checked = function()
					local arg1 = TRIGGER_CONDITIONS[i]:gsub("%.","")
					if conditionsList[arg1] then
						return true
					end
					return false			
				end
				info.func = Me.SecretEditorCondition_OnClick;
			end
			UIDropDownMenu_AddButton(info, level)
		end
	elseif menuList == "Skills" then
		for k,v in pairs( skillsList ) do
			info.text = k
			info.menuList = k
			info.value = UIDROPDOWNMENU_MENU_VALUE
			info.notCheckable = true;
			info.hasArrow = true;
			UIDropDownMenu_AddButton(info, level)
		end
	elseif menuList == "Traits" then
		for i = 1,#Profile.traits do
			info.text = Profile.traits[i].name
			info.isNotRadio = true;
			info.keepShownOnClick = true;
			info.hasArrow = false;
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.arg2 = Profile.traits[i].name
			info.notCheckable = false;
			info.checked = function()
				local arg1 = info.arg1:gsub("%.","")
				local arg2 = Profile.traits[i].name
				if conditionsList[arg1.." "..arg2] then
					return true
				end
				return false			
			end
			info.func = Me.SecretEditorCondition_OnClick;
			UIDropDownMenu_AddButton(info, level)
		end
	elseif menuList then
		for i = 1,#skillsList[menuList] do
			info.text = skillsList[menuList][i].name
			info.arg1 = UIDROPDOWNMENU_MENU_VALUE
			info.arg2 = skillsList[menuList][i].name
			info.isNotRadio = true;
			info.keepShownOnClick = true;
			info.tooltipTitle = skillsList[menuList][i].name;
			if skillsList[menuList][i].desc and skillsList[menuList][i].skillModifier then
				info.tooltipText = skillsList[menuList][i].desc .. "|n|cFF707070(Modified by "..skillsList[menuList][i].skillModifier.." + "..info.text..")|r";
			elseif skillsList[menuList][i].desc then
				info.tooltipText = skillsList[menuList][i].desc;
			end
			
			for i = 1, #Profile.skills do
				if Profile.skills[i].name == info.text then
					if Profile.skills[i].skillModifier and Profile.skills[i].desc then
						info.tooltipText = Profile.skills[i].desc .. "|n|cFF707070(Modified by " .. Profile.skills[i].skillModifier .. ")|r";
					end
					break
				end
			end
			info.notCheckable = false;
			info.checked = function()
				local arg1 = info.arg1:gsub("%.","")
				local arg2 = skillsList[menuList][i].name
				if conditionsList[arg1.." "..arg2] then
					return true
				end
				return false			
			end
			info.func = Me.SecretEditorCondition_OnClick;
			info.tooltipOnButton = true;
			UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Me.SecretEditor_Refresh( effectIndex )
	local secret
	if Me.SecretEditor.parent and effectIndex then
		if Me.ItemEditing then
			secret = Me.ItemEditing.effects[ effectIndex ]
		elseif Me.newItem then
			secret = Me.newItem.effects[ effectIndex ]
		end
		
		if secret then
			DiceMasterSecretEditorSaveButton:SetScript( "OnClick", function()
				Me.SecretEditor_SaveEdits()
			end)
		end
		
		Me.EffectEditingIndex = effectIndex
	else
		secret = Profile.traits[Me.editing_trait]["effects"]["secret"] or nil
	end
	if not secret then
		secret = {
			desc1 = "",
			conditions1 = {},
			desc2 = "",
			conditions2 = {},
			desc3 = "",
			conditions3 = {},
		}
		if not Me.SecretEditor.parent then
			--Profile.traits[Me.editing_trait]["effects"]["secret"] = secret
		end
	end
	Me.SecretEditor.secretDesc1.EditBox:SetText( secret.desc1 )
	Me.SecretEditor.conditionsList1 = secret.conditions1 or {}
	Me.SecretEditor.secretDesc2.EditBox:SetText( secret.desc2 )
	Me.SecretEditor.conditionsList2 = secret.conditions2 or {}
	Me.SecretEditor.secretDesc3.EditBox:SetText( secret.desc3 )
	Me.SecretEditor.conditionsList3 = secret.conditions3 or {}
	--UIDropDownMenu_SetText(Me.SecretEditor.conditions, GetConditionsList()) 
end

function Me.SecretEditor_DeleteSecret()
	if not Me.SecretEditor.parent then
		Profile.traits[Me.editing_trait]["effects"]["secret"] = nil
	end
	
	DiceMasterChargesFrame.traits[Me.editing_trait].secret:Hide()
	Profile.traits[Me.editing_trait].secret1Active = false;
	Profile.traits[Me.editing_trait].secret1Enabled = false;
	Profile.traits[Me.editing_trait].secret2Active = false;
	Profile.traits[Me.editing_trait].secret2Enabled = false;
	Profile.traits[Me.editing_trait].secret3Active = false;
	Profile.traits[Me.editing_trait].secret3Enabled = false;
	
	Me.SecretEditor:Hide()
	Me.TraitEditor_Refresh()
	if IsInRaid( LE_PARTY_CATEGORY_HOME ) then
		Me.Inspect_SendTraits( "RAID", nil )
	elseif IsInGroup( LE_PARTY_CATEGORY_HOME ) then
		Me.Inspect_SendTraits( "PARTY", nil )
	end
end

function Me.SecretEditor_Save()
	if Me.SecretEditor.secretDesc1.EditBox:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid description: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	if ( not Me.SecretEditor.conditionsList1 or next(Me.SecretEditor.conditionsList1) == nil )
	and ( not Me.SecretEditor.conditionsList2 or next(Me.SecretEditor.conditionsList2) == nil )
	and ( not Me.SecretEditor.conditionsList3 or next(Me.SecretEditor.conditionsList3) == nil ) then
		UIErrorsFrame:AddMessage( "You must choose at least one condition for a secret.", 1.0, 0.0, 0.0 );
		return
	end
	
	local secret
	if Me.SecretEditor.parent then
		secret = {
			type = "secret";
		}
	else
		secret = {}
	end
	secret.desc1 = Me.SecretEditor.secretDesc1.EditBox:GetText()
	secret.conditions1 = Me.SecretEditor.conditionsList1 or nil
	secret.desc2 = Me.SecretEditor.secretDesc2.EditBox:GetText()
	secret.conditions2 = Me.SecretEditor.conditionsList2 or nil
	secret.desc3 = Me.SecretEditor.secretDesc3.EditBox:GetText()
	secret.conditions3 = Me.SecretEditor.conditionsList3 or nil
	
	if Me.SecretEditor.parent then
		if Me.ItemEditing then
			tinsert( Me.ItemEditing.effects, secret )
		elseif Me.newItem then
			tinsert( Me.newItem.effects, secret )
		end
		Me.ItemEditorEffectsList_Update()
	else
		Profile.traits[Me.editing_trait]["effects"]["secret"] = secret
	end
end

function Me.SecretEditor_SaveEdits()
	if not Me.EffectEditingIndex then
		return
	end
	
	if Me.SecretEditor.secretName:GetText() == "" then
		UIErrorsFrame:AddMessage( "Invalid name: too short.", 1.0, 0.0, 0.0 );
		return
	end
	
	if ( not Me.SecretEditor.conditionsList1 or next(Me.SecretEditor.conditionsList1) == nil )
	and ( not Me.SecretEditor.conditionsList2 or next(Me.SecretEditor.conditionsList2) == nil )
	and ( not Me.SecretEditor.conditionsList3 or next(Me.SecretEditor.conditionsList3) == nil ) then
		UIErrorsFrame:AddMessage( "You must choose at least one condition for a secret.", 1.0, 0.0, 0.0 );
		return
	end
	
	local secret = {
		type = "secret";
	}
	secret.desc1 = Me.SecretEditor.secretDesc1.EditBox:GetText()
	secret.conditions1 = Me.SecretEditor.conditionsList1 or nil
	secret.desc2 = Me.SecretEditor.secretDesc2.EditBox:GetText()
	secret.conditions2 = Me.SecretEditor.conditionsList2 or nil
	secret.desc3 = Me.SecretEditor.secretDesc3.EditBox:GetText()
	secret.conditions3 = Me.SecretEditor.conditionsList3 or nil
	
	if Me.ItemEditing then
		Me.ItemEditing.effects[ Me.EffectEditingIndex ] = secret
	elseif Me.newItem then
		Me.newItem.effects[ Me.EffectEditingIndex ] = secret
	end
	
	Me.SecretEditor_OnCloseClicked()
	Me.ItemEditorEffectsList_Update()
end

function Me.SecretEditor_OnCloseClicked()
	Me.SecretEditor_Refresh()
	Me.SecretEditor.parent = nil
	Me.SecretEditor:Hide()
	Me.TraitEditor_Refresh()
end

function Me.SecretEditor_Open( parent )
	if parent then
		Me.CloseAllEditors( nil, nil, true )
		Me.SecretEditor.parent = parent
		Me.SecretEditor:SetPoint( "LEFT", parent, "RIGHT" )
		DiceMasterSecretEditorSaveButton:ClearAllPoints()
		DiceMasterSecretEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterSecretEditorDeleteButton:ClearAllPoints()
		DiceMasterSecretEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterSecretEditorDeleteButton:SetText( "Cancel" )
	else
		Me.CloseAllEditors()
		Me.SecretEditor.parent = nil
		Me.SecretEditor:SetPoint( "LEFT", DiceMasterTraitEditor, "RIGHT" )
		DiceMasterSecretEditorSaveButton:ClearAllPoints()
		DiceMasterSecretEditorSaveButton:SetPoint( "BOTTOMLEFT", 6, 4 )
		DiceMasterSecretEditorDeleteButton:ClearAllPoints()
		DiceMasterSecretEditorDeleteButton:SetPoint( "BOTTOMRIGHT", -6, 4 )
		DiceMasterSecretEditorDeleteButton:SetText( "Delete" )
	end
	
	DiceMasterSecretEditorSaveButton:SetScript( "OnClick", function()
		Me.SecretEditor_Save()
		Me.SecretEditor_OnCloseClicked()
	end)
   
	Me.SecretEditor_Refresh()
	Me.SecretEditor:Show()
end

---------------------------------------------------------------------------
-- Received a secret activation.
--  de = description				string
--	si = secret index (1-3)			number
--	ti = trait index (1-5)			number

function Me.SecretEditor_OnSecretActivated( data, dist, sender )	

	if not UnitInRaid( sender) and not UnitInParty( sender ) and UnitName("player") ~= sender then
		return
	end
 
	-- sanitize message
	if not data.de or not data.si or type(data.si)~="number" or data.si > 3 or data.si < 1 or not data.ti or type(data.ti)~="number" or data.ti > 5 or data.ti < 1 then
	   
		return
	end
	
	local desc = tostring( data.de );
	local secretIndex = tostring( data.si );
	local traitIndex = tonumber( data.ti );
	
	Me.inspectData[sender].traits[traitIndex]["secret"..secretIndex.."Active"] = true;
	Me.inspectData[sender].traits[traitIndex]["secret"..secretIndex.."Enabled"] = false;
	
	if not( DiceMasterSecretBanner:IsShown() ) then
		DiceMasterSecretBanner:Show()
	end
	
	if sender == UnitName( "player" ) then
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/secret-icon:12|t |cFFFFFFFFSecret!|r |cFFFF7EFF"..desc.."|r", "SYSTEM")
	else
		Me.PrintMessage("|cFFFFFF00"..sender.." has activated a|r |TInterface/AddOns/DiceMaster/Texture/secret-icon:12|t |cFFFFFFFFSecret!|r |cFFFF7EFF"..desc.."|r", "SYSTEM")
	end
end