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

.model tiny

INCLUDE EMU80.INC

extrn sysreq:byte
extrn port_c:byte
extrn cModel:byte
extrn test_sys_key_scan:near
extrn alt_flag:byte

public get_09_vect
public set_new_09_vect
public restore_09_vect
public key_bytes
public ctrl_keys
public joy_state
public key_bytes_s
public ctrl_keys_s
public led_state
;public light_led
public corr_key_tbl
public f_led

.code

old_09 dd ?

f_led db 1

ext_flag db 0

get_09_vect proc
        push es
        push bx
        mov ax,3509h
        int 21h
        mov word ptr cs:[old_09],bx
        mov word ptr cs:[old_09+2],es
        pop bx
        pop es
        ret
get_09_vect endp

set_new_09_vect proc
        push ax
        push dx
        mov ax,2509h
        push ds
        push cs
        pop ds
        lea dx,int_09
        int 21h
        call light_led
        mov byte ptr cs:[alt_flag],0

        mov word ptr cs:[key_bytes],0ffffh
        mov word ptr cs:[key_bytes+2],0ffffh
        mov word ptr cs:[key_bytes+4],0ffffh
        mov word ptr cs:[key_bytes+6],0ffffh
        mov word ptr cs:[key_bytes_s],0fffh
        mov word ptr cs:[key_bytes_s+2],0fffh
        mov word ptr cs:[key_bytes_s+4],0fffh
        mov word ptr cs:[key_bytes_s+6],0fffh
        mov word ptr cs:[key_bytes_s+8],0fffh
        mov word ptr cs:[key_bytes_s+10],0fffh
        mov byte ptr cs:[ctrl_keys],0ffh
        or byte ptr cs:[ctrl_keys_s],02h ; ##### ?????
  mov byte ptr cs:[ctrl_keys_s],02h ; ####
        mov byte ptr cs:[joy_state],0ffh

        pop ds
        pop dx
        pop ax
        ret
set_new_09_vect endp

restore_09_vect proc
        push ax
        push dx
        mov ax,2509h
        push ds
        lds dx,dword ptr cs:[old_09]
        int 21h
        call restore_led
        pop ds
        pop dx
        pop ax
        ret
restore_09_vect endp

int_09 proc
        push es
        push ax
;i9_1:in al,61h
;test al,80h
;jnz i9_1
        in al,60h

        push ax
        cli
        in al,61h
        or al,80h
        out 61h,al
        and al,7fh
        out 61h,al
        mov al,20h
        out 20h,al
        sti
        pop ax

        cmp al,38h
        jne i4
        mov byte ptr cs:[alt_flag],1
        jmp i5
i4:     cmp al,0b8h
        jne i5
        mov byte ptr cs:[alt_flag],0
i5:     cmp al,0e0h
        jne i6
        mov byte ptr cs:[ext_flag],1
        jmp i7
i6:     push ax
        mov ah,al
        call test_sys_key_scan
        pop ax
;    cmp al,44h
        jne i3
        mov byte ptr cs:[sysreq],1
        jmp i1
i3:     cmp al,46h; ScrollLock
        jne i2
        xor byte ptr cs:[keyb_type],1
        xor byte ptr cs:[led_state],1
        call light_led
        jmp i1
i2:     mov ah,al
        and al,7fh
        cmp al,53h
        ja i1
        call anal_key
i1:
        mov byte ptr cs:[ext_flag],0
i7:
;call light_led
        pop ax
        pop es
;jmp dword ptr cs:[old_09]
        iret
int_09 endp

; Зажигает светодиоды клавиатуры в соответствии с байтом состояния
light_led proc
        cmp byte ptr cs:[f_led],0
        jz ll3
        push ax
ll1:    in al,64h
        test al,2
        jnz ll1
        mov al,0edh
        out 60h,al
        cmp byte ptr cs:[cModel],MODEL_S
        je ll4
        mov al,byte ptr cs:[port_c]
        and al,08h
        ror al,1
        or byte ptr cs:[led_state],al
ll4:    mov al, byte ptr cs:[led_state]
        push ax
ll2:    in al,64h
        test al,2
        jnz ll2
        pop ax
        out 60h,al
        pop ax
ll3:    ret
light_led endp

; Зажигает светодиоды клавиатуры в соответствии с BIOS
restore_led proc
        cmp byte ptr cs:[f_led],0
        jz rl3
        push ax
