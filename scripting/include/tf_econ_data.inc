/**
 * [TF2] Econ Data
 * Functions to read item information from game memory.
 */

#if defined __tf_econ_data_included
	#endinput
#endif

#include <tf2_stocks>

#define __tf_econ_data_included

/**
 * Callback for `TF2Econ_GetItemList`.  Return `true` if the specified item definition index
 * should be added to the returned `ArrayList`.
 */
typedef ItemFilterCriteria = function bool(int defindex, any data);

/**
 * Returns true if there is an item corresponding to the given item definition index.
 */
native bool TF2Econ_IsValidItemDefinition(int defindex);

/**
 * Returns the item's name (corresponds to the "name" key).
 */
native bool TF2Econ_GetItemName(int defindex, char[] name, int maxlen);

/**
 * Returns the item's localization token name (corresponds to the "item_name" key).
 */
native bool TF2Econ_GetLocalizedItemName(int defindex, char[] name, int maxlen);

/**
 * Stores the item class name in the given buffer and returns true if given a valid item
 * definition, otherwise returns false.
 */
native bool TF2Econ_GetItemClassName(int defindex, char[] buffer, int maxlen);

/**
 * Returns the item's weapon slot for the given class, or -1 if the item definition or
 * item / class combination is not valid.
 */
native int TF2Econ_GetItemSlot(int defindex, TFClassType playerClass);

/**
 * Returns the given item's equipment region mask.  This mask can be and-tested with another
 * mask to determine if items conflict.
 */
native int TF2Econ_GetItemEquipRegionMask(int defindex);

/**
 * Returns the given item's equipment region groups as a bitfield.
 * 
 * Internally, this is called an EquipRegionBitMask, but for the sake of clarity it's been
 * renamed in this library to specify equip region groups.
 */
native int TF2Econ_GetItemEquipRegionGroupBits(int defindex);

/**
 * Stores the minimum and maximum item level range in the given cell references and
 * returns true for a valid item definition, otherwise returns false.
 */
native bool TF2Econ_GetItemLevelRange(int defindex, int &iMinLevel, int &iMaxLevel);

/**
 * Returns an `ArrayList` containing attribute defindex / value pairs corresponding to the given
 * item definition, or `null` if not a valid item definition.
 * 
 * This handle is owned by the calling plugin, so it should be `delete`d when not needed
 * anymore.
 */
native ArrayList TF2Econ_GetItemStaticAttributes(int defindex);

/**
 * Returns an arbiitrary string from an item definition's KeyValues structure.
 * You may use subkey notation ('/') to retrieve nested values.
 */
native void TF2Econ_GetItemDefinitionString(int defindex, const char[] key,
		char[] buffer, int maxlen, const char[] defaultValue = "");

/**
 * Returns an ArrayList containing all valid item definition indices.  If an ItemFilterCriteria
 * callback is passed in, the ArrayList only contains defindexes that the callback returned
 * `true` on.
 * 
 * This handle is owned by the calling plugin, so it should be `delete`d when not needed
 * anymore.
 */
native ArrayList TF2Econ_GetItemList(ItemFilterCriteria func = INVALID_FUNCTION, any data = 0);

/**
 * Returns true if the specified className was translated for the given player class.
 * The buffer is not modified if the className was not translated.
 * 
 * This is used for multiclass weapons -- if given a player class-specific classname,
 * this function returns false.
 */
native bool TF2Econ_TranslateWeaponEntForClass(char[] className, int maxlen,
		TFClassType playerClass);

/**
 * Returns true if the given loadout slot index has a name, false otherwise.
 */
native bool TF2Econ_TranslateLoadoutSlotIndexToName(int index, char[] buffer, int maxlen);

/**
 * Returns the loadout slot index for the given slot name, or -1 if not a valid slot.
 */
native int TF2Econ_TranslateLoadoutSlotNameToIndex(const char[] slotName);

/**
 * Returns the number of valid loadout slots.
 */
native int TF2Econ_GetLoadoutSlotCount();

/**
 * Returns true if there is an attribute corresponding to the given attribute definition index.
 */
native bool TF2Econ_IsValidAttributeDefinition(int defindex);

/**
 * Returns true if the attribute is considered hidden (corresponds to the "hidden" key).
 */
native bool TF2Econ_IsAttributeHidden(int defindex);

/** 
 * Returns true if the attribute is stored as an integer (corresponds to the "stored_as_integer"
 * key).
 * 
 * Not sure when this is actually used -- certain attributes such as
 * "mod max primary clip override" are flagged as true, but are float values when retrieved
 * via `TF2Econ_GetItemStaticAttributes()`.
 */
