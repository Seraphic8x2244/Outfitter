# Development Progress

> Live project-development context for a fresh chat. Keep this current and concise. Remove or compress superseded detail once it no longer affects future work.

## Current
- Repository: `Seraphic8x2244/Outfitter`
- Branch: `dev`
- Version: `2.0.26-dev`
- Version-line decision: the 2.x line marks this fork as the ClassicAPI modernization of upstream Outfitter 1.4; patch `8` preserves the eight meaningful runtime/build states already reached before the line change. The accepted `0.1.1-dev` build remains recorded under its tested identity rather than being retroactively renamed.
- Development/handoff head: the commit containing this file; verify the remote `dev` head before editing.
- Pre-centralization branch head: `9088afb9544cdcb4791a5ae61b69e4b407ff975f`
- Current runtime/code head: `c6fffcfd1cc6c6699305408fad8451cb248b5be0`
- Main baseline: `e51322efd2b62a5bc792a8a4fd599c0ed39cdda7` — repository scaffold only, not a runnable addon release.
- Stable baseline/release: None in this repository.
- Upstream runtime baseline: CosminPOP/Outfitter `4587638ae5bd10eb9bc83bbae87a092e4b892d94`
- ClassicAPI research reference: brues-code/ClassicAPI `fde3beca9dba18e7327802eb094b5bff81f39d47`
- Goal: incrementally modernize Outfitter for WoW 1.12.1 using ClassicAPI while preserving the features and data model that make Outfitter distinct.
- Current scope boundary: P1 and P2 are user-accepted on WoW 1.12.1 with ClassicAPI/pfUI. P2 exact code head `2143a0cd29cc50a8e52d45040adacb299bf133cd` passed normal/rapid outfit swaps, manual equipment changes, pfUI character-slot flyout changes, reload persistence, and unchanged SavedVariables schema; bank-open, focused partial/special rechecks, and a true same-legacy-identity duplicate-instance case remain validation debt. P3 slice 1 is user-accepted on exact runtime/code head `026bd1164d817dd6e4775f76df40dd293b2492fa`, version `0.1.1-dev`: repeated one-slot enchanted/unenchanted glove swaps passed in both directions, multiple other outfit swaps passed, manual/character-screen changes remained external/manual, the preserved multi-slot executor remained healthy, and TOC-driven `0.1.1-dev` display was confirmed in the addon list and Outfitter character-screen UI. P3 slice 2 at `2.0.8-dev` was runtime-exercised and revealed a visible ~0.1s-per-slot cadence on sets entering the acknowledgement chain, while legacy-fallback sets remained near-instant. Re-review of ClassicAPI showed that this acknowledgement wait was over-conservative for the narrow all-normal-bag replacement case. The recommendation changed accordingly. Current `2.0.9-dev` runtime/code head `0e2ec6fbea2a4f0fda70dbdf13e3f9c98b4df3b9` removes that per-slot wait: it validates the whole direct list up front, confirms every GUID is still in its exact distinct normal-bag source slot, confirms distinct destination slots, then issues the atomic bag->paperdoll swaps back-to-back. User runtime testing reports the result is essentially immediate and feels like old Outfitter; occasional individual slots can visibly lag briefly, but every tested swap resolved to the correct final equipment with no issue. Slice 2 is accepted. Slice 3 at `2.0.10-dev`, runtime/code head `1c7accbfc4325486c48604e56ee19a51430ad712`, is user-accepted: exact reciprocal ring-slot swaps worked repeatedly in both outfit directions, the items were never observed entering bags, and manual plus config-editor swaps remained healthy. The direct path uses one atomic ClassicAPI paperdoll swap after both GUIDs are verified in the expected source slots. Slice 4 at `2.0.11-dev`, runtime/code head `9353beaa09498e318a1a174984cbdd270a18cea2`, is user-accepted: the exact three-change ring/trinket rotation produced by legacy optimization—synthetic empty target, equipped accessory moving across, then a normal-bag accessory replacing its old slot—worked in runtime testing. Physical executor modernization is intentionally stopped at the safe public-API boundary: explicit unequip has no public cursor-free equipped-slot -> chosen-bag-slot primitive, and multi-step weapon rotations can be affected by weapon-swap timing/GCD restrictions. Timing slice 1 in `2.0.13-dev` failed runtime testing. User observed a new ~0.1–0.2 second game hitch when swapping ordinary outfits and Birthday Suit, with other swaps also feeling laggier. The event-unlock timing experiment is therefore rejected. `2.0.14-dev`, runtime/code head `678c3edcc5536744776791cb8a969b75c6b74cc4`, cleanly restored the accepted `2.0.11-dev` runtime logic while advancing the version only. User retest still observed a brief hitch, possibly somewhat reduced. This proves the hitch predates the rejected `2.0.13-dev` timing experiment. Audit traced a likely older source back to P1: ClassicAPI fires `PLAYER_EQUIPMENT_CHANGED` once per changed paperdoll slot, and Outfitter was running the full expensive `Outfitter_InventoryChanged2` reconciliation for every one of those slot events while also retaining Vanilla's original `UNIT_INVENTORY_CHANGED` reconciliation. `2.0.15-dev` keeps the ClassicAPI per-slot event only for resolving Outfitter-owned direct-swap markers and leaves full reconciliation solely on the legacy inventory event. User runtime testing still observed a hitch but felt it was better; a manual ring change was still noticed normally, and selecting the saved preset restored the saved rings as expected. Audit then found another independent synchronous burst cost while the Outfitter window is visible: each `BAG_UPDATE` invalidates a bag and immediately triggers a visible-list rebuild. `2.0.16-dev` retained immediate per-bag cache invalidation but deferred the visible refresh to ClassicAPI's coalesced `BAG_UPDATE_DELAYED` boundary. User runtime testing found the hitch still present and about the same as `2.0.15-dev`; ring/manual behavior remained correct, so this UI-refresh coalescing was effectively neutral. Audit then moved one level deeper: Vanilla `UNIT_INVENTORY_CHANGED` itself can arrive repeatedly during a multi-slot change, and each event still ran the full inventory reconciliation synchronously. `2.0.17-dev` collapses those events per frame by marking reconciliation pending and running one `Outfitter_InventoryChanged2` pass from the existing update frame on the next frame. User runtime testing reports the hitch is now noticeably shorter than `2.0.16-dev`; treat the performance improvement as accepted while retaining the residual hitch as future profiling work rather than continuing speculative tuning. `2.0.18-dev` is user-accepted for the unchecked-slot correctness fix: a partial/RP outfit containing only visible armour leaves unticked ring slots completely unowned, so moving between full outfits and back to the RP outfit preserves whichever rings the last owning outfit chose. Manually changing/clicking a ring while the RP outfit's ring slot is unticked does not silently add that ring to the RP outfit. This matches the addon model: the checkbox is the explicit slot-ownership control; ticking a slot captures the currently equipped item, unticking removes that slot from the outfit. `2.0.19-dev` completed the single-file/runtime-locales structural cleanup: `OutfitterClassicAPI.lua` was reconciled into `Outfitter.lua`, localization files moved byte-for-byte under `locales/`, and TOC loader paths were updated. Its required in-game structural smoke was not performed before the next behavior-neutral slice. `2.0.20-dev` adds only unused `OutfitterClassicAPI` fact helpers for Riding, helpful-aura name/icon/spell data, current shapeshift form ID, and the ClassicAPI single-form-change event capability. Its structural smoke failed: clicking the Outfitter button raised a secondary nil-global error for `Outfitter_ToggleOutfitterFrame`, even though that function exists later in `Outfitter.lua`, proving the Lua chunk had stopped earlier during load. The only structural delta capable of preventing locale-dependent top-level initialization while still allowing `Outfitter.xml` to load was the new forward-slash locale TOC paths. `2.0.21-dev` changes only those six TOC loader paths to Vanilla-style backslashes and bumps the version; `Outfitter.lua` and all locale bytes are unchanged. User runtime testing reports the complete requested structural/regression smoke passes: no load/click Lua error, the Outfitter window opens and reports `2.0.21-dev`, normal saved-outfit switching works, and manual gear-change reconciliation works. `2.0.22-dev` is a layout-only follow-up: the inner `Outfitter` heading moves left while remaining inset, `New Outfit` moves to the top-right on the same visual centre line, the button changes from 115x21 to 95x25, and the outfit list remains unmoved. User screenshots accept the horizontal spacing/button proportions but show both controls sitting too high in the header; they also show the Outfits page alone carrying an extra light-grey bottom button-bar texture unlike Options. `2.0.24-dev` is the requested chrome-alignment revision: both header controls move down together from y=-36 to y=-43 without changing X positions; the Outfits-only `ButtonBarBackground` is hidden while retained as a layout anchor; the bottom tab label is renamed `Outfits`; and the outer frame version label becomes `v<TOC version>`. Internal `2.0.23-dev` was never delivered for runtime testing because static diff review caught a literal `\\n` locale insertion error; `2.0.24-dev` corrects it. User runtime testing accepts all five `2.0.24-dev` checks: Outfits joins the page like Options, header controls are vertically centred, list position is unchanged, the outer label shows `v2.0.24-dev`, and `New Outfit` still works. `2.0.25-dev` uses the newly freed bottom space for one additional visible outfit row: visible rows increase from 14 to 15, the scroll frame grows 252->270 px, `OutfitterItem14` is added below item 13, and the scrollbar trench grows 258->276 px while its bottom anchor moves down 18 px so its top remains aligned. `2.0.26-dev` carries that viewport change forward unchanged and updates the About page credits only: the redundant `Outfitter <version>` line is removed from About, the original-author credit becomes `Originally designed and written by John Stephen`, a new `Updated and maintained by Revenga` line is added, and `Gaia` is added to the existing Beta Testers list without removing any existing tester, Special Thanks credit, or guild URL.

