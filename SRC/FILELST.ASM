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

public choose_file_name
public save_scr
public rest_scr
public ext_letter

extrn filename:byte
extrn f_file_ss:byte
extrn cModel:byte
;extrn outtextxy2:near

jumps

.code

ext_letter db 'R' ; последняя буква расширения RKx для текущего ПК

choose_file_name proc
        push es
        call clear_list
        mov cx,0
        call get_list
        call sort_list
        call display_list
        call clear_list
        pop es
        ret
choose_file_name endp

pattern db '*.*',0

files_qnt dw ?
;dirs_qnt dw ?
list_ptr dw ?

get_list proc
        mov ah,4eh
        lea dx,pattern
gl2:    int 21h
        jc gl1
        test cx,cx
        jz gl3
        mov al,byte ptr ds:[80h+21]
        and al,cl
        jz gl4
        cmp word ptr ds:[80h+30],002eh
        jz gl4
gl3:    mov bx,80h+30
        call add_list
;       test cx,cx
;       jz gl5
;       inc word ptr [dirs_qnt]
;       jmp gl4
gl5:    inc word ptr [files_qnt]
gl4:    mov ah,4fh
        jmp gl2
gl1:    ret
get_list endp

clear_list proc
        xor ax,ax
        mov word ptr [files_qnt],ax
;       mov word ptr [dirs_qnt],ax
        cmp word ptr [list_ptr],0
        jz cl1
        mov ax, word ptr [list_ptr]
        mov es,ax
        mov ah,49h
        int 21h
        jc malloc_error
        mov word ptr [list_ptr],0
cl1:    ret
clear_list endp

; ds:bx - name (13 chars)
add_list proc
        mov di,word ptr [list_ptr]
        test di,di
        jnz al3
        mov ah,48h
        push bx
        mov bx,1
        int 21h
        pop bx
        jc malloc_error
al5:    mov word ptr [list_ptr],ax
        add ax, word ptr [files_qnt]
        mov es,ax
        xor di,di
        jmp al4
al3:    mov ah,4ah
        push bx
        mov bx,word ptr [files_qnt]
        add bx,1 ; ###
        mov es,di
        int 21h
        jc al7
        pop bx
        jmp al5
al4:    mov cx,16
al6:    mov al,byte ptr ds:[bx]
        inc bx
        stosb
        loop al6
;        sub bx,16
;al2:   mov al,[bx]
;       test al,al
;       jz al1
;       int 29h
;       inc bx
;       jmp al2
;al1:   mov al,0dh
;       int 29h
;       mov al,0ah
;       int 29h
        ret
al8:    pop bx
        jmp malloc_error
al7:    mov bx,word ptr [files_qnt]
        add bx,1 ; ###
        mov ah,48h
        int 21h
        jc al8
        push ax
        push ds
        push es
        mov cx,es
        mov ds,cx       
        mov es,ax
        xor si,si
        xor di,di
        cld
        mov cx,bx
        add cx,cx
        add cx,cx
        add cx,cx
        rep movsw
        pop es
        pop ds
        mov ah,49h
        int 21h
        pop ax
        pop bx
        jmp al5
add_list endp

malloc_error proc
        mov ax,cs
        mov ds,ax
        lea dx,err_mes
        mov ah,9
        int 21h
        int 20h
err_mes  db 'Ошибка выделения памяти !',13,10,'$'
malloc_error endp

; Сохраняет экран в буфере. AX=дескриптор буфера.
save_scr proc
        push es
        push si
        push di
        push cx
        push bx
; Выделяем буфер для сохранения экрана
        mov ah,48h
        mov bx,80*25*2/16
        int 21h
        jc malloc_error
        mov word ptr [scr_buf],ax
        push ax
; Копируем экран в буфер
        push ds
        mov ax,0b800h
        mov ds,ax
        xor si,si
        mov di,word ptr cs:[scr_buf]
        mov es,di
        xor di,di
        mov cx,80*25
        cld
        rep movsw
        pop ds
        pop ax

        pop bx
        pop cx
        pop di
        pop si
        pop es
        ret
save_scr endp

; Восстанавливает экран из буфера. AX=дескриптор буфера.
rest_scr proc
; Восстанавливаем экран из буфера
        push es
        push ax
        push di
        push si
        push cx

        push ds
        mov word ptr [scr_buf],ax
        mov ax,0b800h
        mov es,ax
        xor di,di
        mov si, word ptr cs:[scr_buf]
        mov ds,si
        xor si,si
        mov cx,80*25
        cld
        rep movsw
        pop ds
; Освобождаем буфер экрана
        mov ax,word ptr [scr_buf]
        mov es,ax
        mov ah,49h
        int 21h
;        jc malloc_error
        pop cx
        pop si
        pop di
        pop ax
        pop es
        ret
rest_scr endp

display_list proc
        mov ah,3
        xor bh,bh
        int 10h
        push dx
        mov ah,2
        xor bh,bh
        mov dx,0ffffh
        int 10h

        call save_scr
        push ax

        call draw_frame
        mov word ptr [upper_file_no],0
        mov word ptr [cur_file_no],0
        call print_list

