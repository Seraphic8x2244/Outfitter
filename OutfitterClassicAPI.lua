-- ClassicAPI integration boundary for Outfitter.
--
-- Keep extension-specific item identity and event capability checks here so
-- the legacy outfit model and SavedVariables do not become coupled to
-- ClassicAPI implementation details.

OutfitterClassicAPI = {};

local gOutfitterClassicAPI_RuntimeItemGUIDs = setmetatable({}, {__mode = "k"});
local gOutfitterClassicAPI_OwnedEquipmentChange = nil;

function OutfitterClassicAPI.SetRuntimeItemGUID(pItem, pItemGUID)
	if not pItem then
		return;
	end

	gOutfitterClassicAPI_RuntimeItemGUIDs[pItem] = pItemGUID;
end

function OutfitterClassicAPI.GetRuntimeItemGUID(pItem)
	if not pItem then
		return nil;
	end

	return gOutfitterClassicAPI_RuntimeItemGUIDs[pItem];
end

function OutfitterClassicAPI.IsAvailable()
	return type(C_Item) == "table"
	and type(C_Item.GetItemGUID) == "function"
	and type(C_Item.GetItemLocation) == "function";
end

function OutfitterClassicAPI.HasPlayerEquipmentChangedEvent()
	if not OutfitterClassicAPI.IsAvailable() then
		return false;
	end

	if C_EventUtils
	and C_EventUtils.IsEventValid then
		return C_EventUtils.IsEventValid("PLAYER_EQUIPMENT_CHANGED");
	end

	-- ClassicAPI versions which provide the item identity API used above also
	-- provide this event. The C_EventUtils check is preferred when available.
	return true;
end

function OutfitterClassicAPI.HasBagUpdateDelayedEvent()
	if not OutfitterClassicAPI.IsAvailable() then
		return false;
	end
	
	if C_EventUtils
	and C_EventUtils.IsEventValid then
		return C_EventUtils.IsEventValid("BAG_UPDATE_DELAYED");
	end
	
	-- Supported ClassicAPI builds provide this coalesced bag-change event.
	return true;
end


function OutfitterClassicAPI.GetItemGUID(pItemLocation)
	if not OutfitterClassicAPI.IsAvailable()
	or not pItemLocation then
		return nil;
	end

	return C_Item.GetItemGUID(pItemLocation);
end

function OutfitterClassicAPI.GetInventoryItemGUID(pSlotID)
	if not pSlotID then
		return nil;
	end

	return OutfitterClassicAPI.GetItemGUID({equipmentSlotIndex = pSlotID});
end

function OutfitterClassicAPI.GetBagItemGUID(pBagID, pSlotIndex)
	if pBagID == nil
	or not pSlotIndex then
		return nil;
	end

	return OutfitterClassicAPI.GetItemGUID({bagID = pBagID, slotIndex = pSlotIndex});
end

function OutfitterClassicAPI.GetItemLocation(pItemGUID)
	if not OutfitterClassicAPI.IsAvailable()
	or not pItemGUID then
		return nil;
	end

	return C_Item.GetItemLocation(pItemGUID);
end

function OutfitterClassicAPI.CanEquipItemToSlot()
	return OutfitterClassicAPI.IsAvailable()
	and type(C_Item.EquipItemByName) == "function";
end

local function OutfitterClassicAPI_StartOwnedEquipmentChange(pItemGUID, pSlotID)
	gOutfitterClassicAPI_OwnedEquipmentChange =
	{
		SlotID = pSlotID,
		ItemGUID = pItemGUID,
	};
	
	C_Item.EquipItemByName(pItemGUID, pSlotID);
end

function OutfitterClassicAPI.EquipItemToSlot(pItem, pSlotID)
	if not pItem
	or not pSlotID
	or not OutfitterClassicAPI.CanEquipItemToSlot() then
		return false;
	end
	
	-- Vanilla cannot equip directly from bank storage. Leave bank-sourced
	-- changes on Outfitter's existing bank-aware path.
	if pItem.BagIndex
	and (pItem.BagIndex < 0 or pItem.BagIndex > NUM_BAG_SLOTS) then
		return false;
	end
	
	local vItemGUID = OutfitterClassicAPI.GetRuntimeItemGUID(pItem);
	
	if not vItemGUID then
		return false;
	end
	
	OutfitterClassicAPI_StartOwnedEquipmentChange(vItemGUID, pSlotID);
	return true;
end

function OutfitterClassicAPI.SwapEquippedItems(pItem1, pTargetSlotID1, pItem2, pTargetSlotID2)
	if not pItem1
	or not pItem2
	or not pTargetSlotID1
	or not pTargetSlotID2
	or not pItem1.SlotName
	or not pItem2.SlotName
	or not OutfitterClassicAPI.CanEquipItemToSlot() then
		return false;
	end
	
	local vSourceSlotID1 = GetInventorySlotInfo(pItem1.SlotName);
	local vSourceSlotID2 = GetInventorySlotInfo(pItem2.SlotName);
	
	-- This slice handles only a true reciprocal paperdoll swap: item 1 is
	-- currently in item 2's target slot and vice versa. One atomic swap then
	-- completes both requested changes without any intermediate location state.
	if vSourceSlotID1 ~= pTargetSlotID2
	or vSourceSlotID2 ~= pTargetSlotID1 then
		return false;
	end
	
	local vItemGUID1 = OutfitterClassicAPI.GetRuntimeItemGUID(pItem1);
	local vItemGUID2 = OutfitterClassicAPI.GetRuntimeItemGUID(pItem2);
	
	if not vItemGUID1
	or not vItemGUID2
	or OutfitterClassicAPI.GetInventoryItemGUID(vSourceSlotID1) ~= vItemGUID1
	or OutfitterClassicAPI.GetInventoryItemGUID(vSourceSlotID2) ~= vItemGUID2 then
		return false;
	end
	
	C_Item.EquipItemByName(vItemGUID1, pTargetSlotID1);
	return true;
