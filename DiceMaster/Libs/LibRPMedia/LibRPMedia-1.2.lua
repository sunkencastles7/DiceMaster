-- This is free and unencumbered software released into the public domain.
--
-- Anyone is free to copy, modify, publish, use, compile, sell, or
-- distribute this software, either in source code form or as a compiled
-- binary, for any purpose, commercial or non-commercial, and by any
-- means.
--
-- In jurisdictions that recognize copyright laws, the author or authors
-- of this software dedicate any and all copyright interest in the
-- software to the public domain. We make this dedication for the benefit
-- of the public at large and to the detriment of our heirs and
-- successors. We intend this dedication to be an overt act of
-- relinquishment in perpetuity of all present and future rights to this
-- software under copyright law.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
-- OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
-- ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
-- OTHER DEALINGS IN THE SOFTWARE.
--
-- For more information, please refer to <https://unlicense.org>

assert(LibStub, "Missing dependency: LibStub");

local MINOR_VERSION = 15;

local LRPM12 = LibStub:NewLibrary("LibRPMedia-1.2", MINOR_VERSION);

if not LRPM12 then
    return;
end

local ICON_ID_TYPE_MASK = 0xfc000000;
local ICON_ID_DATA_MASK = 0x03ffffff;
local INV_MISC_QUESTIONMARK = 134400;

local AlwaysTrue;
local BinarySearch;
local CreateIndexedIterator;
local CreateSearchPredicate;
local EnumerateMusicNames;
local GetIconIndexByID;
local GetIconIndexByName;
local GetIconInfoByIndex;
local GetIconType;
local GetMusicIndexByFile;
local GetMusicIndexByID;
local GetMusicIndexByName;
local GetMusicInfoByIndex;
local GetMusicNameIndexRange;
local GetMusicNamesByIndex;
local IsAtlasName;
local IsIconFileName;

local musicIndexByName = {};
local iconIndexByName = {};

--
-- Enums
--

LRPM12.IconType = { File = 1, Atlas = 2 };

--
-- Music API
--

function LRPM12:GetNumMusic()
    return self.db.music.size;
end

function LRPM12:GetAllMusic()
    local music = {};

    for _, musicInfo in self:EnumerateMusic() do
        table.insert(music, musicInfo);
    end

    return music;
end

function LRPM12:GetMusicInfoByFile(musicFile)
    return GetMusicInfoByIndex(self.db.music, GetMusicIndexByFile(self.db.music, musicFile));
end

function LRPM12:GetMusicInfoByID(musicID)
    return GetMusicInfoByIndex(self.db.music, GetMusicIndexByID(self.db.music, musicID));
end

function LRPM12:GetMusicInfoByIndex(musicIndex)
    return GetMusicInfoByIndex(self.db.music, musicIndex);
end

function LRPM12:GetMusicInfoByName(musicName)
    return GetMusicInfoByIndex(self.db.music, GetMusicIndexByName(self.db.music, musicName));
end

function LRPM12:EnumerateMusic(options)
    return CreateIndexedIterator(self.db.music, GetMusicInfoByIndex, options and options.reuseTable or nil);
end

function LRPM12:FindMusic(predicate, options)
    predicate = CreateSearchPredicate(predicate, options);

    local musicDB = self.db.music;
    local musicIndex = 1;
    local musicCount = musicDB.size;

    local function NextMatchingMusic()
        for i = musicIndex, musicCount do
            for _, name in EnumerateMusicNames(musicDB, i, i) do
                if predicate(name) then
                    musicIndex = i + 1;

                    local musicInfo = GetMusicInfoByIndex(musicDB, i, options and options.reuseTable or nil);
                    musicInfo.matchingName = name;
                    return musicInfo;
                end
            end
        end
    end

    return NextMatchingMusic;
end

--
-- Icons API
--

function LRPM12:GetNumIcons()
    return self.db.icons.size;
end

function LRPM12:GetAllIcons()
    local icons = {};

    for _, iconInfo in self:EnumerateIcons() do
        table.insert(icons, iconInfo);
    end

    return icons;
end

function LRPM12:GetIconInfoByID(iconID)
    return GetIconInfoByIndex(self.db.icons, GetIconIndexByID(self.db.icons, iconID));
end

function LRPM12:GetIconInfoByIndex(iconIndex)
    return GetIconInfoByIndex(self.db.icons, iconIndex);
end

function LRPM12:GetIconInfoByName(iconName)
    return GetIconInfoByIndex(self.db.icons, GetIconIndexByName(self.db.icons, iconName));
end

function LRPM12:EnumerateIcons(options)
    return CreateIndexedIterator(self.db.icons, GetIconInfoByIndex, options and options.reuseTable or nil);
