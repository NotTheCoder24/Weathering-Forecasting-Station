#MAKE_BIN#
#LOAD_SEGMENT=0100h#
#LOAD_OFFSET=0000h#

#CS=0100h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#          



;-------------------------IVT-init-----------------------;
mov ax, offset isr0
mov [00200h], ax
mov ax, seg isr0
mov [00202h], ax

mov ax, offset isr1
mov [00204h], ax
mov ax, seg isr1
mov [00206h], ax

mov ax, offset isr2
mov [00208h], ax
mov ax, seg isr2
mov [0020Ah], ax

mov ax, offset isr3
mov [0020Ch], ax
mov ax, seg isr3
mov [0020Eh], ax

;-------------------------IVT-init-----------------------;
jmp START
db 512 dup(0)


;-------------------------Data-segment-----------------------;
C_STATE_A db 00h
C_STATE_B db 00h
LCD_LINE_1 db 'Temp(C): ' 
LCD_LINE_2 db 16 dup('-')
LCD_LINE_3 db 16 dup('.')
LCD_LINE_4 db 16 dup('*')
LCD_COUNT_1 db 9d
LCD_COUNT_2 db 16d
LCD_COUNT_3 db 16d
LCD_COUNT_4 db 16d



FLAG_COUNT   dw 0
VALUES        db 30 dup(0)
COUNTER         dw 0
READY_FOR_HOUR db 1 dup(0)

THP db 1 dup(0)


LCD_LINE_11 db 'Humi1(%): ' 
LCD_LINE_22 db 16 dup('-')
LCD_LINE_33 db 16 dup('.')
LCD_LINE_44 db 16 dup('*')
LCD_COUNT_11 db 9d
LCD_COUNT_22 db 16d
LCD_COUNT_33 db 16d
LCD_COUNT_44 db 16d



;Humi~
FLAGCOUNT_11 dw 0
VALS_11      db 30 dup(0)
CTR_11       dw 0



LCD_LINE_111 db 'Pres(Ba):' 
LCD_LINE_222 db 16 dup('-')
LCD_LINE_333 db 16 dup('.')
LCD_LINE_444 db 16 dup('*')
LCD_COUNT_111 db 9d
LCD_COUNT_222 db 16d
LCD_COUNT_333 db 16d
LCD_COUNT_444 db 16d


;Pres
FCOUNT    dw 0
VALS111     db 30 dup(0)
CTR111      dw 0


numstr db 16 dup(0)

q db 0
r db 0



DIV_BY dw 30d
LIVE_UPDATE db 00h


;------------------------START-inits-----------------------; 

START: cli

a8259 equ 4000h
a8255 equ 4010h
b8255 equ 4020h
a8253 equ 4030h
b8253 equ 4040h


8259_init:

;icw1
mov al, 00010011b   ;ICW4 Needed (single 8259)
mov dx, a8259+00h   ; dx has 1st address of 8259
out dx, al

;icw2
mov al, 10000000b   ; dx has 2nd address of 8259
mov dx, a8259+02h   ; 80h is generatedfor IR0 ie But-INT
out dx,al

;icw4
mov al, 00000011b       ; rest follow 80h - 87h
out dx,al
 
;ocw1
mov al, 11111110b   ; non buffered mode with AEOI enabled
out dx, al  

; Initialising 8255A ...

8255_init:
mov al, 10000010b       ;Cmnd Word - port a(o/p), !(prt B: i/p)
mov dx, a8255+06h
out dx, al

; !(Same as prev 8255) B - i/p C - for controlling ADC

mov al, 10000010b
mov dx, b8255+06h
out dx, al  

8253_init:              ; counter0 - sq. wave - binary i/p(2MHz-i/p)
;1Mhz
mov al, 00010110b
mov dx, a8253+06h
out dx, al
mov al, 02h
mov dx, a8253+00h       ; To divide by 2 - to give 1MHz
out dx, al


