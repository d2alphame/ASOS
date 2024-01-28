JUMP_TABLE:
jmp 0x00:print_null_terminated_string
align 8
jmp 0x00:say_null_terminated_string
align 8
jmp 0x00:print_byte_terminated_string
align 8
jmp 0x00:say_byte_terminated_string
align 8
jmp 0x00:print_length_prefixed_string
align 8
jmp 0x00:say_length_prefixed_string
align 8
jmp 0x00:print_eax_hex
align 8
jmp 0x00:say_eax_hex
align 8
jmp 0x00:print_newline
align 8
jmp 0x00:dump_memory_hex
align 8
jmp 0x00:wait_for_key_ascii
align 8
jmp 0x00:wait_for_key_scancode
align 8

times 512 - ($ - JUMP_TABLE) db 0           ; Pad up to make 512 bytes