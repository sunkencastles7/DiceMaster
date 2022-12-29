-------------------------------------------------------------------------------
-- Dice Master (C) 2022 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

local TRAIT_COOLDOWN_TIMES = {
	["15S"] = 15; ["20S"] = 20; ["30S"] = 30; ["1M"] = 60; ["2M"] = 120; ["3M"] = 180; ["4M"] = 240; ["5M"] = 300; ["10M"] = 600; ["15M"] = 900; ["20M"] = 1200; ["30M"] = 1800; ["1H"] = 3600; ["2H"] = 7200; ["3H"] = 10800; ["4H"] = 14400; ["5H"] = 18000; ["1D"] = 86400; ["2D"] = 172800; ["3D"] = 259200; ["4D"] = 345600; ["5D"] = 432000; ["1W"] = 604800;
}

-------------------------------------------------------------------------------
Me.playerTraitTooltipOpen = false
Me.playerTraitTooltipName = nil
Me.playerTraitTooltipIndex = nil

-------------------------------------------------------------------------------

function Me.CheckTooltipForTerms( text )
	local termsTable = {}
	for k, v in pairs( Me.RollList ) do
		for i = 1, #v do
			local matchFound = string.match( text, "<" .. v[i].subName .. ">" )
			if matchFound then
				local desc = gsub( v[i].desc, "Roll", "An attempt" )
				local termsString = Me.FormatIconForText( v[i].iconID ) .. " |cFFFFFFFF" .. v[i].name .. "|r|n|cFFffd100" .. desc .. "|r|n|cFF707070(Modified by " .. v[i].stat .. " + " .. v[i].name .. ")|r"
				
				if not tContains( termsTable, termsString ) then
					tinsert( termsTable, termsString )
				end
			end
		end
	end
	for k, v in pairs( Me.TermsList ) do
		for i = 1, #v do
			local matchFound = string.match( text, "<" .. v[i].subName .. ">" )
			if matchFound then
				local termsString = Me.FormatIconForText( v[i].iconID ) .. " |cFFFFFFFF" .. v[i].name .. "|r|n|cFFffd100" .. v[i].desc .. "|r"
				if not tContains( termsTable, termsString ) then
					tinsert( termsTable, termsString )
				end
			end
		end
	end
	if #termsTable > 0 then
		table.sort( termsTable )
		local tooltip = termsTable[1]
		for i = 2, #termsTable do
			tooltip = tooltip .. "|n|n" .. termsTable[i]
		end
		DiceMasterTooltip.TextLeft1:SetText( tooltip )
		DiceMasterTooltip:Show()
	end
end

-------------------------------------------------------------------------------
function Me.UpdateTraitTooltip( name, index )
	
	if Me.playerTraitTooltipOpen and Me.playerTraitTooltipName == name and Me.playerTraitTooltipIndex == index then
		Me.OpenTraitTooltip( nil, name, index )
	end
end

