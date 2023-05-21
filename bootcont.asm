; Continuation for the boot sequence. More system call routines are here

; Prints out the content of the eax register in heaxadecimal
; and appends a newline
say_eax_hex:
    mov edx, eax                                ; Preserve the eax value in edx
    mov di, EAX_HEX.hexstring
    mov cx, 0x08                                ; Number of nibbles in a double word
    mov bx, HEX_DIGITS
    .loop:
        rol edx, 0x04
        mov eax, edx
        and eax, 0x0F
        xlatb
        stosb
        cmp cx, 0x00
        je .continue
        dec cx
        jmp .loop
    .continue:
        ; Print the hexadecimal representation
        mov bx, 0x0007
        mov ah, 0x0E
        mov si, EAX_HEX
        mov cx, 0x0A
        .fetch:
            cmp cx, 0x00
            je .done
            lodsb
            int 10h
            dec cx
            jmp .fetch
    .done:
        mov al, 0x0D
        int 10h
        mov al, 0x0A
        retf