;16hz
mov al, 01110110b       ;counter1 - sq. wave - binary i/p
mov dx, a8253+06h
out dx, al
mov al, 24h              ; count = 62500 = 0f424h
mov dx, a8253+02h
out dx, al
mov al, 0F4h
out dx, al

;2-min
mov al, 10110100b       ;cntr3 - Using mode 2 - every 2 min(low)
mov dx, a8253+06h       ;Must be inverted and given as interrupt
out dx, al
mov al, 80h            ; 
mov dx, a8253+04h
out dx, al
mov al, 07h             ; 
out dx, al

;1hr
mov al, 00110100b       ;counter 0 - 16Hz to 1Hr pulse (obsolete)
mov dx, b8253+06h
out dx, al
mov al, 00h
mov dx, b8253+00h
out dx, al
mov al, 0E1h
out dx, al  


LCD_init:
LCDEN equ 80h
LCDRW equ 40h
LCDRS equ 20h

aclrb LCDRW
LCD_OUT 38h
LCD_OUT 0Eh
LCD_OUT 06h

LCD_CLEAR


LCD_init1:
LCDEN1 equ 10h
LCDRW equ 40h
LCDRS equ 20h

aclrb LCDRW
LCD_OUT1 38h
LCD_OUT1 0Eh
LCD_OUT1 06h

LCD_CLEAR



LCD_init11:
LCDEN11 equ 08h
LCDRW equ 40h
LCDRS equ 20h

aclrb LCDRW
LCD_OUT11 38h
LCD_OUT11 0Eh
LCD_OUT11 06h

LCD_CLEAR
 
;------------------------START-code-------------------------;

; Perform Initial display ...

;turn on adc - temperature
mov THP,00h
int 81h     

;wait for eoc

eocint08:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint08

eocint18:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint18

;Store Values - Temperature

mov THP,00h
int 83h

;Repeat process for Humi~ty

mov THP,01h
int 81h     ; do same for humi~

;wait for eoc
eocint010:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint010

eocint101:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint101


mov THP,01h
int 83h

; FOR pressure

mov THP,11h
int 81h     ; do same for humi

;wait for eoc
eocint0109:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint0109

eocint1018:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint1018


mov THP,11h
int 83h



mov THP,00h
int 82h
mov THP,01h
int 82h
mov THP,11h
int 82h

; --------END of initial display ---------------


;poll portb of a8255 forever
xinf:

;check if button is pressed using a flag stored in memory
mov al, LIVE_UPDATE
cmp al, 01h
jnz cont
mov LIVE_UPDATE, 00h

mov THP,00h         ;FOR TEMPERATURE
int 81h ;turn on adc

;wait for eoc
eocint0:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint0

eocint1:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint1


mov THP,00h
int 83h

mov THP,01h
int 81h     ; do same for humi

;wait for eoc
eocint00:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint00

eocint11:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint11


mov THP,01h
int 83h



mov THP,11h ; FOR PRESSURE
int 81h



;wait for eoc
eocint000:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint000

eocint111:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint111

mov THP,11h
int 83h





mov THP,00h
int 82h
mov THP,01h
int 82h
mov THP,11h
int 82h



;regular polling
cont:
mov dx, a8255+02h
in al, dx

mov bl, al
and bl, 01h
jz butint

mov bl, al
and bl, 02h
jz twomin

mov bl, al
and bl, 04h
jz onehr

mov bl, al
and bl, 08h
jz eocint
jmp xinf

;low logic detected. Wait for whole pulse
butint:
in al, dx
and al, 01h
jz butint

int 80h
jmp xinf

twomin:
in al, dx
and al, 02h
jz twomin

mov THP,00h
int 81h

eocint09:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint09

eocint19:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint19

mov THP,00h
int 83h


mov THP,01h
int 81h


;wait for eoc
eocint009:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint009


eocint119:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint119

mov THP,01h
int 83h


mov THP,11h
int 81h



;wait for eoc
eocint00999:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jnz eocint00999