rl1:    in al,64h
        test al,2
        jnz ll1
        mov al,0edh
        out 60h,al
        push es
        mov ax,40h
        mov es,ax
        mov al,byte ptr [es:17h]
        pop es
        pushf
        ror al,1
        ror al,1
        ror al,1
        ror al,1
        and al,07h
        push ax
rl2:    in al,64h
        test al,2
        jnz rl2
        pop ax
        popf
        out 60h,al
        pop ax
rl3:    ret
restore_led endp

; Анализирует скан-код в AL (AH<0, если отжатие)
anal_key proc
; mov byte ptr cs:[key_bytes],al
; ret
        push bx
        push si
        cmp byte ptr cs:[cModel],MODEL_S
        je ak_s

       call corr_key_tbl
        cmp byte ptr cs:[cModel],MODEL_R
        jne ak5
        cmp byte ptr cs:[ext_flag],0
        jnz ak5
        cmp al,45h
        jb ak5
        cmp al,53h
        ja ak5
        sub al,45h
        mov si, offset key_tbl_n
        mov word ptr cs:[key_tbl_r],si
        mov word ptr cs:[key_tbl_l],si
ak5:
        xor bh,bh
        mov bl,al
        add bx,bx
        cmp byte ptr cs:[keyb_type],0
        jz ak3
        mov si, word ptr cs:[key_tbl_r]
        mov al, byte ptr cs:[bx+si+1] ; маска
        mov bl, byte ptr cs:[bx+si]   ; номер байта
        jmp ak4
ak3:    mov si, word ptr cs:[key_tbl_l]
        mov al, byte ptr cs:[bx+si+1] ; маска
        mov bl, byte ptr cs:[bx+si]   ; номер байта
ak4:    xor bh,bh
        test ah,ah
        jns ak1
        or byte ptr cs:[bx+offset key_bytes],al
        jmp ak2
ak1:    not al
        and byte ptr cs:[bx+offset key_bytes],al
ak2:    pop si
        pop bx
        ret
ak_s:
        mov si, offset key_tbl_r_s
        mov word ptr cs:[key_tbl_r],si
        mov si, offset key_tbl_l_s
        mov word ptr cs:[key_tbl_l],si

        cmp byte ptr cs:[ext_flag],0
        jnz ak5_s
; jmp ak5_s
        cmp al,45h
        jb ak5_s
        cmp al,52h
        ja ak5_s
        sub al,45h
        mov si, offset key_tbl_n_s
        mov word ptr cs:[key_tbl_r],si
        mov word ptr cs:[key_tbl_l],si
ak5_s:
        push cx
        xor bh,bh
        mov bl,al
        add al,al
        push ax
        xor ah,ah
        add bx,ax
        pop ax
        cmp byte ptr cs:[keyb_type],0
        jz ak3_s
        mov si, word ptr cs:[key_tbl_r]
ak6_s:  mov cx, word ptr cs:[bx+si+1] ; маска
        mov bl, byte ptr cs:[bx+si]   ; номер байта
        jmp ak4_s
ak3_s:  mov si, word ptr cs:[key_tbl_l]
        mov cx, word ptr cs:[bx+si+1] ; маска
        mov bl, byte ptr cs:[bx+si]   ; номер байта
ak4_s:  xor bh,bh
        add bx,bx
        test ah,ah
        jns ak1_s
        or word ptr cs:[bx+offset key_bytes_s],cx
        jmp ak2_s
ak1_s:  not cx
        and word ptr cs:[bx+offset key_bytes_s],cx
ak2_s:  pop cx
        pop si
        pop bx
        ret
anal_key endp

key_bytes db 8 dup (0ffh)
ctrl_keys db 0f0h
joy_state db 0ffh

key_bytes_s dw 6 dup (0fffh)
ctrl_keys_s dw 02h

keyb_type db 0 ; 0-lat, 1-rus прекл. по ScrollLock

led_state db 0 ; Состояние светодиодов клавиатуры

key_tbl_l dw ? ;key_tbl_l_m or key_tbl_l_arp

key_tbl_l_m:
db 0,0
db 1,1; 01-ESC
db 1,4; 02-1
db 2,4; 03-2
db 3,4; 04-3
db 4,4; 05-4
db 5,4; 06-5
db 6,4; 07-6
db 7,4; 08-7
db 0,8; 09-8
db 1,8; 0a-9
db 0,4; 0b-0
db 5,8; 0c--
db 3,8; 0d
db 7,128; 0e-BSP
db 2,1; 0f-TAB

