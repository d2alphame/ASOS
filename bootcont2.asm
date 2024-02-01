MORE_SYSTEMS_ROUTINES_2:


; Searches for a file.
; IN: SI Pointer to the length prefixed string of the file's name
; OUT: If found, SI will point to the file's entry (i.e. its name, cluster
;      number and size)
; find_file:
;     
;     ; Start by filling up the filename buffer with 60 spaces
;     mov di, .FILE_NAME_BUFFER
;     push di                             ; Save di on the stack as it will be used later
;     mov cx, 60
;     mov al, ' '
;     rep stosb
; 
;     ; Copy the file's name from SI, into the buffer
;     lodsd                               ; Read in the length of the file name
;     mov ecx, eax                        ; Put it in ecx in preparation for the rep movsb instruction
;     pop di                              ; Destination for copying the name of the file
;     rep movsb                           ; Copy the filename to the buffer
; 
;     ; Now we have a space-padded filename string
; 
; 
;     .FILE_NAME_BUFFER:    times 60 db 0                  ; The maximum length of a file's name is 60 bytes



; Reads a single cluster from ASOS's filesystem
; IN ax Cluster number of the cluster to read (0 - 65535)
;    dx:bx Memory location of where clusters should be loaded
read_clusters:

    cmp ax, word [LAST_CLUSTER]
    ja .error

    ; Set up where in memory to load the sectors
    mov word [DATA_ACCESS_PACKET.offset], bx
    mov word [DATA_ACCESS_PACKET.segment], dx

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
    int 13h

.error:
    jmp $