-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Assistant.
--

local Me = DiceMaster4
local Profile = Me.Profile

local filteredList

function Me.Assistant_OnEvent( self, event, arg1, ... )
	if event == "PLAYER_FLAGS_CHANGED" and arg1 == "player" then
		if UnitIsAFK("player") then
			self.AFKTimer = C_Timer.NewTimer( 30, function()
				if UnitIsAFK("player") then
					self.DiceEyes:SetTexCoord(0.5, 1, 0, 1);
					self.AFKTexture:Show()
				end
			end)
		elseif self.AFKTimer then
			self.AFKTimer:Cancel()
			self.AFKTexture:Hide();
		end
	end
end

local function SetSearch( text )
	text = text:lower();
	-- build new list
	filteredList = {};
	for tipIndex = 1, #Me.HelpList do
		local tip = Me.HelpList[tipIndex];
		if tip.title:find( text ) then
			table.insert( filteredList, tip );
		elseif tip.keywords then
			local keywords = tip.keywords;
			for i = 1, #keywords do
				if text:find( keywords[i] ) then
					table.insert( filteredList, tip );
				end	
			end
		end
	end
	Me.Assistant_UpdateSearchPreview()
end

local function GetNumSearchResults()
	if filteredList then
		return #filteredList
	end
	return 0;
end

local function GetSearchDisplay( index )
	if not( filteredList ) then
		return
	end
	
	return filteredList[index].title;
end

function Me.Assistant_ResetSearch()
	DiceMasterAssistantTooltip.Search:Show();
	DiceMasterAssistantTooltip.Text:SetText( "What would you like help with?" )
	DiceMasterAssistantTooltip.Button1:Hide();
	DiceMasterAssistantTooltip.Button2:Hide();
	DiceMasterAssistantTooltip:SetHeight(DiceMasterAssistantTooltip.Text:GetHeight()+90);
	--DiceMasterAssistantTooltip.searchResults:Hide();
end

function Me.Assistant_SelectSearch(index)
	local tip = filteredList[index];
	
	if not( tip ) then
		return
	end
	
	DiceMasterAssistantTooltip.isSticky = true;
	
	DiceMasterAssistantTooltip.Search:Hide();
	DiceMasterAssistantTooltip.Text:SetText( tip.tip )
	
	DiceMasterAssistantTooltip.Button1:Show();
	DiceMasterAssistantTooltip.Button1:ClearAllPoints();
	DiceMasterAssistantTooltip.Button1:SetPoint("BOTTOM", 0, 32);
	DiceMasterAssistantTooltip.Button2:Hide();
	
	if tip.button1Text then
		DiceMasterAssistantTooltip.Button1:SetText( tip.button1Text );
		DiceMasterAssistantTooltip.Button1.onClick = tip.button1OnClick;
	else
		DiceMasterAssistantTooltip.Button1:SetText( "Got it!" );
		DiceMasterAssistantTooltip.Button1.onClick = function()
			DiceMasterAssistantTooltip:Hide();
		end;
	end
	if tip.button2Text then
		DiceMasterAssistantTooltip.Button2:SetText( tip.button1Text );
		DiceMasterAssistantTooltip.Button2.onClick = tip.button2OnClick;
		DiceMasterAssistantTooltip.Button1:ClearAllPoints();
		DiceMasterAssistantTooltip.Button2:ClearAllPoints();
		DiceMasterAssistantTooltip.Button1:SetPoint("BOTTOMLEFT", 6, 42);
		DiceMasterAssistantTooltip.Button2:SetPoint("BOTTOMRIGHT", -6, 42);
		DiceMasterAssistantTooltip.Button2:Show();
	end
	
	DiceMasterAssistantTooltip:SetHeight(DiceMasterAssistantTooltip.Text:GetHeight()+90);
	
	--DiceMasterAssistantTooltip.searchResults:Hide();
end

