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
LAST_CLUSTER:           dw 0xFFFF                   ; Cluster number of the last cluster (starts from 0). Max is 0xFFFF (65535)
LBA_FIRST_LOW:          dd 0x00                     ; Lower 32 bits of LBA of first sector of this filesystem
LBA_FIRST_HIGH:         dd 0x00                     ; Upper 32 bits of LBA of first sector of this filesystem
LBA_LAST_LOW:           dd 0x7FFFF                  ; Lower 32 bits of LBA of last sector of the filesystem
LBA_LAST_HIGH:          dd 0x00                     ; Upper 32 bits of LBA of last sector of the filesystem
FREE_FOR_CUSTOM_USE:    dq 0x00                     ; Free for custom use
RESERVED:               dq 0x00                     ; Reserved for future use
FLAGS:                  dd 0x00                     ; Flags. Not in use for now
XOR_CHECKSUM:           dd 0x00                     ; XOR checksum of the above struc (starting from the jump instruction down to the flags)

; NOTE: The above data takes up 80 bytes

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
    ; Now we've successfully made the jump to the new location in memory, we may happily continue.
    ; Most important thing right now is to save the boot device
    
    mov byte [BOOT_DEVICE], dl                      ; Save the boot device
    push dx                                         ; Also preserve it on the stack

    ; We want to load the remaining sectors in the cluster to which the boot sector belongs.
    ; Figure out where the remaining sectors for the first cluster are

    xor eax, eax
    xor edx, edx

    ; Get LBA of first sector (low 32 bits in eax, high 32 bits in edx) and add 1.
    ; Remember the first sector is the boot sector which has already been loaded, so
    ; we just need the second sector and the rest
    mov eax, dword [LBA_FIRST_LOW]
    mov edx, dword [LBA_FIRST_HIGH]
    add eax, 1
    jnc .continue
    inc edx

.continue:
    ; After figuring out where the remaining sectors for booting are on disk, we can now load them
    mov dword [DATA_ACCESS_PACKET.lba_low], eax
    mov dword [DATA_ACCESS_PACKET.lba_high], edx
    mov cl, byte [SECTORS_PER_CLUSTER]              ; Number of sectors to load will be number of sectors in a cluster less 1. Remember boot sector has alredy been loaded
    mov ax, 0x01
    shl ax, cl                                      ; 2 ^ SECTORS_PER_CLUSTER = Number of sectors per cluster
    dec ax                                          ; Because the boot sector has already been loaded
    mov word [DATA_ACCESS_PACKET.sector_count], ax
    mov word [DATA_ACCESS_PACKET.offset], 0x800     ; Memory offset to load the sectors into
    
    ; Read in the sectors using 13h Extended routines.
    pop dx                                          ; Get back the boot device that was saved earlier
    mov ah, 0x42                                    ; Function to read sectors from the disk
    mov si, DATA_ACCESS_PACKET                      ; Point to the data access packet
    int 13h
    jc error_reading_rest_of_boot_image

    mov si, SUCCESSFUL_BOOT                         ; Success reading the rest of the cluster. Print the success message
    call 0x00:print_null_terminated_string
    
    ; jmp READ_ASOS_BOOT_EXTRAS                       ; Continue with reading the asos boot extras file
    jmp find_sample
    ; jmp $

error_reading_rest_of_boot_image:
    mov si, ERROR_READING_REST_OF_BOOT_IMAGE
    call 0x00:print_null_terminated_string
    jmp $


; Prints a null terminated string. 
; In:
;   SI - pointer to string to print 
print_null_terminated_string:
    mov ah, 0x0E                                ; Function to print in teletype mode
    mov bx, 0x0007                              ; BH = background color (0x00 is black) BL = foreground color (0x07 is grey)
    .loop:
        lodsb                                   ; Read the character to print into AL
        cmp al, 0x00                            ; If it's the null byte, then we're at the end of the string
        je .done
        int 10h                                 ; Print it!
        jmp .loop                               ; Read next character
    .done:
        retf


; Prints a null terminated string but also adds a new line to the end
; In:
;   SI - pointer to string to print
say_null_terminated_string:
    mov ah, 0x0E                                ; Function to print in teletype mode
    mov bx, 0x0007                              ; BH = background color (0x00 is black) BL = foreground color (0x07 is grey)
    .loop:
        lodsb                                   ; Read the character to print into AL
        cmp al, 0x00                            ; If it's the null byte, then we're at the end of the string
        je .add_newline
        int 10h                                 ; Print it!
        jmp .loop                               ; Read next character
    .add_newline:                               ; Prints newline
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h
        retf


