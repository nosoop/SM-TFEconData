# TF2 Econ Data

A library to get TF2 item data from game memory, intended as a successor to TF2ItemsInfo and
TF2IDB.  No more parsing the schema file and maintaining your own structure for plugin support.

I got bored one day and thought about rewriting a few of my internal plugins so they didn't
depend on external tooling anymore.

There's [a semi-guide on porting from existing libraries to this one][port-old-itemdata],
as well as [a WIP plugin that implements the natives from those libraries][econcompat].

[port-old-itemdata]: https://github.com/nosoop/SM-TFEconData/wiki/Porting-TF2IDB-and-TF2II-plugins-to-TFEconData
[econcompat]: https://github.com/nosoop/SM-TFEconDataCompat

## Features

- Retrieve certain properties of an item given its definition index, including entity class
name, level range, and item slot.
- Get lists of definition indices filtered with a user-defined function.
- Translate an entity classname for the appropriate player class (making spawned multiclass
weapons work correctly).  Technically, this is just handled as a call to the game's function,
but it saves you effort from adding / maintaining the `SDKCall` boilerplate yourself.
- Get a loadout slot name by index or translate slot indices (retrieved from item definitions)
to names.
- Read attributes and attribute properties.
- Read quality and rarity names / values.
- Access item equip regions and their equip region overlap masks, so you can determine if two
wearable items are overlapping.  Also access equip region names / group indices.
- Get lists of valid particle definitions, either as a whole or only for hats / taunts /
weapons.  (Internally, the game doesn't do anything special for the particles labled
`other_particles` and `killstreak_eyeglows`.)
- Get a list of all valid paintkit proto definition indices.
- Directly get the addresses of any supported definition type, as well as the schema / protobuf
schema, in case you want to do something the library doesn't support out of the box.

Note that the abstractions are intentionally low; this plugin **doesn't** implement higher-level
functions in SourcePawn to do things like:

- Check for equipment conflicts based on multiple definition indices.
- Resolve paintkit protodefs to their items to determine paint rarity.
- Provide hardcoded filters on cosmetic particles that are not obtainable from crates (map
stamps, pipe smoke).
- Determine which items can be Australium.

## Example

Dump the taunt defindices for a given class:

```sourcepawn
int g_iTauntSlot = -1;

public void OnAllPluginsLoaded() {
	// you could use a hardcoded value of 11 if you want to bet on valve not changing indices
	g_iTauntSlot = TF2Econ_TranslateLoadoutSlotNameToIndex("taunt");
	if (g_iTauntSlot == -1) {
		SetFailState("Failed to determine index for slot name '%s'", "taunt");
	}
	
	ArrayList tauntList = TF2Econ_GetItemList(FilterClassTaunts, TFClass_Scout);
	
	for (int i = 0; i < tauntList.Length; i++) {
		int defindex = tauntList.Get(i);
		PrintToServer("%d", defindex);
	}
	delete tauntList;
}

/**
 * Returns true if the given item is available for the given playerClass as a taunt.
 */
public bool FilterClassTaunts(int defindex, TFClassType playerClass) {
	return TF2Econ_GetItemSlot(defindex, playerClass) == g_iTauntSlot;
}
```
