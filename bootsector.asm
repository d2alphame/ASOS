; The boot sector of ASOS
[Bits 16]

; I know the boot sector will be loaded at 0x7C00, however, it will relocate itself to 0x600 and will spend
; most of its lifetime there. So it makes more sense to have Org 0x600 instead of 0x7C00
[Org 0x600]        

jmp MAIN                                            ; Jump over asos filesystem data below
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
FREE_FOR_CUSTOM_USE:    dq 0x00                     ; Free for custom use
RESERVED:               dq 0x00                     ; Reserved for future use
FLAGS:                  dd 0x00                     ; Flags. Not in use for now
XOR_CHECKSUM:           dd 0x00                     ; XOR checksum of the above struc (starting from the jump instruction down to the flags)

MAIN:
    cli                                             ; Clear interrupts. No interruptions before we're done setting up
    
    ; Setup a flat segment with cs = ds = es = ss = 0
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x600                                   ; Use 0x500 to 0x600 for the stack giving us only 256 bytes of stack space
    sti                                             ; We're done setting up. Set interrupts again

    ; Relocate this boot sector to 0x600. That means the boot sector would now occupy 0x600 to 0x7FF
    mov si, 0x7C00                                  ; Source of bytes to copy i.e, this boot sector
    mov di, 0x600                                   ; Destination of bytes to copy
    mov cx, 0x200                                   ; Number of bytes to copy, here 512
    rep movsb                                       ; Copy
    jmp 0x00:RELOCATED

RELOCATED:
    ; Now we've successfully made the jump to the new location in memory. Now we may happily continue