; Prints a string prefixed by its 4-byte length
; In:
;   SI: Pointer to string
; Remarks: Note that SI actually points to the length of
;          the string which is 4 bytes. So 'lodsd' needs
;          to be done first the fetch the length.
print_length_prefixed_string:
    lodsd                                       ; Reads in the length of the string into eax
    mov ecx, eax                                ; Move it into ecx, getting out of the way
    mov ah, 0x0E                                ; Function to print in teletype mode
    mov bx, 0x0007                              ; Grey text on black background
    cmp ecx, 0x00                               ; This means we've printed the entire string
    je .done
    .loop:
        lodsb
        int 10h
        loop .loop
    .done:
        retf


; Prints a string prefixed by its 4-byte length and appends a newline
; In:
;   SI: Pointer to string
; Remarks: Note that SI actually points to the length of
;          the string which is 4 bytes. So 'lodsd' needs
;          to be done first the fetch the length.
say_length_prefixed_string:
    lodsd                                       ; Reads in the length of the string into eax
    mov ecx, eax                                ; Move it into ecx, getting out of the way
    mov ah, 0x0E                                ; Function to print in teletype mode
    mov bx, 0x0007                              ; Grey text on black background
    cmp ecx, 0x00                           ; This means we've printed the entire string
    je .done
    .loop:
        lodsb
        int 10h
        loop .loop
    .done:
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h
        retf


; Print byte-terminated string
; IN:
;    SI = Pointer to the string to print
;    AL = The byte that terminates the string
print_byte_terminated_string:
    mov dl, al
    mov ah, 0x0E                                ; Function to print in teletype mode
    mov bx, 0x0007                              ; BH = background color (0x00 is black) BL = foreground color (0x07 is grey)
    .loop:
        lodsb                                   ; Read the character to print into AL
        cmp al, dl                              ; If it's the null byte, then we're at the end of the string
        je .done
        int 10h                                 ; Print it!
        jmp .loop                               ; Read next character
    .done:
        retf


; Print byte-terminated string and appends a newline to it
; IN:
;    SI = Pointer to the string to print
;    AL = The byte that terminates the string
say_byte_terminated_string:
    mov dl, al
    mov ah, 0x0E                                ; Function to print in teletype mode
    mov bx, 0x0007                              ; BH = background color (0x00 is black) BL = foreground color (0x07 is grey)
    .loop:
        lodsb                                   ; Read the character to print into AL
        cmp al, dl                              ; If it's the null byte, then we're at the end of the string
        je .done
        int 10h                                 ; Print it!
        jmp .loop                               ; Read next character
    .done:
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h
        retf

; Prints the newline character
print_newline:
    mov bx, 0x0007
    mov ah, 0x0E
    mov al, 0x0A
    int 10h
    mov al, 0x0D
    int 10h
    retf


; Will be used to read in sectors from the disk. Has to be aligned on a 4 byte boundary
align 4
DATA_ACCESS_PACKET:
    .packet_size:       db 0x10                     ; Size of this packet in bytes. This is 16 bytes
    .unused:            db 0x00                     ; Field unused
    .sector_count       dw 0x00                     ; Number of sectors to transfer. This will be calculated
    .offset             dw 0x00                     ; Offset part of memory location for transfer
    .segment            dw 0x00                     ; Segment part of memory location for transfer
    .lba_low            dd 0x00                     ; Low 32 bits of LBA of starting sector for transfer. Will be calculated
    .lba_high           dd 0x00                     ; High 32 bits of LBA of starting sector for transfer. Will be calculated

BOOT_DEVICE: db 0x80
SUCCESSFUL_BOOT: db "Successful boot", 0x0A, 0x0D, 0x00
ERROR_READING_REST_OF_BOOT_IMAGE: db "There was an error reading the rest of the boot image", 0x0A, 0x0D, 0x00


; Pad up to 446 bytes. At byte 446 we should have the Master Boot Record
times 446 - ($ - $$) db 0
MBR: times 64 db 0                                   ; The Master Boot Record. Fill with zeros for now

dw 0xAA55                                            ; The boot signature

; ****************************************************************************
; This is the end of the first sector and the beginning of the next          *
; The jump table follows. This places the jump table at the 2kb (0x800) mark *
; ****************************************************************************

; %include "jumptable.asm"
%include "bootcont.asm"
%include "bootcont2.asm"

 times 65536 - ($ - $$) db 0
 fname: db "Sample"
   times 60 - ($ - fname) db ' '
   dw 0x05
   dw 1024
 times 4194304 - ($ - $$) db 0
   db "Hello"
 times 536870912 - ($ - $$) db 0