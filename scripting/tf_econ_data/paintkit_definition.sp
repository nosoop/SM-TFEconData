Address offs_CProtoBufScriptObjectDefinitionManager_PaintList, // m_arDefinitionsMaps[9].m_Tree.m_Elements.m_pMemory
		sizeof_m_pMemory_DefinitionMap_t;

int Native_GetPaintKitList(Handle hPlugin, int nParams) {
	return MoveHandleImmediate(GetValidPaintKitProtoDefs(), hPlugin);
}

static ArrayList GetValidPaintKitProtoDefs() {
	ArrayList list = new ArrayList();
	
	int nPaintsAllocated = GetNumPaintKitsAllocated();
	for (int i; i < nPaintsAllocated; i++) {
		Address pPaintKitDefinition = GetPaintKitArrayEntry(i);
		if (!pPaintKitDefinition) {
			break;
		}
		
		int protoDefIndex = GetProtoDefIndex(pPaintKitDefinition);
		list.Push(protoDefIndex);
	}
	return list;
}

int Native_GetPaintKitDefinitionAddress(Handle hPlugin, int nParams) {
	int protoDefIndex = GetNativeCell(1);
	
	int nPaintsAllocated = GetNumPaintKitsAllocated();
	for (int i; i < nPaintsAllocated; i++) {
		Address pPaintKitDefinition = GetPaintKitArrayEntry(i);
		if (!pPaintKitDefinition) {
			return view_as<int>(Address_Null);
		}
		
		if (protoDefIndex == GetProtoDefIndex(pPaintKitDefinition)) {
			return view_as<int>(pPaintKitDefinition);
		}
	}
	return view_as<int>(Address_Null);
}

/**
 * Returns address of a CPaintKitDefinition within the CProtoDefMgr's list, or nullptr if
 * invalid.
 */
static Address GetPaintKitArrayEntry(int index) {
	Address pPaintKitData = LoadAddressFromAddress(GetProtoScriptObjDefManager()
			+ offs_CProtoBufScriptObjectDefinitionManager_PaintList);
	
	// array is some sort of struct size 0x10, CPaintKitDefinition* is at offset 0x0C
	Address pPaintKitEntry = pPaintKitData + view_as<Address>(index) * sizeof_m_pMemory_DefinitionMap_t;
	
	// tested in GetValidPaintKits() to be non-zero
	int unknown = LoadFromAddress(pPaintKitEntry, NumberType_Int32);
	if (!unknown) {
		return Address_Null;
	}
	
	return LoadAddressFromAddress(pPaintKitEntry + offs_CUtlMap_m_Tree_m_Elements_m_pMemory_m_Data_elem_u16); // m_Data_elem + 0
}

static int GetNumPaintKitsAllocated() {
	// offset after GetProtoScriptObjDefManager() in CTFItemDefinition::GetValidPaintkits()
	return LoadFromAddress(GetProtoScriptObjDefManager()
			+ offs_CProtoBufScriptObjectDefinitionManager_PaintList	// This is already at offs_CUtlMap_m_Tree_m_Elements_m_pMemory(+4/8)
			+ (offs_CUtlMap_m_Tree_m_NumElements_u16 - offs_CUtlMap_m_Tree_m_Elements_m_pMemory), NumberType_Int16);
}
