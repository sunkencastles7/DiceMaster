-------------------------------------------------------------------------------
-- Dice Master (C) 2019 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

-------------------------------------------------------------------------------

local function UpdateFilled( self )
	if self.filled == 0 then
		self.healthBar:SetValue( 0 )
	else
		self.healthBar:SetValue( self.filled )
		if ( self.filled >= self.filled_max and self.armour > 0 ) then
			self.healthBar.armourGlow:Show()
		else
			self.healthBar.armourGlow:Hide()
		end
	end
	if self.armour == 0 then
		self.armourBar:Hide()
	else
		self.armourBar:Show()
		self.armourBar:SetValue( self.filled + self.armour )
	end
end

-------------------------------------------------------------------------------

local methods = {
	SetMax = function( self, max )
		if max < 0 or max > 1000 then error( "Invalid max value." ) end
		
		self.filled_max = max  
		self.filled     = math.min( self.filled, max )
		self.armour     = math.min( self.armour, max )
		
		self:RefreshFrame()
	end;
	
	SetValue = function( self, filled )
		self.filled = filled
		UpdateFilled( self )
	end;
	
	SetArmour = function( self, armour )
		self.armour = armour or 0
		UpdateFilled( self )
	end;
	
	RefreshFrame = function( self )
		self.healthBar:SetMinMaxValues( 0, self.filled_max )
		self.armourBar:SetMinMaxValues( 0, self.filled_max )
		self.healthBar:SetValue( self.filled_max )
		UpdateFilled( self )
	end;
	
	SetScales = function( self, scale )
		self:SetSize( 230 * scale, 14 * scale )	
		self.healthBar.bar:SetSize( 267 * scale, 38 * scale )	
		self.healthBar.icon:SetSize( 32 * scale, 32 * scale )	
		self.healthBar.armourGlow:SetSize( 14 * scale, 16 * scale )	
	end;
}

-------------------------------------------------------------------------------

function Me.UnitHealthBar_Init( self )

	for k, v in pairs( methods ) do
		self[k] = v
	end
	
	self.filled = 1
	self.armour = 0
	self:SetMax(1) 
end