function Me.Assistant_ShowStickyTip( tip )
	if not( tip ) then
		return
	end
	
	DiceMasterAssistantTooltip.isSticky = true;
	DiceMasterAssistantTooltip.Search:Hide();
	DiceMasterAssistantTooltip.Text:SetText( tip )
	DiceMasterAssistantTooltip.Button1:Show();
	DiceMasterAssistantTooltip.Button1:ClearAllPoints();
	DiceMasterAssistantTooltip.Button1:SetPoint("BOTTOM", 0, 42);
	DiceMasterAssistantTooltip.Button2:Hide();
	DiceMasterAssistantTooltip.Button1:SetText( "Got it!" );
	DiceMasterAssistantTooltip.Button1.onClick = function()
		DiceMasterAssistantTooltip:Hide();
	end;
	DiceMasterAssistantTooltip:SetHeight(DiceMasterAssistantTooltip.Text:GetHeight()+90);
	DiceMasterAssistantTooltip:Show();
	
	--DiceMasterAssistantTooltip.searchResults:Hide();
end

function Me.Assistant_UpdateSearchPreview()
	if strlen(DiceMasterAssistantTooltip.Search:GetText()) < 3 then
		Me.Assistant_HideSearchPreview();
		--DiceMasterAssistantTooltip.searchResults:Hide();
		return;
	end

	local numResults = GetNumSearchResults();

	if numResults == 0 then
		Me.Assistant_HideSearchPreview();
		return;
	end

	local lastShown = DiceMasterAssistantTooltip.Search;
	for index = 1, 5 do
		local button = DiceMasterAssistantTooltip.Search.searchPreview[index];
		if index <= numResults then
			local title, _ = GetSearchDisplay(index);
			button.name:SetText(title);
			button:SetID(index);
			button:Show();
			lastShown = button;
		else
			button:Hide();
		end
	end

	DiceMasterAssistantTooltip.Search.showAllResults:Hide();
	if numResults > 5 then
		DiceMasterAssistantTooltip.Search.showAllResults.text:SetText(string.format("Show All %d Results", numResults));
		DiceMasterAssistantTooltip.Search.showAllResults:Show();
	end

	Me.Assistant_FixSearchPreviewBottomBorder();
	DiceMasterAssistantTooltip.Search.searchPreviewContainer:Show();
end

function Me.Assistant_FixSearchPreviewBottomBorder()
	local lastShownButton = nil;
	if DiceMasterAssistantTooltip.Search.showAllResults:IsShown() then
		lastShownButton = DiceMasterAssistantTooltip.Search.showAllResults;
	else
		for index = 1, 5 do
			local button = DiceMasterAssistantTooltip.Search.searchPreview[index];
			if button:IsShown() then
				lastShownButton = button;
			end
		end
	end

	if lastShownButton ~= nil then
		DiceMasterAssistantTooltip.Search.searchPreviewContainer.botRightCorner:SetPoint("BOTTOM", lastShownButton, "BOTTOM", 0, -8);
		DiceMasterAssistantTooltip.Search.searchPreviewContainer.botLeftCorner:SetPoint("BOTTOM", lastShownButton, "BOTTOM", 0, -8);
	else
		Me.Assistant_HideSearchPreview()();
	end
end

function Me.Assistant_HideSearchPreview()
	DiceMasterAssistantTooltip.Search.showAllResults:Hide();

	local index = 1;
	local unusedButton = DiceMasterAssistantTooltip.Search.searchPreview[index];
	while unusedButton do
		unusedButton:Hide();
		index = index + 1;
		unusedButton = DiceMasterAssistantTooltip.Search.searchPreview[index];
	end

	DiceMasterAssistantTooltip.Search.searchPreviewContainer:Hide();
end

function Me.Assistant_ClearSearch()
	--DiceMasterAssistantTooltip.searchResults:Hide();
	Me.Assistant_HideSearchPreview();
end

function Me.Assistant_OnTextChanged(self)
	SearchBoxTemplate_OnTextChanged(self);

	local text = self:GetText();
	if strlen(text) < 3 then
		Me.Assistant_ClearSearch();
		Me.Assistant_HideSearchPreview();
		--DiceMasterAssistantTooltip.searchResults:Hide();
		return;
	end

	Me.Assistant_SetSearchPreviewSelection(1);
	SetSearch(text);