## Current Design / Development Contract

### Product Identity / Scope
- Preserve Outfitter as Outfitter: named outfits, complete/partial/accessory outfits, automatic/situational outfits, priority/layering, keybinds, special outfits, and manual-change behaviour.
- Prefer incremental modernization over a rewrite.
- Preserve existing SavedVariables where practical.
- Do not turn Outfitter into ItemRack.
- Do not duplicate pfUI's flat Equipment Manager UI or make pfUI's Equipment Manager the product model.
- Target WoW 1.12.1 / Interface 11200 / Lua 5.0.3.
- ClassicAPI is an explicit project prerequisite and should be used directly where it materially improves correctness or implementation quality.
- pfUI compatibility is a first-class target. Turtle/Octo-style enhanced clients should be supported where practical without distorting the core design.

### Architecture / Ownership
- Runtime architecture is intentionally single-file: all executable addon logic lives in `Outfitter.lua`.
- User-facing strings live under `locales/`; `locales/enUS.lua` supplies the base/default strings and locale-specific files override them conditionally.
- `OutfitterClassicAPI.lua` was introduced during P1 without explicit agreement and has now been reconciled back into `Outfitter.lua` in `2.0.19-dev`; future ClassicAPI work stays in the existing namespace section rather than creating another runtime module.
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
- Outfitter uses one runtime logic file: `Outfitter.lua`. ClassicAPI integration remains grouped behind the `OutfitterClassicAPI` namespace inside that file; do not split runtime logic into another Lua file without explicit agreement.

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
- Runtime GUID associations live in the `OutfitterClassicAPI` namespace inside `Outfitter.lua` in a weak-key side-map; no GUID field was added to persisted outfit records or the SavedVariables schema.
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

