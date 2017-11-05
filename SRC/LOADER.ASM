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

;File: LOADER.ASM

; Содержит загрузочную часть и собственно интерпретатор инструкций 8080

INCLUDE EMU80.INC

.model tiny

public fin
public setparms
public quit
public set_video_auto
public set_delay_w_dma
public set_delay_wo_dma
public set_delay_w_dma28
public delay_norm
public delay_dma
public cur_speed
public cur_speed_sb
public delay
public delay_sb
public rom_len
public rom_adr
public ppi_portc_adr
public crt_port1_adr
public romname
public hook_proc_spk
public hook_proc_sb
public hook_p
public hook_r
public hook_a
public hook_m
public hook_s
public hook_o
public hook_m80
public hook_u
public hook_p_sb
public hook_r_sb
public hook_a_sb
public hook_m_sb
public hook_s_sb
public hook_o_sb
public hook_m80_sb
public hook_u_sb
public Start
public Resume
public Init
public LoadROM
public ClearMem
public SetDefParams
public InitOnce
public mempages
public mempage0
public mempage1
public mempage2
public mempage3
public mempage4
public mem
public color_mem
public sym_gen
public romdisk_mem
public fonts_mem

public reg_af
public reg_bc
public reg_de
public reg_hl
public reg_sp
public reg_pc
public anal_params
public f_chscr
public f_use8x12
public reset_addr
public f_saverom
public snd61_and
public delay_sb_dma
public delay_sb_norm
public f_pause

extrn last:byte
extrn emF809:near
extrn emF803:near
extrn emF81B:near
extrn emF812:near
extrn emF80C:near
extrn emF806:near
extrn code_tbl:word
extrn code_tbl_m:word
extrn code_tbl_m2:word
extrn inittimer:near
extrn getcount:near
extrn f_speed:byte
extrn f_vid:byte
extrn f_f809:byte
extrn f_scr:byte
extrn f_font:byte
extrn f_refr:byte
extrn f_snd:byte
extrn f_tape:byte
extrn f_led:byte
extrn setup:near
extrn f_reset:byte
extrn get_key:near
extrn test_key:near
extrn prep_key:near
extrn sysreq:byte
extrn flash_key:near
extrn setscr25:near
extrn setscr30:near
extrn setscr40:near
extrn setscr43:near
extrn refresh_scr:near
extrn load_8x16:near
extrn load_8x16rk:near
extrn load_8x8:near
extrn load_8x8rk:near
extrn load_8x12:near
extrn load_8x12rk:near
extrn setw8:near
extrn set_vga400:near
extrn set_vga350:near
extrn symtable_ptr:word
extrn test_vga:near
extrn test_win:near
extrn test_nt:near
extrn disable_vga:near
extrn set_fontoem:near
extrn enable_hookf809:near
extrn init_sound:near
extrn sh_height:byte
extrn get_09_vect:near
extrn set_new_09_vect:near
extrn restore_09_vect:near
extrn close_file:near
extrn close_file_delay:near
extrn set_cga_mode:near
extrn test_ega:near
extrn find_path:near
extrn com_path:byte
extrn com_path_len:word
;extrn light_led:near
 extrn process_port_c:near
extrn process_int:near
extrn process50:near
extrn disable_ints:near
extrn sysreq_code:byte
extrn GeneralError:near
extrn ROMError:near
extrn SymGenError:near
extrn FontsError:near
extrn ROMDiskError:near
extrn cModel:byte
extrn cMonitor:byte
extrn emu_ret:near
extrn RefreshMenu:near
extrn f_novesa:byte
extrn wSBPort:word
extrn wSBDMA:word
extrn calc_pit:near
extrn refr_sg_scr:near
extrn vretr_cnt:byte
extrn mem_page_no:byte
extrn translate_sysreq_code:near
extrn ticks_per_44100th:word
extrn ticks_per_50ms:word
extrn ticks_per_calc:word
extrn perform_reset:near

extrn bWaitSnd:word
extrn WaitSound:near
extrn StopSound:near
extrn ResetDSP:near
extrn bSBPresent:word ; SB Present

.code

jumps ; ###############

; Регистры
reg_af dw ?
reg_bc dw ?
reg_de dw ?
reg_hl dw ?
reg_sp dw ?
reg_pc dw ?

; Имя файла знакогенератора
symgen_name db 'symgen.bin',0
romdisk_name db 'romdisk.bin',0
fontfile_name db 'fonts.bin',0

; Признак необходимости сохранения ПЗУ в снапшоте
f_saverom db 0

; Дальний указатель на сегмент 8080
mem dd 0 ; Текущая страница
mempages:
mempage0 dd 0 ; Страница 0 или единственная
mempage1 dd 0 ; Страница 1
mempage2 dd 0 ; Страница 2
mempage3 dd 0 ; Страница 3
mempage4 dd 0 ; Страница 4 (то же, что и RomDisk в Орионе)

; Дальний указатель на знакогенератор
sym_gen dd 0

; Дальний указатель на область хранения шрифтов
fonts_mem dd 0

; Дальний указатель на область цвета для ПК "Специалист"
color_mem dd 0

; Дальний указатель на область ROMDISK'а для ПК "Орион"
romdisk_mem dd 0

; Маска регистра 61h для вывода звука
snd61_and db 0ffh

; такты на 100 мкс
delay_norm dw ? ; нормальная работа процессора 8080
delay_dma dw ? ; при включенном ПДП
delay_28 dw 79 ; при включенном ПДП в режиме регенерации ОЗУ для Партнера

delay_sb_norm dw ? ; нормальная работа процессора 8080
delay_sb_dma dw ? ; при включенном ПДП
delay_sb_28 dw 36 ; при включенном ПДП в режиме регенерации ОЗУ для Партнера

; Текущая средняя длительность команды 8080 или 0
delay dw 0ffffh

