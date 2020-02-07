/**
 * [CSGO] Econ Data
 * Functions to read item information from game memory.
 */

#if defined __csgo_econ_data_included
	#endinput
#endif

#define __csgo_econ_data_included

/**
 * Item definition index for the special "default" item entry, which is returned by the game's
 * CEconItemSchema::GetItemDefinition() if the given item definition does not exist.
 * 
 * Not a valid item, but points to a valid item definition, so this does return information when
 * `CSGOEcon_Get*` functions are called on it.
 */
enum {
	CSGO_ITEMDEF_DEFAULT = -1,
};

/**
 * Callback for `CSGOEcon_GetItemList`.  Return `true` if the specified item definition index
 * should be added to the returned `ArrayList`.
 */
typedef ItemFilterCriteria = function bool(int defindex, any data);

/**
 * Returns true if there is an item corresponding to the given item definition index.
 * TF_ITEMDEF_DEFAULT returns false here.
 */
native bool CSGOEcon_IsValidItemDefinition(int defindex);

/**
 * Returns the item's name (corresponds to the "name" key).
 */
native bool CSGOEcon_GetItemName(int defindex, char[] name, int maxlen);

/**
 * Returns the item's localization token name (corresponds to the "item_name" key).
 */
native bool CSGOEcon_GetLocalizedItemName(int defindex, char[] name, int maxlen);

/**
 * Stores the item class name in the given buffer and returns true if given a valid item
 * definition, otherwise returns false.
 */
native bool CSGOEcon_GetItemClassName(int defindex, char[] buffer, int maxlen);

/**
 * Returns the item's weapon slot for the given class, or -1 if the item definition or
 * item / class combination is not valid.
 */
// native int CSGOEcon_GetItemSlot(int defindex, TFClassType playerClass);

/**
 * Returns the given item's equipment region mask.  This mask can be and-tested with another
 * mask to determine if items conflict.
 */
// native int CSGOEcon_GetItemEquipRegionMask(int defindex);

/**
 * Returns the given item's equipment region groups as a bitfield.
 * 
 * Internally, this is called an EquipRegionBitMask, but for the sake of clarity it's been
 * renamed in this library to specify equip region groups.
 */
// native int CSGOEcon_GetItemEquipRegionGroupBits(int defindex);

/**
 * Stores the minimum and maximum item level range in the given cell references and
 * returns true for a valid item definition, otherwise returns false.
 */
native bool CSGOEcon_GetItemLevelRange(int defindex, int &iMinLevel, int &iMaxLevel);

/**
 * Returns the given item's statically defined quality.
 */
native int CSGOEcon_GetItemQuality(int defindex);

/**
 * Returns the given item's rarity, or -1 if the item does not have a statically defined rarity.
 */
native int CSGOEcon_GetItemRarity(int defindex);

/**
 * Returns an `ArrayList` containing attribute defindex / value pairs corresponding to the given
 * item definition, or `null` if not a valid item definition.
 * 
 * This handle is owned by the calling plugin, so it should be `delete`d when not needed
 * anymore.
 */
native ArrayList CSGOEcon_GetItemStaticAttributes(int defindex);

/**
 * Returns an arbiitrary string from an item definition's KeyValues structure.
 * You may use subkey notation ('/') to retrieve nested values.
 * 
 * Returns true if the output buffer is not empty.
 */
native bool CSGOEcon_GetItemDefinitionString(int defindex, const char[] key,
		char[] buffer, int maxlen, const char[] defaultValue = "");

/**
 * Returns an ArrayList containing all valid item definition indices.  If an ItemFilterCriteria
 * callback is passed in, the ArrayList only contains defindexes that the callback returned
 * `true` on.
 * 
 * This handle is owned by the calling plugin, so it should be `delete`d when not needed
 * anymore.
 */
native ArrayList CSGOEcon_GetItemList(ItemFilterCriteria func = INVALID_FUNCTION, any data = 0);

/**
 * Returns true if there is an attribute corresponding to the given attribute definition index.
 */
native bool CSGOEcon_IsValidAttributeDefinition(int defindex);

/**
 * Returns true if the attribute is considered hidden (corresponds to the "hidden" key).
 */
native bool CSGOEcon_IsAttributeHidden(int defindex);

/** 
 * Returns true if the attribute is stored as an integer (corresponds to the "stored_as_integer"
 * key).
 * 
 * Not sure when this is actually used -- certain attributes such as
 * "mod max primary clip override" are flagged as true, but are float values when retrieved
 * via `CSGOEcon_GetItemStaticAttributes()`.
 */
native bool CSGOEcon_IsAttributeStoredAsInteger(int defindex);

/**
 * Stores the attribute name in the given buffer and returns true if given a valid attribute
 * definition, otherwise returns false.
 */
native bool CSGOEcon_GetAttributeName(int defindex, char[] buffer, int maxlen);

/**
 * Stores the attribute class name in the given buffer and returns true if given a valid
 * attribute definition, otherwise returns false.
 */
native bool CSGOEcon_GetAttributeClassName(int defindex, char[] buffer, int maxlen);

/**
 * Returns an arbiitrary string from an item attribute definition's KeyValues structure.
 * You may use subkey notation ('/') to retrieve nested values.
 * 
 * Returns true if the output buffer is not empty.
 */
native bool CSGOEcon_GetAttributeDefinitionString(int defindex, const char[] key,
		char[] buffer, int maxlen, const char[] defaultValue = "");

/**
 * Returns the attribute definition index for a given name, or -1 if the name does not
 * correspond to an attribute.
 */
native int CSGOEcon_TranslateAttributeNameToDefinitionIndex(const char[] name);

/**
 * Returns the address of the singleton CTFItemSchema (subclass of CEconItemSchema).
 * 
 * Here be dragons.
 */
native Address CSGOEcon_GetItemSchemaAddress();

/**
 * Returns the address of the singleton CProtoBufScriptObjectDefinitionManager.
 * 
 * Here be dragons.
 */
native Address CSGOEcon_GetProtoDefManagerAddress();

/**
 * Returns the address of the CEconItemDefinition for the item with the given definition index,
 * or Address_Null if not valid.  The special "default" item definition is returned iff
 * TF_ITEMDEF_DEFAULT is used as the defindex.
 * 
 * Here be dragons.
 */
native Address CSGOEcon_GetItemDefinitionAddress(int defindex);

/**
 * Returns the address of the CEconItemAttributeDefinition for the attribute with the given
 * definition index, or Address_Null if not valid.
 * 
 * Here be dragons.
 */
native Address CSGOEcon_GetAttributeDefinitionAddress(int defindex);


public SharedPlugin __pl_csgo_econ_data = {
	name = "csgo_econ_data",
	file = "csgo_econ_data.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