-------------------------------------------------------------------------------
function Me.OpenTraitTooltip( owner, trait, index )
	local playername = nil
	
	if type(trait) == "string" then
		-- player trait
		
		playername = trait
		
		Me.playerTraitTooltipOpen  = true
		Me.playerTraitTooltipName  = trait
		Me.playerTraitTooltipIndex = index
		trait = Me.inspectData[trait].traits[index]
	end
	
	if owner then
		
		GameTooltip:SetOwner( owner, "ANCHOR_RIGHT" )
	end
	
	GameTooltip:ClearLines()
	
	if trait.name then		
		if trait.icon then
			-- icon with name
			DiceMasterTooltipIcon.icon:SetTexture( trait.icon )
			DiceMasterTooltipIcon:Show()
		else
			DiceMasterTooltipIcon:Hide()
		end
		GameTooltip:AddLine( trait.name, 1, 1, 1, true )
	end
	 
	if trait.usage then
		local usage = Me.FormatUsage( trait.usage, playername )
		local range = Me.FormatRange( trait.range or nil )
		
		if trait.usage == "NONE" then
			usage = nil
		end
		
		if not ( trait.range ) or trait.range == "NONE" then
			range = nil
		end
		
		if usage and usage ~= "Passive" and range then
			local range = Me.FormatRange( trait.range )
			GameTooltip:AddDoubleLine( usage, range, 1, 1, 1, 1, 1, 1, true )
		elseif range and not ( usage ) then
			GameTooltip:AddLine( range, 1, 1, 1, true )
		elseif usage and not ( range ) then
			GameTooltip:AddDoubleLine( usage, nil, 1, 1, 1, 1, 1, 1, true )
		end
		
		if trait.usage and usage ~= "Passive" and trait.castTime then
			local castTime = Me.FormatCastTime( trait.castTime )
			if trait.cooldown and trait.cooldown ~= "NONE" then
				local cooldown = Me.FormatCooldown( trait.cooldown )
				GameTooltip:AddDoubleLine( castTime, cooldown, 1, 1, 1, 1, 1, 1, true )
			else
				GameTooltip:AddDoubleLine( castTime, nil, 1, 1, 1, 1, 1, 1, true )
			end
		end
	end
	
	DiceMasterTooltipIcon.approved:Hide()
	if trait.approved and trait.approved > 0 and Me.PermittedUse() then
		if trait.approved == 1 then
			DiceMasterTooltipIcon.approved:SetTexCoord( 0, 0.5, 0.5, 1 )
		elseif trait.approved == 2 then
			DiceMasterTooltipIcon.approved:SetTexCoord( 0, 0.5, 0, 0.5 )
		end
		DiceMasterTooltipIcon.approved:Show()
	end
	
	if owner and owner.editable_trait then
		owner:SetScript( "OnUpdate", nil )
	end
	
	if trait.cooldown and owner and owner.editable_trait then
		if owner.cooldown:GetCooldownDuration() > 0 then
			local currentTime = GetTime()
			local startTime = owner.cooldown.StartTime
			local duration = TRAIT_COOLDOWN_TIMES[ trait.cooldown ] or 0
			
			local timeElapsed = math.ceil( duration - ( currentTime - startTime ) )
			timeElapsed = string.lower( SecondsToTime( timeElapsed, false ) )
			if timeElapsed and timeElapsed ~= "" then
				GameTooltip:AddLine( "Cooldown remaining: " .. timeElapsed, 1, 1, 1, true )
			end
			
			owner:SetScript( "OnUpdate", function( self )
				if GameTooltip:IsOwned( self ) then
					self:GetScript("OnEnter")( self )
				end
			end)
		end
		if owner.cooldown.text:IsShown() then
			local cooldown = owner.cooldown.text:GetText()
			cooldown = cooldown:gsub( "T", "" )
			if cooldown == "1" then
				GameTooltip:AddLine( "Cooldown remaining: " .. cooldown .. " turn", 1, 1, 1, true )
			else
				GameTooltip:AddLine( "Cooldown remaining: " .. cooldown .. " turns", 1, 1, 1, true )
			end
		end
	end
	
	if trait.desc then
		if Me.db.global.hideTips then
			Me.CheckTooltipForTerms( trait.desc )
		end
		local desc = Me.FormatDescTooltip( trait.desc, playername, index )
		GameTooltip:AddLine( desc, 1, 0.82, 0, true )
	end
	
	local usable = ""
	local guildName, guildRankName, guildRankIndex = GetGuildInfo( "player" )
	
	if owner and owner:GetParent():GetName() == "DiceMasterInspectFrame" and not UnitIsUnit("target", "player") and Me.IsOfficer() then
		local found = false;
		if trait.officers then
			for i=1,#trait.officers do
				if trait.officers[i] == UnitName("player") then	
					found = true;
					break;
				end
			end
		end
		if not found then
			usable = "<Right Click to Approve>|n"
		else
			usable = "<Right Click to Remove Approval>|n"
		end
	end
	
	if trait.effects and next(trait.effects) and owner and owner:GetParent():GetName() == "DiceMasterPanel" then
		usable = usable .. "<Right Click to Use>|n"
	end
	
	if owner and owner:GetParent():GetName() == "DiceMasterPanel" then
		GameTooltip:AddLine( "<Left Click to Edit>", 0.44, 0.44, 0.44, true )
	end
	
	GameTooltip:AddLine( usable .. "<Shift+Click to Link to Chat>", 0.44, 0.44, 0.44, true )
	
	if trait.officers and Me.PermittedUse() then
		local approval
		if trait.officers[2] then
			approval = "|TInterface/AddOns/DiceMaster/Texture/trait-approved:14:14:0:0:32:32:2:14:2:14|t Approved by " .. trait.officers[1] .. " and " .. trait.officers[2]
			GameTooltip:AddLine( approval, 0, 1, 0, true )
		elseif trait.officers[1] then
			approval = "|TInterface/AddOns/DiceMaster/Texture/trait-approved:14:14:0:0:32:32:2:14:18:30|t Approved by " .. trait.officers[1]
			GameTooltip:AddLine( approval, 1, 1, 0, true )
		end
	end
	
	if Me.useCorruptedSkins then
		GameTooltip_SetBackdropStyle( GameTooltip, GAME_TOOLTIP_BACKDROP_STYLE_CORRUPTED_ITEM );
	end
	
    GameTooltip:Show()