db 1,64; Q
db 7,64; W
db 5,16; E
db 2,64; R
db 4,64; T
db 1,128; Y
db 5,64; U
db 1,32; I
db 7,32; O
db 0,64; P
db 3,128; [
db 5,128; ]
db 4,1; Enter
db 8,64; Ctrl ;####
db 1,16; A
db 3,64; S

db 4,16; D
db 6,16; F
db 7,16; G
db 0,32; H
db 2,32; J
db 3,32; K
db 4,32; L
db 2,8; :
db 0,0
db 0,16; @(~)
db 8,128; Shift
db 4,128; \
db 2,128; Z
db 0,128; X
db 3,16; C
db 6,64; V

db 2,16; B
db 6,32; N
db 5,32; M
db 4,8; ,
db 6,8; .
db 7,8; /
db 8,128; Shift ;####
db 0,0; Prs
db 0,0; Alt
db 0,1; Space
db 8,32; Caps Lock ;####
db 3,2; F1
db 4,2; F2
db 5,2; F3
db 6,2; F4
db 7,2; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 2,2; Home
db 0,2; Up
db 5,1; PgUp-Стр
db 5,8; -
db 6,1; Left
db 0,0
db 7,1; Right
db 3,8; +
db 0,0; End

db 1,2
db 0,0; PqDn
db 0,0; Ins
db 4,2; Del-F2

key_tbl_l_arp:
db 0,0
db 0,4; 01-ESC
db 2,2; 02-1
db 2,4; 03-2
db 2,8; 04-3
db 2,16; 05-4
db 2,32; 06-5
db 2,64; 07-6
db 2,128; 08-7
db 3,1; 09-8
db 3,2; 0a-9
db 2,1; 0b-0
db 3,32; 0c--
db 3,8; 0d
db 1,8; 0e-BSP
db 1,1; 0f-TAB

db 6,2; Q
db 6,128; W
db 4,32; E
db 6,4; R
db 6,16; T
db 7,2; Y
db 6,32; U
db 5,2; I
db 5,128; O
db 6,1; P
db 7,8; [
db 7,32; ]
db 1,4; Enter
db 8,64; Ctrl ;####
db 4,2; A
db 6,8; S

db 4,16; D
db 4,64; F
db 4,128; G
db 5,1; H
db 5,4; J
db 5,8; K
db 5,16; L
db 3,4; :
db 0,0
db 4,1; @(~)
db 8,32 ;Shift
db 7,16; \
db 7,4; Z
db 7,1; X
db 4,8; C
db 6,64; V

db 4,4; B
db 5,64; N
db 5,32; M
db 3,16; ,
db 3,64; .
db 3,128; /
db 8,32; Shift
db 0,0; Prs
db 0,0; Alt
db 7,128; Space
var1:
db 8,128 ;Caps Lock
db 0,8; F1
db 0,16; F2
db 0,32; F3
db 0,64; F4
db 0,128; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 0,1; Home
db 1,32; Up
db 0,2; PgUp-Стр
db 3,32; -
db 1,16; Left
db 0,0
db 1,64; Right
db 3,8; +
db 0,0; End

db 1,128
db 0,0; PqDn
db 0,0; Ins
db 0,16; Del-F2


key_tbl_r dw ?

key_tbl_r_m:
db 0,0
db 1,1; 01-ESC
db 1,4; 02-1
db 2,4; 03-2
db 3,4; 04-3
db 4,4; 05-4
db 5,4; 06-5
db 6,4; 07-6
db 7,4; 08-7
db 0,8; 09-8
db 1,8; 0a-9
db 0,4; 0b-0
db 5,8; 0c--
db 3,8; 0d
db 7,128; 0e-BSP
db 2,1; 0f-TAB

db 2,32; Й
db 3,16; Ц
db 5,64; У
db 3,32; К
db 5,16; Е
db 6,32; Н
db 7,16; Г
db 3,128; Ш
db 5,128; Щ
db 2,128; З
db 0,32; Х
db 0,0
db 4,1; Enter
db 8,64; Ctrl ;####
db 6,16; Ф
db 1,128; Ы

db 7,64; В
db 1,16; А
db 0,64; П
db 2,64; Р
db 7,32; О
db 4,32; Л
db 4,16; Д
db 6,64; Ж
db 4,128; Э
db 0,16; @(~)
db 8,32;
db 4,128; \
db 1,64; Я
db 6,128; Ч
db 3,64; C
db 5,32; М