delay_sb dw ? ; тактов на 1/44100 с с учетом ПДП

rom_len dw ? ; длина ПЗУ
rom_adr dw ? ; нач. адрес ПЗУ

ppi_portc_adr dw ? ; адрес порта C ППА
crt_port1_adr dw ? ; адрес регистра управления ВГ75

reset_addr dw 0f800h

f806_adr dw ? ; Адрес процедуры чтения байта с магнитофона
f80c_adr dw ? ; Адрес процедуры записи байта на магнитофон
;f803_adr dw ? ; Адрес процедуры чтения символа с клавиатуры с ожиданием
;f812_adr dw ? ; Адрес процедуры опроса состояния клавиатуры
;f81b_adr dw ? ; Адрес процедуры чтения символа с клавиатуры без ожидания

hook_proc dw ? ; Адрес процедуры перехвата

hook_proc_spk dw ? ; Адрес процедуры перехвата - PC Speaker
hook_proc_sb  dw ? ; Адрес процедуры перехвата - Sound Blaster

interpret_proc dw ? ; Адрес процедуры основного цикла

f_pause db 0 ; Признак паузы

f_use8x12 db 1

; Процедура инициализации. Вызывается один раз при запуске эмулятора
InitOnce proc
        push cs
        pop es

; Выделяем область памяти под сегмент 8080
        mov ah,48h
        mov bx,4096
        int 21h
        jc error
        mov word ptr cs:[mempage0+2],ax
        mov word ptr cs:[mem+2],ax
        mov byte ptr cs:[mem_page_no],0

; Выделяем еще 3 области по 64К памяти под RAMDISK ПК "Орион"
        mov ah,48h
        mov bx,4096
        int 21h
        jc error
        mov word ptr cs:[mempage1+2],ax
        mov ah,48h
        mov bx,4096
        int 21h
        jc error
        mov word ptr cs:[mempage2+2],ax
        mov ah,48h
        mov bx,4096
        int 21h
        jc error
        mov word ptr cs:[mempage3+2],ax

; Выделяем область памяти под область хранения информации о цвете "Спец-та"
        mov ah,48h
        mov bx,300h
        int 21h
        jnc ll4
        jmp error
ll4:    mov word ptr cs:[color_mem+2],ax

; Выделяем область памяти под область хранения ROMDISK'а "Ориона"
        mov ah,48h
        mov bx,4096
        int 21h
        jnc ll6
        jmp error
ll6:    mov word ptr cs:[romdisk_mem+2],ax
        mov word ptr cs:[mempage4+2],ax ; а для ЮТ это входит в эл. диск.

; Очищаем ROMDISK
        push es
        mov es,ax
        mov cx,8000h
        mov ax,0ffffh
        xor di,di
        cld
        rep stosw
        pop es

; Выделяем область памяти под область хранения знакогенератора
        mov ah,48h
        mov bx,768
        int 21h
        jnc lll4
        jmp error
lll4:   mov word ptr cs:[sym_gen+2],ax

; Создаем полный путь к файлам с ПЗУ и знакогенератором
        call find_path

        push ds
        push es
        mov ax,cs
        mov es,ax
        mov ds,ax

; Чтение файла знакогенератора
        push si di
        lea di,com_path
        add di,word ptr [com_path_len]
        mov si, offset symgen_name
        mov cx,11 ; длина имени файла с ПЗУ + 1 нулевой байт
        cld
        rep movsb
        pop di si

; Открываем файл со знакогенератором
        lea dx,com_path
        mov ax,3d00h
        xor cx,cx
        int 21h         ; откраваем файл со знакогенератором
        jnc ll5
        jmp error_symgen

ll5:    mov bx,ax

        mov ax, word ptr cs:[sym_gen+2]
        mov ds,ax

        mov ah,3fh
        mov cx,12288
        xor dx,dx
        int 21h         ; читаем знакогенератор
        jc error

        mov ah,3eh
        int 21h         ; закрываем файл
        jc error

; Выделяем область памяти под область хранения шрифтов
        mov ah,48h
        mov bx,480
        int 21h
        jnc lll5
        jmp error
lll5:   mov word ptr cs:[fonts_mem+2],ax

; Создаем полный путь к файлам со шрифтами
;        call find_path

        mov ax,cs
        mov es,ax
        mov ds,ax

; Чтение файла шрифтов
        push si di
        lea di,com_path
        add di,word ptr cs:[com_path_len]
        mov si, offset fontfile_name
        mov cx,10 ; длина имени файла со шрифтами + 1 нулевой байт
        cld
        rep movsb
        pop di si

; Открываем файл со шрифтами
        lea dx,com_path
        mov ax,3d00h
        xor cx,cx
        int 21h         ; откраваем файл со шрифтами
        jnc lll6
        jmp error_fonts

lll6:    mov bx,ax

        mov ax, word ptr cs:[fonts_mem+2]
        mov ds,ax

        mov ah,3fh
        mov cx,7680
        xor dx,dx
        int 21h         ; читаем шрифты
        jc error

        mov ah,3eh
        int 21h         ; закрываем файл
        jc error

        pop es
        pop ds

        call get_09_vect        ; запоминаем вектор прерывания int 09 клав.

        mov byte ptr cs:[f_novesa],0
        mov byte ptr cs:[f_led],1
        mov byte ptr cs:[f_use8x12],1

        mov word ptr cs:[wSBPort],220h
        mov word ptr cs:[wSBDMA],1

        ret
InitOnce endp

; Очистка памяти сегмента 8080
ClearMem proc
        push ax
        push es

        mov word ptr cs:[filler_word],0
        cmp byte ptr cs:[cModel],MODEL_U
        jne cm1
        mov word ptr cs:[filler_word],0e5e5h

cm1:
        cld

; Очистка памяти основного сегмента 8080
        mov ax, word ptr cs:[mempage0+2]
        mov es,ax
        mov cx,8000h
        mov ax, word ptr cs:[filler_word]
        xor di,di
        rep stosw
;   mov byte ptr es:[0],80h

; Очистка RAMDISK ПК "Орион"
        mov ax, word ptr cs:[mempage1+2]
        mov es,ax
        mov cx,8000h
        mov ax, word ptr cs:[filler_word]
        xor di,di
        rep stosw
;   mov byte ptr es:[0],81h
        mov ax, word ptr cs:[mempage2+2]
        mov es,ax
        mov cx,8000h
        mov ax, word ptr cs:[filler_word]
        xor di,di
        rep stosw
;   mov byte ptr es:[0],82h
        mov ax, word ptr cs:[mempage3+2]
        mov es,ax
        mov cx,8000h
        mov ax, word ptr cs:[filler_word]
        xor di,di
        rep stosw
;   mov byte ptr es:[0],83h
        cmp byte ptr cs:[cModel],MODEL_U ; а нужна ли проверка?
        jne cm2
        mov ax, word ptr cs:[mempage4+2]
        mov es,ax
        mov cx,8000h
        mov ax, word ptr cs:[filler_word] ; вообще-то всегда 0e5h
        xor di,di
        rep stosw
cm2:
        pop es
        pop ax
        ret

filler_word dw 0 ; байт-заполнитель

ClearMem endp

; Устанавливает параметры по умолчанию
SetDefParams proc
        push bp

        ; Загружаем первоначальные значения
        mov byte ptr cs:[f_speed],SPEED_NORM
        mov byte ptr cs:[f_vid],MEM_W
        mov byte ptr cs:[f_f809],HOOKF809_NO
        mov byte ptr cs:[f_scr],SCR_AUTO
        mov byte ptr cs:[f_font],FONT_RK
        mov byte ptr cs:[f_refr],REFR_COMB
        mov byte ptr cs:[f_snd],SND_ON
        mov byte ptr cs:[f_tape],TAPE_FILE
        call RefreshMenu

        ; И модифицируем их в зависимости от прогр. и аппар. особенностей
        call test_vga
        jz l1
        mov cs:f_vgapres,0
        call disable_vga        ; отсутствует VGA - запретить режим 78x30
        call test_ega
        jnz l1
        call set_cga_mode       ; отсутствует EGA - запретить режим Auto
l1:     call test_win
        jz l2
        call set_fontoem        ; работает Windows - не загр. фонта по умолч.

l2:     call test_nt
        test al,al
        jz l3
        call enable_hookf809    ; работает под NT - включить перехват 0F809H
        call set_fontoem        ; а также запретить загрузку фонта
l3:     call RefreshMenu
        pop bp
        ret
SetDefParams endp

; Процедура инициализации. Вызывается при каждой смене типа ПК.
Init proc
        push ds
        push bp
        push ax
        push cx
        push dx
        push si
        push di

        mov ax, word ptr cs:[mempage0+2]
        mov word ptr cs:[mem+2],ax
        mov ds,ax
        mov byte ptr cs:[mem_page_no],0

; Нужно, чтобы программы, ожидающие vertical refresh путем опроса порта
; ВГ75 не зависали - подставим им этот бит
; А также пусть не будут нажаты клавиши УС, НР и РУС/ЛАТ.
        cmp byte ptr cs:[cModel],MODEL_S
        je l7
        cmp byte ptr cs:[cModel],MODEL_M80
        je l17
        cmp byte ptr cs:[cModel],MODEL_U
        jne l7
        cmp byte ptr cs:[cModel],MODEL_O
        je l8

        mov bx, word ptr cs:[crt_port1_adr]
        mov byte ptr ds:[bx],20h

l8:     mov bx, word ptr cs:[ppi_portc_adr]
        mov byte ptr ds:[bx],0f0h
l17:
        mov word ptr ds:[0f75ch],2436h  ; константы чтения/записи для Микро-80
l7:
        call inittimer
        call init_sound
        call cls

        mov byte ptr cs:[f_chscr],1
        call anal_params        ; Разбираем параметры из модуля интерфейса

        pop di
        pop si
        pop dx
        pop cx
        pop ax
        pop bp
        pop ds
        ret
Init endp

; Загрузка ПЗУ.
LoadROM proc
        push ds
        push es
        push bp
        push ax
        push cx
        push dx
        push si
        push di
        mov ax,cs
        mov es,ax
        lea di,com_path
        add di,word ptr [com_path_len]
        mov si,word ptr cs:[romname]
        mov cx,10 ; макс. длина имени файла с ПЗУ + 1 нулевой байт ; ####
        rep movsb

; Открываем файл с ПЗУ
        lea dx,com_path; romname
        mov ax,3d00h
        xor cx,cx
        int 21h         ; откраваем файл с ПЗУ
        jnc l5
        jmp error_rom

l5:     mov bx,ax

        mov ax, word ptr cs:[mem+2]
        mov ds,ax

        mov ah,3fh
        mov cx,word ptr cs:[rom_len]
        mov dx,word ptr cs:[rom_adr]
        int 21h         ; читаем ПЗУ
        jc error

        mov ah,3eh
        int 21h         ; закрываем файл
        jc error

        mov byte ptr cs:[f_saverom],0 ; сбрасываем признак сохранения ПЗУ

        ; Запоминаем адреса процедур точек входа в Монитор
        mov ax, word ptr ds:[0f807h]
        mov word ptr cs:[f806_adr],ax
        mov ax, word ptr ds:[0f80dh]
        mov word ptr cs:[f80c_adr],ax
