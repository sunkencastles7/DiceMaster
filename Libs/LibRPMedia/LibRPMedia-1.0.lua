-- This file is licensed under the terms expressed in the LICENSE file.
assert(LibStub, "Missing dependency: LibStub");

local MODULE_MAJOR = "LibRPMedia-1.0";
local MODULE_MINOR = 18;

local LibRPMedia = LibStub:NewLibrary(MODULE_MAJOR, MODULE_MINOR);
if not LibRPMedia then
    return;
end

-- Upvalues.
local error = error;
local floor = math.floor;
local min = math.min;
local select = select;
local setmetatable = setmetatable;
local strbyte = string.byte;
local strfind = string.find;
local strformat = string.format;
local strgsub = string.gsub;
local strjoin = string.join;
local strlower = string.lower;
local strsplit = string.split;
local strsub = string.sub;
local type = type;
local xpcall = xpcall;

local CallErrorHandler = CallErrorHandler;
local Mixin = Mixin;

-- Local declarations.
local AssertType;
local BinarySearch;
local BinarySearchPrefix;
local CheckType;
local GetCommonPrefixLength;
local IterIcons;
local IterIconsByPattern;
local IterIconsByPrefix;
local IterIndexByPattern;
local IterIndexByPrefix;
local IterMusicFiles;
local IterMusicFilesByPattern;
local IterMusicFilesByPrefix;
local NormalizeIconName;
local NormalizeMusicName;

-- Error constants.
local ERR_DATABASE_NOT_FOUND = "LibRPMedia: Database %q was not found";
local ERR_INVALID_ARG_TYPE = "LibRPMedia: Argument %q is %s, expected %s";
local ERR_INVALID_SEARCH_METHOD = "LibRPMedia: Invalid search method: %q";

--- Music Database API

--- Returns true if music data is presently loaded.
--
--  If this returns false, most other music API functions will error.
function LibRPMedia:IsMusicDataLoaded()
    return self:IsDatabaseRegistered("music");
end

--- Returns the number of music files in the database.
function LibRPMedia:GetNumMusicFiles()
    return self:GetNumDatabaseEntries("music");
end

--- Returns data about a given music file identified by its name.
--
--  An optional second parameter (target) may be specified to control the type
--  of data yielded by the query.
--
--  If a string is given, it must correspond to a field in the database, and
--  will return the value associated with this music file for that field.
--  Invalid field lookups will return nil.
--
--  If a table is given, all fields are collected into the given table and
--  returned. If nil is given, a table is created automatically. The contents
--  of the table are not wiped between calls.
--
--  If the requested music file is not found within the database, nil is
--  returned for all query types.
function LibRPMedia:GetMusicDataByName(musicName, target)
    local musicIndex = self:GetMusicIndexByName(musicName);
    if not musicIndex then
        return nil;
    end

    return self:GetMusicDataByIndex(musicIndex, target);
end

--- Returns data about a given music file identified by its file ID.
--
--  An optional second parameter (target) may be specified to control the type
--  of data yielded by the query.
--
--  If a string is given, it must correspond to a field in the database, and
--  will return the value associated with this music file for that field.
--  Invalid field lookups will return nil.
--
--  If a table is given, all fields are collected into the given table and
--  returned. If nil is given, a table is created automatically. The contents
--  of the table are not wiped between calls.
--
--  If the requested music file is not found within the database, nil is
--  returned for all query types.
function LibRPMedia:GetMusicDataByFile(musicFile, target)
    local musicIndex = self:GetMusicIndexByFile(musicFile);
    if not musicIndex then
        return nil;
    end

    return self:GetMusicDataByIndex(musicIndex, target);
end

