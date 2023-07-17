-------------------------------------------------------------------------------
-- Dice Master (C) 2023 <The League of Lordaeron> - Moon Guard
-------------------------------------------------------------------------------

--
-- Book Editor
--

local Me      = DiceMaster4
local Profile = Me.Profile

-------------------------------------------------------------------------------
-- StaticPopupDialogs
--

StaticPopupDialogs["DICEMASTER4_EDITBOOKTITLE"] = {
  text = "Book Title:",
  button1 = "Accept",
  button2 = "Cancel",
  OnShow = function (self, data)
    self.editBox:SetText( data )
	self.editBox:HighlightText()
  end,
  OnAccept = function (self, data)
    local text = tostring( self.editBox:GetText() ) or DiceMasterBookFrameTitleText:GetText();
	
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

-- Return an texture text tag based on the given image url and size.
local function GetTextureTag(iconPath, iconSize)
	if not iconPath then
		return
	end
	
	iconSize = iconSize or 16;
	return strconcat("|T", iconPath, ":", iconSize, ":", iconSize, "|t");
end

-- Return an texture text tag based on the given icon url and size. Nil safe.
local function GetIconTag(iconPath, iconSize)
	iconPath = iconPath or "Interface/Icons/inv_misc_questionmark";
	return GetTextureTag(iconPath, iconSize);
end

local directReplacements = {
	["/color"] = "|r",
	["/colour"] = "|r",
	["HP"] = "|TInterface/AddOns/DiceMaster/Texture/health-heart:16|t",
	["AR"] = "|TInterface/AddOns/DiceMaster/Texture/armour-icon:16|t",
	["rule"] = "|n|TInterface/COMMON/UI-TooltipDivider:4:260|t|n",
};

local function convertTextTag(tag)

	if directReplacements[tag] then -- Direct replacement
		return directReplacements[tag];
	elseif tag:match("^color:%x%x%x%x%x%x$") then -- Hexa color replacement
		return "|cff"..tag:match("^color:(%x%x%x%x%x%x)$");
	elseif tag:match("^colour:%x%x%x%x%x%x$") then -- Hexa color replacement
		return "|cff"..tag:match("^colour:(%x%x%x%x%x%x)$");
	elseif tag:match("^icon%:[^:]+%:%d+$") then -- Icon
		local icon, size = tag:match("^icon%:([^:]+)%:(%d+)$");
		return GetIconTag(icon, size);
	end

	return "{"..tag.."}";
end

local function convertTextTags(text)
	if text then
		text = text:gsub("%{(.-)%}", convertTextTag);
		return text;
	end
end

local function GetItemBookLink( playerName, guid )
	if not guid then 
		return "|TInterface/Icons/inv_misc_questionmark:16|t |cffffffff[Unknown Item]|r";
	end
	
	local item = Me.FindFirstStack( guid )
	
	if not item then
		return "|TInterface/Icons/inv_misc_questionmark:16|t |cffffffff[Unknown Item]|r";
	end
	
	local icon = item.icon or "Interface/Icons/inv_misc_questionmark"
	local name = item.name or "Unknown Item"
	local colorHex = ITEM_QUALITY_COLORS[ item.quality ].hex or "|cffffffff";
	return "|T"..icon..":16|t "..colorHex.."["..name.."]|r";
end

local function GetItemName( guid )
	if not guid then 
		return "[Unknown Item]";
	end
	
	local item = Me.FindFirstStack( guid )
	
	if not item then
		return "[Unknown Item]";
	end
	
	return "["..item.name.."]" or "[Unknown Item]";
end

local escapedHTMLCharacters = {
	["<"] = "&lt;",
	[">"] = "&gt;",
	["\""] = "&quot;",
};

local structureTags = {
	["{h(%d)}"] = "<h%1>",
	["{h(%d):l}"] = "<h%1 align=\"left\">",
	["{h(%d):c}"] = "<h%1 align=\"center\">",
	["{h(%d):r}"] = "<h%1 align=\"right\">",
	["{/h(%d)}"] = "</h%1>",

	["{p}"] = "<P>",
	["{p:l}"] = "<P align=\"left\">",
	["{p:c}"] = "<P align=\"center\">",
	["{p:r}"] = "<P align=\"right\">",
	["{/p}"] = "</P>",
};

--- alignmentAttributes is a conversion table for taking a single-character
--  alignment specifier and getting a value suitable for use in the HTML
--  "align" attribute.
local alignmentAttributes = {
	["c"] = "center",
	["l"] = "left",
	["r"] = "right",
};

--- IMAGE_PATTERN is the string pattern used for performing image replacements
--  in strings that should be rendered as HTML.
---
--- The accepted form this is "{img:<src>:<width>:<height>[:align]}".
---
--- Each individual segment matches up to the next present colon. The third
--- match (height) and everything thereafter needs to check up-to the next
--- colon -or- ending bracket since they could be the final segment.
---
--- Optional segments should of course have the "?" modifer attached to
--- their preceeding colon, and should use * for the content match rather
--- than +.
local IMAGE_PATTERN = [[{img%:([^:]+)%:([^:]+)%:([^:}]+)%:?([^:}]*)%}]];

