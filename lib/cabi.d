module cabi;
import std.stdint;
import usbextreme;

extern(C) int is_oue(const(void)* headers, size_t headersLen) {
    return isOue(headers[0..headersLen]);
}

extern(C) UsbExtremeVersion get_version(uint8_t usbExtremeVersion) {
    return getVersion(cast(UsbExtremeVersion) usbExtremeVersion);
}

extern(C) size_t oue_num_headers(size_t *numHeaders, const(void) *headers, size_t headersLen) {
    auto result = oueNumHeaders(headers[0..headersLen]);
    *numHeaders = result;
    return result;
}

extern(C) size_t oue_point_headers(const(UsbExtremeBase)** headers, const(void)* rawHeaders, size_t headersLen) {
    auto len = headersLen / UsbExtremeBase.sizeof;
    const(UsbExtremeBase)[] headersArr = (*headers)[0..len];
    return ouePointHeaders(headersArr, rawHeaders[0..headersLen]);
}

extern(C) int oue_version(UsbExtremeVersion* oueVersion, const(void) *headers, size_t headersLen) {
    auto result = oueHeadersVersion(headers[0..headersLen]);
    
    if (result == UsbExtremeVersion.Unknown) {
        return -1;
    }
    
    *oueVersion = result;
    return 1;
}

extern(C) int oue_read_headers(UsbExtremeHeaders* headers, const(void)* rawHeaders, size_t headersLen) {
    return oueReadHeaders(*headers, rawHeaders[0..headersLen]);
}

extern(C) size_t oue_read(UsbExtremeFilestat* filestat, const(UsbExtremeHeaders) headers, int filestatsLen) {
    auto result = oueRead(filestat[0..filestatsLen], headers);
    return result.length;
}

extern(C) void oue_get_name(char* dest, size_t length, const(UsbExtremeHeaders) headers, size_t offset) {
    oueGetName(dest[0..length], headers, offset);
}

extern(C) void oue_filename(char* buffer, size_t length, const(UsbExtremeHeaders) headers, size_t offset) {
    oueFilename(buffer[0..length], headers, offset);
}

extern(C) size_t oue_part_size(const(UsbExtremeHeaders) headers, size_t offset) {
    return ouePartSize(headers, offset);
}
