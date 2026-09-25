-- ClassicAPI integration boundary for Outfitter.
--
-- Keep extension-specific item identity and event capability checks here so
-- the legacy outfit model and SavedVariables do not become coupled to
-- ClassicAPI implementation details.

OutfitterClassicAPI = {};

local gOutfitterClassicAPI_RuntimeItemGUIDs = setmetatable({}, {__mode = "k"});
local gOutfitterClassicAPI_OwnedEquipmentChange = nil;
local gOutfitterClassicAPI_EquipmentChangeSequence = nil;

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
	or not OutfitterClassicAPI.CanEquipItemToSlot()
	or gOutfitterClassicAPI_EquipmentChangeSequence then
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

function OutfitterClassicAPI.BeginEquipmentChangeSequence(pChanges)
	if not pChanges
	or table.getn(pChanges) < 2
	or not OutfitterClassicAPI.CanEquipItemToSlot()
	or gOutfitterClassicAPI_OwnedEquipmentChange
	or gOutfitterClassicAPI_EquipmentChangeSequence then
		return false;
	end
	
	local vSequenceChanges = {};
	
	for _, vChange in pChanges do
		local vItem = vChange.Item;
		
		-- Slice 2 deliberately sequences only normal-bag sources. Equipped
		-- sources can move as an earlier swap completes, and bank/empty-slot
		-- changes retain the proven legacy executor.
		if not vItem
		or not vChange.SlotID
		or vItem.BagIndex == nil
		or vItem.BagIndex < 0
		or vItem.BagIndex > NUM_BAG_SLOTS then
			return false;
		end
		
		local vItemGUID = OutfitterClassicAPI.GetRuntimeItemGUID(vItem);
		
		if not vItemGUID then
			return false;
		end
		
		table.insert(vSequenceChanges,
		{
			SlotID = vChange.SlotID,
			ItemGUID = vItemGUID,
		});
	end
	
	gOutfitterClassicAPI_EquipmentChangeSequence =
	{
		Changes = vSequenceChanges,
		Index = 1,
	};
	
	local vFirstChange = vSequenceChanges[1];
	OutfitterClassicAPI_StartOwnedEquipmentChange(vFirstChange.ItemGUID, vFirstChange.SlotID);
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
	
	local vSequence = gOutfitterClassicAPI_EquipmentChangeSequence;
	
	if vSequence then
		if not vMatched then
			-- Do not guess after an owned swap failed to land as requested.
			-- Reconciliation still runs in Outfitter.lua and the remaining
			-- desired state can be handled by the normal update path.
			gOutfitterClassicAPI_EquipmentChangeSequence = nil;
		else
			vSequence.Index = vSequence.Index + 1;
			
			local vNextChange = vSequence.Changes[vSequence.Index];
			
			if vNextChange then
				OutfitterClassicAPI_StartOwnedEquipmentChange(vNextChange.ItemGUID, vNextChange.SlotID);
			else
				gOutfitterClassicAPI_EquipmentChangeSequence = nil;
			end
		end
	end
	
	return vMatched;
end