end

function OutfitterClassicAPI.RotatePairedAccessoryWithBagItem(pEquippedItem, pTargetSlotID, pBagItem, pBagTargetSlotID)
	if not pEquippedItem
	or not pTargetSlotID
	or not pBagItem
	or not pBagTargetSlotID
	or not pEquippedItem.SlotName
	or pBagItem.BagIndex == nil
	or not pBagItem.BagSlotIndex
	or pBagItem.BagIndex < 0
	or pBagItem.BagIndex > NUM_BAG_SLOTS
	or not OutfitterClassicAPI.CanEquipItemToSlot() then
		return false;
	end
	
	local vSourceSlotID = GetInventorySlotInfo(pEquippedItem.SlotName);
	local vFinger0SlotID = GetInventorySlotInfo("Finger0Slot");
	local vFinger1SlotID = GetInventorySlotInfo("Finger1Slot");
	local vTrinket0SlotID = GetInventorySlotInfo("Trinket0Slot");
	local vTrinket1SlotID = GetInventorySlotInfo("Trinket1Slot");
	local vIsSupportedPair =
		(vSourceSlotID == vFinger0SlotID and pTargetSlotID == vFinger1SlotID)
		or (vSourceSlotID == vFinger1SlotID and pTargetSlotID == vFinger0SlotID)
		or (vSourceSlotID == vTrinket0SlotID and pTargetSlotID == vTrinket1SlotID)
		or (vSourceSlotID == vTrinket1SlotID and pTargetSlotID == vTrinket0SlotID);
	
	-- The bag replacement must fill the equipped item's original slot. That
	-- makes the two direct operations independent: the paperdoll move cannot
	-- relocate the later bag source, and the bag swap then parks the displaced
	-- unwanted accessory in the bag slot it vacates.
	if not vIsSupportedPair
	or pBagTargetSlotID ~= vSourceSlotID then
		return false;
	end
	
	local vEquippedGUID = OutfitterClassicAPI.GetRuntimeItemGUID(pEquippedItem);
	local vBagGUID = OutfitterClassicAPI.GetRuntimeItemGUID(pBagItem);
	
	if not vEquippedGUID
	or not vBagGUID
	or OutfitterClassicAPI.GetInventoryItemGUID(vSourceSlotID) ~= vEquippedGUID
	or OutfitterClassicAPI.GetBagItemGUID(pBagItem.BagIndex, pBagItem.BagSlotIndex) ~= vBagGUID then
		return false;
	end
	
	C_Item.EquipItemByName(vEquippedGUID, pTargetSlotID);
	C_Item.EquipItemByName(vBagGUID, pBagTargetSlotID);
	return true;
end



function OutfitterClassicAPI.EquipItemsToSlots(pChanges)
	if not pChanges
	or table.getn(pChanges) < 2
	or not OutfitterClassicAPI.CanEquipItemToSlot()
	or gOutfitterClassicAPI_OwnedEquipmentChange then
		return false;
	end
	
	local vValidatedChanges = {};
	local vUsedSources = {};
	local vUsedSlots = {};
	
	-- Validate the complete burst before sending anything. This direct path is
	-- deliberately limited to exact items which are still in distinct normal
	-- bag slots. If any source has moved or become ambiguous, execute nothing
	-- here and let Outfitter fall back to its legacy executor.
	for _, vChange in pChanges do
		local vItem = vChange.Item;
		
		if not vItem
		or not vChange.SlotID
		or vItem.BagIndex == nil
		or not vItem.BagSlotIndex
		or vItem.BagIndex < 0
		or vItem.BagIndex > NUM_BAG_SLOTS then
			return false;
		end
		
		local vItemGUID = OutfitterClassicAPI.GetRuntimeItemGUID(vItem);
		
		if not vItemGUID
		or OutfitterClassicAPI.GetBagItemGUID(vItem.BagIndex, vItem.BagSlotIndex) ~= vItemGUID then
			return false;
		end
		
		local vSourceKey = tostring(vItem.BagIndex)..":"..tostring(vItem.BagSlotIndex);
		
		if vUsedSources[vSourceKey]
		or vUsedSlots[vChange.SlotID] then
			return false;
		end
		
		vUsedSources[vSourceKey] = true;
		vUsedSlots[vChange.SlotID] = true;
		
		table.insert(vValidatedChanges,
		{
			SlotID = vChange.SlotID,
			ItemGUID = vItemGUID,
		});
	end
	
	-- All sources are independent bag slots, so these atomic bag->paperdoll
	-- swaps can be issued back-to-back. No later operation needs to re-resolve
	-- a source changed by an earlier swap.
	for _, vChange in vValidatedChanges do
		C_Item.EquipItemByName(vChange.ItemGUID, vChange.SlotID);
	end
	
	return true;
end

function OutfitterClassicAPI.ObservePlayerEquipmentChanged(pSlotID)
	local vEquipmentChange = gOutfitterClassicAPI_OwnedEquipmentChange;
	
	if not vEquipmentChange
	or not pSlotID
	or vEquipmentChange.SlotID ~= pSlotID then
		return nil;
	end
	
	local vMatched = OutfitterClassicAPI.GetInventoryItemGUID(pSlotID) == vEquipmentChange.ItemGUID;
	gOutfitterClassicAPI_OwnedEquipmentChange = nil;
	
	return vMatched;
end
