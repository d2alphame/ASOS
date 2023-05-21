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


; Dump content of memory in hexadecimal. Dumps 256 bytes of memory
; IN
;   SI: Memory address to dump.
; NOTE: The address is expected to be 256-byte aligned
dump_memory_hex:
    ; Check to ensure the address is 256 byte aligned
    mov dx, si
    and dx, 0x00FF
    jne .continue
    stc                             ; Set the carry flag to mean an error occured
    retf

    ; Start on a new line
    .continue:
        mov bx, 0x0007
        mov ah, 0x0E
        mov al, 0x0A
        int 10h
        mov ah, 0x0E
        mov al, 0x0A
        int 10h

    ; Print the headers
    ; First print out 8 spaces
    mov cl, 0x08
    mov ah, 0x0E
    mov al, ' '
    rep int 10h

    mov cl, 0x10
    push si                     ; Remember to preserve the address of the bytes we want to print
    mov si, HEX_DIGITS

    ; Print 2 spaces followed by hex digit
    .header_loop:
        mov al, ' '
        int 10h
        int 10h
        lodsb
        int 10h
        cmp cl, 0x00
        je .newline
        jmp .header_loop
    .newline:
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h
    
    pop si                      ; Retrieve the address of the byte to print

    ; Main loop that prints each line
    .line_loop:

