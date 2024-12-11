-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

-------------------------------------------------------------------------------

function Me.UnitInfo_UpdateStatisticsFrame( statistics, statisticsFrame, isEditable )
	
	if not ( statistics and statisticsFrame ) then
		return;
	end

	statisticsFrame.contentHeight = 0;
	statisticsFrame.lastBullet = nil;

	local numCriteria = #statistics;
	statisticsFrame.numCriteria = numCriteria
	statisticsFrame.bulletPool:ReleaseAll();

	for criteriaIndex = 1, numCriteria do
		local statisticFrame = statisticsFrame.bulletPool:Acquire();
		statisticFrame:SetUp(criteriaIndex, statistics[criteriaIndex], statisticsFrame, isEditable);
	end

	if isEditable then
		local statisticFrame = statisticsFrame.bulletPool:Acquire();
		statisticFrame:SetUp(nil, nil, statisticsFrame, false, true);
		statisticsFrame.button.VisibileButton:Show();
	else
		statisticsFrame.button.VisibileButton:Hide();
	end

	statisticsFrame.descriptionBG:ClearAllPoints();
	statisticsFrame.descriptionBG:SetPoint("TOPLEFT", statisticsFrame.button, "BOTTOMLEFT", 1, 0);
	if statisticsFrame.lastBullet then
		statisticsFrame.descriptionBG:SetPoint("BOTTOMRIGHT", statisticsFrame.description, 9, statisticsFrame.contentHeight * -1 );
	end
end

function Me.UnitInfo_UpdateTraitsFrame( traits, traitsFrame, isEditable )
	
	if not ( traits and traitsFrame ) then
		return;
	end
	
	traitsFrame.contentHeight = 0;
	traitsFrame.lastTrait = nil; 
	
	local numCriteria = #traits;
	traitsFrame.numCriteria = numCriteria
	traitsFrame.bulletPool:ReleaseAll();

	traitsFrame.bulletPool:ReleaseAll();
	for traitIndex = 1 , numCriteria do
		local traitFrame = traitsFrame.bulletPool:Acquire();
		traitFrame:SetUp(traitIndex, traits[traitIndex], traitsFrame, isEditable);
	end
	
	if isEditable then
		local traitFrame = traitsFrame.bulletPool:Acquire();
		traitFrame:SetUp(nil, nil, traitsFrame, false, true);
		traitsFrame.button.VisibileButton:Show();
	else
		traitsFrame.button.VisibileButton:Hide();
	end
	
	traitsFrame.descriptionBG:ClearAllPoints();
	traitsFrame.descriptionBG:SetPoint("TOPLEFT", traitsFrame.button, "BOTTOMLEFT", 1, 0);
	if traitsFrame.lastTrait then
		traitsFrame.descriptionBG:SetPoint("BOTTOMRIGHT", traitsFrame.description, 9, traitsFrame.contentHeight * -1 );
	end
end

function Me.UnitInfo_UpdateDescriptionFrame( description, descriptionFrame, isEditable )
	
	if not ( description and descriptionFrame ) then
		return;
	end

	descriptionFrame.descriptionEditable:SetText( description or "" );
	
	if isEditable then
		descriptionFrame.button.VisibileButton:Show();
	else
		descriptionFrame.button.VisibileButton:Hide();
	end
	
	descriptionFrame.descriptionBG:ClearAllPoints();
	descriptionFrame.descriptionBG:SetPoint("TOPLEFT", descriptionFrame.button, "BOTTOMLEFT", 1, 0);
end

function Me.UnitInfo_UpdateButtonState( button )
	local oldtex = button.textures.expanded;
	if button:GetParent().expanded then
		button.tex = button.textures.expanded;
		oldtex = button.textures.collapsed;
		button.expandedIcon:SetTextColor(PAPER_FRAME_EXPANDED_COLOR:GetRGB());
		button.title:SetTextColor(PAPER_FRAME_EXPANDED_COLOR:GetRGB());
	else
		button.tex = button.textures.collapsed;
		button.expandedIcon:SetTextColor(PAPER_FRAME_COLLAPSED_COLOR:GetRGB());
		button.title:SetTextColor(PAPER_FRAME_COLLAPSED_COLOR:GetRGB());
	end
	
	oldtex.up[1]:Hide();
	oldtex.up[2]:Hide();
	oldtex.up[3]:Hide();
	oldtex.down[1]:Hide();
	oldtex.down[2]:Hide();
	oldtex.down[3]:Hide();


	button.tex.up[1]:Show();
	button.tex.up[2]:Show();
	button.tex.up[3]:Show();
	button.tex.down[1]:Hide();
	button.tex.down[2]:Hide();
	button.tex.down[3]:Hide();
