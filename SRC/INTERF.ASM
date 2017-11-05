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

;File: INTERF.ASM

; Содержит процедуры для интерфейса с пользователем

INCLUDE EMU80.INC

.model tiny

public f_speed
public f_vid
public f_f809
public f_scr
public f_reset
public f_font
public f_refr
public f_snd
public f_tape
public filename
public setup
public getfilename
public disable_vga
public set_fontoem
public enable_hookf809
public set_cga_mode
public filename
public f_choose_file
public f_synb
public f_file_ss
public set_text_mode
public i_spmed
public i_vidno
public i_f809yes
public i_scrlow
public i_scrhigh
public i_scrgr
public i_fontoem
public i_refrcomb
public i_refrrt
public i_refr50
public bNeedClearMem
;public outtextxy2

extrn quit:near
extrn choose_file_name:near
extrn save_scr:near
extrn rest_scr:near
extrn sysreq_code:word
;extrn translate_sysreq_code:near

extrn reg_af:word
extrn reg_bc:word
extrn reg_de:word
extrn reg_hl:word
extrn reg_sp:word
extrn reg_pc:word
extrn reset_addr:word
extrn int_flag:byte
extrn f_pause:byte

extrn ChooseModel:near
extrn SaveSS:near
extrn LoadSS:near
extrn ShowHelp:near
extrn cModel:byte
extrn StopSound:near
extrn ChooseDisk:near
extrn ChooseROM:near
extrn AlterSpeed:near

.code

jumps

h=11
w=49
t=7
l=15

f_reset db 0

bNeedClearMem db ?

; Устанавливает текстовый режим при необходимости
set_text_mode proc
        push ax
        push bx
        mov ah,0fh
        int 10h
        pop bx
        and al,7fh
        cmp al,3
        je stm1
        mov ax,3
        int 10h
stm1:   pop ax
        ret
set_text_mode endp

; Отменяет пункт меню 78x30
disable_vga proc
        mov byte ptr cs:[i_scrhigh+11],1
;       mov word ptr cs:[i_scrlow+3],offset i_scrlow
;       mov word ptr cs:[i_scrlow+5],offset i_scrlow
        ret
disable_vga endp

; Устанавливает пункт меню 80x25 и запрещает остальные
set_cga_mode proc
        mov byte ptr cs:[i_scrhigh+11],1
        mov byte ptr cs:[i_scrauto+11],1
;       mov word ptr cs:[i_scrlow+3],offset i_scrlow
;       mov word ptr cs:[i_scrlow+5],offset i_scrlow
        mov word ptr cs:[l_scr+5], offset i_scrlow
        mov byte ptr cs:[f_scr],SCR_LOW
        mov word ptr cs:[l_font+5],offset i_fontoem
        mov byte ptr cs:[f_font],FONT_OEM
        mov byte ptr cs:[i_fontrk+11],1
        ret
set_cga_mode endp

; Устанавливает знакогенератор cp866
set_fontoem proc
        mov word ptr cs:[l_font+5],offset i_fontoem
        mov byte ptr cs:[f_font],FONT_OEM
        ret
set_fontoem endp

; Устанавливает перехват 0F809H
enable_hookf809 proc
        mov word ptr cs:[l_f809+5],offset i_f809yes
        mov byte ptr cs:[f_f809],HOOKF809_YES
        ret
enable_hookf809 endp

; Отображает меню настроек
setup proc
        pushf
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push bp
        push ds
        mov ax,cs
        mov ds,ax
        push es
;      call translate_sysreq_code
      cmp byte ptr cs:[sysreq_code+1],SYSREQ_MENU
      jne set1
        call save_scr
        push ax
        call set_text_mode
        call StopSound
        call prframe
        call printall
        call input
        pop ax
        call rest_scr
set7:   cmp byte ptr cs:[f_reset],1
       jne set10
set6:  mov word ptr cs:[reg_af],0
       mov word ptr cs:[reg_bc],0
       mov word ptr cs:[reg_de],0
       mov word ptr cs:[reg_hl],0
       mov word ptr cs:[reg_sp],0
       mov byte ptr cs:[int_flag],0
       push ax
       mov ax, word ptr cs:[reset_addr]
       mov word ptr cs:[reg_pc],ax
       pop ax
       mov byte ptr cs:[f_reset],1
set10:  jmp set2
set1:   cmp byte ptr cs:[sysreq_code+1],SYSREQ_RESET
        je set6
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_SAVESS
        jne set4
        call SaveSS
        mov byte ptr cs:[f_reset],0
        jmp set2
