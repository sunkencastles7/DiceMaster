-------------------------------------------------------------------------------
-- Dice Master (C) 2020 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Shop Editing Panel
--

local Me      = DiceMaster4
local Profile = Me.Profile

-------------------------------------------------------------------------------
-- StaticPopupDialogs
--

StaticPopupDialogs["DICEMASTER4_EDITBOOKTITLE"] = {
  text = "Set Health value:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText( data )
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tostring( self.editBox:GetText() ) or DiceMasterBookFrame.TitleText:GetText();
	
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	DiceMasterBookFrame.bookData.title = text;
	Me.BookFrame_Update()
  end,
  hasEditBox = true,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

StaticPopupDialogs["DICEMASTER4_DELETEBOOKPAGE"] = {
  text = "Are you sure you want to delete this page?",
  button1 = "Accept",
  button2 = "Cancel",
  OnAccept = function (self, data)
	tremove( DiceMasterBookFrame.bookData.pages, DiceMasterBookFrame.currentPage )
	DiceMasterBookFrame.currentPage = 1
	Me.BookFrame_Update()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-------------------------------------------------------------------------------
-- BBCode to HTML converter
--

local BOOK_MATERIALS = {
	["Alliance"] = {
		atlas = "QuestBG-Alliance",
		type = "quest",
	},
	["Ardenweald"] = {
		atlas = "questbg-ardenweald",
		type = "quest",
	},
	["Auction"] = {
		path = "AuctionStationery",
		type = "stationery"
	},
	["Bastion"] = {
		atlas = "questbg-bastion",
		type = "quest",
	},
	["Book"] = {
		atlas = "book-bg",
		type = "book",
	},
	["Bronze"] = {
		path = "Bronze",
		type = "itemtext"
	},
	["Hand of Fate"] = {
		atlas = "QuestBG-TheHandofFate",
		type = "quest",
	},
	["Illidari"] = {
		path = "Stationery_ill",
		type = "stationery"
	},
	["Horde"] = {
		atlas = "QuestBG-Horde",
		type = "quest",
	},
	["Kyrian"] = {
		atlas = "questbg-kyrian",
		type = "quest",
	},
	["Legionfall"] = {
		atlas = "QuestBG-Legionfall",
		type = "quest",
	},
	["Love is in the Air"] = {
		path = "Valentine",
		type = "itemtext"
	},
	["Maldraxxus"] = {
		atlas = "questbg-maldraxxus",
		type = "quest",
	},
	["Marble"] = {
		path = "Marble",
		type = "itemtext"
	},
	["Necrolords"] = {
		atlas = "questbg-necrolord",
		type = "quest",
	},
	["Night Fae"] = {
		atlas = "questbg-fey",
		type = "quest",
	},
	["Orc"] = {
		path = "Stationery_OG",
		type = "stationery"
	},
	["Oribos"] = {
		atlas = "questbg-oribos",
		type = "quest",
	},
	["Quest"] = {
		atlas = "questbg-parchment",
		type = "quest",
	},
	["Revendreth"] = {
		atlas = "questbg-revendreth",
		type = "quest",
	},
	["Shadowlands"] = {
		atlas = "questbg-shadowlands",
		type = "quest",
	},
	["Silver"] = {
		path = "Silver",
		type = "itemtext"
	},
	["Stone"] = {
		path = "Stone",
		type = "itemtext"
	},
	["Tauren"] = {
		path = "Stationery_TB",
		type = "stationery"
	},
	["Undead"] = {
		path = "Stationery_UC",
		type = "stationery"
	},
	["Venthyr"] = {
		atlas = "questbg-venthyr",
		type = "quest",
	},
	["Winter Veil"] = {
		path = "Stationery_Chr",
		type = "stationery"
	},
}

local BOOK_FONTS = {
	["Morpheus"] = "Fonts\\MORPHEUS.TTF",
	["Frizqt"] = "Fonts\\FRIZQT__.TTF",
	["Arialn"] = "Fonts\\ARIALN.TTF",
	["Skurri"] = "Fonts\\SKURRI.TTF",
	["Black Chancery"] = "Interface\\AddOns\\DiceMaster\\Fonts\\blkchcry.TTF",
	["Holy Empire"] = "Interface\\AddOns\\DiceMaster\\Fonts\\HOLY.TTF",
	["Trade Winds"] = "Interface\\AddOns\\DiceMaster\\Fonts\\TradeWinds-Regular.TTF",
	["Deutsch Gothic"] = "Interface\\AddOns\\DiceMaster\\Fonts\\Deutsch.TTF",
	["Ancient Runes"] = "Interface\\AddOns\\DiceMaster\\Fonts\\AncientRunes.TTF",
	["Irish Uncialfabeta Bold"] = "Interface\\AddOns\\DiceMaster\\Fonts\\IrishUncialfabeta-Bold.TTF",
	["Elementary Gothic Bookhand"] = "Interface\\AddOns\\DiceMaster\\Fonts\\Elementary_Gothic_Bookhand.TTF",
}

local AppendHtmlAndBodyTags = function(text)
	return "<HTML><BODY>"..text.."</BODY></HTML>";
end

local function SetBookMaterial( materialType )
	DiceMasterBookFramePageBg:SetTexture( nil )
	DiceMasterBookMaterialLeft:SetTexture( nil )
	DiceMasterBookMaterialRight:SetTexture( nil )
	DiceMasterBookMaterialTopLeft:SetTexture( nil );
	DiceMasterBookMaterialTopRight:SetTexture( nil );
	DiceMasterBookMaterialBotLeft:SetTexture( nil );
	DiceMasterBookMaterialBotRight:SetTexture( nil );
	
	if BOOK_MATERIALS[ materialType ] then
		local material = BOOK_MATERIALS[ materialType ]
		if material.type == "stationery" then
			DiceMasterBookMaterialLeft:SetTexture( "Interface/Stationery/" .. ( material.path ) .. "1" );
			DiceMasterBookMaterialRight:SetTexture( "Interface/Stationery/" .. ( material.path ) .. "2" );
		elseif material.type == "itemtext" then
			DiceMasterBookMaterialTopLeft:SetTexture( "Interface/ItemTextFrame/ItemText-" .. material.path .. "-TopLeft" );
			DiceMasterBookMaterialTopRight:SetTexture( "Interface/ItemTextFrame/ItemText-" .. material.path .. "-TopRight" );
			DiceMasterBookMaterialBotLeft:SetTexture( "Interface/ItemTextFrame/ItemText-" .. material.path .. "-BotLeft" );
			DiceMasterBookMaterialBotRight:SetTexture( "Interface/ItemTextFrame/ItemText-" .. material.path .. "-BotRight" );
		elseif material.type == "quest" or material.type == "book" then
			DiceMasterBookFramePageBg:SetAtlas( material.atlas, false )
		end
	end
end

function Me.BookFrame_OnLoad(self)
	ButtonFrameTemplate_HideButtonBar(self);
	
	self:SetClampedToScreen( true )
	self:RegisterForDrag( "LeftButton" )
	self:SetScript( "OnDragStart", self.StartMoving )
	self:SetScript( "OnDragStop", self.StopMovingOrSizing )
	
	DiceMasterBookCurrentPage:SetText( "1/1" );
end

function Me.BookEditorMaterial_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText( DiceMasterBookEditor.MaterialButton, self:GetText() )
	--SetBookMaterial( self:GetText() )
	
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	DiceMasterBookFrame.bookData.material = self:GetText();
	Me.BookFrame_Update()
end

function Me.BookEditorMaterial_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for k, v in pairs( BOOK_MATERIALS ) do
		info.text = k
		info.checked = UIDropDownMenu_GetText( DiceMasterBookEditor.MaterialButton ) == info.text;
		info.notCheckable = false;
		info.func = Me.BookEditorMaterial_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end
end

function Me.BookEditorFont_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText( DiceMasterBookEditor.FontButton, self:GetText() )
	
	--DiceMasterBookPageText:SetFont( BOOK_FONTS[ self:GetText() ], DiceMasterBookFrame.bookData.fontSize.p or 13 );
	
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	DiceMasterBookFrame.bookData.font = self:GetText();
	Me.BookFrame_Update()
end

function Me.BookEditorFont_OnLoad(frame, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	for k, v in pairs( BOOK_FONTS ) do
		info.text = k
		info.checked = UIDropDownMenu_GetText( DiceMasterBookEditor.FontButton ) == info.text;
		info.notCheckable = false;
		info.func = Me.BookEditorFont_OnClick;
		UIDropDownMenu_AddButton(info, level)
	end
end

local function InsertHTMLTags()
	local text = "<html><body>|n<p></p>|n</body></html>"
	return text
end

local function GetHighlightedText( editbox )

	if not editbox then 
		return nil 
	end
	
	local origText = editbox:GetText();
	if not (origText) then return nil end

	local cPos = editbox:GetCursorPosition();

	editbox:Insert("\127");
	local a = string.find(editbox:GetText(), "\127");
	local dLen = math.max(0,string.len(origText)-(string.len(editbox:GetText())-1));
	editbox:SetText(origText);

	editbox:SetCursorPosition(cPos);
	local hs, he = a - 1, a + dLen - 1;
	if hs < he then
		editbox:HighlightText(hs, he);
		return hs, he;
	end
	
end

function Me.BookEditor_Insert( text )
	DiceMasterBookPageTextEditor:Insert( text );
end

function Me.BookEditor_InsertTag( tag, tag2 )
	local hi1, hi2 = GetHighlightedText( DiceMasterBookPageTextEditor );
	local s;

	local inner = "";
	if hi1 and hi2 then
		inner = string.sub(DiceMasterBookPageTextEditor:GetText(), hi1 + 1, hi2);
	end
	if tag2 then
		s = string.format("<%s>%s</%s>", tag, inner, tag2);
	else
		s = string.format("<%s>%s</%s>", tag, inner, tag);
	end
	DiceMasterBookPageTextEditor:Insert(s);
end

function Me.BookEditor_DeletePage()
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	local pages = DiceMasterBookFrame.bookData.pages
	local currentPage = DiceMasterBookFrame.currentPage or 1
	local data = {
		pages = pages;
		currentPage = currentPage;
	}
	
	if ( #pages == 1 ) then
		UIErrorsFrame:AddMessage( "You cannot delete the last page.", 1.0, 0.0, 0.0, 53, 5 );
	else
		StaticPopup_Show( "DICEMASTER4_DELETEBOOKPAGE", nil, nil, data )
	end
	
end

function Me.BookEditor_InsertPage( before )
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	if before then
		tinsert( DiceMasterBookFrame.bookData.pages, #DiceMasterBookFrame.bookData.pages, InsertHTMLTags() )
	else
		tinsert( DiceMasterBookFrame.bookData.pages, InsertHTMLTags() )
	end
	
	Me.BookFrame_Update()
end

function Me.BookEditor_AddBook()
	if not Me.ItemEditing and not Me.newItem then
		return
	end
	
	local scriptData = {
		type = "book";
		title = UnitName( "player" ) .. "'s Book";
		material = "Book";
		pages = { "" };
		font = "Frizqt";
		fontSize = {
			p = 13;
			h1 = 18;
			h2 = 16;
		},
		fontColour = { 0, 0, 0 };
		author = UnitName( "player" );
	}
	
	if Me.ItemEditing then
		tinsert( Me.ItemEditing.effects, scriptData )
	elseif Me.newItem then
		tinsert( Me.newItem.effects, scriptData )
	end
	
	Me.ItemEditorEffectsList_Update()
end

function Me.BookEditor_Load( self )
	self.Inset:SetPoint( "BOTTOMLEFT", 4, 72 )
end

function Me.BookEditor_Show()
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	DiceMasterBookEditor:Show()
	
	local data = DiceMasterBookFrame.bookData
	
	UIDropDownMenu_SetText( DiceMasterBookEditor.MaterialButton, data.material or "Book" )
	UIDropDownMenu_SetText( DiceMasterBookEditor.FontButton, data.font or "Frizqt" )
	
	DiceMasterBookEditor.FontSizeReg:SetText( data.fontSize.p or "13" )
	DiceMasterBookEditor.FontSizeH1:SetText( data.fontSize.h1 or "18" )
	DiceMasterBookEditor.FontSizeH2:SetText( data.fontSize.h2 or "16" )
	
	DiceMasterBookPageText:Hide()
	DiceMasterBookPageTextEditor:SetText( data.pages[ DiceMasterBookFrame.currentPage ] )
	DiceMasterBookPageTextEditor:Show()
end

function Me.BookEditor_Hide()
	DiceMasterBookEditor:Hide()
	
	DiceMasterBookPageText:Show()
	DiceMasterBookPageTextEditor:Hide()
end

function Me.BookFrame_Show( data )
	if not data or not data.type or not data.title or not data.material or not data.pages or not data.font or not data.fontSize or not data.author or data.type ~= "book" then
		return
	end
	
	if data.author == UnitName( "player" ) then
		DiceMasterBookEditPageButton:Show()
		DiceMasterBookCurrentPage:SetPoint( "TOP", 20, -25 )
	else
		DiceMasterBookEditPageButton:Hide()
		DiceMasterBookCurrentPage:SetPoint( "TOP", 20, -35 )
	end
	
	DiceMasterBookFrame.bookData = data
	DiceMasterBookFrame.currentPage = 1;
	Me.BookFrame_Update()
	DiceMasterBookFrame:Show()
end
		
function Me.BookFrame_Update()
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	local data = DiceMasterBookFrame.bookData

	local material = data.material
	if ( not material ) then
		material = "Book";
	end

	DiceMasterBookFrame:SetWidth(DEFAULT_ITEM_TEXT_FRAME_WIDTH);
	DiceMasterBookFrame:SetHeight(DEFAULT_ITEM_TEXT_FRAME_HEIGHT);
	DiceMasterBookScrollFrame:SetPoint("TOPRIGHT", DiceMasterBookFrame, "TOPRIGHT", -31, -63);
	DiceMasterBookScrollFrame:SetPoint("BOTTOMLEFT", DiceMasterBookFrame, "BOTTOMLEFT", 6, 6);
	DiceMasterBookPageText:SetPoint("TOPLEFT", 18, -15);
	DiceMasterBookPageText:SetWidth(270);
	DiceMasterBookPageText:SetHeight(304);

	-- Add some padding at the bottom if the bar can scroll appreciably
	DiceMasterBookScrollFrame:GetScrollChild():SetHeight(1);
	DiceMasterBookScrollFrame:UpdateScrollChildRect();
	if(floor(DiceMasterBookScrollFrame:GetVerticalScrollRange()) > 0) then
		DiceMasterBookScrollFrame:GetScrollChild():SetHeight(DiceMasterBookScrollFrame:GetHeight() + DiceMasterBookScrollFrame:GetVerticalScrollRange() + 30);
	end

	DiceMasterBookScrollFrameScrollBar:SetValue(0);
	DiceMasterBookScrollFrame:Show();
	local page = DiceMasterBookFrame.currentPage or 1;
	local hasNext = false;
	if ( page + 1 <= #data.pages ) then
		hasNext = true;
	end
	
	SetBookMaterial( material )
	DiceMasterBookFrame.TitleText:SetText( data.title );
	DiceMasterBookPageText:SetText( data.pages[ page ] );
	DiceMasterBookPageText:SetFont( BOOK_FONTS[ data.font ], data.fontSize.p );
	DiceMasterBookPageText:SetFont( "H1", BOOK_FONTS[ data.font ], data.fontSize.h1 );
	DiceMasterBookPageText:SetFont( "H2", BOOK_FONTS[ data.font ], data.fontSize.h2 );
	
	DiceMasterBookPageText:SetTextColor( data.fontColour[1] or 0, data.fontColour[2] or 0, data.fontColour[3] or 0 )
	DiceMasterBookPageText:SetTextColor( "H1", data.fontColour[1] or 0, data.fontColour[2] or 0, data.fontColour[3] or 0 )
	DiceMasterBookPageText:SetTextColor( "H2", data.fontColour[1] or 0, data.fontColour[2] or 0, data.fontColour[3] or 0 )
	
	DiceMasterBookPageTextEditor:SetText( data.pages[ page ] );
	DiceMasterBookPageTextEditor:SetFont( BOOK_FONTS[ data.font ], data.fontSize.p );
	
	DiceMasterBookPageTextEditor:SetTextColor( data.fontColour[1] or 0, data.fontColour[2] or 0, data.fontColour[3] or 0 )
	
	DiceMasterBookCurrentPage:Hide()
	DiceMasterBookNextPageButton:Hide();
	DiceMasterBookPrevPageButton:Hide();
	
	if ( (page > 1) or hasNext ) then
		DiceMasterBookCurrentPage:SetText( page .. "/" .. #data.pages );
		DiceMasterBookCurrentPage:Show();
		if ( page > 1 ) then
			DiceMasterBookPrevPageButton:Show();
		else
			DiceMasterBookPrevPageButton:Hide();
		end
		if ( hasNext ) then
			DiceMasterBookNextPageButton:Show();
		else
			DiceMasterBookNextPageButton:Hide();
		end
	end
end

function Me.BookFrame_NextPage()
	if not DiceMasterBookFrame.bookData or not DiceMasterBookFrame.currentPage then
		return
	end
	
	local data = DiceMasterBookFrame.bookData
	if ( DiceMasterBookFrame.currentPage + 1 <= #data.pages ) then
		DiceMasterBookFrame.currentPage = DiceMasterBookFrame.currentPage + 1
	end
	
	Me.BookFrame_Update()
end

function Me.BookFrame_PrevPage()
	if not DiceMasterBookFrame.bookData or not DiceMasterBookFrame.currentPage then
		return
	end
	
	local data = DiceMasterBookFrame.bookData
	if ( DiceMasterBookFrame.currentPage > 1 ) then
		DiceMasterBookFrame.currentPage = DiceMasterBookFrame.currentPage - 1
	end
	
	Me.BookFrame_Update()
end

function Me.BookFrame_Hide( self )
	Me.BookEditor_Hide()
	HideUIPanel( self );
end