--- Returns data about a given music file identified by its index within
--  the database.
--
--  An optional second parameter (target) may be specified to control the type
--  of data yielded by the query.
--
--  If a string is given, it must correspond to a field in the database, and
--  will return the value associated with this music file for that field.
--  Invalid field lookups will return nil.
--
--  If a table is given, all fields are collected into the given table and
--  returned. If nil is given, a table is created automatically. The contents
--  of the table are not wiped between calls.
--
--  If the requested music file is not found within the database, nil is
--  returned for all query types.
function LibRPMedia:GetMusicDataByIndex(musicIndex, target)
    AssertType(musicIndex, "musicIndex", "number");

    local music = self:GetDatabase("music");
    if musicIndex < 1 or musicIndex > music.size then
        -- Index out of range.
        return nil;
    end

    local targetType = type(target);
    if targetType == "string" then
        -- Look up a specific field name.
        local fieldData = music.data[target];
        if not fieldData then
            -- Field name doesn't exist.
            return nil;
        end

        return fieldData[musicIndex];
    elseif targetType == "table" or targetType == "nil" then
        -- Collect into the given table, or create a fresh one.
        local fieldTable = target or {};

        -- The data table is lazily loaded; this breaks pairs/next iteration
        -- until a named field is explicitly looked up.
        local _ = music.data._;

        for fieldName, fieldData in pairs(music.data) do
            fieldTable[fieldName] = fieldData[musicIndex];
        end

        return fieldTable;
    else
        -- Invalid target type; the below check will always fail but it
        -- generates a useful error message for us to spit back out.
        AssertType(target, "target", "string", "table", "nil");
    end
end

--- Returns the file ID for a music file based on its soundkit name, or
--  file path.
--
--  If no match is found, nil is returned.
function LibRPMedia:GetMusicFileByName(musicName)
    return self:GetMusicDataByName(musicName, "file");
end

--- Returns the file ID for a music file based on its index, in the range
--  1 through GetNumMusicFiles.
--
--  If no file is found, nil is returned.
function LibRPMedia:GetMusicFileByIndex(musicIndex)
    return self:GetMusicDataByIndex(musicIndex, "file");
end

--- Returns the duration of a music file from its file ID, if known. The
--  value returned is in fractional seconds.
--
--  If no file is found, or no duration information is available, this will
--  return 0.
function LibRPMedia:GetMusicFileDuration(musicFile)
    return self:GetMusicDataByFile(musicFile, "time") or 0;
end

--- Converts a music file ID to a native music file value that can be
--  supplied to in-game APIs such as PlayMusic and PlaySoundFile.
--
--  If the given music file does not exist in the database, nil is returned.
--
--  The return type of a valid music file is unspecified; the only guarantees
--  are that it will work with most ingame API functions and is convertible
--  to a string.
function LibRPMedia:GetNativeMusicFile(musicFile)
    AssertType(musicFile, "musicFile", "number");

    -- Validate the input file and return nil if invalid.
    if not self:GetMusicIndexByFile(musicFile) then
        return nil;
    end

    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
        -- Classic doesn't support file IDs, so we need to use paths.
        local musicName = self:GetMusicNameByFile(musicFile);
        return strjoin("\\", "Sound", "Music", strsplit("/", musicName)) .. ".mp3";
    end

    -- Default to returning the file ID otherwise.
    return musicFile;
end

--- Returns the index of a music file from its file ID. If the given file
--  ID is not present in the database, nil is returned.
--
--  Indices are not stable and may change between upgrades to the library.
function LibRPMedia:GetMusicIndexByFile(musicFile)
    AssertType(musicFile, "musicFile", "number");

    local music = self:GetDatabase("music");
    return BinarySearch(music.data.file, musicFile);
end

--- Returns the index of a music file from its name. If no matching name
--  is found in the database, nil is returned.
--
--  Indices are not stable and may change between upgrades to the library.
function LibRPMedia:GetMusicIndexByName(musicName)
    AssertType(musicName, "musicName", "string");

    musicName = NormalizeMusicName(musicName);

    local music = self:GetDatabase("music");
    local names = music.index.name;
    return names.row[BinarySearch(names.key, musicName)];
end

--- Returns a string name for a music file based on its index, in the range
--  1 through GetNumMusicFiles.
--
--  While a music file may have multiple names in the form of soundkit
--  names or file paths, this function will return only one predefined name.
--
--  If no name is found, nil is returned.
function LibRPMedia:GetMusicNameByIndex(musicIndex)
    return self:GetMusicDataByIndex(musicIndex, "name");
end

