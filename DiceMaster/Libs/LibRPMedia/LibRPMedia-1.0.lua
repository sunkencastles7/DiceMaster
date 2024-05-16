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

local MINOR_VERSION = 25;

local LRPM10 = LibStub:NewLibrary("LibRPMedia-1.0", MINOR_VERSION);
local LRPM12 = LibStub:GetLibrary("LibRPMedia-1.2", false);

if not LRPM10 then
    return;
end

local FixupIncompatibleData;

LRPM10.IconType = { Texture = LRPM12.IconType.File, Atlas = LRPM12.IconType.Atlas };

function LRPM10:IsMusicDataLoaded()
    return true;  -- No equivalent in 1.2 API.
end

function LRPM10:GetNumMusicFiles()
    return LRPM12:GetNumMusic();
end

function LRPM10:GetMusicDataByName(musicName, target)
    local musicInfo = LRPM12:GetMusicInfoByName(musicName);
    return self:GetMusicDataByIndex(musicInfo and musicInfo.index or nil, target);
end

function LRPM10:GetMusicDataByFile(musicFile, target)
    local musicInfo = LRPM12:GetMusicInfoByFile(musicFile);
    return self:GetMusicDataByIndex(musicInfo and musicInfo.index or nil, target);
end

function LRPM10:GetMusicDataByIndex(musicIndex, target)
    local musicInfo = LRPM12:GetMusicInfoByIndex(musicIndex);

    if not musicInfo then
        return nil;
    end

    if target == "file" then
        return musicInfo.file;
    elseif target == "name" then
        return musicInfo.names[1];
    elseif target == "time" then
        return musicInfo.duration;
    else
        target = target or {};
        target.file = musicInfo.file;
        target.name = musicInfo.names[1];
        target.time = musicInfo.duration;
        return target;
    end
end

function LRPM10:GetMusicFileByName(musicName)
    local musicInfo = LRPM12:GetMusicInfoByName(musicName);
    return musicInfo and musicInfo.file or nil;
end

function LRPM10:GetMusicFileByIndex(musicIndex)
    local musicInfo = LRPM12:GetMusicInfoByIndex(musicIndex);
    return musicInfo and musicInfo.file or nil;
end

function LRPM10:GetMusicFileDuration(musicFile)
    local musicInfo = LRPM12:GetMusicInfoByFile(musicFile);
    return musicInfo and musicInfo.duration or 0;
end

function LRPM10:GetNativeMusicFile(musicFile)
    local musicInfo = LRPM12:GetMusicInfoByFile(musicFile);
    return musicInfo and musicInfo.file or nil;
end

function LRPM10:GetMusicIndexByFile(musicFile)
    local musicInfo = LRPM12:GetMusicInfoByFile(musicFile);
    return musicInfo and musicInfo.index or nil;
end

function LRPM10:GetMusicIndexByName(musicName)
    local musicInfo = LRPM12:GetMusicInfoByName(musicName);
    return musicInfo and musicInfo.index or nil;
end

function LRPM10:GetMusicNameByIndex(musicIndex)
    local musicInfo = LRPM12:GetMusicInfoByIndex(musicIndex);
    return musicInfo and musicInfo.names[1] or nil;
end

function LRPM10:GetMusicNameByFile(musicFile)
    local musicInfo = LRPM12:GetMusicInfoByFile(musicFile);
    return musicInfo and musicInfo.names[1] or nil;
end

function LRPM10:FindMusicFiles(musicName, options)
    local NextMusic = LRPM12:FindMusic(musicName, options);

    local function NextUnpackedMusic()
        local musicInfo = NextMusic();

        if musicInfo then
            return musicInfo.index, musicInfo.file, musicInfo.matchingName;
        end
    end

    return NextUnpackedMusic;
end

function LRPM10:FindAllMusicFiles()
    return self:FindMusicFiles("", { reuseTable = {} });
end

function LRPM10:IsIconDataLoaded()
    return true;  -- No equivalent in 1.2 API.
end

function LRPM10:GetNumIcons()
    return LRPM12:GetNumIcons();
end

function LRPM10:GetIconDataByName(iconName, target)
    local iconInfo = LRPM12:GetIconInfoByName(iconName);
    return self:GetIconDataByIndex(iconInfo and iconInfo.index or nil, target);
end

function LRPM10:GetIconDataByIndex(iconIndex, target)
    local iconInfo = FixupIncompatibleData(LRPM12:GetIconInfoByIndex(iconIndex));

    if not iconInfo then
        return nil;
    end

    if target == "file" then
        return iconInfo.file;
    elseif target == "name" then
        return iconInfo.name;
    elseif target == "type" then
        return iconInfo.type;
    else
        target = target or {};
        target.file = iconInfo.file;
        target.name = iconInfo.name;
        target.type = iconInfo.type;
        return target;
    end
end

function LRPM10:GetIconNameByIndex(iconIndex)
    local iconInfo = LRPM12:GetIconInfoByIndex(iconIndex);
    return iconInfo and iconInfo.name or nil;
end

function LRPM10:GetIconFileByIndex(iconIndex)
    local iconInfo = FixupIncompatibleData(LRPM12:GetIconInfoByIndex(iconIndex));
    return iconInfo and iconInfo.file or nil;
end

function LRPM10:GetIconFileByName(iconName)
    local iconInfo = FixupIncompatibleData(LRPM12:GetIconInfoByName(iconName));
    return iconInfo and iconInfo.file or nil;
end

function LRPM10:GetIconTypeByIndex(iconIndex)
    local iconInfo = FixupIncompatibleData(LRPM12:GetIconInfoByIndex(iconIndex));
    return iconInfo and iconInfo.type or nil;
end

function LRPM10:GetIconTypeByName(iconName)
    local iconInfo = FixupIncompatibleData(LRPM12:GetIconInfoByName(iconName));
    return iconInfo and iconInfo.type or nil;
end

function LRPM10:GetIconIndexByName(iconName)
    local iconInfo = FixupIncompatibleData(LRPM12:GetIconInfoByName(iconName));
    return iconInfo and iconInfo.index or nil;
end

function LRPM10:FindIcons(iconName, options)
    local NextIcon = LRPM12:FindIcons(iconName, options);

    local function NextUnpackedIcon()
        local iconInfo = FixupIncompatibleData(NextIcon());

        if iconInfo then
            return iconInfo.index, iconInfo.name;
        end
    end

    return NextUnpackedIcon;
end

function LRPM10:FindAllIcons()
    return self:FindIcons("", { reuseTable = {} });
end

--
-- Internal Functions
--

function LRPM10:NewDatabase()
    -- No-op; required so that older versions don't error if loaded.
end

function FixupIncompatibleData(iconInfo)
    if not iconInfo then
        return nil;
    elseif iconInfo.type == LRPM12.IconType.Atlas then
        iconInfo.type = LRPM12.IconType.File;
        iconInfo.atlas = nil;
        iconInfo.file = 134400; -- Interface\ICONS\INV_Misc_QuestionMark
        iconInfo.key = "INV_Misc_QuestionMark";
        iconInfo.name = "INV_Misc_QuestionMark";
    elseif not GetFileIDFromPath([[Interface\ICONS\]] .. iconInfo.name) then
        iconInfo.atlas = nil;
        iconInfo.file = 134400; -- Interface\ICONS\INV_Misc_QuestionMark
        iconInfo.key = "INV_Misc_QuestionMark";
        iconInfo.name = "INV_Misc_QuestionMark";
    end

    return iconInfo;
end

