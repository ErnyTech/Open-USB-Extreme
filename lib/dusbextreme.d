module dusbextreme;
import std.stdint;

enum USBEXTREME_NAME_LENGTH = 32;
enum USBEXTREME_ID_LENGTH = 15;
enum USBEXTREME_NAME_EXT_LENGTH = 10;
enum USBEXTREME_MAGIC = 0x08;
enum USBEXTREME_HEADER_SIZE = usb_extreme_base.sizeof;

struct usb_extreme_base {
    uint8_t[6 + USBEXTREME_ID_LENGTH + USBEXTREME_NAME_LENGTH] empty;
    uint8_t magic;
    uint8_t[10] empty2;
}

enum UsbExtremeVersion  {
    V0 = 0x00,
    V1
}

extern(C) int is_oue(immutable(void)* headers, immutable(size_t) headerslen) {
    immutable headers_oeu = cast(immutable usb_extreme_base*) headers;
    immutable headers_nlen = headerslen / USBEXTREME_HEADER_SIZE;
    
    for (auto i = 0; i < headers_nlen; i++) {
        immutable header = headers_oeu[i];
        
        if (header.magic != USBEXTREME_MAGIC) {
            return 0;
        }
    }
    
    return 1;
}

extern(C) UsbExtremeVersion get_version(uint8_t usbExtremeVersion) {
    switch (usbExtremeVersion) {
        case 0: {
            return UsbExtremeVersion.V0;
        }

        case 1: {
            return UsbExtremeVersion.V1;
        }

        default: {
            return UsbExtremeVersion.V1;
        }
    }
}

extern(C) int oue_num_headers(int *num_headers, immutable(void) *headers, size_t headerslen) {
    auto headers_nlen = cast(int) (headerslen / USBEXTREME_HEADER_SIZE);

    if (!is_oue(headers, headerslen)) {
        return -1;
    }

    *num_headers = headers_nlen;
    return headers_nlen;
}
