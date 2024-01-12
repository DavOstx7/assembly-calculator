; ------------------------------------------------------------------------------------------------------------
; Read a BMP file 320x200 and print it to screen
; Author: Barak Gonen, 2014
; Credit: Diego Escala, www.ece.msstate.edu/~reese/EE3724/labs/lab9/bitmap.asm
; -------------------------------------------------------------------------------------------------------------
IDEAL
MODEL small
STACK 100h
DATASEG
filename db 's.bmp',0
filehandle dw ?
Header db 54 dup (0)
Palette db 256*4 dup (0)
ScrLine db 320 dup (0)
ErrorMsg db 'Error', 13, 10,'$'
RES DB 10 DUP ('$')
spaceA db '                         $'
spaceA1 db '                  $'
space db 13, 10, ' $'
msg1 db 13, 10, 'How the calculator works: $'
msg2 db 13, 10, 'Max digits for a number is 4$'
msg3 db 13, 10, 'You enter digits by using the keyboard(you can choose negative numbers by using the "-" key at the start of the input)$'
msg4 db 13, 10, 'When you finish entering your number press enter $'
msg5 db 13, 10, 'If you put more than 4 digits, it will take the last 4 $'
msg6 db 13, 10, 'You choose the math act/elementary arithmetic with the mouse $'
msg7 db 13, 10, 'Turning off the calculator (clicking on OFF) will bring you into text mode and finish the program $'
msg8 db 13, 10, 'Deleting(clicking on C/AC) will start the calculator again $'
msg9 db 13, 10, 'Clicking on " = " is only possible after entering the first number $'
msg10 db 13, 10, 'Using the mouse is only possible after entering number1 or number2 $'
msg11 db 13, 10, 'Max answer possible is (range): 65535-(-65535) $'
msg12 db 13, 10, 'Click any key to continue:  $'
msg13 db 13, 10, 'Over or lower than 65535,(-65535)$'
msg14 db 13, 10, 'Press Esc to turn OFF.  Press any other key to continue$'
msgModule db 13, 10, 'Module:$'
cantDivide db 13, 10, 'Cant divide a number in 0$'
TooBig db 0
address dw ?
address1 dw ?
address2 dw ?
Module dw ?
X dw ?
Y dw ?
arr1 db 4 dup (0)
arr1Spare db 20 dup (0)
arr2 db 4 dup (0)
arr2Spare db 20 dup (0)
tempNum1 dw 0 ;temporary
tempNum2 dw 0 ;temporary
decNum1 dw ? ;dec looking of num 2
decNum2 dw ? ;dec looking of num 1
lenNum1 dw 0 ;length of num1 (how much digits)
lenNum2 dw 0 ;length of num2 (how much digits)
num1 dw 0
num2 dw 0
negNum1 db 0 ;check if num1 is neg (0 means not, 1 means yes)
negNum2 db 0 ;check if num1 is neg (0 means not, 1 means yes)
NTD dw ? ;number to divide
saveModule dw ? ; save the module of the number
saveDiv db ? ;save the div of the number
SLP db ? ;save the place of the last printed number
check db ? ;checking values (it's for checking - it has no purpose)
printMinus db 0 ;if 0 - dont prin't minus, if 1- print minus 
answer dw 0
CODESEG
; ------------------------------------------------------------------------------------------------------------
;PROC Get_Num_1
;IN: NOTHING
;OUT: GETS DEC VALUE OF NUM1, GETS DECIMAL LOOKING OF NUM1(decNum1), GETS IF THE NUM1 IS NEGATIVE, GETS THE LENGTH OF NUM1
; -------------------------------------------------------------------------------------------------------------
	proc GetNum1
	pop [address1]
again:
	mov [num1], 0 ;reset num
	mov si, 0h ;si -> counter for the array
	mov ah, 0 ;get input from keyboard
	int 16h
	cmp ah, 0Ch ;compare input to see if its valid
	JA again
	cmp ah, 0Ch ;compares the input to " - " (minus) to see if its a negetive num
	JNE notNegative
;minus key was pressed	
again1:
	mov [negNum1], 1
	mov ah, 0 ;get the value of the digit
	int 16h
	cmp ah, 0Bh ;compare input to see if its valid
	JA again1
	cmp ah, 0bh ;compare to see if the digit is 0
	JE digitzero	
	dec ah ;minus 1 to get the value of the number 
	mov [arr1 + si], ah
	inc si
	JMP startInput
notNegative:
	cmp ah, 0bh ;compare to see if the digit is 0
	JE digitzero	
	dec ah ;minus 1 to get the value of the number 
	mov [arr1 + si], ah
	inc si
	JMP startInput
startInput:	
	mov ah, 0 ;get the value of the digit
	int 16h
	cmp ah, 01ch ;compare to see if enter was pressed (finish input)
	JE finishInput
	cmp ah, 0Bh ;compare input to see if its valid
	JA startInput
	cmp ah, 0bh ;compare to see if the digit is 0
	JE digitzero	
	dec ah ;minus 1 to get the value of the number 
	mov [arr1 + si], ah
	inc si
	JMP startInput
digitzero:
	mov ah, 0
	mov [arr1 + si], ah
	inc si
	JMP startInput
finishInput:

;making the number(digit * 1 + tens * 10 ...)	
	mov [lenNum1], si
	xor ax, ax
	CMP si, 0h	
	JE lastTime1 ;out of range to jump to lastTime
	dec si ;the place in the array of the last digit
	mov al, [arr1 + si] ;units
	mov [tempNum1], ax
	mov [decNum1], ax ;units 
	mov ax, 10
	
	CMP si, 0h
	JE lastTime ;check if it's the digit on the left(first one)
	dec si
	mov al, 10 ;tens
	xor bx, bx
	mov bl, [arr1 + si]
	mul bl
	add [tempNum1], ax
	
	mov al, 10h ;tens
	xor bx, bx
	mov bl, [arr1 + si]
	mul bl
	add [decNum1], ax
	
	CMP si, 0h 
	JE lastTime
	dec si
	mov ax, 100  ;hundreds
	xor dx, dx
	xor bx, bx
	mov bl, [arr1 + si]
	mul bx
	add [tempNum1], ax
	add [tempNum1], dx
	jmp hop
lastTime1:
	JMP lastTime
hop:	
	mov ax, 100h ;hundreds
	xor dx, dx
	xor bx, bx
	mov bl, [arr1 + si]
	mul bx
	add [decNum1], ax
	add [decNum1], dx
	
	cmp si, 0h
	JE lastTime 
	dec si
	mov ax, 1000 ;thousands
	xor bx, bx
	mov bl, [arr1 + si]
	mul bx
	add [tempNum1], ax
	add [tempNum1], dx
	
	mov ax, 1000h ;thousands
	xor bx, bx
	mov bl, [arr1 + si]
	mul bx
	add [decNum1], ax
	add [decNum1], dx
lastTime:	
	mov bx, [tempNum1]
	mov [num1], bx
	cmp [lenNum1],5 ;if the input was more than 4 digits - make the length 4
	JB lessThan4Input1
	mov [lenNum1], 4h
lessThan4Input1:	
	push [address1]
	ret
	endp GetNum1
; ------------------------------------------------------------------------------------------------------------
;PROC Get_Num_2
;IN: NOTHING
;OUT: GETS DEC VALUE OF NUM2, GETS DECIMAL LOOKING OF NUM2(decNum2), GETS IF THE NUM2 IS NEGATIVE, GETS THE LENGTH OF NUM2
; -------------------------------------------------------------------------------------------------------------
	proc GetNum2
	pop [address2]
againV2:
	mov [num2], 0 ;reset num
	mov si, 0h ;si -> counter for the array
	mov ah, 0 ;get input from keyboard
	int 16h
	cmp ah, 0Ch ;compare input to see if its valid
	JA againV2
	cmp ah, 0Ch ;compares the input to " - " (minus) to see if its a negetive num
	JNE notNegativeV2
;minus key was pressed	
again1V2:
	mov [negNum2], 1
	mov ah, 0 ;get the value of the digit
	int 16h
	cmp ah, 0Ch ;compare input to see if its valid
	JA again1V2
	cmp ah, 0bh ;compare to see if the digit is 0
	JE digitzeroV2	
	dec ah ;minus 1 to get the value of the number 
	mov [arr2 + si], ah
	inc si
	JMP startInputV2	
notNegativeV2:
	cmp ah, 0bh ;compare to see if the digit is 0
	JE digitzeroV2	
	dec ah ;minus 1 to get the value of the number 
	mov [arr2 + si], ah
	inc si
	JMP startInputV2
startInputV2:	
	mov ah, 0 ;get the value of the digit
	int 16h
	cmp ah, 01ch ;compare to see if enter was pressed (finish input)
	JE finishInputV2
	cmp ah, 0Bh ;compare input to see if its valid
	JA startInputV2
	cmp ah, 0bh ;compare to see if the digit is 0
	JE digitzeroV2	
	dec ah ;minus 1 to get the value of the number 
	mov [arr2 + si], ah
	inc si
	JMP startInputV2
	
digitzeroV2:
	mov ah, 0
	mov [arr2 + si], ah
	inc si
	JMP startInputV2
finishInputV2:

;making the number(digit * 1 + tens * 10 ...)	
	mov [lenNum2], si
	xor ax, ax
	CMP si, 0h	
	JE lastTime1V2 ;out of range to jump to lastTime
	dec si ;the place in the array of the last digit
	mov al, [arr2 + si] ;units
	mov [tempNum2], ax
	mov [decNum2], ax ;units 
	mov ax, 10
	
	CMP si, 0h
	JE lastTimeV2 ;check if it's the digit on the left(first one)
	dec si
	mov al, 10 ;tens
	xor bx, bx
	mov bl, [arr2 + si]
	mul bl
	add [tempNum2], ax
	
	mov al, 10h ;tens
	xor bx, bx
	mov bl, [arr2 + si]
	mul bl
	add [decNum2], ax
	
	CMP si, 0h 
	JE lastTimeV2
	dec si
	mov ax, 100  ;hundreds
	xor dx, dx
	xor bx, bx
	mov bl, [arr2 + si]
	mul bx
	add [tempNum2], ax
	add [tempNum2], dx
	jmp hopV2
lastTime1V2:
	JMP lastTimeV2
hopV2:	
	mov ax, 100h ;hundreds
	xor dx, dx
	xor bx, bx
	mov bl, [arr2 + si]
	mul bx
	add [decNum2], ax
	add [decNum2], dx
	
	cmp si, 0h
	JE lastTimeV2
	dec si
	mov ax, 1000 ;thousands
	xor bx, bx
	mov bl, [arr2 + si]
	mul bx
	add [tempNum2], ax
	add [tempNum2], dx
	
	mov ax, 1000h ;thousands
	xor bx, bx
	mov bl, [arr2 + si]
	mul bx
	add [decNum2], ax
	add [decNum2], dx
lastTimeV2:	
	mov bx, [tempNum2]
	mov [num2], bx
	cmp [lenNum2],5 ;if the input was more than 4 digits - make the length 4
	JB lessThan4Input1V2
	mov [lenNum2], 4h
lessThan4Input1V2:	
	push [address2]
	ret
	endp GetNum2
; ------------------------------------------------------------------------------------------------------------
;PROC Print_Num_1
;IN: NOTHING
;OUT:PRINTS NUM1 IN A SPECIFIC POSITION (SLP)
; -------------------------------------------------------------------------------------------------------------
	proc PrintNum1
	pop [address]
	mov  ax,0002h ; hide mouse cursor
	int  33h	
	cmp [negNum1], 0h
	JE notNeg
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov al, 45
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
notNeg:	
	mov si, 0h ;counter of the array
	mov cx, [lenNum1]
	dec cx
	cmp cx, 0  ;check if the number is an unit
	JNE notUnit
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  ax, [decNum1]
	add al, 30h ;print digit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	jmp finishedPrint1
notUnit:
	mov ax, 1
	mov bx, 10h ;multiply by 10 for the amount of digits that are in the num
lop:
	mul bx
loop lop	
	mov [NTD], ax
	cmp si, [lenNum1] ;check if it's already finished printing
	JE finishedPrint1
	mov ax, [decNum1]
	mov bx, [NTD]
	div bx
	mov [saveDiv], al ;save the div (first digit of the number)
	mov [saveModule], dx ;save the module
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;print digit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	
	inc si ;next digit
	cmp si, [lenNum1] ;check if it's already finished printing
	JE finishedPrint1
	mov ax, [NTD]
	mov dx, 0
	mov bx, 10h		
	div bx
	mov [NTD], ax
	mov ax, [saveModule]	
	mov bx, [NTD]
	div bx
	mov [saveDiv], al ;save the div (first digit of the number)
	mov [saveModule], dx ;save the module
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;printdigit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	JMP next
finishedPrint1:
	JMP finishedPrint
	next:
	inc si ;next digit
	
	cmp si, [lenNum1] ;check if it's already finished printing
	JE finishedPrint
	mov ax, [NTD]
	mov bx, 10h
	mov dx, 0
	div bx
	mov [NTD], ax
	mov ax, [saveModule]
	mov bx, [NTD]
	div bx
	mov [saveDiv], al ;save the div (first digit of the number)
	mov [saveModule], dx ;save the module
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2  ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;printdigit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	
	inc si ;next digit
	cmp si, [lenNum1] ;check if it's already finished printing
	JE finishedPrint	
;no need to dive NTD by 10 because it will be unit digit	
	mov bx, [saveModule]
	mov [saveDiv], bl ;move saveModule to saveDiv
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;printdigit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
finishedPrint:
	mov  ax,0001h ; show mouse cursor
	int  33h
	push [address]
	ret
	endp PrintNum1
; ------------------------------------------------------------------------------------------------------------
;PROC Print_Num_2
;IN: NOTHING
;OUT:PRINTS NUM2 IN A SPECIFIC POSITION (SLP)
; -------------------------------------------------------------------------------------------------------------	
	proc PrintNum2
	pop [address2]
	mov  ax,0002h ; hide mouse cursor
	int  33h	
	cmp [negNum2], 0h
	JE notNegV2
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov al, 45
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
notNegV2:	
	mov si, 0h ;counter of the array
	mov cx, [lenNum2]
	dec cx
	cmp cx, 0  ;check if the number is an unit
	JNE notUnitV2
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  ax, [decNum2]
	add al, 30h ;print digit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	jmp finishedPrint1V2
notUnitV2:
	mov ax, 1
	mov bx, 10h ;multiply by 10 for the amount of digits that are in the num
lopV2:
	mul bx
loop lopV2	
	mov [NTD], ax
	cmp si, [lenNum2] ;check if it's already finished printing
	JE finishedPrint1V2
	mov ax, [decNum2]
	mov bx, [NTD]
	div bx
	mov [saveDiv], al ;save the div (first digit of the number)
	mov [saveModule], dx ;save the module
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;print digit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	
	inc si ;next digit
	cmp si, [lenNum2] ;check if it's already finished printing
	JE finishedPrint1V2
	mov ax, [NTD]
	mov dx, 0
	mov bx, 10h		
	div bx
	mov [NTD], ax
	mov ax, [saveModule]	
	mov bx, [NTD]
	div bx
	mov [saveDiv], al ;save the div (first digit of the number)
	mov [saveModule], dx ;save the module
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;printdigit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	JMP nextV2
finishedPrint1V2:
	JMP finishedPrintV2
nextV2:
	inc si ;next digit
	
	cmp si, [lenNum2] ;check if it's already finished printing
	JE finishedPrintV2
	mov ax, [NTD]
	mov bx, 10h
	mov dx, 0
	div bx
	mov [NTD], ax
	mov ax, [saveModule]
	mov bx, [NTD]
	div bx
	mov [saveDiv], al ;save the div (first digit of the number)
	mov [saveModule], dx ;save the module
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2  ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;printdigit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
	
	inc si ;next digit
	cmp si, [lenNum2] ;check if it's already finished printing
	JE finishedPrintV2	
;no need to dive NTD by 10 because it will be unit digit	
	mov bx, [saveModule]
	mov [saveDiv], bl ;move saveModule to saveDiv
	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h

	mov  al, [saveDiv]
	add al, 30h ;printdigit
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]
finishedPrintV2:
	mov  ax,0001h ; show mouse cursor
	int  33h
	push [address2]
	ret
	endp PrintNum2
