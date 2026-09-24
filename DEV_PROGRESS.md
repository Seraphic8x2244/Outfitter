# Development Progress

> Live project-development context for a fresh chat. Keep this current and concise. Remove or compress superseded detail once it no longer affects future work.

## Current
- Repository: `Seraphic8x2244/Outfitter`
- Branch: `dev`
- Version: `0.1.0-dev`
- Development/handoff head: the commit containing this file; verify the remote `dev` head before editing.
- Pre-centralization branch head: `9088afb9544cdcb4791a5ae61b69e4b407ff975f`
- Current runtime/code head: `20879e99be476e03ebcbb7cab6f861a006af1624`
- Main baseline: `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` — repository scaffold only, not a runnable addon release.
- Stable baseline/release: None in this repository.
- Upstream runtime baseline: CosminPOP/Outfitter `4587638ae5bd10eb9bc83bbae87a092e4b892d94`
- ClassicAPI research reference: brues-code/ClassicAPI `fde3beca9dba18e7327802eb094b5bff81f39d47`
- Goal: incrementally modernize Outfitter for WoW 1.12.1 using ClassicAPI while preserving the features and data model that make Outfitter distinct.
- Current scope boundary: runtime-test P1 only. Do not begin P2 or change physical equipment execution until P1 passes in-game.

## Current Design / Development Contract

### Product Identity / Scope
- Preserve Outfitter as Outfitter: named outfits, complete/partial/accessory outfits, automatic/situational outfits, priority/layering, keybinds, special outfits, and manual-change behaviour.
- Prefer incremental modernization over a rewrite.
- Preserve existing SavedVariables where practical.
- Do not turn Outfitter into ItemRack.
- Do not duplicate pfUI's flat Equipment Manager UI or make pfUI's Equipment Manager the product model.
- Target WoW 1.12.1 / Interface 11200 / Lua 5.0.
- ClassicAPI is an explicit project prerequisite and should be used directly where it materially improves correctness or implementation quality.
- pfUI compatibility is a first-class target. Turtle/Octo-style enhanced clients should be supported where practical without distorting the core design.

### Architecture / Ownership
- `gOutfitter_Settings.Outfits` remains the authoritative persisted outfit model.
- `gOutfitter_OutfitStack` remains the runtime layering/priority model.
- Compile the stack bottom-to-top: higher outfits override only the slots they define.
- Complete outfits clear the stack.
- Partial outfits replace the Partial and Accessory layers rather than flattening all active outfits.
- Temporary unnamed outfits preserve external/manual gear changes.
- Special outfits use the same stack and ownership path as ordinary outfits.
- Existing ordering semantics are product behaviour; for example Argent Dawn can sit below Riding so overlapping Riding slots temporarily win.
- Outfit bindings and automatic/situational activation remain Outfitter-owned features.
- The existing inventory reconciliation path, `Outfitter_InventoryChanged2`, is the current authoritative owner for observed equipment changes. New observation sources should route through it until a deliberate ownership change is made.
- ClassicAPI integration lives behind `OutfitterClassicAPI.lua`; avoid scattering extension checks through the legacy file.

### Protocol / Data Model
- Per-character SavedVariables remain rooted at `gOutfitter_Settings`.
- Existing saved outfit records remain compatible; P1 does not persist ClassicAPI GUIDs.
- ClassicAPI per-instance GUIDs are the intended future runtime identity for exact physical-item matching.
- `C_Item.GetItemGUID(itemLocation)` and `C_Item.GetItemLocation(itemGUID)` are the preferred exact identity/location primitives.
- `PLAYER_EQUIPMENT_CHANGED(equipmentSlot, hasCurrent)` is the preferred precise paperdoll observation signal.
- `C_EquipmentSet.*` is a GUID-backed flat-set facility, not Outfitter's authoritative outfit database.
- The `C_EquipmentSet` namespace is shared and user-visible through pfUI. Do not use it as hidden/private Outfitter storage.
- If Outfitter later saves ClassicAPI equipment sets, clear the process-global ignored-slot-for-save state before and after the operation.
- `EQUIPMENT_SWAP_PENDING` / `EQUIPMENT_SWAP_FINISHED` are candidate transaction boundaries only for operations actually performed through `C_EquipmentSet.UseEquipmentSet`.
- Prefer an Outfitter-owned execution adapter for compiled layered outfits rather than forcing layered state into one shared flat set.

### Legacy Behaviour to Preserve
- Named outfits and category semantics.
- Complete/partial/accessory outfit layering.
- Automatic/situational and special outfits.
- Keybindings.
- Temporary outfit/manual-change behaviour.
- Outfit stack priorities and overlap rules.
- SavedVariables compatibility.
- Existing Riding behaviour until a replacement is explicitly runtime-proven.

### Cosmin / Turtle Delta
- Cosmin's meaningful post-import runtime changes are confined to Riding detection.
- The fork progressively widened mount-buff tooltip matching for Turtle dynamic-speed mounts.
- The current upstream head recognizes generic `"Riding"` text and `"Slow and steady..."` in the mount buff tooltip.
- Preserve the resulting Turtle mount behaviour while replacing tooltip-text detection only when ClassicAPI supplies a stronger verified signal.
- The imported Cosmin baseline does not contain a general Swimming special outfit. Swimming is a target behaviour to design/restore explicitly, not an existing behaviour to claim as preserved.