end

function Me.Assistant_OnEnterPressed(self)
	if self.selectedIndex > 6 or self.selectedIndex < 0 then
		return;
	elseif self.selectedIndex == 6 then
		if DiceMasterAssistantTooltip.Search.showAllResults:IsShown() then
			DiceMasterAssistantTooltip.Search.showAllResults:Click();
		end
	else
		local preview = DiceMasterAssistantTooltip.Search.searchPreview[self.selectedIndex];
		if preview:IsShown() then
			preview:Click();
		end
	end

	Me.Assistant_HideSearchPreview();
end

function Me.Assistant_OnKeyDown(self, key)
	if key == "UP" then
		Me.Assistant_SetSearchPreviewSelection(DiceMasterAssistantTooltip.Search.selectedIndex - 1);
	elseif key == "DOWN" then
		Me.Assistant_SetSearchPreviewSelection(DiceMasterAssistantTooltip.Search.selectedIndex + 1);
	end
end

function Me.Assistant_OnFocusLost(self)
	SearchBoxTemplate_OnEditFocusLost(self);
	Me.Assistant_HideSearchPreview();
end

function Me.Assistant_OnFocusGained(self)
	SearchBoxTemplate_OnEditFocusGained(self);
	--DiceMasterAssistantTooltip.searchResults:Hide();
	Me.Assistant_SetSearchPreviewSelection(1);
	Me.Assistant_UpdateSearchPreview();
end

function Me.Assistant_SearchUpdate()
	--local scrollBox = DiceMasterAssistantTooltip.searchResults.ScrollBox;
	local dataProvider = CreateDataProviderByIndexCount(GetNumSearchResults());
	scrollBox:SetDataProvider(dataProvider);
end

function Me.Assistant_SetSearchPreviewSelection(selectedIndex)
	local searchBox = DiceMasterAssistantTooltip.Search;
	local numShown = 0;
	for index = 1, 5 do
		searchBox.searchPreview[index].selectedTexture:Hide();

		if searchBox.searchPreview[index]:IsShown() then
			numShown = numShown + 1;
		end
	end

	if searchBox.showAllResults:IsShown() then
		numShown = numShown + 1;
	end

	searchBox.showAllResults.selectedTexture:Hide();

	if numShown == 0 then
		selectedIndex = 1;
	elseif selectedIndex > numShown then
		-- Wrap under to the beginning.
		selectedIndex = 1;
	elseif selectedIndex < 1 then
		-- Wrap over to the end;
		selectedIndex = numShown;
	end

	searchBox.selectedIndex = selectedIndex;

	if selectedIndex == 6 then
		searchBox.showAllResults.selectedTexture:Show();
	else
		searchBox.searchPreview[selectedIndex].selectedTexture:Show();
	end
end

function Me.Assistant_ShowFullSearch()
	local numResults = GetNumSearchResults();

	--DiceMasterAssistantTooltip.searchResults.TitleText:SetText(string.format(ENCOUNTER_JOURNAL_SEARCH_RESULTS, DiceMasterAssistantTooltip.Search:GetText(), numResults));
	--DiceMasterAssistantTooltip.searchResults:Show();
	Me.Assistant_SearchUpdate();
	Me.Assistant_HideSearchPreview();
	DiceMasterAssistantTooltip.Search:ClearFocus();
end

function Me.Assistant_Init()
	if Me.db.global.assistantEnabled then
		DiceMasterAssistant:Show();
	else
		DiceMasterAssistant:Hide();
	end
	if not( Me.db.global.assistantFirstTime ) then
		Me.db.global.assistantFirstTime = true;
		Me.Assistant_ShowStickyTip( "Hi! I'm Dicey, your DiceMaster assistant!|n|nIf you need help or have questions, I'm here to lend a hand!" );
	end
end