eocint11999:
mov dx, a8255+02h
in al, dx
mov bl, al
and bl, 08h
jz eocint11999

mov THP,11h
int 83h


;Change value of no. of 2 min intervals taken during simulation
 
inc READY_FOR_HOUR

cmp READY_FOR_HOUR,02h
jnz DND_ONE_HOUR

mov THP,00h
int 82h ; Call the 1 hour interrupt
mov THP,01h
int 82h
mov THP,11h
int 82h

mov READY_FOR_HOUR,00h ; Reset the 30, 2-min interval count


DND_ONE_HOUR: jmp xinf


; Obsolete. Is not use as intrpt is called directly

onehr:
in al, dx
and al, 04h
jz onehr

int 82h
jmp xinf

eocint:
in al, dx
and al, 08h
jz eocint

mov THP,00h
int 83h
mov THP,01h
int 83h
mov THP,11h
int 83h


jmp xinf




jmp quit



;------------------------START-macros-----------------------;
pushall macro
    push ax
    push bx
    push cx
    push dx
    push si
    push di
endm

popall macro
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
endm

;set/clear pins since BSR was being strange
asetb    macro mbit
    pushall
    mov al, mbit
    mov bl, C_STATE_A
    or  al, bl
    mov dx, a8255+04h
    out dx, al
    mov bl, al
    mov C_STATE_A, bl
    popall            
endm


aclrb    macro mbit
    pushall
    mov al, mbit
    xor al, 0FFh
    mov bl, C_STATE_A
    and al, bl
    mov dx, a8255+04h
    out dx, al
    mov bl, al
    mov C_STATE_A, bl
    popall             
endm

adcst equ 01h
adcoe equ 02h
adcA equ 04h
adcB equ 08h
adcC equ 10h
adcALE equ 20h

bsetb    macro mbit
    pushall
    mov al, mbit
    mov bl, C_STATE_B
    or  al, bl
    mov dx, b8255+04h
    out dx, al
    mov bl, al
    mov C_STATE_B, bl
    popall            
endm


bclrb    macro mbit
    pushall
    mov al, mbit
    xor al, 0FFh
    mov bl, C_STATE_B
    and al, bl
    mov dx, b8255+04h
    out dx, al
    mov bl, al
    mov C_STATE_B, bl
    popall             
endm

LCD_OUT    macro dat
    aclrb LCDRS
    pushall
    mov al, dat
    mov dx, a8255+00h
    out dx, al
    asetb LCDEN
    aclrb LCDEN
    call delay_20ms
    popall
endm


LCD_OUT1    macro dat
    aclrb LCDRS
    pushall
    mov al, dat
    mov dx, a8255+00h
    out dx, al
    asetb LCDEN1
    aclrb LCDEN1
    call delay_20ms
    popall
endm

LCD_OUT11    macro dat
    aclrb LCDRS
    pushall
    mov al, dat
    mov dx, a8255+00h
    out dx, al
    asetb LCDEN11
    aclrb LCDEN11
    call delay_20ms
    popall
endm


lcd_write_char macro dat
    asetb LCDRS
    pushall
    mov al, dat
    mov dx, a8255+00h
    out dx, al
    asetb LCDEN
    aclrb LCDEN
    call delay_20ms
    popall    

endm

         
lcd_write_char1 macro dat
    asetb LCDRS
    pushall
    mov al, dat
    mov dx, a8255+00h
    out dx, al
    asetb LCDEN1
    aclrb LCDEN1
    call delay_20ms
    popall    

endm

lcd_write_char11 macro dat
    asetb LCDRS
    pushall
    mov al, dat
    mov dx, a8255+00h
    out dx, al
    asetb LCDEN11
    aclrb LCDEN11
    call delay_20ms
    popall    

endm

LCD_CLEAR macro
    LCD_OUT 01h
endm
 