### Legacy Mechanisms Targeted for Replacement
- Global replacement of `PaperDollItemSlotButton_OnClick`.
- Cursor-driven Outfitter swaps using `PickupInventoryItem`, `PickupContainerItem`, and `EquipCursorItem`.
- The hard-coded 1.5-second equipment throttle where a real transaction/completion boundary can replace it.
- The 0.25-second OnUpdate retry loop where event-driven completion can replace it.
- Broad inventory refresh work where precise equipment-change events are sufficient.
- Physical-item matching based only on legacy item-link fields where per-instance GUID identity is available.
- Hidden-tooltip parsing where ClassicAPI exposes the underlying fact directly.
- Do not remove tooltip/stat parsing wholesale: some smart-outfit/stat consumers may still require tooltip-derived data on 1.12.1 until a concrete replacement exists.

### pfUI Coexistence
- brues-code/pfUI contains a ClassicAPI-backed Equipment Manager using the same per-character `C_EquipmentSet` store.
- pfUI adds its own character-frame sidecar, ignored-slot overlays, and per-slot flyout buttons.
- pfUI listens to `EQUIPMENT_SETS_CHANGED`, `EQUIPMENT_SWAP_PENDING`, `EQUIPMENT_SWAP_FINISHED`, `BAG_UPDATE_DELAYED`, and `PLAYER_EQUIPMENT_CHANGED`.
- pfUI's set equip path calls `C_EquipmentSet.UseEquipmentSet`.
- pfUI's per-slot flyout still uses cursor pickup/drop for manual slot changes.
- No explicit Outfitter/ItemRack exclusion logic was found in the inspected pfUI module.
- Do not disable, replace, or mutate pfUI automatically.
- Treat pfUI, ItemRack, and manual swaps as external equipment changes unless an Outfitter-owned transaction proves otherwise.
- External changes should continue to become temporary Outfitter state rather than being immediately fought/reasserted.
- Avoid global paperdoll-function replacement. Future Outfitter QuickSlots integration should be additive and coexist with pfUI's popouts/overlays.
- Keep Outfitter's UI purpose distinct: outfit composition, layering, automatic state, and priorities—not another flat-set manager.

### User-Agency / Constraint Decisions
- Do not preserve arbitrary legacy throttles merely because they exist.
- Remove or change timing constraints only after focused runtime evidence establishes the real API/server dependency and a narrower correct boundary.
- Do not add hidden caps, forced workflows, or normalization for convenience.
- Preserve valid advanced/unusual outfit use when the underlying client can support it correctly.

### Active Implementation Decision: P1
P1 intentionally changes observation only, not physical swapping.

Implemented at runtime/code commit `20879e99be476e03ebcbb7cab6f861a006af1624`:
- Added `OutfitterClassicAPI.lua` as the ClassicAPI boundary.
- Added ClassicAPI availability/event-capability checks.
- Added exact GUID helpers for equipment and bag item locations.
- Added GUID-to-location reverse lookup.
- Registered `PLAYER_EQUIPMENT_CHANGED` when available.
- Routed that event into existing `Outfitter_InventoryChanged2`.
- Kept legacy `UNIT_INVENTORY_CHANGED` during P1 as fallback/parallel observation.
- Did not change cursor swapping, stack compilation, automatic outfits, SavedVariables, Riding detection, or paperdoll hooks.

## Recent Relevant Commits
- `20879e99be476e03ebcbb7cab6f861a006af1624` — P1 ClassicAPI equipment observation/identity bridge; runtime delta awaiting user test.
- `588f52f401a53061e546a3ef8aaeb860de546bcb` — created the initial live handoff/status document.
- `c92a11796e8decb4c43b79b205624e32ceb0ee59` — imported the complete Cosmin runtime baseline, required BLP artwork and `Bindings.xml`, development metadata, and initial workflow/design documentation.
- `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` — initial repository scaffold on `main`.

## Completed / User-Verified
- None. No runtime behaviour from this repository has yet been user-tested.

## Implemented / Awaiting Runtime Test
- Baseline runtime is imported from CosminPOP/Outfitter.
- Required addon-local BLP artwork is present.
- `Bindings.xml` is present; it is loaded by WoW convention outside the TOC list.
- `Outfitter.toc` owns the development version: `## Title: Outfitter-dev`, `## Version: 0.1.0-dev`.
- P1 ClassicAPI observation/identity bridge is implemented at `20879e99be476e03ebcbb7cab6f861a006af1624`.
- No modernization beyond P1 has been implemented.