;        mov ax, word ptr ds:[0f804h]
;        mov word ptr cs:[f803_adr],ax
;        mov ax, word ptr ds:[0f812h]
;        mov word ptr cs:[f812_adr],ax
;        mov ax, word ptr ds:[0f81bh]
;        mov word ptr cs:[f81b_adr],ax

        cmp byte ptr cs:[cModel],MODEL_O
        jne lr1

; Чтение файла ROMDISK'а
        mov ax,cs
        mov es,ax
        mov ds,ax

        push si di
        lea di,com_path
        add di,word ptr [com_path_len]
        mov si, offset romdisk_name
        mov cx,12 ; длина имени файла с ROMDISK'ом + 1 нулевой байт
        cld
        rep movsb
        pop di si

; Открываем файл с ROMDISK'ом
        lea dx,com_path
        mov ax,3d00h
        xor cx,cx
        int 21h         ; откраваем файл с ROMDISK'ом
        jnc ll7
        jmp error_romdisk

ll7:    mov bx,ax

        mov ax, word ptr cs:[romdisk_mem+2]
        mov ds,ax

        mov ah,3fh
        mov cx,65530    ; ##########
        xor dx,dx
        int 21h         ; читаем ROMDISK
;        jc error

        mov ah,3eh
        int 21h         ; закрываем файл
        jc error
lr1:
        pop di
        pop si
        pop dx
        pop cx
        pop ax
        pop bp
        pop es
        pop ds
        ret
LoadROM endp

error:  mov ax,cs
        mov ds,ax
        call GeneralError
        int 20h

error_rom:
        mov ax,cs
        mov ds,ax
        call ROMError
        jmp quit

error_symgen:
        mov ax,cs
        mov ds,ax
        call SymGenError
        int 20h

error_fonts:
        mov ax,cs
        mov ds,ax
        call FontsError
        int 20h

error_romdisk:
        mov ax,cs
        mov ds,ax
        call ROMDiskError
        int 20h

;#########################################################################
Resume:
        mov ax, word ptr cs:[mem+2]
        mov ds,ax
        call restore_regs
        jmp l6
Start:

        mov ax, word ptr cs:[mem+2]
        mov ds,ax

; Поехали !

; Загрузка начальных значений в регистры 8080
mov cx,0
mov dx,0
mov bx,0
mov di,76cfh
mov si,word ptr cs:[reset_addr]

l6:
call getcount   ; Получаем текущее значение счетчика таймера 8254
mov word ptr cs:[init_mtick],ax
mov word ptr cs:[tick_count],0
mov word ptr cs:[count2],400

jmp word ptr cs:[interpret_proc]

; Текущая задержка. Используется при нормальной скорости
cur_speed dw ?
cur_speed_sb dw ?

; Устанавливает скорость с DMA, если установлена норм. скорость
set_delay_w_dma proc
        push ax
        mov ax, word ptr cs:[delay_sb_dma]
        mov word ptr cs:[cur_speed_sb],ax
        mov ax, word ptr cs:[delay_dma]
        mov word ptr cs:[cur_speed],ax
        cmp byte ptr cs:[f_speed],SPEED_NORM
        jne sdn1
        mov word ptr cs:[delay],ax
        mov ax, word ptr cs:[delay_sb_dma]
        mov word ptr cs:[delay_sb],ax
sdn1:   pop ax
        ret
set_delay_w_dma endp

; Устанавливает скорость без DMA, если установлена норм. скорость
set_delay_wo_dma proc
        push ax
        mov ax, word ptr cs:[delay_sb_norm]
        mov word ptr cs:[cur_speed_sb],ax
        mov ax, word ptr cs:[delay_norm]
        mov word ptr cs:[cur_speed],ax
        cmp byte ptr cs:[f_speed],SPEED_NORM
        jne sdd1
        mov word ptr cs:[delay],ax
        mov ax, word ptr cs:[delay_sb_norm]
        mov word ptr cs:[delay_sb],ax
sdd1:   pop ax
        ret
set_delay_wo_dma endp

; Устанавливает скорость режима DMA регенерации памяти,
; если установлена норм. скорость для Партнера
set_delay_w_dma28 proc
        cmp byte ptr cs:[cModel],MODEL_P
        jne set_delay_w_dma
        push ax
        mov ax, word ptr cs:[delay_sb_28]
        mov word ptr cs:[cur_speed_sb],ax
        mov ax, word ptr cs:[delay_28]
        mov word ptr cs:[cur_speed],ax
        cmp byte ptr cs:[f_speed],SPEED_NORM
        jne sd28_1
        mov word ptr cs:[delay],ax
        mov ax, word ptr cs:[delay_sb_28]
        mov word ptr cs:[delay_sb],ax
sd28_1: pop ax
        ret
set_delay_w_dma28 endp

f_chscr db 1    ; 1, если нужно перенастраивать экран
f_vgapres db 1  ; 1, если присутствует VGA

; Перенастройка режима экрана в соответствии с переменными в модуле инт-са
set_video proc
        cmp byte ptr cs:[cModel],MODEL_M80
        je set_video_40
        cmp byte ptr cs:[cModel],MODEL_U
        je set_video_40
        cmp byte ptr cs:[cModel],MODEL_S
        je sv3
        cmp byte ptr cs:[cModel],MODEL_O
        je sv3
        cmp cs:[f_scr],SCR_LOW
        jnz sv1
        jmp set_video_25
sv1:    cmp cs:[f_scr],SCR_HIGH
        jne sv2
        jmp set_video_30
sv2:    call set_video_auto
;     mov     ax,1000h
;     mov     bx,0606h
;     int     10h
sv3:
        ret
set_video endp

load_font8x16 proc
;       cmp cs:[f_vgapres],0
;       jz lf16_2
        cmp cs:[f_font],FONT_OEM
        jz lf16_2
        call load_8x16rk
        call setw8
        jmp lf16_3
lf16_2: ;call load_8x16
lf16_3: ret
load_font8x16 endp

