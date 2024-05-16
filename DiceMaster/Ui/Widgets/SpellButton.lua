-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

local DICEMASTER_DICETYPES = { "d4", "d6", "d8", "d10", "d12", "d20" };

local function HexToRGBPerc( hex )
	local rhex, ghex, bhex, base
    if strlen(hex) == 6 then
        rhex, ghex, bhex = strmatch(hex, "(%x%x)(%x%x)(%x%x)")
        base = 255
    end
    if not (rhex and ghex and bhex) then
        return 1, 1, 1
    else
        return tonumber(rhex, 16)/base, tonumber(ghex, 16)/base, tonumber(bhex, 16)/base
    end
end

local actionIcons = {
	["Movement"] = { 0, 0.25, 0, 0.25 };
	["Action"] = { 0.25, 0.5, 0, 0.25 };
	["Bonus Action"] = { 0.5, 0.75, 0, 0.25 };
}

local function FormatDescription( text )
	local warningIcon = CreateAtlasMarkup("Professions_Icon_Warning", 16, 16);
	text = text:gsub( "{WARNING}", warningIcon );

	return text
end

-------------------------------------------------------------------------------
function Me.OpenSpellTooltip( owner, spellID )
	-- Sanitise
	if not( owner and spellID ) then
		return
	end
	local spell;
	if type(spellID) == "number" then
		spell = DiceMaster4.SpellList["Player's Handbook"][spellID];
	end
	if not( spell ) then return end	
	-- Anchor to the provided button "owner"
	if owner then
		DiceMasterSpellTooltip:SetOwner( owner );
	end
	
	DiceMasterSpellTooltip:ClearAllLines()

	local totalHeight = 0;
	local hasBottomBar = false;
	
	if spell.name then		
		DiceMasterSpellTooltip.Name:SetText( spell.name );
		totalHeight = totalHeight + DiceMasterSpellTooltip.Name:GetHeight();
	end
	if spell.level then
		if type( spell.level ) == "number" then
			DiceMasterSpellTooltip.Level:SetText( "Level " .. spell.level );
			DiceMasterSpellTooltip.Level:Show();
			totalHeight = totalHeight + DiceMasterSpellTooltip.Level:GetHeight();
		else
			DiceMasterSpellTooltip.Level:Hide();
		end
	end
	if spell.school then
		DiceMasterSpellTooltip.Cantrip:Hide();
		if not( spell.level and spell.level == "Cantrip" ) then
			DiceMasterSpellTooltip.School:SetText( spell.school .. " Spell" );
			DiceMasterSpellTooltip.School:ClearAllPoints();
			DiceMasterSpellTooltip.School:SetPoint( "LEFT", DiceMasterSpellTooltip.Level, "RIGHT", 3, 0);
		elseif spell.level and spell.level == "Cantrip" then
			DiceMasterSpellTooltip.School:SetText( spell.school );
			DiceMasterSpellTooltip.School:ClearAllPoints();
			DiceMasterSpellTooltip.School:SetPoint( "TOPLEFT", DiceMasterSpellTooltip.Name, "BOTTOMLEFT", 0, 0);
			DiceMasterSpellTooltip.Cantrip:Show();
			totalHeight = totalHeight + DiceMasterSpellTooltip.School:GetHeight();
		end
	end
	if spell.damage then
		DiceMasterSpellTooltip.Damage:Show();
		DiceMasterSpellTooltip.Damage:SetText( spell.damage .. " Damage" );
		totalHeight = totalHeight + DiceMasterSpellTooltip.Damage:GetHeight();
		if spell.dice then
			local hex = DiceMaster4.DamageTypes[spell.damageType]["hex"];
			local r, g, b = HexToRGBPerc( hex:sub(3) );
			local die = spell.dice:sub(2);
			DiceMasterSpellTooltip.DamageDiceTexture:SetTexture( "Interface/AddOns/DiceMaster/Texture/DamageDice/" .. die );
			print(r,g,b);
			DiceMasterSpellTooltip.DamageDiceTexture:SetVertexColor( r, g, b );
			DiceMasterSpellTooltip.DamageDiceTexture:Show();
			DiceMasterSpellTooltip.DamageDiceTextureAdd:SetTexture( "Interface/AddOns/DiceMaster/Texture/DamageDice/" .. die );
			print(r,g,b);
			DiceMasterSpellTooltip.DamageDiceTextureAdd:SetVertexColor( r, g, b );
			DiceMasterSpellTooltip.DamageDiceTextureAdd:Show();
			DiceMasterSpellTooltip.DamageDice:SetText( "|c" .. hex .. spell.dice .. "|r" );
			DiceMasterSpellTooltip.DamageDice:Show();
			DiceMasterSpellTooltip.DamageTypeTexture:SetTexture( "Interface/AddOns/DiceMaster/Texture/Damage/" .. spell.damageType ); 
			DiceMasterSpellTooltip.DamageTypeTexture:Show();
			DiceMasterSpellTooltip.DamageTypeText:SetText( "|c" .. hex .. spell.damageType .. "|r" );
			DiceMasterSpellTooltip.DamageTypeText:Show();
			DiceMasterSpellTooltip.Description:ClearAllPoints();
			DiceMasterSpellTooltip.Description:SetPoint("TOPLEFT", DiceMasterSpellTooltip.DamageDiceTexture, "BOTTOMLEFT", 0, -5);
			totalHeight = totalHeight + DiceMasterSpellTooltip.DamageDiceTexture:GetHeight();
		end
	else
		DiceMasterSpellTooltip.Damage:Hide();
		DiceMasterSpellTooltip.DamageDiceTexture:Hide();
		DiceMasterSpellTooltip.DamageDiceTextureAdd:Hide();
		DiceMasterSpellTooltip.DamageDice:Hide();
		DiceMasterSpellTooltip.DamageTypeTexture:Hide();
		DiceMasterSpellTooltip.DamageTypeText:Hide();
		DiceMasterSpellTooltip.Description:ClearAllPoints();
		if DiceMasterSpellTooltip.Level:IsShown() then
			DiceMasterSpellTooltip.Description:SetPoint("TOPLEFT", DiceMasterSpellTooltip.Level, "BOTTOMLEFT", 0, -10);
		else
			DiceMasterSpellTooltip.Description:SetPoint("TOPLEFT", DiceMasterSpellTooltip.Level, "BOTTOMLEFT", 0, -20);
		end
	end
	if spell.description then
		spell.description = FormatDescription( spell.description );
		DiceMasterSpellTooltip.Description:SetText( spell.description );
		totalHeight = totalHeight + DiceMasterSpellTooltip.Description:GetHeight();
	end
	if spell.duration then
		-- Assume the buff is the same as the spell itself.
		DiceMasterSpellTooltip.BuffTexture:SetTexture( spell.icon );
		DiceMasterSpellTooltip.BuffTexture:Show();
		DiceMasterSpellTooltip.BuffTextureRing:Show();
		DiceMasterSpellTooltip.BuffDuration:SetText( spell.duration );
		DiceMasterSpellTooltip.BuffDuration:Show();
		DiceMasterSpellTooltip.RangeTexture:ClearAllPoints();
		DiceMasterSpellTooltip.RangeTexture:SetPoint( "TOPLEFT", DiceMasterSpellTooltip.BuffTexture, "BOTTOMLEFT", 0, -5 );
		totalHeight = totalHeight + DiceMasterSpellTooltip.BuffTexture:GetHeight();
	else
		DiceMasterSpellTooltip.BuffTexture:Hide();
		DiceMasterSpellTooltip.BuffTextureRing:Hide();
		DiceMasterSpellTooltip.BuffDuration:Hide();
		DiceMasterSpellTooltip.RangeTexture:ClearAllPoints();
		DiceMasterSpellTooltip.RangeTexture:SetPoint( "TOPLEFT", DiceMasterSpellTooltip.Description, "BOTTOMLEFT", 0, -5 );
	end
	if spell.range then
		DiceMasterSpellTooltip.RangeTexture:Show();
		DiceMasterSpellTooltip.RangeText:Show();
		if type( spell.range ) == "number" then
			DiceMasterSpellTooltip.RangeTexture:SetTexture("Interface/AddOns/DiceMaster/Texture/tooltipicons");
			DiceMasterSpellTooltip.RangeTexture:SetTexCoord( 0.0, 0.39, 0.0, 0.39 );
			DiceMasterSpellTooltip.RangeText:SetText( spell.range .. " yd" );
		elseif spell.range == "Melee" then
			DiceMasterSpellTooltip.RangeTexture:SetTexCoord( 0.0, 0.39, 0.0, 0.39 );
			DiceMasterSpellTooltip.RangeText:SetText( "Melee" );
		end
		hasBottomBar = true;
	else
		DiceMasterSpellTooltip.RangeTexture:Hide();
		DiceMasterSpellTooltip.RangeText:Hide();
	end
	if spell.savingThrow then
		DiceMasterSpellTooltip.SavingThrowTexture:Show();
		DiceMasterSpellTooltip.SavingThrowText:Show();
		DiceMasterSpellTooltip.SavingThrowText:SetText( spell.savingThrow );
		DiceMasterSpellTooltip.SavingThrowTexture:SetHeight(16);
		hasBottomBar = true;
	else
		DiceMasterSpellTooltip.SavingThrowTexture:SetHeight(0);
		DiceMasterSpellTooltip.SavingThrowTexture:Hide();
		DiceMasterSpellTooltip.SavingThrowText:Hide();
	end
	if spell.attackRoll then
		DiceMasterSpellTooltip.AttackRollTexture:Show();
		DiceMasterSpellTooltip.AttackRollText:Show();
		DiceMasterSpellTooltip.AttackRollText:SetText( "Attack Roll" );
		DiceMasterSpellTooltip.AttackRollTexture:SetHeight(16);
		hasBottomBar = true;
	else
		DiceMasterSpellTooltip.AttackRollTexture:SetHeight(0);
		DiceMasterSpellTooltip.AttackRollTexture:Hide();
		DiceMasterSpellTooltip.AttackRollText:Hide();
	end
	if spell.requiresConc then
		DiceMasterSpellTooltip.ConcentrationTexture:Show();
		DiceMasterSpellTooltip.ConcentrationText:Show();
		DiceMasterSpellTooltip.ConcentrationText:SetText( "Concentration" );
		DiceMasterSpellTooltip.ConcentrationTexture:SetHeight(16);
		hasBottomBar = true;
	else
		DiceMasterSpellTooltip.ConcentrationTexture:SetHeight(0);
		DiceMasterSpellTooltip.ConcentrationTexture:Hide();
		DiceMasterSpellTooltip.ConcentrationText:Hide();
	end
	if hasBottomBar then
		totalHeight = totalHeight + 20;
	end
	if spell.castTime then
		DiceMasterSpellTooltip.Delimiter1:ClearAllPoints();
		if not( spell.range or spell.savingThrow or spell.attackRoll or spell.requiresConc ) then
			if spell.duration then
				DiceMasterSpellTooltip.Delimiter1:SetPoint( "TOPLEFT", DiceMasterSpellTooltip.BuffTexture, "BOTTOMLEFT", -6, -7 );
			else
				DiceMasterSpellTooltip.Delimiter1:SetPoint( "TOPLEFT", DiceMasterSpellTooltip.Description, "BOTTOMLEFT", -6, -7 );
			end
		else
			DiceMasterSpellTooltip.Delimiter1:SetPoint( "TOPLEFT", DiceMasterSpellTooltip.RangeTexture, "BOTTOMLEFT", -6, -7 );
		end
		DiceMasterSpellTooltip.ActionTypeTexture:Show();
		DiceMasterSpellTooltip.ActionTypeTexture:SetTexCoord( unpack(actionIcons[spell.castTime]) );
		DiceMasterSpellTooltip.ActionTypeText:Show();
		DiceMasterSpellTooltip.ActionTypeText:SetText( spell.castTime );
		DiceMasterSpellTooltip.ActionTypeTexture:SetHeight(16);
		totalHeight = totalHeight + DiceMasterSpellTooltip.ActionTypeTexture:GetHeight();
	else
		DiceMasterSpellTooltip.ActionTypeTexture:SetHeight(0);
		DiceMasterSpellTooltip.ActionTypeTexture:Hide();
		DiceMasterSpellTooltip.ActionTypeText:Hide();
	end
	DiceMasterSpellTooltip:SetHeight( totalHeight + 50 );
	DiceMasterSpellTooltip:Show();