; ------------------------------------------------------------------------------------------------------------
;PROC Plus_Or_Minus_Module
;IN: NOTHING
;OUT:PRINTS MINUS/PLUS INFRONT OF THE MODULE (IF THERE IS A MODULE)
; -------------------------------------------------------------------------------------------------------------
	proc PlusOrMinusModule
	pop [address]
	cmp [answer], 0
	JE finiV2 ;doesnt need a plus or a minus
	cmp [printMinus], 0h
	JE printPlusOnScreenV2
;printMinusOnScreen
	mov  al, 45 ;print -
	mov  bl, 9  ;Color 
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	jmp finiV2 ;finished printing minus
printPlusOnScreenV2:
	mov  al, 43 ;print +
	mov  bl, 9 ; Color 
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
finiV2:
	push [address]
	ret
	endp PlusOrMinusModule
; ------------------------------------------------------------------------------------------------------------
;PROC Plus_Or_Minus
;IN: NOTHING
;OUT:PRINTS MINUS/PLUS INFRONT OF THE ANSWER (IF THERE IS A MODULE)
; -------------------------------------------------------------------------------------------------------------
	proc PlusOrMinus
	pop [address]
	mov  dl, 6   ;Column
	mov  dh, 5   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	cmp [answer], 0
	JE fini ;doesnt need a plus or a minus
	cmp [printMinus], 0h
	JE printPlusOnScreen
