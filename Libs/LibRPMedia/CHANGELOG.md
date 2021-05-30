# LibRPMedia-1.0

## [v1.1.6](https://github.com/wow-rp-addons/LibRPMedia/tree/v1.1.6) (2020-11-17)
[Full Changelog](https://github.com/wow-rp-addons/LibRPMedia/commits/v1.1.6) [Previous Releases](https://github.com/wow-rp-addons/LibRPMedia/releases)

- Fix automated changelogs for packaged releases  
- Update TOC and library versions  
- CI Improvements (#43)  
    Refactored github action usage to bring them into line with more recent developments; preferring for example  
    the actions now available for luacheck/editorconfig/packaging.  
    Removed embedded tests as these weren't adding much aside from a sanity check, which the UI is good  
    for anyway.  
- Update databases for patch 9.0.2 (#45)  
    Adds 613 new icons and 1437 new musics for Retail, as well as 9 new icons for Classic.  
- Fix uses of CallbackRegistryMixin (#44)  
    This was adjusted heavily in 9.0; for now it'll only work there though but that shouldn't be a huge issue.  
- Change load behaviour to always pull in embeds (#41)  
    The documented behaviour for embedded dependencies was that the addon pulling in the library should manually load them so that our dependencies can be omitted in packaged builds.  
    However this can prove somewhat inconvenient and a bit of a trap since the "expected" behaviour is that pulling in the library should generally just work.  
- Prefer use of CallMethodOnNearestAncestor (#42)  
    This makes things a bit less brittle if frame ownership ever needs juggling around.  
- Release v1.1.5 (#40)  
    * Regenerate Classic database for 1.13.4.34835 with 2 added icons.  
    * Regenerate Retail database for 8.3.0.34769 wit 17 added music files.  
- Swap to using GitHub Actions for CI (#39)  
- Release: v1.1.4 (#38)  
    * Regenerated database for patch 8.3 with 223 added icons and 61 added music files.  
    * Regenerated database for patch 1.13.3 with 1 added icon.  
- Bump TOC for patch 8.2.5 (#36)  
- Regenerate database for patch 8.2.5 (#35)  
- Add icon file ID support (#34)  
- Update changelog for v1.1.1  
- Add GetDataBy<X> API functions (#33)  
- Release: v1.1.0  (#32)  
    Closes #10, closes #31.  
    * Added Icon API as documented in the available README.  
    * Added `LibRPMedia:GetNativeMusicFile(musicFile)` to assist with Classic compatibility, as APIs on the Classic client don't support file IDs.  
    * Improved efficiency of data at-rest; on Retail clients the library uses ~700 KB on startup until databases are accessed.  
    * Various exporter and backend changes.  
- 1.0.0 Code Cleanup (#30)  
    * Remove pointless nil check  
    With the type assertions, we no longer need to guard against a  
    nil musicName when searching for music files.  
    * Minor optimization to base64 decoding  
    For compressed data, string.char can accept multiple arguments  
    and will return a joined string automatically in that case.  
    * Minor version bump  
    * Clarify dependencies in README  
    * Improve .release directory creation  
    Add an explicit target for the release directory to make it only  
    if required, rather than using platform-specific "mkdir -p" stuff.  
    * Clarify building in README  
    * Regenerate data against v1.1.0 exporter  
    No changes to the actual data are present, but this provides us  
    with a human-readable manifest for each database so changes can  
    be diffed more reasonably in the future.  
    * Reorder music tests  
    Check database load/size before API typechecks.  
    We'll also dump the size as a debugging aid.  
    * Update changelog  
- Ensure check/test failures prevent deployment (#29)  
- Add unit tests (#28)  
    The tests provided exercise all the documented guarantees of each  
    public API function, ranging from input argument typechecks to  
    output value guarantees. We also check the consistency of the  
    databases and validate that all lookups work as expected.  
- Strip LibDeflate directories from packager (#25)  
- Release v1.0.0 (#23)  
    Bumped minor version to 2, updated changelog. Changes:  
    * Allow retail data to load on 8.1+ (#13)  
    * Correctly yield matched name from FindMusicFiles (#15)  
    * Add support for querying file duration (#14)  
    * Add typechecks to public API functions (#19)  
    * Implement advanced music search and new exporter (#20)  
    * Add support for compressed data (#21)  
    This version will be tagged tomorrow assuming no bugs crop up.  
- Add Travis configuration (#5)  
    * Ignore generated files from linting  
    * Add packager metadata to TOC  
    * Remove build dependency from release target  
    We'll make it package whatever is in the repo, rather than  
    potentially change things before packaging.  
    * Add more exceptions to Luacheck  
    * Add Travis configuration  
    Runs luacheck on all commits (with our new exclusions), and  
    should package releases when tagged commits are pushed to master.  
    * Update changelog  
    * Minor comment spacing fix  
    * Simplify release packaging process  
    Don't bother with classic/retail differences until things are  
    fleshed out more. We'll report 8.2 compatibility but work on  
    1.13 regardless.  
- Music API Expansions (#4)  
    * Add LibRPMedia:CreateHydratedTable()  
    Allows creation of a table that lazily loads its contents.  
    * Change database export structure  
    Reworked the template module to not bother with replacements, and  
    instead allow code to just write to streams themselves with a fixed  
    header and footer.  
    The music database now emits lazily loaded data for its search index,  
    which additionally no longer uses a radix tree more testing with  
    memory shows that our dataset is marginally smaller with just a  
    binary-search based approach, and with a lot less code required.  
    * Add new search and data functions to Music API  
    These new functions provide ways to convert data in all directions,  
    eg. getting the name of a music piece from its file ID, getting an  
    index of a music piece from its name, etc.  
    Additionally, search is now implemented via FindMusicFiles.  
    Some APIs were renamed as we're not yet beholden to compatibility  
    concerns to better fit the naming scheme:  
    GetMusicFile => GetMusicFileByName  
    IterMusicFiles => FindAllMusicFiles  
    All code relating to the radix tree search was removed, and the  
    data access updated to match the new export format.  
    * Regenerate data to meet new structure  
- Regenerate data to fix classic TOC issue  
- Fix typo in classic TOC  
- Remove Libs exclusion from packager  
    Expectation was it would have applied to the source tree, but it  
    also applied to the checked out libraries.  
    The packager copes fine with replacing the embedded LibStub that  
    we provide with the checked out version.  
- Restore manual checkout of LibStub  
    Just to make testing less complicated if you want to bypass  
    the packager step. You can just clone and run!  
- Manually specify correct interface versions  
    The packager doesn't do this automatically because it's a spiteful  
    little piece of...  
- Add building section to README  
- Regenerate against 8.2.0.30669 data (wowt)  
- Include versioning metadata in templates  
- Fix product name targets in Makefile  
- Remove unused import  
- Change usage of packager filter comments  
    Don't use them in XML since the retail/non-retail check didn't  
    unwrap as I'd hoped. As we want the library to work straight  
    from a git checkout, the XML files will not filter their files.  
    The TOC will reference the files individually and apply exclusions  
    there, since they work as intended it seems.  
- Initial commit of library code  
    The Makefile generates the database files from the exporter script,  
    which are loaded from the XML files. There's some experimental  
    .pkgmeta stuff in use, which is likely about to be changed.  
- Initial commit of the exporter (and templates)  
    The exporter script will generate databases for use by the library  
    from external sources; eg. downloading CSVs from external APIs  
    and parsing them in ways it needs.  
    Each part of the exporter is its own script, the main part being  
    the Exporter.lua script which combines the modules together.  
    The exporter will dump its generated databases to stdout.  
- Initial commit  
