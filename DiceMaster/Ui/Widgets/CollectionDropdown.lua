-------------------------------------------------------------------------------
-- Dice Master (C) 2024 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

local DEFAULTS = {
	["Buffs"] = {};
	["Banners"] = {
		{
			name = "Combat Begins",
			desc = "Combat has officially begun.",
			options = {
				{ icon = "Interface/Icons/VAS_NameChange", name = "Hold Emotes", desc = "Hold posts until the Action Phase." },
			},
		},
		{
			name = "Player Turn",
			desc = "Choose one of the following:",
			options = {
				{ icon = "Interface/Icons/Garrison_Building_SparringArena", name = "Combat Action", desc = "Attempt a Combat Action." },
				{ icon = "Interface/Icons/achievement_guild_doctorisin", name = "Skill", desc = "Attempt to use a Skill." },
				{ icon = "Interface/Icons/achievement_guildperk_quick and dead", name = "Trait", desc = "Use an active-use Trait." },
				{ icon = "Interface/Icons/achievement_guildperk_fasttrack_rank2", name = "Move", desc = "Move to another location." },
				{ icon = "Interface/Icons/ACHIEVEMENT_GUILDPERK_EVERYONES A HERO", name = "Stand", desc = "Stand still and forego your turn." },
			},
		},
		{
			name = "Enemy Turn",
			desc = "You may be prompted to roll for one of the following:",
			options = {
				{ icon = "Interface/Icons/Garrison_Building_SparringArena", name = "Combat Action", desc = "Attempt a Combat Action." },
				{ icon = "Interface/Icons/achievement_guildperk_massresurrection", name = "Saving Throw", desc = "Attempt a Saving Throw." },
			},
		},
		{
			name = "Combat Ends",
			desc = "Combat has officially ended.",
			options = {
				{ icon = "Interface/Icons/VAS_NameChange", name = "Hold Emotes", desc = "Continue holding posts for now." },
				{ icon = "Interface/Icons/vas_guildnamechange", name = "Emote", desc = "You may resume posting in chat." },
			},
		},
	},
}

for i = 1, #DiceMaster4.TermsList["Conditions"] do
	local condition = DiceMaster4.TermsList["Conditions"][i]
	local buff = {
		name = condition.name;
		icon = condition.icon;
		desc = condition.desc;
		cancelable = true;
	}
	tinsert( DEFAULTS["Buffs"], buff )
end

-------------------------------------------------------------------------------
-- StaticPopupDialogs for Collections.
--

StaticPopupDialogs["DICEMASTER4_CREATECOLLECTION"] = {
  text = "Enter a name for this collection:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function(self, data)
    self.editBox:SetText( "Collection 1" )
	self.editBox:HighlightText()
  end,
  OnAccept = function(self, data)
    local text = self.editBox:GetText()
	if data[text] then
		UIErrorsFrame:AddMessage( text.." already exists.", 1.0, 0.0, 0.0 );
	elseif text~= "" then
		data[text] = {};
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t New Collection \"|cFFFFFFFF"..text.."|r\" created.", "SYSTEM");
	else
		UIErrorsFrame:AddMessage( "Invalid name.", 1.0, 0.0, 0.0 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_EDITCOLLECTION"] = {
  text = "Enter a new name for this collection:",
  button1 = "Accept",
  button2 = "Delete",
  button3 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText(data[2])
	self.editBox:HighlightText()
  end,
  OnAccept = function(self, data)
    local text = self.editBox:GetText()
	local collection, name = data[1], data[2];
	if collection[text] then
		UIErrorsFrame:AddMessage( text.." already exists.", 1.0, 0.0, 0.0 );
	elseif text~= "" then
		collection[text] = collection[name];
		collection[name] = nil;
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Collection \"|cFFFFFFFF"..name.."|r\" renamed to \"|cFFFFFFFF"..text.."|r.\"", "SYSTEM");
	else
		UIErrorsFrame:AddMessage( "Invalid name.", 1.0, 0.0, 0.0 );
	end
  end,
  OnCancel = function(self, data)
	local collection, name = data[1], data[2];
	collection[name] = nil;
	Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t Collection \"|cFFFFFFFF"..name.."|r\" deleted.", "SYSTEM");
  end,
  OnAlt = function( self, data)
	self:Hide();
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_ADDMODELTOCOLLECTION"] = {
  text = "Enter the displayID for the model:",
  button1 = "Accept",
  button2 = "Cancel",
  OnAccept = function(self, data)
    local text = tonumber(self.editBox:GetText())
	if text~= nil and (text <= Me.unitList) then
		tinsert(ModelCollection[data], text)
		Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t |cFFFFFFFF"..text.."|r added to Collection \"|cFFFFFFFF"..data.."|r.\"", "SYSTEM");
		Me.ModelPicker_RefreshGrid()
	else
		UIErrorsFrame:AddMessage( "Invalid model.", 1.0, 0.0, 0.0 );
	end
  end,
  hasEditBox = true,
  timeout = 0,
  preferredIndex = 3,
}

