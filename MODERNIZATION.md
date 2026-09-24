# Outfitter Modernization Contract

## Scope

Modernize CosminPOP/Outfitter incrementally for WoW 1.12.1 using
brues-code/ClassicAPI. Preserve Outfitter as Outfitter: named outfits,
complete/partial/accessory outfits, automatic/situational outfits, stack
priority/layering, keybinds, special outfits and manual-change behaviour.

Do not turn the project into ItemRack and do not duplicate pfUI's Equipment
Manager UI or its flat C_EquipmentSet model.

Reference baseline:

- CosminPOP/Outfitter master: `4587638ae5bd10eb9bc83bbae87a092e4b892d94`
- ClassicAPI inspected: `fde3beca9dba18e7327802eb094b5bff81f39d47`
- brues-code/pfUI master inspected during initial research.

## Legacy architecture to preserve

- Per-character SavedVariables remain rooted at `gOutfitter_Settings`.
- `gOutfitter_Settings.Outfits` remains the authoritative persisted outfit
  model.
- `gOutfitter_OutfitStack` is the runtime layering model.
- Compiling the stack is bottom-to-top; a higher outfit overrides only the
  slots it defines.
- Complete outfits clear the stack. Partial outfits replace Partial and
  Accessory layers rather than flattening all active outfits.
- Temporary unnamed outfits preserve manual equipment changes.
- Special outfits use the same stack. Existing ordering such as Argent Dawn
  below Riding is product behaviour, not an implementation accident.
- Outfit bindings and automatic/situational activation remain Outfitter
  features.

## Cosmin/Turtle delta

Cosmin's meaningful runtime changes after the imported legacy baseline are
confined to Riding detection. The fork widened mount-buff tooltip matching so
Turtle WoW dynamic-speed mounts, Riding text and "Slow and steady..." are
recognized. Preserve the resulting behaviour while replacing tooltip-text
detection with a stronger capability when ClassicAPI exposes one.

## Legacy mechanisms targeted for replacement

- Global replacement of `PaperDollItemSlotButton_OnClick`.
- Cursor-driven equipment swaps using `PickupInventoryItem`,
  `PickupContainerItem` and `EquipCursorItem`.
- The 1.5-second swap throttle plus 0.25-second OnUpdate retry loop where an
  event-driven transaction can provide the real completion boundary.
- Item-instance matching derived only from item-link fields when ClassicAPI
  can identify the exact physical item by GUID.
- Hidden-tooltip parsing when ClassicAPI provides the underlying fact
  directly.
- Broad inventory refresh work where `PLAYER_EQUIPMENT_CHANGED(slot,...)`
  provides a precise signal.

Do not remove tooltip/stat parsing wholesale until each consumer has a verified
replacement; some smart-outfit/stat features may still require tooltip-derived
data on 1.12.1.

## ClassicAPI facilities

Primary facilities for this project:

- `C_Item.GetItemGUID(itemLocation)` for exact per-instance identity.
- `C_Item.GetItemLocation(itemGUID)` for reverse lookup.
- Explicit-slot ClassicAPI item swap/equip facilities for cursor-free physical
  execution where appropriate.
- `PLAYER_EQUIPMENT_CHANGED(equipmentSlot, hasCurrent)` for precise
  event-driven paperdoll changes.
- `C_EquipmentSet.*` for named GUID-backed flat sets, ignored-slot semantics,
  missing/inventory state and atomic set swaps.
- `EQUIPMENT_SWAP_PENDING` / `EQUIPMENT_SWAP_FINISHED` for transactions
  performed through `C_EquipmentSet.UseEquipmentSet`.
- `EQUIPMENT_SETS_CHANGED` for shared set-store changes.

ClassicAPI equipment sets are not automatically Outfitter's authoritative data
model. Outfitter's stack can compile several overlapping outfits into a state
that is richer than a single flat set.

## pfUI coexistence

brues-code/pfUI has its own ClassicAPI-backed Equipment Manager. It:

- displays and edits the same global per-character `C_EquipmentSet` store;
- adds its own sidecar, ignored-slot overlays and flyout buttons to the
  character paperdoll;
- listens to ClassicAPI equipment-set and equipment-change events;
- uses cursor pickup/drop for its per-slot flyout swaps.

Compatibility rules:

- Do not create hidden/internal C_EquipmentSet records unless they are clearly
  namespaced and intentionally visible/interoperable with pfUI.
- Prefer an Outfitter-owned execution adapter over using the shared equipment
  set namespace as private storage.
- Do not disable, replace or mutate pfUI automatically.
- Treat pfUI, ItemRack and manual swaps as external equipment changes when no
  Outfitter transaction owns the change; preserve the temporary-outfit
  behaviour rather than fighting the user's action.
- Avoid global function replacement on paperdoll handlers. Use additive hooks
  or Outfitter-owned UI.
- Keep Outfitter's UI purpose distinct: outfit composition, layering,
  automatic states and priorities rather than another flat-set manager.
- If Outfitter later invokes C_EquipmentSet save operations, clear the
  process-global ignored-slot-for-save flags before and after the operation.

## Staged plan

### P0 — Baseline and workflow

Import the Cosmin runtime baseline, establish `dev`, development metadata,
this contract, `dev_rulebook.md` and `DEV_PROGRESS.md`.

### P1 — ClassicAPI observation bridge

Add the smallest ClassicAPI adapter without changing swap semantics. Prove
exact item GUID/location access and route `PLAYER_EQUIPMENT_CHANGED` through
Outfitter's existing inventory reconciliation. Preserve the legacy
SavedVariables representation.

### P2 — Item identity modernization

Augment runtime item records with ClassicAPI GUID identity and prefer it when
matching physical items. Maintain migration/fallback matching for existing
SavedVariables so old outfits continue to load.

### P3 — Cursor-free executor

Replace Outfitter-controlled cursor swaps with ClassicAPI's exact-item,
explicit-slot swap path. Add explicit Outfitter transaction ownership and use
real equipment-change completion signals. Remove the speculative 1.5-second
throttle only after runtime tests prove the replacement boundary.

### P4 — Automatic-state modernization

Replace tooltip parsing and broad polling for Riding, auras, forms, swimming
and similar states only where ClassicAPI exposes reliable facts. Preserve
legacy fallback where a fact remains unavailable. The imported Cosmin source
does not currently contain a general Swimming special outfit, so Swimming is a
target behaviour to design/restore explicitly rather than falsely treating it
as already implemented in this baseline.

### P5 — Paperdoll/pfUI coexistence

Remove the global `PaperDollItemSlotButton_OnClick` replacement. Preserve
Outfitter QuickSlots only through additive integration that coexists with
pfUI's Equipment Manager popouts/overlays. Test with pfUI Equipment Manager
enabled and disabled.

### P6 — Optional C_EquipmentSet interoperability

Only after the Outfitter model and executor are stable, decide whether named
Outfitter outfits should optionally mirror/import/export ClassicAPI equipment
sets. Keep this explicit; never silently make the shared pfUI set store
Outfitter's private backing database.

### P7 — Cleanup

Remove legacy cursor, timer, polling and tooltip paths only after the exact
replacement has been runtime-proven. Preserve SavedVariables migration and
stable user behaviour.

## First implementation slice

Create a small ClassicAPI adapter and register
`PLAYER_EQUIPMENT_CHANGED` as a precise additional observation source,
feeding the existing Outfitter inventory-reconciliation path. Add exact item
GUID/location helpers, but do not change the physical swap executor yet.

This first slice should prove that ClassicAPI can improve observation and item
identity without changing outfit selection, stack semantics, SavedVariables,
automatic outfits or cursor-swap behaviour. Runtime-test it with manual gear
changes and with pfUI's Equipment Manager/flyout before proceeding to the
executor.