load_font8x8 proc
        cmp cs:[f_font],FONT_OEM
        jz lf8_2
        call load_8x8rk
        call setw8
        jmp lf8_3
lf8_2:  ;call load_8x8
lf8_3:  ret
load_font8x8 endp

load_font8x12 proc
        cmp cs:[f_font],FONT_OEM
        jz lf12_2
        call load_8x12rk
        call setw8
        jmp lf8_3
lf12_2: call load_8x12
lf12_3: ret
load_font8x12 endp

set_video_25 proc
        cmp cs:[f_vgapres],0
        jz sv25_1
        call set_vga400
sv25_1: call setscr25
        call load_font8x16
        ret
set_video_25 endp

set_video_30 proc
        call set_vga400
        call setscr25 ; надо ли?
        call setscr30
        call load_font8x16
        ret
set_video_30 endp

set_video_43 proc
        cmp cs:[f_vgapres],0
        jz sv43_1
        call set_vga350
sv43_1: call setscr43
        call load_font8x8
        ret
set_video_43 endp

set_video_40 proc
        cmp cs:[f_use8x12],0
        jz set_video_43
        cmp cs:[f_vgapres],0
        jz sv40_1
sv40_1: call setscr40
        call load_font8x12
        ret
set_video_40 endp

set_video_auto proc
        cmp cs:[f_vgapres],0
        jz set_video_43
        cmp byte ptr cs:[sh_height],30
        jbe set_video_30
        cmp byte ptr cs:[sh_height],43
        jae set_video_43
;        cmp byte ptr cs:[f_use8x12],0
;        je set_video_43
        jmp set_video_40
set_video_auto endp

; Разбор параметров из модуля интерфейса
anal_params proc
        push bx cx dx si di ds
        cmp word ptr cs:[bSBPresent],0
        jnz ap11
        cmp cs:[f_snd],SND_SB
        jne ap11
        mov ax,cs
        mov ds,ax
        call ResetDSP ; проверяем, работает ли SB, если нет,
        test ax,ax    ; игонорируем попытку установления данного параметра
        jnz ap11
        mov byte ptr cs:[f_snd],SND_ON
        call RefreshMenu
ap11:   pop ds di si dx cx bx

        mov byte ptr cs:[snd61_and],0ffh
        mov word ptr cs:[interpret_proc],offset interpret
        push ax
        mov ax, word ptr cs:[hook_proc_spk]
        mov word ptr cs:[hook_proc],ax
        mov ax, word ptr cs:[ticks_per_50ms]
        mov word ptr cs:[ticks_per_calc],ax
        cmp cs:[f_snd],SND_ON
        je ap10
        mov byte ptr cs:[snd61_and],0fdh
        cmp cs:[f_snd],SND_SB
        jne ap10
        mov word ptr cs:[interpret_proc],offset interpret_sb
        mov ax, word ptr cs:[hook_proc_sb]
        mov word ptr cs:[hook_proc],ax
        mov ax, word ptr cs:[ticks_per_44100th]
        mov word ptr cs:[ticks_per_calc],ax
ap10:   pop ax
        cmp cs:[f_speed],SPEED_HIGH
        jnz ap1
        mov word ptr cs:[delay],0fffh
        mov word ptr cs:[delay_sb],07ffh
        jmp ap2
ap1:    cmp cs:[f_speed],SPEED_MEDIUM
        jnz ap5
        push ax
        mov ax, word ptr cs:[delay_norm]
        mov word ptr cs:[delay],ax
        mov ax, word ptr cs:[delay_sb_norm]
        mov word ptr cs:[delay_sb],ax
        pop ax
        jmp ap2
ap5:    push ax
        mov ax,word ptr cs:[cur_speed]
        mov word ptr cs:[delay],ax
        mov ax,word ptr cs:[cur_speed_sb]
        mov word ptr cs:[delay_sb],ax
        pop ax
       cmp byte ptr cs:[f_scr],SCR_GRAPH
       jne ap2
       mov byte ptr cs:[f_f809],HOOKF809_NO
       mov byte ptr cs:[f_vid],MEM_RW
       push ds
       push cs
       pop ds
       call RefreshMenu
       pop ds
       jmp ap3
ap2:    cmp cs:[f_vid],MEM_RW
        je ap3
        cmp cs:[f_snd],SND_SB
        je ap3
        call restore_09_vect
        cmp cs:[f_vid],MEM_NONE
        jz ap8
        mov word ptr cs:[c_table],offset code_tbl_m
        jmp ap4
ap8:    mov word ptr cs:[c_table],offset code_tbl
        push ax
        mov ax, word ptr cs:[delay_dma]
        mov word ptr cs:[cur_speed],ax  ; поск-ку в этом режиме не отсл.
        pop ax                          ; зап. в контр. DMA
        jmp ap4
ap3:    call set_new_09_vect
        mov word ptr cs:[c_table],offset code_tbl_m2
       call process_port_c
ap4:
;       cmp byte ptr cs:[cModel],MODEL_S
;       je ap9
;       cmp byte ptr cs:[cModel],MODEL_O
;       je ap9
;       cmp byte ptr cs:[f_scr],SCR_GRAPH
;       je ap9
        cmp byte ptr cs:[f_chscr],0
        jz ap9
;        jz ap7
        call set_video
ap9:    call refresh_scr
ap7:    mov byte ptr cs:[f_chscr],1 ; зачем ???
        ret
anal_params endp

; Вызывается при нажатии F10
setparms proc
        pushf
        push ax
        call translate_sysreq_code
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_SPEEDUP
        je sp3 ; не перенастраиваем параметры
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_SPEEDDOWN
        je sp3 ; не перенастраиваем параметры
        cmp byte ptr cs:[sysreq_code+1],SYSREQ_PAUSE
        je sp3 ; не перенастраиваем параметры
        mov al,byte ptr cs:[f_scr]
        mov ah,byte ptr cs:[f_font]
        call restore_09_vect            ; восстановить для диалога
        call setup
        xor al,byte ptr cs:[f_scr]
        xor ah,byte ptr cs:[f_font]
        or al,ah
        mov byte ptr cs:[f_chscr],al
        cmp byte ptr cs:[f_vid],MEM_NONE
        jne sp1
        call enable_hookf809
sp1:    cmp byte ptr cs:[f_vgapres],1
        je sp2
        cmp byte ptr cs:[f_scr],SCR_LOW
        jne sp2
        call set_fontoem
sp2:    pop ax
        call anal_params
        popf
        ret
sp3:    call setup
        pop ax
        popf
        ret
setparms endp

; Выход из программы
fin:
exit:
        mov ax,es
        mov ds,ax
quit:
        call StopSound
        call restore_09_vect
        call init_sound
        cmp cs:[f_vgapres],0
        jz q1
        call set_vga400
        call load_8x16
q1:     mov ax,3
        int 10h
        lea dx,copyrmes
        mov ah,9
        int 21h
        int 20h

copyrmes db 'Эмулятор ПК',10,13
         db '"Радио-86РК", "Партнер", "Микроша", "Апогей", "Специалист",',0dh,0ah
         db '"Орион", "Микро-80", "ЮТ-88"',10,13
         db 'Версия 2.86',10,10,13
         db '(c) Copyright Виктор Пыхонин',10,13
         db 'Нижний Новгород, 1997-2000',10,13,24h

; Очистка экрана
cls proc
        mov ax,0600h
        mov cx,0
        mov dx,184fh
        mov bh,7
        int 10h
        ret
cls endp

; Адрес имени файла с ПЗУ
romname dw ?

; Текущая таблица инструкций 8080
c_table dw code_tbl_m

;##############################################################

; сюда управление попадает 50 раз в секунду
inter7:
        mov word ptr cs:[count2],400
        push ax
        call process_int
        call process50
          mov byte ptr cs:[vretr_cnt],13
     cmp byte ptr cs:[f_scr],SCR_GRAPH
     jne inter11
     call refr_sg_scr
;       cmp byte ptr cs:[f_vid],2
;       jne inter11
;       call light_led
inter11:
        call prep_key
        cmp byte ptr cs:[sysreq],0
        jz inter8

        pop ax
        push ax
        call store_regs
        mov byte ptr cs:[sysreq],0
        call flash_key
        call setparms
        cmp byte ptr cs:[f_reset],0
        jz inter11_2
        call perform_reset
        mov byte ptr cs:[f_reset],0
inter11_2:
        call restore_regs

inter8:
        pop ax
;        cmp byte ptr cs:[f_reset],1
;        je inter9
        jmp word ptr cs:[interpret_proc]

;inter9: ; Reset
;        mov byte ptr cs:[f_reset],0
;        mov cx,0
;        mov dx,0
;        mov bx,0
;        mov di,76cfh
;        mov si,0f800h
;        call disable_ints
;        jmp interpret

inter2:
; Берем адрес процедуры из таблицы ...
        mov bp,word ptr cs:[c_table]
        push bx
;         push es
         mov bx, word ptr cs:[mem+2]
         cmp si,0f000h
         jb i_pag_sb
         mov bx, word ptr cs:[mempage0+2]
i_pag_sb:
         mov ds,bx
        xor bh,bh
         mov bl,byte ptr ds:[si]
;         pop es
        add bp,bx
        add bp,bx
        pop bx
        mov bp,word ptr cs:[bp]
; вызываем ее ...
       cmp byte ptr cs:[f_pause],0
       jnz ip1
        call bp
ip11:
        add bp,word ptr cs:[tick_count]
        mov word ptr cs:[tick_count],bp
        sub bp,word ptr cs:[delay]
        jae inter3
        jmp interpret ; к следующей команде
ip1:    mov bp,10
        jmp ip11

; сюда управление попадает каждые 50 мкс
inter3: mov word ptr cs:[tick_count],bp
        mov bp,word ptr cs:[init_mtick]
        push ax
inter4: call getcount
        sub ax,bp
        cmp ax,-119
        ja inter4
;        add ax,bp
;        mov word ptr cs:[init_mtick],ax
  sub word ptr cs:[init_mtick],119
        pop ax
       call calc_pit
;  dec byte ptr cs:[vretr_cnt]
        dec word ptr cs:[count2]
        jnz interpret
        jmp inter7

interpret:
        cmp si,word ptr cs:[rom_adr]
        jb inter2

        jmp word ptr cs:hook_proc

; Находимся в ПЗУ - проверяем перехватываемые адреса

hook_a:
        cmp si,0fe61h
        jz _f803
        cmp si,0fe70h
        jz _f81b
        cmp si,0fcbah
        jz _f809
        cmp si,0fdffh
        jz _f812
        cmp si,0fc46h
        jz _f80c
        cmp si,0fb98h
        jz _f806
        jmp inter2

hook_p:
        cmp si,0fd7bh
        jz _f803
        cmp si,0fce9h
        jz _f81b
        cmp si,0fda5h
        jz _f809
        cmp si,0fc81h
        jz _f812
        cmp si,0fc55h
        jz _f80c
        cmp si,0fba2h
        jz _f806
        jmp inter2

hook_r:
        cmp si,0fe63h
        jz _f803
        cmp si,0fe72h
        jz _f81b
        cmp si,0fcbah
        jz _f809
        cmp si,0fe01h
        jz _f812
        cmp si,0fc46h
        jz _f80c
        cmp si,0fb98h
        jz _f806
        jmp inter2

