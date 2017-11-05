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

; File: EMUIO.ASM

INCLUDE EMU80.INC

; Содержит процедуры, эмулирующие внешние устройства ПК

.model tiny

public scr_beg
public scr_end
public save_byte
public load_byte
public save_port
public load_port
public enable_ints
public disable_ints
public cur_xy
public cur_x
public cur_y
public process_port_c
public port_c
public process_int
public cur_corr
public keybin_port
public crt_param_1
public crt_param_2
public crt_param_3
public crt_param_4
public crt_mreg
public dma_mr
public dma_begadr
public dma_len
public pit_k0
public pit_k1
public pit_k2
public pit_cnt0
public pit_cnt1
public pit_cnt2
public pit_mode0
public pit_mode1
public pit_mode2
public pit_ld0
public pit_ld1
public pit_ld2
public int_flag
public process_crt
public process_pit
public write_byte_spec
public write_byte_spec_640
public write_byte_spec_800
public write_byte_orion
public write_byte_orion_640
public write_byte_orion_800
public cur_color_code
public color_table
public calc_pit
public ticks_per_44100th
public ticks_per_50ms
public ticks_per_calc
public vretr_cnt
public vmem_off
public mem_page_no
public process50
public old_or_colormode
public old_or_scrpage
public or_color_mode
public mem_page_no
public or_scrpage
public process_orion
public perform_reset
public mikr_symg
public use_io_space

extrn symtable_ptr:word
extrn cur_offs:word
extrn sh_scrbeg:word
extrn sh_scrlen:word
extrn sh_width:byte
extrn sh_height:byte
extrn f_scr:byte
extrn f_vid:byte
extrn f_refr:byte
extrn f_snd:byte
extrn f_tape:byte
extrn refresh_scr:near
extrn draw_scr_or:near
extrn set_video_auto:near
extrn key_bytes:byte
extrn ctrl_keys:byte
extrn joy_state:byte
extrn key_bytes_s:word
extrn ctrl_keys_s:word
;extrn light_led:near
extrn led_state:byte
extrn rst6:near
extrn set_delay_w_dma:near
extrn set_delay_wo_dma:near
extrn set_delay_w_dma28:near
extrn cModel:byte
extrn snd61_and:byte
extrn mem:dword
extrn mempage0:dword
extrn mempage1:dword
extrn mempage2:dword
extrn mempage3:dword
extrn color_mem:dword
extrn romdisk_mem:dword
extrn f_refr_txt_scr:byte

extrn PlayByteNoWait:near
extrn ReadByteNoWait:near
extrn ReadSector:near
extrn WriteSector:near
extrn acSectBufA:byte
extrn acSectBufB:byte

jumps  ; Надоело код вылизывать ....

.code

use_io_space db 0 ; Используются ли команды IN/OUT

vmem_off dw 4402

cur_corr dw ?
keybin_port dw ?

;mag_state db 0 ; Порт 1 для Микро-80 или A1 для ЮТ-88

crt_param_1 db ?
crt_param_2 db ?
crt_param_3 db ?
crt_param_4 db ?
dma_mr db 0a4h
crt_mreg db 28h

dma_begadr_old dw 0
dma_len_old dw 0
crt_param_1_old db 0
crt_param_2_old db 0
crt_param_3_old db 0
crt_param_4_old db 0

pit_k0 dw 1
pit_k1 dw 1
pit_k2 dw 1

pit_cnt0 dw 0
pit_cnt1 dw 0
pit_cnt2 dw 0

pit_mode0 db 36h
pit_mode1 db 66h
pit_mode2 db 0b6h

pit_read_byte_cnt0 dw 0 ; Текущий считываемый из счетчика 0 PIT байт (0/1)
pit_read_byte_cnt1 dw 0 ; Текущий считываемый из счетчика 1 PIT байт (0/1)
pit_read_byte_cnt2 dw 0 ; Текущий считываемый из счетчика 2 PIT байт (0/1)

pit_ld0 db 0 ; Признак загрузки счетчика таймера 0
pit_ld1 db 0 ; Признак загрузки счетчика таймера 1
pit_ld2 db 0 ; Признак загрузки счетчика таймера 2

pit_cnt_p dw 0 ; для "Партнера"


snd_state db 0

vretr_cnt db 0 ; признак бита обратного верт. хлда луча. Ставится приблизит.

ticks_per_44100th dw ?
ticks_per_50ms dw ?
ticks_per_calc dw ? ; Одно из 2 вышеперечисленных в зависимости от режима


color_table db 00h, 03h, 05h, 06h
cur_color_code db 0

or_color_mode db 0
or_color4_table db 4 dup (?)
or_color4_table1 db 0fh, 0dh, 0bh, 0eh
or_color4_table2 db 0ah, 09h, 08h, 0ch

mem_page_no db 0 ; Номер текущей страницы памяти ПК "Орион"

or_scrpage db 0 ; Номер текущего экрана ПК "Орион"

romdisk_addr dw 0 ; Текущий адрес в ROMDISK'е

mikr_symg db 0 ; 0/80h в зависимости от тек. знакогенератора "Микроши"

; Разрешение прерываний (EI)
enable_ints proc
        mov byte ptr cs:[int_flag],1
        cmp byte ptr cs:[cModel],MODEL_P
        jne ei2
        cmp byte ptr cs:[int_req],0
        jz ei1
        call process_int
;       mov byte ptr cs:[int_flag],1
ei1:    ret
ei2:    cmp byte ptr cs:[cModel],MODEL_R
        je ei3
        cmp byte ptr cs:[cModel],MODEL_M80
        je ei3
        cmp byte ptr cs:[cModel],MODEL_O
        jne ei1
; в РК-86 - включение динамика
ei3:    push ax
        in al,61h
        and al,0fch
        or al,2
       and al,byte ptr cs:[snd61_and]
        out 61h,al
        pop ax
        ret
; push ax
; push dx
;tttt1:
; in al,dx
; test al,80h
; jnz tttt1
; mov dx,22ch
; mov al,10h
; out dx,al
; mov al,20h
; out dx,al
; pop dx
; pop ax
enable_ints endp

; Запрещение прерываний (DI)
disable_ints proc
        mov byte ptr cs:[int_flag],0
        cmp byte ptr cs:[cModel],MODEL_P
        jne di2
di1:    ret
di2:    cmp byte ptr cs:[cModel],MODEL_R
        je di3
        cmp byte ptr cs:[cModel],MODEL_M80
        je di3
        cmp byte ptr cs:[cModel],MODEL_O
        jne di1
; в РК-86 - выключение динамика
di3:    push ax
        in al,61h
        and al,0fch
        out 61h,al
        pop ax
        ret
; push ax
; push dx
;ttttt1:
; in al,dx
; test al,80h
; jnz ttttt1
; mov dx,22ch
; mov al,10h
; out dx,al
; mov al,0h
; out dx,al
; pop dx
; pop ax
disable_ints endp

process_int proc
        cmp byte ptr cs:[cModel],MODEL_P
        jne pi1 ; Работает только для "Партнера"
       cmp byte ptr cs:[int_flag],0
       jnz pi2
       mov byte ptr cs:[int_req],1
       jmp pi1
pi2:   mov byte ptr cs:[int_flag],0
       mov byte ptr cs:[int_req],0
       push bp
       cmp byte ptr ds:[si],76h ; HLT
       je pi3
       dec si
pi3:   call rst6
       pop bp
pi1:   ret
process_int endp

int_flag db 0 ; 1, если разрешены прерывания
int_req db 0 ; 1, если есть отложеный запрос на прерывание

cursor_state db 0       ; 1, если координата X положения курсора принята,
                        ; а Y - еще нет
cursor_x db ?           ; координата X положения курсора

scr_beg dw ?            ; начало области видеопамяти 64x25
scr_end dw ?            ; ее конец

; Вызывается при попытке записи в память
; BP-адрес, AH-значение

save_byte proc
        cmp byte ptr cs:[cModel],MODEL_O
        je sb_or

        cmp byte ptr cs:[cModel],MODEL_M80
        je sb_m80u
        cmp byte ptr cs:[cModel],MODEL_U
        je sb_u

        cmp bp,word ptr cs:[scr_beg]
        jae sb1
sb0:    mov byte ptr ds:[bp],ah         ; пишем
sb00:   ret

sb_u:
        cmp byte ptr cs:[utrdpag],0
        jz sb_m80u
        push ax
        mov al, byte ptr ds:[si]
        and al,0cfh
        cmp al,0c5h ; push ?
        pop ax
        jne sb_m80u

        ; Обращение к RAMDISK'у
        push bx es
        mov bx, word ptr cs:[utrdseg]
        mov es,bx
        mov byte ptr es:[bp],ah
        pop es bx
        ret

sb_m80u:
        cmp bp,0e000h
        jb sb0
        cmp bp, 0f000h
        jb sb_m80_scr
;   jmp sb0
        cmp bp, 0f800h
; jmp sb0
        jb sb0
        jmp sb00

sb_m80_scr:
; Попали в видеопамять Микро-80 или ЮТ-88
        cmp byte ptr cs:[cModel],MODEL_M80
        je sms1
        or bp,800h
        mov byte ptr ds:[bp],ah
        and bp,0f7ffh
        mov byte ptr ds:[bp],ah
        sub bp,word ptr cs:[scr_beg]
        jmp sms2
sms1:
        mov byte ptr ds:[bp],ah         ; пишем
;        cmp byte ptr cs:[f_scr],SCR_GRAPH
;        je sb00
;        cmp byte ptr cs:[f_refr],REFR_50
;        je sb00
;        test al,al
;        jns sb9
;        cmp al,0c0h
;        ja sb9
;        mov byte ptr cs:[f_refr_txt_scr],1
        sub bp,word ptr cs:[scr_beg]
        cmp bp,800h
        jb sb_m80_scr_atr
        sub bp,800h
sms2:
        push bx
        push ax
        mov ax,bp
        mov bl, 64; byte ptr cs:[sh_width]
        div bl
        mov bh,160
        mov bl,ah
        mul bh
        xor bh,bh
        add ax,bx
        add ax,bx
        mov bp,ax
        pop ax
        push ax
        mov bx,word ptr cs:[symtable_ptr]
        mov al,ah
        and al,07fh
        xlat cs:[bx]
        push es
        mov bx,0b800h
        mov es,bx
        mov byte ptr es:[bp+816],al     ; ###
        mov byte ptr es:[bp+817],07h    ; ###
       cmp byte ptr cs:[cModel],MODEL_M80
       je sms3
        test ah,ah
        jns sms3
       mov byte ptr es:[bp+817],70h     ; ###
sms3:
        pop es
        pop ax
        pop bx
        ret
sb_m80_scr_atr:
        push bx
        push ax
        mov ax,bp
        mov bl, 64; byte ptr cs:[sh_width]
        div bl
        mov bh,160
        mov bl,ah
        mul bh
        xor bh,bh
        add ax,bx
        add ax,bx
        mov bp,ax
        inc bp
        pop ax
        push ax
        test ah,ah
        mov al,07h
        jz smsa1
        mov al,70h
smsa1:
        push es
        mov bx,0b800h
        mov es,bx
        mov byte ptr es:[bp+816],al          ; ###
        pop es
        pop ax
        pop bx
        ret
                               
sb_or:
        cmp bp,0f000h
        jae sb_or_1
        push ax
        mov ax, word ptr cs:[mem+2]
        mov ds,ax
        pop ax
        cmp bp,word ptr cs:[scr_beg]
        jb sb0
        cmp bp,word ptr cs:[scr_end]
        ja sb0
        cmp byte ptr cs:[mem_page_no],0
        je sb_or_2
        cmp byte ptr cs:[mem_page_no],1
        jne sb0
; Пишем цвет
        mov byte ptr ds:[bp],ah         ; пишем
        mov al,ah
        push ax es bx
        mov bx, word ptr cs:[mempage0+2]
        mov es,bx
        pop bx
        mov ah, byte ptr es:[bp]
        pop es
        call word ptr cs:[write_byte_orion]
        pop ax
        ret
; Пишем байт
sb_or_2:mov byte ptr ds:[bp],ah         ; пишем
        push ax es bx
        mov bx, word ptr cs:[mempage1+2]
        mov es,bx
        pop bx
        mov al, byte ptr es:[bp]
        pop es
        call word ptr cs:[write_byte_orion]
        pop ax
        ret
sb_or_1:
        cmp bp,0f400h
        jb sbm5_1
        cmp bp,0f500h
        jb ppi1_out
        cmp bp,0f600h
        jb ppird_out
        cmp bp,0f700h
        jb sb00 ; ВВ55 в будущем ?
        cmp bp,0f800h
        jb disk_out ; дисковод
        cmp bp,0f900h
        jb or_color_mode_out
        cmp bp,0fa00h
        jb or_mp_port_out
        cmp bp,0fb00h
        jb or_scrpage_out
        jmp sb00
sbm5_1: ; Попали в системное ОЗУ "Ориона"
        push ax
        mov ax, word ptr cs:[mempage0+2]
        mov ds,ax
        pop ax
        jmp sb0

sb1:    cmp bp,word ptr cs:[scr_end]
        ja sb2
; Попали в видеопамять
        mov al, byte ptr ds:[bp]
        mov byte ptr ds:[bp],ah
        cmp byte ptr cs:[cModel],MODEL_S
        jne sb6
        jmp word ptr cs:[write_byte_spec]
sb6:
        cmp byte ptr cs:[f_scr],SCR_GRAPH
        je sb00
        cmp byte ptr cs:[f_refr],REFR_50
        je sb00
        test al,al
        jns sb9 
        cmp al,0c0h
        ja sb9
        mov byte ptr cs:[f_refr_txt_scr],1
sb9:    sub bp,word ptr cs:[scr_beg]
        push bx
        push ax
        mov ax,bp
        mov bl, 78; byte ptr cs:[sh_width]
        div bl
        mov bh,160
        mov bl,ah
        mul bh
        xor bh,bh
        add ax,bx
        add ax,bx
        mov bp,ax
        pop ax
        push ax
        mov bx,word ptr cs:[symtable_ptr]
        mov al,ah
        test al,al
        jns sb55
        cmp al,0c0h
        jb sb58
        cmp al,0f0h
        jae sb57
        mov al,0b0h
        jmp sb56
sb58:   mov byte ptr cs:[f_refr_txt_scr],1
sb57:   xor al,al
        jmp sb55
sb55:
        xlat cs:[bx]
sb56:
        push es
        mov bx,0b800h
        mov es,bx
        mov byte ptr es:[bp],al
        pop es
        pop ax
        pop bx
        ret

sb2:
        cmp byte ptr cs:[cModel],MODEL_P
        jne sbm_1

        cmp bp,0d800h
        jb sb0
        cmp bp,0d900h
        jae sb3_p
        jmp crt_out
sb3_p:  cmp bp,0da00h
        jae sb4_p
        jmp ppi1_out
sb4_p:  cmp bp,0db00h
        jae sb5_p
        ret
sb5_p:  cmp bp,0dc00h
        jae sb6_p
        jmp dma_out
sb6_p:  ret

sbm_1:
        cmp byte ptr cs:[cModel],MODEL_R
        jne sbm_2

        cmp bp,8000h
        jb sb0
        cmp bp,0a000h
        jae sb3_r
        jmp ppi1_out
sb3_r:  cmp bp,0c000h
        jae sb4_r
        jmp pit_out
sb4_r:  cmp bp,0e000h
        jae sb5_r
        jmp crt_out
sb5_r:  jmp dma_out

sbm_2:
        cmp byte ptr cs:[cModel],MODEL_M
        jne sbm_3

        cmp bp,8000h
        jb sb0
        cmp bp,0c000h
        jae sb3_m
        ret
sb3_m:  cmp bp,0c800h
        jae sb4_m
        jmp ppi1_out
sb4_m:  cmp bp,0d000h
        jae sb5_m
        jmp ppi2_out
sb5_m:  cmp bp,0d800h
        jae sb6_m
        jmp crt_out
sb6_m:  cmp bp,0e000h
        jae sb7_m
        jmp pit_out
sb7_m:  cmp bp,0f800h
        jae sb8_m
        ret
sb8_m:  jmp dma_out

sbm_3:
        cmp byte ptr cs:[cModel],MODEL_A
        jne sbm_4

        cmp bp,0ec00h
        jb sb0
        cmp bp,0ed00h
        jae sb3_a
        jmp pit_out
sb3_a:  cmp bp,0ee00h
        jae sb4_a
        jmp ppi1_out
sb4_a:  cmp bp,0ef00h
        jae sb5_a
        jmp ppi2_out
sb5_a:  cmp bp,0f000h
        jae sb6_a
        jmp crt_out
sb6_a:  cmp bp,0f100h
        jae sb7_a
        jmp dma_out
sb7_a:  ret

sbm_4:
;        cmp byte ptr cs:[cModel],MODEL_S
;        jne sb00 ; Микро-80 или ЮТ-88 ; ###

        cmp bp,0c000h
        jb sb0
        cmp bp,0f800h
        jae ppi1_out
        jmp sb00

save_byte endp

save_port proc
        cmp ah,7
        je sp_kbd_out
        cmp byte ptr cs:[cModel],MODEL_M80
        je sp_m80
        cmp ah,0a1h
        je sp_mag_out
        and ah,0f0h
        cmp ah,40h
        je rdu_sel
        ;###
        ret
sp_m80: cmp ah,1
        je sp_mag_out
        ret
save_port endp

rdu_sel:
       push bx
       xor bx,bx
       and al,0fh
       mov byte ptr cs:[utrdpag],0
       je rdusel
       cmp al,0fh
       je rdusel
       test al,1
       mov bx,4
       mov byte ptr cs:[utrdpag],1
       jz rdusel
       test al,2
       mov bx,8
       mov byte ptr cs:[utrdpag],2
       jz rdusel
       test al,4
       mov bx,12
       mov byte ptr cs:[utrdpag],3
       jz rdusel
       mov bx,16
       mov byte ptr cs:[utrdpag],4
rdusel:
       mov bx, word ptr cs:[mempage0+bx+2]
       mov word ptr cs:[utrdseg],bx
       pop bx
       ret

utrdseg dw ?        
utrdpag db ?

sp_kbd_out:
        mov byte ptr cs:[port_a_val],al
        ret

sp_mag_out:
        mov byte ptr cs:[port_c],al
        cmp byte ptr cs:[cModel],MODEL_M80
        je smo1
        cmp byte ptr cs:[f_snd],SND_ON
        jne smo1
        push ax
        mov ah,al
        and ah,1
        rol ah,1
        in al,61h
        and al,0fdh
        or al,ah
        out 61h,al
        pop ax
smo1:   ret

; Порт переключения страниц ПК "Орион"
or_mp_port_out proc
       and ah,3
       mov byte ptr cs:[mem_page_no],ah
       add ah,ah
       add ah,ah
       push bx
       mov bl,ah
       xor bh,bh
       mov bx, word ptr cs:[mempage0+bx+2]
       mov word ptr cs:[mem+2],bx
       mov ds,bx
       pop bx
       ret
or_mp_port_out endp

; Порт управления режимом цвета в Орионе
or_color_mode_out proc
       mov byte ptr cs:[or_color_mode],ah
       cmp ah,4
       je ocmo1
       cmp ah,5
       je ocmo2
;      call draw_scr_or
       ret
ocmo1: push ax
       mov ax, word ptr cs:[or_color4_table1] 
       mov word ptr cs:[or_color4_table],ax
       mov ax, word ptr cs:[or_color4_table1+2]
       mov word ptr cs:[or_color4_table+2],ax
       pop ax
       ret
ocmo2: push ax
       mov ax, word ptr cs:[or_color4_table2]
       mov word ptr cs:[or_color4_table],ax
       mov ax, word ptr cs:[or_color4_table2+2]
       mov word ptr cs:[or_color4_table+2],ax
       pop ax
       ret
or_color_mode_out endp

; Порт переключения экранных областей в Орионе
or_scrpage_out proc
       and ah,3
       mov byte ptr cs:[or_scrpage],ah
       push bx
       mov bl,ah
       xor bh,bh
       xor bx,3
       ror bx,1
       ror bx,1
       mov word ptr cs:[scr_beg],bx
       add bx,2fffh
       mov word ptr cs:[scr_end],bx
       pop bx
;      call draw_scr_or
       ret
or_scrpage_out endp

; Эмуляция ROMDISK'а ПК "Орион"
ppird_out proc
        and bp,3
        cmp bp,2
        jne prdi1
        mov byte ptr cs:[romdisk_addr+1],ah
        ret
prdi1:  cmp bp,1
        jne prdi2
        mov byte ptr cs:[romdisk_addr],ah
prdi2:  ret
ppird_out endp

ppird_in proc
        and bp,3
        cmp bp,0
        jne prdo1
        push es bp
        mov bp, word ptr cs:[romdisk_mem+2]
        mov es,bp
        mov bp, word ptr cs:[romdisk_addr]
        mov ah, byte ptr es:[bp]
        pop bp es
        ret
prdo1:  cmp bp,1
        jne prdo2
        mov ah, byte ptr cs:[romdisk_addr]
        ret
prdo2:  cmp bp,2
        jne prdo3
        mov ah, byte ptr cs:[romdisk_addr+1]
prdo3:  ret
ppird_in endp


; Эмуляция ВГ75
crt_out proc
        test bp,1h
        jz cp1
     cmp byte ptr cs:[crt_mreg],ah  ; Для ускорения/замедления ####
     je co2
       cmp byte ptr cs:[crt_mreg],0e0h
        mov byte ptr cs:[crt_mreg],ah
       jne co1
       ; Устанавливаем видеорежим (было E0 - приостанов)
       cmp byte ptr cs:[dma_mr],0a4h
       jne co1
       call do7 ; чтобы не ломать голову ;) Это работает... Т.ж. пров-ся E0
co1:
       call set_dma_delay
co2:
        cmp ah,0
        jz cp3
        mov byte ptr cs:[crt_mode],0     ; режим управления курсором
        mov byte ptr cs:[cursor_state],0 ; запись в управляющий регистр
        ret
cp1:    cmp byte ptr cs:[crt_mode],0
        jnz cp4                          ; управляющая команда
        cmp byte ptr cs:[cursor_state],0 ; запись в регистр данных
        jne cp2
        mov byte ptr cs:[cur_x],ah       ; запоминаем X и факт его записи
        inc byte ptr cs:[cursor_state]
        ret
cp2:    dec byte ptr cs:[cursor_state]   ; устанавливаем курсор
        mov byte ptr cs:[cur_y],ah
        cmp byte ptr cs:[f_scr],SCR_GRAPH
        je cp8
        push ax
        push bx
        push dx
        mov dl,byte ptr cs:[cur_x]
        mov dh,ah
        mov ah,2
        xor bh,bh
        sub dx,word ptr cs:[cur_corr]    ; коррекция положения курсора
        add dx,word ptr cs:[cur_offs]
        int 10h
        pop dx
        pop bx
        pop ax
cp8:    ret
cp3:    mov byte ptr cs:[crt_mode],1     ; управляющий режим
        mov byte ptr cs:[crt_param_n],0
        ret
cp4:    inc byte ptr cs:[crt_param_n]
        cmp byte ptr cs:[crt_param_n],1
        jnz cp5
        mov byte ptr cs:[crt_param_1],ah
        and ah,7fh
        mov byte ptr cs:[crt_cols],ah
        ret
cp5:    cmp byte ptr cs:[crt_param_n],2
        jnz cp6
        mov byte ptr cs:[crt_param_2],ah
        and ah,3fh
        mov byte ptr cs:[crt_lines],ah
        ret
cp6:    cmp byte ptr cs:[crt_param_n],3
        jnz cp7
        mov byte ptr cs:[crt_param_3],ah
        ret
cp7:    mov byte ptr cs:[crt_param_4],ah
        mov byte ptr cs:[crt_mode],0
        ret
crt_out endp

; Производит настройку экрана в соответствии с запомненными параметрами
process_crt proc
        cmp byte ptr cs:[cModel],MODEL_S
        je pc4
        cmp byte ptr cs:[cModel],MODEL_O
        je pc4
        push bp
        mov ah,byte ptr cs:[crt_param_1]
        and ah,7fh
        mov byte ptr cs:[crt_cols],ah
        mov ah,byte ptr cs:[crt_param_2]
        and ah,3fh
        mov byte ptr cs:[crt_lines],ah
        call set_dma_delay
pc2:    call do7
        pop bp
pc4:    ret
process_crt endp

set_dma_delay proc
        cmp byte ptr cs:[dma_mr],80h
        je sdd1
        cmp byte ptr cs:[dma_mr],28h
        jne sdd3
        call set_delay_w_dma28
        jmp sdd2
sdd3:   cmp byte ptr cs:[crt_mreg],0e0h
        je sdd1
        call set_delay_w_dma
        jmp sdd2
sdd1:   call set_delay_wo_dma
sdd2:   ret
set_dma_delay endp

cur_xy:
cur_x:
db 0
cur_y:
db 0

; Эмуляция PPI
ppi1_out proc

        cmp byte ptr cs:[cModel],MODEL_P
        jne ppim_1

        cmp bp,0d903h
        cmp bp,0d902h
        je ppi1_c
        cmp bp,0d903h
        je ppi1_r
        cmp bp,0d900h
        je ppi1_a
        ret

ppim_1:
        cmp byte ptr cs:[cModel],MODEL_M
        jne ppim_2

        and bp,0c003h
        cmp bp,0c002h
        je ppi1_c
;       cmp bp,0c003h
;       je ppi1_r
        cmp bp,0c001h
        je ppi1_a
        ret

ppim_2:
        cmp byte ptr cs:[cModel],MODEL_R
        jne ppim_3

        and bp,3
        cmp bp,0002h
        je ppi1_c
        cmp bp,0000h
        je ppi1_a
        ret

ppim_3:
        cmp byte ptr cs:[cModel],MODEL_A
        jne ppim_7

        and bp,0ed03h
        cmp bp,0ed02h
        je ppi1_c
        cmp bp,0ed00h
        je ppi1_a
        ret

ppim_7:
        cmp byte ptr cs:[cModel],MODEL_S
        jne ppim_8

        and bp,0f803h
        cmp bp,0f802h
        je ppi1_c
        cmp bp,0f803h
        je ppi1_r
        cmp bp,0f801h
        je ppi1_b_out_s
        mov byte ptr cs:[port_ac_s],ah
        ret

ppim_8:
        and bp,3
        cmp bp,02h
        je ppi1_c
        cmp bp,00h
        je ppi1_a
        ret

ppi1_b_out_s:
        push ax
        and ah,0fch
        and byte ptr cs:[ctrl_keys_s],3
        or byte ptr cs:[ctrl_keys_s],ah
        pop ax
        ret

port_ac_s dw ?

; Обрабатывает состояние порта C ППА
process_port_c proc
        push ax
        mov ah, byte ptr cs:[port_c]
        jmp kpc4
process_port_c endp


; запись в порт C ППА ВВ55
; бит 1 - управление динамиком (0-писк)
ppi1_c:
        mov byte ptr cs:[port_c],ah
        push ax
kpc4:

        cmp byte ptr cs:[cModel],MODEL_P
        jne ppim_4

        in al,61h
        test ah,2
        jnz kpc1
        or al,03h
       and al,byte ptr cs:[snd61_and]
        jmp kpc2
kpc1:   and al,0fch
kpc2:   out 61h,al
        jmp ppim_5

ppim_4:
        cmp byte ptr cs:[cModel],MODEL_M
        jne ppim_6

        and ah,6
        mov al,ah
        and al,4
        shr al,1
        and al,ah
        shr al,1
        or ah,al
        in al,61h
        and al,0fch
        or al,ah
       and al,byte ptr cs:[snd61_and]
        out 61h,al
;        in al,61h
;        test ah,2
;        jz kpc1_m
;        or al,03h
;        jmp kpc2_m
;kpc1_m:   and al,0fch
;kpc2_m:   out 61h,al
;;;        cmp byte ptr cs:[f_vid],2
;;;        jne kpc3
        jmp ppim_5

ppim_6:  cmp byte ptr cs:[cModel],MODEL_S
        jne ppim_5

        mov byte ptr cs:[port_c],ah

        push ax
        and ah,0fh
        mov byte ptr cs:[port_ac_s+1],ah 
        pop ax

        mov byte ptr cs:[snd_state],ah
        in al,61h
        and al,0fch
        test ah,20h
        jz kpc1_s
        or al,02h
       and al,byte ptr cs:[snd61_and]
kpc1_s: out 61h,al
; and ah,20h
; push dx
; mov dx,22ch
; mov al,10h
; out dx,al
; mov al,ah
; out dx,al
; pop dx

        ; Цвет
        push bx
        push ax
        lea bx, color_table
        mov al,byte ptr cs:[port_c]
        rol al,1
        rol al,1
        and al,3
        xor ah,ah
        add bx,ax
        mov al,byte ptr cs:[bx]
        mov byte ptr cs:[cur_color_code],al
        pop ax
        pop bx

