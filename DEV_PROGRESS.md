# Development Progress

> Live project-development context for a fresh chat. Keep this current and concise. Remove or compress superseded detail once it no longer affects future work.

## Current
- Repository: `Seraphic8x2244/Outfitter`
- Branch: `dev`
- Version: `2.0.14-dev`
- Version-line decision: the 2.x line marks this fork as the ClassicAPI modernization of upstream Outfitter 1.4; patch `8` preserves the eight meaningful runtime/build states already reached before the line change. The accepted `0.1.1-dev` build remains recorded under its tested identity rather than being retroactively renamed.
- Development/handoff head: the commit containing this file; verify the remote `dev` head before editing.
- Pre-centralization branch head: `9088afb9544cdcb4791a5ae61b69e4b407ff975f`
- Current runtime/code head: `678c3edcc5536744776791cb8a969b75c6b74cc4`
- Main baseline: `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` — repository scaffold only, not a runnable addon release.
- Stable baseline/release: None in this repository.
- Upstream runtime baseline: CosminPOP/Outfitter `4587638ae5bd10eb9bc83bbae87a092e4b892d94`
- ClassicAPI research reference: brues-code/ClassicAPI `fde3beca9dba18e7327802eb094b5bff81f39d47`
- Goal: incrementally modernize Outfitter for WoW 1.12.1 using ClassicAPI while preserving the features and data model that make Outfitter distinct.
- Current scope boundary: P1 and P2 are user-accepted on WoW 1.12.1 with ClassicAPI/pfUI. P2 exact code head `2143a0cd29cc50a8e52d45040adacb299bf133cd` passed normal/rapid outfit swaps, manual equipment changes, pfUI character-slot flyout changes, reload persistence, and unchanged SavedVariables schema; bank-open, focused partial/special rechecks, and a true same-legacy-identity duplicate-instance case remain validation debt. P3 slice 1 is user-accepted on exact runtime/code head `026bd1164d817dd6e4775f76df40dd293b2492fa`, version `0.1.1-dev`: repeated one-slot enchanted/unenchanted glove swaps passed in both directions, multiple other outfit swaps passed, manual/character-screen changes remained external/manual, the preserved multi-slot executor remained healthy, and TOC-driven `0.1.1-dev` display was confirmed in the addon list and Outfitter character-screen UI. P3 slice 2 at `2.0.8-dev` was runtime-exercised and revealed a visible ~0.1s-per-slot cadence on sets entering the acknowledgement chain, while legacy-fallback sets remained near-instant. Re-review of ClassicAPI showed that this acknowledgement wait was over-conservative for the narrow all-normal-bag replacement case. The recommendation changed accordingly. Current `2.0.9-dev` runtime/code head `0e2ec6fbea2a4f0fda70dbdf13e3f9c98b4df3b9` removes that per-slot wait: it validates the whole direct list up front, confirms every GUID is still in its exact distinct normal-bag source slot, confirms distinct destination slots, then issues the atomic bag->paperdoll swaps back-to-back. User runtime testing reports the result is essentially immediate and feels like old Outfitter; occasional individual slots can visibly lag briefly, but every tested swap resolved to the correct final equipment with no issue. Slice 2 is accepted. Slice 3 at `2.0.10-dev`, runtime/code head `1c7accbfc4325486c48604e56ee19a51430ad712`, is user-accepted: exact reciprocal ring-slot swaps worked repeatedly in both outfit directions, the items were never observed entering bags, and manual plus config-editor swaps remained healthy. The direct path uses one atomic ClassicAPI paperdoll swap after both GUIDs are verified in the expected source slots. Slice 4 at `2.0.11-dev`, runtime/code head `9353beaa09498e318a1a174984cbdd270a18cea2`, is user-accepted: the exact three-change ring/trinket rotation produced by legacy optimization—synthetic empty target, equipped accessory moving across, then a normal-bag accessory replacing its old slot—worked in runtime testing. Physical executor modernization is intentionally stopped at the safe public-API boundary: explicit unequip has no public cursor-free equipped-slot -> chosen-bag-slot primitive, and multi-step weapon rotations can be affected by weapon-swap timing/GCD restrictions. Timing slice 1 in `2.0.13-dev` failed runtime testing. User observed a new ~0.1–0.2 second game hitch when swapping ordinary outfits and Birthday Suit, with other swaps also feeling laggier. The event-unlock timing experiment is therefore rejected. `2.0.14-dev`, runtime/code head `678c3edcc5536744776791cb8a969b75c6b74cc4`, cleanly restores the accepted `2.0.11-dev` runtime logic while advancing the version only. The original 1.5-second throttle and 0.25-second retry scheduler are fully restored for this rollback gate.

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
- Existing saved outfit records remain compatible; P2 keeps ClassicAPI GUIDs in a transient weak-key runtime side-map rather than adding fields to saved outfit tables.
- ClassicAPI per-instance GUIDs are now preferred for exact physical-item matching when present; legacy `Code` / `SubCode` / `EnchantCode` matching remains the fallback and hydrates runtime GUID identity after a successful legacy match.
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