;division routine since div was acting strange
wow_divide macro  divi
    
    pushall
    mov cx, 00
    mov bx, divi
    
    loopy:
    sub ax, bx
    inc cx
    cmp ax, 0
    jge loopy

    dec cx
    add ax, bx
    
    mov r, al
    mov q, cl

    popall
endm

          
wow_divide1 macro  divi
    
    pushall
    mov cx, 00
    mov bx, divi
    
    loopy1:
    sub ax, bx
    inc cx
    cmp ax, 0
    jge loopy1

    dec cx
    add ax, bx
    
    mov r, al
    mov q, cl

    popall
endm

wow_divide2 macro  divi
    
    pushall
    mov cx, 00
    mov bx, divi
    
    loopy2:
    sub ax, bx
    inc cx
    cmp ax, 0
    jge loopy2

    dec cx
    add ax, bx
    
    mov r, al
    mov q, cl

    popall
endm

;------------------------START-Procedure Defs-----------------------;

;delay proc: just a huge loop
delay_20ms proc near
    mov dx, 10
r1: mov cx, 2353
r2: loop r2
    dec dx
    jne r1
    ret     
delay_20ms endp


;write a string in memory to LCD
write_string proc near   
    lea si, LCD_LINE_1
    mov cl, LCD_COUNT_1
l1: lcd_write_char [si]
    inc si
    loop l1
    ret
write_string endp


;write a string in memory to LCD
write_string1 proc near   
    lea si, LCD_LINE_11
    mov cl, LCD_COUNT_11
l11: lcd_write_char1 [si]
    inc si
    loop l11
    ret
write_string1 endp


;write a string in memory to LCD
write_string11 proc near   
    lea si, LCD_LINE_111
    mov cl, LCD_COUNT_111
l111: lcd_write_char11 [si]
    inc si
    loop l111
    ret
write_string11 endp


;-----------------------------------------------
;Scale Humidity 

convert_humi proc near
    
    ;get it to scale (0-99%)
    mov ah, 00h
    mov al, q
    mov bl, 99d            
    mul bl
    mov bl, 0FFh            ;FFh is the max o/p from ADC
    div bl
    
    
    ;split the numbers                        
    mov ah, 00h
    mov bl, 10d
    div bl
    
    lea si, numstr          ;Load appropriate ascii value(quo)
    add ax, 3030h
    mov [si], al
    mov [si+1], ah 
    
    mov al, r
    mov ah, 00h
    
    mov bx, 100d
    mul bx
    mov bl, 30d
    div bl
    
    mov ah, 00h
    mov bl, 10d
    div bl
    add ax, 3030h
    
    mov [si+2], al      ;Load appropriate ascii value(rem)
    mov [si+3], ah
   
    ret

convert_humi endp

; Scaling fns ----------------------------------------------

;Scale temperature 

convert_temp proc near
    
    ;get it to scale (5-50 C)
    mov ah, 00h
    mov al, q
    mov bl, 45d
    mul bl
    mov bl, 0FFh
    div bl
    add ax, 05h
    
    ;split the numbers                     
    mov ah, 00h
    mov bl, 10d
    div bl
    
    lea si, numstr
    add ax, 3030h
    mov [si], al
    mov [si+1], ah 
    
    mov al, r
    mov ah, 00h
    
    mov bx, 100d
    mul bx
    mov bl, 30d
    div bl
    
    mov ah, 00h
    mov bl, 10d
    div bl
    add ax, 3030h
    
    mov [si+2], al
    mov [si+3], ah
   
    ret

convert_temp endp


;--------------------------------------------------------------------------
;Scale Pressure  

convert_pres proc near
    
    ;get it to scale (0-2 Bar)
    mov ah, 00h
    mov al, q
    mov bl, 02d            
    mul bl
    mov bl, 0FFh            ;FFh is the max o/p from ADC
    div bl
    
    
    ;split the numbers                        
    mov ah, 00h
    mov bl, 10d
    div bl
    
    lea si, numstr          ;Load appropriate ascii value(quo)
    add ax, 3030h
    mov [si], al
    mov [si+1], ah 
    
    mov al, r
    mov ah, 00h
    
    mov bx, 100d
    mul bx
    mov bl, 30d
    div bl
    
    mov ah, 00h
    mov bl, 10d
    div bl
    add ax, 3030h
    
    mov [si+2], al      ;Load appropriate ascii value(rem)
    mov [si+3], ah
   
    ret

