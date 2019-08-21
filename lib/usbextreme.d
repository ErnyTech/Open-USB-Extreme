module usbextreme;
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

struct usb_extreme_headers {
    const(void)* first_header;
    const(usb_extreme_base)* headers;
    int num_headers;
    size_t headerslen;
    UsbExtremeVersion oueVersion;
}

struct usb_extreme_filestat {
    int offset;
    char[USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH] name;
    SCECdvdMediaType type;
    uint16_t size;
    uint8_t video_mode;
    UsbExtremeVersion usb_extreme_version;
}

enum UsbExtremeVersion {
    V0 = 0x00,
    V1
}

enum SCECdvdMediaType {
    SCECdGDTFUNCFAIL	= -1,
    SCECdNODISC		= 0x00,
    SCECdDETCT,
    SCECdDETCTCD,
    SCECdDETCTDVDS,
    SCECdDETCTDVDD,
    SCECdUNKNOWN,

    SCECdPSCD		= 0x10,
    SCECdPSCDDA,
    SCECdPS2CD,
    SCECdPS2CDDA,
    SCECdPS2DVD,

    SCECdCDDA		= 0xFD,
    SCECdDVDV,
    SCECdIllegalMediaoffset
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

extern(C) int oue_read_headers(usb_extreme_headers* headers, const(void)* raw_headers, size_t headerslen) {
    const(usb_extreme_base)* headers_ptr;
    UsbExtremeVersion oueVersion;
    auto num_headers = cast(int) (headerslen / USBEXTREME_HEADER_SIZE);
    usb_extreme_headers headers_temp = {null, null, 0, 0, UsbExtremeVersion.V0};

    if (oue_point_headers(&headers_ptr, raw_headers, headerslen) <= 0) {
            return -1;
    }

    if (oue_version(&oueVersion, raw_headers, headerslen) <= 0) {
        return -1;
    }

    headers_temp.first_header = raw_headers;
    headers_temp.headers = headers_ptr;
    headers_temp.num_headers = num_headers;
    headers_temp.headerslen = headerslen;
    headers_temp.oueVersion = oueVersion;
    *headers = headers_temp;
    return 1;
}

extern(C) int oue_read(usb_extreme_filestat* filestat, const(usb_extreme_headers) headers, int filestats_nlen) {
    import core.stdc.string : strncpy, strncat;
    
    int offset = filestats_nlen;
    auto headers_full = cast(usb_extreme_v1*) headers.headers;
    usb_extreme_v1 header;
    usb_extreme_filestat filestats_temp = {0, ['0'], SCECdvdMediaType.SCECdNODISC, 0, 0, UsbExtremeVersion.V0};
    uint16_t size = 0;
    uint8_t video_mode = 0;
    uint8_t usb_extreme_version;
    int i;

    for(i = 0; i < headers.num_headers; i++) {
        if(offset == 0) {
            return i;
        }

        header = headers_full[i];
        strncpy(filestats_temp.name.ptr, header.name.ptr, USBEXTREME_NAME_LENGTH);
        usb_extreme_version = header.usb_extreme_version;

        if(usb_extreme_version >= 1) {
            size = header.size;
            video_mode = header.video_mode;
            strncat(filestats_temp.name.ptr, header.name_ext.ptr, USBEXTREME_NAME_EXT_LENGTH);
        }

        filestats_temp.size = size;
        filestats_temp.type = cast(SCECdvdMediaType) header.type;
        filestats_temp.offset = i;
        filestats_temp.video_mode = video_mode;
        filestats_temp.usb_extreme_version = cast(UsbExtremeVersion) usb_extreme_version;
        filestat[i] = filestats_temp;
        offset -= 1;
    }

    return i;
}
