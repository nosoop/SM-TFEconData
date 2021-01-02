/**
 * Natives / functions for accessing CEconItemDefinition / CTFItemDefinition properties.
 */

any sizeof_static_attrib_t;

#include <classdefs/econ_item_definition.sp>
#include <classdefs/static_attrib.sp>

/**
 * native bool(int itemdef, char[] buffer, int maxlen);
 * 
 * Stores the internal item name into the buffer.  Returns true if the item definition exists.
 */
public int Native_GetItemName(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	int maxlen = GetNativeCell(3);
	
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return false;
	}
	
	char[] buffer = new char[maxlen];
	
	LoadStringFromAddress(pItemDef.m_szItemName, buffer, maxlen);
	SetNativeString(2, buffer, maxlen, true);
	return true;
}

/**
 * native bool(int itemdef, char[] buffer, int maxlen);
 * 
 * Stores the item's localization token into the buffer.  Returns true if the item definition
 * exists.
 */
public int Native_GetLocalizedItemName(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	int maxlen = GetNativeCell(3);
	
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return false;
	}
	
	char[] buffer = new char[maxlen];
	LoadStringFromAddress(pItemDef.m_szLocalizedItemName, buffer, maxlen);
	SetNativeString(2, buffer, maxlen, true);
	return true;
}

/**
 * native bool(int itemdef, char[] buffer, int maxlen);
 * 
 * Stores the item class name into the buffer.  Returns true if the item definition exists.
 */
public int Native_GetItemClassName(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	int maxlen = GetNativeCell(3);
	
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return false;
	}
	
	char[] buffer = new char[maxlen];
	LoadStringFromAddress(pItemDef.m_szItemClassname, buffer, maxlen);
	SetNativeString(2, buffer, maxlen, true);
	return true;
}

/**
 * native int(int itemdef, TFClassType playerClass);
 * 
 * Stores the item loadout slot for the given class.  Returns -1 if the item definition does 
 * not exist or if the item is not valid for the given player class.
 */
public int Native_GetItemSlot(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	int playerClass = GetNativeCell(2);
	
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return -1;
	}
	return LoadFromAddress(pItemDef.m_aiItemSlot + view_as<Address>(playerClass * 4),
			NumberType_Int32);
}

/**
 * native int();
 * 
 * Returns the default assigned item loadout slot, or -1 if the item definition does not exist.
 */
public int Native_GetItemDefaultSlot(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return -1;
	}
	return pItemDef.m_iDefaultItemSlot;
}

/**
 * native int(int itemdef);
 * 
 * Returns a bitset indicating group conflicts (that is, item cannot be worn with an item with
 * that bit set).
 */
public int Native_GetItemEquipRegionMask(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	
	if (!pItemDef) {
		ThrowNativeError(1, "Item definition index %d is not valid", defindex);
	}
	
	return pItemDef.m_bitsEquipRegionConflicts;
}

/**
 * native int(int itemdef);
 * 
 * Returns a bitset indicating item group membership.
 */
public int Native_GetItemEquipRegionGroupBits(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	
	if (!pItemDef) {
		ThrowNativeError(1, "Item definition index %d is not valid", defindex);
	}
	
	return pItemDef.m_bitsEquipRegionGroups;
}

/**
 * native bool(int itemdef, int &min, int &max);
 * 
 * Returns true on a valid item, populating `min` and `max` with the item's min / max level
 * range.
 */
public int Native_GetItemLevelRange(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return false;
	}
	
	SetNativeCellRef(2, pItemDef.m_u8MinLevel);
	SetNativeCellRef(3, pItemDef.m_u8MaxLevel);
	return true;
}

/**
 * native int(int itemdef);
 * 
 * Returns the item's given item quality.  Throws if the item is not valid.
 */
public int Native_GetItemQuality(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		ThrowNativeError(1, "Item definition index %d is not valid", defindex);
	}
	
	int quality = pItemDef.m_u8ItemQuality;
	
	// sign extension on byte -- valve's econ support lib uses "any" as a quality of -1
	// this is handled through CEconItemSchema::BGetItemQualityFromName()
	return (quality >> 7)? 0xFFFFFF00 | quality : quality;
}

/**
 * native int(int itemdef);
 * 
 * Returns the item's given item rarity.  Throws if the item is not valid.
 */
public int Native_GetItemRarity(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	
	if (!pItemDef) {
		ThrowNativeError(1, "Item definition index %d is not valid", defindex);
	}
	
	int rarity = pItemDef.m_si8ItemRarity;
	
	// sign extension on byte -- items that don't have rarities assigned are -1
	return (rarity >> 7)? 0xFFFFFF00 | rarity : rarity;
}

/**
 * native ArrayList<int, any>(int itemdef);
 * 
 * Returns an ArrayList containing the item's static attribute index / value pairs.
 */
public int Native_GetItemStaticAttributes(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return view_as<int>(INVALID_HANDLE);
	}
	
	int nAttribs = pItemDef.m_AttributeList.Length;
	Address pAttribList = pItemDef.m_AttributeList.m_Memory;
	
	// struct { attribute_defindex, value } // (TF2)
	ArrayList attributeList = new ArrayList(2, nAttribs);
	for (int i; i < nAttribs; i++) {
		StaticAttrib_t pStaticAttrib = StaticAttrib_t.FromAddress(pAttribList
				+ view_as<Address>(i * StaticAttrib_t.GetClassSize()));
		
		attributeList.Set(i, pStaticAttrib.m_iAttributeDefinitionIndex, 0);
		attributeList.Set(i, pStaticAttrib.m_iRawValue, 1);
	}
	return MoveHandle(attributeList, hPlugin);
}

/**
 * native bool(int itemdef, const char[] key, char[] buffer, int maxlen);
 * 
 * Looks up the key in the item definition's KeyValues instance.  Returns true if the buffer is
 * not empty after the process.
 */
public int Native_GetItemDefinitionString(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	int keylen;
	GetNativeStringLength(2, keylen);
	keylen++;
	
	char[] key = new char[keylen];
	GetNativeString(2, key, keylen);
	
	int maxlen = GetNativeCell(4);
	char[] buffer = new char[maxlen];
	
	GetNativeString(5, buffer, maxlen);
	
	CEconItemDefinition pItemDef = GetEconItemDefinition(defindex);
	if (pItemDef) {
		Address pKeyValues = pItemDef.m_pKeyValues;
		if (KeyValuesPtrKeyExists(pKeyValues, key)) {
			KeyValuesPtrGetString(pKeyValues, key, buffer, maxlen, buffer);
		}
	}
	
	SetNativeString(3, buffer, maxlen, true);
	return !!buffer[0];
}

/**
 * native bool(int itemdef);
 * 
 * Returns true if the given item definition corresponds to an item.
 */
public int Native_IsValidItemDefinition(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	return ValidItemDefIndex(defindex);
}
