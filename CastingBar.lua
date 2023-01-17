-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Casting bar interface.
--

local Me = DiceMaster4
local Profile = Me.Profile

local methods = {
	---------------------------------------------------------------------------
	-- Cancel the casting bar.
	--
	Cancel = function( self )
		if ( self:IsShown() ) then
			Me.CastingBar_InterruptSpell(self, false);
		end
	end;
	---------------------------------------------------------------------------
	-- Check if the casting bar has been cancelled.
	--
	IsCancelled = function( self )
		if ( not self:IsShown() ) or ( self.fadeOut ) then
			return true;
		end
		return false;
	end;
}

function Me.CastingBar_OnLoad(self)
	CastingBarFrame_SetStartCastColor(self, 1.0, 0.7, 0.0);
	CastingBarFrame_SetStartChannelColor(self, 0.0, 1.0, 0.0);
	CastingBarFrame_SetFinishedCastColor(self, 0.0, 1.0, 0.0);
	CastingBarFrame_SetNonInterruptibleCastColor(self, 0.7, 0.7, 0.7);
	CastingBarFrame_SetFailedCastColor(self, 1.0, 0.0, 0.0);

	CastingBarFrame_SetUseStartColorForFinished(self, true);
	CastingBarFrame_SetUseStartColorForFlash(self, true);
	
	
	self.StagePoints = {};
	self.StagePips = {};
	self.StageTiers = {};

	self:SetUnit("player", true, false);
	
	self.showCastbar = true;

	for k, v in pairs( methods ) do
		self[k] = v
	end

	self.Icon:Hide()

	local point, relativeTo, relativePoint, offsetX, offsetY = self.Spark:GetPoint(1);
	if ( point == "CENTER" ) then
		self.Spark.offsetY = offsetY;
	end
end

function Me.CastingBar_Show(type, text, texture, duration, notInterruptible, sound)
	local frame = DiceMasterCastingBarFrame
	if ( type == "cast" ) then
		if ( not text ) then
			frame:Hide();
			return;
		end

		local startColor = CastingBarFrame_GetEffectiveStartColor(frame, false, notInterruptible);
		frame:SetStatusBarColor(startColor:GetRGB());
		if frame.flashColorSameAsStart then
			frame.Flash:SetVertexColor(startColor:GetRGB());
		else
			frame.Flash:SetVertexColor(1, 1, 1);
		end
		
		if ( frame.Spark ) then
			frame.Spark:Show();
		end
		frame.value = 0;
		frame.maxValue = duration;
		frame:SetMinMaxValues(0, frame.maxValue);
		frame:SetValue(frame.value);
		if ( frame.Text ) then
			frame.Text:SetText(text);
		end
		if ( frame.Icon ) then
			frame.Icon:SetTexture(texture);
			if ( frame.iconWhenNoninterruptible ) then
				frame.Icon:SetShown(not notInterruptible);
			end
		end
		CastingBarFrame_ApplyAlpha(frame, 1.0);
		frame.isInterruptible = not notInterruptible;
		frame.holdTime = 0;
		frame.casting = true;
		frame.channeling = nil;
		frame.fadeOut = nil;

		if ( frame.BorderShield ) then
			if ( frame.showShield and notInterruptible ) then
				frame.BorderShield:Show();
				if ( frame.BarBorder ) then
					frame.BarBorder:Hide();
				end
			else
				frame.BorderShield:Hide();
				if ( frame.BarBorder ) then
					frame.BarBorder:Show();
				end
			end
		end
		if ( frame.showCastbar ) then
			frame:Show();
		end
	elseif ( type == "channel" ) then
		if ( not text ) then
			frame:Hide();
			return;
		end

		local startColor = CastingBarFrame_GetEffectiveStartColor(frame, true, notInterruptible);
		if frame.flashColorSameAsStart then
			frame.Flash:SetVertexColor(startColor:GetRGB());
		else
			frame.Flash:SetVertexColor(1, 1, 1);
		end
		frame:SetStatusBarColor(startColor:GetRGB());
		frame.value = duration
		frame.maxValue = duration;
		frame:SetMinMaxValues(0, frame.maxValue);
		frame:SetValue(frame.value);
		if ( frame.Text ) then
			frame.Text:SetText(text);
		end
		if ( frame.Icon ) then
			frame.Icon:SetTexture(texture);
		end
		if ( frame.Spark ) then
			frame.Spark:Hide();
		end
		CastingBarFrame_ApplyAlpha(frame, 1.0);
		frame.isInterruptible = not notInterruptible;
		frame.holdTime = 0;
		frame.casting = nil;
		frame.channeling = true;
		frame.fadeOut = nil;
		
		if ( frame.BorderShield ) then
			if ( frame.showShield and notInterruptible ) then
				frame.BorderShield:Show();
				if ( frame.BarBorder ) then
					frame.BarBorder:Hide();
				end
			else
				frame.BorderShield:Hide();
				if ( frame.BarBorder ) then
					frame.BarBorder:Show();
				end
			end
		end
		if ( frame.showCastbar ) then
			frame:Show();
		end
	end
	if ( sound ) then
		_, frame.sound = PlaySound( sound )
	end