### Active Implementation Decision: P4
P4 begins with a read-only audit against pinned ClassicAPI `fde3beca9dba18e7327802eb094b5bff81f39d47`. No runtime files changed during the audit.

Audit findings:
- Automatic/situational state detection is already event-driven. There is no periodic special-state polling loop to remove. `PLAYER_AURAS_CHANGED` triggers the broad aura/form refresh; zone, combat, death and Dining health/mana state use their existing events. The 0.25-second `OutfitterUpdateFrame` loop belongs to equipment retry/execution, not automatic-state detection, and is outside P4.
- Riding currently comes from mount-buff tooltip text, including Cosmin/Turtle compatibility matches for the normal mount-speed text, generic `"Riding"`, and `"Slow and steady..."`. ClassicAPI exposes `IsMounted()`, backed directly by the player's mount-display descriptor field, which is a stronger semantic fact than tooltip text. Preserve the tooltip path as fallback/validation protection until the direct path is runtime-proven on the target Turtle-compatible setup.
- ClassicAPI `C_UnitAuras` exposes player helpful-aura `name`, `icon` and `spellId` directly. One `AuraUtil.ForEachAura` / slot-based scan can preserve the existing aura-name/icon semantics for Dining, Shadowform, Ghost Wolf, Feign Death state, Hunter aspects and Evocate without reading hidden buff-tooltip lines on the ClassicAPI path.
- Dining has no separate verified "is dining" state API. Its existing fork/knife and drink-icon semantics should remain aura-derived; only the source of aura metadata can be modernized. The existing UNIT_HEALTH/UNIT_MANA unequip rule remains unchanged.
- ClassicAPI exposes `GetShapeshiftFormID()` plus `UPDATE_SHAPESHIFT_FORM`, providing a direct current-form fact and a dedicated change event. This can replace the legacy "aura changed -> enumerate available forms -> compare localized form names" mechanism on the ClassicAPI path.
- Direct form migration must preserve the existing Outfitter state set only. Verified 1.12 form IDs cover current Warrior stances, Druid Cat/Bear/Dire Bear/Aquatic/Travel/Moonkin, Rogue Stealth, Shaman Ghost Wolf and Priest Shadowform. Do not silently add Spirit of Redemption, Turtle Tree of Life, or Turtle Swift Travel behavior merely because ClassicAPI exposes their form IDs.
- ClassicAPI also exposes `IsSwimming()`, but the imported Outfitter baseline has no Swimming special outfit. This is capability evidence only; adding Swimming remains explicitly out of scope.
- `OutfitterTooltip` is also used for item-stat and bind-on-equip inspection. P4 must not remove the hidden tooltip infrastructure wholesale; only automatic-state tooltip reads with a proven direct replacement are candidates.
- ClassicAPI-specific state capability checks and reads should remain grouped behind the `OutfitterClassicAPI` namespace inside `Outfitter.lua`, preserving one runtime logic file and the native fallback boundary.