hook_m:
        cmp si,0fed0h
        jz _f803
        cmp si,0feeah
        jz _f81b
        cmp si,0fd25h
        jz _f809
        cmp si,0fe7fh
        jz _f812
        cmp si,0fcabh
        jz _f80c
        cmp si,0fc0dh
        jz _f806
        jmp inter2

hook_s:
        cmp si,0c337h
        jz _f803
        cmp si,0ce5ch
        jz _f81b
;        cmp si,0cec8h
;        jz _f809
        cmp si,0c3d0h
        jz _f80c_s
        cmp si,0c377h
        jz _f806
        jmp inter2
hook_o:
        cmp si,0f803h
        jz _f803
        cmp si,0faeeh
        jz _f81b
        cmp si,0f809h
        jz _f809
        cmp si,0fa78h
        jz _f812
;        cmp si,0fa53h
        cmp si,word ptr cs:[f80c_adr]
        jz _f80c
;        cmp si,0f9cdh
        cmp si,word ptr cs:[f806_adr]
        jz _f806
        jmp inter2

hook_m80:
        cmp si,0ff41h
        jz _f803
;        cmp si,0fe68h
;        jz _f809
        cmp si,0ffeeh
        jz _f812
        cmp si,0fde6h
        jz _f80c
        cmp si,0fd95h
        jz _f806
        jmp inter2
;        cmp si,word ptr cs:[f803_adr]
;        jz _f803
;;        cmp si,0fe68h
;;        jz _f809
;        cmp si,word ptr cs:[f812_adr]
;        jz _f812
;        cmp si,word ptr cs:[f80c_adr]
;        jz _f80c
;        cmp si,word ptr cs:[f806_adr]
;        jz _f806
;        cmp byte ptr cs:[cMonitor],MON_M80_O
;        je inter2
;        cmp si,word ptr cs:[f81b_adr]
;        jz _f81b
;        jmp inter2

hook_u:
        cmp si,0fd57h
        jz _f803
        cmp si,0fd9ah
        jz _f81b
        cmp si,0fc43h
        jz _f809
        cmp si,0fe6bh
        jz _f812
        cmp si,0fbeeh
        jz _f80c
        cmp si,0fb71h
        jz _f806
        jmp inter2

inter6:
        jmp inter2

tick_count dw ? ; счетчик тактов 8080
init_mtick dw ? ; значение счетчика 8254 PC
count2 dw ?     ; счетчик до 20 мс

_f80c:
;        cmp byte ptr cs:[f_tape],TAPE_FILE
;        jne inter2
        call emf80c
        call emu_ret
        jmp interpret

_f80c_s:
;        cmp byte ptr cs:[f_tape],TAPE_FILE
;        jne inter2
        push cx
        mov cl,al
        call emf80c
        pop cx
        call emu_ret
        jmp interpret

_f806:
        cmp byte ptr cs:[f_tape],TAPE_FILE
        jne inter2
        call emf806
        call emu_ret
        jmp interpret

_f803:  call close_file ; Если работали с файлом, то его закрыть
        cmp byte ptr cs:[f_snd],SND_SB
        je inter2_sb
        cmp byte ptr cs:[f_vid],MEM_RW
        je inter6
        call store_regs
        call process50 ; Кто знает, сколько времени мы не нажимали на клавишу..
        call emf803
        cmp byte ptr cs:[f_reset],1        ; пров. на Reset, поскольку
        jne _f803_1                        ; окно настроек м.б. вызвано и
        call restore_regs
        call perform_reset
        mov byte ptr cs:[f_reset],0
       jmp inter2_x
_f803_1:
        cmp byte ptr cs:[f_snd],SND_SB
        je inter2_sb
        cmp byte ptr cs:[f_vid],MEM_RW
        je inter2
        call emu_ret
        jmp interpret

_f81b:  call close_file_delay ; Если работали с файлом, то его закрыть
;        cmp byte ptr cs:[f_snd],SND_SB
;        je inter2_sb
        cmp byte ptr cs:[f_vid],MEM_RW
        je inter6
        call store_regs
        call process50 ; Кто знает, когда следующие "20мс" истекут в этом режиме
        call emf81b
        cmp byte ptr cs:[f_reset],1        ; пров. на Reset, поскольку
        jne _f81b_1                        ; окно настроек м.б. вызвано и
        call restore_regs
        call perform_reset
        mov byte ptr cs:[f_reset],0
        jmp inter2_x
_f81b_1:
        cmp byte ptr cs:[f_snd],SND_SB
        je inter2_sb
        cmp byte ptr cs:[f_vid],MEM_RW
        je inter2
        call emu_ret
        jmp interpret                      ; из этого обработчика

inter2_x: cmp byte ptr cs:[f_snd],SND_SB
        je inter2_sb
        jmp inter2

_f809:  cmp byte ptr cs:[f_f809],HOOKF809_NO
        jz inter6
        call emf809
call emu_ret
;        mov si,0ffffh
        jmp interpret

_f812:  sahf
        call emf812
        lahf
        cmp byte ptr cs:[f_vid],MEM_RW
        je inter6
call emu_ret
;        mov si,0ffffh
        jmp interpret


;##############################################################

; сюда управление попадает 50 раз в секунду
inter7_1:
        mov word ptr cs:[count2],400
        push ax
  mov byte ptr cs:[vretr_cnt],28
        call process_int
        call process50
     cmp byte ptr cs:[f_scr],SCR_GRAPH
     jne inter11_1
     call refr_sg_scr

inter11_1:
  push ax bx cx dx si di ds
  mov ax,cs
  mov ds,ax
  call WaitSound
  pop ds di si dx cx bx ax
        call prep_key
        cmp byte ptr cs:[sysreq],0
        jz inter8_1

        pop ax
        push ax
        call store_regs
        mov byte ptr cs:[sysreq],0
        call flash_key
        call setparms
        cmp byte ptr cs:[f_reset],0
        jz inter11_3
        call perform_reset
        mov byte ptr cs:[f_reset],0
inter11_3:
        call restore_regs

inter8_1:
        pop ax
        jmp word ptr cs:[interpret_proc]

inter2_sb:
; Берем адрес процедуры из таблицы ...
        mov bp,word ptr cs:[c_table]
        push bx
;         push es
         mov bx, word ptr cs:[mem+2]
         cmp si,0f000h
         jb i_pag
         mov bx, word ptr cs:[mempage0+2]
i_pag:
         mov ds,bx
        xor bh,bh
         mov bl,byte ptr ds:[si]
;         pop es
        add bp,bx
        add bp,bx
        pop bx
        mov bp,word ptr cs:[bp]
; вызываем ее ...
       cmp byte ptr cs:[f_pause],0
       jnz ip2
        call bp
ip21:
        add bp,word ptr cs:[tick_count]
        mov word ptr cs:[tick_count],bp
;        sub bp,word ptr cs:[delay]
        sub bp,word ptr cs:[delay_sb]
        jae inter3_1
        jmp interpret_sb ; к следующей команде
ip2:    mov bp,10
        jmp ip21

; сюда управление попадает каждые 1/44100 с
inter3_1: mov word ptr cs:[tick_count],bp
        mov bp,word ptr cs:[init_mtick]
;        push ax
;inter4_1: call getcount
;        sub ax,bp
;        cmp ax,-119
;        ja inter4
;  sub ax,bp
;        add ax,bp
;        mov word ptr cs:[init_mtick],ax
;        pop ax
;  dec byte ptr cs:[vretr_cnt]
       call calc_pit
  cmp word ptr cs:[bWaitSnd],0
  je interpret_sb

  jmp inter7_1

;        dec word ptr cs:[count2]
;        jnz interpret_sb
;        jmp inter7_1

interpret_sb:
        cmp si,word ptr cs:[rom_adr]
        jb inter2_sb

        jmp word ptr cs:hook_proc_sb

;######################

hook_a_sb:
        cmp si,0fe61h
        jz _f803_sb
        cmp si,0fe70h
        jz _f81b_sb
        cmp si,0fc46h
        jz _f80c_sb
        cmp si,0fb98h
        jz _f806_sb
        jmp inter2_sb

hook_p_sb:
        cmp si,0fd7bh
        jz _f803_sb
        cmp si,0fce9h
        jz _f81b_sb
        cmp si,0fc55h
        jz _f80c_sb
        cmp si,0fba2h
        jz _f806_sb
        jmp inter2_sb

hook_r_sb:
        cmp si,0fe63h
        jz _f803_sb
        cmp si,0fe72h
        jz _f81b_sb
        cmp si,0fc46h
        jz _f80c_sb
        cmp si,0fb98h
        jz _f806_sb
        jmp inter2_sb

hook_m_sb:
        cmp si,0fed0h
        jz _f803_sb
        cmp si,0feeah
        jz _f81b_sb
        cmp si,0fcabh
        jz _f80c_sb
        cmp si,0fc0dh
        jz _f806_sb
        jmp inter2_sb

hook_s_sb:
        cmp si,0c337h
        jz _f803_sb
        cmp si,0ce5ch
        jz _f81b_sb
        cmp si,0c3d0h
        jz _f80c_s_sb
        cmp si,0c377h
        jz _f806_sb
        jmp inter2_sb

hook_o_sb:
        cmp si,0f803h
        jz _f803_sb
        cmp si,0faeeh
        jz _f81b_sb
;        cmp si,0fa53h
        cmp si,word ptr cs:[f80c_adr]
        jz _f80c_sb
;        cmp si,0f9cdh
        cmp si,word ptr cs:[f806_adr]
        jz _f806_sb
        jmp inter2_sb

hook_m80_sb:
        cmp si,0ff41h
        jz _f803_sb
        cmp si,0fde6h
        jz _f80c_sb
        cmp si,0fd95h
        jz _f806_sb
        jmp inter2_sb

hook_u_sb:
        cmp si,0fd57h
        jz _f803_sb
        cmp si,0fd9ah
        jz _f81b_sb
        cmp si,0fbeeh
        jz _f80c_sb
        cmp si,0fb71h
        jz _f806_sb
        jmp inter2

inter6_sb:
        jmp inter2_sb

_f80c_sb:
        cmp byte ptr cs:[f_tape],TAPE_FILE
        jne inter2_sb
        call emf80c
        call emu_ret
        jmp interpret_sb

_f80c_s_sb:
        cmp byte ptr cs:[f_tape],TAPE_FILE
        jne inter2_sb
        push cx
        mov cl,al
        call emf80c
        pop cx
        call emu_ret
        jmp interpret_sb

_f806_sb:
        cmp byte ptr cs:[f_tape],TAPE_FILE
        jne inter2_sb
        call emf806
        call emu_ret
        jmp interpret_sb

_f803_sb:
        call close_file ; Если работали с файлом, то его закрыть
        jmp inter6_sb

_f81b_sb:
        call close_file_delay ; Если работали с файлом, то его закрыть
        jmp inter6_sb

;##############################################################


store_regs proc
        mov word ptr cs:[reg_af],ax
        mov word ptr cs:[reg_bc],cx
        mov word ptr cs:[reg_de],dx
        mov word ptr cs:[reg_hl],bx
        mov word ptr cs:[reg_sp],di
        mov word ptr cs:[reg_pc],si
        ret
store_regs endp

restore_regs proc
        mov ax, word ptr cs:[reg_af]
        mov cx, word ptr cs:[reg_bc]
        mov dx, word ptr cs:[reg_de]
        mov bx, word ptr cs:[reg_hl]
        mov di, word ptr cs:[reg_sp]
        mov si, word ptr cs:[reg_pc]
        ret
restore_regs endp

end
