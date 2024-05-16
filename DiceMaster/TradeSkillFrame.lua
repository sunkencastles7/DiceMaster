-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Trade skill interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local filteredList = nil
local TradeSkillSearchParameters = { "name", "whiteText1", "whiteText2", "useText", "requirement", "flavorText", "author" }

local TradeSkillTypeColor = {
	["optimal"]	= { r = 1.00, g = 0.50, b = 0.25, font = "GameFontNormalLeftOrange" };       
	["medium"]	= { r = 1.00, g = 1.00, b = 0.00, font = "GameFontNormalLeftYellow" };       
	["easy"]		= { r = 0.25, g = 0.75, b = 0.25, font = "GameFontNormalLeftLightGreen" };   
	["trivial"]	= { r = 0.50, g = 0.50, b = 0.50, font = "GameFontNormalLeftGrey" };         
	["header"]	= { r = 1.00, g = 0.82, b = 0,    font = "GameFontNormalLeft" };
};

local function GetNumTradeSkills()
	if filteredList then
		return #filteredList or 0;
	end
	
	return #Me.Profile.recipes or 0;
end

local function GetNumExpandedTradeSkills()
	local list = filteredList or Me.Profile.recipes
	local count = 0;
	
	for i = 1, #list do
		if list[i].type == "header" or list[i].expanded then
			count = count + 1
		end
	end
	
	return count or 0;
end

local function HasReagentsToCraft( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.reagents then
			for i = 1, #recipe.reagents do
				if Me.FindTotalAmount( recipe.reagents[i].guid ) < recipe.reagents[i].count then
					return false
				end
			end
		end
		return true;
	end
	return false;
end

local function GetNumAvailableToCraft( skillIndex )
	local list = filteredList or Me.Profile.recipes
	local totalCraftable = 0;
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.reagents then
			totalCraftable = 200;
			haveReagents = true;
			for i = 1, #recipe.reagents do
				if haveReagents then
					if Me.FindTotalAmount( recipe.reagents[i].guid ) >= recipe.reagents[i].count then
						local amountCraftable = math.floor( Me.FindTotalAmount( recipe.reagents[i].guid ) / recipe.reagents[i].count )
						if amountCraftable < totalCraftable then
							totalCraftable = amountCraftable
						end
					else
						haveReagents = false;
						return 0;
					end
				end
			end
		end
	end
	return totalCraftable;
end

local function GetTradeSkillNumReagents( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.reagents then
			return #recipe.reagents;
		end
	end
	
	return 0;
end

local function GetTradeSkillReagentInfo( skillIndex, reagentIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.reagents[reagentIndex] then
			local reagent = recipe.reagents[reagentIndex]
			return reagent.name, reagent.icon, reagent.count, Me.FindTotalAmount( reagent.guid ) or 0;
		end
	end
	
	return false;
end

local function GetTradeSkillIcon( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		return recipe.item.icon;
	end
	
	return nil;
end

local function GetTradeSkillSelectionIndex()
	if DiceMasterTradeSkillFrame.selectedSkill then
		return DiceMasterTradeSkillFrame.selectedSkill
	end
	
	return 0;
end

local function GetFirstTradeSkill()
	local list = filteredList or Me.Profile.recipes
	for i = 1, #list do
		if list[i] and list[i].item then
			return i;
		end
	end
	return false;
end

local function GetFirstExpandedTradeSkill()
	local list = filteredList or Me.Profile.recipes
	for i = 1, #list do
		if list[i] and list[i].item and list[i].expanded then
			return i;
		end
	end
	return false;
end

local function GetTradeSkillLine()
	local list = filteredList or Me.Profile.recipes
	if DiceMasterTradeSkillFrame.selectedSkill then
		if list[DiceMasterTradeSkillFrame.selectedSkill] then
			local skill = list[DiceMasterTradeSkillFrame.selectedSkill]
			if ( skill.skill and skill.skill.guid ) then
				for i = 1, #Me.Profile.skills do
					if Me.Profile.skills[i].type ~= "header" and Me.Profile.skills[i].guid and Me.Profile.skills[i].guid == skill.skill.guid then
						return Me.Profile.skills[i].name or "", Me.Profile.skills[i].rank or 0, Me.Profile.skills[i].maxRank or 0;
					end
				end
				return skill.skill.name or "", 0, skill.skill.maxRank or 0;
			end
		end
	end
	return "", 0, 0;
end

local function GetTradeSkillInfo( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.type and recipe.type == "header" then
			return recipe.name, "header", 0, recipe.expanded or false;
		else
			return recipe.item.name, "medium", GetNumAvailableToCraft(skillIndex), recipe.expanded or false;
		end
	end

	return nil;
end

local function GetTradeSkillItemInfo( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.item then
			return recipe.item;
		end
	end

	return false;
end

local function GetTradeSkillDescription( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.description then
			return recipe.description;
		end
	end

	return false;
end

local function GetTradeSkillCooldown( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe.lastCastTime and recipe.cooldown then
			if time() - recipe.lastCastTime < recipe.cooldown then
				return time() - recipe.lastCastTime;
			end
			return false;
		end
	end

	return false;
end

local function GetTradeSkillNumMade( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		local recipe = list[skillIndex]
		if recipe and recipe.yieldMin and recipe.yieldMax then
			return recipe.yieldMin, recipe.yieldMax;
		end
	end

	return 1, 1;
end

local function GetTradeSkillTools( skillIndex )
	local list = filteredList or Me.Profile.recipes
	if list[skillIndex] then
		if list[skillIndex].requiredTool then
			return list[skillIndex].requiredTool.name
		end
	end
	
	return false;
end

local function GetTradeskillRepeatCount( skillIndex )
	if DiceMasterTradeSkillFrame.repeatCount then
		return DiceMasterTradeSkillFrame.repeatCount
	end
	
	return 1;
end

local function CollapseTradeSkillAll()
	local list = filteredList or Me.Profile.recipes
	for i = 1, #list do
		if list[i] then
			list[i].expanded = false;
		end
	end
	if not ( GetTradeSkillSelectionIndex() ) then
		Me.TradeSkillFrame_SetSelection(GetFirstTradeSkill());
	end	
	Me.TradeSkillFrame_Update()
end

local function ExpandTradeSkillAll()
	local list = filteredList or Me.Profile.recipes
	for i = 1, #list do
		if list[i] then
			list[i].expanded = true;
		end
	end
	if not ( GetTradeSkillSelectionIndex() ) then
		Me.TradeSkillFrame_SetSelection(GetFirstTradeSkill());
	end	
	Me.TradeSkillFrame_Update()
end

local function GetIndexByFilteredIndex( skillIndex )
	if filteredList then
		for i = 1, #Me.Profile.recipes do
			if filteredList[skillIndex] == Me.Profile.recipes[i] then
				return i;
			end
		end
	end
	return skillIndex
end

local function CollapseTradeSkillSubClass( skillIndex )
	local list = Me.Profile.recipes
	local newIndex = GetIndexByFilteredIndex( skillIndex )
	for i = newIndex, #list do
		if list[i] then
			if list[i].type == "recipe" or i == newIndex then
				list[i].expanded = false;
				if GetTradeSkillSelectionIndex() == i then
					Me.TradeSkillFrame_SetSelection(GetFirstExpandedTradeSkill());
				end
			elseif list[i].type == "header" then
				-- Stop when we reach another header
				break
			end
		end
	end
	Me.TradeSkillFrame_Update()
end

local function ExpandTradeSkillSubClass( skillIndex )
	local list = filteredList or Me.Profile.recipes
	local newIndex = GetIndexByFilteredIndex( skillIndex )
	for i = newIndex, #list do
		if list[i] then
			if list[i].type == "recipe" or i == newIndex then
				list[i].expanded = true;
			elseif list[i].type == "header" then
				-- Stop when we reach another header
				break
			end
		end
	end
	Me.TradeSkillFrame_Update()
end

local function GrantTradeSkillSkillUp( skillData, amount )
	if not skillData or not amount then
		return
	end
	
	local foundSkill = false;
	for i = 1, #Me.Profile.skills do
		if Me.Profile.skills[i] then
			local skill = Me.Profile.skills[i];
			if skill.guid == skillData.guid then
				foundSkill = true;
				Me.Profile.skills[i].rank = Me.Profile.skills[i].rank + amount;
				Me.PrintMessage( "|cFF8080ffYour skill in "..Me.Profile.skills[i].name.." has increased to "..Me.Profile.skills[i].rank..".|r", "SYSTEM" )
				break;
			end
		end
	end
	Me.SkillFrame_UpdateSkills()
end

local function ProduceTradeSkillItem( skillIndex )
	if not Me.Profile.recipes[skillIndex] then
		return
	end
	
	if ( Me.Profile.recipes[skillIndex].requiredTool and Me.FindTotalAmount( Me.Profile.recipes[skillIndex].requiredTool.guid ) == 0 ) then
		-- missing the required tools
		return
	end
	
	if Me.Profile.recipes[skillIndex].skill and Me.Profile.recipes[skillIndex].skill.guid and Me.Profile.recipes[skillIndex].skill.amount then
		GrantTradeSkillSkillUp( Me.Profile.recipes[skillIndex].skill, Me.Profile.recipes[skillIndex].skill.amount or 1 )
	end
	
	if Me.Profile.recipes[skillIndex].reagents then
		-- consume reagents
		for i = 1, #Me.Profile.recipes[skillIndex].reagents do
			if ( Me.Profile.recipes[skillIndex].reagents[i] ) then
				Me.DeleteItem( Me.Profile.recipes[skillIndex].reagents[i].guid, Me.Profile.recipes[skillIndex].reagents[i].count )
			end
		end
	end
	
	-- produce item
	local item = Me.GetItemInfo( Me.Profile.recipes[skillIndex].item.guid )
	if ( item ) then
		local minMade, maxMade = GetTradeSkillNumMade(skillIndex);
		if ( maxMade > 1 and minMade < maxMade ) then
			Me.CreateItem( item, random( minMade, maxMade ) )
		else
			Me.CreateItem( item, minMade )
		end
		item.amount = minMade or 1;
		item.labelText = "You created"
		data = Me:Serialize( "ITEM", item );
		Me:SendCommMessage( "DCM4", data, "WHISPER", UnitName("player"), "NORMAL" )
	end
	
	Me.TradeSkillFrame_SetSelection(GetTradeSkillSelectionIndex())
	Me.TradeSkillFrame_Update()
end

StaticPopupDialogs["DICEMASTER4_UNLEARNRECIPE"] = {
  text = "Are you sure you want to unlearn this recipe?",
  button1 = "Unlearn",
  button2 = "Cancel",
  OnShow = function( self, data )
	local recipe = Me.Profile.recipes[ data ] or nil
	if ( recipe ) then
		self.text:SetText( "Are you sure you want to unlearn "..recipe.item.name.."?" )
	end
  end,
  OnAccept = function (self, data)
	local recipe = Me.Profile.recipes[ data ]
	if not ( recipe ) then
		return
	end
	Me.PrintMessage( "You have unlearned how to create an item: "..recipe.item.name..".", "SYSTEM" )
	tremove( Me.Profile.recipes, data )
	if ( GetTradeSkillSelectionIndex() == data ) then
		Me.TradeSkillFrame_SetSelection(GetFirstTradeSkill());
	end	
	Me.TradeSkillFrame_Update()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

function Me.DoTradeSkill( skillIndex, loop )
	if Me.Profile.recipes[skillIndex] then
		local name = Me.Profile.recipes[skillIndex].item.name
		local castTime = Me.Profile.recipes[skillIndex].castTime or 2;
	
		Dismount()
		Me.CastBar( "cast", name, nil, castTime, false, 6425 )
		if ( loop and loop > 1 ) then
			DiceMasterCastingBarFrame["OnFinished"] = function() 		
				ProduceTradeSkillItem( skillIndex )
				Me.DoTradeSkill(skillIndex, loop - 1)
			end
		else
			DiceMasterCastingBarFrame["OnFinished"] = function() 		
				ProduceTradeSkillItem( skillIndex )
			end
		end
	end
end

function Me.TradeSkillFrame_OnShow(self)
	ShowUIPanel(DiceMasterTradeSkillFrame);
	
	DiceMasterTradeSkillCreateButton:Disable();
	DiceMasterTradeSkillCreateAllButton:Disable();
	local tsIndex = 0;
	if ( GetTradeSkillSelectionIndex() == 0 ) then
		tsIndex = GetFirstTradeSkill();
	else
		tsIndex = GetTradeSkillSelectionIndex();
	end	
	Me.TradeSkillFrame_SetSelection(tsIndex);
	
	FauxScrollFrame_SetOffset(DiceMasterTradeSkillListScrollFrame, 0);
	DiceMasterTradeSkillListScrollFrameScrollBar:SetMinMaxValues(0, 0); 
	DiceMasterTradeSkillListScrollFrameScrollBar:SetValue(0);
	SetPortraitTexture(DiceMasterTradeSkillFramePortrait, "player");
	Me.TradeSkillFrame_Update();
end

function Me.TradeSkillFrame_OnLoad(self)
	self:SetClampedToScreen( true )
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
end

function Me.TradeSkillFrame_Update()
	--Me.TradeSkillBuildFilteredList()
	local numTradeSkills = GetNumTradeSkills();
	local skillOffset = FauxScrollFrame_GetOffset(DiceMasterTradeSkillListScrollFrame);
	-- If no recipes
	if ( numTradeSkills <= 1 ) then
		DiceMasterTradeSkillFrameTitleText:SetText("Crafting");
		DiceMasterTradeSkillHighlight:Hide()
		DiceMasterTradeSkillSkillName:Hide();
		DiceMasterTradeSkillSkillIcon:Hide();
		DiceMasterTradeSkillDescription:Hide();
		DiceMasterTradeSkillRequirementLabel:Hide();
		DiceMasterTradeSkillRequirementText:SetText("");
		DiceMasterTradeSkillCollapseAllButton:Disable();
		DiceMasterTradeSkillUnlearnButton:Disable();
		DiceMasterTradeSkillUnlearnButton:GetNormalTexture():SetDesaturated(true);
		for i=1, 8, 1 do
			_G["DiceMasterTradeSkillReagent"..i]:Hide();
		end
	else
		DiceMasterTradeSkillHighlight:Show()
		DiceMasterTradeSkillSkillName:Show();
		DiceMasterTradeSkillSkillIcon:Show();
		DiceMasterTradeSkillDescription:Show()
		DiceMasterTradeSkillCollapseAllButton:Enable();
		DiceMasterTradeSkillUnlearnButton:Enable();
		DiceMasterTradeSkillUnlearnButton:GetNormalTexture():SetDesaturated(false);
	end
	-- ScrollFrame update
	FauxScrollFrame_Update(DiceMasterTradeSkillListScrollFrame, numTradeSkills, 8, 16, nil, nil, nil, DiceMasterTradeSkillHighlightFrame, 293, 316 );
	
	if ( DiceMasterTradeSkillDetailScrollFrameScrollBar:IsVisible() ) then
		DiceMasterTradeSkillDetailScrollFrame:SetWidth(300)
		DiceMasterTradeSkillDetailScrollChildFrame:SetWidth(300)
	else
		DiceMasterTradeSkillDetailScrollFrame:SetWidth(320)
		DiceMasterTradeSkillDetailScrollChildFrame:SetWidth(320)
	end
	
	DiceMasterTradeSkillHighlightFrame:Hide();
	for i=1, 8, 1 do
		local skillIndex = i + skillOffset;
		local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(skillIndex);
		local skillButton = _G["DiceMasterTradeSkillSkill"..i];
		if ( skillIndex <= numTradeSkills ) then
			-- Set button widths if scrollbar is shown or hidden
			if ( DiceMasterTradeSkillListScrollFrame:IsVisible() ) then
				skillButton:SetWidth(293);
			else
				skillButton:SetWidth(323);
			end
			local color = TradeSkillTypeColor[skillType];
			if ( color ) then
				skillButton:SetNormalFontObject(color.font);
			end
			
			skillButton:SetID(skillIndex);
			skillButton:Show();
			-- Handle headers
			if ( skillType == "header" ) then
				skillButton:SetText(skillName);
				if ( isExpanded ) then
					skillButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
				else
					skillButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
				end
				_G["DiceMasterTradeSkillSkill"..i.."Highlight"]:SetTexture("Interface\\Buttons\\UI-PlusButton-Hilight");
				_G["DiceMasterTradeSkillSkill"..i]:UnlockHighlight();
			else
				if ( not skillName ) then
					return;
				end
				skillButton:SetNormalTexture("");
				_G["DiceMasterTradeSkillSkill"..i.."Highlight"]:SetTexture("");
				if ( numAvailable == 0 ) then
					skillButton:SetText(" "..skillName);
				else
					skillButton:SetText(" "..skillName.." ["..numAvailable.."]");
				end
				
				-- Place the highlight and lock the highlight state
				if ( GetTradeSkillSelectionIndex() == skillIndex ) then
					DiceMasterTradeSkillHighlightFrame:SetPoint("TOPLEFT", "DiceMasterTradeSkillSkill"..i, "TOPLEFT", 0, 0);
					DiceMasterTradeSkillHighlightFrame:Show();
					skillButton:SetNormalFontObject(color.font);
					_G["DiceMasterTradeSkillSkill"..i]:LockHighlight();
				else
					_G["DiceMasterTradeSkillSkill"..i]:UnlockHighlight();
				end
			end
			
		else
			skillButton:Hide();
		end
	end
	
	-- Set the expand/collapse all button texture
	local numHeaders = 0;
	local notExpanded = 0;
	for i=1, numTradeSkills, 1 do
		local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(i);
		if ( skillName and skillType == "header" ) then
			numHeaders = numHeaders + 1;
			if ( not isExpanded ) then
				notExpanded = notExpanded + 1;
			end
		end
		if ( GetTradeSkillSelectionIndex() == i ) then
			-- Set the max makeable items for the create all button
			DiceMasterTradeSkillFrame.numAvailable = numAvailable;
		end
	end
	-- If all headers are not expanded then show collapse button, otherwise show the expand button
	if ( notExpanded ~= numHeaders ) then
		DiceMasterTradeSkillCollapseAllButton.collapsed = nil;
		DiceMasterTradeSkillCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up");
	else
		DiceMasterTradeSkillCollapseAllButton.collapsed = 1;
		DiceMasterTradeSkillCollapseAllButton:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up");
	end
	
	local tsIndex = 0;
	if ( GetTradeSkillSelectionIndex() == 0 ) then
		Me.TradeSkillFrame_SetSelection(GetFirstTradeSkill());
	end	
end

function Me.TradeSkillFrame_SetSelection(id)
	local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(id);
	DiceMasterTradeSkillHighlightFrame:Show();
	if ( skillType == "header" ) then
		DiceMasterTradeSkillHighlightFrame:Hide();
		if ( isExpanded ) then
			CollapseTradeSkillSubClass(id);
		else
			ExpandTradeSkillSubClass(id);
		end
		return;
	end
	DiceMasterTradeSkillFrame.selectedSkill = id;
	--SelectTradeSkill(id);
	if ( GetTradeSkillSelectionIndex() > GetNumTradeSkills() ) then
		return;
	end
	local color = TradeSkillTypeColor[skillType];
	if ( color ) then
		DiceMasterTradeSkillHighlight:SetVertexColor(color.r, color.g, color.b);
	end
	
	-- Set statusbar info
	local skillLineName, skillLineRank, skillLineMaxRank = GetTradeSkillLine();
	DiceMasterTradeSkillRankFrameSkillName:SetText(skillLineName);
	DiceMasterTradeSkillRankFrame:SetStatusBarColor(0.0, 0.0, 1.0, 0.5);
	DiceMasterTradeSkillRankFrameBackground:SetVertexColor(0.0, 0.0, 0.75, 0.5);
	DiceMasterTradeSkillRankFrame:SetMinMaxValues(0, skillLineMaxRank);
	DiceMasterTradeSkillRankFrame:SetValue(skillLineRank);
	if ( skillLineName ~= "" ) then
		DiceMasterTradeSkillRankFrameSkillRank:SetText(skillLineRank.."/"..skillLineMaxRank);
	else
		DiceMasterTradeSkillRankFrameSkillRank:SetText("");
	end

	DiceMasterTradeSkillSkillName:SetText(skillName);
	if ( GetTradeSkillDescription(id) ) then
		DiceMasterTradeSkillDescription:Show();
		DiceMasterTradeSkillDescription:SetText(GetTradeSkillDescription(id));
		DiceMasterTradeSkillReagentLabel:SetPoint("TOPLEFT", DiceMasterTradeSkillDescription, "BOTTOMLEFT", 0, -10)
	else
		DiceMasterTradeSkillDescription:Hide();
		DiceMasterTradeSkillDescription:SetText("");
		DiceMasterTradeSkillReagentLabel:SetPoint("TOPLEFT", 8, -47)
	end
	if ( GetTradeSkillCooldown(id) ) then
		DiceMasterTradeSkillSkillCooldown:SetText("Cooldown remaining: "..SecondsToTime(GetTradeSkillCooldown(id)));
	else
		DiceMasterTradeSkillSkillCooldown:SetText("");
	end
	DiceMasterTradeSkillSkillIcon:SetNormalTexture(GetTradeSkillIcon(id));
	local minMade, maxMade = GetTradeSkillNumMade(id);
	if ( maxMade > 1 ) then
		if ( minMade == maxMade ) then
			DiceMasterTradeSkillSkillIconCount:SetText(minMade);
		else
			DiceMasterTradeSkillSkillIconCount:SetText(minMade.."-"..maxMade);
		end
		if ( DiceMasterTradeSkillSkillIconCount:GetWidth() > 39 ) then
			DiceMasterTradeSkillSkillIconCount:SetText("~"..floor((minMade + maxMade)/2));
		end
	else
		DiceMasterTradeSkillSkillIconCount:SetText("");
	end
	
	-- Reagents
	local creatable = 1;
	local numReagents = GetTradeSkillNumReagents(id);
	for i=1, numReagents, 1 do
		local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(id, i);
		local reagent = _G["DiceMasterTradeSkillReagent"..i]
		local name = _G["DiceMasterTradeSkillReagent"..i.."Name"];
		local count = _G["DiceMasterTradeSkillReagent"..i.."Count"];
		if ( not reagentName or not reagentTexture ) then
			reagent:Hide();
		else
			reagent:Show();
			SetItemButtonTexture(reagent, reagentTexture);
			name:SetText(reagentName);
			-- Grayout items
			if ( playerReagentCount < reagentCount ) then
				SetItemButtonTextureVertexColor(reagent, 0.5, 0.5, 0.5);
				name:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
				creatable = nil;
			else
				SetItemButtonTextureVertexColor(reagent, 1.0, 1.0, 1.0);
				name:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
			end
			if ( playerReagentCount >= 100 ) then
				playerReagentCount = "*";
			end
			count:SetText(playerReagentCount.." /"..reagentCount);
		end
	end
	-- Place reagent label
	local reagentToAnchorTo = numReagents;
	if ( (numReagents > 0) and (mod(numReagents, 2) == 0) ) then
		reagentToAnchorTo = reagentToAnchorTo - 1;
	end
	
	for i=numReagents + 1, 8, 1 do
		_G["DiceMasterTradeSkillReagent"..i]:Hide();
	end

	local spellFocus = GetTradeSkillTools(id);
	if ( spellFocus ) then
		DiceMasterTradeSkillRequirementLabel:Show();
		DiceMasterTradeSkillRequirementText:SetText(spellFocus);
	else
		DiceMasterTradeSkillRequirementLabel:Hide();
		DiceMasterTradeSkillRequirementText:SetText("");
	end

	if ( creatable ) then
		DiceMasterTradeSkillCreateButton:Enable();
		DiceMasterTradeSkillCreateAllButton:Enable();
	else
		DiceMasterTradeSkillCreateButton:Disable();
		DiceMasterTradeSkillCreateAllButton:Disable();
	end
	DiceMasterTradeSkillDetailScrollFrame:UpdateScrollChildRect();

	-- Reset the number of items to be created
	DiceMasterTradeSkillInputBox:SetNumber(GetTradeskillRepeatCount());
end

function Me.TradeSkillSkillButton_OnClick(self, button)
	if ( button == "LeftButton" ) then
		Me.TradeSkillFrame_SetSelection(self:GetID());
		Me.TradeSkillFrame_Update();
	end
end

function Me.TradeSkillBuildFilteredList()
	local search = DiceMasterTradeSkillSearchBar:GetText():lower()
	if #search < 2 then
		-- Ignore searches less than two characters
		if filteredList then
			filteredList = nil
		end
	else
		-- build new list
		filteredList = {}
		for i = 1, #Me.Profile.recipes do
			local recipe = Me.Profile.recipes[i]
			if Me.Profile.recipes[i].type == "header" then
				tinsert( filteredList, recipe )
			elseif Me.Profile.recipes[i].expanded then
				local item = recipe.item or nil;
				if item then
					for param = 1, #TradeSkillSearchParameters do
						local parameter = TradeSkillSearchParameters[param]
						if item[parameter] and item[parameter]:lower():find( search ) and not ( tContains( filteredList, Me.Profile.recipes[i] ) ) then
							tinsert( filteredList, recipe )
						end
					end
				end
			end
		end
	end
end

function Me.TradeSkillCollapseAllButton_OnClick(self)
	if (self.collapsed) then
		self.collapsed = nil;
		ExpandTradeSkillAll();
	else
		self.collapsed = 1;
		DiceMasterTradeSkillListScrollFrameScrollBar:SetValue(0);
		CollapseTradeSkillAll();
	end
end

function Me.TradeSkillFrameIncrement_OnClick(self)
	if ( DiceMasterTradeSkillInputBox:GetNumber() < 100 ) then
		DiceMasterTradeSkillInputBox:SetNumber(DiceMasterTradeSkillInputBox:GetNumber() + 1);
	end
end

function Me.TradeSkillFrameDecrement_OnClick(self)
	if ( DiceMasterTradeSkillInputBox:GetNumber() > 0 ) then
		DiceMasterTradeSkillInputBox:SetNumber(DiceMasterTradeSkillInputBox:GetNumber() - 1);
	end
end