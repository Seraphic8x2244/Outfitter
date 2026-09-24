# Development Progress

## Current state

- Repository: `Seraphic8x2244/Outfitter`
- Current branch: `dev`
- Current dev version: `0.1.0-dev`
- Current runtime/code head: `c92a11796e8decb4c43b79b205624e32ceb0ee59`
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

P1 from `MODERNIZATION.md`: add the smallest ClassicAPI observation/identity bridge
without changing physical outfit swap behaviour.

The first implementation slice is:

1. add `OutfitterClassicAPI.lua`;
2. expose exact item GUID/location helpers;
3. register `PLAYER_EQUIPMENT_CHANGED`;
4. feed that event into the existing inventory reconciliation path;
5. keep the legacy cursor equipment executor unchanged.

## Recent relevant commits

- `c92a11796e8decb4c43b79b205624e32ceb0ee59` — imported the complete Cosmin runtime
  baseline and required artwork/bindings, added development Title/Version metadata,
  copied the authoritative rulebook, and added the modernization contract.
- `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` — initial repository scaffold on
  `main`.

## Completed and user-verified

None. No runtime behaviour from this repository has been user-tested yet.

## Implemented but untested

Baseline/setup only:

- Cosmin runtime source and required BLP artwork imported.
- `Bindings.xml` imported.
- `Outfitter.toc` now supplies `## Title: Outfitter-dev` and
  `## Version: 0.1.0-dev`.
- `dev_rulebook.md` installed as the workflow authority.
- `MODERNIZATION.md` records the architecture findings, compatibility constraints,
  staged plan and first implementation slice.

No modernization code has been implemented yet.

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

After P1 is implemented, test the exact P1 commit in WoW 1.12.1 with ClassicAPI:

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

Implement P1 only: add a small ClassicAPI adapter plus
`PLAYER_EQUIPMENT_CHANGED` observation, route it through the existing inventory
reconciliation path, perform static review, update this file, and stop for runtime
testing before beginning P2 or changing the equipment executor.
