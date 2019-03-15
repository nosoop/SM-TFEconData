# TF2 Econ Data

Work-in-progress library to get TF2 item data from game memory.

I got bored one day and thought about rewriting a few of my internal plugins so they didn't
depend on external tooling anymore.

A partial replacement for TF2ItemsInfo and TF2 Item DB.

## Features

* Retrieve certain properties of an item given its definition index, including entity class
name, level range, and item slot.
* Get an `ArrayList` of definition indexes filtered with a user-defined function.
* Translate an entity classname for the appropriate player class (making spawned multiclass
weapons work correctly).  Technically, this is just handled as a call to the game's function,
but it saves you effort from adding / maintaining the `SDKCall` boilerplate yourself.

## Example

Dump the taunt defindices for a given class:

```
public void OnPluginStart() {
	ArrayList tauntList = TF2Econ_GetItemList(FilterClassTaunts, TFClass_Scout);
	
	for (int i = 0; i < tauntList.Length; i++) {
		int defindex = tauntList.Get(i);
		PrintToServer("%d", defindex);
	}
	delete tauntList;
}

/**
 * Returns true if the given item is available for the given playerClass as a taunt (slot 11).
 */
public bool FilterClassTaunts(int defindex, TFClassType playerClass) {
	return TF2Econ_GetItemSlot(defindex, playerClass) == 11;
}
```