;printMinusOnScreen
	mov  al, 45 ;print -
	mov  bl, 9  ;Color  
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	jmp fini ;finished printing minus
printPlusOnScreen:
	mov  al, 43 ;print +
	mov  bl, 9 ; Color 
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
fini:
	push [address]
	ret
	endp PlusOrMinus
; ------------------------------------------------------------------------------------------------------------
;PROC Plus_Nums
;IN: NOTHING
;OUT:CALCULATES THE ANSWER(NUM1 + NUM2) AND MOVES IT TO [ANSWER]
; -------------------------------------------------------------------------------------------------------------
	proc PlusNums
	pop [address]			
;comparing the numbers to know how to add them (checking who has a minus and who is bigger)
	mov al ,[negNum1] ;checking if only 1 number is negetive
	add al, [negNum2]
	CMP al, 0
	JE normalPlus
	CMP al, 1
	JE OneNeg
;both numbers are negative
	mov ax, [num1]
	mov [answer], ax
	mov ax, [num2]
	add [answer], ax
	mov [printMinus], 1
	JMP finishPlus
normalPlus:	
	mov ax, [num1]
	mov [answer], ax
	mov ax, [num2]
	add [answer], ax
	mov [printMinus], 0
	JMP finishPlus
OneNeg:	
;checking if the numbers are equal; (answer will be 0)
	mov ax, [num1]
	cmp ax, [num2]
	JE finishPlus
