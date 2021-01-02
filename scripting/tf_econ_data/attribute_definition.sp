#include <classdefs/econ_item_attribute_definition.sp>

/**
 * native bool(int attrdef);
 * 
 * Returns true if the given attribute is marked as hidden.
 */
public int Native_IsAttributeHidden(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemAttributeDefinition pAttributeDef = GetEconAttributeDefinition(defindex);
	return pAttributeDef? pAttributeDef.m_bHidden : false;
}

/**
 * native bool(int attrdef);
 * 
 * Returns true if the given attribute is marked as stored as an integer.
 */
public int Native_IsAttributeStoredAsInteger(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemAttributeDefinition pAttributeDef = GetEconAttributeDefinition(defindex);
	return pAttributeDef? pAttributeDef.m_bIsInteger : false;
}

/**
 * bool(int attrdef, char[] buffer, int maxlen);
 *
 * Returns true if the given attribute definition is valid, storing its name into the buffer.
 */
public int Native_GetAttributeName(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemAttributeDefinition pAttributeDef = GetEconAttributeDefinition(defindex);
	if (!pAttributeDef) {
		return false;
	}
	
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	LoadStringFromAddress(pAttributeDef.m_szAttributeName, buffer, maxlen);
	SetNativeString(2, buffer, maxlen, true);
	return true;
}

/**
 * bool(int attrdef, char[] buffer, int maxlen);
 *
 * Returns true if the given attribute definition is valid, storing its attribute class name
 * into the buffer.
 */
public int Native_GetAttributeClassName(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	CEconItemAttributeDefinition pAttributeDef = GetEconAttributeDefinition(defindex);
	if (!pAttributeDef) {
		return false;
	}
	
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	LoadStringFromAddress(pAttributeDef.m_szAttributeClass, buffer, maxlen);
	SetNativeString(2, buffer, maxlen, true);
	return true;
}

/**
 * bool(int attrdef, const char[] key, char[] buffer, int maxlen, const char[] defaultVal = "");
 *
 * Retrieves the `key` entry from the attribute's KeyValues struct and returns true if the
 * given output buffer is not empty.  If `defaultVal` is set, it is copied to the output buffer.
 */
public int Native_GetAttributeDefinitionString(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	int keylen;
	GetNativeStringLength(2, keylen);
	keylen++;
	
	char[] key = new char[keylen];
	GetNativeString(2, key, keylen);
	
	int maxlen = GetNativeCell(4);
	char[] buffer = new char[maxlen];
	
	GetNativeString(5, buffer, maxlen);
	
	CEconItemAttributeDefinition pItemDef = GetEconAttributeDefinition(defindex);
	if (pItemDef && KeyValuesPtrKeyExists(pItemDef.m_pKeyValues, key)) {
		KeyValuesPtrGetString(pItemDef.m_pKeyValues, key, buffer, maxlen, buffer);
	}
	
	SetNativeString(3, buffer, maxlen, true);
	return !!buffer[0];
}

bool IsValidAttributeDefinition(int defindex) {
	return !!GetEconAttributeDefinition(defindex);
}

/**
 * bool(int attrdef);
 * 
 * Returns true if the given identifier corresponds to an attribute definition.
 */
public int Native_IsValidAttributeDefinition(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	return IsValidAttributeDefinition(defindex);
}
