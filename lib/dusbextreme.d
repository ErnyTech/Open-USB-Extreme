module dusbextreme;
import std.stdint;

enum USBEXTREME_NAME_LENGTH = 32;
enum USBEXTREME_ID_LENGTH = 15;
enum USBEXTREME_NAME_EXT_LENGTH = 10;
enum USBEXTREME_MAGIC = 0x08;
enum USBEXTREME_HEADER_SIZE = usb_extreme_base.sizeof;

align(1) struct usb_extreme_base {
    align(1):
    uint8_t[6 + USBEXTREME_ID_LENGTH + USBEXTREME_NAME_LENGTH] empty;
    uint8_t magic;
    uint8_t[10] empty2;
}

align(1) struct usb_extreme_v0 {
    align(1):
    char[USBEXTREME_NAME_LENGTH] name;
    char[USBEXTREME_ID_LENGTH] id;
    uint8_t n_parts;
    uint8_t type;
    uint8_t[4] empty;
    uint8_t magic;
    uint8_t[USBEXTREME_NAME_EXT_LENGTH] empty2;
}

align(1) struct usb_extreme_v1 {
    align(1):
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

enum UsbExtremeVersion  {
    V0 = 0x00,
    V1
}

extern(C) int is_oue(const(void)* headers, size_t headerslen) {
    const headers_oeu = cast(const usb_extreme_base*) headers;
    auto headers_nlen = headerslen / USBEXTREME_HEADER_SIZE;
    
    for (auto i = 0; i < headers_nlen; i++) {
        auto header = headers_oeu[i];
        
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

extern(C) int oue_num_headers(int *num_headers, const(void) *headers, size_t headerslen) {
    auto headers_nlen = cast(int) (headerslen / USBEXTREME_HEADER_SIZE);

    if (!is_oue(headers, headerslen)) {
        return -1;
    }

    *num_headers = headers_nlen;
    return headers_nlen;
}

extern(C) int oue_point_headers(const(usb_extreme_base)** headers, const(void)* raw_headers, size_t headerslen) {
    int headers_nlen;

    if (oue_num_headers(&headers_nlen, raw_headers, headerslen) <= 0) {
        return -1;
    }

    *headers = cast(const(usb_extreme_base)*) raw_headers;
    return headers_nlen;
}

extern(C) int oue_version(UsbExtremeVersion* oueVersion, const(void) *headers, size_t headerslen) {
    auto headers_oeu = cast(usb_extreme_v1*) headers;
    auto headers_nlen = headerslen / USBEXTREME_HEADER_SIZE;
    auto first_version = UsbExtremeVersion.V0;
    int i;

    if(!is_oue(headers, headerslen)) {
        return -1;
    }

    for(i = 0; i < headers_nlen; i++) {
        auto header = headers_oeu[i];

        if (i == 0) {
            first_version = get_version(header.usb_extreme_version);
        } else {
            if (first_version != get_version(header.usb_extreme_version)) {
                *oueVersion = UsbExtremeVersion.V0;
                return -2;
            }
        }
    }

    *oueVersion = first_version;
    return 1;
}