convert_pres endp


;output ascii equiv values on LCD from mem location

num_out proc near
    
    LCD_OUT 01h
     lea si, LCD_LINE_1
    mov cl, LCD_COUNT_1
    lx1: lcd_write_char [si]
    inc si
    loop lx1
    ;call write_string
    
    mov al, numstr
    mov ah, numstr+1
    lcd_write_char al
    lcd_write_char ah
    lcd_write_char '.'
    mov al, numstr+2
    mov ah, numstr+3
    
    lcd_write_char al
    lcd_write_char ah
   
    
    ret     
    
num_out endp


;output ascii equiv values on LCD from mem location
num_out1 proc near
    
    LCD_OUT1 01h
    
    lea si, LCD_LINE_11
    mov cl, LCD_COUNT_11
lx11:     mov bl, [si]
    lcd_write_char1 bl
    add si, 1
    loop lx11
    
    ;call write_string1
    
    mov al, numstr
    mov ah, numstr+1
    lcd_write_char1 al
    lcd_write_char1 ah
    lcd_write_char1 '.'
    mov al, numstr+2
    mov ah, numstr+3
    
    lcd_write_char1 al
    lcd_write_char1 ah
   
    
    ret     
    
num_out1 endp

num_out11 proc near
    
    LCD_OUT11 01h
    ;call write_string11
    
    lea si, LCD_LINE_111
    mov cl, LCD_COUNT_111
lx111: lcd_write_char11 [si]
    inc si
    loop lx111
    
    mov al, numstr
    mov ah, numstr+1
    lcd_write_char11 al
    lcd_write_char11 ah
    lcd_write_char11 '.'
    mov al, numstr+2
    mov ah, numstr+3
    
    lcd_write_char11 al
    lcd_write_char11 ah
   
    
    ret     
    
num_out11 endp

; ------------------------- End of procedure Defs --------------------------

;------------------------START Of ISRs-----------------------;

;2 minute interrupt
isr1:

    
    ; First make OE high PC1
    bsetb adcoe


    cmp THP,00h
    jnz humiisr1

    ;Assuming that CBA is connected to PC 4-3-2
    ;select channel 000
    bclrb adcA
    bclrb adcB
    bclrb adcC

    ;Now make a high-low pulse on ALE;PC5
    bsetb adcALE
    bclrb adcALE

    ;High-low pulse on SOC - connected to PC0
    bsetb adcst
    bclrb adcst

    ;now wait for EOC interrupt
    jmp isr1end

    humiisr1:           ; THP == 1
    cmp THP,01h
    jnz presisr1

    ;select channel 001
    bsetb adcA
    bclrb adcB
    bclrb adcC

    ;Now make a high-low pulse on ALE;PC5
    bsetb adcALE
    bclrb adcALE

    ;High-low pulse on SOC - connected to PC0
    bsetb adcst
    bclrb adcst

    jmp isr1end

    presisr1:

    ;select channel 010
    bclrb adcA
    bsetb adcB
    bclrb adcC

    ;Now make a high-low pulse on ALE;PC5
    bsetb adcALE
    bclrb adcALE

    ;High-low pulse on SOC - connected to PC0
    bsetb adcst
    bclrb adcst

    

isr1end:
    
iret


