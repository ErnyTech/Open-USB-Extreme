// D import file generated from '/home/erny/Open-USB-Extreme/lib/usbextreme.d'
module usbextreme;
import std.stdint;
enum USBEXTREME_NAME_LENGTH = 32;
enum USBEXTREME_ID_LENGTH = 15;
enum USBEXTREME_NAME_EXT_LENGTH = 10;
enum USBEXTREME_MAGIC = 8;
enum USBEXTREME_HEADER_SIZE = UsbExtremeBase.sizeof;
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
		uint8_t n_parts;
		uint8_t type;
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
		uint8_t n_parts;
		uint8_t type;
		uint16_t size;
		uint8_t videoMode;
		uint8_t usbExtremeVersion;
		uint8_t magic;
		char[USBEXTREME_NAME_EXT_LENGTH] nameExt;
	}
}
struct UsbExtremeHeaders
{
	const(void)* firstHeader;
	const(UsbExtremeBase)[] headers;
	int numHeaders;
	size_t headersLen;
	UsbExtremeVersion oueVersion;
}
struct UsbExtremeFilestat
{
	int offset;
	char[USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH] name;
	SCECdvdMediaType type;
	uint16_t size;
	uint8_t videoMode;
	UsbExtremeVersion usbExtremeVersion;
}
enum UsbExtremeVersion 
{
	V0 = 0,
	V1,
	Unknown,
}
enum SCECdvdMediaType 
{
	SCECdGDTFUNCFAIL = -1,
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
extern (D) UsbExtremeVersion getVersion(uint8_t usbExtremeVersion);
extern (D) int oueNumHeaders(const(void)[] headers);
extern (D) int ouePointHeaders(ref const(UsbExtremeBase)[] headers, const(void)[] rawHeaders);
extern (D) UsbExtremeVersion oueHeadersVersion(const(void)[] headers);
extern (D) int oueReadHeaders(ref UsbExtremeHeaders headers, const(void)[] rawHeaders);
extern (D) UsbExtremeFilestat[] oueRead(UsbExtremeFilestat[] filestats, const(UsbExtremeHeaders) headers);
private R[] castArray(R, T)(T[] array)
{
	auto ptr = array.ptr;
	auto castPtr = cast(R*)ptr;
	return castPtr[0..array.length * T.sizeof / R.sizeof];
}