end

-------------------------------------------------------------------------------
function Me.CloseSpellTooltip()
    DiceMasterSpellTooltip:Hide();
end

-------------------------------------------------------------------------------
-- Handler for spell tooltips.
--
local function OnEnter( self )
	
	self.highlight:Show();
	Me.OpenSpellTooltip( self, self.spellID );
	 
end

local function OnLeave( self )
	if not self.selected then
		self.highlight:Hide();
	end
    DiceMasterSpellTooltip:Hide();
end

-------------------------------------------------------------------------------
local methods = {
	---------------------------------------------------------------------------
	-- Set a static texture for this button.
	--
	-- Overrides SetSpell.
	--
	SetTexture = function( self, tex )
		self.spellID = nil;
		self.icon:SetTexture( tex );
		self.icon:SetVertexColor( 1, 1, 1 );
	end;
	
	---------------------------------------------------------------------------
	-- Hook this button up to a direct spell.
	--
	SetSpell = function( self, spellID )
		self.spellID = spellID;
		self:Refresh();
	end;
	
	---------------------------------------------------------------------------
	-- Refresh after a spell changes.
	--
	Refresh = function( self )
		self.icon:SetVertexColor( 1, 1, 1 );
		if self.spellID then
			self.icon:SetTexture( DiceMaster4.SpellList["Player's Handbook"][self.spellID]["icon"] );
		end
	end;
	
	---------------------------------------------------------------------------
	-- "Select" this spell, i.e. make it glow.
	--
	Select = function( self, selected )
		self.selected = selected;
		if selected then
			self.highlight:Show();
		else
			self.highlight:Hide();
		end
	end;
}

-------------------------------------------------------------------------------
-- Initialize a new spell button.
--
function Me.SpellButton_Init( self )

	for k, v in pairs( methods ) do
		self[k] = v;
	end
	 
	self:SetScript( "OnEnter", OnEnter );
	self:SetScript( "OnLeave", OnLeave );
end