end

-------------------------------------------------------------------------------
function Me.CloseTraitTooltip()
	Me.playerTraitTooltipOpen = false
    GameTooltip:Hide()
	DiceMasterTooltipIcon:Hide()
	DiceMasterTooltipIcon.approved:Hide()
	DiceMasterTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Handler for trait tooltips.
--
local function OnEnter( self )
	
	self.highlight:Show()
	
	if self.customTooltip then
		GameTooltip:SetOwner( self, "ANCHOR_RIGHT" )
		GameTooltip:ClearLines()
		GameTooltip:AddLine( self.customTooltip, 1, 1, 1, true )
		GameTooltip:Show()
		return
	end
	
	if not self.trait and not self.traitPlayer then return end
	
	if self.trait then
		Me.OpenTraitTooltip( self, self.trait, nil )
	elseif self.traitPlayer then 
		Me.OpenTraitTooltip( self, self.traitPlayer, self.traitIndex )
	else
		return
	end
	 
end

local function OnLeave( self )
	if not self.selected then
		self.highlight:Hide()
	end
	if self.traitPlayer then
		Me.playerTraitTooltipOpen = false
	end
	
    GameTooltip:Hide()
	DiceMasterTooltipIcon:Hide()
	DiceMasterTooltipIcon.approved:Hide()
	DiceMasterTooltip:Hide()
end

-------------------------------------------------------------------------------
local methods = {
	---------------------------------------------------------------------------
	-- Set a static texture for this button.
	--
	-- Overrides SetTrait.
	--
	SetTexture = function( self, tex )
		self.trait       = nil
		self.traitPlayer = nil
		--self.traitIndex  = nil
		self.icon:SetTexture( tex )
		self.icon:SetVertexColor( 1, 1, 1 )
		self.count:SetText( "")
		self.count:Hide()
		self.secret:Hide()
	end;
	
	---------------------------------------------------------------------------
	-- Hook this button up to a direct trait.
	--
	SetTrait = function( self, trait )
		self.trait = trait
		self:Refresh()
	end;
	
	---------------------------------------------------------------------------
	-- Hook this button up to a player trait.
	--
	SetPlayerTrait = function( self, player, index )
		self.trait = nil
		self.traitPlayer = player
		self.traitIndex  = index
		self:Refresh()
	end;
	
	---------------------------------------------------------------------------
	-- Refresh after a trait changes.
	--
	Refresh = function( self )
		self.icon:SetVertexColor( 1, 1, 1 )
		self.count:SetText( "")
		self.count:Hide()
		self.secret:Hide()
		if self.trait then
			self.icon:SetTexture( self.trait.icon )
		elseif self.traitPlayer then		
			self.icon:SetTexture( Me.inspectData[self.traitPlayer].traits[self.traitIndex].icon )
			if self:GetParent() == DiceMasterPanel then
				if Me.db.global.showUses then
					local usage = Me.inspectData[self.traitPlayer].traits[self.traitIndex].usage or "PASSIVE"
					if usage:find("USE") then
						local uses = usage:gsub( "USE", "" )
						self.count:SetText( uses )
						self.count:Show()
					end
				end
			end
		end
		if self.traitPlayer then
			if Me.inspectData[self.traitPlayer].traits[self.traitIndex].secret1Enabled then
				self.secret:Show()
				self.secret.one:Show()
			end
			if Me.inspectData[self.traitPlayer].traits[self.traitIndex].secret2Enabled then
				self.secret:Show()
				self.secret.two:Show()
			end
			if Me.inspectData[self.traitPlayer].traits[self.traitIndex].secret3Enabled then
				self.secret:Show()
				self.secret.three:Show()
			end
		end
	end;
	
	---------------------------------------------------------------------------
	-- "Select" this trait, i.e. make it glow.
	--
	Select = function( self, selected )
		self.selected = selected
		if selected then
			self.highlight:Show()
		else
			self.highlight:Hide()
		end
	end;
	
	SetCustomTooltip = function( self, text )
		self.customTooltip = text
	end;
}

-------------------------------------------------------------------------------
-- Initialize a new trait button.
--
function Me.TraitButton_Init( self )

	for k, v in pairs( methods ) do
		self[k] = v
	end
	 
	self:SetScript( "OnEnter", OnEnter )
	self:SetScript( "OnLeave", OnLeave )
	self.editable_trait = false 
end

