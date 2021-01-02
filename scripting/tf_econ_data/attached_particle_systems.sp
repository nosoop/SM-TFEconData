#include <classdefs/particle_system.sp>

// enum values for tree elements -- these should be moved when we have more CUtlRBTree accessors
enum TreeElement {
	Tree_LeftChild,
	Tree_RightChild,
	Tree_Parent
};

// particle sets -- these must remain synced to the ones in tf_econ_data.inc
// and must only be appended to maintain compatibility
enum TFEconParticleSet {
	ParticleSet_All,
	ParticleSet_CosmeticUnusualEffects,
	ParticleSet_WeaponUnusualEffects,
	ParticleSet_TauntUnusualEffects
};

/**
 * native ArrayList<int>(TFEconParticleSet particleSet);
 * 
 * Returns a list of particle indices included in the given particle set.
 */
public int Native_GetParticleAttributeList(Handle hPlugin, int nParams) {
	TFEconParticleSet particleSet = GetNativeCell(1);
	if (particleSet < ParticleSet_All || particleSet >= TFEconParticleSet) {
		ThrowNativeError(1, "Invalid particle list %d", particleSet);
	}
	
	return MoveHandleImmediate(GetParticleAttributeList(particleSet), hPlugin);
}

static ArrayList GetParticleAttributeList(TFEconParticleSet particleSet) {
	if (particleSet == ParticleSet_All) {
		// read all particles from CUtlRBTree
		ArrayList list = new ArrayList();
		for (int i = GetFirstParticleSystem(); i != 0xFFFF; i = GetNextParticleSystem(i)) {
			Address pParticleSystemEntry = GetAttachedParticleSystemEntry(i);
			list.Push(GetParticleSystemPtrAttributeValue(pParticleSystemEntry));
		}
		return list;
	}
	
	Address pParticleVector = GetParticleListAddress(particleSet);
	if (!pParticleVector) {
		// we should've caught this in Native_GetParticleAttributeList
		return null;
	}
	
	int nParticles = LoadFromAddress(
			pParticleVector + view_as<Address>(0x0C), NumberType_Int32);
	Address pParticleData = DereferencePointer(GetParticleListAddress(particleSet));
	
	ArrayList list = new ArrayList();
	for (int i; i < nParticles; i++) {
		Address pParticleID = pParticleData + view_as<Address>(i * 0x04);
		int value = LoadFromAddress(pParticleID, NumberType_Int32);
		list.Push(value);
	}
	return list;
}

/**
 * Returns the address to a CUtlVector containing the given particles, or Address_Null if not
 * a valid particle set.
 */
static Address GetParticleListAddress(TFEconParticleSet particleSet) {
	switch (particleSet) {
		case ParticleSet_CosmeticUnusualEffects: {
			return GetEconItemSchema().m_CosmeticUnusualEffectList;
		}
		case ParticleSet_WeaponUnusualEffects: {
			return GetEconItemSchema().m_WeaponUnusualEffectList;
		}
		case ParticleSet_TauntUnusualEffects: {
			return GetEconItemSchema().m_TauntUnusualEffectList;
		}
	}
	return Address_Null;
}

/**
 * native bool(int index, char[] buffer, int maxlen);
 * 
 * Returns true if a particle system index exists, storing the name in the given buffer.
 */
public int Native_GetParticleAttributeSystemName(Handle hPlugin, int nParams) {
	int attrValue = GetNativeCell(1);
	AttachedParticleSystem_t pParticleSystemEntry = FindParticleSystemByAttributeValue(attrValue);
	if (!pParticleSystemEntry) {
		return false;
	}
	
	int maxlen = GetNativeCell(3);
	
	char[] buffer = new char[maxlen];
	LoadStringFromAddress(pParticleSystemEntry.m_szParticleSystem, buffer, maxlen);
	
	if (strlen(buffer)) {
		SetNativeString(2, buffer, maxlen, true);
		return true;
	}
	return false;
}

/**
 * native Address(int index);
 * 
 * Returns an attachedparticlesystem_t struct corresponding to the particle index, or
 * Address_Null if invalid.
 */
public int Native_GetParticleAttributeAddress(Handle hPlugin, int nParams) {
	int attrValue = GetNativeCell(1);
	return view_as<int>(FindParticleSystemByAttributeValue(attrValue));
}

static AttachedParticleSystem_t FindParticleSystemByAttributeValue(int attributeValue) {
	for (int i = GetFirstParticleSystem(); i != 0xFFFF; i = GetNextParticleSystem(i)) {
		Address pParticleSystemEntry = GetAttachedParticleSystemEntry(i);
		
		int particleIndex = GetParticleSystemPtrAttributeValue(pParticleSystemEntry);
		if (particleIndex == attributeValue) {
			return AttachedParticleSystem_t.FromAddress(pParticleSystemEntry);
		}
	}
	return AttachedParticleSystem_t.FromAddress(Address_Null);
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
	return s_pParticleData + view_as<Address>(index * AttachedParticleSystem_t.GetClassSize());
}

static Address GetParticleSystemTree() {
	return GetEconItemSchema().m_ParticleSystemTree;
}
