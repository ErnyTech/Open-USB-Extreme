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

extern(D) int isOue(const(void)[] headers) {
    auto headers_oeu = castArray!(const usb_extreme_base)(headers);
    
    foreach (header; headers_oeu) {
        if (header.magic != USBEXTREME_MAGIC) {
            return 0;
        }
    }
    
    return 1;
}

extern(D) UsbExtremeVersion getVersion(uint8_t usbExtremeVersion) {
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

extern(D) int oueNumHeaders(ref int num_headers, const(void)[] headers) {
    auto headers_nlen = cast(int) (castArray!(usb_extreme_base)(headers).length);

    if (!isOue(headers)) {
        return -1;
    }

    num_headers = headers_nlen;
    return headers_nlen;
}

extern(D) int ouePointHeaders(ref const(usb_extreme_base)[] headers, const(void)[] raw_headers) {
    int headers_nlen;

    if (oueNumHeaders(headers_nlen, raw_headers) <= 0) {
        return -1;
    }

    headers = castArray!(const(usb_extreme_base))(raw_headers)[];
    return headers_nlen;
}

extern(D) int oueHeadersVersion(ref UsbExtremeVersion oueVersion, const(void)[] headers) {
    auto headers_oeu = castArray!(usb_extreme_v1)(headers);
    auto first_version = UsbExtremeVersion.V0;

    if (!isOue(headers)) {
        return -1;
    }

    foreach (i, header; headers_oeu) {
        if (i == 0) {
            first_version = getVersion(header.usb_extreme_version);
        } else {
            if (first_version != getVersion(header.usb_extreme_version)) {
                oueVersion = UsbExtremeVersion.V0;
                return -2;
            }
        }
    }

    oueVersion = first_version;
    return 1;
}

extern(D) int oueReadHeaders(ref usb_extreme_headers headers, const(void)[] raw_headers) {    
    UsbExtremeVersion oueVersion;
    auto num_headers = cast(int) (raw_headers.length / USBEXTREME_HEADER_SIZE);
    
    if (!isOue(raw_headers)) {
        return -1;
    }
    
    if (oueHeadersVersion(oueVersion, raw_headers) <= 0) {
        return -1;
    }
    
    auto headersArr = castArray!(usb_extreme_base)(raw_headers);
    headers = usb_extreme_headers(raw_headers.ptr,
            headersArr.ptr,
            num_headers,
            raw_headers.length,
            oueVersion);
    return 1;
}

extern(D) int oueRead(usb_extreme_filestat[] filestat, const(usb_extreme_headers) headers) {
    import core.stdc.string : strncpy, strncat;
    
    int offset = cast(int) filestat.length;
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

private R[] castArray(R, T) (T[] array) { // Workaround for https://issues.dlang.org/show_bug.cgi?id=20088
    auto ptr = array.ptr;
    auto castPtr = cast(R*) ptr;
    return castPtr[0..((array.length * T.sizeof) / R.sizeof)];
}
