module cabi;
import std.stdint;
import usbextreme;

extern(C) int is_oue(const(void)* headers, size_t headerslen) {
    return isOue(headers, headerslen);
}

extern(C) UsbExtremeVersion get_version(uint8_t usbExtremeVersion) {
    return getVersion(usbExtremeVersion);
}

extern(C) int oue_num_headers(int *num_headers, const(void) *headers, size_t headerslen) {
    return oueNumHeaders(*num_headers, headers, headerslen);
}

extern(C) int oue_point_headers(const(usb_extreme_base)** headers, const(void)* raw_headers, size_t headerslen) {
    return ouePointHeaders(*headers, raw_headers, headerslen);
}

extern(C) int oue_version(UsbExtremeVersion* oueVersion, const(void) *headers, size_t headerslen) {
    return oueHeadersVersion(*oueVersion, headers, headerslen);
}

extern(C) int oue_read_headers(usb_extreme_headers* headers, const(void)* raw_headers, size_t headerslen) {
    return oueReadHeaders(*headers, raw_headers, headerslen);
}

extern(C) int oue_read(usb_extreme_filestat* filestat, const(usb_extreme_headers) headers, int filestats_nlen) {
    return oueRead(filestat[0..filestats_nlen], headers);
}
