/**
 * [TF2] Econ Data
 * 
 * Functions to read item information from game memory.
 */
#pragma semicolon 1
#include <sourcemod>

#include <tf2_stocks>

#pragma newdecls required

#include <stocksoup/handles>
#include <stocksoup/memory>

#define PLUGIN_VERSION "0.2.0"
public Plugin myinfo = {
	name = "[TF2] Econ Data",
	author = "nosoop",
	description = "A library to read item data straight from the game's memory.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFEconData"
}

Handle g_SDKCallGetEconItemSchema;
Handle g_SDKCallSchemaGetItemDefinition;
Handle g_SDKCallTranslateWeaponEntForClass;

Address offs_CEconItemDefinition_u8MinLevel,
		offs_CEconItemDefinition_u8MaxLevel,
		offs_CEconItemDefinition_pszItemClassname,
		offs_CEconItemDefinition_aiItemSlot,
		offs_CEconItemSchema_ItemList,
		offs_CEconItemSchema_nItemCount;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen) {
	RegPluginLibrary("tf_econ_data");
	
	CreateNative("TF2Econ_IsValidDefinitionIndex", Native_IsValidDefIndex);
	
	CreateNative("TF2Econ_GetItemClassName", Native_GetItemClassName);
	CreateNative("TF2Econ_GetItemSlot", Native_GetItemSlot);
	CreateNative("TF2Econ_GetItemLevelRange", Native_GetItemLevelRange);
	CreateNative("TF2Econ_TranslateWeaponEntForClass", Native_TranslateWeaponEntForClass);
	CreateNative("TF2Econ_GetItemList", Native_GetItemList);
	CreateNative("TF2Econ_GetItemDefinitionAddress", Native_GetItemDefinitionAddress);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.econ_data");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.econ_data).");
	}
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "GEconItemSchema()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallGetEconItemSchema = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CEconItemSchema::GetItemDefinition()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallSchemaGetItemDefinition = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TranslateWeaponEntForClass()");
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallTranslateWeaponEntForClass = EndPrepSDKCall();
	
	offs_CEconItemDefinition_u8MinLevel =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_u8MinLevel");
	offs_CEconItemDefinition_u8MaxLevel =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_u8MaxLevel");
	offs_CEconItemDefinition_pszItemClassname =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_pszItemClassname");
	offs_CEconItemDefinition_aiItemSlot =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_aiItemSlot");
	offs_CEconItemSchema_ItemList =
			GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_ItemList");
	offs_CEconItemSchema_nItemCount =
			GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_nItemCount");
	
	delete hGameConf;
}

public int Native_GetItemClassName(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	bool bResult = GetItemClass(defindex, buffer, maxlen);
	if (bResult) {
		SetNativeString(2, buffer, maxlen, true);
	}
	return bResult;
}

bool GetItemClass(int defindex, char[] buffer, int maxlen) {
	Address pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return false;
	}
	LoadStringFromAddress(
			DereferencePointer(pItemDef + offs_CEconItemDefinition_pszItemClassname),
			buffer, maxlen);
	return true;
}

public int Native_GetItemSlot(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	TFClassType playerClass = GetNativeCell(2);
	return GetItemSlot(defindex, playerClass);
}

/**
 * Returns the slot an item can be used in by defindex, or -1 if invalid item or invalid class.
 */
int GetItemSlot(int defindex, TFClassType playerClass) {
	Address pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return -1;
	}
	
	return LoadFromAddress(pItemDef + offs_CEconItemDefinition_aiItemSlot +
			view_as<Address>(view_as<int>(playerClass) * 4), NumberType_Int32);
}

public int Native_GetItemLevelRange(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	
	int iMinLevel, iMaxLevel;
	if (GetItemLevelRange(defindex, iMinLevel, iMaxLevel)) {
		SetNativeCellRef(2, iMinLevel);
		SetNativeCellRef(3, iMaxLevel);
		return true;
	}
	return false;
}

bool GetItemLevelRange(int defindex, int &iMinLevel, int &iMaxLevel) {
	Address pItemDef = GetEconItemDefinition(defindex);
	if (!pItemDef) {
		return false;
	}
	
	iMinLevel = LoadFromAddress(pItemDef + offs_CEconItemDefinition_u8MinLevel,
			NumberType_Int8);
	iMaxLevel = LoadFromAddress(pItemDef + offs_CEconItemDefinition_u8MaxLevel,
			NumberType_Int8);
	return true;
}

public int Native_IsValidDefIndex(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	return ValidItemDefIndex(defindex);
}

public int Native_TranslateWeaponEntForClass(Handle hPlugin, int nParams) {
	char weaponClass[64];
	GetNativeString(1, weaponClass, sizeof(weaponClass));
	int maxlen = GetNativeCell(2);
	TFClassType playerClass = GetNativeCell(3);
	
	if (TranslateWeaponEntForClass(weaponClass, maxlen, playerClass)) {
		SetNativeString(1, weaponClass, maxlen, true);
		return true;
	}
	return false;
}

public int Native_GetItemList(Handle hPlugin, int nParams) {
	Function func = GetNativeFunction(1);
	any data = GetNativeCell(2);
	
	Address pSchema = GetEconItemSchema();
	if (!pSchema) {
		return 0;
	}
	
	ArrayList itemList = new ArrayList();
	
	// CEconItemSchema.field_0xE8 is a CUtlVector of some struct size 0x0C
	// (int defindex, CEconItemDefinition*, int m_Unknown)
	
	int nItemDefs = LoadFromAddress(pSchema + offs_CEconItemSchema_nItemCount,
			NumberType_Int32);
	for (int i = 0; i < nItemDefs; i++) {
		Address entry = DereferencePointer(pSchema + offs_CEconItemSchema_ItemList)
				+ view_as<Address>(i * 0x0C);
		
		// I have no idea how this check works but it's also in
		// CEconItemSchema::GetItemDefinitionByName
		if (LoadFromAddress(entry + view_as<Address>(0x08), NumberType_Int32) < -1) {
			continue;
		}
		
		int defindex = LoadFromAddress(entry, NumberType_Int32);
		
		if (func == INVALID_FUNCTION) {
			itemList.Push(defindex);
			continue;
		}
		
		bool result;
		Call_StartFunction(hPlugin, func);
		Call_PushCell(defindex);
		Call_PushCell(data);
		Call_Finish(result);
		
		if (result) {
			itemList.Push(defindex);
		}
	}
	
	return MoveHandle(itemList, hPlugin);
}

public int Native_GetItemDefinitionAddress(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	return view_as<int>(GetEconItemDefinition(defindex));
}

bool ValidItemDefIndex(int defindex) {
	return !!GetEconItemDefinition(defindex);
}

static Address GetEconItemDefinition(int defindex) {
	Address pSchema = GetEconItemSchema();
	return pSchema? SDKCall(g_SDKCallSchemaGetItemDefinition, pSchema, defindex) : Address_Null;
}

static Address GetEconItemSchema() {
	return SDKCall(g_SDKCallGetEconItemSchema);
}

static bool TranslateWeaponEntForClass(char[] buffer, int maxlen, TFClassType playerClass) {
	return SDKCall(g_SDKCallTranslateWeaponEntForClass, buffer, maxlen, buffer, playerClass);
}

static Address GameConfGetAddressOffset(Handle gamedata, const char[] key) {
	Address offs = view_as<Address>(GameConfGetOffset(gamedata, key));
	if (offs == view_as<Address>(-1)) {
		SetFailState("Failed to get member offset %s", key);
	}
	return offs;
}

// note: in CEconItemDefinition, defindex is at 0x08