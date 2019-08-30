module usbextreme;
import std.stdint;

enum USBEXTREME_NAME_LENGTH = 32;
enum USBEXTREME_ID_LENGTH = 15;
enum USBEXTREME_NAME_EXT_LENGTH = 10;
enum USBEXTREME_MAGIC = 0x08;
enum USBEXTREME_HEADER_SIZE = UsbExtremeBase.sizeof;
enum USBEXTREME_FILESTAT_NAME_LENGTH = USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH;
enum USBEXTREME_PREFIX = "ul.";
enum USBEXTREME_CRC32_LENGTH = 8;
enum USBEXTREME_FILENAME_LENGTH = USBEXTREME_ID_LENGTH + USBEXTREME_CRC32_LENGTH + 1;
enum USBEXTREME_PART_SIZE_V0 = 0x40000000;

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
    uint8_t parts;
    SCECdvdMediaType type;
    uint8_t[4] empty;
    uint8_t magic;
    uint8_t[USBEXTREME_NAME_EXT_LENGTH] empty2;
}

align(1) struct UsbExtremeV1 {
    align(1):
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

struct UsbExtremeHeaders {
    const(void)* firstHeader;
    const(UsbExtremeBase)[] headers;
    size_t numHeaders;
    size_t headersLen;
    UsbExtremeVersion oueVersion;
}

struct UsbExtremeFilestat {
    size_t offset;
    char[USBEXTREME_FILESTAT_NAME_LENGTH] name;
    SCECdvdMediaType type;
    size_t partSize;
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
        oueGetName(filestat.name, headers, i);
        auto headerVersion = getVersion(header.usbExtremeVersion);
        auto partSize = ouePartSize(headers, i);
        uint8_t videoMode = 0;
        
        if (headerVersion >= 1) {
            videoMode = header.videoMode;
        } 

        filestat.partSize = partSize;
        filestat.type = header.type;
        filestat.offset = i;
        filestat.videoMode = videoMode;
        filestat.usbExtremeVersion = headerVersion;
        headersLength -= 1;
        fileStatsLength += 1;
    }
    
    return filestats[0..fileStatsLength];
}

extern(D) void oueGetName(char[] dest, const(UsbExtremeHeaders) headers, size_t offset) {
    auto headersFull = castArray!(UsbExtremeV1)(headers.headers);
    auto header = headersFull[offset];
    auto headerVersion = getVersion(header.usbExtremeVersion);

    dest[0..USBEXTREME_NAME_LENGTH] = header.name[0..$];

    if (headerVersion >= 1) {
        dest[USBEXTREME_NAME_LENGTH..USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH] = header.nameExt[0..$];
    }
}

extern(D) char[] oueFilename(char[] buffer, const(UsbExtremeHeaders) headers, size_t offset) {
    import core.stdc.stdio : snprintf;

    char[USBEXTREME_FILESTAT_NAME_LENGTH] name;
    auto headersFull = castArray!(UsbExtremeV1)(headers.headers);
    auto header = headersFull[offset];
    auto startupId = header.id[3..$];

    oueGetName(name, headers, offset);

    auto crc = crc32(name);

    snprintf(buffer.ptr, buffer.length, "%s%08X.%s", USBEXTREME_PREFIX.ptr, crc, startupId.ptr);
    return buffer;
}

extern(D) size_t ouePartSize(const(UsbExtremeHeaders) headers, size_t offset) {
    auto headersFull = castArray!(UsbExtremeV1)(headers.headers);
    auto header = headersFull[offset];
    auto headerVersion = getVersion(header.usbExtremeVersion);

    if (headerVersion >= 1) {
        return header.partSize * (2 ^^ 20);
    } else {
        return USBEXTREME_PART_SIZE_V0;
    }
}

private R[] castArray(R, T) (T[] array) { // Workaround for https://issues.dlang.org/show_bug.cgi?id=20088
    auto ptr = array.ptr;
    auto castPtr = cast(R*) ptr;
    return castPtr[0..((array.length * T.sizeof) / R.sizeof)];
}

__gshared uint[1024] crcTable;
private uint crc32(char[] name) {
    int crc;
    int count;

    foreach (table; 0 .. 256) {
        crc = table << 24;

        for (count = 8; count > 0; count--) {
            if (crc < 0) {
                crc = crc << 1;
            } else {
                crc = (crc << 1) ^ 0x04C11DB7;
            }
        }

         crcTable[255 - table] = crc;
    }

    do {
        auto singleChar = name[count++];
        crc = crcTable[singleChar ^ ((crc >> 24) & 0xFF)] ^ ((crc << 8) & 0xFFFFFF00);
    } while (name[count - 1] != 0);

    return crc;
}