--- Returns a string name for a music file based on its file ID.
--
--  If no name is found, nil is returned.
function LibRPMedia:GetMusicNameByFile(musicFile)
    return self:GetMusicDataByFile(musicFile, "name");
end

--- Returns an iterator for accessing all music files in the database
--  matching the given name, matching according to the given options table.
--
--  The iterator will return triplet of file index, file ID, and file name.
--
--  The order of which files are returned by this iterator is not guaranteed.
function LibRPMedia:FindMusicFiles(musicName, options)
    AssertType(musicName, "musicName", "string");
    AssertType(options, "options", "table", "nil");

    -- If the search space is empty then everything matches; the iterator
    -- from FindAllMusic files is *considerably* more efficient.
    if musicName == "" then
        return self:FindAllMusicFiles();
    end

    -- Default the options and extract them.
    local optMethod = options and options.method or "prefix";

    -- Grab the database and search appropriately.
    local music = self:GetDatabase("music");
    if optMethod == "prefix" then
        return IterMusicFilesByPrefix(music, musicName);
    elseif optMethod == "substring" then
        musicName = NormalizeMusicName(musicName);
        return IterMusicFilesByPattern(music, musicName, true);
    elseif optMethod == "pattern" then
        -- We won't normalize a pattern because it's a bit tricky.
        return IterMusicFilesByPattern(music, musicName, false);
    else
        error(strformat(ERR_INVALID_SEARCH_METHOD, optMethod), 2);
    end
end

--- Returns an iterator for accessing all music files in the database.
--  The iterator will return a triplet of file index, file ID, and file name.
--
--  The order of which files are returned by this iterator is not guaranteed.
function LibRPMedia:FindAllMusicFiles()
    local music = self:GetDatabase("music");
    return IterMusicFiles(music);
end

--- Icon Database API

--- Icon type enumeration.
LibRPMedia.IconType = {
    -- Icon name is a standard texture file in the Interface\Icons folder.
    Texture = 1,
    -- Icon name is a texture atlas.
    Atlas = 2,
};

--- Returns true if icon data is presently loaded.
--
--  If this returns false, most other icon API functions will error.
function LibRPMedia:IsIconDataLoaded()
    return self:IsDatabaseRegistered("icons");
end

--- Returns the number of icons in the database.
function LibRPMedia:GetNumIcons()
    return self:GetNumDatabaseEntries("icons");
end

--- Returns data about a given icon identified by its name.
--
--  An optional second parameter (target) may be specified to control the type
--  of data yielded by the query.
--
--  If a string is given, it must correspond to a field in the database, and
--  will return the value associated with this icon for that field. Invalid
--  field lookups will return nil.
--
--  If a table is given, all fields are collected into the given table and
--  returned. If nil is given, a table is created automatically. The contents
--  of the table are not wiped between calls.
--
--  If the requested icon is not found within the database, nil is returned
--  for all query types.
function LibRPMedia:GetIconDataByName(iconName, target)
    local iconIndex = self:GetIconIndexByName(iconName);
    if not iconIndex then
        return nil;
    end

    return self:GetIconDataByIndex(iconIndex, target);
end

--- Returns data about a given icon identified by its index within
--  the database.
--
--  An optional second parameter (target) may be specified to control the type
--  of data yielded by the query.
--
--  If a string is given, it must correspond to a field in the database, and
--  will return the value associated with this icon for that field. Invalid
--  field lookups will return nil.
--
--  If a table is given, all fields are collected into the given table and
--  returned. If nil is given, a table is created automatically. The contents
--  of the table are not wiped between calls.
--
--  If the requested icon is not found within the database, nil is returned
--  for all query types.
function LibRPMedia:GetIconDataByIndex(iconIndex, target)
    AssertType(iconIndex, "iconIndex", "number");

    local icons = self:GetDatabase("icons");
    if iconIndex < 1 or iconIndex > icons.size then
        -- Index out of range.
        return nil;
    end

    local targetType = type(target);
    if targetType == "string" then
        -- Look up a specific field name.
        local fieldData = icons.data[target];
        if not fieldData then
            -- Field name doesn't exist.
            return nil;
        end

        return fieldData[iconIndex];
    elseif targetType == "table" or targetType == "nil" then
        -- Collect into the given table, or create a fresh one.
        local fieldTable = target or {};

        -- The data table is lazily loaded; this breaks pairs/next iteration
        -- until a named field is explicitly looked up.
        local _ = icons.data._;

        for fieldName, fieldData in pairs(icons.data) do
            fieldTable[fieldName] = fieldData[iconIndex];
        end

        return fieldTable;
    else
        -- Invalid target type; the below check will always fail but it
        -- generates a useful error message for us to spit back out.
        AssertType(target, "target", "string", "table", "nil");
    end
