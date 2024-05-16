-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

local Me = DiceMaster4

Me.MinimapButton = {}

local LDB    = LibStub:GetLibrary( "LibDataBroker-1.1" )
local DBIcon = LibStub:GetLibrary( "LibDBIcon-1.0"     )

-------------------------------------------------------------------------------
function Me.MinimapButton_Init()
	local self = Me.MinimapButton
	
	self.data = LDB:NewDataObject( "DiceMaster", {
		type = "data source";
		text = "DiceMaster";
		icon = "Interface/AddOns/DiceMaster/Icons/DiceMaster";
		OnClick = function(...) Me.MinimapButton:OnClick(...) end;
		OnEnter = function(...) Me.MinimapButton:OnEnter(...) end;
		OnLeave = function(...) Me.MinimapButton:OnLeave(...) end;
	})
end

-------------------------------------------------------------------------------
function Me.MinimapButton:OnLoad() 
	DBIcon:Register( "DiceMaster", self.data, Me.db.char.minimapicon )
end

-------------------------------------------------------------------------------
function Me.MinimapButton:Show( show )
	if show then
		DBIcon:Show( "DiceMaster" )
		Me.db.char.minimapicon.hide = false
	else
		DBIcon:Hide( "DiceMaster" )
		Me.db.char.minimapicon.hide = true
	end
end

-------------------------------------------------------------------------------
function Me.MinimapButton:OnClick( frame, button )
	if button == "LeftButton" then
		Me.ShowPanel( Me.db.char.hidepanel )
	elseif button == "RightButton" then
		Me.OpenConfig()
	end
end
   
-------------------------------------------------------------------------------
function Me.MinimapButton:OnEnter( frame ) 
	-- Section the screen into 6 sextants and define the tooltip 
	-- anchor position based on which sextant the cursor is in.
	-- Code taken from WeakAuras.
	--
    local max_x = 768 * GetMonitorAspectRatio()
    local max_y = 768
    local x, y = GetCursorPosition()
	
    local horizontal = (x < (max_x/3) and "LEFT") or ((x >= (max_x/3) and x < ((max_x/3)*2)) and "") or "RIGHT"
    local tooltip_vertical = (y < (max_y/2) and "BOTTOM") or "TOP"
    local anchor_vertical = (y < (max_y/2) and "TOP") or "BOTTOM"
    GameTooltip:SetOwner( frame, "ANCHOR_NONE" )
    GameTooltip:SetPoint( tooltip_vertical..horizontal, frame, anchor_vertical..horizontal )
	
	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine( "DiceMaster", Me.version, 1, 1, 1, 1, 1, 1 )
	GameTooltip:AddLine( " " )
	GameTooltip:AddLine( "|cff00ff00Left-click|r to toggle panel.", 1, 1, 1 )
	GameTooltip:AddLine( "|cff00ff00Right-click|r for configuration.", 1, 1, 1 )
	GameTooltip:Show()
end

-------------------------------------------------------------------------------
function Me.MinimapButton:OnLeave( frame ) 
	GameTooltip:Hide()
end
