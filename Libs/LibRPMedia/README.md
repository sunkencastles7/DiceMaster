# LibRPMedia

LibRPMedia provides a common database of in-game resources for use by RP addons.

## Embedding

LibRPMedia uses [LibStub](https://www.curseforge.com/wow/addons/libstub) as its versioning mechanism, so the existing documentation with regards to embedding and loading the library applies here.

You can import this repository as a Git submodule, or just download a release and copy the folder into your own project as needed. To load the library, include a reference to the `LibRPMedia-1.0.xml` file within your addon.

### Dependencies

This library depends upon the following. These libraries are loaded automatically when including any of the above XML files.

 * [LibStub](https://www.curseforge.com/wow/addons/libstub)

Copies of these are present in the Libs directory as a convenience and may be used by the embedding addon.

## Usage

### Music API

#### `LibRPMedia:IsMusicDataLoaded()`

Returns `true` if the music database has been loaded. If this returns `false`, most other Music API functions will raise errors.

##### Usage

```lua
print("Is music data loaded?", LibRPMedia:IsMusicDataLoaded());
-- Example output: "Is music data loaded? true"
```

#### `LibRPMedia:GetNumMusicFiles()`

Returns the number of music files present within the database.

##### Usage

```lua
print("Number of music files:", LibRPMedia:GetNumMusicFiles());
-- Example output: "Number of music files: 192"
```

#### `LibRPMedia:GetMusicDataByName(musicName[, target])`

Returns data about a music file identified by its name.

An optional second parameter (target) may be specified to control the type of data yielded by the query:

* If a string is given, it must correspond to a field in the database, and will return the value associated with this music file for that field. Invalid field lookups will return `nil`.
* If a table is given, all fields are collected into the given table and returned. The contents of the table are not wiped.
* If nil is given, a table is created automatically, and all fields will be collected into it and returned.

If the requested music file is not found within the database, `nil` is returned for all query types.

##### Usage

```lua
local musicData = LibRPMedia:GetMusicDataByName("citymusic/darnassus/darnassus intro");
local musicFile = LibRPMedia:GetMusicDataByName("citymusic/darnassus/darnassus intro", "file");

assert(musicData.file == musicFile);
print("Music file ID:", musicFile);
-- Example output: "Music file ID: 53183"
```

#### `LibRPMedia:GetMusicDataByFile(musicName[, target])`

Returns data about a music file identified by its file ID.

An optional second parameter (target) may be specified to control the type of data yielded by the query:

* If a string is given, it must correspond to a field in the database, and will return the value associated with this music file for that field. Invalid field lookups will return `nil`.
* If a table is given, all fields are collected into the given table and returned. The contents of the table are not wiped.
* If nil is given, a table is created automatically, and all fields will be collected into it and returned.

If the requested music file is not found within the database, `nil` is returned for all query types.

##### Usage

```lua
local musicData = LibRPMedia:GetMusicDataByFile(53183);
local musicName = LibRPMedia:GetMusicDataByFile(53183, "name");

assert(musicData.name == musicName);
print("Music name:", musicName);
-- Example output: "Music name: citymusic/darnassus/darnassus intro"
```

#### `LibRPMedia:GetMusicDataByIndex(musicIndex[, target])`

Returns data about a music file identified by its numeric index inside the database, in the range of 1 through the result of `LibRPMedia:GetNumMusicFiles()`.

An optional second parameter (target) may be specified to control the type of data yielded by the query:

* If a string is given, it must correspond to a field in the database, and will return the value associated with this music file for that field. Invalid field lookups will return `nil`.
* If a table is given, all fields are collected into the given table and returned. The contents of the table are not wiped.
* If nil is given, a table is created automatically, and all fields will be collected into it and returned.

If the requested music file is not found within the database, `nil` is returned for all query types.

##### Usage

```lua
local musicData = LibRPMedia:GetMusicDataByIndex(1);
local musicFile = LibRPMedia:GetMusicDataByIndex(1, "file");

assert(musicData.file == musicFile);
print("Music file ID:", musicFile);
-- Example output: "Music file ID: 53183"
```

#### `LibRPMedia:GetMusicFileByName(musicName)`

Returns the file ID associated with a given name or file path.

If using a file name, this will usually match that of a soundkit name as present within the internal client databases, eg. `zone-cursedlandfelwoodfurbolg_1`.

If using a file path, the database only includes entries for files within the `sound/music` directory tree. The file path should omit the `sound/music/` prefix, as well as the file extension (`.mp3`).

If no music file is found with the given name or path, `nil` is returned.

##### Usage

```lua
PlaySoundFile(LibRPMedia:GetMusicFileByName("zone-cursedlandfelwoodfurbolg_1"), "Music");
```

#### `LibRPMedia:GetMusicFileByIndex(musicIndex)`

Returns the file ID associated with the given numeric index inside the database, in the range of 1 through the result of `LibRPMedia:GetNumMusicFiles()`. Queries outside of this range will return `nil`.

##### Usage

```lua
PlaySoundFile(LibRPMedia:GetMusicFileByIndex(42), "Music");
```

#### `LibRPMedia:GetMusicFileDuration(musicFile)`

Returns the duration of a music file by its file ID. The value returned will be in fractional seconds, if present in the database.

If no duration information is found for the referenced file, `0` is returned.

##### Usage

```lua
local file = LibRPMedia:GetMusicFileByName("citymusic/darnassus/darnassus intro");
print("File duration (seconds):", LibRPMedia:GetMusicFileDuration(file));
-- Example output: "File duration (seconds): 39.923125"
```

#### `LibRPMedia:GetNativeMusicFile(musicFile)`

Returns a native music file value for a given music file ID that that can be supplied to in-game APIs such as PlayMusic and PlaySoundFile. The type of the returned value is unspecified; the only guarantees are that it may be used with in-game APIs and is convertible to a string.

If the given music file ID is not present within the database, `nil` is returned.

##### Usage

```lua
print("Native file:", LibRPMedia:GetNativeMusicFile(53600));
-- Example output (retail): "Native file: 53600"
-- Example output (classic): "Native file: Sound\Music\zonemusic\naxxramas\naxxramashubbasel.mp3"
```

#### `LibRPMedia:GetMusicIndexByFile(musicFile)`

Returns the music index associated with the given file ID inside the database.

If no matching file ID is found, `nil` is returned.

The index returned by this function is not guaranteed to remain stable between upgrades to this library.

##### Usage

```lua
print("Music index (by file):", LibRPMedia:GetMusicIndexByFile(53183));
-- Example output: "Music index (by file): 1"
```

#### `LibRPMedia:GetMusicIndexByName(musicName)`

Returns the music index associated with the given music name inside the database.

Music files may be associated with multiple names, and this function will search against all of them. If no matching name is found, `nil` is returned.

The index returned by this function is not guaranteed to remain stable between upgrades to this library.

##### Usage

```lua
print("Music index (by name):", LibRPMedia:GetMusicIndexByName("citymusic/darnassus/darnassus intro"));
-- Example output: "Music index (by name): 1"
```

#### `LibRPMedia:GetMusicNameByIndex(musicIndex)`

Returns the music name associated with the given numeric index inside the database, in the range of 1 through the result of `LibRPMedia:GetNumMusicFiles()`. Queries outside of this range will return `nil`.

Music files may be associated with multiple names, however only one name will ever be returned by this function. The name returned by this function is not guaranteed to remain stable between upgrades to this library.

##### Usage

```lua
print("Music name (by index):", LibRPMedia:GetMusicNameByIndex(1));
-- Example output: "Music name (by index): citymusic/darnassus/darnassus intro"
```

#### `LibRPMedia:GetMusicNameByFile(musicFile)`

Returns the music name associated with the given file ID inside the database.

Music files may be associated with multiple names, however only one name will ever be returned by this function. The name returned by this function is not guaranteed to remain stable between upgrades to this library. If no matching name is found, `nil` is returned.

##### Usage

```lua
print("Music name (by file):", LibRPMedia:GetMusicNameByFile(53183));
-- Example output: "Music name (by file): citymusic/darnassus/darnassus intro"
```

#### `LibRPMedia:FindMusicFiles(musicName[, options])`

Returns an iterator for accessing the contents of the music database for music files matching the given name. The iterator will return a triplet of the music index, file ID, and music name on each successive call, or `nil` at the end of the database.

Music files may be associated with multiple names, and this function will search against all of them. The music index and name yielded by this iterator is not guaranteed to remain stable between upgrades to this library.

The order of files returned by this iterator is not stable between upgrades to this library.

##### Usage

```lua
-- Prefix searching (default):
for index, file, name in LibRPMedia:FindMusicFiles("citymusic/") do
    print("Found music file:", name, file);
    -- Example output: "Found music file: citymusic/darnassus/darnassus intro, 53183"
end

-- Substring matching:
for index, file, name in LibRPMedia:FindMusicFiles("mus_50", { method = "substring" }) do
    print("Found music file:", name, file);
    -- Example output: "Found music file: mus_50_augustcelestials_01, 642565"
end

-- Pattern matching:
for index, file, name in LibRPMedia:FindMusicFiles("^mus_[78]", { method = "pattern" }) do
    print("Found music file:", name, file);
    -- Example output: "Found music file: mus_70_artif_brokenshore_battewalk_01, 1506788"
end
```

#### `LibRPMedia:FindAllMusicFiles()`

Returns an iterator for accessing the contents of the music database. The iterator will return a triplet of the music index, file ID, and music name on each successive call, or `nil` at the end of the database.

The music index and name yielded by this iterator is not guaranteed to remain stable between upgrades to this library.

The order of files returned by this iterator is not stable between upgrades to this library.

##### Usage

```lua
for index, file, name in LibRPMedia:FindAllMusicFiles() do
    print("Found music file:", name, file);
    -- Example output: "Found music file: citymusic/darnassus/darnassus intro, 53183"
end
```

### Icon API

#### `LibRPMedia:IsIconDataLoaded()`

Returns `true` if the icon database has been loaded. If this returns `false`, most other Icon API functions will raise errors.

##### Usage

```lua
print("Is icon data loaded?", LibRPMedia:IsIconDataLoaded());
-- Example output: "Is icon data loaded? true"
```

#### `LibRPMedia:GetNumIcons()`

Returns the number of icons present within the database.

##### Usage

```lua
print("Number of icons:", LibRPMedia:GetNumIcons());
-- Example output: "Number of icons: 20974"
```

#### `LibRPMedia:GetIconDataByName(iconName[, target])`

Returns data about an icon identified by its name.

An optional second parameter (target) may be specified to control the type of data yielded by the query:

* If a string is given, it must correspond to a field in the database, and will return the value associated with this icon for that field. Invalid field lookups will return `nil`.
* If a table is given, all fields are collected into the given table and returned. The contents of the table are not wiped.
* If nil is given, a table is created automatically, and all fields will be collected into it and returned.

If the requested icon is not found within the database, `nil` is returned for all query types.

##### Usage

```lua
local iconData = LibRPMedia:GetIconDataByName("ability-ambush");
local iconName = LibRPMedia:GetIconDataByName("ability-ambush", "name");

assert(iconData.name == iconName);
print("Icon name:", iconName);
-- Example output: "Icon name: ability-ambush"
```

#### `LibRPMedia:GetIconDataByIndex(iconIndex[, target])`

Returns data about an icon identified by its numeric index inside the database, in the range of 1 through the result of `LibRPMedia:GetNumIcons()`.

An optional second parameter (target) may be specified to control the type of data yielded by the query:

* If a string is given, it must correspond to a field in the database, and will return the value associated with this icon for that field. Invalid field lookups will return `nil`.
* If a table is given, all fields are collected into the given table and returned. The contents of the table are not wiped.
* If nil is given, a table is created automatically, and all fields will be collected into it and returned.

If the requested icon is not found within the database, `nil` is returned for all query types.

##### Usage

```lua
local iconData = LibRPMedia:GetIconDataByIndex(1);
local iconName = LibRPMedia:GetIconDataByIndex(1, "name");

assert(iconData.name == iconName);
print("Icon name:", iconName);
-- Example output: "Icon name: ability-ambush"
```

#### `LibRPMedia:GetIconNameByIndex(iconIndex)`

Returns the name of an icon by its given index within the database, in the range of 1 through the result of `LibRPMedia:GetNumIcons()`. Queries outside of this range will return `nil`.

Icon indices are not stable and may result in different data being returned between upgrades to the library. It is recommended to persist icons via their name and instead query via the `GetIcon<X>ByName` functions where possible.

##### Usage

```lua
print("Icon Name #1:", LibRPMedia:GetIconNameByIndex(1));
-- Example output: "Icon Name #1: ability_ambush"
```

#### `LibRPMedia:GetIconFileByIndex(iconIndex)`

Returns the file ID of an icon by its given index within the database, in the range of 1 through the result of `LibRPMedia:GetNumIcons()`. Queries outside of this range will return `nil`.

Icon indices are not stable and may result in different data being returned between upgrades to the library. It is recommended to persist icons via their name and instead query via the `GetIcon<X>ByName` functions where possible.

##### Usage

```lua
print("Icon File ID #1:", LibRPMedia:GetIconFileByIndex(1));
-- Example output: "Icon File ID #1: 1044087"
```

#### `LibRPMedia:GetIconTypeByIndex(iconIndex)`

Returns the type of an icon by its given index within the database, in the range of 1 through the result of `LibRPMedia:GetNumIcons()`. Queries outside of this range will return `nil`, otherwise a value present in the `LibRPMedia.IconType` enumeration is returned.

Icon indices are not stable and may result in different data being returned between upgrades to the library. It is recommended to persist icons via their name and instead query via the `GetIcon<X>ByName` functions where possible.

##### Usage

```lua
print("Icon Type #1:", LibRPMedia:GetIconTypeByIndex(1));
-- Example output: "Icon Type #1: 1"
```

#### `LibRPMedia:GetIconFileByName(iconName)`

Returns the file ID of an icon keyed by its name within the database. If the given icon name cannot be found `nil` is returned.

##### Usage

```lua
print("Icon File ID:", LibRPMedia:GetIconFileByName("raceicon-dwarf-female"));
-- Example output: "Icon File ID: 1662186"
```

#### `LibRPMedia:GetIconTypeByName(iconName)`

Returns the type of an icon keyed by its name within the database. If the given icon name cannot be found `nil` is returned, otherwise a value present in the `LibRPMedia.IconType` enumeration is returned.

##### Usage

```lua
print("Icon Type:", LibRPMedia:GetIconTypeByName("raceicon-dwarf-female"));
-- Example output: "Icon Type: 2"
```

#### `LibRPMedia:GetIconIndexByName(iconName)`

Returns the index of an icon keyed by its name within the database. If the given icon name cannot be found `nil` is returned, otherwise an index integer is returned within the range 1 through `LibRPMedia:GetNumIcons()`.

Icon indices are not stable and may result in different data being returned between upgrades to the library. It is recommended to persist icons via their name and instead query via the `GetIcon<X>ByName` functions where possible.

##### Usage

```lua
print("Icon Index:", LibRPMedia:GetIconIndexByName("ability-ambush"));
-- Example output: "Icon Index: 1"
```

#### `LibRPMedia:FindIcons(iconName[, options])`

Returns an iterator for accessing the contents of the icon database for icons matching the given name. The iterator will return a pair of the icon index and icon name on each successive call, or `nil` at the end of the database.

Icon indices are not stable and may result in different data being returned between upgrades to the library.

The order of files returned by this iterator is not stable between upgrades to this library.

##### Usage

```lua
-- Prefix searching (default):
for index, name in LibRPMedia:FindIcons("ability_") do
    print("Found icon:", name);
    -- Example output: "Found icon: ability_ambush"
end

-- Substring matching:
for index, name in LibRPMedia:FindIcons("hunter", { method = "substring" }) do
    print("Found icon:", name);
    -- Example output: "Found icon: ability_hunter_swiftstrike"
end

-- Pattern matching:
for index, name in LibRPMedia:FindIcons("^inv_mace_%d+", { method = "pattern" }) do
    print("Found icon:", name);
    -- Example output: "Found icon: inv_mace_01"
end
```

#### `LibRPMedia:FindAllIcons()`

Returns an iterator for accessing the contents of the icon database. The iterator will return a pair of the icon index and icon name on each successive call, or `nil` at the end of the database.

Icon indices are not stable and may result in different data being returned between upgrades to the library.

The order of files returned by this iterator is not stable between upgrades to this library.

##### Usage

```lua
for index, name in LibRPMedia:FindAllIcons() do
    print("Found icon:", name);
    -- Example output: "Found icon: ability_ambush"
end
```

## Building

The included Makefile will execute the exporter script to generate the databases, and update the manifest files. The exporter script has the following dependencies:

* [csv](https://luarocks.org/modules/geoffleyland/csv)
* [etlua](https://luarocks.org/modules/leafo/etlua)
* [LuaBitOp](https://luarocks.org/modules/luarocks/luabitop)
* [luafilesystem](https://luarocks.org/modules/hisham/luafilesystem)
* [luasocket](https://luarocks.org/modules/luasocket/luasocket)
* [lzlib](https://luarocks.org/modules/hisham/lzlib)
* [md5](https://luarocks.org/modules/tomasguisasola/md5)
* [penlight](https://luarocks.org/modules/steved/penlight)

In addition, you must ensure that [cURL](https://curl.haxx.se/) and [ffmpeg](https://ffmpeg.org/) are locally installed.

The exporter script makes use of [LuaCasc](https://www.townlong-yak.com/casc/) which is included in the repository (`Exporter/casc`).

Running `make` will regenerate the data for both Classic and Retail versions of the game, downloading data from the CDN and various external services and caching them the `.cache` directory. The generated databases will be stored within the `LibRPMedia-{Classic,BCC,Retail}-1.0.lua` files.

## License

The library is released under the terms of the [Unlicense](https://unlicense.org/), a copy of which can be found in the `LICENSE` document at the root of the repository.

Basically, you're completely free to use it and don't need to worry about crediting us.

## Contributors

* [Daniel "Meorawr" Yates](https://github.com/meorawr)
