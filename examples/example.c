#include <stdio.h>
#include <stdlib.h>
#include <usbextreme.h>

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: open-usbextreme-example <path/to/ul.cfg>\n");
        return 1;
    }

    FILE *f = fopen(argv[1], "rb");
    fseek(f, 0, SEEK_END);
    long fsize = ftell(f);

    if (fsize <= 0) {
        return 1;
    }

    unsigned long size = *(unsigned long*) &fsize;
    fseek(f, 0, SEEK_SET);

    void *data = malloc(size + 1);
    fread(data, size, 1, f);
    fclose(f);

    usb_extreme_headers headers;

    if(oue_read_headers(&headers, data, size) <= 0) {
       return 1;
    }

    usb_extreme_filestat filestats[10];
    int nstats = oue_read(filestats, headers, 10);

    int i;
    for(i = 0; i < nstats; i++) {
        printf("Game name [%d]: %s\n", filestats[i].offset, filestats[i].name);
    }
    return 0;
}