;making the answer (the answer is going to be +(num1 - num2) or -(num1 - num2)
	mov ax, [num1]
	cmp ax, [num2]
	JA num1Bigger
;num2 bigger
	mov ax, [num2]
	mov [answer], ax
	mov ax, [num1]
	sub [answer], ax
;deciding if the answer is positive or negative	
	cmp [negNum2], 0h 
	JE	num2Positive
;num2 is negative
	mov [printMinus], 1h
	jmp finishPlus
num2Positive:
	mov [printMinus], 0h
	jmp finishPlus
	
num1Bigger:
	mov ax, [num1] ;making the answer (the answer is going to be +(num1 - num2) or -(num1 - num2)
	mov [answer], ax
	mov ax, [num2]
	sub [answer], ax
	
	cmp [negNum1], 0h
	JE num1Positive
;num1 is negative
	mov [printMinus], 1h
	jmp finishPlus
num1Positive:
	mov [printMinus], 0h
finishPlus:
	push [address]
	ret
	endp PlusNums
; ------------------------------------------------------------------------------------------------------------
;PROC Minus_Nums
;IN: NOTHING
;OUT:CALCULATES THE ANSWER(NUM1 - NUM2) AND MOVES IT TO [ANSWER]
; -------------------------------------------------------------------------------------------------------------
	proc MinusNums
	pop [address]
	mov al ,[negNum1] ;checking if only 1 number is negetive
	add al, [negNum2]
	CMP al, 0
	JE NoNeg
	CMP al, 1
	JE OneNegM
;both numbers are negative (al =2)
	mov ax, [num1]
	cmp ax, [num2]
	JE finishMinus1
	JA num1BiggerM
;num2 is bigger
	mov [printMinus], 0h
	mov ax, [num2]
	mov [answer], ax
	mov ax, [num1]
	sub [answer], ax
	JMP finishMinus	
num1BiggerM:
	mov [printMinus], 1
	mov ax, [num1]
	mov [answer], ax
	mov ax, [num2]
	sub [answer], ax
	JMP finishMinus
finishMinus1: ;out of bytes
jmp finishMinus	
;Both numbers are not negative(positive)
NoNeg:
	mov ax, [num1]
	cmp ax, [num2]
	JA num1BiggerM1
;num2 is bigger
	mov [printMinus], 1h
	mov ax, [num2]
	mov [answer], ax
	mov ax, [num1]
	sub [answer], ax
	JMP finishMinus
num1BiggerM1:
	mov [printMinus], 0h
	mov ax, [num1]
	mov [answer], ax
	mov ax, [num2]
	sub [answer], ax
	JMP finishMinus
;one number is negative:	
OneNegM:
	mov ax, [num1]
	mov [answer], ax
	mov ax, [num2]
	add [answer], ax
	xor ax, ax
	mov al, [negNum1]
	cmp al, 1h
	JE num1IsNeg
;num2 is neg
	mov [printMinus], 0h
	JMP finishMinus
num1IsNeg:
	mov [printMinus], 1h
finishMinus:
	push [address]
	ret
	endp MinusNums
; ------------------------------------------------------------------------------------------------------------
;PROC Mult_Nums
;IN: NOTHING
;OUT:CALCULATES THE ANSWER(NUM1 * NUM2) AND MOVES IT TO [ANSWER]
; -------------------------------------------------------------------------------------------------------------
	proc MultNums
	pop [address]
	xor ax, ax
	xor dx, dx
	mov ax, [num1]
	mov bx, [num2]
	mul bx
	cmp dx, 0
	JA Over ;answer is too big	
	
	mov [answer], ax ;answer is okay
;comparing to see if the number is positive or negative
	mov al, [negNum1]
	add al, [negNum2]
	cmp al, 1
	JE NeedsAMinus
;answer is positive
	mov [printMinus], 0
	jmp fin ;finished
;answer is negative
NeedsAMinus:
	mov [printMinus], 1
	jmp fin ;finished
Over:
mov [TooBig], 1h	
fin:
	push [address]
	ret
	endp MultNums
; ------------------------------------------------------------------------------------------------------------
;PROC Div_Nums
;IN: NOTHING
;OUT:CALCULATES THE ANSWER(NUM1 / NUM2) AND MOVES IT TO [ANSWER]
; -------------------------------------------------------------------------------------------------------------
	proc DivNums
	pop [address]
	cmp [num2], 0
	JE finis ;cant divide 
	xor ax, ax
	xor dx, dx
	mov ax, [num1]
	mov bx, [num2]
	div bx
	mov [answer], ax
	mov [module], dx
	;comparing to see if the number is positive or negative
	mov al, [negNum1]
	add al, [negNum2]
	cmp al, 1
	JE NeedsAMinusV2
;answer is positive
	mov [printMinus], 0
	jmp finis ;finished
;answer is negative
NeedsAMinusV2:
	mov [printMinus], 1
finis:
	push [address]
	ret
	endp DivNums
; ------------------------------------------------------------------------------------------------------------
;PROC Reset_RES
;IN: NOTHING
;OUT:RESETS RES TO '$'(RES IS ARRAY)
; -------------------------------------------------------------------------------------------------------------
	proc ResetRES
	pop [address]
	mov si, 0
	mov cx, 10
Reset:
	mov [RES + si], '$'
	inc si
loop Reset	
	push [address]
	ret
	endp ResetRES
; ------------------------------------------------------------------------------------------------------------
;PROC HEX_2_DEC
;IN: NOTHING
;OUT:PRINTS THE DECIMAL VALUE OF AN HEXA NUMBER(IF THE NUMBER IS 64H - IT PRINTS 100)
; -------------------------------------------------------------------------------------------------------------		
	PROC HEX2DEC ;procedure that prints the decimal value of an hexa number, for example: 64h will print 100
    MOV CX,0
    MOV BX,10
   
LOOP1: MOV DX,0
       DIV BX
       ADD DL,30H
       PUSH DX
       INC CX
       CMP AX,9
       JG LOOP1
     
       ADD AL,30H
       MOV [SI],AL
     
LOOP2: POP AX
       INC SI
       MOV [SI],AL
       LOOP LOOP2
       RET
	ENDP HEX2DEC 
; ------------------------------------------------------------------------------------------------------------
;PROC P_Plus
;IN: NOTHING
;OUT:PRINTS "+" INFRONT OF NUMBER1
; -------------------------------------------------------------------------------------------------------------		
	proc PPlus 
	pop [address]
	;print " + " on the screen 
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov  al, 43 ;print +
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]	
	push [address]
	ret
	endp PPlus
; ------------------------------------------------------------------------------------------------------------
;PROC P_Minus
;IN: NOTHING
;OUT:PRINTS "-" INFRONT OF NUMBER1
; -------------------------------------------------------------------------------------------------------------			
	proc PMinus
	pop [address]
	;print " - " on the screen 	
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	
	mov  al, 45 ;print -
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]	
	push [address]
	ret
	endp PMinus
