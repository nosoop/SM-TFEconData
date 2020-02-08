/**
 * [TF2] Econ Data
 * 
 * Functions to read item information from game memory.
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>

#pragma newdecls required

#include <stocksoup/handles>
#include <stocksoup/memory>

#define PLUGIN_VERSION "0.16.4"
public Plugin myinfo = {
	name = "[CS:GO] Econ Data",
	author = "nosoop",
	description = "A library to read item data straight from the game's memory.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/SM-TFEconData"
}

Address offs_CEconItemSchema_ItemQualities,
		offs_CEconItemSchema_ItemList,
		offs_CEconItemSchema_nItemCount,
		offs_CEconItemSchema_AttributeList;

#include "tf_econ_data/attached_particle_systems.sp"
#include "tf_econ_data/loadout_slot.sp"
#include "tf_econ_data/item_definition.sp"
#include "tf_econ_data/equip_regions.sp"
#include "tf_econ_data/attribute_definition.sp"
#include "tf_econ_data/paintkit_definition.sp"
#include "tf_econ_data/quality_definition.sp"
#include "tf_econ_data/rarity_definition.sp"
#include "tf_econ_data/keyvalues.sp"

#define TF_ITEMDEF_DEFAULT -1

Handle g_SDKCallGetEconItemSchema;
Handle g_SDKCallItemSystem;
Handle g_SDKCallSchemaGetItemDefinition;
Handle g_SDKCallSchemaGetAttributeDefinitionByName;
// Handle g_SDKCallTranslateWeaponEntForClass;
Handle g_SDKCallGetProtoDefManager;
Handle g_SDKCallGetProtoDefIndex;

public APLRes AskPluginLoad2(Handle self, bool late, char[] error, int maxlen) {
	RegPluginLibrary("csgo_econ_data");
	
	// item information
	CreateNative("CSGOEcon_IsValidItemDefinition", Native_IsValidItemDefinition);
	CreateNative("CSGOEcon_GetItemName", Native_GetItemName);
	CreateNative("CSGOEcon_GetLocalizedItemName", Native_GetLocalizedItemName);
	CreateNative("CSGOEcon_GetItemClassName", Native_GetItemClassName);
	// CreateNative("CSGOEcon_GetItemSlot", Native_GetItemSlot);
	CreateNative("CSGOEcon_GetItemLevelRange", Native_GetItemLevelRange);
	CreateNative("CSGOEcon_GetItemQuality", Native_GetItemQuality);
	CreateNative("CSGOEcon_GetItemRarity", Native_GetItemRarity);
	CreateNative("CSGOEcon_GetItemStaticAttributes", Native_GetItemStaticAttributes);
	CreateNative("CSGOEcon_GetItemDefinitionString", Native_GetItemDefinitionString);
	
	// global items
	CreateNative("CSGOEcon_GetItemList", Native_GetItemList);
	
	// attribute information
	CreateNative("CSGOEcon_IsValidAttributeDefinition", Native_IsValidAttributeDefinition);
	CreateNative("CSGOEcon_IsAttributeHidden", Native_IsAttributeHidden);
	CreateNative("CSGOEcon_IsAttributeStoredAsInteger", Native_IsAttributeStoredAsInteger);
	CreateNative("CSGOEcon_GetAttributeName", Native_GetAttributeName);
	CreateNative("CSGOEcon_GetAttributeClassName", Native_GetAttributeClassName);
	CreateNative("CSGOEcon_GetAttributeDefinitionString", Native_GetAttributeDefinitionString);
	CreateNative("CSGOEcon_TranslateAttributeNameToDefinitionIndex",
			Native_TranslateAttributeNameToDefinitionIndex);
	
	// low-level stuff
	CreateNative("CSGOEcon_GetItemSchemaAddress", Native_GetItemSchemaAddress);
	CreateNative("CSGOEcon_GetItemDefinitionAddress", Native_GetItemDefinitionAddress);
	CreateNative("CSGOEcon_GetAttributeDefinitionAddress", Native_GetAttributeDefinitionAddress);
	
	return APLRes_Success;
}

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("csgo.econ_data");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (csgo.econ_data).");
	}
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "GEconItemSchema()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallGetEconItemSchema = EndPrepSDKCall();
	
	if (!g_SDKCallGetEconItemSchema) {
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "ItemSystem()");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		g_SDKCallItemSystem = EndPrepSDKCall();
		
		if (!g_SDKCallItemSystem) {
			SetFailState("Could not set up GEconItemSchema() or ItemSystem() calls.");
		}
	}
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CEconItemSchema::GetItemDefinition()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_SDKCallSchemaGetItemDefinition = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CEconItemSchema::GetAttributeDefinitionByName()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_SDKCallSchemaGetAttributeDefinitionByName = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "KeyValues::GetString()");
	PrepSDKCall_SetReturnInfo(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallGetKeyValuesString = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "KeyValues::FindKey()");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_SDKCallGetKeyValuesFindKey = EndPrepSDKCall();
	
	offs_CEconItemDefinition_pKeyValues =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_pKeyValues");
	offs_CEconItemDefinition_u8MinLevel =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_u8MinLevel");
	offs_CEconItemDefinition_u8MaxLevel =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_u8MaxLevel");
	offs_CEconItemDefinition_u8ItemQuality =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_u8ItemQuality");
	offs_CEconItemDefinition_si8ItemRarity =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_si8ItemRarity");
	offs_CEconItemDefinition_AttributeList =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_AttributeList");
	offs_CEconItemDefinition_pszLocalizedItemName =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_pszLocalizedItemName");
	offs_CEconItemDefinition_pszItemClassname =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_pszItemClassname");
	offs_CEconItemDefinition_pszItemName =
			GameConfGetAddressOffset(hGameConf, "CEconItemDefinition::m_pszItemName");
	
	// offs_CEconItemSchema_ItemRarities =
			// GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_ItemRarities");
	// offs_CEconItemSchema_iLastValidRarity =
			// GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_iLastValidRarity");
	// offs_CEconItemSchema_ItemQualities =
			// GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_ItemQualities");
	offs_CEconItemSchema_ItemList =
			GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_ItemList");
	offs_CEconItemSchema_nItemCount =
			GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_nItemCount");
	// offs_CEconItemSchema_EquipRegions =
			// GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_EquipRegions");
	// offs_CEconItemSchema_ParticleSystemTree =
			// GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_ParticleSystemTree");
	offs_CEconItemSchema_AttributeList =
			GameConfGetAddressOffset(hGameConf, "CEconItemSchema::m_AttributeList");
	
	offs_CTFItemSchema_ItemSlotNames =
			GameConfGetAddressOffset(hGameConf, "CCStrike15ItemSchema::m_ItemSlotNames");
	
	offs_CEconItemAttributeDefinition_pKeyValues =
			GameConfGetAddressOffset(hGameConf, "CEconItemAttributeDefinition::m_pKeyValues");
	offs_CEconItemAttributeDefinition_iAttributeDefinitionIndex =
			GameConfGetAddressOffset(hGameConf,
			"CEconItemAttributeDefinition::m_iAttributeDefinitionIndex");
	offs_CEconItemAttributeDefinition_bHidden =
			GameConfGetAddressOffset(hGameConf, "CEconItemAttributeDefinition::m_bHidden");
	offs_CEconItemAttributeDefinition_bIsInteger =
			GameConfGetAddressOffset(hGameConf, "CEconItemAttributeDefinition::m_bIsInteger");
	offs_CEconItemAttributeDefinition_pszAttributeName =
			GameConfGetAddressOffset(hGameConf,
			"CEconItemAttributeDefinition::m_pszAttributeName");
	offs_CEconItemAttributeDefinition_pszAttributeClass =
			GameConfGetAddressOffset(hGameConf,
			"CEconItemAttributeDefinition::m_pszAttributeClass");
	
	sizeof_static_attrib_t = GameConfGetAddressOffset(hGameConf, "sizeof(static_attrib_t)");
	
	delete hGameConf;
	
	CreateConVar("csgoecondata_version", PLUGIN_VERSION,
			"Version for CS:GO Econ Data, to gauge popularity.", FCVAR_NOTIFY);
}

public int Native_TranslateWeaponEntForClass(Handle hPlugin, int nParams) {
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

public int Native_GetItemSchemaAddress(Handle hPlugin, int nParams) {
	return view_as<int>(GetEconItemSchema());
}

public int Native_GetItemDefinitionAddress(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	return view_as<int>(GetEconItemDefinition(defindex));
}

bool ValidItemDefIndex(int defindex) {
	// special case: return false on TF_ITEMDEF_DEFAULT
	return defindex != TF_ITEMDEF_DEFAULT && !!GetEconItemDefinition(defindex);
}

Address GetEconItemDefinition(int defindex) {
	Address pSchema = GetEconItemSchema();
	if (!pSchema) {
		return Address_Null;
	}
	
	Address pItemDefinition = SDKCall(g_SDKCallSchemaGetItemDefinition, pSchema, defindex, false);
	
	// special case: return default item definition on TF_ITEMDEF_DEFAULT (-1)
	// otherwise return a valid definition iff not the default
	if (defindex == TF_ITEMDEF_DEFAULT || pItemDefinition != GetEconDefaultItemDefinition()) {
		return pItemDefinition;
	}
	return Address_Null;
}

static Address GetEconDefaultItemDefinition() {
	static Address s_pDefaultItemDefinition;
	if (!s_pDefaultItemDefinition) {
		s_pDefaultItemDefinition = GetEconItemDefinition(TF_ITEMDEF_DEFAULT);
	}
	return s_pDefaultItemDefinition;
}

public int Native_GetAttributeDefinitionAddress(Handle hPlugin, int nParams) {
	int defindex = GetNativeCell(1);
	return view_as<int>(GetEconAttributeDefinition(defindex));
}

Address GetEconAttributeDefinition(int defindex) {
	// NOTE: CS:GO has their attribute list where indices are directly mapped within CUtlVector
	// TF2 does not do this (they also instead store CEconItemAttributeDefinition directly)
	// so don't merge into TF2 branch
	Address pSchema = GetEconItemSchema();
	if (!pSchema) {
		return Address_Null;
	}
	
	int nAttributes = LoadFromAddress(
			pSchema + offs_CEconItemSchema_AttributeList + view_as<Address>(0x0C),
			NumberType_Int32);
	if (defindex >= nAttributes) {
		return Address_Null;
	}
	Address pAttributeData = DereferencePointer(pSchema + offs_CEconItemSchema_AttributeList);
	return DereferencePointer(pAttributeData + view_as<Address>(0x04 * defindex));
}

public int Native_TranslateAttributeNameToDefinitionIndex(Handle hPlugin, int nParams) {
	int maxlen;
	GetNativeStringLength(1, maxlen);
	maxlen++;
	char[] attrName = new char[maxlen];
	GetNativeString(1, attrName, maxlen);
	
	Address pAttribute = GetEconAttributeDefinitionByName(attrName);
	if (pAttribute) {
		Address pOffs =
				pAttribute + offs_CEconItemAttributeDefinition_iAttributeDefinitionIndex;
		return LoadFromAddress(pOffs, NumberType_Int32);
	}
	return -1;
}

Address GetEconAttributeDefinitionByName(const char[] name) {
	Address pSchema = GetEconItemSchema();
	return pSchema?
			SDKCall(g_SDKCallSchemaGetAttributeDefinitionByName, pSchema, name) : Address_Null;
}

Address GetEconItemSchema() {
	if (g_SDKCallGetEconItemSchema) {
		return SDKCall(g_SDKCallGetEconItemSchema);
	}
	if (g_SDKCallItemSystem) {
		Address pItemSystem = SDKCall(g_SDKCallItemSystem);
		return pItemSystem? pItemSystem + view_as<Address>(4) : Address_Null;
	}
	return Address_Null;
}

Address GetProtoScriptObjDefManager() {
	return SDKCall(g_SDKCallGetProtoDefManager);
}

public int Native_GetProtoDefManagerAddress(Handle hPlugin, int nParams) {
	return view_as<int>(GetProtoScriptObjDefManager());
}

int GetProtoDefIndex(Address pProtoDefinition) {
	return SDKCall(g_SDKCallGetProtoDefIndex, pProtoDefinition);
}

static Address GameConfGetAddressOffset(Handle gamedata, const char[] key) {
	Address offs = view_as<Address>(GameConfGetOffset(gamedata, key));
	if (offs == view_as<Address>(-1)) {
		SetFailState("Failed to get member offset %s", key);
	}
	return offs;
}
