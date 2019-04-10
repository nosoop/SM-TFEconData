Address offs_CEconItemQualityDefinition_iValue,
		offs_CEconItemQualityDefinition_pszName;

public int Native_GetQualityName(Handle hPlugin, int nParams) {
	int quality = GetNativeCell(1);
	
	Address pQualityDef = GetEconQualityDefinition(quality);
	if (!pQualityDef) {
		return false;
	}
	
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	bool bResult = LoadEconQualityDefinitionString(quality,
			offs_CEconItemQualityDefinition_pszName, buffer, maxlen);
	
	if (bResult) {
		SetNativeString(2, buffer, maxlen, true);
	}
	return bResult;
}

public int Native_TranslateQualityNameToValue(Handle hPlugin, int nParams) {
	bool caseSensitive = GetNativeCell(2);
	
	int maxlen;
	GetNativeStringLength(1, maxlen);
	maxlen++;
	
	char[] input = new char[maxlen];
	GetNativeString(1, input, maxlen);
	
	ArrayList qualityPointerList = GetEconQualityPointerList();
	if (!qualityPointerList) {
		return -1;
	}
	
	int result = -1;
	for (int i; i < qualityPointerList.Length && result == -1; i++) {
		char buffer[32];
		Address pQualityDef = qualityPointerList.Get(i);
		Address pszName =
				DereferencePointer(pQualityDef + offs_CEconItemQualityDefinition_pszName);
		LoadStringFromAddress(pszName, buffer, sizeof(buffer));
		
		if (StrEqual(input, buffer, caseSensitive)) {
			result = GetEconQualityValue(pQualityDef);
		}
	}
	delete qualityPointerList;
	
	return result;
}

Address GetEconQualityDefinition(int quality) {
	/** 
	 * Valve's implementation uses a lookup within a CUtlRBTree structure, which requires an
	 * SDKCall.
	 * 
	 * For our sanity's sake, we'll just iterate over the underlying data array and accept the 
	 * performance penalty.
	 */ 
	
	ArrayList qualityPointerList = GetEconQualityPointerList();
	if (!qualityPointerList) {
		return Address_Null;
	}
	
	Address result;
	for (int i; i < qualityPointerList.Length && !result; i++) {
		Address pQualityDef = qualityPointerList.Get(i);
		if (quality == GetEconQualityValue(pQualityDef)) {
			result = pQualityDef;
		}
	}
	delete qualityPointerList;
	
	return result;
}

/**
 * Returns the quality value of a given quality definition.
 */
static int GetEconQualityValue(Address pQualityDef) {
	return LoadFromAddress(pQualityDef + offs_CEconItemQualityDefinition_iValue,
					NumberType_Int32);
}

/**
 * Returns an ArrayList of CEconItemQualityDefinition addresses.
 */
static ArrayList GetEconQualityPointerList() {
	if (!GetEconQualityDefinitionCount()) {
		return null;
	}
	
	ArrayList result = new ArrayList();
	for (int i; i < GetEconQualityDefinitionCount(); i++) {
		result.Push(GetEconQualityDefinitionFromMemoryIndex(i));
	}
	return result;
}

/**
 * Returns the address of a CEconItemQualityDefinition based on an array index in the schema's
 * internal CEconItemQualityDefinition array.
 */
static Address GetEconQualityDefinitionFromMemoryIndex(int index) {
	if (index < 0 || index >= GetEconQualityDefinitionCount()) {
		return Address_Null;
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
	return DereferencePointer(GetEconQualityDefinitionTree() + view_as<Address>(0x04))
			+ view_as<Address>((index * 0x24) + 0x14);
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
	
	Address pSchema = GetEconItemSchema();
	if (!pSchema) {
		return Address_Null;
	}
	
	s_pItemQualityTree = pSchema + offs_CEconItemSchema_ItemQualities;
	return s_pItemQualityTree;
}

static bool LoadEconQualityDefinitionString(int quality, Address offset, char[] buffer,
		int maxlen) {
	Address pQualityDef = GetEconQualityDefinition(quality);
	if (!pQualityDef) {
		return false;
	}
	
	LoadStringFromAddress(DereferencePointer(pQualityDef + offset), buffer, maxlen);
	return true;
}
