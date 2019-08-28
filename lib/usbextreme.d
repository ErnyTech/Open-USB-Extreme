module usbextreme;
import std.stdint;

enum USBEXTREME_NAME_LENGTH = 32;
enum USBEXTREME_ID_LENGTH = 15;
enum USBEXTREME_NAME_EXT_LENGTH = 10;
enum USBEXTREME_MAGIC = 0x08;
enum USBEXTREME_HEADER_SIZE = UsbExtremeBase.sizeof;

align(1) struct UsbExtremeBase {
    align(1):
    uint8_t[6 + USBEXTREME_ID_LENGTH + USBEXTREME_NAME_LENGTH] empty;
    uint8_t magic;
    uint8_t[10] empty2;
}

align(1) struct UsbExtremeV0 {
    align(1):
    char[USBEXTREME_NAME_LENGTH] name;
    char[USBEXTREME_ID_LENGTH] id;
    uint8_t n_parts;
    SCECdvdMediaType type;
    uint8_t[4] empty;
    uint8_t magic;
    uint8_t[USBEXTREME_NAME_EXT_LENGTH] empty2;
}

align(1) struct UsbExtremeV1 {
    align(1):
    char[USBEXTREME_NAME_LENGTH] name;
    char[USBEXTREME_ID_LENGTH] id;
    uint8_t n_parts;
    SCECdvdMediaType type;
    uint16_t size;
    uint8_t videoMode;
    UsbExtremeVersion usbExtremeVersion;
    uint8_t magic;
    char[USBEXTREME_NAME_EXT_LENGTH] nameExt;
}

struct UsbExtremeHeaders {
    const(void)* firstHeader;
    const(UsbExtremeBase)[] headers;
    size_t numHeaders;
    size_t headersLen;
    UsbExtremeVersion oueVersion;
}

struct UsbExtremeFilestat {
    size_t offset;
    char[USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH] name;
    SCECdvdMediaType type;
    uint16_t size;
    uint8_t videoMode;
    UsbExtremeVersion usbExtremeVersion;
}

enum UsbExtremeVersion : uint8_t {
    V0 = 0x00,
    V1,
    Unknown
}

enum SCECdvdMediaType : uint8_t {
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
    auto headersOeu = castArray!(const UsbExtremeBase)(headers);
    
    foreach (header; headersOeu) {
        if (header.magic != USBEXTREME_MAGIC) {
            return false;
        }
    }
    
    return true;
}

extern(D) UsbExtremeVersion getVersion(UsbExtremeVersion usbExtremeVersion) {
    switch (usbExtremeVersion) {
        case UsbExtremeVersion.V0: {
            return UsbExtremeVersion.V0;
        }

        case UsbExtremeVersion.V1: {
            return UsbExtremeVersion.V1;
        }

        default: {
            return UsbExtremeVersion.V0;
        }
    }
}

extern(D) size_t oueNumHeaders(const(void)[] headers) {
    auto headersLen = castArray!(UsbExtremeBase)(headers).length;

    if (!isOue(headers)) {
        return -1;
    }

    return headersLen;
}

extern(D) size_t ouePointHeaders(ref const(UsbExtremeBase)[] headers, const(void)[] rawHeaders) {
    auto headersLen = oueNumHeaders(rawHeaders);

    if (headersLen <= 0) {
        return -1;
    }

    headers = castArray!(const(UsbExtremeBase))(rawHeaders)[];
    return headersLen;
}

extern(D) UsbExtremeVersion oueHeadersVersion(const(void)[] headers) {
    auto headersOeu = castArray!(UsbExtremeV1)(headers);
    auto firstVersion = UsbExtremeVersion.V0;

    if (!isOue(headers)) {
        return UsbExtremeVersion.Unknown;
    }

    foreach (i, header; headersOeu) {
        if (i == 0) {
            firstVersion = getVersion(header.usbExtremeVersion);
        } else {
            if (firstVersion != getVersion(header.usbExtremeVersion)) {
                return UsbExtremeVersion.V0;
            }
        }
    }

    return firstVersion;
}

extern(D) int oueReadHeaders(ref UsbExtremeHeaders headers, const(void)[] rawHeaders) {    
    auto oueVersion = oueHeadersVersion(rawHeaders);
    auto numHeaders = oueNumHeaders(rawHeaders);
    
    if (!isOue(rawHeaders)) {
        return -1;
    }
    
    if (oueVersion == UsbExtremeVersion.Unknown) {
        return -1;
    }
    
    auto headersArr = castArray!(UsbExtremeBase)(rawHeaders);
    headers = UsbExtremeHeaders(rawHeaders.ptr,
            headersArr,
            numHeaders,
            rawHeaders.length,
            oueVersion);
    return 1;
}

extern(D) UsbExtremeFilestat[] oueRead(UsbExtremeFilestat[] filestats, const(UsbExtremeHeaders) headers) {   
    auto headersFull = castArray!(UsbExtremeV1)(headers.headers);
    auto headersLength = headersFull.length;
    int fileStatsLength = 0;
    
    foreach (i, ref filestat; filestats) {
        if (headersLength == 0) {
            return filestats[0..i];
        }
        
        auto header = headersFull[i];
        filestat.name[0..USBEXTREME_NAME_LENGTH] = header.name[0..$];
        auto headerVersion = getVersion(header.usbExtremeVersion);
        uint16_t size = 0;
        uint8_t videoMode = 0;
        
        if (headerVersion >= 1) {
            size = header.size;
            videoMode = header.videoMode;
            filestat.name[USBEXTREME_NAME_LENGTH..USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH] = header.nameExt[0..$];
        }
        
        filestat.size = size;
        filestat.type = header.type;
        filestat.offset = i;
        filestat.videoMode = videoMode;
        filestat.usbExtremeVersion = headerVersion;
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
