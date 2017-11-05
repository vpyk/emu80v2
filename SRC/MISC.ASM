;
;  Emu80 v. 2.86
;  (c) Viktor Pykhonin <pyk@mail.ru>, 1997-2000
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;

;File: MISC.ASM

; Содержит разнообразные служебные процедуры

INCLUDE EMU80.INC

.model tiny

public get_key
public test_key
public prep_key
public sysreq
public sysreq_code
public flash_key

public inittimer
public getcount

public init_sound

public setscr25
public setscr30
public setscr40
public setscr43
public setw8
public test_vga
public test_ega
public test_nt
public test_win
public load_8x16
public load_8x16rk
public load_8x8
public load_8x8rk
public load_8x12
public load_8x12rk
public set_vga400
public set_vga350

public find_path
public com_path
public com_path_len

public test_sys_key
public test_sys_key_scan
public alt_flag
public translate_sysreq_code

extrn fonts_mem:dword

.code

jumps

;### Процедуры для работы с клавиатурой ###

; Эти процедуры всегда работают с последним символом,
; игнорируя очередь (точнее, эмулируется буфер из одного симфола)

; Буфер из одного символа
key dw 0

; Флаг - устанавливается при нажатии F10
sysreq db 0

; Код системной клавиши
sysreq_code dw ?

; Признак нажатия Alt (режим чт/зап)
alt_flag db ?

tst proc
        mov ah,11h
        int 16h
        ret
tst endp

; Подготовка символа и анализ F10
prep_key proc
;        call tst
;        jnz pk2
;        mov es:[key],0
;        jmp pk1
pk3:    call tst
        jz pk1
pk2:    mov ah,10h;xor ah,ah
        int 16h
        call test_sys_key;cmp ah,4400h
        jne pk4
        mov byte ptr es:[sysreq],1
;        jmp pk3
pk4:    mov es:[key],ax
        jmp pk3
pk1:    ret
prep_key endp

; Чтение символа
get_key proc
        call prep_key
        mov ax,es:[key]
        mov es:[key],0
        test ax,ax
        jnz gk1
        mov ah,10h
        int 16h
gk1:    ret
get_key endp

; Проверка нажатия (наличия в буфере)
test_key proc
        push ax
        call prep_key
        mov ax,es:[key]
        test ax,ax
        pop ax
        ret
test_key endp

; Очистка буфера
flash_key proc
        mov es:[key],0
        ret
flash_key endp

;Z=1, если в AX - код системной клавиши и запоминает ее код в sysreq_code
test_sys_key proc
        cmp ah,44h ; F10
        je tsk1
;        cmp ah,58h ; F12
;        je tsk1
        cmp ah,71h ; Alt-F10
        je tsk1
        cmp ah,70h ; Alt-F9
        je tsk1
        cmp ah,6Fh ; Alt-F8
        je tsk1
        cmp ah,8Bh ; Alt-F11
        je tsk1
        cmp ah,69h ; Alt-F2
        je tsk1
        cmp ah,6Ah ; Alt-F3
        je tsk1
        cmp ah,6Ch ; Alt-F5
        je tsk1
        cmp ah,6Dh ; Alt-F6
        je tsk1
        cmp ah,68h ; Alt-F1
        je tsk1
        cmp ah,43h ; F9
        je tsk1
        ret
tsk1:   mov word ptr cs:[sysreq_code],ax
        ret
test_sys_key endp

;Z=1, если в AX - скан-код системной клавиши и запоминает ее код в sysreq_code
test_sys_key_scan proc
        cmp ah,44h   ; F10
        je tsks1
        cmp ah,58h   ; F12
        je tsks1
        cmp ah,43h   ; F9
        je tsks1
        cmp byte ptr cs:[alt_flag],1
        jne tsks1
        cmp ah,57h ; Alt-F11
        je tsks1
        cmp ah,3bh ; Alt-F1
        je tsks1
        cmp ah,3ch ; Alt-F2
        je tsks1
        cmp ah,3dh ; Alt-F3
        je tsks1
        cmp ah,3fh ; Alt-F5
        je tsks1
        cmp ah,40h ; Alt-F6
        je tsks1
        cmp ah,42h ; Alt-F8
        je tsks1
        cmp ah,49h ; Alt-PgUp
        je tsks1
        cmp ah,51h ; Alt-PgDn
        je tsks1
        ret
tsks1:  mov word ptr cs:[sysreq_code],ax
        mov al, byte ptr cs:[alt_flag]
        mov byte ptr cs:[alt_flag_mem],al
        ret
test_sys_key_scan endp

alt_flag_mem db 0