end

function Me.CastingBar_OnUpdate(self, elapsed)
	if ( ( self.casting or self.channeling ) and self.isInterruptible and GetUnitSpeed("player") > 0 ) then
		Me.CastingBar_InterruptSpell(self, false)
		return
	end
	if ( self.casting ) then
		self.value = self.value + elapsed;
		if ( self.value >= self.maxValue ) then
			self:SetValue(self.maxValue);
			Me.CastingBar_FinishSpell(self, self.Spark, self.Flash);
			return;
		end
		self:SetValue(self.value);
		if ( self.Flash ) then
			self.Flash:Hide();
		end
		if ( self.Spark ) then
			local sparkPosition = (self.value / self.maxValue) * self:GetWidth();
			self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, self.Spark.offsetY or 2);
		end
	elseif ( self.channeling ) then
		self.value = self.value - elapsed;
		if ( self.value <= 0 ) then
			Me.CastingBar_FinishSpell(self, self.Spark, self.Flash);
			return;
		end
		self:SetValue(self.value);
		if ( self.Flash ) then
			self.Flash:Hide();
		end
	elseif ( GetTime() < self.holdTime ) then
		return;
	elseif ( self.flash ) then
		local alpha = 0;
		if ( self.Flash ) then
			alpha = self.Flash:GetAlpha() + CASTING_BAR_FLASH_STEP;
		end
		if ( alpha < 1 ) then
			if ( self.Flash ) then
				self.Flash:SetAlpha(alpha);
			end
		else
			if ( self.Flash ) then
				self.Flash:SetAlpha(1.0);
			end
			self.flash = nil;
		end
	elseif ( self.fadeOut ) then
		local alpha = self:GetAlpha() - CASTING_BAR_ALPHA_STEP;
		if ( alpha > 0 ) then
			CastingBarFrame_ApplyAlpha(self, alpha);
		else
			self.fadeOut = nil;
			self:Hide();
		end
	end
end

function Me.CastingBar_FinishSpell(self)	
	if ( not self:IsVisible() ) then
			self:Hide();
		end
	if ( self.casting or self.channeling ) then
		if ( self.Spark ) then
			self.Spark:Hide();
		end
		if ( self.Flash ) then
			self.Flash:SetAlpha(0.0);
			self.Flash:Show();
		end
		self:SetValue(self.maxValue);
		if ( self.casting ) then
			self.casting = nil;
			if not self.finishedColorSameAsStart then
				self:SetStatusBarColor(self.finishedCastColor:GetRGB());
			end
		else
			self.channeling = nil;
		end
		self.flash = true;
		self.fadeOut = true;
		self.holdTime = 0;
	end
	if ( self.sound ) then
		StopSound( self.sound )
	end
	if self["OnFinished"] then
		self:OnFinished(self)
	end
end

function Me.CastingBar_InterruptSpell(self, hasFailed)
	if ( self:IsShown() and self.casting and not self.fadeOut ) then
		self:SetValue(self.maxValue);
		self:SetStatusBarColor(self.failedCastColor:GetRGB());
		if ( self.Spark ) then
			self.Spark:Hide();
		end
		if ( self.Text ) then
			if ( hasFailed ) then
				self.Text:SetText(FAILED);
			else
				UIErrorsFrame:AddMessage( "Interrupted", 1.0, 0.0, 0.0, 53, 5 ); 
				self.Text:SetText(INTERRUPTED);
			end
		end
		if ( self.sound ) then
			StopSound( self.sound )
		end
		self.casting = nil;
		self.channeling = nil;
		self.fadeOut = true;
		self.holdTime = GetTime() + CASTING_BAR_HOLD_TIME;
	end
end