; ------------------------------------------------------------------------------------------------------------
;PROC P_Mult
;IN: NOTHING
;OUT:PRINTS "*" INFRONT OF NUMBER1
; -------------------------------------------------------------------------------------------------------------			
	proc PMult 
	pop [address]
	;print " * " on the screen 
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov  al, 42 ;print  *
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]	
	push [address]
	ret
	endp PMult
; ------------------------------------------------------------------------------------------------------------
;PROC P_Div
;IN: NOTHING
;OUT:PRINTS "/" INFRONT OF NUMBER1
; -------------------------------------------------------------------------------------------------------------			
	proc PDiv 
	pop [address]
	;print " / " on the screen 
	mov  dl, [SLP]   ;Column
	mov  dh, 2   ;Row
	mov  bh, 0    ;Display page
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov  al, 47 ;print  /
	mov  bl, 0Ch  ;Color is red
	mov  bh, 0    ;Display page
	mov  ah, 0Eh  ;Teletype
	int  10h
	inc [SLP]		
	push [address]
	ret
	endp PDiv
; ------------------------------------------------------------------------------------------------------------
;PROC Reset_Vars
;IN: NOTHING
;OUT:RESETS/SETS THE VARIABLES TO THEIR STARTING VALUES
; -------------------------------------------------------------------------------------------------------------			
	proc ResetVars
	pop [address]
	mov [answer],0 ;reset answer
	mov [negNum1], 0 ;reset
	mov [negNum2], 0 ;reset
	xor ax, ax
	xor dx, dx
	mov [TooBig], 0h ;reset
	mov [module], 0 ;reset
	mov [SLP], 8h ;place to start printing
	push [address]
	ret 
	endp ResetVars
