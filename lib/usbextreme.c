#include <usbextreme.h>
#include <string.h>

int oue_read_headers(usb_extreme_headers *headers, void *raw_headers, const size_t headerslen) {
    usb_extreme_base *headers_ptr;
    usb_extreme_versions version;
    int num_headers = (int) (headerslen / USBEXTREME_HEADER_SIZE);
    usb_extreme_headers headers_temp = {NULL, NULL, 0, 0, 0};

    if(oue_point_headers(&headers_ptr, raw_headers, headerslen) <= 0) {
            return -1;
    }

    if(oue_version(&version, raw_headers, headerslen) <= 0) {
        return -1;
    }

    headers_temp.first_header = raw_headers;
    headers_temp.headers = headers_ptr;
    headers_temp.num_headers = num_headers;
    headers_temp.headerslen = headerslen;
    headers_temp.version = version;
    *headers = headers_temp;
    return 1;
}

int oue_read(usb_extreme_filestat *filestat, const usb_extreme_headers headers, const int filestats_nlen) {
    int offset = filestats_nlen;
    usb_extreme_v1 *headers_full = (usb_extreme_v1*) headers.headers;
    usb_extreme_v1 header;
    usb_extreme_filestat filestats_temp = {0, {'0'}, 0, 0, 0, 0};
    u16 size = 0;
    u8 video_mode = 0;
    u8 usb_extreme_version;
    int i;

    for(i = 0; i < headers.num_headers; i++) {
        if(offset == 0) {
            return i;
        }

        header = headers_full[i];
        strncpy(filestats_temp.name, header.name, USBEXTREME_NAME_LENGTH);
        usb_extreme_version = header.usb_extreme_version;

        if(usb_extreme_version >= 1) {
            size = header.size;
            video_mode = header.video_mode;
            strncat(filestats_temp.name, header.name_ext, USBEXTREME_NAME_EXT_LENGTH);
        }

        filestats_temp.size = size;
        filestats_temp.type = header.type;
        filestats_temp.offset = i;
        filestats_temp.video_mode = video_mode;
        filestats_temp.usb_extreme_version = usb_extreme_version;
        filestat[i] = filestats_temp;
        offset -= 1;
    }

    return i;
}
