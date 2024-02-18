MORE_SYSTEMS_ROUTINES_2:

; Searches for a file.
; IN:   SI  Pointer to the length prefixed string of the file's name
;       DI  Pointer to where file entry should be placed if the file is found.
;           This should be at least 64 bytes.
; OUT:  If found, DI will point to the file's entry (i.e. its name, cluster
;      number and size)
find_file:
    
    push di

    ; Start by filling up the filename buffer with 60 spaces
    mov di, .FILE_NAME_BUFFER
    mov ecx, 60
    mov al, ' '
    rep stosb

    ; Copy the file's name from SI, into the buffer
    lodsd                               ; Read in the length of the file name
    mov di, .FILE_NAME_BUFFER
    mov ecx, eax                        ; Put it in ecx in preparation for the rep movsb instruction
    rep movsb                           ; Copy the filename to the buffer


    ; Now we have a space-padded filename string

    ; Read in cluster number 16 to 1023 (in a loop) and search for the filename within the cluster
    xor dx, dx                          ; Clusters will be loaded at dx:bx
    mov bx, 0x2000                      ; In this case we'll load the clusters at 0x00:0x2000
    mov ax, 0x10                        ; Cluster number to read. We want clusters 16 to 1023
    
.outer_loop:
    call read_clusters
        jc .error
    
        mov si, bx
        mov cx, 64
        .inner_loop:
            push cx
            mov cx, 60
            mov di, .FILE_NAME_BUFFER
            repz cmpsb
            pop cx                      ; We pop cx before the jump (next instruction) in order to prevent stack overflow
            jz .found
            add si, 4                   ; Skip over last 4 bytes of the file entry we just checked
            loop .inner_loop
    inc ax
    cmp ax, 1023
    jna .outer_loop

    ; If we get here, it means the file was not found
    .not_found:
        stc
        pop di
        retf

    .found:
        clc
        pop di
        sub si, 60
        mov ecx, 64
        rep movsb
        sub di, 64
        retf

    .error:
        pop di
        retf

    .FILE_NAME_BUFFER:    times 60 db 0                  ; The maximum length of a file's name is 60 bytes



; Reads a single cluster from ASOS's filesystem
; IN ax Cluster number of the cluster to read (0 - 65535)
;    dx:bx Memory location of where clusters should be loaded
read_clusters:

    ; Can't load a cluster greater than the last cluster, duh.
    cmp ax, word [LAST_CLUSTER]
    ja .error_out_of_bounds

    ; Preserve the following 4 registers
    mov dword [.PRESERVE_EAX], eax
    mov dword [.PRESERVE_ECX], ecx
    mov dword [.PRESERVE_EDX], edx
    mov dword [.PRESERVE_ESI], esi

    ; Set up where in memory to load the sectors
    mov word [DATA_ACCESS_PACKET.offset], bx
    mov word [DATA_ACCESS_PACKET.segment], dx

    ; Number of sectors to read = 2 ^ SECTORS_PER_CLUSTER
    mov cl, byte [SECTORS_PER_CLUSTER]
    mov edx, 0x01
    shl edx, cl
    mov word [DATA_ACCESS_PACKET.sector_count], dx

    ; Calculate the lba of the clusters to read.
    mov edx, [LBA_FIRST_HIGH]
    shl eax, cl
    add eax, dword [LBA_FIRST_LOW]
    jnc .continue
    inc edx
.continue:

    mov dword[DATA_ACCESS_PACKET.lba_low], eax
    mov dword[DATA_ACCESS_PACKET.lba_high], edx

    mov dl, byte [BOOT_DEVICE]                      ; Get the boot device
    mov ah, 0x42                                    ; Function to read sectors from the disk
    mov si, DATA_ACCESS_PACKET                      ; Point to the data access packet
    int 13h                                         ; BIOS interrupt to read sectors
    
    jc .error_reading_clusters

    clc
    mov eax, dword [.PRESERVE_EAX]
    mov ecx, dword [.PRESERVE_ECX]
    mov edx, dword [.PRESERVE_EDX]
    mov esi, dword [.PRESERVE_ESI]
    ret

.error_out_of_bounds:
    stc
    mov ax, 0x01
    mov si, .CLUSTER_OUT_OF_BOUNDS
    ret

.error_reading_clusters:
    stc
    mov ax, 0x02
    mov si, .ERROR_READING_CLUSTERS
    mov edx, dword [.PRESERVE_EDX]
    mov ecx, dword [.PRESERVE_ECX]
    ret 

; Errors
.CLUSTER_OUT_OF_BOUNDS: db "Cluster number to read is out of bounds"
.ERROR_READING_CLUSTERS: db "Error reading clusters from the storage device"

; The following is a buffer for preserving registers eax, edx, ecx, esi
.PRESERVE_EAX: dd 0x00
.PRESERVE_ECX: dd 0x00
.PRESERVE_EDX: dd 0x00
.PRESERVE_ESI: dd 0x00


find_sample:

    xor esi, esi
    xor edi, edi
 
    mov si, .FLEN
    mov di, .FILE_ENT
    call 0x00:find_file

    jc .not_found
    jmp $

.not_found:
    call 0x00:print_eax_hex
    jmp $

    .FLEN: dd 6
    .FILENAME: db "Bloody"
    .FILE_ENT: times 60 db 0
    .FILE_PPT: dd 0
    