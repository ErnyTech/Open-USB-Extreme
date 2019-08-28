import core.stdc.stdio;
import core.stdc.stdlib;
import usbextreme;

extern(C) int main(int argc, char[]* argv) {
    UsbExtremeHeaders headers;
    UsbExtremeFilestat[10] filestatsBuf = void;

    if (argc < 2) {
        printf("Usage: open-usbextreme-example <path/to/ul.cfg>\n");
        return 1;
    }
    
    auto f = fopen(argv[0].ptr, "rb");
    
    if (!f) {
        printf("Open error with file: %s\n", argv[0].ptr);
        return 1;
    }
    
    fseek(f, 0, SEEK_END);
    auto fsize = ftell(f);
    
    if (fsize <= 0) {
        return 1;
    }
    
    auto size = *(cast(ulong*) &fsize);
    fseek(f, 0, SEEK_SET);

    auto data = malloc(size + 1);
    fread(data, size, 1, f);
    fclose(f);

    if (oueReadHeaders(headers, data[0..size]) <= 0) {
       return 1;
    }
    
    auto filestats = oueRead(filestatsBuf, headers);

    foreach (filestat; filestats) {
        printf("Game name [%d]: %s\n", filestat.offset, filestat.name.ptr);
    }
    
    return 0;
}