## Recent Relevant Commits
- `c83967e6dfc9f6a174e29d5463ccc8d3c3b648bf` — `2.0.19-dev`: reconcile `OutfitterClassicAPI.lua` into `Outfitter.lua`, move localization files byte-for-byte under `locales/`, and update TOC loader paths.
- `53cdecd54f4ce24a8e90c3d90ee41c4d5e84e3bc` — temporary canonical Lua 5.0.3 validation state for exact `2.0.19-dev` runtime files; GitHub Actions run `36238242344` passed all 7 runtime Lua files.
- `0969b1d395d5787e2d6f35a6da34e645c46386d0` — remove temporary Lua 5.0.3 checker/workflow and document the single-file runtime/locales architecture; runtime files unchanged from `c83967e6...`.
- `de0ddd8468dab5d27388ab178cc4af432ed5ec78` — `2.0.18-dev`: fix inherited unchecked-slot reconciliation by updating the selected outfit only for checked, known slots.
- `f1b653605815e2442b67f24ea19592860ef45d8d` — canonical Lua 5.0.3 validation state for `2.0.18-dev`; GitHub Actions run `36230875432` passed all 8 runtime Lua files using the exact VanillaTemplate checker content.
- `7171d295e9711c9a94ee5f75b5bff5b041be15ca` — removed the temporary canonical-checker bundle and validation workflow; runtime files unchanged from `de0ddd84...`.
- `cec8bf4e3421f2b42f5486860af0141ef8719493` — `2.0.17-dev`: collapse repeated legacy inventory-change reconciliation into one next-frame pass.
- `8c38c2486db43824bf672baa9a35472000dc796a` — temporary Lua 5.0.2 validation commit for exact `2.0.17-dev` runtime files; Actions run `36187009322` passed all 8 runtime Lua files.
- `2305b3614a890380f4a52e5d3ef40decf27452af` — removed the temporary `2.0.17-dev` validation workflow; runtime files unchanged from `cec8bf4e...`.
- `cd302975013a3d6edc42145d331ff21d2011301f` — `2.0.16-dev`: coalesce bag-driven visible-list refreshes to `BAG_UPDATE_DELAYED` while keeping per-bag invalidation immediate.
- `389e6fe3ac974fa5ece6cfc2ed0b5fe7c909ed9c` — temporary Lua 5.0.2 validation commit for exact `2.0.16-dev` runtime files; Actions run `36186387842` passed all 8 runtime Lua files.
- `0dd98386435b1215199f6d671827d517705ab156` — removed the temporary `2.0.16-dev` validation workflow; runtime files unchanged from `cd302975...`.
- `a6d7ca70cbec8a29fa5ec9e850d1785e7e6f4961` — `2.0.15-dev`: stop doing a full Outfitter inventory reconciliation once per ClassicAPI paperdoll slot event; retain the event only for owned-marker observation.
- `18a89322f1d2a76bda0b25e07d8c5a9b27967dca` — temporary Lua 5.0.2 validation commit for exact `2.0.15-dev` runtime files; Actions run `36184200070` passed all 8 runtime Lua files.
- `dfde79b41b2f0438e221731c6bbfc1979c44ed19` — removed the temporary `2.0.15-dev` validation workflow; runtime files unchanged from `a6d7ca70...`.
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
- `Outfitter.toc` owns the development version: `## Title: Outfitter-dev`, `## Version: 2.0.19-dev`. `locales/enUS.lua` reads that version through `GetAddOnMetadata("Outfitter", "Version")`; the old hardcoded upstream `1.4` display value is removed.
- P1 ClassicAPI observation/identity bridge plus initialization/preflight hardening and the minimap drag-state fix are implemented and user-verified.
- P2 runtime item identity is implemented at `2143a0cd29cc50a8e52d45040adacb299bf133cd`: transient GUID associations, GUID-indexed live items, exact-match preference, and legacy fallback hydration. It is user-accepted after successful normal/rapid outfit switching, manual equipment changes, pfUI character-slot flyout changes, reload persistence, and unchanged SavedVariables schema. Bank-open matching, focused partial/special-outfit rechecks, and a true same-legacy-identity duplicate-instance case remain explicit validation debt.
- P3 slice 1 is implemented, compiler-checked, and user-accepted. Executor logic is `5b2f20a93a3e1e743ff6f5a7ae39739928f7aa5e`; the exact accepted runtime/code head is `026bd1164d817dd6e4775f76df40dd293b2492fa`, version `0.1.1-dev`. Repeated one-slot swaps between the unenchanted and 1% haste Gauntlets of the Righteous Champion passed in both directions, multiple other set swaps passed, manual character-screen equipment changes remained external/manual, and the preserved full-set/multi-slot path remained healthy. The UI correctly reports `0.1.1-dev` in both the addon list and Outfitter's character-screen title/pop-out.
- `2.0.8-dev` acknowledgement sequencing was partially runtime-tested: some sets were near-instant via legacy fallback, while direct-path sets visibly equipped piece-by-piece at roughly ~0.1s per slot. No Lua error was reported, but the added cadence was considered unnecessary after ClassicAPI re-review.
- `2.0.9-dev` is implemented, compiler-checked, and user-accepted at exact runtime/code head `0e2ec6fbea2a4f0fda70dbdf13e3f9c98b4df3b9`. It replaces the acknowledgement wait with full-list prevalidation plus immediate direct burst for the same narrow safe case. Runtime result: swaps are essentially immediate and feel like old Outfitter; occasional individual-slot visual lag self-resolves correctly; no issue was reported.
- `2.0.10-dev` is implemented, compiler-checked, and user-accepted at exact runtime/code head `1c7accbfc4325486c48604e56ee19a51430ad712`. Exact reciprocal ring swaps passed repeatedly with no observed bag transit; manual swapping and config-editor swapping also remained healthy.
- `2.0.11-dev` is implemented, compiler-checked, and user-accepted at exact runtime/code head `9353beaa09498e318a1a174984cbdd270a18cea2`. The exact one-way ring/trinket paired-slot rotation with a normal-bag replacement worked without reported errors.
- `2.0.17-dev` performance delta is user-tested at exact runtime/code head `cec8bf4e3421f2b42f5486860af0141ef8719493`: the client hitch remains but is noticeably shorter than `2.0.16-dev`, validating per-frame coalescing of legacy inventory reconciliation as a real performance improvement.
- `2.0.18-dev` is implemented, canonical-Lua-5.0.3 compiler-checked, and user-accepted at exact runtime/code head `de0ddd8468dab5d27388ab178cc4af432ed5ec78`. A visible-armour-only RP outfit correctly left rings untouched across full-set -> RP -> different-full-set -> RP transitions, and interacting with an unticked ring slot did not silently add it to the RP outfit.

