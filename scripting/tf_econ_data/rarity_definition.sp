#include <classdefs/econ_item_rarity_definition.sp>

/**
 * native bool(int rarity, char[] buffer, int maxlen);
 * 
 * Stores the name of the provided rarity value into the given buffer, returning whether or not
 * it exists.
 */
public int Native_GetRarityName(Handle hPlugin, int nParams) {
	int rarity = GetNativeCell(1);
	
	CEconItemRarityDefinition pRarityDef = GetEconRarityDefinition(rarity);
	if (!pRarityDef) {
		return false;
	}
	
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	GetRarityName(pRarityDef, buffer, maxlen);
	SetNativeString(2, buffer, maxlen, true);
	return true;
}

/**
 * native int(const char[] name, bool caseSensitive = true);
 * 
 * Checks if any of the rarity definitions match the given name, returning the rarity value
 * if found, else -1.
 */
public int Native_TranslateRarityNameToValue(Handle hPlugin, int nParams) {
	// TODO always disable case-sensitivity, same as quality
	bool caseSensitive = GetNativeCell(2);
	
	int maxlen;
	GetNativeStringLength(1, maxlen);
	maxlen++;
	
	char[] input = new char[maxlen];
	GetNativeString(1, input, maxlen);
	
	int nRarityCount = GetEconRarityDefinitionCount();
	for (int i; i < nRarityCount; i++) {
		char buffer[32];
		CEconItemRarityDefinition pRarityDef = GetEconRarityDefinitionFromMemoryIndex(i);
		GetRarityName(pRarityDef, buffer, sizeof(buffer));
		if (StrEqual(input, buffer, caseSensitive)) {
			return GetRarityValue(pRarityDef);
		}
	}
	
	return -1;
}

/**
 * native ArrayList<cell_t>(void);
 * 
 * Returns a list containing valid rarity values.
 */
public int Native_GetRarityList(Handle hPlugin, int nParams) {
	ArrayList rarityValues = new ArrayList();
	
	int nRarityCount = GetEconRarityDefinitionCount();
	for (int i; i < nRarityCount; i++) {
		CEconItemRarityDefinition pRarityDef = GetEconRarityDefinitionFromMemoryIndex(i);
		rarityValues.Push(GetRarityValue(pRarityDef));
	}
	
	return MoveHandleImmediate(rarityValues, hPlugin);
}

/**
 * native Address<CEconItemRarityDefinition>(int index);
 */
public int Native_GetRarityDefinitionAddress(Handle hPlugin, int nParams) {
	int value = GetNativeCell(1);
	return view_as<int>(GetEconRarityDefinition(value));
}

CEconItemRarityDefinition GetEconRarityDefinition(int rarity) {
	int nRarityCount = GetEconRarityDefinitionCount();
	for (int i; i < nRarityCount; i++) {
		CEconItemRarityDefinition pRarityDef = GetEconRarityDefinitionFromMemoryIndex(i);
		if (rarity == GetRarityValue(pRarityDef)) {
			return pRarityDef;
		}
	}
	return CEconItemRarityDefinition.FromAddress(Address_Null);
}

static int GetRarityValue(CEconItemRarityDefinition pRarityDef) {
	return pRarityDef? pRarityDef.m_iValue : -1;
}

static void GetRarityName(CEconItemRarityDefinition pRarityDef, char[] buffer, int maxlen) {
	if (!pRarityDef) {
		return;
	}
	LoadStringFromAddress(pRarityDef.m_szName, buffer, maxlen);
}

/**
 * Returns the address of a CEconItemRarityDefinition based on an array index in the schema's
 * internal CEconItemRarityDefinition array.
 */
static CEconItemRarityDefinition GetEconRarityDefinitionFromMemoryIndex(int index) {
	if (index < 0 || index >= GetEconRarityDefinitionCount()) {
		return CEconItemRarityDefinition.FromAddress(Address_Null);
	}
	
	return CEconItemRarityDefinition.FromAddress(
			DereferencePointer(GetEconRarityDefinitionTree() + view_as<Address>(0x04))
			+ view_as<Address>((index * 0x34) + 0x14));
}

/**
 * Returns the number of valid items in the internal CEconItemRarityDefinition array.
 */
static int GetEconRarityDefinitionCount() {
	CEconItemSchema pSchema = GetEconItemSchema();
	return pSchema ? pSchema.m_iLastValidRarity + 1 : 0;
}

static Address GetEconRarityDefinitionTree() {
	static Address s_pItemRarityTree;
	if (s_pItemRarityTree) {
		return s_pItemRarityTree;
	}
	
	CEconItemSchema pSchema = GetEconItemSchema();
	if (!pSchema) {
		return Address_Null;
	}
	
	s_pItemRarityTree = pSchema.m_ItemRarities;
	return s_pItemRarityTree;
}