P1 observation bridge was implemented at `20879e99be476e03ebcbb7cab6f861a006af1624`:
- Added `OutfitterClassicAPI.lua` as the ClassicAPI boundary.
- Added ClassicAPI availability/event-capability checks.
- Added exact GUID helpers for equipment and bag item locations.
- Added GUID-to-location reverse lookup.
- Registered `PLAYER_EQUIPMENT_CHANGED` when available.
- Routed that event into existing `Outfitter_InventoryChanged2`.
- Kept legacy `UNIT_INVENTORY_CHANGED` during P1 as fallback/parallel observation.

The first runtime test exposed a legacy first-use lifecycle failure. Runtime/code commit `24e4b557aa722ab46014cf5a7597f52d2104ddba` fixed that core P1-blocking initialization path:
- `Outfitter_Update` and the Outfitter UI toggle no longer enter settings-dependent paths before initialization completes.
- First-use initialization still accepts the legacy `PLAYER_ALIVE` trigger, but `BAG_UPDATE` or `UNIT_INVENTORY_CHANGED` may also establish inventory readiness if `PLAYER_ALIVE` is not delivered.
- Initial startup keeps those two readiness events registered; normal post-initialization zoning retains the legacy suspension behaviour.

A broader preflight hardening pass completed at `9e7f75634072600ec470fa00e21da84eeeb61526`:
- Normalizes missing `Options`, `LastOutfitStack`, `HideHelm`, `HideCloak`, and per-category outfit tables before migrations/UI/special-outfit code consumes them.
- Guards slash-command, binding, public outfit lookup, special-outfit lookup, list-item lookup, and add-outfit entry points against pre-initialization nil access.
- Keeps the minimap button hidden until initialization decides whether it should be shown, eliminating its pre-init drag/click state mutation window.
- Audited all 98 direct `gOutfitter_Settings` references; remaining unguarded accesses are owned by post-initialization UI/internal paths reached only after the lifecycle gate.
- No cursor swapping, stack compilation, automatic-outfit semantics, SavedVariables schema, Riding detection, or paperdoll hook behaviour was changed.

Rapid switching then exposed a separate legacy minimap-drag/timer invariant failure. Runtime/code head `dcc3f3572c201a568eb5471ebf52019fb42feefe`:
- Makes minimap drag-start initialize its own cursor/center origin instead of assuming `OnMouseDown` ran first.
- Uses `OutfitterMinimapButton:GetEffectiveScale()` explicitly rather than relying on the shared update frame's `this`.
- Clears drag origin state on drag end.
- Detects and cancels impossible stale drag state before any arithmetic, so the shared equipment update timer cannot repeatedly fault on nil coordinates.
- Does not alter equipment execution or outfit semantics.

### Active Implementation Decision: P2
P2 item-identity modernization is implemented at `2143a0cd29cc50a8e52d45040adacb299bf133cd`:
- Physical inventory/bag item records receive ClassicAPI per-instance GUIDs when the API can resolve them.
- Runtime GUID associations live in `OutfitterClassicAPI.lua` in a weak-key side-map; no GUID field was added to persisted outfit records or the SavedVariables schema.
- The equippable-item cache now indexes live physical items by GUID in addition to the legacy code/slot indexes.
- Matching prefers an exact GUID hit when both the outfit-side runtime identity and live item are available.
- Existing saved outfits and any location/API gaps continue through the original code/subcode/enchant fallback; a successful fallback match hydrates the outfit item's transient GUID for later exact matching in the same session.
- Inventory snapshots refresh runtime GUID identity even when the legacy item fields are unchanged, so same-link physical instances can be distinguished after they move during the session.
- The legacy ammo-slot name/texture fallback intentionally does not inherit the GUID of the bag stack used to identify it.
- ClassicAPI's reverse `C_Item.GetItemLocation(itemGUID)` helper was inspected but is not used to change equipment execution in P2; physical execution remains P3.
- The physical executor, 1.5-second throttle, Riding/special-outfit semantics, paperdoll hook, TOC version, and SavedVariables structure are unchanged.

### Active Implementation Decision: P3
P3 slice 1 was accepted on exact runtime/code head `026bd1164d817dd6e4775f76df40dd293b2492fa`, version `0.1.1-dev`.

P3 slice 2 was first implemented at `2.0.8-dev` with acknowledgement-driven one-at-a-time sequencing. User runtime testing showed that sets entering that path visibly equipped piece-by-piece at roughly ~0.1s per slot while legacy-fallback sets remained near-instant. That behavior was not present in original Outfitter and was traced to our own conservative wait, not an armor-specific rule.