## Static / Automated Checks
- Imported runtime Lua/XML/localization files were verified content-identical to Cosmin's inspected head blobs; project metadata/docs are the intentional differences.
- XML addon-local texture references were checked and the required BLP assets imported.
- `Bindings.xml` was verified upstream and imported.
- Legacy outfit stack, equipment update path, paperdoll hook, tooltip parsing, cursor swap path, and timer/throttle path were inspected.
- ClassicAPI equipment-set, item GUID/location, explicit equipment-swap, and equipment-change event facilities were inspected.
- P4 read-only audit inspected current Riding/aura/form/Dining event, tooltip and update paths plus pinned ClassicAPI state/aura/form facilities. Verified direct capabilities: descriptor-backed `IsMounted()`, `C_UnitAuras`/`AuraUtil` name/icon/spell data, descriptor-backed `GetShapeshiftFormID()`, and dedicated `UPDATE_SHAPESHIFT_FORM`. `IsSwimming()` also exists but does not justify adding a Swimming outfit.
- pfUI's ClassicAPI Equipment Manager and paperdoll flyout module were inspected.
- Historical P1 diff review confirmed the original runtime delta was limited to the then-separate `OutfitterClassicAPI.lua`, its TOC entry, and small event registration/callback insertions in `Outfitter.lua`.
- `2.0.19-dev` deliberately reverses that temporary split: the ClassicAPI namespace is concatenated into `Outfitter.lua`. Canonical Lua 5.0.3 compilation passes after consolidation, so top-level local pressure does not require a second runtime logic file.
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
- Canonical Lua 5.0.3 validation passed all 8 runtime Lua files for `2.0.18-dev` in GitHub Actions run `36230875432` on validation commit `f1b653605815e2442b67f24ea19592860ef45d8d`. Because `VanillaTemplate` is private and the Outfitter Actions token cannot cross-checkout it, the exact canonical `tools/lua50` files were temporarily copied into the validation commit, run unchanged, then removed at `7171d295e9711c9a94ee5f75b5bff5b041be15ca`. Runtime files exactly match code head `de0ddd8468dab5d27388ab178cc4af432ed5ec78`.
- Canonical Lua 5.0.3 validation passed all 7 runtime Lua files for `2.0.19-dev` in GitHub Actions run `36238242344` on validation commit `53cdecd54f4ce24a8e90c3d90ee41c4d5e84e3bc`. The exact canonical checker bundle was temporarily restored, pointed at `Outfitter.lua` plus the six `locales/` files, then removed at `0969b1d395d5787e2d6f35a6da34e645c46386d0`. Runtime files exactly match code head `c83967e6dfc9f6a174e29d5463ccc8d3c3b648bf`.
- Canonical Lua 5.0.3 validation passed all 7 runtime Lua files for `2.0.20-dev` in GitHub Actions run `36239656403` on validation commit `3b0ec324af13288aaf08401c276160ace98aa219`. The same canonical checker tree and temporary workflow used for `2.0.19-dev` were restored unchanged and removed immediately afterward at `e4cc0fe1ec58e7f143802fc94e612b949b5691a3`. Runtime files exactly match code head `1cbac5b2dc505a7d04266628ce597c76c0877e86`.
- Canonical Lua 5.0.3 validation passed all 7 runtime Lua files for `2.0.24-dev` in GitHub Actions run `36243630264` on validation commit `c0aacafeaef49d3e5ab6d59b8161868d22982c68`. The unchanged canonical checker bundle was temporarily restored and removed at `3878eec20066db8956995f556bd28b8d949f2fe5`; runtime Lua files exactly match code head `c81bf220ca90ebe65f57ba89795c51d2a491e1ba`. XML changes were separately scope-reviewed; no Lua automatic-state/timing code changed.
- Canonical Lua 5.0.3 validation passed all 7 runtime Lua files for `2.0.25-dev` in GitHub Actions run `36252030694` on validation commit `dc6d6ca2825ee93ef84a0e029df77c3664a41d11`. The unchanged checker bundle was removed again at `3387da615b0bfa70e9cd26635be69a12408916be`; runtime Lua files exactly match code head `f998bdd9b474bd46fbc42f749896a9a69a8bad59`. The only Lua delta is `Outfitter_cMaxDisplayedItems` 14->15.
- Canonical Lua 5.0.3 validation passed all 7 runtime Lua files for `2.0.26-dev` in GitHub Actions run `36252638863` on validation commit `6fbd7a67d3cf3fc1c0c9dc585e9661a41b1e4d60`. The unchanged checker bundle was removed again at `8f38a0f5484895bd6de6a487b75e5dc74d1d1626`; runtime Lua files exactly match code head `c6fffcfd1cc6c6699305408fad8451cb248b5be0`. The Lua delta is localization strings only.
- No static/compiler inspection is being counted as an in-game test.

