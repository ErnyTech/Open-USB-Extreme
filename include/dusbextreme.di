// D import file generated from 'dusbextreme.d'
module dusbextreme;
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
enum UsbExtremeVersion 
{
	V0 = 0,
	V1,
}
extern (C) int is_oue(const(void)* headers, size_t headerslen);
extern (C) UsbExtremeVersion get_version(uint8_t usbExtremeVersion);
extern (C) int oue_num_headers(int* num_headers, const(void)* headers, size_t headerslen);
extern (C) int oue_point_headers(const(usb_extreme_base)** headers, const(void)* raw_headers, size_t headerslen);
extern (C) int oue_version(UsbExtremeVersion* oueVersion, const(void)* headers, size_t headerslen);