; Преобразовывает код системной клавиши в код действия
translate_sysreq_code proc
        push bx
        lea bx, [sysreq_code+1]
        cmp byte ptr cs:[bx],44h
        jne tsc0
        mov byte ptr cs:[bx],SYSREQ_MENU
        cmp byte ptr cs:[alt_flag_mem],1
        jne tscQ
tsc01:  mov byte ptr cs:[bx],SYSREQ_QUIT
        jmp tscQ
tsc0:   cmp byte ptr cs:[bx],71h
        je tsc01
tsc1:   cmp byte ptr cs:[bx],57h
        jne tsc2
tsc3:   mov byte ptr cs:[bx],SYSREQ_RESET
        jmp tscQ
tsc2:   cmp byte ptr cs:[bx],8Bh
        je tsc3

        cmp byte ptr cs:[bx],42h
        jne tsc18
tsc19:  mov byte ptr cs:[bx],SYSREQ_ROM
        jmp tscQ
tsc18:  cmp byte ptr cs:[bx],6fh
        je tsc19

tsc16:  cmp byte ptr cs:[bx],49h
        jne tsc17
        mov byte ptr cs:[bx],SYSREQ_SPEEDUP
        jmp tscQ

tsc17:  cmp byte ptr cs:[bx],51h
        jne tsc44
        mov byte ptr cs:[bx],SYSREQ_SPEEDDOWN
        jmp tscQ

tsc44:  cmp byte ptr cs:[bx],58h
        jne tsc4
        mov byte ptr cs:[bx],SYSREQ_PAUSE
        jmp tscQ

tsc4:   cmp byte ptr cs:[bx],43h
        jne tsc5
        mov byte ptr cs:[bx],SYSREQ_MODEL
        cmp byte ptr cs:[alt_flag_mem],1
        jne tscQ
tsc02:  mov byte ptr cs:[bx],SYSREQ_MODELNOCLEAR
        jmp tscQ
tsc5:   cmp byte ptr cs:[bx],70h
        je tsc02

        cmp byte ptr cs:[bx],3ch
        jne tsc6
tsc7:   mov byte ptr cs:[bx],SYSREQ_SAVESS
        jmp tscQ
tsc6:   cmp byte ptr cs:[bx],69h
        je tsc7

        cmp byte ptr cs:[bx],3dh
        jne tsc8
tsc9:   mov byte ptr cs:[bx],SYSREQ_LOADSS
        jmp tscQ
tsc8:   cmp byte ptr cs:[bx],6Ah
        je tsc9

        cmp byte ptr cs:[bx],3fh
        jne tsc12
tsc13:  mov byte ptr cs:[bx],SYSREQ_DISKA
        jmp tscQ
tsc12:  cmp byte ptr cs:[bx],6Ch
        je tsc13

        cmp byte ptr cs:[bx],40h
        jne tsc14
tsc15:  mov byte ptr cs:[bx],SYSREQ_DISKB
        jmp tscQ
tsc14:  cmp byte ptr cs:[bx],6Dh
        je tsc15

        cmp byte ptr cs:[bx],3bh
        jne tsc10
tsc11:  mov byte ptr cs:[bx],SYSREQ_HELP
        jmp tscQ
tsc10:  jmp tsc11
tscQ:   ;mov byte ptr cs:[alt_flag],0
        pop bx
        ret
translate_sysreq_code endp

;### Процедуры для работы с таймером ###

; Инициализация таймера
inittimer proc
        mov al,36h;34h
        out 43h,al
        xor al,al
        out 40h,al
        out 40h,al
        ret
inittimer endp

; Получение текущего значения счетчика в AX
getcount proc
        push cx
        mov al,06h
        out 43h,al
        in al,40h
        mov cl,al
        in al,40h
        mov ah,al
        mov al,cl
        pop cx
        ret
getcount endp

;### Процедуры для работы с экраном ###

;Устанавливает режим 80x30
setscr30 proc
        push ax
        push dx
        mov ax,3;83h
        int 10h