dl1:    mov ax,0
        int 16h
        cmp al,1bh ; Esc
        je dl6
        cmp al,0dh ; Enter
        je dl4
        cmp ax,5000h ; \/
        jne dl2
        mov ax,word ptr [cur_file_no]
        inc ax
        cmp ax, word ptr [files_qnt]
        jae dl1
        mov word ptr [cur_file_no],ax
        sub ax,word ptr [upper_file_no]
        cmp ax,word ptr [max_files_qnt]
        jb dl3
        inc word ptr [upper_file_no]
dl3:    call print_list
        jmp dl1
dl2:    cmp ax,4800h ; /\
        jne dl8
        mov ax,word ptr [cur_file_no]
        dec ax
        cmp ax,0
        jl dl1
        mov word ptr [cur_file_no],ax
        sub ax,word ptr [upper_file_no]
        jnl dl5
        dec word ptr [upper_file_no]
dl5:    call print_list
        jmp dl1
dl8:    cmp ax,5100h ; PgDn
        jne dla
        mov ax,word ptr [upper_file_no]
        add ax,23
        cmp ax, word ptr [files_qnt]
        jae dl1
        mov word ptr [upper_file_no],ax
        mov ax,word ptr [cur_file_no]
        add ax,23
        sub ax, word ptr [files_qnt]
        jl dl9
        sub ax,22
        neg ax
        add word ptr [cur_file_no],ax
        jmp dlc
dl9:    add word ptr [cur_file_no],23
dlc:    call print_list
        jmp dl1
dla:    cmp ax,4900h ; PgUp
        jne dl1
        mov ax,word ptr [cur_file_no]
        sub ax,23
        jl dl1
        mov word ptr [cur_file_no],ax
        mov ax,word ptr [upper_file_no]
        cmp ax,23
        jle dld
        sub word ptr [upper_file_no],23
        jmp dlb
dld:    mov word ptr [upper_file_no],0
dlb:    call print_list
        jmp dl1

dl4:    mov ax,word ptr [list_ptr]
        add ax,[cur_file_no]
        push ds
        mov ds,ax
        xor si,si
        push es
        lea di,filename
        mov ax,cs
        mov es,ax
        mov cx,10h
        cld
        rep movsb
        pop es
        pop ds
        jmp dl7
dl6:    mov byte ptr cs:[filename],0
dl7:    pop ax
        call rest_scr
        mov ah,2
        xor bh,bh
        pop dx
        int 10h
        ret
display_list endp

scr_buf dw ?

; Рисует рамку
draw_frame proc
        push es
        mov ax,0b800h
        mov es,ax

        mov di,80-14
        mov ah,0fh
        mov al,'╔'
        cld
        stosw
        mov al,'═'
        mov cx,12
        rep stosw
        mov al,'╗'
        stosw

        mov di,(80-14)+24*80*2
        mov al,'╚'
        stosw
        mov al,'═'
        mov cx,12
        rep stosw
        mov al,'╝'
        stosw

        mov di,(80-14)+80*2
        mov al,'║'
        mov cx,23
df1:    stosw
        push ax
        mov al,' '
        push cx
        mov cx,12
        rep stosw
        pop cx
        pop ax
        stosw
        add di,80*2-28
        loop df1

;        lea si,list_hint
;        mov dx,1822h
;        mov ah,0fh
;        call outtextxy2

        pop es
        ret
;list_hint db '  Pg Pg '
draw_frame endp

cur_file_no dw ?
upper_file_no dw ?
max_files_qnt dw ?

print_list proc
        push ds
        push es
        mov ax,word ptr [files_qnt]
        sub ax,word ptr [upper_file_no]
        cmp ax,23
        jna pl5
        mov ax,23
pl5:    mov word ptr [max_files_qnt],ax
;        cmp word ptr [max_files_qnt],0
;        je pl1
        mov ax,0b800h
        mov es,ax
        mov di,80-14+2+160
        mov cx,word ptr [upper_file_no]
pl4:    mov ax,cx
        push ax
        sub ax,cs:[upper_file_no]
        cmp ax,word ptr cs:[max_files_qnt]
        pop ax
        jae pl6
        push di
        add ax,word ptr cs:[list_ptr]
        mov ds,ax
        xor si,si
        cld
; Анализируем расширение
        mov ah,07h
pl10:   lodsb
        cmp al,0
        je pl11
        cmp al,'.'
        jne pl10
        lodsb
        push cx
        mov cl,al
        lodsw
        call anal_ext
        pop cx

pl11:   xor si,si
pl3:    lodsb
        test al,al
        jz pl2
        stosw
        jmp pl3
pl2:    mov al,' '
        cmp byte ptr es:[di],'║'
        je pl8
        stosw
        jmp pl2
pl8:    pop di
        add di,80*2
        inc cx
        jmp pl4

