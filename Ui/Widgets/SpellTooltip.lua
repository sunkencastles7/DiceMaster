-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

-------------------------------------------------------------------------------
local methods = {
	---------------------------------------------------------------------------
	-- Set a static texture for this button.
	--
	-- Overrides SetSpell.
	--
	SetOwner = function( self, owner )
		self:ClearAllPoints();
		self:SetPoint("BOTTOMLEFT", owner, "TOPRIGHT");
	end;
	
	---------------------------------------------------------------------------
	-- Hook this button up to a direct spell.
	--
	ClearAllLines = function( self )
		local fields = {"Name", "Level", "School", "Damage", "DamageDice", "Description", "BuffDuration", "RangeText", "AttackRollText", "SavingThrowText", "ConcentrationText"};

		for i = 1, #fields do 
			DiceMasterSpellTooltip[ fields[i] ]:SetText("");
		end
	end;

	
	GetTotalWidth = function( self )
		local fields = {"Name", "Level", "Damage", "Description", };

		local totalWidth = 0;
		for i = 1, #fields do
			local child = DiceMasterSpellTooltip[ fields[i] ];
			if child:IsShown() then
				if self:GetWidth() > 230 then self:SetWidth( 230 ) end
				if child:GetWidth() > totalWidth then
					totalWidth = child:GetWidth();
				end
			end
		end
		if totalWidth > 254 then totalWidth = 254 end

		return totalWidth;
	end;
}

-------------------------------------------------------------------------------
-- Initialize a new spell button.
--
function Me.SpellTooltip_Init( self )

	local layout = NineSliceUtil.GetLayout("TooltipDefaultDarkLayout");
	NineSliceUtil.ApplyLayout(self.NineSlice, layout);
	self.NineSlice:Show();

	for k, v in pairs( methods ) do
		self[k] = v
	end
end
