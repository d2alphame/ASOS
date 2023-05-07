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

    mov ah, 0x0E                                    ; Print in teletype mode
    mov al, 'A'                                     ; The character to print
    mov bx, 0x0007                                  ; Print in page 0 (bh), grey text on black background (bl)
    int 10h                                         ; Interrupt for printing to screen
    jmp $                                           ; Hang here

    .installer_boot_device: db 0                    ; We'll save the boot device here as soon as we find it

times 510 - ($ - $$) db 0                       ; Padd with 0s up to 510 bytes
dw 0xAA55                                       ; The boot signature
times 1474560 - ($ - $$) db 0                   ; Pad with more 0s to make up 1.44MB floppy disk