;   mov ax, 1201h
;   mov bl, 30h
;   int 10h
        cli
        mov dx,3d4h
        mov al,11h
        out dx,al
        inc dx
        in al,dx
        and al,7fh
        out dx,al
        dec dx
        mov al,06h
        out dx,al
        mov al,0bh     ; Общее число линий гор. разв. мл. 8 бит
        inc dx
        out dx,al
        dec dx
        mov al,07h     
        out dx,al
        mov al,3eh     ; 8-е и 9-е биты регистров
        inc dx
        out dx,al
        dec dx
        mov al,10h
        out dx,al
        mov al,0eah    ; Начало обр. верт. хода луча мл. 8 бит
        inc dx
        out dx,al
        dec dx
        mov al,12h
        out dx,al
        mov al,0dfh    ; Завершение отображения верт. развертки. мл. 8 бит
        inc dx
        out dx,al
        dec dx
        mov al,15h     
        out dx,al
        mov al,0e7h    ; Начало импульса гашения верт. развертки. мл. 8 бит
        inc dx  
        out dx,al
        dec dx
        mov al,16h
        out dx,al
        mov al,04h     ; Конец импульса гашения верт. развертки. мл. 8 бит
        inc dx
        out dx,al
        dec dx
        sti
        mov ax,40h
        push es
        mov es,ax
        mov byte ptr es:[0084h],1dh ; установка переменной BIOS числа строк
;       mov byte ptr es:[0049h],07fh
        pop es
;   push es
;   cli
;   mov dx, 3C4h
;   mov al, 0
;   out dx, al     
;   mov al, 1
;   inc dx
;   out dx, al     
;   dec dx
;   mov dx, 3D4h
;   mov al, 17h
;   out dx, al     
;   inc dx
;   in al, dx      
;   and al, 7Fh
;   out dx, al     
;   dec dx
;   mov al, 11h
;   out dx, al     
;   inc dx
;   in al, dx      
;   and al, 7Fh
;   out dx, al     
;   mov dx, 3CCh
;   in al, dx      
;   or al, 0C0h
;   mov dx, 3C2h
;   out dx, al     
;   mov dx, 3D4h
;   mov al, 6
;   out dx, al     
;   mov al, 0Bh
;   inc dx
;   out dx, al     
;   dec dx
;   mov al, 7
;   out dx, al  
;   mov al, 3Eh 
;   inc dx
;   out dx, al  
;   dec dx
;   mov al, 9
;   out dx, al  
;   mov al, 4Fh 
;   inc dx
;   out dx, al     
;   dec dx
;   mov al, 10h
;   out dx, al     
;   mov al, 0EAh 
;   inc dx
;   out dx, al     
;   dec dx
;   mov al, 11h
;   out dx, al     
;   mov al, 8Ch  
;   inc dx
;   out dx, al     
;   dec dx
;   mov al, 12h
;   out dx, al     
;   mov al, 0DFh 
;   inc dx
;   out dx, al     
;   dec dx
;   mov al, 15h
;   out dx, al     
;   mov al, 0E7h 
;   inc dx
;   out dx, al     
;   dec dx
;   mov al, 16h
;   out dx, al     
;   mov al, 4
;   inc dx
;   out dx, al     
;   dec dx
;   mov al, 11h
;   out dx, al     
;   inc dx
;   in al, dx      
;   or al, 80h
;   out dx, al     
;   dec dx
;   mov al, 17h
;   out dx, al     
;   inc dx
;   in al, dx      
;   or al, 80h
;   out dx, al     
;   mov dx, 3C4h
;   mov al, 0
;   out dx, al     
;   mov al, 3
;   inc dx
;   out dx, al     
;   dec dx
;   sti
;   mov ax, 40h
;   mov es, ax
;   mov byte ptr es:84h, 1Dh
;   pop es
        pop dx
        pop ax
        ret
setscr30 endp

; Устанавливает режим 80x25 (без очистки экрана)
setscr25 proc
        mov ax,3;83h
        int 10h
        ret
setscr25 endp

; Устанавливает режим 80x43
setscr43 proc
        push bx
        mov ax,3;83h
        int 10h
        mov ax,1112h
        xor bl,bl
        int 10h
        pop bx
        ret
setscr43 endp

;Z=1, если присутствует VGA
test_vga proc
        mov ax,1a00h
        int 10h
        cmp al,1ah
;       cmp al,1h
        ret
test_vga endp

;Z=0, если присутствует EGA
test_ega proc
        mov ax,1200h
        mov bx,0010h
        int 10h
        cmp bl,10h
;       cmp bl,3h
        ret
test_ega endp

;Устанавливает режим 400 строк для VGA
set_vga400 proc
        push bx
        mov ax,1202h
        mov bl,30h
        int 10h
        pop bx
        ret
set_vga400 endp

;Устанавливает режим 350 строк для VGA
set_vga350 proc
        push bx
        mov ax,1201h
        mov bl,30h
        int 10h
        pop bx
        ret
set_vga350 endp

;Загружает стандартный шрифт 8x16
load_8x16 proc
        push bx
        mov ax,1104h
        xor bl,bl
        int 10h
;       mov ax,1103h
;       xor bl,bl
;       int 10h
        pop bx
        ret
