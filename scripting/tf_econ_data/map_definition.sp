/**
 * native int(const char[] name);
 */
public int Native_GetMapDefinitionIndex(Handle hPlugin, int nParams)
{
	int len = 0;
	GetNativeStringLength(1, len);
	len++;

	char[] name = new char[len];
	GetNativeString(1, name, len);

	return GetMapDefinitionIndex(name);
}