native bool TF2Econ_IsAttributeStoredAsInteger(int defindex);

/**
 * Stores the attribute name in the given buffer and returns true if given a valid attribute
 * definition, otherwise returns false.
 */
native bool TF2Econ_GetAttributeName(int defindex, char[] buffer, int maxlen);

/**
 * Stores the attribute class name in the given buffer and returns true if given a valid
 * attribute definition, otherwise returns false.
 */
native bool TF2Econ_GetAttributeClassName(int defindex, char[] buffer, int maxlen);

/**
 * Returns an arbiitrary string from an item attribute definition's KeyValues structure.
 * You may use subkey notation ('/') to retrieve nested values.
 */
native void TF2Econ_GetAttributeDefinitionString(int defindex, const char[] key,
		char[] buffer, int maxlen, const char[] defaultValue = "");

/**
 * Returns the attribute definition index for a given name, or -1 if the name does not
 * correspond to an attribute.
 */
native int TF2Econ_TranslateAttributeNameToDefinitionIndex(const char[] name);

/**
 * Stores the quality name in the given buffer and returns true if given a valid quality value,
 * otherwise returns false;
 */
native bool TF2Econ_GetQualityName(int quality, char[] buffer, int maxlen);

/**
 * Returns the quality value for a given name, or -1 if the name does not correspond to an item
 * quality.
 */
native int TF2Econ_TranslateQualityNameToValue(const char[] name, bool caseSensitive = true);

/**
 * Returns an ArrayList containing all valid quality values.
 * 
 * This handle is owned by the calling plugin, so it should be `delete`d when not needed
 * anymore.
 */
native ArrayList TF2Econ_GetQualityList();

/**
 * Stores the rarity name in the given buffer and returns true if given a valid rarity value,
 * otherwise returns false;
 * 
 * Note:  Rarity names returned by this value correspond to the localized "weapon grade" names,
 * but are completely different.  "Civilian Grade" corresponds to "common", "Freelance Grade" to
 * "uncommon", and so on.
 */
native bool TF2Econ_GetRarityName(int rarity, char[] buffer, int maxlen);

/**
 * Returns the rarity value for a given name, or -1 if the name does not correspond to an item
 * rarity.
 */
native int TF2Econ_TranslateRarityNameToValue(const char[] name, bool caseSensitive = true);

/**
 * Returns an ArrayList containing all valid rarity values.
 * 
 * This handle is owned by the calling plugin, so it should be `delete`d when not needed
 * anymore.
 */
native ArrayList TF2Econ_GetRarityList();

/**
 * Returns a StringMap containing all valid equip region names mapped to their equip region
 * group indices.
 */
native StringMap TF2Econ_GetEquipRegionGroups();

/**
 * Returns true if the given equip region name is valid, storing its equip region mask in the
 * given by-ref``mask` argument.
 */
native bool TF2Econ_GetEquipRegionMask(const char[] equipRegion, int &mask);

/**
 * Returns the address of the singleton CTFItemSchema (subclass of CEconItemSchema).
 * 
 * Here be dragons.
 */
native Address TF2Econ_GetItemSchemaAddress();

/**
 * Returns the address of the CEconItemDefinition for the item with the given definition index,
 * or Address_Null if not valid.
 * 
 * Here be dragons.
 */
native Address TF2Econ_GetItemDefinitionAddress(int defindex);

/**
 * Returns the address of the CEconItemAttributeDefinition for the attribute with the given
 * definition index, or Address_Null if not valid.
 * 
 * Here be dragons.
 */
native Address TF2Econ_GetAttributeDefinitionAddress(int defindex);

/**
 * Returns the address of the CEconItemRarityDefinition for the rarity with the given value,
 * or Address_Null if not valid.
 * 
 * You know the drill at this point.
 */
native Address TF2Econ_GetRarityDefinitionAddress(int rarity);

/**
 * @deprecated Renamed native to TF2Econ_IsValidItemDefinition so there is a better distinction
 * between item and attribute definitions.
 * 
 * This native will still be present for backwards compatibility.
 */
#pragma deprecated Use TF2Econ_IsValidItemDefinition instead
native bool TF2Econ_IsValidDefinitionIndex(int defindex);

public SharedPlugin __pl_tf_econ_data = {
	name = "tf_econ_data",
	file = "tf_econ_data.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