load_8x16 endp

;Загружает стандартный шрифт 8x8
load_8x8 proc
        push bx
        mov ax,1102h
        xor bl,bl
        int 10h
;       mov ax,1103h
;       xor bl,bl
;       int 10h
        pop bx
        ret
load_8x8 endp

; Загружает шрифт 8x16 знакогенератора РК-86
; в символы 00-5F, D0-DF, F0-FF
load_8x16rk proc
        push bx
        push cx
        push dx
        push es

        mov bx,word ptr cs:[fonts_mem]+2
        mov es,bx

        mov ax,1100h
        mov bx,1000h
        mov cx,60h
        xor dx,dx
        mov bp,0
        int 10h
        mov ax,1100h
        mov bx,1000h
        mov cx,10h
        mov dx,0d0h
        mov bp,600h
        int 10h
        mov ax,1100h
        mov bx,1000h
        mov cx,10h
        mov dx,0f0h
        mov bp,700h
        int 10h
        pop es
        pop dx
        pop cx
        pop bx
        ret
load_8x16rk endp

; Загружает шрифт 8x8 знакогенератора РК-86
; в символы 00-5F, D0-DF, F0-FF
load_8x8rk proc
        push bx
        push cx
        push dx
        push es

        mov bx,word ptr cs:[fonts_mem]+2
        add bx,80h
        mov es,bx

        mov ax,1100h
        mov bx,0800h
        mov cx,60h
        xor dx,dx
        mov bp,0
        int 10h
        mov ax,1100h
        mov bx,0800h
        mov cx,10h
        mov dx,0d0h
        mov bp,300h
        int 10h
        mov ax,1100h
        mov bx,0800h
        mov cx,10h
        mov dx,0f0h
        mov bp,380h
        int 10h
        pop es
        pop dx
        pop cx
        pop bx
        ret
load_8x8rk endp

; Устанавливает для VGA режим ширины символов 8 (по умолчанию 9)
setw8 proc
        push dx
        mov dx,03C4h
        mov al,01h
        out dx,al
        inc dx
        in al,dx
        dec dx
        test al,01h
        jne fin
        cli
        mov ax,0100h
        out dx,ax
        inc ax
        out dx,al
        inc dx
        in al,dx
        dec dx
        or al,01h
        mov ah,al
        mov al,01h
        out dx,ax
        mov dl,0CCh
        in al,dx
        and al,0F3h
        mov dl,0C2h
        out dx,al
        mov dl,0DAh
        in al,dx
        mov dl,0C0h
        mov al,13h
        out dx,al
        mov al,00h
        out dx,al
        mov dl,0DAh
        in al,dx
        mov dl,0C0h
        mov al,20h
        out dx,al
        mov dl,0C4h
        mov ax,0300h
        out dx,ax
        sti
fin:    pop dx
        ret
setw8 endp

setscr40 proc
        push ax
        push dx
        mov ax,3;83h
        int 10h
;   mov ax, 1201h
;   mov bl, 30h
;   int 10h
        cli
        mov dx,3d4h
        mov al,11h
        out dx,al
        inc dx
        in al,dx
        and al,7fh
        out dx,al
        dec dx
        mov al,06h
        out dx,al
        mov al,0bh     ; Общее число линий гор. разв. мл. 8 бит
        inc dx
        out dx,al
        dec dx
        mov al,07h     
        out dx,al
        mov al,3eh     ; 8-е и 9-е биты регистров
        inc dx
        out dx,al
        dec dx
        mov al,10h
        out dx,al
        mov al,0eah    ; Начало обр. верт. хода луча мл. 8 бит
        inc dx
        out dx,al
        dec dx
        mov al,12h
        out dx,al
        mov al,0dfh    ; Завершение отображения верт. развертки. мл. 8 бит
        inc dx
        out dx,al
        dec dx
        mov al,15h     
        out dx,al
        mov al,0e7h    ; Начало импульса гашения верт. развертки. мл. 8 бит
        inc dx  
        out dx,al
        dec dx
        mov al,16h
        out dx,al
        mov al,04h     ; Конец импульса гашения верт. развертки. мл. 8 бит
        inc dx
        out dx,al

        dec dx
        mov al,09h
        out dx,al
        mov al,0bh     ; Высота символа
        inc dx
        out dx,al

        sti

        push es

        mov ax,40h
        mov es,ax
        mov byte ptr es:[0084h],27h ; установка переменной BIOS числа строк
        mov word ptr es:[0085h],12 ; установка переменной BIOS высоты символа

        mov ah,1         ; Курсор - форма
        mov cx,0607h
        int 10h

        pop es

        call load_8x12

        pop dx
        pop ax
        ret