; ------------------------------------------------------------------------------------------------------------
;PROC Print_Instructions
;IN: NOTHING
;OUT:PRINTS THE INSTRUCTIONS AT THE START OF THE PROGRAM (IN TEXT MODE)
; -------------------------------------------------------------------------------------------------------------			
	proc PrintInstructions
	pop [address]
	lea DX,[msg1] ;Show msg1
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg2] ;Show msg2
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg3] ;Show msg3
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg4] ;Show msg4
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg5] ;Show msg5
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg6] ;Show msg6
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg7] ;Show msg7
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg8] ;Show msg8
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg9] ;Show msg9
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg10] ;Show msg10
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg11] ;Show msg11
	mov AH,09h
	int 21h
	lea DX,[space] 
	mov AH,09h
	int 21h
	lea DX,[msg12] ;Show msg12
	mov AH,09h
	int 21h	
	push [address]
	ret
	endp PrintInstructions
; ------------------------------------------------------------------------------------------------------------
;PROC Mouse_Int
;IN: NOTHING
;OUT:WAITING FOR A VALID MOUSE CLICK(A CLICK IN A VALID/LOGICAL PLACE), THEN MOVES THE POSITION OF THE CLICK TO [X] AND [Y]
; -------------------------------------------------------------------------------------------------------------			
	proc MouseInt
	pop [address]
