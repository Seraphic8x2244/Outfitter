-- ClassicAPI integration boundary for Outfitter.
--
-- Keep extension-specific item identity and event capability checks here so
-- the legacy outfit model and SavedVariables do not become coupled to
-- ClassicAPI implementation details.

OutfitterClassicAPI = {};

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
