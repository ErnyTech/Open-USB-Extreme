module cabi;
import std.stdint;
import usbextreme;

extern(C) int is_oue(const(void)* headers, size_t headerslen) {
    return isOue(headers[0..headerslen]);
}

extern(C) UsbExtremeVersion get_version(uint8_t usbExtremeVersion) {
    return getVersion(usbExtremeVersion);
}

extern(C) int oue_num_headers(int *num_headers, const(void) *headers, size_t headerslen) {
    auto result = oueNumHeaders(headers[0..headerslen]);
    *num_headers = result;
    return result;
}

extern(C) int oue_point_headers(const(usb_extreme_base)** headers, const(void)* raw_headers, size_t headerslen) {
    auto len = headerslen / usb_extreme_base.sizeof;
    const(usb_extreme_base)[] headersArr = (*headers)[0..len];
    return ouePointHeaders(headersArr, raw_headers[0..headerslen]);
}

extern(C) int oue_version(UsbExtremeVersion* oueVersion, const(void) *headers, size_t headerslen) {
    auto result = oueHeadersVersion(headers[0..headerslen]);
    
    if (result == UsbExtremeVersion.Unknown) {
        return -1;
    }
    
    *oueVersion = result;
    return 1;
}

extern(C) int oue_read_headers(usb_extreme_headers* headers, const(void)* raw_headers, size_t headerslen) {
    return oueReadHeaders(*headers, raw_headers[0..headerslen]);
}

extern(C) int oue_read(usb_extreme_filestat* filestat, const(usb_extreme_headers) headers, int filestats_nlen) {
    auto result = oueRead(filestat[0..filestats_nlen], headers);
    return cast(int) result.length;
}