pl6:
        mov ax,word ptr cs:[cur_file_no]
        sub ax,word ptr cs:[upper_file_no]
        mov bl,160
        mul bl
        mov bx,160+80-14+2
        add bx,ax
        inc bx
        mov cx,12
        mov al,byte ptr es:[bx]
        and al,0fh
        or al,30h
        cmp al,37h
        jne pl7
        mov al,30h
pl7:    mov byte ptr es:[bx],al
        inc bx
        inc bx
        loop pl7

        mov cx,23
        sub cx, cs:[max_files_qnt]
        jz pl1
        mov ax, cs:[max_files_qnt]
        mov bl,160
        mul bl
        mov di,ax
        add di,160+80-14+2
        cld
        mov ax,0f00h
pl9:    push cx
        mov cx,12
        rep stosw
        pop cx
        add di,160-24
        loop pl9

pl1:    pop es
        pop ds
        ret
print_list endp

; Анализирует расширение в CL, AL, AH и возвращает атрибут в AH
anal_ext proc
        cmp byte ptr cs:[f_file_ss],1
        je aeSS
        cmp byte ptr cs:[f_file_ss],2
        je aeODI
        cmp cl,'B'
        je aeB
        cmp cl,'E'
        je aeE
        cmp cl,'G'
        je aeG
        cmp cl,'P'
        je aeP
        cmp cl,'R'
        je aeR
        jmp aeRET
aeB:    cmp ax,'MS'
        jne aeB1
        mov ah,0eh
        ret
aeB1:   cmp ax,'SS'
        jne aeRET
        mov ah,0ch
        ret
aeE:    cmp ax,'MD'
        jne aeRET
        mov ah,09h
        ret
aeG:    cmp ax,'MA'
        jne aeRET
        cmp byte ptr cs:[ext_letter],'R'
        jne aeRET
        mov ah,0bh
        ret
aeP:    cmp ax,'IK'
        jne aeRET
        mov ah,06h
        ret
aeR:    cmp al,'K'; cmp ax,004bh ;RK
        jne aeRET
aeR_3:  cmp byte ptr cs:[ext_letter],'S'
        je aeR_2
        cmp byte ptr cs:[ext_letter],'O'
        je aeR_2
        test ah,ah
        jz aeR_1
aeR_2:  cmp ah, byte ptr cs:[ext_letter]
        jne aeRET
aeR_1:  mov ah,0ah
        ret                
aeRET:  mov ah,07h
        ret
aeSS:   cmp byte ptr cs:[cModel],MODEL_O
        jne aeSS1
        cmp cl,'B'
        jne aeSS3
        cmp ax,'UR'
        jne aeRET
        mov ah,0dh
        ret
aeSS3:  cmp cl,'O'
        jne aeSS2
        cmp ax,'ID'
        jne aeRET
        mov ah,0eh
        ret

aeSS2:  cmp cl,'R'
        jne aeRET
;        jmp aeSS3
aeSS1:  cmp cl,'R'
        jne aeRET
        cmp al,'K'
        je aeR_3 ; загр. снапшота - расш. РК?
        cmp ax,'SS'
        jne aeRET
        mov ah,0bh
        ret
aeODI:  cmp cl,'O'
        jne aeRET
        cmp ax,'ID'
        jne aeRET
        mov ah,0bh
        ret
anal_ext endp

sort_list proc
        mov si,word ptr [list_ptr]
        test si,si
        jz sl1
        push ds
        push es
        mov ds,si
        xor si,si
        mov bp,word ptr cs:[files_qnt]

sl2:    cmp bp,1
        jbe sl3

        ;es:di=ds:si+16
        mov di,ds
        inc di
        mov es,di
        xor di,di

        lea cx,[bp-1]
sl4:    call cmp_and_exchg
        mov ax,es
        inc ax
        mov es,ax
        loop sl4

        mov ax,ds
        inc ax
        mov ds,ax
        dec bp
        jnz sl2

sl3:    pop es
        pop ds
sl1:    ret
sort_list endp

cmp_and_exchg proc
        push si
        push di

        cld
        push si
        push di

cae5:   lodsb
        cmp al,'.'
        je cae6
        cmp al,0
        je cae6
        jmp cae5
cae6:   dec si
cae7:   mov al,byte ptr es:[di]
        cmp al,'.'
        je cae8
        cmp al,0
        je cae8
        inc di
        jmp cae7
cae8:   lodsb
        mov ah,byte ptr es:[di]
        inc di
        cmp al,ah
        ja cae12
        jb cae13
        test ax,ax
        jz cae10
        jmp cae8
cae10:  pop di
        pop si

cae4:   lodsb
        mov ah,byte ptr es:[di]
        inc di
        cmp al,ah
        ja cae2
        jb cae3
        test ax,ax
        jz cae3
        jmp cae4

cae13:  pop di
        pop si
        jmp cae3

cae12:  pop di
        pop si

cae2:   pop di
        pop si
        push di
        push si
        push cx
        mov cx,16
        cld
cae1:   lodsb
        mov ah,byte ptr es:[di]
        stosb
        mov byte ptr ds:[si-1],ah
        loop cae1
        pop cx
cae3:   pop di
        pop si
        ret
cmp_and_exchg endp

end