-------------------------------------------------------------------------------

local methods = {
	SetCollection = function( self, defaultText, collectionType, collectFunc, checkFunc, returnFunc )
		if not( collectionType ) then
			return
		end

		local collection, hasDefaults, hasSubCollection;
		if collectionType == "Statistics" then
			collection = Me.db.global.collections.statistics;
			hasDefaults = false;
			hasSubCollection = true;
		elseif collectionType == "Buffs" then
			collection = Me.db.global.collections.buffs;
			hasDefaults = true;
			hasSubCollection = true;
		elseif collectionType == "Models" then
			collection = Me.db.global.collections.models;
			hasDefaults = true;
			hasSubCollection = false;
		elseif collectionType == "Banners" then
			collection = Me.db.global.collections.banners;
			hasDefaults = true;
			hasSubCollection = true;
		end

		if not( collection and type(collection)=="table" ) then
			return
		end

		self:SetDefaultText(defaultText or "My Collections");
		self:SetupMenu(function(dropdown, rootDescription)
			rootDescription:CreateTitle( collectionType );
			if hasDefaults then
				rootDescription:CreateDivider();
				local defaults;
				if hasSubCollection then
					defaults = rootDescription:CreateButton("Default", nil);
					defaults:AddInitializer(function(button, description, menu)
						MenuVariants.CreateSubmenuArrow(button);
					end);
					-- Defaults
					for i = 1, #DEFAULTS[collectionType] do
						local default = DEFAULTS[collectionType][i];
						local entryButton = defaults:CreateButton( default.name, function()
							returnFunc(default)
						end);
						entryButton:SetTooltip(function(tooltip, elementDescription)
							if default.name and default.desc then
								GameTooltip:AddLine( default.name, 1, 0.81, 0 );
								GameTooltip:AddLine( Me.FormatDescTooltip( default.desc ), 1, 1, 1, true );
							elseif default.tooltip then
								GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
								GameTooltip_AddNormalLine(tooltip, default.tooltip);
							end
						end);
						if default.icon then
							entryButton:AddInitializer(function(button, description, menu)
								local rightTexture = button:AttachTexture();
								rightTexture:SetSize(18, 18);
								rightTexture:SetPoint("RIGHT");
								rightTexture:SetTexture( default.icon );
							end);
						end
					end
				else
					defaults = rootDescription:CreateRadio("Default", function() return checkFunc("Default") end, function() returnFunc("default"); end, 1);
					defaults:SetSelectionIgnored()
				end
				rootDescription:CreateDivider();
			end
			for k, v in pairs(collection) do
				local subCollection
				if hasSubCollection then
					subCollection = rootDescription:CreateButton(k, nil);
					subCollection:AddInitializer(function(button, description, menu)
						MenuVariants.CreateSubmenuArrow(button);
						local gearButton = MenuTemplates.AttachAutoHideGearButton(button);
						gearButton:SetPoint("RIGHT", button, "RIGHT", -16, 0);
						MenuUtil.HookTooltipScripts(gearButton, function(tooltip)
							GameTooltip_SetTitle(tooltip, "Edit/Delete");
						end);
						gearButton:SetScript("OnClick", function()
							StaticPopup_Show("DICEMASTER4_EDITCOLLECTION", nil, nil, { collection, k } )
							menu:Close();
						end);
					end);
					if #v > 0 then
						for i = 1, #v do
							local entry = v[i];
							local entryButton = subCollection:CreateButton( entry.name, function()
								returnFunc(entry);
							end);
							entryButton:SetTooltip(function(tooltip, elementDescription)
								if entry.name and entry.desc then
									GameTooltip:AddLine( entry.name, 1, 0.81, 0 );
									GameTooltip:AddLine( Me.FormatDescTooltip( entry.desc ), 1, 1, 1, true );
								elseif entry.tooltip then
									GameTooltip_SetTitle(tooltip, MenuUtil.GetElementText(elementDescription));
									GameTooltip_AddNormalLine(tooltip, entry.tooltip);
								end
							end);
							if entry.icon then
								entryButton:AddInitializer(function(button, description, menu)
									local rightTexture = button:AttachTexture();
									rightTexture:SetSize(18, 18);
									rightTexture:SetPoint("RIGHT");
									rightTexture:SetTexture( entry.icon );
									local deleteButton = MenuTemplates.AttachAutoHideButton(button, "Interface/Buttons/UI-GroupLoot-Pass-Up");
									deleteButton:SetSize(16, 16);
									deleteButton:SetPoint("RIGHT", rightTexture, "LEFT");
									MenuUtil.HookTooltipScripts(deleteButton, function(tooltip)
										GameTooltip_SetTitle(tooltip, "Remove from Collection");
									end);
									deleteButton:SetScript("OnClick", function()
										tremove( v, i );
										Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t " .. entry.name .. " removed from Collection \"".. k ..".\"", "SYSTEM");
										menu:Close();
										self:GenerateMenu()
									end);
								end);
							else
								entryButton:AddInitializer(function(button, description, menu)
									local deleteButton = MenuTemplates.AttachAutoHideButton(button, "Interface/Buttons/UI-GroupLoot-Pass-Up");
									deleteButton:SetSize(16, 16);
									deleteButton:SetPoint("RIGHT");
									MenuUtil.HookTooltipScripts(deleteButton, function(tooltip)
										GameTooltip_SetTitle(tooltip, "Remove from Collection");
									end);
									deleteButton:SetScript("OnClick", function()
										tremove( v, i );
										Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t " .. entry.name .. " removed from Collection \"".. k ..".\"", "SYSTEM");
										menu:Close();
										self:GenerateMenu()
									end);
								end);
							end
						end
					end
					subCollection:CreateButton( CreateAtlasMarkup("communities-icon-addchannelplus") .. "|cFF00FF00 Add to Collection", function()
						local entryData = collectFunc();
						if type(entryData) == "table" then
							tinsert( v, entryData );
							Me.PrintMessage("|TInterface/AddOns/DiceMaster/Texture/logo:12|t " .. entryData.name .. " added to Collection \"".. k ..".\"", "SYSTEM");
							self:GenerateMenu();
						end
					end);
				else
					subCollection = rootDescription:CreateRadio(k, function(k) return checkFunc(k) end, function(k) returnFunc(k); end, k);
					subCollection:AddInitializer(function(button, description, menu)
						local gearButton = MenuTemplates.AttachAutoHideGearButton(button);
						gearButton:SetPoint("RIGHT");
						MenuUtil.HookTooltipScripts(gearButton, function(tooltip)
							GameTooltip_SetTitle(tooltip, "Edit/Delete");
						end);
						gearButton:SetScript("OnClick", function()
							StaticPopup_Show("DICEMASTER4_EDITCOLLECTION", nil, nil, { collection, k } )
							menu:Close();
						end);
					end);
				end
			end
			rootDescription:CreateButton( CreateAtlasMarkup("communities-icon-addchannelplus") .. "|cFF00FF00 New Collection", function()
				StaticPopup_Show("DICEMASTER4_CREATECOLLECTION", nil, nil, collection)
			end)
		end);
	end;

	Enable = function( self )
		self:Enable();
	end;

	Disable = function( self )
		self:Disable();
	end;
};

-------------------------------------------------------------------------------
function Me.CollectionDropdown_Init( self )

	for k, v in pairs( methods ) do
		self[k] = v
	end
end