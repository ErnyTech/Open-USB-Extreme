#ifndef USBEXTREME_H
#define USBEXTREME_H

#ifndef u8
   #include <stdint.h>
   typedef uint8_t u8;
   typedef uint16_t u16;
#endif

#ifndef size_t
   #include <stddef.h>
#endif

#define USBEXTREME_NAME_LENGTH 32
#define USBEXTREME_ID_LENGTH 15
#define USBEXTREME_NAME_EXT_LENGTH 10
#define USBEXTREME_MAGIC 0x08

typedef enum {
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
} SCECdvdMediaType;

typedef enum {
    USB_EXTREME_V0 = 0x00,
    USB_EXTREME_V1,
    USB_EXTREME_UNKNOWN
} usb_extreme_versions;

typedef struct __attribute__((__packed__)) {
    u8 empty[6 + USBEXTREME_ID_LENGTH + USBEXTREME_NAME_LENGTH];
    u8 magic;
    u8 empty2[10];
} usb_extreme_base;

typedef struct __attribute__((__packed__)) {
    char name[USBEXTREME_NAME_LENGTH];
    char id[USBEXTREME_ID_LENGTH];
    u8 n_parts;
    u8 type;
    u8 empty[4];
    u8 magic;
    u8 empty2[USBEXTREME_NAME_EXT_LENGTH];
} usb_extreme_v0;

typedef struct __attribute__((__packed__)) {
    char name[USBEXTREME_NAME_LENGTH];
    char id[USBEXTREME_ID_LENGTH];
    u8 n_parts;
    u8 type;
    u16 size;
    u8 video_mode;
    u8 usb_extreme_version;
    u8 magic;
    char name_ext[USBEXTREME_NAME_EXT_LENGTH];
} usb_extreme_v1;

typedef struct {
    size_t offset;
    char name[USBEXTREME_NAME_LENGTH + USBEXTREME_NAME_EXT_LENGTH];
    SCECdvdMediaType type;
    u16 size;
    u8 video_mode;
    usb_extreme_versions usb_extreme_version;
} usb_extreme_filestat;

typedef struct {
    void *first_header;
    usb_extreme_base *headers;
    size_t num_headers;
    size_t headerslen;
    usb_extreme_versions version;
} usb_extreme_headers;

#define USBEXTREME_HEADER_SIZE sizeof(usb_extreme_base)

/* Global headers functions */
int is_oue(const void *headers, const size_t headerslen);
usb_extreme_versions get_version(u8 version);
size_t oue_point_headers(usb_extreme_base **headers, void *raw_headers, size_t headerslen);
size_t oue_num_headers(size_t *num_headers, const void *headers, size_t headerslen);
int oue_version(usb_extreme_versions *version, const void *headers, size_t headerslen);
int oue_read_headers(usb_extreme_headers *headers, void *raw_headers, const size_t headerslen);

/* Read functions */
size_t oue_read(usb_extreme_filestat *filestats, const usb_extreme_headers headers, const int filestats_nlen);

/* implementation in development
 *
int oue_add(usb_extreme_headers *headers, const usb_extreme_filestat filestat);

int oue_edit(usb_extreme_headers *headers, const usb_extreme_filestat filestat);

int oue_remove(usb_extreme_headers *headers, const usb_extreme_filestat filestat);
*/

#endif /* !USBEXTREME_H */