db 1,32; И
db 4,64; Т
db 0,128; Ь
db 2,16; Б
db 0,16; Ю
db 7,8; /
db 8,128; Shift ;####
db 0,0; Prs
db 0,0; Alt
db 0,1; Space
db 8,32; Caps Lock ;####
db 3,2; F1
db 4,2; F2
db 5,2; F3
db 6,2; F4
db 7,2; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 2,2; Home
db 0,2; Up
db 5,1; PgUp-Стр
db 5,8; -
db 6,1; Left
db 0,0
db 7,1; Right
db 3,8; +
db 0,0; End

db 1,2
db 0,0; PqDn
db 0,0; Ins
db 4,2; Del-F2

key_tbl_r_arp:
db 0,0
db 0,4; 01-ESC
db 2,2; 02-1
db 2,4; 03-2
db 2,8; 04-3
db 2,16; 05-4
db 2,32; 06-5
db 2,64; 07-6
db 2,128; 08-7
db 3,1; 09-8
db 3,2; 0a-9
db 2,1; 0b-0
db 3,32; 0c--
db 3,8; 0d
db 1,8; 0e-BSP
db 1,1; 0f-TAB

db 5,4; Й
db 4,8; Ц
db 6,32; У
db 5,8; К
db 4,32; Е
db 5,64; Н
db 4,128; Г
db 7,8; Ш
db 7,32; Щ
db 7,4; З
db 5,1; Х
db 0,0
db 1,4; Enter
db 8,64; Ctrl ;####
db 4,64; Ф
db 7,2; Ы

db 6,128; В
db 4,2; А
db 6,1; П
db 6,4; Р
db 5,128; О
db 5,16; Л
db 4,16; Д
db 6,64; Ж
db 7,16; Э
db 4,1; @(~)-Ю
db 8,32
db 7,16; \
db 6,2; Я
db 7,64; Ч
db 6,8; С
db 5,32; М

db 5,2; И
db 6,16; Т
db 7,1; Ь
db 4,4; Б
db 4,1; Ю
db 3,128; /
db 8,32
db 0,0; Prs
db 0,0; Alt
db 7,128; Space
var2:
db 8,128
db 0,8; F1
db 0,16; F2
db 0,32; F3
db 0,64; F4
db 0,128; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 0,1; Home
db 1,32; Up
db 0,2; PgUp-Стр
db 3,32; -
db 1,16; Left
db 0,0
db 1,64; Right
db 3,8; +
db 0,0; End

db 1,128
db 0,0; PqDn
db 0,0; Ins
db 0,16; Del-F2

key_tbl_n: ; джойстик в РК-86 (доп. клав.)
db 9,1 ; NumLock=fire
db 0,0 ; ScrollLock
db 9,0ah ; 7
db 9,8 ; 8
db 9,0ch ; 9
db 3,32 ; -
db 9,2 ; 4
db 9,1 ; 5=fire
db 9,4 ; 6
db 3,8 ; +
db 9,12h ; 1
db 9,10h ; 2
db 9,14h ; 3
db 9,1 ; Ins=fire
db 9,1 ; Del=fire

key_tbl_l_8u:  ; Микро-80 & ЮТ-88 лат.
db 0,0
db 0,0; 01-ESC
db 0,2; 02-1
db 0,4; 03-2
db 0,8; 04-3
db 0,16; 05-4
db 0,32; 06-5
db 0,64; 07-6
db 1,1; 08-7
db 1,2; 09-8
db 1,4; 0a-9
db 0,1; 0b-0
db 1,64; 0c--
db 1,16; 0d
db 6,32; 0e-BSP
db 0,0; 0f-TAB

db 4,32; Q
db 5,16; W
db 3,1; E
db 4,64; R
db 5,2; T
db 5,64; Y
db 5,4; U
db 3,16; I
db 4,8; O
db 4,16; P
db 6,2; [
db 6,8; ]
db 7,16; Enter
db 8,2; Ctrl ;####
db 2,8; A
db 5,1; S

db 2,64; D
db 3,2; F
db 3,4; G
db 3,8; H
db 3,32; J
db 3,64; K
db 4,1; L
db 1,8; :
db 0,0
db 2,4; @(~)
db 8,4 ;Shift
db 6,4; \
db 6,1; Z
db 5,32; X
db 2,32; C
db 5,8; V

db 2,16; B
db 4,4; N
db 4,2; M
db 1,32; ,
db 2,1; .
db 2,2; /
db 8,4; Shift
db 0,0; Prs
db 0,0; Alt
db 6,64; Space