## Static / Automated Checks
- Imported runtime Lua/XML/localization files were verified content-identical to Cosmin's inspected head blobs; project metadata/docs are the intentional differences.
- XML addon-local texture references were checked and the required BLP assets imported.
- `Bindings.xml` was verified upstream and imported.
- Legacy outfit stack, equipment update path, paperdoll hook, tooltip parsing, cursor swap path, and timer/throttle path were inspected.
- ClassicAPI equipment-set, item GUID/location, explicit equipment-swap, and equipment-change event facilities were inspected.
- pfUI's ClassicAPI Equipment Manager and paperdoll flyout module were inspected.
- P1 diff review confirmed the runtime delta is limited to `OutfitterClassicAPI.lua`, its TOC entry, and small event registration/callback insertions in `Outfitter.lua`.
- P1 adds no new top-level locals to the large legacy `Outfitter.lua`; the adapter is separate to avoid worsening Lua 5.0 top-level local pressure.
- No static inspection is being counted as an in-game test.

## Current Issues
- P1 has not yet been runtime-tested.
- Legacy Outfitter globally replaces `PaperDollItemSlotButton_OnClick`, creating a future coexistence risk with pfUI and other paperdoll addons.
- Physical equipment execution remains cursor-driven.
- Legacy equipment updates still use the 1.5-second throttle and 0.25-second OnUpdate retry path.
- Aura/item facts are still often derived through hidden tooltips.
- Shared `C_EquipmentSet` state must not be used as hidden Outfitter storage.
- External pfUI/ItemRack/manual swaps must not be mistaken for Outfitter-owned transactions.
- Swimming requires an explicit design because it is absent from this imported baseline.

## Testing

### Last Runtime Test
- Version/commit: None
- Passed: None
- Failed: None
- Not tested: Entire imported baseline and P1 runtime delta in this repository.

### Next Runtime Test
Test exact runtime/code commit `20879e99be476e03ebcbb7cab6f861a006af1624` on WoW 1.12.1 with ClassicAPI, preferably with brues-code/pfUI present:

1. Login/reload with no Lua errors.
2. Open Outfitter and verify the imported baseline UI still works.
3. Manually equip and unequip several equipment slots; verify Outfitter reconciles the changes.
4. Repeat manual slot changes through pfUI's Equipment Manager/flyouts.
5. Verify externally initiated gear changes are accepted as manual/temporary state rather than immediately reasserted by Outfitter.
6. Exercise existing named, partial, and special outfits and verify they still use the unchanged legacy executor.
7. Verify SavedVariables remain compatible and no unexpected schema mutation occurs.
8. Report any duplicate-event/reconciliation symptoms caused by keeping both `UNIT_INVENTORY_CHANGED` and `PLAYER_EQUIPMENT_CHANGED` during P1.

## Planned / Next Work
- **P0 — baseline/workflow:** complete.
- **P1 — ClassicAPI observation bridge:** implemented; runtime validation pending.
- **P2 — item identity modernization:** augment runtime item records with ClassicAPI GUID identity and prefer exact GUID matching while preserving legacy SavedVariables migration/fallback matching.
- **P3 — cursor-free executor:** replace Outfitter-controlled cursor swaps with ClassicAPI exact-item/explicit-slot swapping; introduce Outfitter transaction ownership; remove legacy timing constraints only after runtime evidence proves the replacement boundary.
- **P4 — automatic-state modernization:** replace tooltip parsing/broad polling for Riding, auras, forms, Swimming, and similar states only where a verified ClassicAPI fact exists; preserve fallback where needed.
- **P5 — paperdoll/pfUI coexistence:** remove the global `PaperDollItemSlotButton_OnClick` replacement and preserve QuickSlots via additive integration; test pfUI Equipment Manager enabled and disabled.
- **P6 — optional C_EquipmentSet interoperability:** only after Outfitter's model/executor are stable, decide whether named Outfitter outfits should explicitly import/export/mirror user-visible ClassicAPI sets.
- **P7 — cleanup:** remove obsolete cursor/timer/polling/tooltip paths only after their replacements are runtime-proven.

## Deferred / Out of Scope
Until P1 passes, do not:
- Begin P2.
- Change the physical equipment swap executor.
- Remove or retune the 1.5-second throttle.
- Persist GUIDs into the existing SavedVariables schema.
- Migrate or silently mirror outfits into `C_EquipmentSet`.
- Change automatic/special outfit semantics.
- Change Riding detection.
- Add Swimming.
- Remove the paperdoll hook.
- Redesign the Outfitter UI.

Longer-term non-goals:
- Rewriting Outfitter from scratch.
- Replacing Outfitter with ItemRack-like semantics.
- Duplicating pfUI's flat Equipment Manager as Outfitter's primary product.

## Release / Promotion Notes
- Main-only or release-only content to preserve: `main` currently contains only the original scaffold README; it is not a stable addon tree.
- Known validation debt accepted for release: None; no release has been authorized.
- External/runtime prerequisites: WoW 1.12.1 and ClassicAPI. pfUI is a compatibility target but not Outfitter's state owner.
- No stable release exists yet.
- Before first promotion, compare `dev` and `main`, remove development-only status material, apply stable TOC metadata, and preserve only intentional main/release content.

## Exact Next Step
Runtime-test exact runtime/code commit `20879e99be476e03ebcbb7cab6f861a006af1624` using the checklist above. Record the exact results here. Do not begin P2 or change the physical equipment executor until that test passes.
