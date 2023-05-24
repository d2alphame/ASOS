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
    mov di, DUMP_LINE_BUFFER

    mov cx, 0x10                    ; Number of lines to be printed. Will be used in a loop

    .outer_loop:
        push cx

        ; Main loop that prints a line
        mov cx, 0x10
        call .buffer_the_address             ; Adds to the buffer the printable representation of the said address

        .line_loop:
            mov dx, si
            mov al, ' '
            stosb
            mov ax, dx
            shr ax, 4
            and ax, 0x0F
            xlatb
            stosb
            mov ax, dx
            and ax, 0x0F
            xlatb
            stosb
            inc si
            loop .line_loop
            call .print_the_buffer      ; Print buffer

        ; Check if all 16 lines have been printed
        pop cx
        loop .outer_loop

        ; cmp cx, 0               ; This means we've printed 16 lines
        ; jmp .line_loop_done     ; We're done
        ; dec cx
        ; push cx                 ; Save cx register and continue
        ; inc si
        ; mov di, DUMP_LINE_BUFFER
        ; jmp .line_loop
    .line_loop_done:
        retf

    .print_the_buffer:
        push si
        push cx
        push bx
        mov cx, 0x0E
        mov si, DUMP_LINE_BUFFER
        mov bx, 0x0007
        mov ah, 0x0E
        .print_loop:
            lodsb
            int 10h
            cmp cx, 0
            je .print_loop_done
            dec cx
            jmp .print_loop
        .print_loop_done:
            pop bx
            pop cx
            pop si
            ret

    .buffer_the_address:
        mov bx, HEX_DIGITS
        mov dx, si
        mov cl, 0x04
        .buffer_loop:
            rol dx, 4
            mov ax, dx
            and ax, 0x000F
            xlatb
            stosb
            loop .buffer_loop

        ; mov si, DUMP_LINE_BUFFER
        ; call 0x00:print_null_terminated_string
        ; jmp $
            
        ret


DUMP_LINE_BUFFER:
    .address: dd 0x00
    .values: times 6 dq 0x00
    .newline: db 0x0A, 0x0D

DUMP_MEMORY_ADDRESS dw 0x00             ; Memory address
times 512 - ($ - say_eax_hex) db 0x00

TEST:
mov si, 0x7C00
call 0x00:dump_memory_hex
jmp $