end

-------------------------------------------------------------------------------

local statisticMethods = {
	SetUp = function( self, index, statistic, frame, isEditable, isLast )
		if ( statistic and statistic.name and statistic.value and statistic.tooltip ) or isLast then
			if isLast then
				self.index = nil;
				self.tooltipTitle = "Add New Statistic"
				self.tooltipInfo = "Add a new statistic to this category.";
				self.isEditable = false;
				self.TextLeft:SetText( "Add New..." );
				self.TextRight:SetText( "" );
				self.Icon:SetTexture( "Interface/PaperDollInfoFrame/Character-Plus" );
				self.IconBorder:Hide();
				self.IconBG:Hide();
			else
				self.index = index;
				self.tooltipTitle = statistic.name
				self.tooltipInfo = statistic.tooltip
				self.isEditable = isEditable;
				self.TextLeft:SetText( statistic.name .. ":" );
				self.Icon:SetTexture( statistic.icon or "Interface/Icons/inv_misc_questionmark" );
				self.IconBorder:Show();
				self.IconBG:Show();
			
				local TEXT_SUBS = {
					{"<HP>", "|TInterface/AddOns/DiceMaster/Texture/health-heart:12|t"},
					{"<AR>", "|TInterface/AddOns/DiceMaster/Texture/armour-icon:12|t"},
				}
			
				local text = statistic.value
				for i = 1, #TEXT_SUBS do
					text = gsub( text, TEXT_SUBS[i][1], TEXT_SUBS[i][2] )
				end
			
				-- <img> </img>
				text = gsub( text, "<img>","|T" )
				text = gsub( text, "</img>",":12|t" )
			
				-- <color=rrggbb> </color>
				text = gsub( text, "<color=(.-)>","|cFF%1" )
				text = gsub( text, "</color>","|r" )
			
				self.TextRight:SetText( text );
			end

			if (not frame.lastBullet) then
				self:SetPoint("TOPLEFT", frame.descriptionBG, "TOPLEFT", 13, -11);
			else
				self:SetPoint("TOPLEFT", frame.lastBullet, "BOTTOMLEFT", 0, -14);
			end
			frame.lastBullet = self;

			local textHeight = self.TextLeft:GetHeight();
			self:SetSize(self.TextLeft:GetStringWidth() + self.TextRight:GetStringWidth() + 27, textHeight);
			frame.contentHeight = frame.contentHeight + textHeight + 14;

			if frame.expanded then
				self:Show();
			else
				self:Hide();
			end
		end
	end;
	
	OnClick = function( self, button )
		if self.isEditable and self.index then
			Me.UnitManagerFieldEditor_Edit( "statistic", self.index )
		end
	end;

	OnEnter = function( self )
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
		GameTooltip:SetText(self.tooltipTitle, HIGHLIGHT_FONT_COLOR:GetRGB());
		GameTooltip:AddLine(self.tooltipInfo, 1, 0.81, 0, true);
		
		if self.isEditable then
			GameTooltip:AddLine( "<Left Click to Edit>", 0.44, 0.44, 0.44, true);
		end
		
		GameTooltip:Show();
	end;
	
	OnLeave = function( self )
		GameTooltip:Hide();
	end;
}

local traitMethods = {
	SetUp = function( self, index, trait, frame, isEditable, isLast )
		if ( trait and trait.name and trait.icon and trait.uses and trait.description ) or isLast then
			
			if isLast then
				self.index = nil;
				self.Text:SetText( "Add New..." );
				self.Icon:SetTexture("Interface/PaperDollInfoFrame/Character-Plus");
				self.abilityName = "Add New Trait";
				self.abilityUses = nil;
				self.abilityDescription = "Add a new trait to this category.";
				self.isEditable = false;
				self.IconBorder:Hide();
				self.IconBG:Hide();
			else
				self.index = index;
				self.Text:SetText(trait.name);
				self.Icon:SetTexture(trait.icon);
				self.abilityName = trait.name;
				self.abilityUses = trait.uses;
				self.abilityDescription = trait.description;
				self.isEditable = isEditable;
				self.IconBorder:Show();
				self.IconBG:Show();
			end

			if (not frame.lastTrait) then
				self:SetPoint("TOPLEFT", frame.descriptionBG, "TOPLEFT", 8, -11);
			else
				self:SetPoint("TOP", frame.lastTrait, "BOTTOM", 0, -9);
			end
			frame.lastTrait = self;
			
			frame.contentHeight = frame.contentHeight + self:GetHeight() + 9;

			if frame.expanded then
				self:Show();
			else
				self:Hide();
			end
		end
	end;
	
	OnClick = function( self, button )
		if self.isEditable and self.index then
			Me.UnitManagerFieldEditor_Edit( "trait", self.index )
		end
	end;
	
	OnEnter = function( self )
		GameTooltip:SetOwner(self.Icon, "ANCHOR_RIGHT", 6, 0);
		GameTooltip:SetText(self.abilityName, HIGHLIGHT_FONT_COLOR:GetRGB());
		GameTooltip:AddLine(self.abilityUses, 1, 1, 1, true);	
		GameTooltip:AddLine( Me.FormatDescTooltip( self.abilityDescription ), 1, 0.81, 0, true);
		
		if self.isEditable then
			GameTooltip:AddLine( "<Left Click to Edit>", 0.44, 0.44, 0.44, true);
		end
		
		if self.index then
			GameTooltip:AddLine( "<Shift+Click to Link to Chat>", 0.44, 0.44, 0.44, true);
		end

		GameTooltip:Show();
	end;
	
	OnLeave = function( self )
		GameTooltip:Hide();
	end;
}