end

function LRPM12:FindIcons(predicate, options)
    predicate = CreateSearchPredicate(predicate, options);

    local iconsDB = self.db.icons;
    local iconIndex = 1;
    local iconCount = iconsDB.size;

    local function NextMatchingIcon()
        for i = iconIndex, iconCount do
            local name = iconsDB.name[i];

            if predicate(name) then
                iconIndex = i + 1;

                local iconInfo = GetIconInfoByIndex(iconsDB, i, options and options.reuseTable or nil);
                iconInfo.matchingName = name;
                return iconInfo;
            end
        end
    end

    return NextMatchingIcon;
end

--
-- Auxiliary API
--

function LRPM12:PlayMusic(musicID, ...)
    local musicInfo = self:GetMusicInfoByID(musicID);

    if musicInfo then
        return true, PlayMusic(musicInfo.file, ...);
    else
        return false;
    end
end

function LRPM12:PlayMusicSoundFile(musicID, ...)
    local musicInfo = self:GetMusicInfoByID(musicID);

    if musicInfo then
        return true, PlaySoundFile(musicInfo.file, ...);
    else
        return false;
    end
end

function LRPM12:SetTextureToIcon(texture, icon)
    local iconSource, iconType = self:ResolveIcon(icon);

    if iconType == LRPM12.IconType.Atlas then
        texture:SetAtlas(iconSource);
    else
        texture:SetTexture(iconSource);
    end
end

function LRPM12:SetPortraitToIcon(texture, icon)
    if not texture.LRPM12_TextureMask then
        local mask = [[Interface\CHARACTERFRAME\TempPortraitAlphaMask]];
        local wrapMode = "CLAMPTOBLACKADDITIVE";

        texture.LRPM12_TextureMask = texture:GetParent():CreateMaskTexture();
        texture.LRPM12_TextureMask:SetAllPoints(texture);
        texture.LRPM12_TextureMask:SetTexture(mask, wrapMode, wrapMode);
        texture:AddMaskTexture(texture.LRPM12_TextureMask);
    end

    return self:SetTextureToIcon(texture, icon);
end

function LRPM12:GenerateIconMarkup(icon, width, height, offsetX, offsetY)
    local iconSource, iconType = self:ResolveIcon(icon);
    local markupBase;

    if iconType == LRPM12.IconType.Atlas then
        markupBase = "|A:%1$s:%3$d:%2$d:%4$d:%5$d|a";
    else
        markupBase = "|T%1$s:%3$d:%2$d:%4$d:%5$d:%2$d:%3$d|t";
    end

    return string.format(markupBase, iconSource, width, height, offsetX or 0, offsetY or 0);
end