MouseLP:
	mov ax,3h
	int 33h
	cmp bx, 01h ; check left mouse click
	jne MouseLP
	shr cx,1 ; adjust cx to range 0-319, to fit screen
	mov [X], cx ;set X
	mov [Y], dx ;set Y
	push [address]
	ret
	endp MouseInt
	
;image/picture of calculator procedures	
proc OpenFile
; Open file
mov ah, 3Dh
xor al, al
mov dx, offset filename
int 21h
jc openerror
mov [filehandle], ax
ret
openerror:
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
ret
endp OpenFile
proc ReadHeader
; Read BMP file header, 54 bytes
mov ah,3fh
mov bx, [filehandle]
mov cx,54
mov dx,offset Header
int 21h
ret
endp ReadHeader
proc ReadPalette
; Read BMP file color palette, 256 colors * 4 bytes (400h)
mov ah,3fh
mov cx,400h
mov dx,offset Palette
int 21h
ret
endp ReadPalette
proc CopyPal
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
mov si,offset Palette
mov cx,256
mov dx,3C8h
mov al,0
; Copy starting color to port 3C8h
out dx,al
; Copy palette itself to port 3C9h
inc dx
PalLoop:
; Note: Colors in a BMP file are saved as BGR values rather than RGB.
mov al,[si+2] ; Get red value.
shr al,2 ; Max. is 255, but video palette maximal
; value is 63. Therefore dividing by 4.
out dx,al ; Send it.
mov al,[si+1] ; Get green value.
shr al,2
out dx,al ; Send it.
mov al,[si] ; Get blue value.
shr al,2
out dx,al ; Send it.
add si,4 ; Point to next color.
; (There is a null chr. after every color.)
loop PalLoop
ret
endp CopyPal
proc CopyBitmap
; BMP graphics are saved upside-down.
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
mov ax, 0A000h
mov es, ax
mov cx,200
PrintBMPLoop:
push cx
; di = cx*320, point to the correct screen line
mov di,cx
shl cx,6
shl di,8
add di,cx
; Read one line
mov ah,3fh
mov cx,320
mov dx,offset ScrLine
int 21h
; Copy one line into video memory
cld ; Clear direction flag, for movsb
mov cx,320
mov si,offset ScrLine
rep movsb ; Copy line to the screen
 ;rep movsb is same as the following code:
 ;mov es:di, ds:si
 ;inc si
 ;inc di
 ;dec cx
 ;loop until cx=0
pop cx
loop PrintBMPLoop
ret
endp CopyBitmap
start:
mov ax, @data
mov ds, ax
;Showing the instructions
	call PrintInstructions
	mov AH, 01h  ; wait for any key to be pressed 
	int 21h 	
	mov al, 13h ;graphic mode
	mov ah, 0
	int 10h
; Process BMP of the opening project picture
call OpenFile
call ReadHeader
call ReadPalette
call CopyPal
call CopyBitmap
	mov AH, 01h  ; wait for any key to be pressed 
	int 21h 
	StartCalc:	
	call ResetVars ;reset/sets the variable to their starting value
	mov al, 13h ;graphic mode
	mov ah, 0
	int 10h
	;Initializes the mouse
	mov ax,0h
	int 33h
	
	; Show mouse
	mov ax,1h
	int 33h

	mov  ax,0002h ; hide mouse cursor
	int  33h
	
; Process BMP file
mov [filename], 'c' ;picture of the calculator
call OpenFile
call ReadHeader
call ReadPalette
call CopyPal
call CopyBitmap
	mov  ax,0001h ; show mouse cursor
	int  33h
	call GetNum1   ;get number 1
	call PrintNum1 ;print number 1
	jmp Mouse ;go to get Mouse Interrupt
StartCalc1: ;out of bytes
jmp StartCalc
Mouse:	
xor ax, ax ;reseting registers 
xor dx, dx
xor bx, bx
xor cx, cx
; Loop until mouse click
	call MouseInt ;waiting for a mouse click then settings X and Y 
;Settings max and minumun for the click, else go back until valid mouse click
	cmp [Y], 39h ;minimum Y 
	JB Mouse
	cmp [Y], 0BFh ;max Y
	JA Mouse
;checking if the mouse click was on "OFF"
	cmp [Y], 0A3h
	JB AC
	cmp [X], 0A1h
	JB AC
	cmp [X], 0CDh
	JA AC
	JB OFF2