set4:   cmp byte ptr cs:[sysreq_code+1],SYSREQ_LOADSS
        jne set11
        call LoadSS
        mov byte ptr cs:[f_reset],0
        cmp al,3
        jne set2
        mov byte ptr cs:[f_reset],1
        jmp set7
set11:  cmp byte ptr cs:[sysreq_code+1],SYSREQ_DISKA
        jne set12
        mov ax,0
        push ax
        call ChooseDisk
        pop ax
        mov byte ptr cs:[f_reset],0
        jmp set2
set12:  cmp byte ptr cs:[sysreq_code+1],SYSREQ_DISKB
        jne set5
        mov ax,1
        push ax
        call ChooseDisk
        pop ax
        mov byte ptr cs:[f_reset],0
        jmp set2
set5:   cmp byte ptr cs:[sysreq_code+1],SYSREQ_ROM
        je set13
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_SPEEDUP
        je set14
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_SPEEDDOWN
        je set14
        mov byte ptr cs:[bNeedClearMem],1
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_MODEL
        je set8
        mov byte ptr cs:[bNeedClearMem],0
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_MODELNOCLEAR
        je set8
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_QUIT
        je set9
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_PAUSE
        je set15
        call ShowHelp
        jmp set2
set8:   call ChooseModel
        mov byte ptr cs:[f_reset],al
        jmp set7
set13:  call ChooseROM
        mov byte ptr cs:[f_reset],al
        jmp set7
set15:  xor byte ptr cs:[f_pause],0ffh
        mov byte ptr cs:[f_reset],0
        jmp set2
set14:  mov al,byte ptr cs:[sysreq_code+1]
        xor ah,ah
        push ax
        call AlterSpeed
        pop ax
        mov byte ptr cs:[f_reset],0
        jmp set2
set9:   jmp quit
set2:   pop es
        pop ds
        pop bp
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        ret
setup endp

; Запрос имени файла
getfilename proc
        pushf
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push bp
        push ds
        mov ax,es
        mov ds,ax
        push es
        call save_scr
        push ax
        call query
        call readstr
        pop ax
        call rest_scr
        pop es
        pop ds
        pop bp
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        popf
        ret
getfilename endp

i_spnorm:
        db SPEED_NORM
        db 1
        db 24
        dw i_spmed
        dw i_spmax
        dw l_vid
        dw l_tape
        db 0
        db 'Норм.',0
i_spmed:
        db SPEED_MEDIUM
        db 1
        db 31
        dw i_spmax
        dw i_spnorm
        dw l_vid
        dw l_tape
        db 0
        db 'Без ПДП',0
i_spmax:
        db SPEED_HIGH
        db 1
        db 40
        dw i_spnorm
        dw i_spmed
        dw l_vid
        dw l_tape
        db 0
        db 'Макс.',0
l_speed:
f_speed:db SPEED_NORM
        dw l_vid
        dw l_tape
        dw i_spnorm
        db 1
        db 3
        db 'Скорость:',0

i_vidno:
        db MEM_NONE
        db 2
        db 24
        dw i_vidyes
        dw i_vidfull
        dw l_f809
        dw l_speed
        db 0
        db 'Нет',0
i_vidyes:
        db MEM_W
        db 2
        db 29
        dw i_vidfull
        dw i_vidno
        dw l_f809
        dw l_speed
        db 0
        db 'Зап.',0
i_vidfull:
        db MEM_RW
        db 2
        db 35
        dw i_vidno
        dw i_vidyes
        dw l_f809
        dw l_speed
        db 0
        db 'Чт/Зап',0
l_vid:
f_vid:  db MEM_W
        dw l_f809
        dw l_speed
        dw i_vidyes
        db 2
        db 3
        db 'Эмул.в/пам.и порт.:',0

i_f809yes:
        db HOOKF809_YES
        db 3
        db 24
        dw i_f809no
        dw i_f809no
        dw l_scr
        dw l_vid
        db 0
        db 'Да',0
i_f809no:
        db HOOKF809_NO
        db 3
        db 28
        dw i_f809yes
        dw i_f809yes
        dw l_scr
        dw l_vid
        db 0
        db 'Нет',0
l_f809:
f_f809: db HOOKF809_NO
        dw l_scr
        dw l_vid
        dw i_f809no
        db 3
        db 3
        db 'Перехват 0F809H:',0

i_scrauto:
        db SCR_AUTO
        db 4
        db 24
        dw i_scrgr
        dw i_scrhigh
        dw l_font
        dw l_f809
        db 0
        db 'Авто',0
i_scrgr:
        db SCR_GRAPH
        db 4
        db 31
        dw i_scrlow
        dw i_scrauto
        dw l_font
        dw l_f809
        db 0
        db 'Граф.',0
i_scrlow:
        db SCR_LOW
        db 4
        db 38
        dw i_scrhigh
        dw i_scrgr
        dw l_font
        dw l_f809
        db 0
        db '25',0
i_scrhigh:
        db SCR_HIGH
        db 4
        db 42
        dw i_scrauto
        dw i_scrlow
        dw l_font
        dw l_f809
        db 0
        db '30',0
l_scr:
f_scr:  db SCR_AUTO
        dw l_font
        dw l_f809
        dw i_scrauto
        db 4
        db 3
        db 'Разрешение экрана:',0

i_fontoem:
        db FONT_OEM
        db 5
        db 24
        dw i_fontrk
        dw i_fontrk
        dw l_refr
        dw l_scr
        db 0
        db 'cp866',0
i_fontrk:
        db FONT_RK
        db 5
        db 31
        dw i_fontoem
        dw i_fontoem
        dw l_refr
        dw l_scr
        db 0
        db 'РК',0
l_font:
f_font:  db FONT_RK
        dw l_refr
        dw l_scr
        dw i_fontrk
        db 5
        db 3
        db 'Знакогенератор:',0

i_refrcomb:
        db REFR_COMB
        db 6
        db 24
        dw i_refrrt
        dw i_refr50
        dw l_snd
        dw l_font
        db 0
        db 'Комб.',0
i_refrrt:
        db REFR_RT
        db 6
        db 31
        dw i_refr50
        dw i_refrcomb
        dw l_snd
        dw l_font
        db 0
        db 'Real-time',0
i_refr50:
        db REFR_50
        db 6
        db 42
        dw i_refrcomb
        dw i_refrrt
        dw l_snd
        dw l_font
        db 0
        db '50Гц',0
l_refr:
f_refr: db REFR_COMB
        dw l_snd
        dw l_font
        dw i_refrcomb
        db 6
        db 3
        db 'Обн. текст. экрана:',0


i_sndon:
        db SND_ON
        db 7
        db 24
        dw i_sndoff
        dw i_sndsb
        dw l_tape
        dw l_refr
        db 0
        db 'Вкл.',0
i_sndoff:
        db SND_OFF
        db 7
        db 30
        dw i_sndsb
        dw i_sndon
        dw l_tape
        dw l_refr
        db 0
        db 'Выкл.',0
i_sndsb:
        db SND_SB
        db 7
        db 37
        dw i_sndon
        dw i_sndoff
        dw l_tape
        dw l_refr
        db 0
        db 'SB',0
l_snd:
f_snd:  db SND_ON
        dw l_tape
        dw l_refr
        dw i_sndon
        db 7
        db 3
        db 'Звук:',0

i_tapefile:
        db TAPE_FILE
        db 8
        db 24
        dw i_tapesbout
        dw i_tapesbin
        dw l_speed
        dw l_snd
        db 0
        db 'Файл',0
i_tapesbout:
        db TAPE_SBOUT
        db 8
        db 30
        dw i_tapesbin
        dw i_tapefile
        dw l_speed
        dw l_snd
        db 0
        db 'SB-Out',0
i_tapesbin:
        db TAPE_SBIN
        db 8
        db 38
        dw i_tapefile
        dw i_tapesbout
        dw l_speed
        dw l_snd
        db 0
        db 'SB-In',0
l_tape:
f_tape: db TAPE_FILE
        dw l_speed
        dw l_snd
        dw i_tapefile
        db 8
        db 3
        db 'Магнитофон:',0

stline  dw l_speed

outtextxy proc
        push ax
        mov al,dh
        add al,t
        add dl,l
        xor ah,ah
        mov cl,80
        mul cl
        xor dh,dh
        add ax,dx
        shl ax,1
        mov di,ax
        mov ax,0b800h
        mov es,ax
        pop ax
        cld
otxy1:  lodsb
        test al,al
        jz otxyex
        stosw
        jmp otxy1
otxyex: ret
outtextxy endp

outtextxy2 proc
        push ax
        mov al,dh
        xor ah,ah
        mov cl,80
        mul cl
        xor dh,dh
        add ax,dx
        shl ax,1
        mov di,ax
        mov ax,0b800h
        mov es,ax
        pop ax
        cld
otxy2_1:  lodsb
        test al,al
        jz otxy2_ex
        stosw
        jmp otxy2_1
otxy2_ex: ret
outtextxy2 endp

printitem proc
        push es
        push dx
        push cx
        push ax
        mov dl,byte ptr [bx+2]
        mov dh,byte ptr [bx+1]
        lea si,[bx+12]
        call outtextxy
        pop ax
        pop cx
        pop dx
        pop es
        ret
printitem endp

printline proc
        push si
        push cx
        push bx
        push es
        push dx
        push cx
        push ax
        mov dl,byte ptr [bx+8]
        mov dh,byte ptr [bx+7]
        lea si,[bx+9]
        mov ah,1bh
        call outtextxy
        pop ax
        pop cx
        pop dx
        pop es
        mov bx,word ptr [bx+5]
        mov cx,bx
;        mov ah,1eh
        call printitem
pl1:    mov bx,word ptr [bx+3]
        cmp cx,bx
        je plex
        mov ah,17h
        cmp byte ptr [bx+11],0
        jz pl2
        mov ah,18h
pl2:    call printitem
        jmp pl1
plex:   pop bx
        pop cx
        pop si
        ret
printline endp

printall proc
        push bx
        push cx
        mov bx,[stline]
        mov cx,bx
pa1:    mov ah,1eh
        call printline
        mov bx,word ptr [bx+1]
        cmp bx,cx
        jne pa1
        pop cx
        pop bx
        ret
printall endp

prframe proc
;        push ds
;        mov ax,0b800h
;        mov ds,ax
;        mov si,160*t+(l*2)
;        lea di,winbuf
;        mov cx,h
;        cld
;gw0:    push cx
;        push si
;        mov cx,w
;        rep movsw
;        pop si
;        pop cx
;        add si,160
;        loop gw0
;        pop ds
        push es
        mov ax,0b800h
        mov es,ax
        mov di,160*t+(l*2)
        mov cx,h
        cld
        mov ax,1e00h
gw1:    push cx
        push di
        mov cx,w
        rep stosw
        pop di
        pop cx
        add di,160
        loop gw1
        mov di,160*t+(l*2)+2
        mov ax,1ecdh
        mov cx,w-2
        rep stosw
        mov di,160*t+160*(h-1)+(l*2)+2
        mov ax,1ecdh
        mov cx,w-2
        rep stosw
        mov di,160*t+(l*2)
        mov byte ptr es:[di],'╔'
        mov byte ptr es:[di+(w*2-2)],'╗'
        mov byte ptr es:[di+(h-1)*160],'╚'
        mov byte ptr es:[di+(h-1)*160+(w*2-2)],'╝'
        mov cx,h-2
gw2:    add di,160
        mov byte ptr es:[di],'║'
        loop gw2
        mov cx,h-2
        mov di,160*(t+1)+(l*2)+(w*2-2)
gw3:    mov byte ptr es:[di],'║'
        add di,160
        loop gw3
        mov ah,1ah
        mov dh,h-2
        mov dl,6
        lea si,lastline
        call outtextxy
        pop es
        ret
prframe endp

;restwin proc
;        push es
;        mov ax,0b800h
;        mov es,ax
;        mov di,160*t+(l*2)
;        lea si,winbuf
;        mov cx,h
;        cld
;pw0:    push cx
;        push di
;        mov cx,w
;        rep movsw
;        pop di
;        pop cx
;        add di,160
;        loop pw0
;        pop es
;        ret
;restwin endp

query   proc
        push es
        push ax
        push di
        push si
        push cx
        mov ax,0b800h
        mov es,ax
        mov di,160*10+44
        lea si,frame
        cld
        mov dx,5
em0:    push di
        mov cx,36
        mov ah,1eh
em1:    lodsb
        stosw
        loop em1
        pop di
        add di,160
        dec dx
        jnz em0
        cmp byte ptr [f_file_ss],1
        jne em2
       cmp byte ptr [f_choose_file],0
       jne em2
        lea si,prompt_ss
        mov dx,0b18h
        mov ah,1eh
        call outtextxy2
em2:    cmp byte ptr [f_file_ss],2
        jne em3
        lea si,prompt_odi
        mov dx,0b18h
        mov ah,1eh
        call outtextxy2
em3:    pop cx
        pop si
        pop di
        pop ax
        pop es
        ret
query   endp

prsymb proc
        mov ah,0eh
        push bx
        xor bh,bh
        mov cx,1
        int 10h
        pop bx
        ret
prsymb endp

; 1, если нужно выбирать файл
f_choose_file db ?

; 1, если файл снапшота
f_file_ss db ?

; 1, если нужно писать синхробайт
f_synb db 0

readstr proc
        mov ah,3
        xor bh,bh
        int 10h
        push dx
        mov ah,2
        xor bh,bh
        mov dx,0b24h
        int 10h
        lea bx,filename