After re-reading pinned ClassicAPI internals, the design changed for `2.0.9-dev` at runtime/code head `0e2ec6fbea2a4f0fda70dbdf13e3f9c98b4df3b9`:
- The direct multi-change path remains limited to two-or-more non-empty replacements whose source items are in normal bags and have transient ClassicAPI GUIDs.
- Before sending anything, the adapter verifies every runtime GUID still matches the exact recorded bag/slot, every source bag slot is distinct, and every destination equipment slot is distinct.
- Only after the full list passes validation are the atomic `C_Item.EquipItemByName(itemGUID, dstSlot)` calls issued back-to-back.
- This is safe for the current narrow bag->paperdoll case because each source is independent; an earlier swap only displaces the old equipped item into that incoming item's own vacated bag slot and does not relocate another future source.
- If any precondition fails, the direct path sends nothing and the entire list falls back to legacy Outfitter.
- Explicit unequips, slot-to-slot dependencies/sources, bank items, and mixed/no-GUID lists remain legacy.
- There are no item-destruction calls in Outfitter's runtime. The direct path uses swap operations only; deletion is not a recovery mechanism.
- The 1.5-second equipment-update throttle and 0.25-second retry loop remain unchanged.

Historical slice 1 implementation details:
- ClassicAPI `C_Item.EquipItemByName(itemGUID, dstSlot)` was verified in the pinned ClassicAPI source to use a cursor-free direct inventory swap when an explicit destination slot is supplied.
- The adapter now exposes a narrow exact-slot operation which requires a transient runtime GUID and refuses bank-sourced items because vanilla does not support equip-from-bank.
- The adapter records the destination slot/GUID as an Outfitter-owned pending equipment change and resolves that marker from `PLAYER_EQUIPMENT_CHANGED`; observed equipment changes still route through `Outfitter_InventoryChanged2`, preserving external/manual reconciliation ownership.
- `Outfitter_ExecuteEquipmentChangeList` uses the new path only when the optimized change list contains exactly one non-empty equip/replacement. If GUID identity is unavailable, it falls back to the original cursor executor.
- Multi-change execution intentionally remains legacy for now. ClassicAPI's own implementation notes confirm that client item locations may remain stale between packet sends; sending several direct swaps in the existing loop would therefore be unsafe without Outfitter-owned sequencing across acknowledgements.
- Explicit empty-slot unequips remain legacy because the public direct equip primitive targets paperdoll slots rather than an empty bag destination.
- The hard-coded 1.5-second update throttle and 0.25-second OnUpdate retry loop are unchanged until this transaction boundary is runtime-proven.
- Stack compilation, special/Riding semantics, paperdoll integration, bank deposit/withdraw execution, SavedVariables, and UI behaviour are otherwise unchanged.

