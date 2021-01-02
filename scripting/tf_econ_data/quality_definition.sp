#include <classdefs/econ_item_quality_definition.sp>

/**
 * native bool(int quality, char[] buffer, int maxlen);
 * 
 * Stores the name of the quality value into the provided buffer, returning whether or not it
 * exists.
 */
public int Native_GetQualityName(Handle hPlugin, int nParams) {
	int quality = GetNativeCell(1);
	
	CEconItemQualityDefinition pQualityDef = GetEconQualityDefinition(quality);
	if (!pQualityDef) {
		return false;
	}
	
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	GetEconQualityName(pQualityDef, buffer, maxlen);
	SetNativeString(2, buffer, maxlen, true);
	return true;
}

/**
 * native int(const char[] name, bool caseSensitive = true);
 * 
 * Checks if any of the quality definitions match the given name, returning the quality value
 * if found, else -1.
 */
public int Native_TranslateQualityNameToValue(Handle hPlugin, int nParams) {
	// TODO always disable case-sensitivity, pretty sure nobody wants to make a distinction.
	bool caseSensitive = GetNativeCell(2);
	
	int maxlen;
	GetNativeStringLength(1, maxlen);
	maxlen++;
	
	char[] input = new char[maxlen];
	GetNativeString(1, input, maxlen);
	
	int nQualityDefs = GetEconQualityDefinitionCount();
	for (int i; i < nQualityDefs; i++) {
		char buffer[32];
		CEconItemQualityDefinition pQualityDef = GetEconQualityDefinitionFromMemoryIndex(i);
		LoadStringFromAddress(pQualityDef.m_szName, buffer, sizeof(buffer));
		if (StrEqual(input, buffer, caseSensitive)) {
			return GetEconQualityValue(pQualityDef);
		}
	}
	return -1;
}

/**
 * native ArrayList<cell_t>(void);
 * 
 * Returns a list containing valid quality values.
 */
public int Native_GetQualityList(Handle hPlugin, int nParams) {
	int nQualityDefs = GetEconQualityDefinitionCount();
	if (!nQualityDefs) {
		return view_as<int>(INVALID_HANDLE);
	}
	
	ArrayList qualityValues = new ArrayList();
	for (int i; i < nQualityDefs; i++) {
		CEconItemQualityDefinition pQualityDef = GetEconQualityDefinitionFromMemoryIndex(i);
		qualityValues.Push(GetEconQualityValue(pQualityDef));
	}
	
	return MoveHandleImmediate(qualityValues, hPlugin);
}

CEconItemQualityDefinition GetEconQualityDefinition(int quality) {
	/** 
	 * Valve's implementation uses a lookup within a CUtlRBTree structure, which requires an
	 * SDKCall.
	 * 
	 * For our sanity's sake, we'll just iterate over the underlying data array and accept the 
	 * performance penalty.
	 */
	int nQualityDefs = GetEconQualityDefinitionCount();
	for (int i; i < nQualityDefs; i++) {
		CEconItemQualityDefinition pQualityDef = GetEconQualityDefinitionFromMemoryIndex(i);
		if (quality == GetEconQualityValue(pQualityDef)) {
			return pQualityDef;
		}
	}
	return CEconItemQualityDefinition.FromAddress(Address_Null);
}

/**
 * Returns the quality value of a given quality definition.
 */
static int GetEconQualityValue(CEconItemQualityDefinition pQualityDef) {
	return pQualityDef? pQualityDef.m_iValue : -1;
}

/**
 * Returns the quality name of a given quality definition.
 */
static void GetEconQualityName(CEconItemQualityDefinition pQualityDef, char[] buffer,
		int maxlen) {
	if (!pQualityDef) {
		return;
	}
	LoadStringFromAddress(DereferencePointer(pQualityDef.m_szName), buffer, maxlen);
}

/**
 * Returns the address of a CEconItemQualityDefinition based on an array index in the schema's
 * internal CEconItemQualityDefinition array.
 */
static CEconItemQualityDefinition GetEconQualityDefinitionFromMemoryIndex(int index) {
	if (index < 0 || index >= GetEconQualityDefinitionCount()) {
		return CEconItemQualityDefinition.FromAddress(Address_Null);
	}
	
	// g_schema.field_0xA0 is the address of the CUtlRBTree
	// g_schema.field_0xA4 is some weird array access -- probably a key / value mapping?
	// g_schema.field_0xA8 is the number of elements in the quality list
	
	// implementation based off of CEconItemSchema::GetQualityDefinition()
	// it's going to absolutely suck if they change the implementation / remove the function
	
	/**
	 * This array access can be checked against the call made to
	 * CEconItemQualityDefinition::BInitFromKV() within CEconItemSchema::BInitQualities().
	 */
	return CEconItemQualityDefinition.FromAddress(
			DereferencePointer(GetEconQualityDefinitionTree() + view_as<Address>(0x04))
			+ view_as<Address>((index * 0x24) + 0x14));
}

/**
 * Returns the number of items in the internal CEconItemQualityDefinition array.
 */
static int GetEconQualityDefinitionCount() {
	Address pItemQualityTree = GetEconQualityDefinitionTree();
	return pItemQualityTree?
			LoadFromAddress(pItemQualityTree + view_as<Address>(0x08), NumberType_Int32) :
			0;
}

static Address GetEconQualityDefinitionTree() {
	static Address s_pItemQualityTree;
	if (s_pItemQualityTree) {
		return s_pItemQualityTree;
	}
	
	CEconItemSchema pSchema = GetEconItemSchema();
	if (!pSchema) {
		return Address_Null;
	}
	
	s_pItemQualityTree = pSchema.m_ItemQualities;
	return s_pItemQualityTree;
}