## Current Issues
- P1 is currently passing in-game after a clean SavedVariables reset.
- P2's runtime GUID identity/matching delta is compiler-checked and user-accepted. Normal/rapid switching, manual changes, pfUI character-slot flyout changes, reload persistence, and unchanged SavedVariables schema pass. Bank-open matching, focused partial/special-outfit rechecks, and a true same-legacy-identity duplicate-instance case remain documented validation debt; P3 is now unblocked.
- The original pre-existing Outfitter SavedVariables produced malformed/blank outfit names and odd disabled states. Deleting those SavedVariables fixed the problem; the old file is no longer available, so migration compatibility with that unknown prior schema cannot be diagnosed or claimed.
- The earlier pre-initialization settings nil failures and repeated minimap-drag timer failure are fixed and user-verified not to recur in the tested setup.
- Legacy Outfitter globally replaces `PaperDollItemSlotButton_OnClick`, creating a future coexistence risk with pfUI and other paperdoll addons.
- P3 slices 1–4 physical execution are user-accepted through `2.0.11-dev`. Safe public-API direct coverage now includes single exact replacements, independent normal-bag multi-replacements, exact reciprocal paired-slot exchanges, and the exact one-way ring/trinket rotation with bag replacement. Explicit unequip, weapon-specific multi-step rotations, bank, moved/ambiguous source, mixed unsupported, and no-GUID cases remain legacy. The `2.0.13-dev` timing experiment is rejected due to runtime hitching; `2.0.14-dev` restores accepted timing behavior.
- Legacy equipment updates still use the 1.5-second throttle and 0.25-second OnUpdate retry path; neither timing constraint has been relaxed yet.
- The inherited unchecked-slot outfit-editor bug is fixed and user-accepted in `2.0.18-dev`: `Outfitter_UpdateOutfitFromInventory` updates only slots whose checkbox is checked and not unknown. Unticked slots remain outside the outfit and inherit the last state supplied by another owning outfit or manual state.
- Automatic aura-state detection still performs a broad helpful-aura scan and may read hidden buff-tooltip text on each `PLAYER_AURAS_CHANGED`. The P4 audit verified direct ClassicAPI replacements for Riding state, aura name/icon data and current shapeshift form; item-stat/BOE tooltip consumers remain separate and must not be removed wholesale. `2.0.20-dev`/`2.0.21-dev` expose those ClassicAPI facts behind unused bridge helpers only; no automatic-state behavior has changed yet.
- `2.0.20-dev` failed the structural runtime smoke: clicking `OutfitterButton` produced `Outfitter_ToggleOutfitterFrame` nil because `Outfitter.lua` had not completed execution. `2.0.21-dev` is the narrow loader-path correction: locale files remain under `locales/`, but the TOC now uses backslashes. User runtime testing confirms the correction passes. No Lua file changed from the compiler-checked `2.0.20-dev` bytes.
- `2.0.22-dev` changes only `Outfitter.xml` header layout plus the TOC version: inner title anchor `LEFT`/`TOPLEFT` at `(42,-36)`; `New Outfit` is 95x25 and anchors `RIGHT`/`TOPRIGHT` at `(-14,-36)`. User screenshots accept the horizontal spacing and button size, but request both controls lower/vertically centred.
- `2.0.24-dev` keeps those X positions and the 95x25 button, moves both header centres to y=-43, hides the Outfits-page-only `ButtonBarBackground` without removing its anchor object (so list/scroll geometry stays unchanged), renames the tab to `Outfits`, and adds a dedicated outer-frame `v<version>` label sourced from TOC metadata. `2.0.23-dev` was superseded before runtime because static review caught an invalid literal `\\n` in `locales/enUS.lua`.
- `2.0.24-dev` is user-accepted for all requested chrome checks. `2.0.25-dev` is UI-only and increases the Outfits viewport from 14 to 15 rows using the freed bottom space; list top/header/tab geometry is unchanged, and the scrollbar/trench is extended downward in lockstep.
- `2.0.25-dev` was not yet runtime-confirmed before `2.0.26-dev` superseded it. `2.0.26-dev` contains the same 15-row viewport plus About-credit text/layout changes only; no outfit, P4, Riding, or timing behavior changed.
- Shared `C_EquipmentSet` state must not be used as hidden Outfitter storage.
- External pfUI/ItemRack/manual swaps must not be mistaken for Outfitter-owned transactions.
- Swimming requires an explicit design because it is absent from this imported baseline.