AC:		
;checking if the mouse click was on "AC"/"C" (delete) or " = ", else goes to "Math:" to check if it was clicked on a math act		
	cmp [X], 0D6h
	JB Math
	cmp [X], 0FFh
	JA Math
	cmp [Y], 84h
	JB StartCalc1
	JA Equal1	
Math:	
	cmp [X], 8h ;checking if the left click mouse was on in a valid place (elementary arithmetic)
	JB Mouse	
	cmp [X],33h
	JA Mouse
	
	cmp [Y], 66h ;checking the place of the click 
	JB divide
	cmp [Y], 84h
	JB multiply
	cmp [Y], 0A2h
	JB minus ;substract
	JA plusV2 ;add
	
OFF2: ;out of bytes
JMP OFF1	
divide:
	call PDiv ;prints "/" on screen	
	call GetNum2 ;getting num2
	call DivNums ;calculating num1 / num2
	cmp [num2], 0h ;compares to see if the second num is 0, if so it has no meaning (error)
	JNE enddV2
	lea DX,[cantDivide] 
	mov AH,09h
	int 21h	
	jmp BackToTheStart1
multiply:
	call PMult ;prints "*" on screen
	call GetNum2 ;getting num2
	call MultNums ;calculating num1 * num2
jmp endd
Equal1: ;relative jump out of range
jmp Equal
OFF1: ;relative jump out of range
jmp OFF
plusV2: ;out of range
jmp plus
enddV2: ;out of range
jmp endd
minus:	
	call PMinus ;prints "-" on screen	
	call GetNum2 ;get num2
	call MinusNums ;calculating num1 - num2
	jmp endd
BackToTheStart1:
JMP BackToTheStart
plus:
	call PPlus ;prints "+" on screen	
	call GetNum2 ;get num2
	call PlusNums ;calculating num1 + num2
	jmp endd
StartCalc2:
jmp StartCalc1	
;OFF button was pressed
OFF:	
mov al, 3h
mov ah, 0h
int 10h
jmp exit
;if the "=" button was pressed before entering the second number
Equal:
mov ax, [num1]
mov [answer], ax ;moving to the answer the number (num1)
mov al, [negNum1]
mov [printMinus], al ;mov negNum1 to printMinus to see if it will need to print Minus
jmp PrintAnswer	 ;go to print the number

endd:
call PrintNum2
;waiting for a mouse click
MouseV2:	
xor ax, ax
xor dx, dx
xor bx, bx
; Loop until mouse click
call MouseInt
;Settings max and minumun for the click, else go back until valid mouse click
	cmp [Y], 39h ;minimum Y 
	JB MouseV2
	cmp [Y], 0BFh ;max Y
	JA MouseV2
;checking if the mouse click was on "OFF"
	cmp [Y], 0A3h
	JB ACV2
	cmp [X], 0A1h
	JB ACV2
	cmp [X], 0CDh
	JA ACV2
	JB OFF
ACV2:		
;checking if the mouse click was on "AC"/"C" (delete) or " = ", else goes to "Math:" to check if it was clicked on a math act		
	cmp [X], 0D6h
	JB MouseV2
	cmp [X], 0FFh
	JA MouseV2
	cmp [Y], 84h
	JB StartCalc2 ;click was on AC/C
	JMP PrintAnswer ;click was on "="	
OFF3: ;out of bytes
jmp OFF	
PrintAnswer:
	cmp [TooBig], 1h ;see if the answer is bigger or lower than the max
	JE	AnswerTooBig
	call PlusOrMinus; prints Plus if the answer is positive, prints minus if the number is negative	
	call ResetRES ;reset RES array
    MOV AX,[answer]     
    LEA SI,[RES]
    CALL HEX2DEC ;prints the decimal value of the answer(the answer is in hexa)
   
    LEA DX,[RES]
    MOV AH,9
    INT 21H 
	
	cmp [module], 0	
	JE BackToTheStart ;there is no module
;there is module (the act was divide)
	LEA DX,[msgModule]
    MOV AH,9
    INT 21H 
	call PlusOrMinusModule; prints Plus if the answer is positive, prints minus if the number is negative
	call ResetRES ;reset RES array
    MOV AX,[module]     
    LEA SI,[RES]
    CALL HEX2DEC
    LEA DX,[RES]
    MOV AH,9
    INT 21H 
	JMP BackToTheStart
AnswerTooBig:
	LEA DX,[msg13]
    MOV AH,9
    INT 21H 
BackToTheStart:	
	lea DX,[msg14] ;Show msg12
	mov AH,09h
	int 21h	
	mov ah, 0 ;get input from keyboard(if input is Escape), turn off the calc. any other key - continue
	int 16h
	cmp ah, 1
	JE OFF3
	jmp StartCalc2

exit:
mov ax, 4c00h
int 21h
END start