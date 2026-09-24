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
	
	-- P3 starts with one exact, explicit-slot swap at a time. Keep an
	-- Outfitter-owned marker for the matching PLAYER_EQUIPMENT_CHANGED
	-- acknowledgement; multi-change sequencing will build on this boundary
	-- after the single-change path is runtime-proven.
	gOutfitterClassicAPI_OwnedEquipmentChange =
	{
		SlotID = pSlotID,
		ItemGUID = vItemGUID,
	};
	
	C_Item.EquipItemByName(vItemGUID, pSlotID);
	return true;
end

function OutfitterClassicAPI.ObservePlayerEquipmentChanged(pSlotID)
	local vEquipmentChange = gOutfitterClassicAPI_OwnedEquipmentChange;
	
	if not vEquipmentChange
	or not pSlotID
	or vEquipmentChange.SlotID ~= pSlotID then
		return nil;
	end
	
	gOutfitterClassicAPI_OwnedEquipmentChange = nil;
	
	return OutfitterClassicAPI.GetInventoryItemGUID(pSlotID) == vEquipmentChange.ItemGUID;
end