## Recent Relevant Commits
- `678c3edcc5536744776791cb8a969b75c6b74cc4` — `2.0.14-dev`: revert the failed event-unlock timing experiment and restore accepted `2.0.11-dev` runtime behavior.
- `54fa2c771356d3bccf32f28c66842911e018b7f7` — temporary Lua 5.0.2 validation commit for exact `2.0.14-dev` runtime files; Actions run `36182444547` passed all 8 runtime Lua files.
- `e68f2f7c56697819a2dc2b88d489c6bc3f683241` — removed the temporary `2.0.14-dev` validation workflow; runtime files unchanged from `678c3edc...`.
- `f65083c3bbe8559a8e6088a0bcab20eeed06375a` — `2.0.12-dev`: first timing-slice implementation; direct executors report direct/legacy mode and direct operations gain pending final-slot tracking. Pre-handoff review found reciprocal swaps were not yet registering their expected two final slots, so this build was not handed off.
- `d10f7d26b37818671e0bd8c8ef205b10f4eef595` — `2.0.13-dev`: correct reciprocal direct-swap completion tracking; this is the runtime candidate.
- `80f927b8f899f20ad8d6d915c47844df862f848b` — temporary Lua 5.0.2 validation commit for exact `2.0.13-dev` runtime files; Actions run `36167384692` passed all 8 runtime Lua files.
- `f73993a6d9fa4a85625d2a5899775bdbaf3fa566` — removed the temporary `2.0.13-dev` validation workflow; runtime files unchanged from `d10f7d26...`.
- `9353beaa09498e318a1a174984cbdd270a18cea2` — `2.0.11-dev`: handle the exact one-way ring/trinket paired-slot rotation plus bag replacement with two prevalidated atomic swaps.
- `cf76782319fb4431f702318937a7ee900e12c156` — temporary Lua 5.0.2 validation commit for exact `2.0.11-dev` runtime files; Actions run `36164448061` passed all 8 runtime Lua files.
- `b42529f356a93d6a8583326cc5a5f9d046416863` — removed the temporary `2.0.11-dev` validation workflow; runtime files unchanged from `9353beaa...`.
- `1c7accbfc4325486c48604e56ee19a51430ad712` — `2.0.10-dev`: add a narrowly-scoped atomic reciprocal equipped-slot swap for exact two-item paperdoll exchanges.
- `f0c0a1963352b3e8e14f42903892201842667fbb` — temporary Lua 5.0.2 validation commit for exact `2.0.10-dev` runtime files; Actions run `36161783647` passed all 8 runtime Lua files.
- `5163008f3158abc6a5510004dc637373201179e1` — removed the temporary `2.0.10-dev` validation workflow; runtime files unchanged from `1c7accb...`.
- `0e2ec6fbea2a4f0fda70dbdf13e3f9c98b4df3b9` — `2.0.9-dev`: remove the per-slot acknowledgement wait for the narrow safe multi-change path; validate exact distinct bag sources/destinations first, then issue direct swaps back-to-back.
- `16c6d5110e440da8a6d3075c6036d6e92fc8c9b8` — temporary Lua 5.0.2 validation commit for exact `2.0.9-dev` runtime files; Actions run `36153635758` passed all 8 runtime Lua files.
- `a3c9afc7519c34185cb29d550bcda9f1096342e2` — removed the temporary `2.0.9-dev` validation workflow; runtime files unchanged from `0e2ec6f...`.
- `a3bbb8ddb30f7f0a19d2ba685c166b28206c06d0` — P3 slice 2: sequence exact normal-bag multi-slot replacements across matching equipment-change acknowledgements; bump TOC to `2.0.8-dev`.
- `7b61e32e96cf378078fd27c9dfeefe934a1d3986` — temporary Lua 5.0.2 validation commit for the exact slice 2 runtime files; GitHub Actions run `36148023987` passed.
- `f73a7b3e7415c1284b8c1eb37984b87ff1b4c556` — removed the temporary slice 2 validation workflow; runtime files unchanged from `a3bbb8ddb30f7f0a19d2ba685c166b28206c06d0`.
- `026bd1164d817dd6e4775f76df40dd293b2492fa` — fixed the user-visible Outfitter version to read `GetAddOnMetadata("Outfitter", "Version")` instead of hardcoded upstream `1.4`; runtime files now identify the P3 test build as `0.1.1-dev`.
- `adc23b441413e39bd85ab736fe653168753139ee` — bumped the current P3 test build from `0.1.0-dev` to `0.1.1-dev`.
- `dda160ba0101cb4e2e8758b7061c058873fb0efe` — clarified the authoritative versioning rule: every addon/runtime change increments the numeric TOC version; documentation-only/status-only commits do not.
- `5b2f20a93a3e1e743ff6f5a7ae39739928f7aa5e` — completed P3 slice 1 runtime delta by excluding bank-sourced items from the direct exact-slot path.
- `2644ee6c3c406077994136347972e85b2ff2e807` — routed single-change equip/replacement lists through the P3 ClassicAPI adapter and observed owned acknowledgements before normal reconciliation.
- `9ec1c61c1b2d378bc5b10fc073da40ced3757931` — added the P3 exact GUID/explicit-slot adapter and owned equipment-change marker.
- `4e703b53b7d70a151cbec49cc2288d85427afc80` — recorded explicit user acceptance of P2 and opened P3.
- `7e69473f0990cf7f41f10a0ed821399d9d001f84` — recorded the partial P2 runtime pass before final user acceptance.
- `2143a0cd29cc50a8e52d45040adacb299bf133cd` — implemented P2 transient ClassicAPI GUID identity, exact runtime matching, and legacy fallback hydration without changing SavedVariables or the physical executor.
- `dcc3f3572c201a568eb5471ebf52019fb42feefe` — fixed stale/incomplete minimap drag state so it cannot repeatedly crash the shared update timer.
- `0e98276856f64c975e5eb3c9a055e04552d84c57` — recorded clean-start/outfit-creation success and the repeated minimap timer failure.
- `9e7f75634072600ec470fa00e21da84eeeb61526` — completed P1 preflight hardening by normalizing legacy/partial settings, guarding pre-init public/keybind/slash lookup paths, and hiding the minimap button until initialization.
- `9b0aad1d72a64485c7479819f8f1e2a58974e7ce` — hardened settings normalization and public entry points.
- `24e4b557aa722ab46014cf5a7597f52d2104ddba` — fixed first-use initialization readiness and blocked settings-dependent UI/update paths until initialization completes.
- `028f0311ca103744a2141a1fd162715c4099ecf3` — recorded the failed first P1 runtime test and its common pre-initialization settings failure.
- `20879e99be476e03ebcbb7cab6f861a006af1624` — P1 ClassicAPI equipment observation/identity bridge; first runtime test reached initialization failures before the remaining checklist could be completed.
- `588f52f401a53061e546a3ef8aaeb860de546bcb` — created the initial live handoff/status document.
- `c92a11796e8decb4c43b79b205624e32ceb0ee59` — imported the complete Cosmin runtime baseline, required BLP artwork and `Bindings.xml`, development metadata, and initial workflow/design documentation.
- `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` — initial repository scaffold on `main`.