--- Note that the image tag has to be outside a <P> tag.
---@language HTML
local IMAGE_TAG = [[</P><img src="%s" width="%s" height="%s" align="%s"/><P>]];

-- Convert the given text by its HTML representation
local toHTML = function(text, noColor, noBrackets)

	-- 1) Replacement : & character
	text = text:gsub("&", "&amp;");

	-- 2) Replacement : escape HTML characters
	for pattern, replacement in pairs(escapedHTMLCharacters) do
		text = text:gsub(pattern, replacement);
	end

	-- 3) Replace Markdown
	local titleFunction = function(titleChars, title)
		local titleLevel = #titleChars;
		return "\n<h" .. titleLevel .. ">" .. strtrim(title) .. "</h" .. titleLevel .. ">";
	end;

	text = text:gsub("^(#+)(.-)\n", titleFunction);
	text = text:gsub("\n(#+)(.-)\n", titleFunction);
	text = text:gsub("\n(#+)(.-)$", titleFunction);
	text = text:gsub("^(#+)(.-)$", titleFunction);

	-- 4) Replacement : text tags
	for pattern, replacement in pairs(structureTags) do
		text = text:gsub(pattern, replacement);
	end

	local tab = {};
	local i=1;
	while text:find("<") and i<500 do

		local before;
		before = text:sub(1, text:find("<") - 1);
		if #before > 0 then
			tinsert(tab, before);
		end

		local tagText;

		local tag = text:match("</(.-)>");
		if tag then
			tagText = text:sub( text:find("<"), text:find("</") + #tag + 2);
			if #tagText == #tag + 3 then
				return
			end
			tinsert(tab, tagText);
		else
			return
		end

		local after;
		after = text:sub(#before + #tagText + 1);
		text = after;

		--- 	Log.log("Iteration "..i);
		--- 	Log.log("before ("..(#before).."): "..before);
		--- 	Log.log("tagText ("..(#tagText).."): "..tagText);
		--- 	Log.log("after ("..(#before).."): "..after);

		i = i+1;
		if i == 500 then
			break;
		end
	end
	if #text > 0 then
		tinsert(tab, text); -- Rest of the text
	end

	--- log("Parts count "..(#tab));

	local finalText = "";
	for _, line in pairs(tab) do

		if not line:find("<") then
			line = "<P>" .. line .. "</P>";
		end
		line = line:gsub("\n","<br/>");

		-- Image tag. Specifiers after the height are optional, so they
		-- must be suitably defaulted and validated.
		line = line:gsub(IMAGE_PATTERN, function(img, width, height, align)
			-- If you've not given an alignment, or it's entirely invalid,
			-- you'll get the old default of center.
			align = alignmentAttributes[align] or "center";

			-- Don't blow up on non-numeric inputs. They won't display properly
			-- but that's a separate issue.
			width = tonumber(width) or 128;
			height = tonumber(height) or 128;

			-- Width and height should be absolute.
			-- The tag accepts negative value but people used that to fuck up their profiles
			return string.format(IMAGE_TAG, img, math.abs(width), math.abs(height), align);
		end);

		line = line:gsub("%!%[(.-)%]%((.-)%)", function(icon, size)
			if icon:find("\\") then
				-- If icon text contains \ we have a full texture path
				local width, height;
				if size:find("%,") then
					width, height = strsplit(",", size);
				else
					width = tonumber(size) or 128;
					height = width;
				end
				-- Width and height should be absolute.
				-- The tag accepts negative value but people used that to fuck up their profiles
				return string.format(IMAGE_TAG, icon, math.abs(width), math.abs(height), "center");
			end
			return GetIconTag(icon, tonumber(size) or 25);
		end);

		line = line:gsub("{link%:(.-)%:(.-)}", function(playerName, guid)
			local linkText = GetItemBookLink( playerName, guid )
			return "<a href=\""..playerName..":"..guid.."\">"..linkText.."</a>"
		end);

		finalText = finalText .. line;
	end

	finalText = convertTextTags(finalText);

	return "<HTML><BODY>" .. finalText .. "</BODY></HTML>";
end

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
	["Darkmoon"] = {
		path = "QuestBackgroundDarkmoon",
		type = "custom",
	},
	["BloodElf"] = {
		path = "QuestBackgroundBloodElf",
		type = "custom",
	},
	["KaelStaff"] = {
		path = "QuestBackgroundKaelStaff",
		type = "custom",
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
	["Legion Runes"] = "Interface\\AddOns\\DiceMaster\\Fonts\\LegionRunes.TTF",
	["Irish Uncialfabeta Bold"] = "Interface\\AddOns\\DiceMaster\\Fonts\\IrishUncialfabeta-Bold.TTF",
	["Elementary Gothic Bookhand"] = "Interface\\AddOns\\DiceMaster\\Fonts\\Elementary_Gothic_Bookhand.TTF",
	["Belwe Medium"] = "Interface\\AddOns\\DiceMaster\\Fonts\\Belwe_Medium.TTF",
	["Darnassian"] = "Interface\\AddOns\\DiceMaster\\Fonts\\DarnassianRunes-Regular.TTF",
	["Thalassian"] = "Interface\\AddOns\\DiceMaster\\Fonts\\Thalassian_Font.TTF",
}

local function SetBookMaterial( materialType )
	DiceMasterBookFramePageBg:SetTexture( nil );
	DiceMasterBookFramePageBg:SetSize(299, 357);
	DiceMasterBookFramePageBg:SetTexCoord( 0, 1, 0, 1 );
	DiceMasterBookMaterialLeft:SetTexture( nil );
	DiceMasterBookMaterialRight:SetTexture( nil );
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
		elseif material.type == "custom" then
			DiceMasterBookFramePageBg:SetTexture( "Interface/AddOns/DiceMaster/Texture/" .. material.path );
			DiceMasterBookFramePageBg:SetTexCoord( 0.00195312, 0.585938, 0.00195312, 0.796875 );
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
	
	SetPortraitToTexture( self.PortraitContainer.portrait, "Interface/Spellbook/Spellbook-Icon" )
	
	DiceMasterBookCurrentPage:SetText( "1/1" );
end

function Me.BookEditorMaterial_OnClick(self, arg1, arg2, checked)
	UIDropDownMenu_SetText( DiceMasterBookEditor.MaterialButton, self:GetText() )
	
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
	
	DiceMasterBookPageText:SetFont( "P", BOOK_FONTS[ self:GetText() ], DiceMasterBookFrame.bookData.fontSize.p or 13, "" );
	
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
		s = string.format("{%s}%s{/%s}", tag, inner, tag2);
	else
		s = string.format("{%s}%s{/%s}", tag, inner, tag);
	end
	DiceMasterBookPageTextEditor:Insert(s);
end

function Me.BookEditor_InsertLink( playerName, guid )
	local itemLink = "{link:"..playerName..":"..guid.."}"
	DiceMasterBookPageTextEditor:Insert( itemLink );
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
		UIErrorsFrame:AddMessage( "You cannot delete the last page.", 1.0, 0.0, 0.0 );
	else
		StaticPopup_Show( "DICEMASTER4_DELETEBOOKPAGE", nil, nil, data )
	end
	
end

function Me.BookEditor_InsertPage( before )
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	if before then
		tinsert( DiceMasterBookFrame.bookData.pages, DiceMasterBookFrame.currentPage, "" )
	else
		tinsert( DiceMasterBookFrame.bookData.pages, "" )
		DiceMasterBookFrame.currentPage = DiceMasterBookFrame.currentPage + 1
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
		pages = { "Text goes here." };
		font = "Frizqt";
		fontSize = {
			p = 13;
			h1 = 18;
			h2 = 16;
		},
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

function Me.BookEditor_SaveCurrentPage()
	if not DiceMasterBookFrame.bookData then
		return
	end
	
	DiceMasterBookFrame.bookData.pages[ DiceMasterBookFrame.currentPage ] = DiceMasterBookPageTextEditor:GetText() or "";
	DiceMaster4.BookFrame_Update()
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

function Me.BookFrame_OnHyperlinkClick(self, url, text, button)
	if not url then return end
	
	local player, guid = strsplit( ":", url )
	
	if not player or not guid then return end
	
	if button == "LeftButton" then
		if IsShiftKeyDown() then
			local channels = {
				"PARTY",
				"RAID",
				"GUILD",
				"WHISPER",
			}
			local channelName = tostring(LAST_ACTIVE_CHAT_EDIT_BOX:GetAttribute("chatType")) or nil
			local dist = "GUILD"
			for i = 1, #channels do
				if channels[i] == channelName then
					dist = channels[i]
					break;
				end
			end
			local channel = nil
			if dist == "WHISPER" then
				channel = ACTIVE_CHAT_EDIT_BOX:GetAttribute("tellTarget") or nil
			end
			
			local slot = false;
	
			for i = 1, 42 do
				if Me.inspectData[player].inventory[i] and Me.inspectData[player].inventory[i].guid == guid then
					slot = i;
					break
				end
			end
	
			if not slot then
				return
			end
			
			Me.Inspect_SendItemSlot( slot, false, dist, channel )
			local name = Me.inspectData[player].inventory[slot].name:gsub( " ", " " )
			ChatEdit_InsertLink(
				string.format( "[DiceMaster4Item:%s:%s:%s]", player, guid, name ) ) 
		else
			local link = "DiceMaster4Item:"..player..":"..guid
			ItemRefTooltip:SetHyperlink(link)
		end
	end
end

function Me.BookFrame_OnHyperlinkEnter(self, url, text)
	if not url then return end
	
	local player, guid = strsplit( ":", url )
	
	if not player or not guid then return end
	
	local slot = false;
	for i = 1, 42 do
		if Me.inspectData[player].inventory[i] and Me.inspectData[player].inventory[i].guid == guid then
			slot = i;
			break
		end
	end

	if not slot then
		-- request a status update from the player if we can't find the item
		local request_data = {
			ts = {};
			ss = Me.inspectData[player].statusSerial;
			bs = {};
		}
		local msg = Me:Serialize( "INSP", request_data )
		Me:SendCommMessage( "DCM4", msg, "WHISPER", player, "NORMAL" )
		return
	end
	
	Me.OpenItemTooltip( nil, UnitName("player"), slot )
end

function Me.BookFrame_OnHyperlinkLeave()
	GameTooltip:Hide()
	DiceMasterTooltipIcon:Hide()
	DiceMasterTooltipIcon.approved:Hide()
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
	DiceMasterBookFrameTitleText:SetText( data.title );
	DiceMasterBookPageText:SetText( toHTML( data.pages[ page ] ) );
	DiceMasterBookPageText:SetFont( "P", BOOK_FONTS[ data.font ], data.fontSize.p, "" );
	DiceMasterBookPageText:SetFont( "H1", BOOK_FONTS[ data.font ], data.fontSize.h1, "" );
	DiceMasterBookPageText:SetFont( "H2", BOOK_FONTS[ data.font ], data.fontSize.h2, "" );
	
	local textColor = GetMaterialTextColors( material )
	
	DiceMasterBookPageText:SetTextColor( "P", textColor[1] or 0, textColor[2] or 0, textColor[3] or 0 )
	DiceMasterBookPageText:SetTextColor( "H1", textColor[1] or 0, textColor[2] or 0, textColor[3] or 0 )
	DiceMasterBookPageText:SetTextColor( "H2", textColor[1] or 0, textColor[2] or 0, textColor[3] or 0 )
	
	DiceMasterBookPageTextEditor:SetText( data.pages[ page ] );
	DiceMasterBookPageTextEditor:SetFont( BOOK_FONTS[ data.font ], data.fontSize.p, "" );
	
	DiceMasterBookPageTextEditor:SetTextColor( textColor[1] or 0, textColor[2] or 0, textColor[3] or 0 )
	
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