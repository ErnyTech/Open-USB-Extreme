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
    const(usb_extreme_base)[] headers;
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
    V1,
    Unknown
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

extern(D) bool isOue(const(void)[] headers) {
    auto headers_oeu = castArray!(const usb_extreme_base)(headers);
    
    foreach (header; headers_oeu) {
        if (header.magic != USBEXTREME_MAGIC) {
            return false;
        }
    }
    
    return true;
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

extern(D) int oueNumHeaders(const(void)[] headers) {
    auto headers_nlen = cast(int) (castArray!(usb_extreme_base)(headers).length);

    if (!isOue(headers)) {
        return -1;
    }

    return headers_nlen;
}

extern(D) int ouePointHeaders(ref const(usb_extreme_base)[] headers, const(void)[] raw_headers) {
    auto headers_nlen = oueNumHeaders(raw_headers);

    if (headers_nlen <= 0) {
        return -1;
    }

    headers = castArray!(const(usb_extreme_base))(raw_headers)[];
    return headers_nlen;
}

extern(D) UsbExtremeVersion oueHeadersVersion(const(void)[] headers) {
    auto headers_oeu = castArray!(usb_extreme_v1)(headers);
    auto first_version = UsbExtremeVersion.V0;

    if (!isOue(headers)) {
        return UsbExtremeVersion.Unknown;
    }

    foreach (i, header; headers_oeu) {
        if (i == 0) {
            first_version = getVersion(header.usb_extreme_version);
        } else {
            if (first_version != getVersion(header.usb_extreme_version)) {
                return UsbExtremeVersion.V0;
            }
        }
    }

    return first_version;
}

extern(D) int oueReadHeaders(ref usb_extreme_headers headers, const(void)[] raw_headers) {    
    auto oueVersion = oueHeadersVersion(raw_headers);
    auto num_headers = oueNumHeaders(raw_headers);
    
    if (!isOue(raw_headers)) {
        return -1;
    }
    
    if (oueVersion == UsbExtremeVersion.Unknown) {
        return -1;
    }
    
    auto headersArr = castArray!(usb_extreme_base)(raw_headers);
    headers = usb_extreme_headers(raw_headers.ptr,
            headersArr,
            num_headers,
            raw_headers.length,
            oueVersion);
    return 1;
}

extern(D) usb_extreme_filestat[] oueRead(usb_extreme_filestat[] filestats, const(usb_extreme_headers) headers) {   
    auto headers_full = castArray!(usb_extreme_v1)(headers.headers);
    auto headersLength = headers_full.length;
    int fileStatsLength = 0;
    
    foreach (i, ref filestat; filestats) {
        if (headersLength == 0) {
            return filestats[0..i];
        }
        
        auto header = headers_full[i];
        filestat.name[0..USBEXTREME_NAME_LENGTH] = header.name[0..$];
        auto headerVersion = getVersion(header.usb_extreme_version);
        uint16_t size = 0;
        uint8_t videoMode = 0;
        
        if (headerVersion >= 1) {
            size = header.size;
            videoMode = header.video_mode;
            filestat.name[USBEXTREME_NAME_LENGTH..USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH] = header.name_ext[0..$];
        }
        
        filestat.size = size;
        filestat.type = cast(SCECdvdMediaType) header.type;
        filestat.offset = cast(int) i;
        filestat.video_mode = videoMode;
        filestat.usb_extreme_version = headerVersion;
        headersLength -= 1;
        fileStatsLength += 1;
    }
    
    return filestats[0..fileStatsLength];
}

private R[] castArray(R, T) (T[] array) { // Workaround for https://issues.dlang.org/show_bug.cgi?id=20088
    auto ptr = array.ptr;
    auto castPtr = cast(R*) ptr;
    return castPtr[0..((array.length * T.sizeof) / R.sizeof)];
}