end

--- Returns the name of an icon by its index. If the given index is outside
--  of the range 1 through GetNumIcons(), nil is returned.
function LibRPMedia:GetIconNameByIndex(iconIndex)
    return self:GetIconDataByIndex(iconIndex, "name");
end

--- Returns the file ID of an icon by its index. If the given index is
--  outside of the range 1 through GetNumIcons(), nil is returned.
function LibRPMedia:GetIconFileByIndex(iconIndex)
    return self:GetIconDataByIndex(iconIndex, "file");
end

--- Returns the file ID of an icon by its name. If no matching name is found
--  in the database, nil is returned.
function LibRPMedia:GetIconFileByName(iconName)
    return self:GetIconDataByName(iconName, "file");
end

--- Returns the type of an icon by its index. If the given index is outside
--  of the range 1 through GetNumIcons(), nil is returned.
function LibRPMedia:GetIconTypeByIndex(iconIndex)
    return self:GetIconDataByIndex(iconIndex, "type");
end

--- Returns the name of an icon by its name. If no matching name is found in
--  the database, nil is returned.
function LibRPMedia:GetIconTypeByName(iconName)
    return self:GetIconDataByName(iconName, "type");
end

--- Returns the index of an icon from its name. If no matching name is found
--  in the database, nil is returned.
--
--  Indices are not stable and may change between upgrades to the library.
function LibRPMedia:GetIconIndexByName(iconName)
    AssertType(iconName, "iconName", "string");

    local icons = self:GetDatabase("icons");
    return BinarySearch(icons.data.name, NormalizeIconName(iconName));
end

--- Returns an iterator for accessing all icons in the database matching
--  the given name, matching according to the given options table.
--
--  The iterator will yield each matching icon index and name on each
--  successive call, until the end of the matching set is reached.
--
--  The order of which files are returned by this iterator is not guaranteed.
function LibRPMedia:FindIcons(iconName, options)
    AssertType(iconName, "iconName", "string");
    AssertType(options, "options", "table", "nil");

    -- If the search space is empty then everything matches.
    if iconName == "" then
        return self:FindAllIcons();
    end

    -- Default the options and extract them.
    local optMethod = options and options.method or "prefix";

    -- Grab the database and search appropriately.
    local icons = self:GetDatabase("icons");
    if optMethod == "prefix" then
        return IterIconsByPrefix(icons, iconName);
    elseif optMethod == "substring" then
        return IterIconsByPattern(icons, NormalizeIconName(iconName), true);
    elseif optMethod == "pattern" then
        return IterIconsByPattern(icons, iconName, false);
    else
        error(strformat(ERR_INVALID_SEARCH_METHOD, optMethod), 2);
    end
end

--- Returns an iterator for accessing all icons in the database.
--
--  The iterator will yield each icon index and name on each successive call,
--  until the end of the database is reached.
--
--  The order of which icons are returned by this iterator is not guaranteed.
function LibRPMedia:FindAllIcons()
    local icons = self:GetDatabase("icons");
    return IterIcons(icons);
end

--- Internal API
--  The below declarations are for internal use only.

--- Table storing all the databases.
--
--  This _currently_ doesn't persist across upgrades as there's a lot of
--  assumptions about the structure of the data, and the data is packed
--  into the library regardless.
LibRPMedia.schema = {};