db 8,1 ;Caps Lock
db 0,0; F1
db 0,0; F2
db 0,0; F3
db 0,0; F4
db 0,0; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0
db 0,0; Num Lock
db 0,0; Scroll Lock
db 7,64; Home
db 7,4; Up
db 7,32; PgUp-Стр
db 1,64; -
db 7,2; Left
db 0,0
db 7,1; Right
db 1,16; +
db 0,0; End

db 7,8
db 0,0; PqDn
db 0,0; Ins
db 0,0; Del-F2

key_tbl_r_8u:  ; Микро-80 & ЮТ-88 рус.
db 0,0
db 0,4; 01-ESC
db 2,2; 02-1
db 2,4; 03-2
db 2,8; 04-3
db 2,16; 05-4
db 2,32; 06-5
db 2,64; 07-6
db 2,128; 08-7
db 3,1; 09-8
db 3,2; 0a-9
db 2,1; 0b-0
db 3,32; 0c--
db 3,8; 0d
db 1,8; 0e-BSP
db 1,1; 0f-TAB

db 5,4; Й
db 4,8; Ц
db 6,32; У
db 5,8; К
db 4,32; Е
db 5,64; Н
db 4,128; Г
db 7,8; Ш
db 7,32; Щ
db 7,4; З
db 5,1; Х
db 0,0
db 1,4; Enter
db 8,64; Ctrl ;####
db 4,64; Ф
db 7,2; Ы

db 6,128; В
db 4,2; А
db 6,1; П
db 6,4; Р
db 5,128; О
db 5,16; Л
db 4,16; Д
db 6,64; Ж
db 7,16; Э
db 4,1; @(~)-Ю
db 8,32
db 7,16; \
db 6,2; Я
db 7,64; Ч
db 6,8; С
db 5,32; М

db 5,2; И
db 6,16; Т
db 7,1; Ь
db 4,4; Б
db 4,1; Ю
db 3,128; /
db 8,32
db 0,0; Prs
db 0,0; Alt
db 7,128; Space
db 8,128
db 0,8; F1
db 0,16; F2
db 0,32; F3
db 0,64; F4
db 0,128; F5

db 0,0
db 0,0
db 0,0
db 0,0
db 0,0

key_tbl_l_s:
db 0,0,0
db 0,128,0; 01-ESC
db 4,0,4; 02-1
db 4,0,2; 03-2
db 4,0,1; 04-3
db 4,128,0; 05-4
db 4,64,0; 06-5
db 4,32,0; 07-6
db 4,16,0; 08-7
db 4,8,0; 09-8
db 4,4,0; 0a-9
db 4,2,0; 0b-0
db 4,1,0; 0c--
db 4,0,8; 0d
db 1,1,0; 0e-BSP
db 0,0,1; 0f-TAB

db 1,0,8; Q
db 2,0,2; W
db 3,128,0; E
db 2,64,0; R
db 1,64,0; T
db 2,0,4; Y
db 3,0,2; U
db 1,128,0; I
db 2,32,0; O
db 2,128,0; P
db 3,16,0; [
db 3,8,0; ]
db 0,1,0; Enter
db 0,8,0; Ctrl ;ПВ
db 2,0,1; A
db 1,0,2; S

db 2,8,0; D
db 2,0,8; F
db 3,32,0; G
db 3,2,0; H
db 3,0,8; J
db 3,0,1; K
db 2,16,0; L
db 3,1,0; :
db 0,0,0
db 1,8,0; @(~)
db 6,2,0 ;Shift
db 2,2,0; \
db 3,4,0; Z
db 1,32,0; X
db 3,0,4; C
db 2,4,0; V

db 1,16,0; B
db 3,64,0; N
db 1,0,1; M
db 1,4,0; ,
db 2,1,0; .
db 1,2,0; /
db 6,1,0; Shift
db 0,0,0; Prs
db 0,0,0; Alt
db 0,32,0; Space
db 0,0,8 ;Caps Lock
db 5,0,8; F1
db 5,0,4; F2
db 5,0,2; F3
db 5,0,1; F4
db 5,128,0; F5

db 5,64,0 ;F6
db 5,32,0 ;F7
db 5,16,0 ;F8
db 0,0,0
db 0,0,0
db 0,0,0; Num Lock
db 0,0,0; Scroll Lock
db 0,0,4; Home
db 0,0,2; Up
db 5,1,0; PgUp-Стр
db 4,1,0; -
db 0,16,0; Left
db 5,8,0 ;Edit-5
db 0,4,0; Right
db 4,0,8; +
db 5,2,0; End

