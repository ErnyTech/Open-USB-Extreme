// D import file generated from 'usbextreme.d'
module usbextreme;
import std.stdint;
enum USBEXTREME_NAME_LENGTH = 32;
enum USBEXTREME_ID_LENGTH = 15;
enum USBEXTREME_NAME_EXT_LENGTH = 10;
enum USBEXTREME_MAGIC = 8;
enum USBEXTREME_HEADER_SIZE = usb_extreme_base.sizeof;
align (1) struct usb_extreme_base
{
	align (1) 
	{
		uint8_t[6 + USBEXTREME_ID_LENGTH + USBEXTREME_NAME_LENGTH] empty;
		uint8_t magic;
		uint8_t[10] empty2;
	}
}
align (1) struct usb_extreme_v0
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
align (1) struct usb_extreme_v1
{
	align (1) 
	{
		char[USBEXTREME_NAME_LENGTH] name;
		char[USBEXTREME_ID_LENGTH] id;
		uint8_t n_parts;
		uint8_t type;
		uint16_t size;
		uint8_t video_mode;
		uint8_t usb_extreme_version;
		uint8_t magic;
		char[USBEXTREME_NAME_EXT_LENGTH] name_ext;
	}
}
struct usb_extreme_headers
{
	const(void)* first_header;
	const(usb_extreme_base)* headers;
	int num_headers;
	size_t headerslen;
	UsbExtremeVersion oueVersion;
}
struct usb_extreme_filestat
{
	int offset;
	char[USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH] name;
	SCECdvdMediaType type;
	uint16_t size;
	uint8_t video_mode;
	UsbExtremeVersion usb_extreme_version;
}
enum UsbExtremeVersion 
{
	V0 = 0,
	V1,
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
extern (C) int isOue(const(void)* headers, size_t headerslen);
extern (D) UsbExtremeVersion getVersion(uint8_t usbExtremeVersion);
extern (D) int oueNumHeaders(ref int num_headers, const(void)* headers, size_t headerslen);
extern (D) int ouePointHeaders(ref const(usb_extreme_base)* headers, const(void)* raw_headers, size_t headerslen);
extern (D) int oueHeadersVersion(ref UsbExtremeVersion oueVersion, const(void)* headers, size_t headerslen);
extern (D) int oueReadHeaders(ref usb_extreme_headers headers, const(void)* raw_headers, size_t headerslen);
extern (D) int oueRead(usb_extreme_filestat[] filestat, const(usb_extreme_headers) headers);
