Address offs_CEconItemQualityDefinition_iValue,
		offs_CEconItemQualityDefinition_pszName;

Handle g_SDKCallRBTreeFindQualityDefinition;

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
	
	Address pQualityDef;
	int q;
	while ((pQualityDef = GetEconQualityDefinition(q))) {
		char buffer[32];
		Address pszName =
				DereferencePointer(pQualityDef + offs_CEconItemQualityDefinition_pszName);
		LoadStringFromAddress(pszName, buffer, sizeof(buffer));
		
		if (StrEqual(input, buffer, caseSensitive)) {
			return LoadFromAddress(pQualityDef + offs_CEconItemQualityDefinition_iValue,
					NumberType_Int32);
		}
		q++;
	}
	return -1;
}

Address GetEconQualityDefinition(int quality) {
	Address pSchema = GetEconItemSchema();
	if (!pSchema) {
		return Address_Null;
	}
	
	/**
	 * Questionable hack: we simulate a stack-allocated struct with an int[] in SP-land.
	 * 
	 * This is what `CEconItemSchema::GetQualityDefinition()` does on Linux; the function
	 * doesn't exist on Windows so we're reimplementing it.
	 */
	any lessFunc_t[5];
	lessFunc_t[0] = quality; // int
	lessFunc_t[1] = 0x7FFFFFFF; // int
	lessFunc_t[2] = 0; // char*
	lessFunc_t[3] = 0; // ???
	lessFunc_t[4] = 0; // char*
	
	// CUtlRBTree<CEconItemQualityDefinition>::Find returns an offset into some data (int)
	Address pItemQualityTree = pSchema + offs_CEconItemSchema_ItemQualities;
	int index = SDKCall(g_SDKCallRBTreeFindQualityDefinition, pItemQualityTree, lessFunc_t);
	
	if (index == -1) {
		return Address_Null;
	}
	
	// g_schema.field_0xA0 is the address of the CUtlRBTree
	// g_schema.field_0xA4 is some weird array access -- probably a key / value mapping?
	// g_schema.field_0xA8 is the number of elements in the quality list
	
	// implementation based off of CEconItemSchema::GetQualityDefinition()
	// it's going to absolutely suck if they change the implementation / remove the function
	return DereferencePointer(pItemQualityTree + view_as<Address>(0x04))
			+ view_as<Address>((index * 0x24) + 0x14);
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