; 9 цветов
;   push ax
;   mov al,byte ptr cs:[port_c]
;   rol al,1
;   rol al,1
;   rol al,1
;   and al,6
;   mov ah,al
;   mov al,byte ptr cs:[port_c]
;   rol al,1
;   rol al,1
;   rol al,1
;   rol al,1
;   and al,1
;   or al,ah
;   mov byte ptr cs:[cur_color_code],al
;   pop ax

ppim_5:
        and ah,08h
        ror ah,1
        and byte ptr cs:[led_state],0fbh
        or byte ptr cs:[led_state],ah
;       call light_led

kpc3:   pop ax
kpc5:   ret

; запись в регистр управляющего слова (РУС) ППА
; отслеживаем только звук (см. выше)

        cmp byte ptr cs:[cModel],MODEL_P
        jne kpc4

ppi1_r:
        cmp ah,80h
        jb kpc6
        ; ###########?
        mov byte ptr cs:[port_c],0
        mov byte ptr cs:[port_a_val],0
        mov word ptr cs:[port_ac_s],0
        and byte ptr cs:[ctrl_keys_s],3

        ; ###########?
        mov byte ptr cs:[cur_color_code],00h
        jmp kpc5
kpc6:
        push ax
        push cx
        mov cl,ah
        ror cl,1
        and cl,07h;03h
        mov al,0feh
        rol al,cl
        and byte ptr cs:[port_c],al
        and ah,1
        rol ah,cl
        or byte ptr cs:[port_c],ah
        mov ah, byte ptr cs:[port_c]
        pop cx
        jmp kpc4

ppi1_a:
        mov byte ptr cs:[port_a_val],ah
        ret
ppi1_out endp

port_c db 0
port_a_val db 0ffh ; значение, записанное в порт A ППА (B для Микроши)

; Эмуляция PIT
pit_out proc
        cmp byte ptr cs:[cModel],MODEL_M
        jne pitm_1

        cmp byte ptr cs:[f_snd],SND_SB
        je pitm_2

        cmp bp,0d803h
        jne pp1
        push ax
        mov al,0b6h
        out 43h,al
        pop ax
        jmp pitm_2
pp1:    push ax
        mov al,ah
        out 42h,al
        mov al, byte ptr cs:[pit_k2+1]
        mov byte ptr cs:[pit_k2],al
        mov byte ptr cs:[pit_k2+1],ah
        pop ax
        jmp pitm_2

pitm_1:
        cmp byte ptr cs:[cModel],MODEL_R
        je pitm_2
        cmp byte ptr cs:[cModel],MODEL_A
        jne pp2_a ; ret
pitm_2:
        and bp,3
        cmp bp,3h
        jne pp1_a
        push ax
        and ah,0c0h
        rol ah,1
        rol ah,1
        cmp ah,3
        je pp3_a
        mov al,ah
        xor ah,ah
        mov bp,ax
        pop ax
        push ax
      test ah,30h ; Защелкивание
      jz pitm_5
        mov byte ptr cs:[pit_mode0+bp],ah
        mov byte ptr cs:[pit_ld0+bp],0 ; not loaded
pitm_4:
        add bp,bp
        mov word ptr cs:[pit_k0+bp],1
        mov word ptr cs:[pit_cnt0+bp],0
pitm_5:
        mov word ptr cs:[pit_read_byte_cnt0+bp],0
;       test ah,0eh
;       jnz pitm_3
;       mov word ptr cs:[pit_k0+bp],0 ; Режим 0
;pitm_3:
pp3_a:  pop ax
pp2_a:  ret

pp1_a:
        push bp bx cx
        and bp,0003h
        mov bx,bp
        push bx
        mov cl, byte ptr cs:[pit_mode0+bx]
        add bx,bx
        add bx,offset pit_k0
        and cl,30h

        cmp cl,10h
        jne pp4_a
        mov byte ptr cs:[bx],ah ; мл. байт
        mov byte ptr cs:[pit_ld0+bp],1 ; loaded
        jmp pp5_a
pp4_a:  cmp cl,20h
        jne pp6_a
        mov byte ptr cs:[bx+1],ah ; ст. байт
        mov byte ptr cs:[pit_ld0+bp],1 ; loaded
        jmp pp5_a
pp6_a:  ;cmp cl,0 ; защелкивание - ничего не пишем
        ;je pp5_a
        ; мл, старший байты...
        push bp
        add bp,bp
        add bx, word ptr cs:[bp+pit_read_byte_cnt0]
        xor word ptr cs:[bp+pit_read_byte_cnt0],1
        mov byte ptr cs:[bx],ah
        mov bx, word ptr cs:[pit_read_byte_cnt0+bp]
        xor bx,1
        pop bp
        mov byte ptr cs:[pit_ld0+bp],bl ; loaded or not
;  sub bx, offset pit_k0
;  add bx, offset pit_cnt0
;  mov byte ptr cs:[bx],ah

;     push ax
;     mov al,byte ptr cs:[bx+1]
;     mov byte ptr cs:[bx],al
;     mov byte ptr cs:[bx+1],ah
;     pop ax

pp5_a:
        pop bx
        ; Вставить сюда проверку на режим 0 вместо всего этого ####
        cmp byte ptr cs:[cModel],MODEL_R
        jne pp1_a_1
        cmp bp,2
        jne pp1_a_1
        mov bx, word ptr cs:[pit_k2]
        mov word ptr cs:[pit_cnt2],bx
pp1_a_1:pop cx bx bp
        ret
pit_out endp

process_pit proc
        cmp byte ptr cs:[cModel],MODEL_M
        jne ppi2
        push ax
        mov al,0b6h
        out 43h,al
        pop ax
        cmp word ptr cs:[pit_k2],1
        jne ppi1
ppi2:   ret
ppi1:   push ax
        mov ax, word ptr cs:[pit_k2]
        out 42h,al
        jmp short $+2
        mov al,ah
        out 42h,al
        pop ax
        ret
process_pit endp

ppi2_out:
        cmp byte ptr cs:[cModel],MODEL_M
        jne ppi2_1
        and bp,3
        cmp bp,1
        jne ppi2_1
        push ax
        mov al,byte ptr cs:[mikr_symg]
        xor al,ah
        mov byte ptr cs:[mikr_symg],ah
        and byte ptr cs:[mikr_symg],80h
        test al,80h
        pop ax
        je ppi2_1
        mov byte ptr cs:[f_refr_txt_scr],1
ppi2_1:
        ret

dma_out proc
        and bp,000fh
        cmp bp,4
        jne do1
        push cx
        mov cl,8
        ror word ptr cs:[dma_begadr],cl
        pop cx
        mov byte ptr cs:[dma_begadr+1],ah
        ret
do1:    cmp bp,5
        jne do2
        push cx
        mov cl,8
        ror word ptr cs:[dma_len],cl
        pop cx
        mov byte ptr cs:[dma_len+1],ah
        ret
do2:    cmp bp,8
        jne do3
        cmp ah, byte ptr cs:[dma_mr]
        je do3
        mov byte ptr cs:[dma_mr],ah

        call set_dma_delay
;        cmp ah,80h
;        je do5
;        cmp ah,28h
;        jne do8
;        call set_delay_w_dma28
;        jmp do6
;do8:    cmp byte ptr cs:[crt_mreg],0e0h
;        je do5
;        call set_delay_w_dma
;        jmp do6
;do5:    call set_delay_wo_dma

do6:    test ah,4
        jz do3
        and word ptr cs:[dma_len],3fffh
        push ax
        mov ax,word ptr cs:[dma_begadr]
        mov word ptr cs:[sh_scrbeg],ax
        mov ax,word ptr cs:[dma_len]
        inc ax
        mov word ptr cs:[sh_scrlen],ax
        mov al,byte ptr cs:[crt_lines]
        inc al
        mov byte ptr cs:[sh_height],al
        mov al,byte ptr cs:[crt_cols]
        inc al
        mov byte ptr cs:[sh_width],al
; Делим длину экрана на количество столбцов
        push cx
        mov cl,al
        mov ax,word ptr cs:[sh_scrlen]
        div cl
        pop cx
; Сравниваем результат с числом строк и берем меньшее
        cmp al,byte ptr cs:[sh_height]
        jae do4
        mov byte ptr cs:[sh_height],al
do4:    pop ax
; refresh screen
do7:    cmp byte ptr cs:[f_scr],MEM_RW
        jne do3
        cmp byte ptr cs:[crt_mreg],0e0h
        je do3
        push ax
        push bx
        push cx
        push dx
        push si
        push di

     xor bx,bx
     xor dx,dx

     mov ax, word ptr cs:[dma_begadr]
     mov cx,ax
     xor ax, word ptr cs:[dma_begadr_old]
     or bx,ax
     mov word ptr cs:[dma_begadr_old],cx

     mov ax, word ptr cs:[dma_len]
     mov cx,ax
     xor ax, word ptr cs:[dma_len_old]
     or dx,ax
     mov word ptr cs:[dma_len_old],cx

     mov ax, word ptr cs:[crt_param_1]
     mov cx,ax
     xor ax, word ptr cs:[crt_param_1_old]
     or dx,ax
     mov word ptr cs:[crt_param_1_old],cx

     mov ax, word ptr cs:[crt_param_3]
     mov cx,ax
     xor ax, word ptr cs:[crt_param_3_old]
     or dx,ax
     mov word ptr cs:[crt_param_3_old],cx

     test dx,dx
     jz do9

     call set_video_auto
     jmp do10

do9:
     test bx,bx
     jz do8

do10:
        call refresh_scr
do8:
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
do3:    ret
dma_out endp

crt_param_n db 0
crt_mode db 0 ; 0-курсор, 1-управл.
crt_lines db ?
crt_cols db ?
dma_begadr dw ?
dma_len dw ?

; Вызывается при попытке чтения из памяти
; BP-адрес Возврат : AH-значение

load_byte proc

        cmp byte ptr cs:[cModel],MODEL_M80
        je lb_m80u
        cmp byte ptr cs:[cModel],MODEL_U
        je lb_u

        cmp byte ptr cs:[cModel],MODEL_P
        jne lbm_1

        cmp bp,0d800h
        jb lb0
        cmp bp,0d900h
        jae lb3_p
        jmp crt_in
lb3_p:  cmp bp,0da00h
        jae lb4_p
        jmp ppi1_in
lb4_p:  cmp bp,0db00h
        jae lb5_p
        ret
lb5_p:  cmp bp,0dc00h
        jae lb6_p
        jmp dma_in
lb6_p:  cmp bp,0f000h
        jae lb0
        mov ah,0ffh
        ret

lbm_1:
        cmp byte ptr cs:[cModel],MODEL_R
        jne lbm_2

        cmp bp,8000h
        jb lb0
        cmp bp,0a000h
        jae lb3_r
        jmp ppi1_in
lb3_r:  cmp bp,0c000h
        jae lb4_r
        cmp bp,0a000h
        je ppi2_in
        cmp bp,0a001h
        je no_in
        cmp bp,0a002h
        je no_in
        cmp bp,0a003h
        je no_in
        jmp pit_in
lb4_r:  cmp bp,0e000h
        jae lb0
        jmp crt_in

lbm_2:
        cmp byte ptr cs:[cModel],MODEL_M
        jne lbm_3

        cmp bp,8000h
        jb lb0
        cmp bp,0c000h
        jae lb3_m
        ret
lb3_m:  cmp bp,0c800h
        jae lb4_m
        jmp ppi1_in
lb4_m:  cmp bp,0d000h
        jae lb5_m
        jmp ppi2_in
lb5_m:  cmp bp,0d800h
        jae lb6_m
        jmp crt_in
lb6_m:  cmp bp,0e000h
        jae lb7_m
        jmp pit_in
lb7_m:  cmp bp,0f800h
        jae lb0
lb8_m:  jmp dma_in

lbm_3:
        cmp byte ptr cs:[cModel],MODEL_A
        jne lbm_4

        cmp bp,0ec00h
        jb lb0
        cmp bp,0ed00h
        jae lb3_a
        jmp pit_in
lb3_a:  cmp bp,0ee00h
        jae lb4_a
        jmp ppi1_in
lb4_a:  cmp bp,0ef00h
        jae lb5_a
        jmp ppi2_in
lb5_a:  cmp bp,0f000h
        jae lb0
        jmp crt_in

lbm_4:
        cmp byte ptr cs:[cModel],MODEL_S
        jne lbm_5

        cmp bp,0f800h
        jae ppi1_in
        jmp lb0

lbm_5:  ; Орион
        cmp bp,0f000h
        jae lb_or_1
        push ax
        mov ax, word ptr cs:[mem+2]
        mov ds,ax
        pop ax
        jmp lb0
lb_or_1:cmp bp,0f400h
        jb lbm5_1
        cmp bp,0f500h
        jb ppi1_in
        cmp bp,0f600h
        jb ppird_in
        cmp bp,0f700h
        jb lbm5_1 ; ####
        cmp bp,0f800h
        jb disk_in
lbm5_1: ; Попали в системное ОЗУ "Ориона"
        push ax
        mov ax, word ptr cs:[mempage0+2]
        mov ds,ax
        pop ax
        jmp lb0

lb0:    mov byte ptr ah,ds:[bp];                ; читаем
lb00:   ret

lb_u:
        cmp byte ptr cs:[utrdpag],0
        jz lb_m80u
        push ax
        mov al, byte ptr ds:[si]
        and al,0cfh
        cmp al,0c1h ; pop ?
        pop ax
        jne lb_m80u

        ; Обращение к RAMDISK'у
        push bx es
        mov bx, word ptr cs:[utrdseg]
        mov es,bx
        mov ah,byte ptr es:[bp]
        pop es bx
        ret

lb_m80u:
        cmp bp,0e000h
        jb lb0
        cmp bp,0f000h
        jae lb0
        cmp byte ptr cs:[cModel],MODEL_U
        je lb0
        mov ah,0ffh
        jmp lb00

load_byte endp

load_port proc
        cmp ah,6
        je lp_kbd_in
        cmp ah,7
        je lp_kbdout_in
        cmp ah,5
        je lp_kbdc_in
        cmp byte ptr cs:[cModel],MODEL_M80
        je lp_m80
        cmp ah,0a1h
        je lp_mag_in
        ret
lp_m80: 
        cmp ah,1h
        je lp_mag_in
        ret
load_port endp

lp_kbdc_in:
        mov al,byte ptr cs:[ctrl_keys]
        and al,07h
        ret

lp_kbd_in:
        push cx ax bx
        mov bx, offset key_bytes
        mov cx,8
        mov ah,07fh
        mov al,byte ptr cs:[port_a_val]
lki1:   rcr al,1
        jc lki2
        and ah, byte ptr cs:[bx]
lki2:   inc bx
        loop lki1
        pop bx
        mov cl,ah
        pop ax
        mov al,cl
        pop cx
        ret

lp_kbdout_in:
        mov al,byte ptr cs:[port_a_val]
        ret

lp_mag_in:
        ;###

crt_in:
        xor ah,ah
        cmp byte ptr cs:[vretr_cnt],0
        jz ci_1
        mov ah,20h
ci_1:   ret
dma_in:
ppi2_in2:
no_in:
        mov ah,0ffh
        ret

pit_in:
        and bp,3
        cmp bp,3
        je no_in

;        add bp,bp
;        add bp, word ptr cs:[pit_read_byte_cnt0]
;        xor word ptr cs:[pit_read_byte_cnt0],1
;        mov ah, byte ptr cs:[pit_cnt0+bp]
;        ret

        push bp bx ax
        and bp,0003h
        mov bx,bp
        add bx,bx
        add bx,offset pit_cnt0
        mov al, byte ptr cs:[pit_mode0+bp]
        and al,30h
        cmp al,10h
        jne pti1
        mov bl, byte ptr cs:[bx] ; мл. байт
        jmp pti2
pti1:
        cmp al,20h
        jne pti3
        mov bl, byte ptr cs:[bx+1] ; ст. байт
        jmp pti2
pti3:
        add bp,bp
        add bx, word ptr cs:[bp + offset pit_read_byte_cnt0]
        xor word ptr cs:[bp + offset pit_read_byte_cnt0],1
        mov bl, byte ptr cs:[bx]
pti2:
        pop ax
        mov ah,bl
        pop bx bp
        ret

ppi2_in:
        cmp byte ptr cs:[cModel],MODEL_M
        jne ppi2_in3
        and bp,3
        cmp bp,1
        jne no_in
        mov ah,byte ptr cs:[mikr_symg]
        ret
ppi2_in3:
        cmp byte ptr cs:[cModel],MODEL_R
        jne ppi2_in2
        mov ah, byte ptr cs:[joy_state]
        ret

ppi1_in proc
        push cx
        push ax
        mov ax,bp
        and al,03h

        cmp byte ptr cs:[cModel],MODEL_S
        je ppi1_s

        cmp al,byte ptr cs:[keybin_port]

        jne ppi1_1
        push bx
        mov bx, offset key_bytes
        mov cx,8
        mov ah,0ffh
        mov al,byte ptr cs:[port_a_val]
ppi1_2: rcr al,1
        jc ppi1_3
        and ah, byte ptr cs:[bx]
ppi1_3: inc bx
        loop ppi1_2
        pop bx
ppi1_5: mov cl,ah
        pop ax
        mov ah,cl
        pop cx
        ret
ppi1_1: cmp al,2
        je ppi1_4
        mov ah,byte ptr cs:[port_a_val]
        jmp ppi1_5
ppi1_4: mov ah,byte ptr cs:[ctrl_keys]
        and ah,0f0h
        mov al,byte ptr cs:[port_c]
        and al,0fh
        or ah,al
        jmp ppi1_5

ppi1_s:
        cmp al,1
        jne ppi1_1_s
        
        push bx
        push bp
        mov bx, offset key_bytes_s
        xor al,al
        mov cx,6
ppi1_s3:ror al,1
        mov bp, word ptr cs:[port_ac_s]
        or bp, word ptr cs:[bx]
        cmp bp,0fffh
        jne ppi1_s4
        or al,80h
ppi1_s4:inc bx
        inc bx
        loop ppi1_s3
        pop bp
        pop bx
        mov cl, byte ptr cs:[ctrl_keys_s]
        and cl,3
        or cl,al
        pop ax
        mov ah,cl
        xor ah,1
        pop cx
;        pop ax
;        mov ah, byte ptr cs:[ctrl_keys_s]
;        pop cx
        ret
ppi1_1_s: call ppi1_s_or
        cmp al,0
        jne ppi1_s2
        pop ax
        mov ah,cl
        pop cx
        ret
ppi1_s2:mov al,byte ptr cs:[port_c]
        and al,0f0h
        or ch,al
        pop ax
        mov ah,ch
        pop cx
        ret

ppi1_s_or: 
        push ax
        push bx
        push dx
        mov bx, offset key_bytes_s
        mov cx,6
        mov dx,0fffh
        mov al,byte ptr cs:[ctrl_keys_s]
        rcr al,1
        rcr al,1
ppi1s_2:rcr al,1
        jc ppi1s_3
        and dx, word ptr cs:[bx]
ppi1s_3:inc bx
        inc bx
        loop ppi1s_2
        mov cx,dx
        pop dx
        pop bx
        pop ax
        ret

ppi1_in endp

write_byte_spec dw ?
write_byte_orion dw ?

write_byte_spec_640 proc
        push es
        push bx
        push ax

        ; Color
        push dx
        mov dx,3ceh
        mov al,01h
        mov ah, byte ptr cs:[cur_color_code]
        out dx,ax
        pop dx

mov ax, word ptr cs:[color_mem+2]
mov es,ax
mov al, byte ptr cs:[cur_color_code]
mov byte ptr es:[bp-9000h],al

        mov ax,0a000h
        mov es,ax

        mov ax,-9000h
        add ax,bp
        mov bl,ah
        xor bh,bh
        mov ah,80
        mul ah
        add bx,ax
        add bx,8976
        pop ax
        mov es:[bx],ah

        pop bx
        pop es
        ret
write_byte_spec_640 endp

write_byte_spec_800 proc
        push es
        push bp
        push cx
        push bx
        push ax

        ; Color
        push dx
        mov dx,3ceh
        mov al,01h
        mov ah, byte ptr cs:[cur_color_code]
        out dx,ax
        pop dx

mov ax, word ptr cs:[color_mem+2]
mov es,ax
mov al, byte ptr cs:[cur_color_code]
mov byte ptr es:[bp-9000h],al

        mov ax,0a000h
        mov es,ax

        mov ax,-9000h
        add ax,bp
        mov bl,ah
        xor bh,bh
        mov ah,100
        mul ah
        add bx,ax
        add bx,bx
        add bx,word ptr cs:[vmem_off]; 4402
        mov bp,bx

        pop ax
        push ax
        xor bx,bx
        mov al,ah
        mov cx,8
wbc1:   rcl al,1
        lahf
        rcl bx,1
        sahf
        rcl bx,1
        loop wbc1
        xchg bh,bl
        mov word ptr es:[bp],bx
        mov word ptr es:[bp+100],bx

        pop ax
        pop bx
        pop cx
        pop bp
        pop es
        ret
write_byte_spec_800 endp

; bp - адрес, ah-байт, al-цвет
write_byte_orion_640 proc
        test byte ptr cs:[or_color_mode],06h
        jnz wbo2
        mov al,02h
        test byte ptr cs:[or_color_mode],1
        jz wbo2
        mov al,1eh
wbo2:
        push es
        push cx
        push bx
        push ax

        mov cx,ax
        mov ax,0a000h
        mov es,ax

        mov ax,bp
        sub ax, word ptr cs:[scr_beg]
        mov bl,ah
        xor bh,bh
        mov ah,80
        mul ah
        add bx,ax
        add bx,8976
        pop ax

        cmp byte ptr cs:[or_color_mode],4
        jz wbo640_4
        cmp byte ptr cs:[or_color_mode],5
        jz wbo640_4

; 16 цветов
;        mov es:[bx],ah
        push dx ax
        mov dx,3ceh
        mov ah,cl
        shr ah,4
        xor ah,0fh
        mov al,01h
        out dx,ax
        mov byte ptr es:[bx],0ffh
        mov al, byte ptr es:[bx]
        mov al,8
        mov ah,ch
        out dx,ax
        mov ah,cl
        and ah,0fh
        xor ah,0fh
        mov al,01h
        out dx,ax
        mov byte ptr es:[bx],0ffh
        mov ax,0ff08h
        out dx,ax
        pop ax dx
        jmp wbo640_ret

; 4 цвета
wbo640_4:
;        mov es:[bx],ah
        push dx ax bx bp
        mov bp,bx
        mov dx,3ceh
        mov bh,cl
        mov bl,ch
        mov cx,8
        mov ah,80h
wbo4:   push bp
        push ax
        xor bp,bp
        rcl bh,1
        rcl bp,1
        rcl bl,1
        rcl bp,1
        mov ah, byte ptr cs:[bp+or_color4_table]
        mov al,1
        out dx,ax
        pop ax
        pop bp
        mov al,08h
        out dx,ax
        rcr ah,1

        mov al, byte ptr es:[bp]
        mov byte ptr es:[bp],0ffh

        loop wbo4

        mov ax,0ff08h
        out dx,ax
        pop bp bx ax dx

wbo640_ret:      
        pop bx
        pop cx
        pop es
        ret
write_byte_orion_640 endp

; bp - адрес, ah-байт, al-цвет
write_byte_orion_800 proc
        test byte ptr cs:[or_color_mode],06h
        jnz wbo3
        mov al,02h
        test byte ptr cs:[or_color_mode],1
        jz wbo3
        mov al,1eh

wbo3:
        push es
        push bp
        push cx
        push bx
        push ax

        mov ax,0a000h
        mov es,ax

        mov ax,bp
        sub ax, word ptr cs:[scr_beg]
        mov bl,ah
        xor bh,bh
        mov ah,100
        mul ah
        add bx,ax
        add bx,bx
        add bx,word ptr cs:[vmem_off]; 4402
        mov bp,bx

        pop ax
       push ax
       mov cx,ax

        cmp byte ptr cs:[or_color_mode],4
        jz wbo800_4
        cmp byte ptr cs:[or_color_mode],5
        jz wbo800_4

       push cx
        xor bx,bx
        mov al,ah
        mov cx,8
wbo1:   rcl al,1
        lahf
        rcl bx,1
        sahf
        rcl bx,1
        loop wbo1
        xchg bh,bl
       pop cx

; 16 цветов
;        mov word ptr es:[bp],bx
;        mov word ptr es:[bp+100],bx
        push dx ax
        mov dx,3ceh
        mov ah,cl
        shr ah,4
        xor ah,0fh
        mov al,01h
        out dx,ax
        mov word ptr es:[bp],0ffffh
        mov word ptr es:[bp+100],0ffffh
;        mov byte ptr es:[bx],0ffh
        mov al, byte ptr es:[bp]

        and cl,0fh
        xor cl,0fh

        mov al,8
        mov ah,bl
        out dx,ax
        mov ah,cl
        mov al,01h
        out dx,ax
        mov byte ptr es:[bp],0ffh
        mov byte ptr es:[bp+100],0ffh

        mov al,8
        mov ah,bh
        out dx,ax
        mov ah,cl
        mov al,01h
        out dx,ax
        mov byte ptr es:[bp+1],0ffh
        mov byte ptr es:[bp+101],0ffh

        mov ax,0ff08h
        out dx,ax
        pop ax dx
        jmp wbo800_ret

; 4 цвета
wbo800_4:
;        mov word ptr es:[bp],bx
;        mov word ptr es:[bp+100],bx
        push dx ax bp bx
        mov dx,3ceh
        mov bh,cl
        mov bl,ch

        call wbo5
        inc bp
        call wbo5

        mov ax,0ff08h
        out dx,ax
        pop bx bp ax dx

wbo800_ret:
        pop ax
        pop bx
        pop cx
        pop bp
        pop es
        ret

wbo5:
        mov cx,4
        mov ah,0c0h
wbo6:   push bp
        push ax
        xor bp,bp
        rcl bh,1
        rcl bp,1
        rcl bl,1
        rcl bp,1
        mov ah, byte ptr cs:[bp+or_color4_table]
        mov al,1
        out dx,ax
        pop ax
        pop bp
        mov al,08h
        out dx,ax
        rcr ah,1
        rcr ah,1

        mov al, byte ptr es:[bp]
        mov byte ptr es:[bp],0ffh
        mov byte ptr es:[bp+100],0ffh

        loop wbo6
        ret
write_byte_orion_800 endp


; Вызывается каждые 1/44100 с или 50 мс в зависимости от режима.
; Рассчитывает следующие значения счетчиков и программирует таймер PC
calc_pit proc
        cmp byte ptr cs:[vretr_cnt],0
        jz cpt0
        dec byte ptr cs:[vretr_cnt]
cpt0:
     
        cmp byte ptr cs:[cModel],MODEL_A
        jne cpt4
        push ax bx

        mov byte ptr cs:[pit_val0],0
        cmp byte ptr cs:[pit_ld0],0
        jz @a0
        mov ax,word ptr cs:[pit_cnt0]
        mov bx,word ptr cs:[pit_k0]
        call cpt1
        mov cs:[pit_val0],bl
        mov word ptr cs:[pit_cnt0],ax
@a0:
        mov byte ptr cs:[pit_val1],0
        cmp byte ptr cs:[pit_ld1],0
        jz @a1
        mov ax,word ptr cs:[pit_cnt1]
        mov bx,word ptr cs:[pit_k1]
        call cpt1
        mov cs:[pit_val1],bl
        mov word ptr cs:[pit_cnt1],ax
@a1:
        mov byte ptr cs:[pit_val2],0
        cmp byte ptr cs:[pit_ld2],0
        jz @a2
        mov ax,word ptr cs:[pit_cnt2]
        mov bx,word ptr cs:[pit_k2]
        call cpt1
        mov cs:[pit_val2],bl
        mov word ptr cs:[pit_cnt2],ax
@a2:
        cmp byte ptr cs:[f_snd],SND_SB
        je cpt6

        mov ah,byte ptr cs:[pit_val0]
        or ah,byte ptr cs:[pit_val1]
        or ah,byte ptr cs:[pit_val2]

        and ah,2
        in al,61h
        and al,0fch
        or al,ah
        and al,byte ptr cs:[snd61_and]
        out 61h,al
        jmp cpt5

cpt6:
        mov al,byte ptr cs:[pit_val0]
        and al,1fh
        mov ah,byte ptr cs:[pit_val1]
        and ah,1fh
        add al,ah
        mov ah,byte ptr cs:[pit_val2]
        and ah,1fh
        add al,ah
        mov ah,byte ptr cs:[port_c]
        and ah,1
        ror ah,1
        ror ah,1
        ror ah,1
        add al,ah
        xor ah,ah
cpt7:
       cmp byte ptr cs:[f_tape], TAPE_SBIN
       je cpt13

        push ds cx dx
        push ax
        mov ax,cs
        mov ds,ax
        call PlayByteNoWait
        pop ax
        pop dx cx ds
        jmp cpt5

 cpt13:
       push ds cx dx
       push ax
       mov ax,cs
       mov ds,ax
       call ReadByteNoWait
       cmp byte ptr cs:[cModel],MODEL_P
       jne cpt14
       and byte ptr cs:[ctrl_keys],07fh   ; ######
       ror al,1
       or byte ptr cs:[ctrl_keys],al
       jmp cpt15
