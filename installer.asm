; This is the installation floppy for the ASOS operating system.
[Bits 16]
[Org 0x7c00]

jmp 0x00:MAIN                                       ; A trick to set cs = 0                             

MAIN:
    cli                                             ; Clear interrupts. No interruptions before we're done setting up

    ; Setup a flat segment with cs = ds = es = ss = 0
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x600                                   ; Use 0x500 to 0x600 for the stack giving us 256 bytes of stack space

    sti                                             ; We're done setting up. Set interrupts again

    ; Notify of successful boot
    mov si, BOOT_SUCCESS
    call print_null_terminated_string

    mov byte [INSTALLER_BOOT_DEVICE], dl            ; Save the boot device. This will be handed to us by BIOS

    ; Reset the floppy disk. Remember the boot device is still in dl
    mov ah, 0x00                                    ; Function to reset disk
    int 13h                                         ; Disk routines
    jc disk_reset_error                             ; Carry would be set if there was an error

    ; Load in second sector from the boot device into 0x600. That's just above the stack we set up.
    ; Boot device here being the installation floppy
    mov dl, byte [INSTALLER_BOOT_DEVICE]            ; Reload the boot device number into dl
    mov ax, 0x0201                                  ; AH = 2, function to read sectors. AL = 1 number of sectors to read
    mov bx, CONST_SECOND_SECTOR_MEMORY_LOCATION     ; es:bx = where to load the sectors in memory
    mov cx, 0x0002                                  ; CH = Cylinder/track, CL = Sector number (Sector numbering starts with 1) 
    int 13h                                         ; Read the sector
    jc disk_read_error                              ; Carry would be set if there was an error

    ; Read the first sector of the first drive into memory. For this we use the new disk routines
    mov dl, 0x80                                    ; We want to read from the first hard disk
    mov si, DISK_ACCESS_PACKET                      ; Point si at the data packet
    mov ah, 0x42                                    ; Read function (in extended disk routines)




    ; Prints a null-terminated string in teletype mode.
    ; In
    ; SI = String to print
    print_null_terminated_string:
        mov ah, 0x0E
        mov bx, 0x0007
        .loop:
            lodsb
            cmp al, 0x00
            je .done
            int 10h
            jmp .loop
        .done:
            ret
    
    disk_reset_error:
        mov si, ERROR_RESETTING_BOOT_DEVICE
        call print_null_terminated_string
        jmp $

    disk_read_error:
        mov si, ERROR_READING_INSTALLATION_FLOPPY
        call print_null_terminated_string
        jmp $

    harddisk_read_error:
        mov si, ERROR_READING_HARDDISK
        call print_null_terminated_string
        jmp $
    
    align 4                                         ; The disk access packet which follows should be aligned on a 4-byte boundary
    DISK_ACCESS_PACKET:
        .size_of_packet:    db 0x10                                     ; Size of the packet is 16 bytes
        .unused:            db 0x00                                     ; This field is unused
        .sector_count:      dw 0x01                                     ; Number of sectors to transfer
        .offset:            dw CONST_HARDDISK_FIRST_SECTOR_MEMORY_OFF   ; Offset of memory address for transfer
        .segment:           dw CONST_HARDDISK_FIRST_SECTOR_MEMORY_SEG   ; Segment of memory address for transfer
        .start_lba_lower:   dd 0x01                                     ; Lower 32 bits of LBA of sectors to load
        .start_lba_upper:   dd 0x00                                     ; Upper 16 bits of LBA of sectors to load

    INSTALLER_BOOT_DEVICE:  db 0                    ; We'll save the boot device here as soon as we find it

    BOOT_SUCCESS: db "Boot Successful", 0x0A, 0x0D, 0x00
    ERROR_RESETTING_BOOT_DEVICE: db "Could not reset installation floppy drive", 0x0A, 0x0D, 0x00
    ERROR_READING_INSTALLATION_FLOPPY: db "Error reading installation floppy", 0x0A, 0x0D, 0x00
    ERROR_READING_HARDDISK: db "Error reading from the hard disk", 0x0A, 0x0D, 0x00


times 510 - ($ - $$) db 0                           ; Padd with 0s up to 510 bytes
dw 0xAA55                                           ; The boot signature
times 1474560 - ($ - $$) db 0                       ; Pad with more 0s to make up 1.44MB floppy disk


CONST_SECOND_SECTOR_MEMORY_LOCATION equ 0x600       ; Where in memory second sector of the installation floppy will be loaded
CONST_HARDDISK_FIRST_SECTOR_MEMORY_OFF equ 0x800    ; Where in memory first sector of hard disk will be loaded (offset)
CONST_HARDDISK_FIRST_SECTOR_MEMORY_SEG equ 0x00     ; Where in memory first sector of hard disk will be loaded (segment)