local infoMethods = {	
	ToggleHeaders = function( self )
		local isEditable = self.isEditable;
		local hideHeaders;
		self.expanded = not self.expanded;
		hideHeaders = not self.expanded;

		if hideHeaders then
			self.button.expandedIcon:SetText("+");
			self.description:Hide();
			self.descriptionEditable:Hide();
			if ( self.bulletPool and self.numCriteria ) then
				for frame, v in self.bulletPool:EnumerateActive() do
					frame:Hide()
				end
			end
			self.descriptionBG:Hide();
			self.descriptionBGBottom:Hide();
		else
			if ( not isEditable ) then
				self.descriptionEditable:Disable();
				if strlen(self.description:GetText() or "") > 0 then
					self.description:Show();
				else
					self.description:Hide();
				end
				self.description:SetWidth(self:GetWidth() -20);
			else
				if strlen(self.descriptionEditable:GetText() or "") > 0 then
					self.descriptionEditable:Show();
					self.descriptionEditable:Enable();
				else
					self.descriptionEditable:Hide();
				end
				self.descriptionEditable:SetWidth(self:GetWidth() -20);
			end
			if ( self.bulletPool and self.numCriteria ) then
				for frame, v in self.bulletPool:EnumerateActive() do
					frame:Show()
				end
			end
			if self.button then
				self.descriptionBG:Show();
				self.descriptionBGBottom:Show();
				self.button.expandedIcon:SetText("-");
			end
		end
		Me.UnitInfo_UpdateButtonState( self.button )
		self:ShiftHeaders( self.index or 1, self:GetParent() )
		
		PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
	end;
	
	ShiftHeaders = function( self, index, parentFrame )
		local usedHeaders = parentFrame.usedHeaders
		if not usedHeaders[index] then
			return;
		end

		for i=index,#usedHeaders-1 do
			if usedHeaders[i].descriptionBG:IsShown() then
				usedHeaders[i+1]:SetPoint("TOP", usedHeaders[i].descriptionBG, "BOTTOM", 0 , -6);
			else
				usedHeaders[i+1]:SetPoint("TOP", usedHeaders[i], "BOTTOM", 0 , -6);
			end
			
		end
	end;

	OnToggleVisibility = function ( self, frame, button )
		frame.isVisible = not( frame.isVisible );
		frame.NormalTexture:SetAtlas( "gm-icon-visible" .. ( frame.isVisible and "" or "dis") );
		frame.NormalTexture:SetAlpha( frame.isVisible and 1 or 0.5 );
		frame:GetScript("OnEnter")(frame, button);

		-- TODO
		-- UNIT_EDITOR_UNITS[ unitEditor.selectedUnitID ].isVisible = isVisible;
		-- Me.UnitManagerUnitEditor_UpdateUnitList()
	end;
}

-------------------------------------------------------------------------------

function Me.UnitInfoStatistic_Init( self )

	for k, v in pairs( statisticMethods ) do
		self[k] = v
	end
	
end

function Me.UnitInfoTrait_Init( self )

	for k, v in pairs( traitMethods ) do
		self[k] = v
	end
	
end

function Me.UnitInfo_Init( self )

	for k, v in pairs( infoMethods ) do
		self[k] = v
	end
	
	self.expanded = false;
	self.description:Hide();
	self.descriptionEditable:Hide();
	self.descriptionBG:Hide();
	self.descriptionBGBottom:Hide();
	self.button.expandedIcon:SetText("+");
end
