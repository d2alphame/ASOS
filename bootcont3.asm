; Loops until a given key with the ascii code is pressed.
;   In AL: ASCII of key to wait for
;   Out AL: ASCII of the key
wait_for_key_ascii:
    mov dl, al
    .loop:
        mov ah, 0x00                    ; BIOS function to get key
        int 16h                         ; Keyboard interrupt
        cmp al, dl                      ; Check if it's the key we're waiting for
        jnz .loop                       ; Continue waiting if it's not

    retf


; Loops until a given key with the scancode is pressed.
;   In AL: Scancode of key to wait for
;   Out AH: Scancode of the key
;       AL: ASCII of the key, if the key has no ascii, this would be 0
wait_for_key_scancode:
    mov dl, ah
    .loop:
        mov ah, 0x00                    ; BIOS function to get key
        int 16h                         ; Keyboard interrupt
        cmp ah, dl                      ; Check if it's the key we're waiting for
        jnz .loop                       ; Continue waiting if it's not

    retf


; Prints a string whose length is specified in ecx.
; In SI: Points to the string to print
;    ECX: The length of the string
print_string_len_ecx:
    mov ah, 0x0E
    mov bx, 0x0007
    jecxz .done
    .loop:
        lodsb
        int 10h
        loop .loop
    .done:
        retf


; Prints a string whose length is specified in ecx and appends a newline
; In SI: Points tot he string to print
;   ECX: The length of the string to print
say_string_len_ecx:
    mov ah, 0x0E
    mov bx, 0x0007
    jecxz .done
    .loop:
        lodsb
        int 10h
        loop .loop
    mov al, 0x0D
    int 10h
    mov al, 0x0A
    int 10h    
    .done:
        retf