cpt14:
       cmp byte ptr cs:[cModel],MODEL_S
       je cpt16
       and byte ptr cs:[ctrl_keys],0efh   ; ######
       rol al,1
       rol al,1
       rol al,1
       rol al,1
       or byte ptr cs:[ctrl_keys],al
       jmp cpt15
cpt16:
       and byte ptr cs:[ctrl_keys_s],0feh   ; ######
       or byte ptr cs:[ctrl_keys_s],al
cpt15:
       pop ax
       pop dx cx ds

cpt5:   pop bx ax
        ret

; Декремент счетчика
; Вх:  AX - тек. знач. счетчика
;      BX - нач. знач. счетчика
; Вых: BL=0/FF, в зависимости от полупериода
;      AX - измененное знач. счетчика
cpt1:
        cmp bx,3
        jbe cpt2

        sub ax,word ptr cs:[ticks_per_calc]
        jnc cpt3
        add ax,bx
cpt3:   shr bx,1
        cmp ax,bx
        mov bl,0
        jb cpt_e
        mov bl,0ffh
cpt_e:  ret
cpt2:   xor bl,bl
        ret

; Декремент счетчика без анализа полупериодов
; Вх:  AX - тек. знач. счетчика
;      BX - нач. знач. счетчика
; Вых: BX= кол-во переходов через 0
;      AX - измененное знач. счетчика
cpt1_1:
        push cx
        xor cx,cx
        cmp bx,3
        jbe cpt2_1
        sub ax,word ptr cs:[ticks_per_calc]
        jnc cpt2_1
cpt3_1: inc cx
        add ax,bx
        jc cpt2_1
        jmp cpt3_1
cpt2_1: mov bx,cx
        pop cx
        ret

cpt4:
        cmp byte ptr cs:[cModel],MODEL_M
        jne cpt9

        push ax bx

        cmp byte ptr cs:[pit_ld0],0
        jz @m0
        mov ax,word ptr cs:[pit_cnt0]
        mov bx,word ptr cs:[pit_k0]
        call cpt1
        mov word ptr cs:[pit_cnt0],ax
@m0:
        cmp byte ptr cs:[pit_ld1],0
        jz @m1
        mov ax,word ptr cs:[pit_cnt1]
        mov bx,word ptr cs:[pit_k1]
        call cpt1
        mov word ptr cs:[pit_cnt1],ax
@m1:
        mov byte ptr cs:[pit_val2],0
        cmp byte ptr cs:[pit_ld2],0
        jz @m2
        mov ax,word ptr cs:[pit_cnt2]
        mov bx,word ptr cs:[pit_k2]
        call cpt1
        mov cs:[pit_val2],bl
        mov word ptr cs:[pit_cnt2],ax
@m2:
        cmp byte ptr cs:[f_snd],SND_SB
        jne cpt5

        mov al,byte ptr cs:[pit_val2]
        and al,1fh
        cmp byte ptr cs:[f_tape],TAPE_SBOUT
        jne cpt17
        xor al,al ; для вывода на магнитофон отключаем выход таймера
cpt17:
        mov ah,byte ptr cs:[port_c]
;        test ah,4
;        jnz cpt10
;        and ah,2
;        ror ah,1
;        ror ah,1
;        ror ah,1
;        ror ah,1
        test ah,2
        jnz cpt10
        and ah,4
        rol ah,1
        rol ah,1
        rol ah,1

        mov al,ah
;        xor ah,ah
;        jmp cpt7
cpt10:  mov ah,byte ptr cs:[port_c]
        and ah,1
        ror ah,1
        ror ah,1
        ror ah,1
        add al,ah
        xor ah,ah
        jmp cpt7

cpt9:
        cmp byte ptr cs:[cModel],MODEL_R
        jne cpt9_2

        push ax bx

        mov byte ptr cs:[pit_val0],0
        cmp byte ptr cs:[pit_ld0],0
        jz @r0
        mov ax,word ptr cs:[pit_cnt0]
        mov bx,word ptr cs:[pit_k0]
        call cpt1
        mov cs:[pit_val0],bl
        mov word ptr cs:[pit_cnt0],ax
@r0:
        cmp byte ptr cs:[pit_ld1],0
        mov bx,0
        jz @r1
        mov ax,word ptr cs:[pit_cnt1]
        mov bx,word ptr cs:[pit_k1]
        call cpt1_1
        mov word ptr cs:[pit_cnt1],ax
@r1:
        cmp byte ptr cs:[pit_ld2],0
        jz cpt9_5
        cmp word ptr cs:[pit_cnt2],0
        jz cpt9_5
        sub word ptr cs:[pit_cnt2],bx
         jnc cpt9_5                    
         mov word ptr cs:[pit_cnt2],0

cpt9_5:
        cmp byte ptr cs:[f_snd],SND_SB
        je cpt9_4

        xor ah,ah
;        cmp word ptr cs:[pit_k2],3
;        jbe cpt9_8
 ;    mov ah,byte ptr cs:[pit_mode2]
 ;    and ah,6
 ;    cmp ah,6 ; mode 3
 ;    je cpt9_8

     cmp byte ptr cs:[pit_ld2],0
     jz cpt9_8
 ;    jz cpt9_6
;     cmp word ptr cs:[pit_k2],0
;     je cpt9_6
        cmp word ptr cs:[pit_cnt2],0
        jz cpt9_6
cpt9_8:
        mov ah,byte ptr cs:[pit_val0]
cpt9_6:
        or ah,byte ptr cs:[int_flag]
        rol ah,1
        and ah,2
        in al,61h
        and al,0fch
        or al,ah
        and al,byte ptr cs:[snd61_and]
        out 61h,al
        jmp cpt5

cpt9_4:
        xor al,al
 ;       cmp word ptr cs:[pit_k2],3
 ;       jbe cpt9_9
;     mov ah,byte ptr cs:[pit_mode2]
;     and ah,6
;     cmp ah,6 ; mode 3
;     je cpt9_9

     cmp byte ptr cs:[pit_ld2],0
     jz cpt9_9
 ;    jz cpt9_7
;     cmp word ptr cs:[pit_k2],0
;     je cpt9_7
        cmp word ptr cs:[pit_cnt2],0
        jz cpt9_7
cpt9_9:
        mov al,byte ptr cs:[pit_val0]
cpt9_7:
        and al,20h
cpt9_3:
        mov ah,byte ptr cs:[port_c]
        and ah,1
        ror ah,1
        ror ah,1
        ror ah,1
        add al,ah
        mov ah, byte ptr cs:[int_flag]
        and ah,1
        ror ah,1
        ror ah,1
        ror ah,1
        add al,ah
        xor ah,ah
        jmp cpt7

cpt9_2:
        cmp byte ptr cs:[f_snd],SND_SB
        jne cpt_e
        cmp byte ptr cs:[cModel],MODEL_O
        jne cpt8
cpt9_1:
        push ax bx
        xor ah,ah
        mov al, byte ptr cs:[int_flag]
        and al,1
        ror al,1
        ror al,1
        ror al,1
        mov ah,byte ptr cs:[port_c]
        and ah,1
        ror ah,1
        ror ah,1
        ror ah,1
        add al,ah
        jmp cpt7

cpt8:
        cmp byte ptr cs:[cModel],MODEL_S
        jne cpt11
        push ax bx
        xor ah,ah
        mov al, byte ptr cs:[snd_state]
        and al,20h
;        shl al,1
        mov ah, byte ptr cs:[port_c]
        and ah,80h
        ror ah,1
        ror ah,1
        add al,ah
        jmp cpt7

cpt11:
        cmp byte ptr cs:[cModel],MODEL_M80
        jne cpt19
        push ax bx
        mov ah,byte ptr cs:[port_c]
        and ah,1
        ror ah,1
        ror ah,1
        mov al, byte ptr cs:[int_flag]
        and al,1
        ror al,1
        ror al,1
        add al,ah
        jmp cpt7

cpt19:
        cmp byte ptr cs:[cModel],MODEL_U
        jne cpt18
        push ax bx
        mov al,byte ptr cs:[port_c]
        and al,1
        ror al,1
        ror al,1
        jmp cpt7

cpt18:  ; Партнер
        push ax bx

        mov ax,word ptr cs:[pit_cnt_p]
        mov bx,1000
        call cpt1
        mov word ptr cs:[pit_cnt_p],ax

        mov al,bl
        and al,3fh
        mov ah,byte ptr cs:[port_c]
        test ah,2
        jz cpt12
        xor al,al
cpt12:
        and ah,1
        ror ah,1
        ror ah,1
        add al,ah
        jmp cpt10

pit_val0 db 0
pit_val1 db 0
pit_val2 db 0

calc_pit endp

old_or_scrpage db 0ffh
old_or_colormode db 0ffh

or_scr_redr_cnt db 3

; Эта процедура вызывается 50 раз в секунду.
process50 proc
        cmp byte ptr cs:[cModel],MODEL_O
        jne pf1
        push ax
        dec byte ptr cs:[or_scr_redr_cnt]
        mov al, byte ptr cs:[or_scr_redr_cnt]
        test al,al
        jnz pf4
        mov byte ptr cs:[or_scr_redr_cnt],3
        mov al, byte ptr cs:[or_scrpage]
        cmp al, byte ptr cs:[old_or_scrpage]
        jne pf2
        mov al, byte ptr cs:[or_color_mode]
        cmp al, byte ptr cs:[old_or_colormode]
        je pf4
pf2:    call draw_scr_or
pf3:    mov al, byte ptr cs:[or_scrpage]
        mov byte ptr cs:[old_or_scrpage],al
        mov al, byte ptr cs:[or_color_mode]
        mov byte ptr cs:[old_or_colormode],al
pf4:    pop ax
        ret
