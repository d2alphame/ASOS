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

    ; From the installation floppy, read in the sectors of the os to be installed on the hard disk. Note that DL still
    ; contains the drive number of the device that was booted from
    mov ax, 0x0208                                  ; AH = 2, function to read sectors. AL = 8 number of sectors to read
    mov bx, 0x600                                   ; es:bx = where to load the sectors in memory. We've already set es to 0
    mov cx, 0x0002                                  ; CH = Cylinder/track, CL = Sector number (Sector numbering starts with 1) 
    int 13h                                         ; Read the sectors
    jc floppy_read_error                            ; Carry would be set if there was an error

    ; Copy the os' sectors from memory onto the hard disk
    mov si, DISK_ACCESS_PACKET                      ; Point si to the disk access packet for the copy
    mov ah, 0x43                                    ; Write sectors to hard drive (new extension function)
    mov dl, 0x80                                    ; Write to the first hard disk
    int 13h                                         ; Do the copy
    jc disk_write_error                             ; Display error if an error occured

    ; If there was no error, display the installation success message and loop
    mov si, INSTALLATION_SUCCESS
    call print_null_terminated_string
    jmp $


    ; Prints a null-terminated string in teletype mode.
    ; In
    ; SI = String to print
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
            ret

    floppy_read_error:
        mov si, ERROR_READING_INSTALLATION_FLOPPY
        call print_null_terminated_string
        jmp $

    disk_write_error:
        mov si, ERROR_WRITING_HARDDISK
        call print_null_terminated_string
        jmp $
    
    
    align 4                                         ; The disk access packet which follows should be aligned on a 4-byte boundary
    
    ; Disk access packet. This one will be used for copying the loaded sectors from memory to harddisk
    DISK_ACCESS_PACKET:
        .size_of_packet:    db 0x10                 ; Size of the packet is 16 bytes
        .unused:            db 0x00                 ; This field is unused
        .sector_count:      dw 0x08                 ; Number of sectors to transfer
        .offset:            dw 0x600                ; Offset of memory address for transfer
        .segment:           dw 0x00                 ; Segment of memory address for transfer
        .lba                dq 0x00                 ; LBA of sectors to copy to

    INSTALLER_BOOT_DEVICE:  db 0                    ; We'll save the boot device here as soon as we find it

    BOOT_SUCCESS: db "Boot Successful", 0x0A, 0x0D, 0x00
    ERROR_READING_INSTALLATION_FLOPPY: db "Error reading installation floppy", 0x0A, 0x0D, 0x00
    ERROR_WRITING_HARDDISK: db "Error writing data to the hard disk", 0x0A, 0x0D, 0x00
    INSTALLATION_SUCCESS:   db "The OS has been successfully installed.", 0x0A, 0x0D
                            db "Remove the installation floppy and restart the system", 0x0A, 0x0D, 0x00

times 510 - ($ - $$) db 0                           ; Padd with 0s up to 510 bytes
dw 0xAA55                                            ; The boot signature
times 1474560 - ($ - $$) db 0                       ; Pad with more 0s to make up 1.44MB floppy disk