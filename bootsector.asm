; The boot sector of ASOS
[Bits 16]
[Org 0x7C00]

jmp 0x00:MAIN                   ; Jump over asos filesystem data below and also set cs = 0
align 8                         ; ASOS filesystem requires this



        