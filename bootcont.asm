MORE_SYSTEMS_ROUTINES:


; Prints out the content of the eax register in hexadecimal
; IN:
;   EAX: The value to print 
print_eax_hex:
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
        loop .loop

    ; Print the hexadecimal representation
    mov bx, 0x0007
    mov ah, 0x0E
    mov si, EAX_HEX
    mov cx, 0x0A
    .fetch:
        lodsb
        int 10h
        loop .fetch
    retf


; Prints out the content of the eax register in heaxadecimal
; and appends a newline
say_eax_hex:
    xor ecx, ecx
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
        loop .loop
    ; Print the hexadecimal representation
    mov bx, 0x0007
    mov ah, 0x0E
    mov si, EAX_HEX
    mov cx, 0x0A
    .fetch:
        lodsb
        int 10h
        loop .fetch
    .done:
        mov al, 0x0D
        int 10h
        mov al, 0x0A
        int 10h
        retf


; Dump content of memory in hexadecimal. Dumps 256 bytes of memory
; IN
;   SI: Memory address to dump.
; NOTE: The address is expected to be 256-byte aligned
dump_memory_hex:

    ; Check to ensure the address is 256 byte aligned
    mov dx, si
    and dx, 0x00FF
    cmp dx, 0x00
    je .continue
    stc                             ; Set the carry flag to mean an error occured
    retf

    ; Start on a new line
    .continue:
        mov bx, 0x0007
        mov ah, 0x0E
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h

    ; Print the headers
    ; First print out intial 8 spaces in the header
    mov cl, 0x04
    mov ah, 0x0E
    mov al, ' '
    .print_initial_spaces:
    int 10h
    loop .print_initial_spaces

    mov cl, 0x10
    push si                         ; Remember to preserve the address of the bytes we want to print
    mov si, HEX_DIGITS

    ; Print 2 spaces followed by hex digit. Still part of the headers
    .header_loop:
        mov al, ' '
        int 10h
        int 10h
        lodsb
        int 10h
        loop .header_loop
    .newline:
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h
    ; We're done printing the header

    pop si                          ; Retrieve the address of the bytes to print
    mov bx, HEX_DIGITS
    mov di, DUMP_LINE_BUFFER_HEX

    mov cx, 0x10                    ; Number of lines to be printed. Will be used in a loop

    .outer_loop:
        push cx

        ; Main loop that prints a line
        call .buffer_the_address             ; Adds to the buffer the printable representation of the said address
        mov cx, 0x10

        .line_loop:
            mov al, ' '
            stosb
            lodsb
            mov dx, ax
            shr ax, 4
            and ax, 0x0F
            xlatb
            stosb
            mov ax, dx
            and ax, 0x0F
            xlatb
            stosb
            loop .line_loop

            call .print_the_buffer      ; Print buffer

        ; Check if all 16 lines have been printed
        pop cx
        loop .outer_loop                ; Loop to print next line if we're not done
        retf

    .print_the_buffer:
        push si
        push cx
        push bx
        mov cx, 0x36
        mov si, DUMP_LINE_BUFFER_HEX
        mov bx, 0x0007
        mov ah, 0x0E
        .print_loop:
            lodsb
            int 10h
            loop .print_loop
        pop bx
        pop cx
        pop si
        ret

    .buffer_the_address:
        mov bx, HEX_DIGITS
        mov di, DUMP_LINE_BUFFER_HEX
        mov dx, si
        mov cl, 0x04
        .buffer_loop:
            rol dx, 4
            mov ax, dx
            and ax, 0x000F
            xlatb
            stosb
            loop .buffer_loop
        ret



; Dumps 256 bytes of memory. But prints the printable ascii bytes
; instead of their hexadecimal value
; IN
;   SI - Pointer to memory location of bytes to print
; NOTE: The memory location is expected be 256 bytes aligned
dump_memory_ascii:
    
    ; Check to ensure the address is 256 byte aligned
    mov dx, si
    and dx, 0x00FF
    cmp dx, 0x00
    je .continue
    stc                             ; Set the carry flag to mean an error occured
    retf

    ; Start on a new line
    .continue:
        mov bx, 0x0007
        mov ah, 0x0E
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h

    ; Print the headers
    ; First print out intial 8 spaces in the header
    mov cl, 0x04
    mov ah, 0x0E
    mov al, ' '
    .print_initial_spaces:
    int 10h
    loop .print_initial_spaces

    mov cl, 0x10
    push si                         ; Remember to preserve the address of the bytes we want to print
    mov si, HEX_DIGITS

    ; Print 2 spaces followed by hex digit. Still part of the headers
    .header_loop:
        mov al, ' '
        int 10h
        int 10h
        lodsb
        int 10h
        loop .header_loop
    .newline:
        mov al, 0x0A
        int 10h
        mov al, 0x0D
        int 10h
    ; We're done printing the header

    pop si                          ; Retrieve the address of the bytes to print
    mov bx, HEX_DIGITS
    mov di, DUMP_LINE_BUFFER_ASCII

    mov cx, 0x10                    ; Number of lines to be printed. Will be used in a loop

    .outer_loop:
        push cx

        ; Main loop that prints a line
        call .buffer_the_address             ; Adds to the buffer the printable representation of the said address
        mov cx, 0x10

        .line_loop:
            mov al, ' '
            stosb
            lodsb
            mov dx, ax
            shr ax, 4
            and ax, 0x0F
            xlatb
            stosb
            mov ax, dx
            and ax, 0x0F
            xlatb
            stosb
            loop .line_loop

            call .print_the_buffer      ; Print buffer

        ; Check if all 16 lines have been printed
        pop cx
        loop .outer_loop                ; Loop to print next line if we're not done
        retf

    .print_the_buffer:
        push si
        push cx
        push bx
        mov cx, 0x36
        mov si, DUMP_LINE_BUFFER_ASCII
        mov bx, 0x0007
        mov ah, 0x0E
        .print_loop:
            lodsb
            int 10h
            loop .print_loop
        pop bx
        pop cx
        pop si
        ret

    .buffer_the_address:
        mov bx, HEX_DIGITS
        mov di, DUMP_LINE_BUFFER_ASCII
        mov dx, si
        mov cl, 0x04
        .buffer_loop:
            rol dx, 4
            mov ax, dx
            and ax, 0x000F
            xlatb
            stosb
            loop .buffer_loop
        ret


READ_ASOS_BOOT_EXTRAS:
    ; mov al, 65
    ; call 0x00:wait_for_key_ascii
    ; mov ah, 0x0E
    ; mov bx, 0x0007
    ; int 10h
    ; jmp $

DUMP_LINE_BUFFER_HEX:
    .address: dd 0x00
    .values: times 6 dq 0x00
    .newline: db 0x0A, 0x0D

DUMP_LINE_BUFFER_ASCII:
    .address: dd 0x00
    
EAX_HEX:
    .prefix: db "0x"
    .hexstring: dq 0x00
HEX_DIGITS: db "0123456789ABCDEF", 0x00


; times 512 - ($ - MORE_SYSTEMS_ROUTINES) db 0x00

; TEST:
; mov si, 0x7C00
; call 0x00:dump_memory_hex
; jmp $