--- Registers a named database with the given minor version.
--
--  If a database already exists with a greater or same minor version nil is
--  returned, otherwise a table will be returned.
--
--  The database will be initialized with a size field (set to zero), and a
--  version field matching the given minor version.
function LibRPMedia:NewDatabase(databaseName, minorVersion)
    -- Get or create a table for the database.
    local database = self.schema[databaseName] or {};
    if database.version and database.version >= minorVersion then
        -- No upgrade required.
        return nil;
    end

    -- Upgrade fields on the database.
    database.size = database.size or 0;
    database.version = minorVersion;

    self.schema[databaseName] = database;
    return database;
end

--- Returns true if the named database exists.
function LibRPMedia:IsDatabaseRegistered(databaseName)
    return self.schema[databaseName] ~= nil;
end

--- Returns the named database.
--  This function will error if the database is not present.
function LibRPMedia:GetDatabase(databaseName)
    local database = self.schema[databaseName];
    if not database then
        error(strformat(ERR_DATABASE_NOT_FOUND, databaseName), 2);
    end

    return database;
end

--- Returns the number of entries present within a named database.
--  This function will error if the database is not present.
function LibRPMedia:GetNumDatabaseEntries(databaseName)
    local database = self:GetDatabase(databaseName);
    return database.size;
end

--- Creates a table that lazily loads its contents upon first access to any
--  field.
--
--  If an error occurs during data loading, the global error handler is
--  invoked but execution will not terminate, and nil is instead returned.
function LibRPMedia:CreateLazyTable(generatorFunc)
    local metatable = {};
    metatable.__index = function(proxy, key)
        -- Unset the metatable so that loading is only tried once.
        setmetatable(proxy, nil);

        local ok, data = xpcall(generatorFunc, CallErrorHandler);
        if not ok then
            -- Error is passed through default error handler.
            return nil;
        end

        -- Copy the loaded data into the proxy.
        Mixin(proxy, data);
        return proxy[key];
    end

    return setmetatable({}, metatable);
end

--- Loads the given string of code as a function, executing it and returning
--  the result.
--
--  The loaded function will have an environment with LibRPMedia present.
function LibRPMedia:LoadFunctionFromString(code)
    local chunk = assert(loadstring(code));
    local env = setmetatable({ LibRPMedia = LibRPMedia }, { __index = _G });
    setfenv(chunk, env);

    local data = chunk();

    -- Loading the data often generates a ton of garbage, so we'll sneak in
    -- a free collection before wrapping up.
    collectgarbage("collect");
    return data;
end

--- Restores a string list encoded as a list of front-coded strings, returning
--  a new table with the loaded contents.
function LibRPMedia:LoadFrontCodedStringList(input)
    local output = {};

    -- Iterate over the list in pairs of common prefix length and suffixes.
    for i = 1, #input, 2 do
        local commonLength = input[i];
        local suffix = input[i + 1];

        if commonLength == 0 then
            -- No data in common; the suffix is the whole string.
            output[#output + 1] = suffix;
        else
            -- Combine the suffix with the previously restored string.
            local prefix = output[#output];
            local restored = strsub(prefix, 1, commonLength) .. suffix;

            output[#output + 1] = restored;
        end
    end

    return output;
end

--- Checks the type of a given value against a list of types. If no type
--  matches, returns nil and an error message formatted with the given
--  parameter name.
--
--  On success, the value is returned as-is with a nil error message.
function CheckType(value, name, t1, t2, ...)
    local tv = type(value);

    -- Slight unrolling; handle the common case of a one or two type check
    -- explicitly without having to iterate over the varargs.
    if tv == t1 then
        return value, nil;
    elseif t2 and tv == t2 then
        return value, nil;
    end

    -- Otherwise consult the varargs.
    for i = 1, select("#", ...) do
        local tn = select(i, ...);
        if tv == tn then
            return value, nil;
        end
    end

    -- Invalid parameter.
    local types;
    if not t2 then
        types = t1;
    elseif select("#", ...) == 0 then
        types = strjoin(" or ", t1, t2);
    else
        types = strjoin(", ", t1, t2, ...);
    end

    return nil, strformat(ERR_INVALID_ARG_TYPE, name, tv, types);
end

--- Asserts the type of a given value as with CheckType, but raises an error
--  if the check fails.
--
--  The error will be raised to occur at a stack depth 3 levels higher than
--  this function, and so will be reported by the caller of the function that
--  calls AssertType.
function AssertType(...)
    local value, err = CheckType(...);
    if not value and err then
        error(err, 3);
    end

    return value;
end

--- Internal utility functions.
--  Some of these are copy/pasted from the exporter, so need keeping in sync.

--- Performs a binary search for a value inside a given value, optionally
--  limited to the ranges i through j (defaulting to 1, #table).
--
--  This function will always return the index that is the closest to the
--  given value if an exact match cannot be found.
function BinarySearchPrefix(table, value, i, j)
    local l = i or 1;
    local r = j or #table;

    while l <= r do
        local m = floor((l + r) / 2);
        if table[m] < value then
            l = m + 1;
        elseif table[m] > value then
            r = m - 1;
        else
            return m;
        end
    end

    return l;
end

--- Performs a binary search for a value inside a given table, optionally
--  limited to the ranges i through j (defaulting to 1, #table).
--
--  If a match is found, the index of the value is returned. Otherwise, nil.
function BinarySearch(table, value, i, j)
    local index = BinarySearchPrefix(table, value, i, j);
    return table[index] == value and index or nil;
end

--- Returns the length of the longest common prefix between two strings.
function GetCommonPrefixLength(a, b)
    if a == b then
        return #a;
    end

    local offset = 1;
    local length = min(#a, #b);

    -- The innards of the loop are manually unrolled so we can minimize calls.
    while offset <= length do
        local a1, a2, a3, a4, a5, a6, a7, a8 = strbyte(a, offset, offset + 7);
        local b1, b2, b3, b4, b5, b6, b7, b8 = strbyte(b, offset, offset + 7);

        if a1 ~= b1 then
            return offset - 1;
        elseif a2 ~= b2 then
            return offset;
        elseif a3 ~= b3 then
            return offset + 1;
        elseif a4 ~= b4 then
            return offset + 2;
        elseif a5 ~= b5 then
            return offset + 3;
        elseif a6 ~= b6 then
            return offset + 4;
        elseif a7 ~= b7 then
            return offset + 5;
        elseif a8 ~= b8 then
            return offset + 6;
        end

        offset = offset + 8;
    end

    return offset - 1;
end

--- Returns an iterator that returns all matching rows in the given database
--  index that match a given common prefix string.
--
--  For each matching row, the given accessor function is called with the
--  given data parameter, the row index, and the matched key. The return
--  values from this are yielded to the caller of the iterator.
function IterIndexByPrefix(index, prefix, rowAccessorFunc, data)
    -- Map of row indices that we've already returned.
    local seen = {};

    -- Begin iteration from the closest matching prefix.
    local offset = BinarySearchPrefix(index.key, prefix);
    local length = #index.key;

    local iterator = function()
        -- Loop so long as we don't run out of keys.
        while offset <= length do
            local key = index.key[offset];
            local commonLength = GetCommonPrefixLength(prefix, key);
            if commonLength ~= #prefix then
                -- Common prefix length isn't the full prefix, so we're
                -- past the searchable range where things can match.
                return nil;
            end

            -- Obtain the row index for this key.
            local row = index.row[offset];
            offset = offset + 1;

            if not seen[row] then
                -- Row hasn't been yielded yet; yield data from the accessor.
                seen[row] = true;
                return rowAccessorFunc(data, row, key);
            end
        end
    end

    return iterator;
end

--- Returns an iterator that returns all matching rows in the given database
--  index that match a given pattern string. If plain is true, the search
--  will not be a pattern but rather a substring test.
--
--  For each matching row, the given accessor function is called with the
--  given data parameter, the row index, and the matched key. The return
--  values from this are yielded to the caller of the iterator.
function IterIndexByPattern(index, pattern, plain, rowAccessorFunc, data)
    -- Map of row indices that we've already returned.
    local seen = {};

    -- Start iteration from the start of the index array.
    local offset = 1;
    local length = #index.key;

    local iterator = function()
        -- Loop so long as we don't run out of keys.
        while offset <= length do
            local key = index.key[offset];
            local row = index.row[offset];
            offset = offset + 1;

            -- If the row hasn't been seen, test the key.
            if not seen[row] and strfind(key, pattern, 1, plain) then
                -- Git a hit.
                seen[row] = true;
                return rowAccessorFunc(data, row, key);
            end
        end
    end

    return iterator;
end

-- Music API support functions.
do
    -- Common accessor function for translating a matching row index to a
    -- set of return values for music entry iterators.
    local function accessor(data, row, key)
        -- The music name is always the matched key and not the canonical
        -- name, since searches don't make sense otherwise.
        local musicIndex = row;
        local musicFile = data.file[musicIndex];
        local musicName = key;

        return musicIndex, musicFile, musicName;
    end

    -- Iterator for accessing all music files in index-order.
    local function iterator(music, musicIndex)
        musicIndex = musicIndex + 1;
        if musicIndex > music.size then
            return nil;
        end

        local musicFile = music.data.file[musicIndex];
        local musicName = music.data.name[musicIndex];
        return musicIndex, musicFile, musicName;
    end

    --- Returns an iterator that returns all music files in the database
    --  in index-order.
    function IterMusicFiles(music)
        return iterator, music, 0;
    end

    --- Returns an iterator that returns all matching entries in the given
    --  music database that match a given pattern string. If plain is true,
    --  the search will not be a pattern but rather a substring test.
    function IterMusicFilesByPattern(music, pattern, plain)
        local index = music.index.name;
        local data = music.data;

        return IterIndexByPattern(index, pattern, plain, accessor, data);
    end

    --- Returns an iterator that returns all matching entries in the given
    --  music database that match a given common prefix string.
    function IterMusicFilesByPrefix(music, prefix)
        local index = music.index.name;
        local data = music.data;

        return IterIndexByPrefix(index, prefix, accessor, data);
    end

    --- Normalizes the given music name.
    function NormalizeMusicName(musicName)
        -- Music names are lowercased strings with / path separators.
        return strlower(strgsub(musicName, "\\", "/"));
    end
end

-- Icon API support functions.
do
    -- Iterator for accessing all icons in index-order.
    local function iterator(icons, iconIndex)
        iconIndex = iconIndex + 1;
        if iconIndex > icons.size then
            return nil;
        end

        local iconName = icons.data.name[iconIndex];
        return iconIndex, iconName;
    end

    --- Returns an iterator that returns all icon entries in the database
    --  in index-order.
    function IterIcons(icons)
        return iterator, icons, 0;
    end

    --- Returns an iterator that returns all matching entries in the given
    --  icon database that match a given pattern string. If plain is true,
    --  the search will not be a pattern but rather a substring test.
    function IterIconsByPattern(icons, pattern, plain)
        local patternIterator = function(_, offset)
            -- Test indices until we run out of them.
            for iconIndex = offset + 1, icons.size do
                local iconName = icons.data.name[iconIndex];
                if strfind(iconName, pattern, 1, plain) then
                    -- Icon matches the pattern, yield it.
                    return iconIndex, iconName;
                end
            end
        end

        return patternIterator, icons, 0;
    end

    --- Returns an iterator that returns all matching entries in the given
    --  icon database that match a given common prefix string.
    function IterIconsByPrefix(icons, prefix)
        local prefixIterator = function(_, offset)
            local iconIndex = offset + 1;
            local iconName = icons.data.name[iconIndex];
            local commonLength = GetCommonPrefixLength(prefix, iconName);
            if commonLength == #prefix then
                -- Common prefix length still matches, so this is a hit.
                return iconIndex, iconName;
            end

            -- Common prefix length isn't the full prefix, so we're
            -- past the searchable range where things can match.
            return nil;
        end

        -- Start iteration from the index before the matched prefix, as our
        -- name data is stored alphabetically.
        local startIndex = BinarySearchPrefix(icons.data.name, prefix);
        return prefixIterator, icons, startIndex - 1;
    end

    --- Normalizes the given icon name.
    function NormalizeIconName(iconName)
        -- Icon names are just lowercased strings.
        return strlower(iconName);
    end
end