rstr1:  mov byte ptr [bx],0
rstr2:  call show_hint
        xor ah,ah
        int 16h
        cmp al,0dh
        je rstr3
        cmp al,1bh
        je rstr9
        cmp ax,3d00h ; F3
        je rstrc
        cmp al,8
        je rstr5
        cmp bx,(offset filename)+20
        je rstr2
        test al,al
        jz rstr4
        cmp al,20h
        jl rstr2
        cmp al,7fh
        jg rstr2
        mov byte ptr [bx],al
        inc bx
        call prsymb
        jmp rstr1
rstr4:  cmp ax,4b00h
        jne rstr2
rstr5:  cmp bx,offset filename
        je rstr2
        mov al,8
        call prsymb
        mov al,' '
        call prsymb
        mov al,8
        call prsymb
        dec bx
        jmp rstr1
rstr9:  mov byte ptr cs:[filename],0
        jmp rstr6
rstr3:  
        cmp byte ptr cs:[filename],0
        jne rstr6
        push bx
        call choose_file_name
        pop bx
        cmp byte ptr cs:[filename],0
        jz rstr2
rstr6:  mov ah,2
        xor bh,bh
        pop dx
        int 10h
        ret
rstrc:  xor byte ptr [f_synb],1
        mov al,byte ptr [f_synb]
        xor al,1
        shl al,1
        add al,'+'
        mov byte ptr [wr_hint+19h],al
        jmp rstr2
show_hint:
        cmp byte ptr [f_choose_file],0
        jnz rstra
; Запись
        lea si,wr_hint
        cmp byte ptr [f_file_ss],0
        jne rstre
        mov dx,0d1ah
        jmp rstrb
rstre:  lea si,emp_hint_r
        jmp rstr8
; Чтение
rstra:  cmp byte ptr [filename],0
        jz rstr7
rstrd:  lea si,emp_hint
        jmp rstr8
rstr7:  lea si,nemp_hint
rstr8:  mov dx,0d1ch
rstrb:  mov ah,1ah
        call outtextxy2
        ret
emp_hint db  '       Esc-отмена       ',0
emp_hint_r db  '   Esc - отмена записи  ',0
nemp_hint db 'Enter-выбор  Esc-отмена',0
wr_hint db   '  Esc-отмена  F3:С/байт-[-] ',0
prompt_ss db 'Файл[.rss]:',0
prompt_odi db 'Файл[.odi]:',0
readstr endp

input proc
        mov bx,word ptr [stline]
inpaa:  mov si,bx
        mov bx,word ptr [bx+5]
inpl:   mov ah,3eh
        push bx
        mov bx,si
        call printline
        pop bx
        mov al,byte ptr [bx]
        mov byte ptr [si],al
inpr:   mov ah,10h
        int 16h
        cmp ah,4bh ; <-
        jne inp1
inpb:   mov bx,word ptr [bx+5]
        mov word ptr [si+5],bx
        cmp byte ptr [bx+11],0
        jnz inpb
        jmp inpl
inp1:   cmp ah,4dh ; ->
        jne inp2
inpc:   mov bx,word ptr [bx+3]
        mov word ptr [si+5],bx
        cmp byte ptr [bx+11],0
        jnz inpc
        jmp inpl
inp2:   cmp ah,48h ; ^
        jne inp3
        mov bx,word ptr [bx+9]
        jmp inpa
inp3:   cmp ah,50h ; \/
        jne inp4
inp5:   mov bx,word ptr [bx+7]
        jmp inpa
inp4:  cmp ah,43h ; F9
       jne inpd
       push bx
       push si
       call ChooseModel
       pop si
       pop bx
       test ax,ax
       jnz inp7
       jmp inpr
inpd:  cmp ah,3bh ; F1
       jne inpe
       push bx
       push si
       call ShowHelp
       pop si
       pop bx
       jmp inpr
inpe:   cmp al,0dh
        je inp5
        cmp al,1bh
        je inpex
        and al,0dfh
        cmp al,51h
        je inp6
        cmp al,52h
        je inp7
        jmp inpr
inpa:   push bx
        mov bx,si
        mov ah,1eh
        call printline
        pop bx
        mov word ptr [stline],bx
jmp inpaa
inp6:   call rest_scr
        jmp quit
inp7:   mov byte ptr [f_reset],1
inpex:  ret
input endp

frame db '╔══════════════════════════════════╗'
      db '║  Имя файла:                      ║'
      db '╟──────────────────────────────────╢'                                                                   
      db '║                                  ║'
      db '╚══════════════════════════════════╝'


;winbuf db h*w*2 dup ( ? )
filename db 21 dup ( ? )
lastline db 'ESC-Возврат R-Reset F1-Помощь Q-Выход',0

end
