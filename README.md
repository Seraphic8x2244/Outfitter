# Outfitter

Outfitter is a Vanilla WoW 1.12.1 addon for creating, managing, and automatically switching between equipment sets.

This is an updated version of the original Outfitter addon, based on the [CosminPOP/Outfitter](https://github.com/CosminPOP/Outfitter) fork. The aim of this version is not to reinvent Outfitter, but to keep what made it useful while bringing some of its older internals up to date for modern 1.12.1 clients.

## Requirements

- [brues-code/ClassicAPI](https://github.com/brues-code/ClassicAPI)

## What it does

Outfitter lets you create named outfits and switch between them without having to manage every item manually.

It supports:

- Complete and partial outfits
- Accessory outfits
- Automatic outfits for things such as riding, forms, stances and other situations
- Outfit layering and priorities
- Keybinds for switching outfits
- Manual equipment changes without fighting the addon
- Quick equipment selection from the character window
- Importing existing ClassicAPI equipment sets into Outfitter

Imported equipment sets are copied into Outfitter rather than linked or synchronised with the original set.

## Modernisation

The original addon was written around the limitations and behaviour of the old Vanilla client APIs.

This fork uses [brues-code/ClassicAPI](https://github.com/brues-code/ClassicAPI) where it provides a cleaner or more reliable solution, particularly for item identity, equipment changes, equipment events, forms, auras and equipment-set interoperability.

A substantial amount of the original fallback behaviour is intentionally still present. Some equipment situations cannot yet be handled safely through the newer cursor-free paths, so Outfitter falls back to its established behaviour rather than risking incorrect item movement.

## Credits

Outfitter was originally designed and written by John Stephen.

This version builds on the work preserved in the CosminPOP fork and updates it for the current Vanilla 1.12.1 addon environment.