;EOC interrupt
isr3:


    cmp THP,00h
    jnz humiisr3


    mov dx, b8255+02h
    in al, dx

    ;Finally make OE low
    bclrb adcoe


    cmp FLAG_COUNT, 0
    jnz x4
    ;for the first hour, flagcnt = 0; for consecutive iterations, it'll be >0

    mov bx, COUNTER
    lea si, VALUES 
      
    mov [si+bx], al
    inc bx
    mov COUNTER, bx
    cmp bx, 30
    jnz x5

    mov FLAG_COUNT, 1
    mov COUNTER, 0
    jmp endisr1

    x4: mov bx, COUNTER
    lea si, VALUES
    mov [si+bx], al
    inc bx
    cmp bx, 30
    jnz x5
    mov bx, 0

    x5: mov COUNTER, bx

    jmp endisr1

    humiisr3:       ;THP == 1
    cmp THP,01h
    jnz presisr3

    
    mov dx, b8255+02h
    in al, dx

    ;Finally make OE low
    bclrb adcoe


    cmp FLAGCOUNT_11, 0
    jnz x41

    mov bx, CTR_11
    lea si, VALS_11 
      
    mov [si+bx], al
    inc bx
    mov CTR_11, bx
    cmp bx, 30
    jnz x51

    mov FLAGCOUNT_11, 1
    mov CTR_11, 0
    jmp endisr1

    x41:    mov bx, CTR_11
    lea si, VALS_11
    mov [si+bx], al
    inc bx
    cmp bx, 30
    jnz x51
    mov bx, 0

    x51:    mov CTR_11, bx
    jmp endisr1

    presisr3:

    
    mov dx, b8255+02h
    in al, dx

    ;Finally make OE low
    bclrb adcoe


    cmp FCOUNT, 0
    jnz x411
    

    mov bx, CTR111
    lea si, VALS111 
      
    mov [si+bx], al
    inc bx
    mov CTR111, bx
    cmp bx, 30
    jnz x511

    mov FCOUNT, 1
    mov CTR111, 0
    jmp endisr1

    x411:   mov bx, CTR111
    lea si, VALS111
    mov [si+bx], al
    inc bx
    cmp bx, 30
    jnz x511
    mov bx, 0

    x511:   mov CTR111, bx

    
     
    endisr1:
iret
      
      
      
;1hr int 
isr2:

cmp THP,00h
jnz humiisr2

    mov bx, 00h
    mov cx, 30d
    lea si, VALUES

    xadd:
    mov dl, [si]
    mov dh, 00h
    add bx, dx
    inc si
    dec cx
    jnz xadd
    mov ax, bx

    mov dx, FLAG_COUNT
    cmp dx, 1
    jnz x2

    mov DIV_BY, 30d
    jmp x3

    x2:
    mov dx, COUNTER
    mov DIV_BY, dx
    
    x3:
    wow_divide DIV_BY 

    call convert_temp
    call num_out

jmp endisr2:

    humiisr2:
    cmp THP,01h
    jnz presisr2

    mov bx, 00h
    mov cx, 30d
    lea si, VALS_11

    xadd1:
    mov dl, [si]
    mov dh, 00h
    add bx, dx
    inc si
    dec cx
    jnz xadd1
    mov ax, bx

    mov dx, FLAGCOUNT_11
    cmp dx, 1
    jnz x21

    mov DIV_BY, 30d
    jmp x31

    x21:
    mov dx, CTR_11
    mov DIV_BY, dx
    x31:

    wow_divide1 DIV_BY 

    call convert_humi
    call num_out1
    jmp endisr2

    presisr2:

    
    mov bx, 00h
    mov cx, 30d
    lea si, VALS111

    xadd11:
    mov dl, [si]
    mov dh, 00h
    add bx, dx
    inc si
    dec cx
    jnz xadd11
    mov ax, bx

    mov dx, FCOUNT
    cmp dx, 1
    jnz x211

    mov DIV_BY, 30d
    jmp x311

    x211:
    mov dx, CTR111
    mov DIV_BY, dx
    x311:

    wow_divide2 DIV_BY 

    call convert_pres
    call num_out11


endisr2:

iret 
 
;button interrupt
isr0:
    mov LIVE_UPDATE, 01h
iret  

;-----------------------END OF ISRs------------------------;



quit:
hlt