## Testing

### Last Runtime Test
- Version/runtime head: `2.0.26-dev`, `c6fffcfd1cc6c6699305408fad8451cb248b5be0`.
- Passed: the 15-row Outfits viewport is present, the list still starts at the accepted top position, and the extended scrollbar/trench behaves correctly without colliding with the tabs.
- Passed: the accepted `2.0.24-dev` header/tab/version chrome remains correct.
- Passed: About shows `About Outfitter`, `Originally designed and written by John Stephen`, and `Updated and maintained by Revenga`.
- Passed: Gaia is included in Beta Testers; existing tester names, Special Thanks credits, and guild URLs remain present.
- Passed: the duplicate About-page `Outfitter <version>` line is gone.
- Result: `2.0.26-dev` UI/content follow-up accepted.

### Next Runtime Test
- After the next P4 implementation slice, test Riding automatic-outfit activation/deactivation on the ClassicAPI path and verify the existing Turtle/legacy aura-tooltip Riding fallback still behaves unchanged when that capability path is unavailable.
- Keep the residual outfit-change hitch as profiling debt; do not resume speculative timing changes without instrumentation.
- P3 direct execution remains intentionally bounded at the accepted safe public-API cases; unsupported weapon/unequip/bank/mixed cases retain legacy fallback.

