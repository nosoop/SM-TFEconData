# TF2 Econ Data

Work-in-progress library to get TF2 item data from game memory.

A semi-replacement for TF2ItemsInfo and TF2 Item DB.

## Features

* Retrieve certain properties of an item given its definition index, including entity class
name, level range, and item slot.
* Get an `ArrayList` of definition indexes filtered with a user-defined function.
* Translate an entity classname for the appropriate player class (making spawned multiclass
weapons work correctly).

## Example

Dump the primary weapon defindices for a specific class:

```
public void DumpPrimaryWeaponsForClass(TFClassType playerClass) {
	ArrayList primaryList = TF2Econ_GetItemList(FilterPrimaryItems, playerClass);
	
	for (int i = 0; i < primaryList.Length; i++) {
		PrintToServer("%d", primaryList.Get(i));
	}
	delete primaryList;
}

public bool FilterPrimaryItems(int defindex, TFClassType playerClass) {
	return TF2Econ_GetItemSlot(defindex, playerClass) == 0;
}
```
