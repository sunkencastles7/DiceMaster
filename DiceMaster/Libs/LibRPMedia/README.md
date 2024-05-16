# LibRPMedia

LibRPMedia provides a common database of in-game resources for use by RP addons.

## Dependencies

The following libraries must be loaded into the environment by addons prior to loading LibRPMedia. The library does not hard-embed or attempt to load these dependencies itself.

- [LibStub](https://www.curseforge.com/wow/addons/libstub)

## Embedding

The library may be imported as an external in a `.pkgmeta` file as shown below, through the use of a Git submodule, or by downloading an existing packaged release and copying it into your addon folder.

```yaml
externals:
  Libs/LibRPMedia: https://github.com/wow-rp-addons/LibRPMedia
```

To load the library include a reference to the `lib.xml` file either within your TOC or through an XML Include element.

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <Include file="Libs\LibRPMedia\lib.xml"/>
</Ui>
```

## License

The library is released under the terms of the [Unlicense](https://unlicense.org/), a copy of which can be found in the `LICENSE` document at the root of the repository.

## Contributors

* [Daniel "Meorawr" Yates](https://github.com/meorawr)
