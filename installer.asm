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
    mov sp, 0xFFFE                                  ; Point the stack to the top of the segment

    sti                                             ; We're done setting up. Set interrupts again

    mov byte [.installer_boot_device], dl           ; Save the boot device. This will be handed to us by BIOS

    ; Reset the floppy disk
    mov ah, 0x00                                    ; Function to reset disk
    int 13h                                         ; Disk routines

    ; Load in sector number 1 from the boot device into 0x7E00 (that's at the end of this boot sector)
    mov dl, byte [.installer_boot_device]           ; Reload the boot device number into dl
    mov ax, 0x0201                                  ; AH = 2, function to read sectors. AL = 1 number of sectors to read
    mov bx, 0x7E00                                  ; es:bx = where to load the sectors in memory
    int 13h                                         ; Read the sector

    ; Read the first sector of the first drive into memory. For this we use the new disk routines
    mov dl, 0x80                                    ; We want to read from the first hard disk
    mov si, DATA.size_of_packet                     ; Point si at the data packet
    mov ah, 0x42                                    ; Read function (in extended disk routines)

    mov ah, 0x0E                                    ; Print in teletype mode
    mov al, 'A'                                     ; The character to print
    mov bx, 0x0007                                  ; Print in page 0 (bh), grey text on black background (bl)
    int 10h                                         ; Interrupt for printing to screen
    jmp $                                           ; Hang here

    
    .installer_boot_device: db 0                    ; We'll save the boot device here as soon as we find it
    
    align 4                                         ; The disk access packet which follows should be aligned on a 4-byte boundary
    DATA:
        .size_of_packet:    db 0x10                 ; Size of the packet is 16 bytes
        .unused:            db 0x00                 ; This field is unused
        .sector_count:      dw 0x01                 ; Number of sectors to transfer
        .offset:            dw 0x8000               ; Offset of memory address for transfer
        .segment:           dw 0x00                 ; Segment of memory address for transfer
        .start_lba_lower:   dd 0x01                 ; Lower 32 bits of LBA of sectors to load
        .start_lba_upper:   dd 0x00                 ; Upper 16 bits of LBA of sectors to load


times 510 - ($ - $$) db 0                       ; Padd with 0s up to 510 bytes
dw 0xAA55                                       ; The boot signature
times 1474560 - ($ - $$) db 0                   ; Pad with more 0s to make up 1.44MB floppy disk