setscr40 endp

open_symbols proc
        cli
        mov dx,3c4h
        mov ax,0100h
        out dx,ax
        mov ax,0402h
        out dx,ax
        mov ax,0704h
        out dx,ax
        mov ax,0300h
        out dx,ax
        sti
        mov dx,3ceh
        mov ax,0204h
        out dx,ax
        mov ax,0005h
        out dx,ax
        mov ax,0006h
        out dx,ax
        ret
open_symbols endp

close_symbols proc
        cli
        mov dx,3c4h
        mov ax,0100h
        out dx,ax
        mov ax,0302h
        out dx,ax
        mov ax,0304h
        out dx,ax
        mov ax,0300h
        out dx,ax
        sti
        mov dx,3ceh
        mov ax,0004h
        out dx,ax
        mov ax,1005h
        out dx,ax
        mov ax,0e06h
        out dx,ax
        ret
close_symbols endp

; Загружает шрифт 8x12 знакогенератора cp866
load_8x12 proc
        push ds es
        call open_symbols
        mov ax,0a000h
        mov es,ax
        push cx si di

        mov si,word ptr cs:[fonts_mem]+2
        add si,120h
        mov ds,si

        xor si,si
        xor di,di
        xor dl,dl

        call ldf

        pop di si cx
        call close_symbols
        pop es ds
        ret
load_8x12 endp

; Загружает шрифт 8x12 знакогенератора РК-86
; в символы 00-5F, D0-DF, F0-FF
load_8x12rk proc
        push ds es
        call open_symbols
        mov ax,0a000h
        mov es,ax
        push cx si di

        mov si,word ptr cs:[fonts_mem]+2
        add si,0c0h
        mov ds,si

        xor si,si
        xor di,di
        mov dl,60h
        call ldf

        mov si,60h*12
        mov di,0d0h*32
        mov dl,10h
        call ldf

        mov si,70h*12
        mov di,0f0h*32
        mov dl,10h
        call ldf

        pop di si cx
        call close_symbols
        pop es ds
        ret
load_8x12rk endp

ldf:
l1:     mov cx,12
        cld
        rep movsb
        add di,20
        dec dl
        jnz l1
        ret

;### Процедуры для работы со звуком ###

init_sound proc
        push ax
        push dx
        mov dx,1491
        in al,61h
        and al,0fch
        out 61h,al
        mov al,0b6h
        out 43h,al
        mov al,dl
        out 42h,al
        mov al,dh
        out 42h,al
        pop dx
        pop ax
        ret
init_sound endp

;### Прочие процедуры ###

; Z=0, если работает Windows в расширенном режиме
test_win proc
        mov ax,1600h
        int 2fh
        cmp al,0h
        jz tw1
        cmp al,80h
tw1:    ret
test_win endp

; AL=1, если запущена под Windows NT и 0 в противном случае
test_nt proc
        push es
        push ds
        push cs
        pop es
        push si
        mov si,word ptr cs:[2ch]
        mov ds,si
        xor si,si
tnt1:   cmp byte ptr ds:[si],0
        jz tnt2
        push si
        lea di,nt_var
        mov cx,14
        rep cmpsb
        je tnt3
        pop si
tnt4:   lodsb
        test al,al
        jnz tnt4
        jmp tnt1
tnt3:   pop si
        mov al,1
        jmp tnt5
tnt2:   xor al,al
tnt5:   pop si
        pop ds
        pop es
        ret
nt_var db 'OS=Windows_NT',0
test_nt endp

; заносит путь к com-файлу в сторку com_path
find_path proc
        push es
        push ds
        push cs
        pop es
        push si
        mov si,cs
        mov ds,si
        mov si,word ptr cs:[2ch]
        mov ds,si
        xor si,si
fp1:    cmp byte ptr ds:[si],0
        jz fp2
fp4:    lodsb
        test al,al
        jnz fp4
        jmp fp1
fp2:    inc si
        cmp word ptr ds:[si],1
        jne fp5
        inc si
        inc si
        mov di,offset com_path
fp6:    lodsb 
        test al,al
        je fp7
        stosb
        inc word ptr es:[com_path_len]
        jmp fp6
fp7:    dec si
        dec word ptr es:[com_path_len]
        cmp byte ptr ds:[si],'\'
        jne fp7
        inc word ptr es:[com_path_len]
        inc word ptr es:[com_path_len]
fp5:    pop si
        pop ds
        pop es
        ret
com_path db 128 dup (0)
com_path_len dw 0
find_path endp

end