## Completed / User-Verified
- P1 ClassicAPI observation bridge is user-verified passed on WoW 1.12.1 with ClassicAPI and pfUI present.
- Clean SavedVariables startup produces a healthy named default outfit list and Outfitter opens normally.
- Creating outfits, switching rapidly between them, manual equipment changes, pfUI-driven equipment changes, temporary/manual external-state handling, partial/special outfit behaviour, and reload persistence all behave as expected from the user's prior TurtleWoW experience.
- Rapid switching no longer reproduces the prior repeated `CursorStartX` timer error on runtime/code head `dcc3f3572c201a568eb5471ebf52019fb42feefe`.
- Native Outfitter minimap-button dragging remains environment-limited because pfUI manages addon-button dragging; attempted click/drag interaction produced no Lua error.

## Implemented / Awaiting Runtime Test
- Baseline runtime is imported from CosminPOP/Outfitter.
- Required addon-local BLP artwork is present.
- `Bindings.xml` is present; it is loaded by WoW convention outside the TOC list.
- `Outfitter.toc` owns the development version: `## Title: Outfitter-dev`, `## Version: 2.0.14-dev`. `OutfitterStrings.lua` reads that version through `GetAddOnMetadata("Outfitter", "Version")`; the old hardcoded upstream `1.4` display value is removed.
- P1 ClassicAPI observation/identity bridge plus initialization/preflight hardening and the minimap drag-state fix are implemented and user-verified.
- P2 runtime item identity is implemented at `2143a0cd29cc50a8e52d45040adacb299bf133cd`: transient GUID associations, GUID-indexed live items, exact-match preference, and legacy fallback hydration. It is user-accepted after successful normal/rapid outfit switching, manual equipment changes, pfUI character-slot flyout changes, reload persistence, and unchanged SavedVariables schema. Bank-open matching, focused partial/special-outfit rechecks, and a true same-legacy-identity duplicate-instance case remain explicit validation debt.
- P3 slice 1 is implemented, compiler-checked, and user-accepted. Executor logic is `5b2f20a93a3e1e743ff6f5a7ae39739928f7aa5e`; the exact accepted runtime/code head is `026bd1164d817dd6e4775f76df40dd293b2492fa`, version `0.1.1-dev`. Repeated one-slot swaps between the unenchanted and 1% haste Gauntlets of the Righteous Champion passed in both directions, multiple other set swaps passed, manual character-screen equipment changes remained external/manual, and the preserved full-set/multi-slot path remained healthy. The UI correctly reports `0.1.1-dev` in both the addon list and Outfitter's character-screen title/pop-out.
- `2.0.8-dev` acknowledgement sequencing was partially runtime-tested: some sets were near-instant via legacy fallback, while direct-path sets visibly equipped piece-by-piece at roughly ~0.1s per slot. No Lua error was reported, but the added cadence was considered unnecessary after ClassicAPI re-review.
- `2.0.9-dev` is implemented, compiler-checked, and user-accepted at exact runtime/code head `0e2ec6fbea2a4f0fda70dbdf13e3f9c98b4df3b9`. It replaces the acknowledgement wait with full-list prevalidation plus immediate direct burst for the same narrow safe case. Runtime result: swaps are essentially immediate and feel like old Outfitter; occasional individual-slot visual lag self-resolves correctly; no issue was reported.
- `2.0.10-dev` is implemented, compiler-checked, and user-accepted at exact runtime/code head `1c7accbfc4325486c48604e56ee19a51430ad712`. Exact reciprocal ring swaps passed repeatedly with no observed bag transit; manual swapping and config-editor swapping also remained healthy.
- `2.0.11-dev` is implemented, compiler-checked, and user-accepted at exact runtime/code head `9353beaa09498e318a1a174984cbdd270a18cea2`. The exact one-way ring/trinket paired-slot rotation with a normal-bag replacement worked without reported errors.