pf1:    cmp byte ptr cs:[f_refr],REFR_RT
        je pf6
        cmp byte ptr cs:[f_scr],SCR_GRAPH
        je pf6
        cmp byte ptr cs:[cModel],MODEL_R
        je pf5
        cmp byte ptr cs:[cModel],MODEL_M
        je pf5
        cmp byte ptr cs:[cModel],MODEL_P
        je pf5
        cmp byte ptr cs:[cModel],MODEL_A
        je pf5
pf6:    ret
pf5:    cmp byte ptr cs:[f_refr],REFR_50
        je pf7
        cmp byte ptr cs:[f_refr_txt_scr],0
        jz pf6
pf7:    call refresh_scr
        ret
process50 endp

; Вызывается при Reset'е эмулируемого компьютера
perform_reset proc
; Reset таймера
        mov word ptr cs:[pit_k0],1
        mov word ptr cs:[pit_k1],1
        mov word ptr cs:[pit_k2],1
        mov word ptr cs:[pit_cnt0],0
        mov word ptr cs:[pit_cnt1],0
        mov word ptr cs:[pit_cnt2],0
        mov word ptr cs:[pit_read_byte_cnt0],0
        mov word ptr cs:[pit_read_byte_cnt1],0
        mov word ptr cs:[pit_read_byte_cnt2],0
        mov byte ptr cs:[pit_ld0],0
        mov byte ptr cs:[pit_ld1],0
        mov byte ptr cs:[pit_ld2],0
        mov byte ptr cs:[pit_mode0],36h
        mov byte ptr cs:[pit_mode1],76h
        mov byte ptr cs:[pit_mode2],0b6h
       mov word ptr cs:[dma_begadr_old],0
       mov word ptr cs:[dma_len_old],0
       mov byte ptr cs:[crt_param_1_old],0
       mov byte ptr cs:[crt_param_2_old],0
       mov byte ptr cs:[crt_param_3_old],0
       mov byte ptr cs:[crt_param_4_old],0
        cmp byte ptr cs:[cModel],MODEL_R
        je pr1
        mov byte ptr cs:[pit_mode2],0b0h
pr1:   cmp byte ptr cs:[cModel],MODEL_U
        je pr2
       push bx
       mov bx, word ptr cs:[mempage0+2]
       mov word ptr cs:[utrdseg],bx
       mov byte ptr cs:[utrdpag],0
       pop bx
pr2:
        ret
perform_reset endp

; Устанавливает параметры Ориона, считанные из снапшота
process_orion proc
       cmp byte ptr cs:[cModel],MODEL_O
       je po1
       mov ah, byte ptr cs:[or_scrpage]
       push bx
       mov bl,ah
       xor bh,bh
       xor bx,3
       ror bx,1
       ror bx,1
       mov word ptr cs:[scr_beg],bx
       add bx,2fffh
       mov word ptr cs:[scr_end],bx
       mov ah, byte ptr cs:[mem_page_no]
       and ah,3
       mov byte ptr cs:[mem_page_no],ah
       add ah,ah
       add ah,ah
       mov bl,ah
       xor bh,bh
       mov bx, word ptr cs:[mempage0+bx+2]
       mov word ptr cs:[mem+2],bx
       mov ds,bx
       pop bx
po1:   ret
process_orion endp

; ######################### ЭМУЛЯЦИЯ ДИСКОВОДА #########################

disk_in proc
        test bp,24h
        mov ah,0
        jnz diQ
        and bp,3
        cmp bp,0
        je disk_stat_in
        cmp bp,1
        je disk_cyl_in
        cmp bp,2
        je disk_sect_in
        jmp disk_data_in
diQ:    ret

; Чтение регистра статуса
disk_stat_in:
        mov ah,0
        cmp byte ptr cs:[b_transfer],0
        jz diQ
        mov ah,3
        ret

; Чтение регистра дорожки
disk_cyl_in:
        mov ah, byte ptr cs:[cyl]
        ret

; Чтение регистра сектора
disk_sect_in:
        mov ah, byte ptr cs:[sect]
        ret

; Чтение регистра данных
disk_data_in:
        mov ah,0
        cmp byte ptr cs:[b_transfer],0
        jz diQ
        push bx si
        mov bx, word ptr cs:[sect_ofs]
        inc word ptr cs:[sect_ofs]
        mov si, word ptr cs:[cur_sect_buf]
        mov ah, byte ptr cs:[bx+si]
        pop si
        cmp bx,3ffh
        pop bx
        jnz ddiQ
        mov word ptr cs:[sect_ofs],0
        mov byte ptr cs:[b_transfer],0

ddiQ:   ret
disk_in endp

disk_out proc
        test bp,24h
        jnz disk_ctrl_out
        and bp,3
        cmp bp,0
        je disk_cmd_out
        cmp bp,1
        je disk_cyl_out
        cmp bp,2
        je disk_sect_out
        jmp disk_data_out

; Запись в регистр управления
disk_ctrl_out:
        mov al,ah
        and ah,1
        mov byte ptr cs:[disk],ah
        and al,10h
        shr al,4
        xor al,1
        mov byte ptr cs:[head],al
        ret

; Запись регистра данных
disk_data_out:
        mov byte ptr cs:[vg_data_reg],ah
        cmp byte ptr cs:[b_transfer],0
        jz ddoQ
        cmp byte ptr cs:[b_read],0
        jnz ddoQ
        push bx si
        mov bx, word ptr cs:[sect_ofs]
        inc word ptr cs:[sect_ofs]
        mov si, word ptr cs:[cur_sect_buf]
        mov byte ptr cs:[bx+si],ah
        pop si
        cmp bx,3ffh
        pop bx
        jnz ddiQ
        mov word ptr cs:[sect_ofs],0
        mov byte ptr cs:[b_transfer],0

        push ds es ax bx cx dx si di bp
        push ax
        mov ax,cs
        mov ds,ax
        mov es,ax
        xor ah,ah
        mov al, byte ptr cs:[sect]
        push ax
        mov al, byte ptr cs:[head]
        push ax
        mov al, byte ptr cs:[cyl]
        push ax
        mov al, byte ptr cs:[disk]
        push ax
        call WriteSector
        pop ax ax ax ax ax
        pop bp di si dx cx bx ax es ds

ddoQ:   ret

; Запись регистра дорожки
disk_cyl_out:
        mov byte ptr cs:[cyl],ah
        ret

; Запись регистра сектора
disk_sect_out:
        mov byte ptr cs:[sect],ah
        ret

; Запись регистра команд
disk_cmd_out:
        mov byte ptr cs:[b_transfer],0
        push ax
        mov al,ah
        and al,0f0h
        cmp al,0
        je cmd_reset
        cmp al,10h
        je cmd_seek
        cmp al,20h
        je cmd_step
        cmp al,30h
        je cmd_step
        cmp al,40h
        je cmd_stepup
        cmp al,50h
        je cmd_stepup
        cmp al,60h
        je cmd_stepdown
        cmp al,70h
        je cmd_stepdown
        cmp al,80h
        je cmd_read_sector
        cmp al,90h
        je cmd_read_sector
        cmp al,0a0h
        je cmd_write_sector
        cmp al,0b0h
        je cmd_write_sector
        ; Остальные не реализовываем...
dcoQ:   pop ax
        ret

; Восстановление
cmd_reset:
        mov byte ptr cs:[cyl],0
        pop ax
        ret

; Поиск
cmd_seek:
        mov ah, byte ptr cs:[vg_data_reg]
        cmp ah,79h
        ja dcoQ
        mov byte ptr cs:[cyl],ah
        pop ax
        ret

; Шаг #########
cmd_step:
        cmp byte ptr cs:[b_stdn],0
        jnz cmd_stepdown        
cmd_stepup:
;        test ah,10h
;        jz csQ
        mov byte ptr cs:[b_stdn],0
        cmp byte ptr cs:[cyl],79
        jl csQ
        inc byte ptr cs:[cyl]
csQ:    pop ax
        ret
cmd_stepdown:
;        test ah,10h
;        jz csQ
        mov byte ptr cs:[b_stdn],1
        cmp byte ptr cs:[cyl],0
        ja csQ
        dec byte ptr cs:[cyl]
        pop ax
        ret

; Чтение сектора
cmd_read_sector:
        cmp byte ptr cs:[disk],0
        mov ax, offset acSectBufA
        je crs1
        mov ax, offset acSectBufB
crs1:   mov word ptr cs:[cur_sect_buf],ax
        mov byte ptr cs:[b_transfer],1
        mov byte ptr cs:[b_read],1
        mov word ptr cs:[sect_ofs],0

        push ds es ax bx cx dx si di bp
        push ax
        mov ax,cs
        mov ds,ax
        mov es,ax
        xor ah,ah
        mov al, byte ptr cs:[sect]
        push ax
        mov al, byte ptr cs:[head]
        push ax
        mov al, byte ptr cs:[cyl]
        push ax
        mov al, byte ptr cs:[disk]
        push ax
        call ReadSector
        pop ax ax ax ax ax
        pop bp di si dx cx bx ax es ds

        pop ax
        ret

; Запись сектора
cmd_write_sector:
        cmp byte ptr cs:[disk],0
        mov ax, offset acSectBufA
        je cws1
        mov ax, offset acSectBufB
cws1:   mov word ptr cs:[cur_sect_buf],ax
        mov byte ptr cs:[b_transfer],1
        mov byte ptr cs:[b_read],0
        mov word ptr cs:[sect_ofs],0

        pop ax
        ret

disk_out endp

b_transfer db 0 ; 1, если идет чтение
b_read db 0 ; 0-чтение, 1-запись. Действителен при b_transfer=1
cyl db 0 ; регистр дорожки
sect db 0 ; регистр сектора
disk db 0 ; текущий диск
head db 0 ; текущая сторона
vg_data_reg db 0 ; регистр данных ВГ93
sect_ofs dw 0 ; Текущее смещение в буфере сектора
cur_sect_buf dw ? ; Текущий буфер сектора
b_stdn db 0 ; 1, если шаг назад

end
