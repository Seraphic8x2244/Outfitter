# Development Progress

## Current state

- Repository: `Seraphic8x2244/Outfitter`
- Current branch: `dev`
- Current dev version: `0.1.0-dev`
- Current runtime/code head: `20879e99be476e03ebcbb7cab6f861a006af1624`
- Main baseline: `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` (repository scaffold only; not a runnable addon release)
- Latest stable release in this repository: none yet
- Upstream runtime reference: CosminPOP/Outfitter `4587638ae5bd10eb9bc83bbae87a092e4b892d94`
- Workflow authority: `dev_rulebook.md`
- Project contract: `MODERNIZATION.md`

Git commits cannot self-reference their own SHA inside the file they contain. Treat the
commit containing this status file as the handoff/status head and verify that its
runtime tree is a documentation-only successor of the exact runtime/code head above
before editing.

## Current goal

Runtime-validate P1 from `MODERNIZATION.md`. The ClassicAPI observation/identity
bridge is implemented at `20879e99be476e03ebcbb7cab6f861a006af1624`; do not begin
P2 until this exact runtime slice passes in-game.

## Recent relevant commits

- `20879e99be476e03ebcbb7cab6f861a006af1624` — added `OutfitterClassicAPI.lua`,
  exact GUID/location helpers, and `PLAYER_EQUIPMENT_CHANGED` routed into the
  existing inventory-reconciliation owner. Physical swap semantics are unchanged.
- `c92a11796e8decb4c43b79b205624e32ceb0ee59` — imported the complete Cosmin runtime
  baseline and required artwork/bindings, added development Title/Version metadata,
  copied the authoritative rulebook, and added the modernization contract.
- `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` — initial repository scaffold on
  `main`.

## Completed and user-verified

None. No runtime behaviour from this repository has been user-tested yet.

## Implemented but untested

P1 is implemented at `20879e99be476e03ebcbb7cab6f861a006af1624`:

- Added `OutfitterClassicAPI.lua` as the narrow extension boundary.
- Added ClassicAPI availability/event-capability checks.
- Added exact `C_Item.GetItemGUID` helpers for equipment and bag locations.
- Added `C_Item.GetItemLocation` reverse lookup.
- Registered `PLAYER_EQUIPMENT_CHANGED` when ClassicAPI reports the event.
- Routed that event into the existing `Outfitter_InventoryChanged2` state owner.
- Kept `UNIT_INVENTORY_CHANGED` during P1 as the legacy/fallback signal.
- Left all physical equipment execution, stack semantics, SavedVariables and special
  outfit behaviour unchanged.

Baseline/setup is also complete: Cosmin runtime/assets and `Bindings.xml` are
imported, `Outfitter.toc` owns `0.1.0-dev`, and the workflow/design docs are in
place.

## Static/inspection checks completed

- Verified the imported runtime Lua/XML/localization files are content-identical to
  Cosmin's head blobs; only project metadata/documentation differs.
- Verified the XML references addon-local BLP textures and included those assets.
- Verified `Bindings.xml` exists upstream and included it because WoW loads it by
  convention outside the TOC list.
- Inspected the legacy outfit stack, equipment update path, paperdoll hook, tooltip
  parsing, cursor swap path and timer/throttle path.
- Inspected ClassicAPI equipment-set, item GUID/location, explicit equipment swap
  and equipment-change event facilities.
- Inspected pfUI's ClassicAPI Equipment Manager and paperdoll flyouts.
- Reviewed the P1 commit diff: only `OutfitterClassicAPI.lua`, `Outfitter.toc`, and
  the two small observation insertions in `Outfitter.lua` changed.
- Verified P1 adds no new top-level locals to the large legacy `Outfitter.lua`; the
  adapter is a separate file to avoid increasing Lua 5.0 local-pressure in that chunk.

## Current issues / risks

- Legacy Outfitter globally replaces `PaperDollItemSlotButton_OnClick`; pfUI also
  attaches equipment-manager controls to paperdoll slots.
- Legacy equipment execution is cursor-driven.
- Equipment updates are throttled to 1.5 seconds and retried through a 0.25-second
  OnUpdate timer.
- Aura/item facts are often obtained through hidden tooltip parsing.
- The pfUI Equipment Manager exposes the shared per-character
  `C_EquipmentSet` namespace, so Outfitter must not use that namespace as hidden
  private storage.
- pfUI's flyouts and other equipment addons must be treated as external/manual gear
  changes unless an Outfitter transaction owns the change.
- The imported Cosmin baseline does not contain a general Swimming special outfit;
  Swimming is a target behaviour to design/restore explicitly rather than an
  already-present feature to preserve verbatim.

## Last runtime test

None for this repository/version.

## Next runtime test

Test exact runtime commit `20879e99be476e03ebcbb7cab6f861a006af1624` in WoW 1.12.1 with ClassicAPI:

- login/reload with no Lua errors;
- Outfitter opens and existing baseline UI still functions;
- manually equip/unequip several slots and verify Outfitter reconciles them;
- repeat manual swaps through pfUI's equipment flyout/Equipment Manager;
- verify no equipment is reasserted by Outfitter when the change is external;
- verify existing named/partial/special outfit selection still uses the unchanged
  legacy executor;
- verify SavedVariables remain compatible.

## Planned

- P1 ClassicAPI observation bridge.
- P2 exact GUID-backed runtime identity with SavedVariables compatibility.
- P3 cursor-free Outfitter executor and transaction ownership.
- P4 automatic-state modernization including Riding and an explicit Swimming design.
- P5 remove the global paperdoll function replacement and validate pfUI coexistence.
- P6 optional explicit C_EquipmentSet interoperability.
- P7 proven-path cleanup.

## Deferred / out of scope for the current slice

Do not start before the P1 runtime test:

- changing the physical equipment swap executor;
- removing the 1.5-second throttle;
- persisting GUIDs into the existing SavedVariables schema;
- migrating or mirroring outfits into `C_EquipmentSet`;
- changing automatic/special outfit semantics;
- redesigning the Outfitter UI;
- changing Riding detection;
- adding Swimming;
- removing the paperdoll hook.

## Exact next step

Runtime-test exact commit `20879e99be476e03ebcbb7cab6f861a006af1624` using the
checklist above. Record the result here. Do not begin P2 or change the equipment
executor until that test passes.
