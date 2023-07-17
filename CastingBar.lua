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
	self.StagePoints = {};
	self.StagePips = {};
	self.StageTiers = {};
	
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
		
		frame.barType = "standard"
		frame:SetStatusBarTexture(frame:GetTypeInfo(frame.barType).filling);
		frame:ClearStages();
		frame:ShowSpark();
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
		frame.isInterruptible = not notInterruptible;
		frame.holdTime = 0;
		frame.casting = true;
		frame.channeling = nil;
		frame.reverseChanneling = nil;
		frame.fadeOut = nil;

		frame:StopAnims();
		frame:ApplyAlpha(1.0);

		frame.CastTimeText:Hide();
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
		
		frame.maxValue = duration;
		frame.barType = type;

		frame:SetStatusBarTexture(frame:GetTypeInfo(frame.barType).filling);

		frame:ClearStages();
		frame.value = duration;

		frame:ShowSpark();

		frame:SetMinMaxValues(0, frame.maxValue);
		frame:SetValue(frame.value);
		if ( frame.Text ) then
			frame.Text:SetText(text);
		end
		if ( frame.Icon ) then
			frame.Icon:SetTexture(texture);
		end
		frame.reverseChanneling = nil;
		frame.casting = nil;
		frame.channeling = true;
		
		frame:StopAnims();
		frame:ApplyAlpha(1.0);

		frame.CastTimeText:Hide();
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

		frame:UpdateShownState(frame.showCastbar);
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
	if ( self.casting or self.reverseChanneling) then
		self.value = self.value + elapsed;
		if ( self.value >= self.maxValue ) then
			self:SetValue(self.maxValue);
			if (not self.reverseChanneling) then
				Me.CastingBar_FinishSpell(self, self.Spark, self.Flash);
			else
				if self.FlashLoopingAnim and not self.FlashLoopingAnim:IsPlaying() then
					self.FlashLoopingAnim:Play();
					self.Flash:Show();
				end
			end
			self.Spark:Hide();
			return;
		end
		self:SetValue(self.value);
		if ( self.Flash ) then
			self.Flash:Hide();
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
	end

	if ( self.casting or self.reverseChanneling or self.channeling ) then
		if ( self.Spark ) then
			local sparkPosition = (self.value / self.maxValue) * self:GetWidth();
			self.Spark:SetPoint("CENTER", self, "LEFT", sparkPosition, self.Spark.offsetY or 0);
		end
	end
end

function Me.CastingBar_FinishSpell(self)
	if self.maxValue and not self.reverseChanneling and not self.channeling then
		self:SetValue(self.maxValue);
	end
	local barTypeInfo = self:GetTypeInfo(self.barType);
	self:SetStatusBarTexture(barTypeInfo.full);

	self:HideSpark();

	if ( self.Flash ) then
		self.Flash:SetAtlas(barTypeInfo.glow);
		self.Flash:SetAlpha(0.0);
		self.Flash:Show();
	end
	
	self:PlayFadeAnim();
	self:PlayFinishAnim();
	
	self.casting = nil;
	self.channeling = nil;
	self.reverseChanneling = nil;

	if ( self.sound ) then
		StopSound( self.sound )
	end
	if self["OnFinished"] then
		self:OnFinished(self)
	end
end

function Me.CastingBar_InterruptSpell(self, hasFailed)
	if ( self:IsShown() and self.casting and (not self.FadeOutAnim or not self.FadeOutAnim:IsPlaying()) ) then
		self.barType = "interrupted"; -- failed and interrupted use same bar art
		self:SetStatusBarTexture(self:GetTypeInfo(self.barType).full);

		self:ShowSpark();

		if ( self.Text ) then
			if ( hasFailed ) then
				self.Text:SetText(FAILED);
			else
				UIErrorsFrame:AddMessage( INTERRUPTED, 1.0, 0.0, 0.0 ); 
				self.Text:SetText(INTERRUPTED);
			end
		end
		if ( self.sound ) then
			StopSound( self.sound )
		end

		self.casting = nil;
		self.channeling = nil;
		self.reverseChanneling = nil;

		if self.HoldFadeOutAnim then
			self.HoldFadeOutAnim:Play();
		end
		if self.InterruptShakeAnim and tonumber(GetCVar("ShakeStrengthUI")) > 0 then
			self.InterruptShakeAnim:Play();
		end
		if self.InterruptGlowAnim then
			self.InterruptGlowAnim:Play();
		end
		if self.InterruptSparkAnim then
			self.InterruptSparkAnim:Play();
		end
	end
end