function LRPM12:ResolveIcon(icon)
    -- The input icon is either an atlas name, a possibly-stringified file
    -- ID, or an icon name.

    if IsAtlasName(icon) then
        return icon, LRPM12.IconType.Atlas;
    end

    -- Try to coerce the token to a number, if that fails we'll attempt
    -- to resolve a file ID from it (assuming it's a name), and finally
    -- if that fails we'll default it to a question mark.

    local file = tonumber(icon);

    if not file then
        file = GetFileIDFromPath([[Interface\ICONS\]] .. tostring(icon));
    end

    -- Checking for an index by its ID (which for files is the same as
    -- the ID) is done here to weed out invalid file IDs for non-icons.

    if not file or not GetIconIndexByID(self.db.icons, bit.band(file, ICON_ID_DATA_MASK)) then
        file = INV_MISC_QUESTIONMARK;
    end

    return file, LRPM12.IconType.File;
end

--
-- Internal Functions
--

LRPM12.db = nil;

function AlwaysTrue()
    return true;
end

function BinarySearch(t, v, i, j)
    local floor = math.floor;

    local l = i or 1;
    local r = j or #t;

    while l <= r do
        local m = floor((l + r) / 2);
        if t[m] < v then
            l = m + 1;
        elseif t[m] > v then
            r = m - 1;
        else
            return m;
        end
    end

    return nil;
end

function CreateIndexedIterator(source, accessor, ...)
    local index = 0;
    local args = { n = select("#", ...), ... };

    local function NextItem()
        local item = accessor(source, index + 1, unpack(args, 1, args.n));

        if item then
            index = index + 1;
            return index, item;
        end
    end

    return NextItem;
end

function CreateSearchPredicate(predicate, options)
    if predicate == nil or predicate == "" then
        -- Predicate is nil or empty, so default to always passing.
        return AlwaysTrue;
    elseif type(predicate) == "string" then
        -- Predicate is a string, so it's a text-based search.
        local method = options and options.method or "substring";
        local search = string.lower(predicate);
        local plain  = (method ~= "pattern");

        return function(text)
            local index = string.find(text, search, 1, plain);
            return (method ~= "prefix" and index) or (method == "prefix" and index == 1);
        end
    else
        -- Predicate is assumed to be callable.
        return predicate;
    end
end

function EnumerateMusicNames(musicDB, i, j)
    local mi, mj = i or 1, j or musicDB.size;
    local ni, nj = GetMusicNameIndexRange(musicDB, mi);

    local function NextMusicName()
        while mi <= mj do
            if ni <= nj then
                local name = musicDB.name[ni];
                ni = ni + 1;
                return mi, name;
            else
                mi = mi + 1;
                ni, nj = GetMusicNameIndexRange(musicDB, mi);
            end
        end
    end

    return NextMusicName;
end

function GetIconIndexByID(iconsDB, iconID)
    return BinarySearch(iconsDB.id, iconID, 1, iconsDB.size);
end

function GetIconIndexByName(iconsDB, iconName)
    if not next(iconIndexByName) then
        for index = 1, iconsDB.size do
            local name = iconsDB.name[index];
            iconIndexByName[name] = iconIndexByName[name] or index;
        end
    end

    return iconIndexByName[string.lower(iconName)];
end

function GetIconInfoByIndex(iconsDB, iconIndex, infoTable)
    if not iconIndex or iconIndex < 1 or iconIndex > iconsDB.size then
        return nil;
    end

    local id = iconsDB.id[iconIndex];
    local name = iconsDB.name[iconIndex];
    local type = GetIconType(id);
    local file = (type == LRPM12.IconType.File) and bit.band(id, ICON_ID_DATA_MASK) or nil;
    local atlas = (type == LRPM12.IconType.Atlas) and bit.band(id, ICON_ID_DATA_MASK) or nil;
    local key = (type == LRPM12.IconType.Atlas or IsIconFileName(name)) and name or file;

    local iconInfo = infoTable or {};
    iconInfo.index = iconIndex;
    iconInfo.id = id;
    iconInfo.key = key;
    iconInfo.name = name;
    iconInfo.type = type;
    iconInfo.file = file;
    iconInfo.atlas = atlas;

    return iconInfo;
end

function GetIconType(iconID)
    if type(iconID) ~= "number" then
        return nil;
    elseif bit.band(iconID, ICON_ID_TYPE_MASK) ~= 0 then
        return LRPM12.IconType.Atlas;
    else
        return LRPM12.IconType.File;
    end
end

function GetMusicIndexByFile(musicDB, musicFile)
    return BinarySearch(musicDB.file, musicFile, 1, musicDB.size);
end

function GetMusicIndexByID(musicDB, musicID)
    return GetMusicIndexByFile(musicDB, musicID);
end

function GetMusicIndexByName(musicDB, musicName)
    if not next(musicIndexByName) then
        for index, name in EnumerateMusicNames(musicDB) do
            musicIndexByName[name] = musicIndexByName[name] or index;
        end
    end

    return musicIndexByName[string.lower(musicName or "")];
end

function GetMusicInfoByIndex(musicDB, musicIndex, infoTable)
    if not musicIndex or musicIndex < 1 or musicIndex > musicDB.size then
        return nil;
    end

    local file = musicDB.file[musicIndex];
    local duration = musicDB.time[musicIndex];

    local musicInfo = infoTable or {};
    musicInfo.index = musicIndex;
    musicInfo.id = file;
    musicInfo.duration = duration;
    musicInfo.names = GetMusicNamesByIndex(musicDB, musicIndex, musicInfo.names);
    musicInfo.file = file;

    return musicInfo;
end

function GetMusicNameIndexRange(musicDB, musicIndex)
    local nkey = musicDB.nkey[musicIndex] or math.huge;
    local nstart = bit.rshift(nkey, 5) + 1;
    local ncount = bit.band(nkey, 0x1f);

    return nstart, nstart + ncount;
end

function GetMusicNamesByIndex(musicDB, musicIndex, namesTable)
    local first, last = GetMusicNameIndexRange(musicDB, musicIndex);
    local names = namesTable or {};

    table.wipe(names);

    for i = first, last do
        table.insert(names, musicDB.name[i]);
    end

    return names;
end

function IsAtlasName(atlasName)
    if type(atlasName) ~= "string" then
        return false;
    elseif C_Texture then
        return C_Texture.GetAtlasInfo(atlasName) ~= nil;
    else
        return GetAtlasInfo(atlasName) ~= nil;
    end
end

function IsIconFileName(iconName)
    return GetFileIDFromPath([[Interface\ICONS\]] .. iconName) ~= nil;
end

