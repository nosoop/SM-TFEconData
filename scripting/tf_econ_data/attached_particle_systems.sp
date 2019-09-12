Address offs_CEconItemSchema_ParticleSystemTree;

// known members of attachedparticlesystem_t
Address offs_attachedparticlesystem_pszParticleSystem,
		offs_attachedparticlesystem_iAttributeValue;

// enum values for tree elements -- these should be moved when we have more CUtlRBTree accessors
enum TreeElement {
	Tree_LeftChild,
	Tree_RightChild,
	Tree_Parent
};

#define ATTACHED_PARTICLE_SYSTEM_STRUCT_SIZE 0x40

public int Native_GetParticleAttributeList(Handle hPlugin, int nParams) {
	return MoveHandleImmediate(GetParticleAttributeList(), hPlugin);
}

static ArrayList GetParticleAttributeList() {
	ArrayList list = new ArrayList();
	for (int i = GetFirstParticleSystem(); i != 0xFFFF; i = GetNextParticleSystem(i)) {
		Address pParticleSystemEntry = GetAttachedParticleSystemEntry(i);
		list.Push(GetParticleSystemPtrAttributeValue(pParticleSystemEntry));
	}
	return list;
}

public int Native_GetParticleAttributeSystemName(Handle hPlugin, int nParams) {
	int attrValue = GetNativeCell(1);
	Address pParticleSystemEntry = FindParticleSystemByAttributeValue(attrValue);
	if (!pParticleSystemEntry) {
		return false;
	}
	
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	
	Address pParticleName = DereferencePointer(
			pParticleSystemEntry + offs_attachedparticlesystem_pszParticleSystem);
	LoadStringFromAddress(pParticleName, buffer, maxlen);
	
	if (strlen(buffer)) {
		SetNativeString(2, buffer, maxlen, true);
		return true;
	}
	return false;
}

public int Native_GetParticleAttributeAddress(Handle hPlugin, int nParams) {
	int attrValue = GetNativeCell(1);
	return view_as<int>(FindParticleSystemByAttributeValue(attrValue));
}

static Address FindParticleSystemByAttributeValue(int attributeValue) {
	for (int i = GetFirstParticleSystem(); i != 0xFFFF; i = GetNextParticleSystem(i)) {
		Address pParticleSystemEntry = GetAttachedParticleSystemEntry(i);
		
		int particleIndex = GetParticleSystemPtrAttributeValue(pParticleSystemEntry);
		if (particleIndex == attributeValue) {
			return pParticleSystemEntry;
		}
	}
	return Address_Null;
}

/**
 * ============================================================================
 * Below is a partial implementation of CUtlRBTree<attachedparticlesystem_t...>.
 */

/* returns pParticleSystemEntry->iAttributeValue */
static int GetParticleSystemPtrAttributeValue(Address pParticleSystemEntry) {
	return LoadFromAddress(pParticleSystemEntry + offs_attachedparticlesystem_iAttributeValue,
			NumberType_Int32);
}

// implementation of CUtlRBTree<>::FirstInorder()
static int GetFirstParticleSystem() {
	// get root left child of CUtlRBTree
	int index = LoadFromAddress(GetParticleSystemTree() + view_as<Address>(0x14),
			NumberType_Int16);
	if (index == 0xFFFF) {
		return -1;
	}
	
	int child;
	while ((child = GetParticleSystemTreeElement(index, Tree_LeftChild)) != 0xFFFF) {
		index = child;
	}
	return index;
}

// implementation of CUtlRBTree<>::NextInorder()
static int GetNextParticleSystem(int index) {
	if (GetParticleSystemTreeElement(index, Tree_RightChild) != 0xFFFF) {
		index = GetParticleSystemTreeElement(index, Tree_RightChild);
		while (GetParticleSystemTreeElement(index, Tree_LeftChild) != 0xFFFF) {
			index = GetParticleSystemTreeElement(index, Tree_LeftChild);
		}
		return index;
	}
	
	int parent = GetParticleSystemTreeElement(index, Tree_Parent);
	while (IsParticleSystemRightChild(index)) {
		index = parent;
		if (index == 0xFFFF) {
			break;
		}
		parent = GetParticleSystemTreeElement(index, Tree_Parent);
	}
	return parent;
}

// get index of attachedparticlesystem_t in CUtlRBTree
static int GetParticleSystemTreeElement(int index, TreeElement elem) {
	Address pTree = GetAttachedParticleSystemEntry(index);
	switch (elem) {
		case Tree_LeftChild: {
			return LoadFromAddress(pTree, NumberType_Int16);
		}
		case Tree_RightChild: {
			return LoadFromAddress(pTree + view_as<Address>(0x02), NumberType_Int16);
		}
		case Tree_Parent: {
			return LoadFromAddress(pTree + view_as<Address>(0x04), NumberType_Int16);
		}
	}
	return 0xFFFF;
}

static bool IsParticleSystemRightChild(int index) {
	int parent = GetParticleSystemTreeElement(index, Tree_Parent);
	return GetParticleSystemTreeElement(parent, Tree_RightChild) == index;
}

// get address of attachedparticlesystem_t in CUtlRBTree by index
static Address GetAttachedParticleSystemEntry(int index) {
	static Address s_pParticleData;
	if (!s_pParticleData) {
		Address pParticleSystemTree = GetParticleSystemTree();
		s_pParticleData = DereferencePointer(pParticleSystemTree + view_as<Address>(0x08));
	}
	return s_pParticleData + view_as<Address>(index * ATTACHED_PARTICLE_SYSTEM_STRUCT_SIZE);
}

static Address GetParticleSystemTree() {
	return GetEconItemSchema() + offs_CEconItemSchema_ParticleSystemTree;
}