## Static / Automated Checks
- Imported runtime Lua/XML/localization files were verified content-identical to Cosmin's inspected head blobs; project metadata/docs are the intentional differences.
- XML addon-local texture references were checked and the required BLP assets imported.
- `Bindings.xml` was verified upstream and imported.
- Legacy outfit stack, equipment update path, paperdoll hook, tooltip parsing, cursor swap path, and timer/throttle path were inspected.
- ClassicAPI equipment-set, item GUID/location, explicit equipment-swap, and equipment-change event facilities were inspected.
- pfUI's ClassicAPI Equipment Manager and paperdoll flyout module were inspected.
- P1 diff review confirmed the runtime delta is limited to `OutfitterClassicAPI.lua`, its TOC entry, and small event registration/callback insertions in `Outfitter.lua`.
- P1 adds no new top-level locals to the large legacy `Outfitter.lua`; the adapter is separate to avoid worsening Lua 5.0 top-level local pressure.
- Static review of the initialization call chain and all 98 direct `gOutfitter_Settings` references identified and closed the remaining defensible pre-init/partial-settings hazards without altering outfit semantics.
- Real Lua 5.0.2 compiler check passed all 8 runtime Lua files after the full preflight hardening pass.
- Real Lua 5.0.2 compiler check also passed all 8 runtime Lua files after the drag-state fix. That successful run was on validation commit `1f34cf97f09cc3cb55b6666f320afe57e0e058bf`, whose runtime files match runtime/code head `dcc3f3572c201a568eb5471ebf52019fb42feefe`; the temporary workflow was removed afterward at `ea16a761de1c2d857ec63e34ce8d85c2d676f35c`.
- P2 diff review confirmed only `Outfitter.lua` and `OutfitterClassicAPI.lua` changed; no TOC, XML, physical-executor, throttle, Riding/special-outfit, or paperdoll-hook code was changed.
- The verified Lua 5.0.2 compiler path used during P1 was rerun against the P2 candidate and passed all 8 runtime Lua files in GitHub Actions run `36036193227`; the checked runtime files are exactly code commit `2143a0cd29cc50a8e52d45040adacb299bf133cd` plus the temporary validation workflow.
- ClassicAPI adapter capability checks were re-reviewed against brues-code/ClassicAPI's documented `C_EventUtils.IsEventValid` and `PLAYER_EQUIPMENT_CHANGED` support.
- For P3, pinned ClassicAPI source `fde3beca9dba18e7327802eb094b5bff81f39d47` was inspected: explicit-slot `C_Item.EquipItemByName(item, dstSlot)` uses the cursor-free direct swap primitive, accepts an exact GUID/item location, and server/client location lag between sequential swaps is a real concern that requires owned sequencing rather than a naive loop replacement.
- P3 diff review from P2-accepted head `4e703b53b7d70a151cbec49cc2288d85427afc80` to runtime/code head `5b2f20a93a3e1e743ff6f5a7ae39739928f7aa5e` changes only `Outfitter.lua` (+27/-2) and `OutfitterClassicAPI.lua` (+54); no TOC, XML, stack-model, throttle, Riding/special-outfit, paperdoll-hook, or SavedVariables changes are present.
- Real Lua 5.0.2 compiler validation passed all 8 runtime Lua files in GitHub Actions run `36072172938` on validation commit `b24ba181d467e2a7cbf600563331b387d6fdd32e`; those runtime files exactly contain P3 executor code head `5b2f20a93a3e1e743ff6f5a7ae39739928f7aa5e` plus only the temporary validation workflow, which was removed at `5904ca337211a488900d7a696181f998d5595a31`.
- After correcting version ownership/display, real Lua 5.0.2 compiler validation passed all 8 runtime Lua files again in GitHub Actions run `36072774529` on validation commit `e687d60acda216ecb0b5a8a09b4a073c9d7c8219`; its addon runtime files match exact runtime/code head `026bd1164d817dd6e4775f76df40dd293b2492fa`. The temporary workflow was removed at `941a09ec5e9a4dcc6fe1fd1ba273fb9700aaefa2`.
- P3 slice 2 diff review from accepted slice 1 to runtime/code head `a3bbb8ddb30f7f0a19d2ba685c166b28206c06d0` changes only `Outfitter.lua`, `OutfitterClassicAPI.lua`, and the TOC version. No outfit-stack, SavedVariables, automatic/special outfit, bank deposit/withdraw, paperdoll, Riding, throttle, or retry-loop code changed.
- Real Lua 5.0.2 compiler validation passed all 8 runtime Lua files in GitHub Actions run `36148023987` on validation commit `7b61e32e96cf378078fd27c9dfeefe934a1d3986`; its addon runtime files exactly match runtime/code head `a3bbb8ddb30f7f0a19d2ba685c166b28206c06d0`. The temporary workflow was removed at `f73a7b3e7415c1284b8c1eb37984b87ff1b4c556`.
- `2.0.9-dev` diff review changes only `Outfitter.lua`, `OutfitterClassicAPI.lua`, and the TOC version. It removes the slice-2 acknowledgement state machine, adds exact bag-slot/GUID and duplicate source/destination prevalidation, and preserves all documented legacy fallbacks and timing code.
- Real Lua 5.0.2 compiler validation passed all 8 runtime Lua files in GitHub Actions run `36153635758` on validation commit `16c6d5110e440da8a6d3075c6036d6e92fc8c9b8`; its addon runtime files exactly match runtime/code head `0e2ec6fbea2a4f0fda70dbdf13e3f9c98b4df3b9`. The temporary workflow was removed at `a3c9afc7519c34185cb29d550bcda9f1096342e2`.
- `2.0.10-dev` diff review changes only `Outfitter.lua`, `OutfitterClassicAPI.lua`, and the TOC version. The new direct path requires exactly two reciprocal equipped sources, verifies both transient GUIDs still occupy the expected paperdoll source slots, and completes both requested moves with one atomic direct swap. Explicit unequip, non-reciprocal dependencies, bank paths, stack semantics, SavedVariables, automatic/special outfits, and legacy timing are unchanged.
- Real Lua 5.0.2 compiler validation passed all 8 runtime Lua files in GitHub Actions run `36161783647` on validation commit `f0c0a1963352b3e8e14f42903892201842667fbb`; its addon runtime files exactly match runtime/code head `1c7accbfc4325486c48604e56ee19a51430ad712`. The temporary workflow was removed at `5163008f3158abc6a5510004dc637373201179e1`.
- `2.0.11-dev` diff review changes only `Outfitter.lua`, `OutfitterClassicAPI.lua`, and the TOC version. The new path recognizes exactly the three optimized changes `[empty target, equipped ring/trinket -> paired target, normal-bag replacement -> old source slot]`, restricts direct execution to ring/trinket pairs, verifies the equipped GUID and exact bag GUID/location before sending anything, then performs paperdoll swap first and bag->paperdoll swap second. Weapons, explicit unequips, bank paths, stack semantics, SavedVariables, automatic/special outfits, and legacy timing are unchanged.
- Real Lua 5.0.2 compiler validation passed all 8 runtime Lua files in GitHub Actions run `36164448061` on validation commit `cf76782319fb4431f702318937a7ee900e12c156`; its addon runtime files exactly match runtime/code head `9353beaa09498e318a1a174984cbdd270a18cea2`. The temporary workflow was removed at `b42529f356a93d6a8583326cc5a5f9d046416863`.
- `2.0.13-dev` timing diff kept swap-selection rules unchanged but runtime testing rejected the event-owned pending-slot bookkeeping because outfit changes visibly hitched the game for roughly 0.1–0.2 seconds.
- `2.0.14-dev` restores `Outfitter.lua` and `OutfitterClassicAPI.lua` byte-for-byte to accepted `2.0.11-dev` runtime content; only `Outfitter.toc` advances to `2.0.14-dev`.
- Real Lua 5.0.2 compiler validation passed all 8 runtime Lua files in GitHub Actions run `36182444547` on validation commit `54fa2c771356d3bccf32f28c66842911e018b7f7`; its addon runtime files exactly match runtime/code head `678c3edcc5536744776791cb8a969b75c6b74cc4`. The temporary workflow was removed at `e68f2f7c56697819a2dc2b88d489c6bc3f683241`.
- No static/compiler inspection is being counted as an in-game test.

