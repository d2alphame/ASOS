; The boot sector of ASOS
[Bits 16]
[Org 0x7C00]

jmp 0x00:MAIN                                       ; Jump over asos filesystem data below and also set cs = 0
        align 8                                     ; ASOS filesystem requires this
LABEL:                  db "ASOS            "       ; Label. 16 Filename characters padded with spaces
SECTOR_COUNT:           dq 0x400000                 ; Number of sectors on the disk
BYTES_PER_SECTOR:       db 0x01                     ; 2 ^ (1 + 8) = 2 ^ 9 = 512
SECTORS_PER_CLUSTER:    db 0x03                     ; 2 ^ 3 = 8. Using 8 sectors per cluster
FS_VERSION:             dw 0x0100                   ; Version 1.0. Major version in upper byte, minor version in lower byte
SIGNATURE:              dw 0xA51                    ; Signature of the tool, program, or system that created this filesystem
LAST_CLUSTER:           dw 0xFFFF                   ; Number of clusters that make up this filesystem - 1. This implies there are 0x10000 (65536) clusters
LBA_FIRST:              dq 0x00                     ; LBA of first sector of this filesystem
LBA_LAST:               dq 0x7FFFF                  ; LBA of last sector of the filesystem