db 0,0,1; Down
db 5,4,0; PqDn
db 5,0,1; Ins
db 5,0,4; Del-F2

key_tbl_r_s:
db 0,0,0
db 0,128,0; 01-ESC
db 4,0,4; 02-1
db 4,0,2; 03-2
db 4,0,1; 04-3
db 4,128,0; 05-4
db 4,64,0; 06-5
db 4,32,0; 07-6
db 4,16,0; 08-7
db 4,8,0; 09-8
db 4,4,0; 0a-9
db 4,2,0; 0b-0
db 4,1,0; 0c--
db 4,0,8; 0d
db 1,1,0; 0e-BSP
db 0,0,1; 0f-TAB

db 3,0,8; Й
db 3,0,4; Ц
db 3,0,2; У
db 3,0,1; К
db 3,128,0; Е
db 3,64,0; Н
db 3,32,0; Г
db 3,16,0; Ш
db 3,8,0; Щ
db 3,4,0; З
db 3,2,0; Х
db 0,0,0; ]
db 0,1,0; Enter
db 0,8,0; Ctrl ;ПВ
db 2,0,8; Ф
db 2,0,4; Ы

db 2,0,2; В
db 2,0,1; А
db 2,128,0; П
db 2,64,0; Р
db 2,32,0; О
db 2,16,0; Л
db 2,8,0; Д
db 2,4,0; Ж
db 2,2,0; Э
db 1,8,0; @(~)-Ю
db 6,2,0 ;Shift
db 2,2,0; \
db 1,0,8; Я
db 1,0,4; Ч
db 1,0,2; С
db 1,0,1; М

db 1,128,0; И
db 1,64,0; Т
db 1,32,0; Ь
db 1,16,0; Б
db 1,8,0; Ю
db 1,2,0; /
db 6,1,0; Shift
db 0,0,0; Prs
db 0,0,0; Alt
db 0,32,0; Space
db 0,0,8 ;Caps Lock
db 5,0,8; F1
db 5,0,4; F2
db 5,0,2; F3
db 5,0,1; F4
db 5,128,0; F5

db 5,64,0 ;F6
db 5,32,0 ;F7
db 5,16,0 ;F8
db 0,0,0
db 0,0,0
db 0,0,0; Num Lock
db 0,0,0; Scroll Lock
db 0,0,4; Home
db 0,0,2; Up
db 5,1,0; PgUp-Стр
db 4,1,0; -
db 0,16,0; Left
db 5,8,0 ;Edit-5
db 0,4,0; Right
db 4,0,8; +
db 5,2,0; End

db 0,0,1; Down
db 5,4,0; PqDn
db 5,0,1; Ins
db 5,0,4; Del-F2

key_tbl_n_s:
db 5,8,0 ; Edit - Num Lock
db 0,0,0 ; Scroll Lock - не используется
db 4,16,0; 7-Home
db 4,8,0; 8-Up
db 4,4,0; 9-PgUp
db 4,1,0; -
db 4,128,0; 4-Left
db 4,64,0 ;5-Edit
db 4,32,0; 6-Right
db 4,0,8; +
db 4,0,4; 1-End
db 4,0,2; 2-Down
db 4,0,1; 3-PqDn
db 4,2,0; 0-Ins


; Корректирует таблицы в соответствии с типом компьютера
corr_key_tbl proc
        push ax bx
        mov ax, offset key_tbl_l_arp
        mov bx, offset key_tbl_r_arp
        cmp byte ptr cs:[cModel],MODEL_M
        jne cv2
        mov ax, offset key_tbl_l_m
        mov bx, offset key_tbl_r_m
cv2:
        cmp byte ptr cs:[cModel],MODEL_M80
        jne cv3
cv4:    mov ax, offset key_tbl_l_8u
        mov bx, offset key_tbl_r_8u
        jmp cv5
cv3:    cmp byte ptr cs:[cModel],MODEL_U
        je cv4
cv5:
        mov word ptr cs:[key_tbl_l],ax
        mov word ptr cs:[key_tbl_r],bx
        mov al,128
        cmp byte ptr cs:[cModel],MODEL_P
        jne cv1
        mov al,16
cv1:    mov byte ptr cs:[var1+1],al
        mov byte ptr cs:[var2+1],al
        pop bx ax
        ret
corr_key_tbl endp


end
