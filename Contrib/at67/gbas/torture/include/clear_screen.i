xreset              EQU     register0
xcount              EQU     register1
ycount              EQU     register2
treset              EQU     register3
breset              EQU     register4
top                 EQU     register5
bot                 EQU     register6
vramAddr            EQU     register7
evenAddr            EQU     register8
    
    
%SUB                resetVideoTable
                    ; resets video table pointers
resetVideoTable     LDWI    0x0008
                    STW     vramAddr
                    LDWI    giga_videoTable
                    STW     evenAddr
    
resetVT_loop        LDW     vramAddr
                    DOKE    evenAddr
                    INC     evenAddr
                    INC     evenAddr
    
                    INC     vramAddr
                    LD      vramAddr
                    SUBI    giga_yres+8
                    BLT     resetVT_loop
                    RET
%ENDS   
    
%SUB                initClearFuncs
initClearFuncs      PUSH
                    LDWI    resetVideoTable
                    CALL    giga_vAC
    
                    LDWI    0x0002                              ; starting cursor position
                    STW     cursorXY
                    LDWI    0x7FFF
                    ANDW    miscFlags
                    STW     miscFlags                           ; reset on bottom row flag
            
                    LD      fgbgColour
                    ST      giga_sysArg0
                    ST      giga_sysArg0 + 1
                    ST      giga_sysArg2
                    ST      giga_sysArg2 + 1                    ; 4 pixels of fg colour
    
                    LDWI    SYS_Draw4_30                        ; setup 4 pixel SYS routine
                    STW     giga_sysFn
                    POP
                    RET
%ENDS   

%SUB                clearScreen
                    ; clears the viewable screen, (unrolled 4 times with a SYS call doing 4 pixels, so 16 pixels per loop)
clearScreen         PUSH
                    LDWI    initClearFuncs
                    CALL    giga_vAC
                    
                    LDWI    giga_vram                           ; top line
                    STW     giga_sysArg4
    
clearS_loop         LD      giga_sysArg4
                    SYS     0xFF                                ; SYS_Draw4_30, 270 - 30/2 = 0xFF
                    ADDI    0x04
                    ST      giga_sysArg4
                    SYS     0xFF
                    ADDI    0x04
                    ST      giga_sysArg4
                    SYS     0xFF
                    ADDI    0x04
                    ST      giga_sysArg4
                    SYS     0xFF
                    ADDI    0x04
                    ST      giga_sysArg4
                    SUBI    giga_xres
                    BLT     clearS_loop
    
                    LDI     0
                    ST      giga_sysArg4
                    INC     giga_sysArg4 + 1                    ; next top line
                    LD      giga_sysArg4 + 1
                    SUBI    giga_yres + 8
                    BLT     clearS_loop
                    POP
                    RET
%ENDS   
    
%SUB                clearVertBlinds
                    ; clears the viewable screen using a vertical blinds effect
clearVertBlinds     PUSH
                    LDWI    initClearFuncs
                    CALL    giga_vAC

                    LDWI    giga_vram                           ; top line
                    STW     giga_sysArg4
                    LD      giga_sysArg4 + 1
                    ST      top
    
clearVB_loop        LD      top
                    ST      giga_sysArg4 + 1                    ; top line
                    SYS     0xFF                                ; SYS_Draw4_30, 270 - 30/2 = 0xFF
    
                    LDWI    giga_yres - 1 + 16
                    SUBW    top
                    ST      giga_sysArg4 + 1                    ; bottom line
                    SYS     0xFF                                ; SYS_Draw4_30, 270 - 30/2 = 0xFF
    
                    LD      giga_sysArg4
                    ADDI    0x04
                    ST      giga_sysArg4
                    SUBI    giga_xres
                    BLT     clearVB_loop
    
                    LDI     0
                    ST      giga_sysArg4
                    INC     top                                 ; next top line
                    LD      top
                    SUBI    giga_yres / 2 + 8
                    BLT     clearVB_loop
                    POP
                    RET
%ENDS   
        
%SUB                clearRVertBlinds
                    ; clears a region using a vertical blinds effect
clearRVertBlinds    PUSH
                    LDWI    initClearFuncs
                    CALL    giga_vAC
    
clearRVB_loop       LDW     top
                    STW     giga_sysArg4                        ; top line
                    SYS     0xFF                                ; SYS_Draw4_30, 270 - 30/2 = 0xFF
    
                    LDW     bot
                    STW     giga_sysArg4                        ; bottom line
                    SYS     0xFF                                ; SYS_Draw4_30, 270 - 30/2 = 0xFF
    
                    LD      top                                 ; 4 horizontal pixels
                    ADDI    0x04
                    ST      top
                    LD      bot                                 ; 4 horizontal pixels
                    ADDI    0x04
                    ST      bot
                    LoopCounter xcount clearRVB_loop
    
                    INC     top + 1                             ; next top line
                    LD      bot + 1                             ; next bottom line
                    SUBI    0x01
                    ST      bot + 1
    
                    LD      treset                              ; reset low bytes of treset, breset and xcount
                    ST      top
                    LD      breset
                    ST      bot
                    LD      xreset
                    ST      xcount
                    LoopCounter ycount clearRVB_loop
                    POP
                    RET
%ENDS