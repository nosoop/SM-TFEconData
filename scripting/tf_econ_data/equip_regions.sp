/**
 * Natives for accessing the item schema's equip region data.
 */

/**
 * I'm not going to bother putting these in gamedata for now.  It's a struct.
 */
#include <classdefs/equip_region.sp>

/**
 * native StringMap<int>();
 * 
 * Returns a mapping of group name to group index.
 */
public int Native_GetEquipRegionGroups(Handle hPlugin, int nParams) {
	CEconItemSchema pSchema = GetEconItemSchema();
	if (!pSchema) {
		return view_as<int>(INVALID_HANDLE);
	}
	
	StringMap equipRegionMap = new StringMap();
	
	// CUtlVector lookup
	Address pEquipRegions = pSchema.m_EquipRegions;
	
	int nEquipRegions = LoadFromAddress(
			pEquipRegions + view_as<Address>(0x0C), NumberType_Int32);
	
	Address pEquipRegionData = DereferencePointer(pEquipRegions);
	for (int i; i < nEquipRegions; i++) {
		char equipRegion[32];
		
		EquipRegion_t pEquipRegionEntry = EquipRegion_t.FromAddress(
				pEquipRegionData + view_as<Address>(i * EquipRegion_t.GetClassSize()));
		
		LoadStringFromAddress(pEquipRegionEntry.m_szName, equipRegion, sizeof(equipRegion));
		equipRegionMap.SetValue(equipRegion, pEquipRegionEntry.m_iGroup);
	}
	return MoveHandle(equipRegionMap, hPlugin);
}

/**
 * native bool(const char[] name, int &mask);
 * 
 * Returns a bitset of groups the given group-by-name conflicts with.
 */
public int Native_GetEquipRegionMask(Handle hPlugin, int nParams) {
	CEconItemSchema pSchema = GetEconItemSchema();
	if (!pSchema) {
		return false;
	}
	
	int maxlen;
	GetNativeStringLength(1, maxlen);
	
	maxlen++;
	
	char[] desiredEquipRegion = new char[maxlen];
	GetNativeString(1, desiredEquipRegion, maxlen);
	
	// CUtlVector lookup
	Address pEquipRegions = pSchema.m_EquipRegions;
	int nEquipRegions = LoadFromAddress(
			pEquipRegions + view_as<Address>(0x0C), NumberType_Int32);
	
	Address pEquipRegionData = DereferencePointer(pEquipRegions);
	for (int i; i < nEquipRegions; i++) {
		char equipRegion[64];
		
		EquipRegion_t pEquipRegionEntry = EquipRegion_t.FromAddress(
				pEquipRegionData + view_as<Address>(i * EquipRegion_t.GetClassSize()));
		
		LoadStringFromAddress(pEquipRegionEntry.m_szName, equipRegion, sizeof(equipRegion));
		if (!StrEqual(equipRegion, desiredEquipRegion)) {
			continue;
		}
		
		SetNativeCellRef(2, pEquipRegionEntry.m_iGroup);
		return true;
	}
	return false;
}