## Current Issues
- P1 is currently passing in-game after a clean SavedVariables reset.
- P2's runtime GUID identity/matching delta is compiler-checked and user-accepted. Normal/rapid switching, manual changes, pfUI character-slot flyout changes, reload persistence, and unchanged SavedVariables schema pass. Bank-open matching, focused partial/special-outfit rechecks, and a true same-legacy-identity duplicate-instance case remain documented validation debt; P3 is now unblocked.
- The original pre-existing Outfitter SavedVariables produced malformed/blank outfit names and odd disabled states. Deleting those SavedVariables fixed the problem; the old file is no longer available, so migration compatibility with that unknown prior schema cannot be diagnosed or claimed.
- The earlier pre-initialization settings nil failures and repeated minimap-drag timer failure are fixed and user-verified not to recur in the tested setup.
- Legacy Outfitter globally replaces `PaperDollItemSlotButton_OnClick`, creating a future coexistence risk with pfUI and other paperdoll addons.
- P3 slices 1–4 physical execution are user-accepted through `2.0.11-dev`. Safe public-API direct coverage now includes single exact replacements, independent normal-bag multi-replacements, exact reciprocal paired-slot exchanges, and the exact one-way ring/trinket rotation with bag replacement. Explicit unequip, weapon-specific multi-step rotations, bank, moved/ambiguous source, mixed unsupported, and no-GUID cases remain legacy. The `2.0.13-dev` timing experiment is rejected due to runtime hitching; `2.0.14-dev` restores accepted timing behavior.
- Legacy equipment updates still use the 1.5-second throttle and 0.25-second OnUpdate retry path; neither timing constraint has been relaxed yet.
- User reported an inherited outfit-editor bug: a slot unchecked in the selected outfit can still be written back into that outfit during inventory reconciliation. Audit confirms upstream `Outfitter_UpdateOutfitFromInventory` uses `if not vCheckbox:GetChecked() or not vCheckbox.IsUnknown then`, so unchecked slots can still be updated. This is separate from the `2.0.13-dev` timing regression and should be fixed only after the rollback gate.
- Aura/item facts are still often derived through hidden tooltips.
- Shared `C_EquipmentSet` state must not be used as hidden Outfitter storage.
- External pfUI/ItemRack/manual swaps must not be mistaken for Outfitter-owned transactions.
- Swimming requires an explicit design because it is absent from this imported baseline.

