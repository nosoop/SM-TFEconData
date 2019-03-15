/**
 * [TF2] Econ Data
 * Functions to read item information from game memory.
 */

#if defined __tf_econ_data_included
	#endinput
#endif

#include <tf2_stocks>

#define __tf_econ_data_included

typedef ItemFilterCriteria = function bool(int defindex, any data);

/**
 * Returns true if there is an item corresponding to the given definition index.
 */
native bool TF2Econ_IsValidDefinitionIndex(int defindex);

/**
 * Returns the item class name.
 */
native bool TF2Econ_GetItemClassName(int defindex, char[] buffer, int maxlen);

/**
 * Returns the item's weapon slot, or -1 if the defindex or item / class combination is not
 * valid.
 */
native int TF2Econ_GetItemSlot(int defindex, TFClassType playerClass);

/**
 * Returns true if the specified className was translated for the given player class.
 * 
 * This is used for multiclass weapons -- if given a player class-specific classname,
 * this function returns false.
 */
native bool TF2Econ_TranslateWeaponEntForClass(char[] className, int maxlen,
		TFClassType playerClass);

/**
 * Returns the minimum and maximum level range for the item.
 */
native bool TF2Econ_GetItemLevelRange(int defindex, int &iMinLevel, int &iMaxLevel);

/**
 * Returns an ArrayList containing all valid defindexes.  If an ItemFilterCriteria callback is
 * passed in, the ArrayList only contains defindexes that the callback returned `true` on.
 * 
 * This handle must be freed.
 */
native ArrayList TF2Econ_GetItemList(ItemFilterCriteria func = INVALID_FUNCTION, any data = 0);

public SharedPlugin __pl_tf_econ_data = {
	name = "tf_econ_data",
	file = "tf_econ_data.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};
