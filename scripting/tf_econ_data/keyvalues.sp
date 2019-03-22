Handle g_SDKCallGetKeyValuesString;
Handle g_SDKCallGetKeyValuesFindKey;

bool KeyValuesPtrKeyExists(Address pKeyValues, const char[] key) {
	if (!pKeyValues) {
		return false;
	}
	return !!SDKCall(g_SDKCallGetKeyValuesFindKey, pKeyValues, key, false);
}

void KeyValuesPtrGetString(Address pKeyValues, const char[] key, char[] buffer, int maxlen,
		const char[] defaultValue) {
	SDKCall(g_SDKCallGetKeyValuesString, pKeyValues, buffer, maxlen, key, defaultValue);
}
