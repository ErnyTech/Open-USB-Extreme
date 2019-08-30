// D import file generated from '/home/erny/Open-USB-Extreme/lib/usbextreme.d'
module usbextreme;
import std.stdint;
enum USBEXTREME_NAME_LENGTH = 32;
enum USBEXTREME_ID_LENGTH = 15;
enum USBEXTREME_NAME_EXT_LENGTH = 10;
enum USBEXTREME_MAGIC = 8;
enum USBEXTREME_HEADER_SIZE = UsbExtremeBase.sizeof;
enum USBEXTREME_FILESTAT_NAME_LENGTH = USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH;
enum USBEXTREME_PREFIX = "ul.";
enum USBEXTREME_CRC32_LENGTH = 8;
enum USBEXTREME_FILENAME_LENGTH = USBEXTREME_ID_LENGTH + USBEXTREME_CRC32_LENGTH + 1;
enum USBEXTREME_PART_SIZE_V0 = 1073741824;
align (1) struct UsbExtremeBase
{
	align (1) 
	{
		uint8_t[6 + USBEXTREME_ID_LENGTH + USBEXTREME_NAME_LENGTH] empty;
		uint8_t magic;
		uint8_t[10] empty2;
	}
}
align (1) struct UsbExtremeV0
{
	align (1) 
	{
		char[USBEXTREME_NAME_LENGTH] name;
		char[USBEXTREME_ID_LENGTH] id;
		uint8_t parts;
		SCECdvdMediaType type;
		uint8_t[4] empty;
		uint8_t magic;
		uint8_t[USBEXTREME_NAME_EXT_LENGTH] empty2;
	}
}
align (1) struct UsbExtremeV1
{
	align (1) 
	{
		char[USBEXTREME_NAME_LENGTH] name;
		char[USBEXTREME_ID_LENGTH] id;
		uint8_t parts;
		SCECdvdMediaType type;
		uint16_t partSize;
		uint8_t videoMode;
		UsbExtremeVersion usbExtremeVersion;
		uint8_t magic;
		char[USBEXTREME_NAME_EXT_LENGTH] nameExt;
	}
}
struct UsbExtremeHeaders
{
	const(void)* firstHeader;
	const(UsbExtremeBase)[] headers;
	size_t numHeaders;
	size_t headersLen;
	UsbExtremeVersion oueVersion;
}
struct UsbExtremeFilestat
{
	size_t offset;
	char[USBEXTREME_FILESTAT_NAME_LENGTH] name;
	SCECdvdMediaType type;
	size_t partSize;
	uint8_t videoMode;
	UsbExtremeVersion usbExtremeVersion;
}
enum UsbExtremeVersion : uint8_t
{
	V0 = 0,
	V1,
	Unknown,
}
enum SCECdvdMediaType : uint8_t
{
	SCECdNODISC = 0,
	SCECdDETCT,
	SCECdDETCTCD,
	SCECdDETCTDVDS,
	SCECdDETCTDVDD,
	SCECdUNKNOWN,
	SCECdPSCD = 16,
	SCECdPSCDDA,
	SCECdPS2CD,
	SCECdPS2CDDA,
	SCECdPS2DVD,
	SCECdCDDA = 253,
	SCECdDVDV,
	SCECdIllegalMediaoffset,
}
extern (D) bool isOue(const(void)[] headers);
extern (D) UsbExtremeVersion getVersion(UsbExtremeVersion usbExtremeVersion);
extern (D) size_t oueNumHeaders(const(void)[] headers);
extern (D) size_t ouePointHeaders(ref const(UsbExtremeBase)[] headers, const(void)[] rawHeaders);
extern (D) UsbExtremeVersion oueHeadersVersion(const(void)[] headers);
extern (D) int oueReadHeaders(ref UsbExtremeHeaders headers, const(void)[] rawHeaders);
extern (D) UsbExtremeFilestat[] oueRead(UsbExtremeFilestat[] filestats, const(UsbExtremeHeaders) headers);
extern (D) void oueGetName(char[] dest, const(UsbExtremeHeaders) headers, size_t offset);
extern (D) char[] oueFilename(char[] buffer, const(UsbExtremeHeaders) headers, size_t offset);
extern (D) size_t ouePartSize(const(UsbExtremeHeaders) headers, size_t offset);
private R[] castArray(R, T)(T[] array)
{
	auto ptr = array.ptr;
	auto castPtr = cast(R*)ptr;
	return castPtr[0..array.length * T.sizeof / R.sizeof];
}
__gshared uint[1024] crcTable;
private uint crc32(char[] name);