## Planned / Next Work
- **P0 — baseline/workflow:** complete.
- **P1 — ClassicAPI observation bridge:** complete and user-verified.
- **P2 — item identity modernization:** implemented, compiler-checked, and user-accepted at `2143a0cd29cc50a8e52d45040adacb299bf133cd`. Normal/rapid swaps, manual changes, pfUI slot-flyout changes, reload persistence, and unchanged SavedVariables schema pass. Bank-open matching, focused partial/special rechecks, and true exact-duplicate physical-instance testing remain validation debt.
- **P3 — cursor-free executor/performance:** accepted at the current safe boundary through `2.0.18-dev`. Physical-executor slices 1–4 are user-accepted; `2.0.17-dev` materially shortened the hitch by coalescing legacy inventory reconciliation once per frame; `2.0.18-dev` restores correct partial-outfit slot ownership. The rejected `2.0.12/2.0.13` timing design stays rejected. Residual hitching is profiling debt, not a reason for more speculative timing changes.
- **P4 — automatic-state modernization:** read-only capability audit complete. `2.0.20-dev` implements the first preservation-first bridge inside the existing `OutfitterClassicAPI` namespace: Riding state, helpful-aura name/icon/spell data, current shapeshift form ID, and `UPDATE_SHAPESHIFT_FORM` capability are exposed but not consumed. The structural gate passed on `2.0.21-dev`; the UI/content follow-ups through `2.0.26-dev` are user-accepted. Resume with Riding as the first single-consumer integration while preserving the existing Turtle/legacy fallback. Do not add Swimming or broaden the existing form/special-outfit set.
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
- Remove or weaken the existing Turtle/legacy Riding fallback before the ClassicAPI Riding path is runtime-proven.
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
Implement the first P4 single-consumer slice for Riding only: use `OutfitterClassicAPI.GetRidingState()` when available to drive the existing Riding special-outfit state, while retaining the current aura/tooltip Riding heuristic as the Turtle/non-capability fallback and validation protection. Preserve the existing special-outfit ID, stack/priority semantics, and activation/deactivation behavior. Do not yet consume the helpful-aura or shapeshift bridge, do not add Swimming or Turtle-only Tree/Swift Travel behavior, and do not touch Dining health/mana semantics, zone behavior, the residual hitch, 1.5-second throttle, or 0.25-second equipment retry loop.