## Testing

### Last Runtime Test
- Version/commit: `2.0.13-dev`, exact runtime/code head `d10f7d26b37818671e0bd8c8ef205b10f4eef595`.
- Failed: ordinary outfit swaps visibly hung the game for roughly 0.1–0.2 seconds.
- Failed: Birthday Suit also produced the same visible hitch.
- Other tested swaps still resolved, but felt laggier than before.
- Separate observation: unchecked outfit slots can still be saved/restored; static audit confirms this is an inherited upstream logic bug, not introduced by the timing slice.
- Result: reject the `2.0.12/2.0.13` event-unlock timing design and restore the accepted baseline.

### Next Runtime Test
- Test `2.0.14-dev`, exact runtime/code head `678c3edcc5536744776791cb8a969b75c6b74cc4`.
- This is intentionally the accepted `2.0.11-dev` runtime restored under a new version. Confirm ordinary outfit swaps and Birthday Suit no longer produce the new ~0.1–0.2 second game hitch.
- No need for special internal-path testing; use the same outfits which felt bad on `2.0.13-dev`.
- The unchecked-slot saving/restoring bug is not fixed in this rollback build; it is the next isolated slice after the hitch regression is confirmed gone.

## Planned / Next Work
- **P0 — baseline/workflow:** complete.
- **P1 — ClassicAPI observation bridge:** complete and user-verified.
- **P2 — item identity modernization:** implemented, compiler-checked, and user-accepted at `2143a0cd29cc50a8e52d45040adacb299bf133cd`. Normal/rapid swaps, manual changes, pfUI slot-flyout changes, reload persistence, and unchanged SavedVariables schema pass. Bank-open matching, focused partial/special rechecks, and true exact-duplicate physical-instance testing remain validation debt.
- **P3 — cursor-free executor/timing:** physical-executor slices 1–4 remain user-accepted through `2.0.11-dev`. The `2.0.12/2.0.13` event-unlock timing experiment is rejected due to visible runtime hitching. `2.0.14-dev` restores the accepted runtime exactly and is the rollback gate. Do not attempt another timing redesign until the rollback is confirmed.
- **P4 — automatic-state modernization:** replace tooltip parsing/broad polling for Riding, auras, forms, Swimming, and similar states only where a verified ClassicAPI fact exists; preserve fallback where needed.
- **P5 — paperdoll/pfUI coexistence:** remove the global `PaperDollItemSlotButton_OnClick` replacement and preserve QuickSlots via additive integration; test pfUI Equipment Manager enabled and disabled.
- **P6 — optional C_EquipmentSet interoperability:** only after Outfitter's model/executor are stable, decide whether named Outfitter outfits should explicitly import/export/mirror user-visible ClassicAPI sets.
- **P7 — cleanup:** remove obsolete cursor/timer/polling/tooltip paths only after their replacements are runtime-proven.

## Deferred / Out of Scope
During the current P3 slice, do not:
- Broaden the direct executor beyond the accepted slice 4 boundary; weapons, explicit unequip, other slot-to-slot dependency/source, bank, mixed/no-GUID migration remain at the documented safety boundary unless new ClassicAPI capability or focused evidence changes it.
- Remove or retune the 1.5-second throttle or 0.25-second retry loop.
- Persist GUIDs into the existing SavedVariables schema unless the P2 design explicitly proves a migration requirement; the current plan is runtime identity plus legacy fallback.
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
Runtime-test `2.0.14-dev`, exact runtime/code head `678c3edcc5536744776791cb8a969b75c6b74cc4`, using the same ordinary outfits and Birthday Suit that visibly hitched on `2.0.13-dev`. Confirm the new ~0.1–0.2 second game hitch is gone and behavior feels like the accepted `2.0.11-dev` baseline again. Do not combine another timing change with this gate. After rollback confirmation, fix the inherited unchecked-slot update bug in `Outfitter_UpdateOutfitFromInventory` as its own runtime slice and version bump.
