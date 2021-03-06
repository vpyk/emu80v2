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

;File: EMUROM.ASM

; ����ন� ��楤���, �������騥 ������� �⠭����� �� ���

INCLUDE EMU80.INC

.model tiny

public emF809
public emF803
public emF81B
public emF812
public emF80C
public emF806
public symtable_ptr
public cur_offs
public refresh_scr
public sh_height
public sh_width
public sh_scrbeg
public sh_scrlen
public close_file
public close_file_delay
public begin_scr
public cur_off_rom
public draw_scr_beg
public draw_scr_len
public romvar_addr
public curpos_addr
public f_novesa
public refr_sg_scr
public draw_scr_or
public f_refr_txt_scr
;public set_graph_mode

extrn fin:near
extrn setparms:near
extrn f_reset:byte
extrn f_vid:byte
extrn f_snd:byte
extrn getfilename:near
extrn filename:byte
extrn test_key:near
extrn get_key:near
extrn prep_key:near
extrn scr_beg:word
extrn scr_end:word
extrn f_scr:byte
extrn f_refr:byte
extrn f_font:byte
extrn set_new_09_vect:near
extrn restore_09_vect:near
extrn cur_xy:word
extrn f_choose_file:byte
extrn f_file_ss:byte
extrn f_synb:byte
extrn cur_corr:word
extrn cModel:byte
extrn test_sys_key:near
extrn sysreq:byte
extrn sysreq_code:byte
extrn set_text_mode:near
extrn write_byte_spec:word
extrn write_byte_spec_640:near
extrn write_byte_spec_800:near
extrn write_byte_orion:word
extrn write_byte_orion_640:near
extrn write_byte_orion_800:near
extrn mem:dword
extrn color_mem:dword
extrn cur_color_code:byte
extrn StopSound:near
extrn DrawScr:near
extrn dma_begadr:word
extrn dma_len:word
extrn mempage0:dword
extrn mempage1:dword
extrn old_or_colormode:byte
extrn old_or_scrpage:byte
extrn mikr_symg:byte

.code

jumps

; ��砫� �।��� ��� ��࠭��� ������ 64x25
begin_scr dw ?

cur_off_rom dw ?
draw_scr_beg dw ?
draw_scr_len dw ?
romvar_addr dw ?
curpos_addr dw ?

; ������, 㧠�뢠�騩, �� �ॡ���� ����ᮢ�� ⥪�⮢��� ��࠭�
; ��᫥ ����� ���� ��ਡ�⮢ (�ந�������� �� �� 50 ࠧ � ᥪ㭤�)
f_refr_txt_scr db 0

;��६����, ��।����騥 ०�� ��ᯫ�� � ०��� ���
sh_scrbeg dw 76d0h  ; ��砫� ��࠭��� ������
sh_height db 30     ; ������⢮ ��ப
sh_width db 78      ; ������⢮ ᨬ����� � ��ப�
sh_scrlen dw 78*30  ; ����� ��࠭��� ������ (���筮 sh_width*sh_height)

s_startline db 0    ; ����� ᢥ��� �� �⮡ࠦ���� �� PC

close_file_cnt dw 0 ; ���稪 �맮�� 0f81b. �� ���⨦���� 500 ���� 䠩�

;####===-- ������ 0F809H --===####
; �뢮� ᨬ���� �� ��࠭
; �室:
; C - �뢮���� ᨬ���

emF809: push ax
        push bx
        push cx
        push dx

        and cl,7fh
        
        cmp es:curstate,0
        je em09_g
        jmp em09stt

em09_g: cmp cl,20h      
        jl em09_b
        jmp em09norm

em09_b: cmp cl,8        ; ��५�� �����
        jne em09_1
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        dec dl
        cmp dl,-1
        je em09_c
        jmp em09spos
em09_c: mov dl,63
        dec dh
        cmp dh,-1
        je em09_d
        jmp em09spos
em09_d: mov dh,24
        jmp em09spos

em09_1:
        cmp cl,18h      ; ��५�� ��ࠢ�
        jne em09_2
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        inc dl
        cmp dl,64
        je em09_e
        jmp em09spos
em09_e: mov dl,0
        inc dh
        cmp dh,25
        je em09_f
        jmp em09spos
em09_f: mov dh,0
        jmp em09spos

em09_2:
        cmp cl,19h      ; ��५�� �����
        jne em09_3
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        dec dh
        cmp dh,-1
        jne em09spos
        mov dh,24
        jmp em09spos

em09_3:
        cmp cl,1ah      ; ��५�� ����
        jne em09_4
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        inc dh
        cmp dh,25
        jne em09spos
        mov dh,0
        jmp em09spos

em09_4:
        cmp cl,7h       ; ��㪮��� ᨣ���
        jne em09_5
        mov ax,0e07h
        mov bx,0
        int 10h
        jmp em09exit

em09_5:
        cmp cl,0ch      ; HOME
        jne em09_6
        mov dx,0
        jmp em09spos

em09_6:
        cmp cl,0dh      ; ��
        jne em09_7
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        mov dl,0
        jmp em09spos

em09_7:
        cmp cl,0ah      ; ��
        jne em09_8
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        jmp em09_a

em09spos:
        mov bx,word ptr cs:[curpos_addr]
        mov word ptr ds:[bx],dx
        push cx
        mov cx,word ptr cs:[cur_off_rom]
        mov bx,word ptr cs:[curpos_addr]
        add word ptr ds:[bx],cx 
        pop cx
        jmp em09exit

em09_8:
        cmp cl,1fh      ; ���⪠ ��࠭� - ���
        jne em09_9
        mov ax,0600h
        mov cx,0
        mov dx,word ptr es:[scr_dim]
        mov bh,7
        int 10h
        push es
        push di
        mov dx,ds
        mov es,dx
        mov di,word ptr cs:[draw_scr_beg]
        mov cx,word ptr cs:[draw_scr_len]
        xor al,al
        cld
        rep stosb
        pop di
        pop es
        mov dx,0
        jmp em09spos

em09_9:
        cmp cl,1bh      ; ��2 (ESC)
        jne em09norm
        mov es:curstate,1
        jmp em09quit


em09norm: 
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        mov bh,78
        mov al,dh
        mul bh
        xor dh,dh
        add ax,dx
        mov bx,ax
        add bx, word ptr cs:[begin_scr]
        mov ds:[bx],cl

        mov bx,cs:[symtable_ptr]
        mov al,cl
        xlat byte ptr es:symtable_ptr
        call pos_cursor_mon

        mov ah,0ah
        mov cx,1
        mov bx,0
        int 10h
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        inc dl
        mov bx,word ptr cs:[curpos_addr]
        mov word ptr ds:[bx],dx
        mov bx,word ptr cs:[curpos_addr]
        mov ax,word ptr cs:[cur_off_rom]
        add word ptr ds:[bx],ax
        cmp dl,64
        jne em09exit
        mov bx,word ptr cs:[curpos_addr]
        mov byte ptr ds:[bx],0
        mov ax,word ptr cs:[cur_off_rom]
        add byte ptr ds:[bx],al
em09_a: inc dh
        mov bx,word ptr cs:[curpos_addr]
        mov ds:[bx+1],dh
        mov ax,word ptr cs:[cur_off_rom]
        add byte ptr ds:[bx+1],ah
        cmp dh,25
        jne em09exit
        mov byte ptr ds:[bx+1],24
        add byte ptr ds:[bx+1],ah
        mov ax,0601h
        mov bh,07h
        mov cx,word ptr es:[cur_offs]
        xor cl,cl
        mov dx,word ptr es:[scr_dim]
        int 10h
        push es
        push si
        push di
        mov dx,ds
        mov es,dx
        mov si,word ptr cs:[begin_scr]
        add si,78
        mov di,word ptr cs:[begin_scr]
        mov cx,78*25
        cld
        rep movsb
        pop di
        pop si
        pop es
em09exit:        
        call pos_cursor_mon
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        sub dx,word ptr cs:[cur_off_rom]
        mov cl,78
        mov al,dh
        mul cl
        xor dh,dh
        add ax,dx
        add ax,word ptr cs:[begin_scr]
        mov bx,word ptr cs:[romvar_addr]
        mov word ptr ds:[bx],ax
em09quit:        
        pop dx
        pop cx
        pop bx
        pop ax
        ret

em09stt:
        cmp es:[curstate],1
        jne em09_10
        cmp cl,59h
        jne em09stterr
        mov es:[curstate],2
        jmp em09quit
em09_10:
        cmp es:[curstate],2
        jne em09_11
        sub cl,20h
        mov bx,word ptr cs:[curpos_addr]
        mov ds:[bx+1],cl
        mov ax,word ptr cs:[cur_off_rom]
        add byte ptr ds:[bx+1],ah
        mov es:[curstate],3
        jmp em09quit
em09_11:
        sub cl,20h
        mov bx,word ptr cs:[curpos_addr]
        mov byte ptr ds:[bx],cl
        mov ax,word ptr cs:[cur_off_rom]
        add byte ptr ds:[bx],al
        mov es:[curstate],0
        jmp em09exit
em09stterr:
        mov es:[curstate],0
        jmp em09quit

pos_cursor proc
        push ax
        push bx
        push dx
        mov dx,word ptr es:[cur_xy]
        sub dx,word ptr cs:[cur_corr]
        add dx,word ptr es:[cur_offs]
        mov ah,2
        mov bh,0
        int 10h
        pop dx
        pop bx
        pop ax
        ret
pos_cursor endp

pos_cursor_mon proc
        push ax
        push bx
        push dx
        mov bx,word ptr cs:[curpos_addr]
        mov dx,word ptr ds:[bx]
        mov word ptr es:[cur_xy],dx
        sub dx,word ptr cs:[cur_off_rom]
        add dx,word ptr es:[cur_offs]
        mov ah,2
        mov bh,0
        int 10h
        pop dx
        pop bx
        pop ax
        ret
pos_cursor_mon endp

curstate db 0

; ������ ᨬ���쭠� ⠡���
symtable_ptr dw symtable

; ������ ��४���஢�� ��� CP866
symtable:
 db 0,'������� ',15,' ',24,'  ',26,25
 db '��������   ��',27,9,' '
 db ' !"#$%&',27h,'()*+,-./'
 db '0123456789:;<=>?'
 db '@ABCDEFGHIJKLMNO'
 db 'PQRSTUVWXYZ[\]^_'
 db '����������������'
 db '����������������'

; ������ ��४���஢�� ��� ����㦠����� ������������ ��
symtablerk:
 db 00h,01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh
 db 10h,11h,12h,13h,14h,15h,16h,17h,18h,19h,1Ah,1Bh,1Ch,1Dh,1Eh,1Fh
 db 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2Ah,2Bh,2Ch,2Dh,2Eh,2Fh
 db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3Ah,3Bh,3Ch,3Dh,3Eh,3Fh
 db 40h,41h,42h,43h,44h,45h,46h,47h,48h,49h,4Ah,4Bh,4Ch,4Dh,4Eh,4Fh
 db 50h,51h,52h,53h,54h,55h,56h,57h,58h,59h,5Ah,5Bh,5Ch,5Dh,5Eh,5Fh
 db 0D0h,0D1h,0D2h,0D3h,0D4h,0D5h,0D6h,0D7h
 db 0D8H,0D9h,0DAh,0DBh,0DCh,0DDh,0DEh,0DFh
 db 0F0h,0F1h,0F2h,0F3h,0F4h,0F5h,0F6h,0F7h
 db 0F8H,0F9h,0FAh,0FBh,0FCh,0FDh,0FEh,0FFh

; ������ ��४���஢�� ��� ��ண� ������������ �����
symtablemikr2:
 db 00h,0BCh,0C9h,0BBh,0CCh,0CEh,0CBh,0CAh,0BAh,0CDh,00h,0CEh,0C8h,00h,0Fh,0Bh
 db 0Eh,1Dh,2Ah,2Ah,2Ah,2Ah,09h,0B0h,0B0h,0Eh,0B0h,09h,0B0h,1Eh,0B0h,0B0h
 db 20h,21h,22h,23h,24h,25h,26h,27h,28h,29h,2Ah,2Bh,2Ch,2Dh,2Eh,2Fh
 db 30h,31h,32h,33h,34h,35h,36h,37h,38h,39h,3Ah,3Bh,3Ch,3Dh,3Eh,3Fh
 db '椥�娩�����'
 db '�����㦢������',017h
 db '����������������'
 db '���������������',017H


;####===-- ������ 0F803H --===####
; ���� ᨬ���� � ���������� � ��������� ������
; ��室:
; A - ��⠭�� ᨬ���

emF803: push bx
        push cx
        push dx

em03_1:
;       mov ax,0
;       int 16h
        call get_key
        
        call test_sys_key ;F10
        ; cmp ah,44h
        jne em03_2
        call setparms
        mov byte ptr cs:[sysreq],0
        cmp byte ptr es:[f_reset],1
        je em03exit
        cmp byte ptr es:[f_snd],SND_SB
        je em03exit
        cmp byte ptr es:[f_vid],MEM_RW
        je em03exit
        jmp em03_1
em03_2:
        call scan2rk
        cmp al,'�'
        je em03_1

em03exit:        
        pop dx
        pop cx
        pop bx
        ret

; ������ ��४���஢�� ��� ����������
keytable:
 db '@ABCDEFGHIJKLMNO'
 db 'PQRSTUVWXYZ[\]^_'
 db 'abwgdevzijklmnop'
 db 'rstufhc~{}',27h,'yx|`q'
 db 'abwgdevzijklmnop'
 db '����������������'
 db '����������������'
 db '����������������'
 db 'rstufhc~{}',27h,'yx|`q'
 db '����������������'

; ������ ��४���஢�� ���������� ��� ���७��� ������
; ����� ⠡���� - db 0
keytbl2:
 db 4bh,8h
 db 4dh,18h
 db 48h,19h
 db 50h,1ah
 db 47h,0ch
 db 3bh,0h
 db 3ch,1h
 db 3dh,2h
 db 3eh,3h
 db 3fh,4h
 db 53h,1h
 db 52h,3h
 db 49h,1fh
 db 0

; �८�ࠧ�� ᪠�-��� ������ � ��� ������ ��, �ᯮ���� keytbl2
scan2rk proc
        cmp al,0
        je srk_ext
        cmp al,0e0h
        jne srk5
        test ah,ah
        jne srk_ext
        
srk5:   cmp al,60h
        jb srk_tstbsp
        sub al,60h
        lea bx,keytable
        xlat byte ptr es:keytable
        ret
srk_tstbsp:
        cmp ax,0e08h
        je srk_4
        ret
srk_4:        
        mov al,7fh
        ret
srk_ext:
        lea bx,keytbl2
srk_2:  
        cmp ah,byte ptr es:[bx]
        je srk_3
        inc bx
        inc bx
        cmp byte ptr es:[bx],0
        jne srk_2
        mov al,'�'
        ret
srk_3:
        mov al,byte ptr es:[bx+1]
        ret
scan2rk endp

;####===-- ������ 0F81BH --===####
; ���� ᨬ���� � ���������� ��� �������� ������
; ��室:
; A - ��⠭�� ᨬ��� (FF - ������ �� �����, FE - ������ ���/���)
emF81B: push bx
        push cx
        push dx
        
em1b_4: ;mov ah,01h
;        int 16h
        call test_key
        
        jz em1b_3
        
;        mov ah,0
;        int 16h
        call get_key

        call test_sys_key ;F10
        ;cmp ah,44h
        jne em1b_2
        call setparms
        mov byte ptr cs:[sysreq],0
        cmp byte ptr es:[f_reset],1
        je em1bexit
        cmp byte ptr es:[f_snd],SND_SB
        je em1bexit
        cmp byte ptr es:[f_vid],MEM_RW
        je em1bexit
        jmp em1b_4
em1b_3:
        push es
        mov ax,40h
        mov es,ax
        mov al,es:[17h]
        pop es
        and al,08h
        mov al,0ffh
        jz em1bexit
        mov al,0feh
        jmp em1bexit

em1b_2:
        call scan2rk
        cmp al,'�'
        jne em1bexit
        mov al,0ffh

em1bexit:        
        pop dx
        pop cx
        pop bx
        ret



;####===-- ������ 0F812H --===####
; �஢�ઠ ������ ������

emF812: push bx
        push cx
        push dx

;       mov ah,01h
;       int 16h
        call test_key

        mov al,0
        jz em12_1
        mov al,0ffh
em12_1: test al,al
        pop dx
        pop cx
        pop bx
        ret

; ���� - 1, �᫨ �ந�室�� �⥭�� �� 䠩��
f_file_open db 0

; ���ਯ�� 䠩�� ��� 0 �� �訡��
file_id dw 0

; ����訢��� ��� � ���뢠�� 䠩� �� ������
; �᫨ ��⠭����� �ਧ��� ����� ᨭ�஡���,
; � �����뢠�� ��� (0E6H)
open_file_write proc
        call restore_09_vect
        mov byte ptr cs:[f_choose_file],0
        mov byte ptr cs:[f_file_ss],0
       call set_text_mode
       call StopSound
        call getfilename
       call restore_mode
       call set_appropr_09_vect
        lea dx,filename
        mov cx,20h
        mov ah,3ch
of0:    int 21h
        mov word ptr [file_id],0
        jc of1
        mov word ptr [file_id],ax
of1:    mov byte ptr [f_file_open],1
        cmp byte ptr [f_synb],0
        jz of2
        cmp word ptr [file_id],0
        jz of2

        ; ��襬 ᨭ�஡���
        mov bx,ax
        mov cx,1
        lea dx,syn_byte
        mov ah,40h
        int 21h

of2:    ret
syn_byte db 0e6h
open_file_write endp

; ����訢��� ��� � ���뢠�� 䠩� �� �⥭��
; �᫨ �ଠ� � ᨭ�஡��⮬, � �ய�᪠�� ���� ���� (0E6H)
open_file_read proc
        call restore_09_vect
        mov byte ptr cs:[f_choose_file],1
        mov byte ptr cs:[f_file_ss],0
       call set_text_mode
       call StopSound
        call getfilename
       call restore_mode
        call set_appropr_09_vect
        lea dx,filename
        xor cl,cl
        mov ax,3d00h
        int 21h
        mov word ptr [file_id],0
        jc ofr3
        mov word ptr [file_id],ax
ofr3:   mov byte ptr [f_file_open],1
; �஢��塞 �ଠ�
        ; ��⠥� ���� 5 ����
        mov bx,word ptr [file_id]
        test bx,bx
        jz ofr1
        mov cx,5
        lea dx,first_5_bytes
        mov ah,3fh
        int 21h
        test ax,ax
        jz ofr1
        ; ����⠭�������� ������ � 䠩��
        push ax
        mov ax,4200h
        mov bx,word ptr [file_id]
        xor cx,cx
        xor dx,dx
        int 21h
        ; ��������㥬 �ଠ�
        pop ax
        cmp byte ptr [first_5_bytes],0e6h
        jne ofr1
        cmp ax,5
        jne ofr2
        cmp word ptr [first_5_bytes+1],0e6e6h
        jne ofr2
        cmp word ptr [first_5_bytes+3],0e6e6h
        je ofr2
        cmp byte ptr [first_5_bytes+4],0e6h
        jne ofr1
ofr2:   mov bx,word ptr [file_id] ; �ய�᪠�� ���� ���� E6
        mov cx,1
        lea dx,first_5_bytes
        mov ah,3fh
        int 21h
ofr1:   ret        
first_5_bytes db 5 dup (0)
open_file_read endp

; ����뢠�� ������ 䠩�
close_file proc
        mov word ptr cs:[close_file_cnt],0
        push ax
        push bx
        mov byte ptr es:[f_sync_found],0
        cmp byte ptr es:[f_file_open],0
        jz cf1
        mov byte ptr es:[f_file_open],0
        mov bx,word ptr es:[file_id]
        test bx,bx
        jz cf1
        mov ah,3eh
        int 21h
cf1:    pop bx
        pop ax
        ret
close_file endp

; ����뢠�� ������ 䠩�, �᫨ �맢��� �����, 祬 500 ࠧ
close_file_delay proc
        inc word ptr cs:[close_file_cnt]
        cmp word ptr cs:[close_file_cnt],500
        jne cfd1
        call close_file
cfd1:   ret
close_file_delay endp

; ����騩 �⠥�� �� 䠩�� ����
cur_byte db ?

; ���� - 1, �᫨ ������ ���� ᨭ�஡��� (⠪�� �� �����)
f_sync_found db 0

; ���� ���� � 䠩� (⮫쪮 �᫨ 㦥 �� ᨭ�஡���)
write_file proc
        mov word ptr cs:[close_file_cnt],0
        cmp byte ptr [f_file_open],1
        je wf2
        call open_file_write
wf2:    mov bx,word ptr [file_id]
        test bx,bx
        jz wf1
        cmp byte ptr [f_sync_found],0
        jnz wf3
        cmp al,0e6h     ; ᨭ�஡���
        jne wf1
        mov byte ptr [f_sync_found],1
        jmp wf1
wf3:    mov byte ptr [cur_byte],al
        mov cx,1
        lea dx,cur_byte
        mov ah,40h
        int 21h
wf1:    ret
write_file endp

; ��⠥� ���� �� 䠩��
read_file proc
        mov word ptr cs:[close_file_cnt],0
        cmp byte ptr [f_file_open],0
        je rf1
        mov bx,word ptr [file_id]
        test bx,bx
        jz rf1
        mov cx,1
        lea dx,cur_byte
        mov ah,3fh
        int 21h
         test ax,ax
         jz rf1
;        jc rf1
        mov al,byte ptr [cur_byte]
        clc
        ret
rf1:    stc
;        xor al,al
        mov al,0dah
        ret
read_file endp

; ��� ᨭ�஡��� � 䠩��
read_file_sync proc
        cmp byte ptr [f_file_open],1
        je rfs1
        call open_file_read
        jmp read_file
rfs1:   call read_file
        jc rfs2
        cmp al,0e6h
        jne rfs1
rfs2:   jmp read_file
read_file_sync endp

;####===-- ������ 0F80CH --===####
; �뢮� ���� �� ������䮭
; C - �뢮���� ����

emF80C: push ax
        push bx
        push cx
        push dx
        push ds
        mov bx,es
        mov ds,bx

        cmp byte ptr cs:[cModel],MODEL_M80
        je emc1
        mov al,cl
emc1:   call write_file

        pop ds
        pop dx
        pop cx
        pop bx
        pop ax
        ret

;####===-- ������ 0F806H --===####
; �⥭�� ���� � ������䮭�
; �室:
; A=8 - ��� �������� ᨭ�஡��� (E6)
; A=FF - � ��������� ᨭ�஡���

emF806: push bx
        push cx
        push dx
        push ds
        mov bx,es
        mov ds,bx

        cmp al,08h
        jne em06_1
        call read_file
        jmp em06_2
em06_1: call read_file_sync

em06_2: pop ds
        pop dx
        pop cx
        pop bx
        ret

;##################################################################
;### ��⠭���� ��࠭��� ����஥� � �⮡ࠦ���� ��࠭��� ������ ###
;##################################################################
refresh_scr proc
        cmp byte ptr cs:[cModel],MODEL_M80
        je rs_m80u
        cmp byte ptr cs:[cModel],MODEL_U
        je rs_m80u

        cmp byte ptr cs:[cModel],MODEL_S
        je rs10

      cmp byte ptr cs:[cModel],MODEL_M80
      je rs11
      cmp byte ptr cs:[cModel],MODEL_U
      je rs11

        cmp byte ptr cs:[cModel],MODEL_O
        jne rs9
rs10:   jmp set_graph_mode

rs11:      ;###
        ret

rs9:    cmp byte ptr cs:[f_scr],SCR_GRAPH
jne rs8
        push ax
        mov ax, word ptr cs:[sh_scrbeg]
        mov word ptr cs:[dma_begadr],ax
        mov ax, word ptr cs:[sh_scrlen]
        dec ax
        mov word ptr cs:[dma_len],ax
        pop ax
        jmp set_graph_mode

rs8:    cmp byte ptr cs:[f_scr],SCR_HIGH
        jnz rs1
; 30x78
        mov word ptr cs:[scr_dim],1d4dh

        cmp byte ptr cs:[cModel],MODEL_P
        jne rsm_1

        mov word ptr cs:[scr_beg],76d0h
        mov word ptr cs:[scr_end],7ff3h
        mov word ptr cs:[cur_offs],0303h
        jmp rs22
rsm_1:
        cmp byte ptr cs:[cModel],MODEL_A
        jne rsm_2

        mov word ptr cs:[scr_beg],0e1d0h
        mov word ptr cs:[scr_end],0eaf3h
        mov word ptr cs:[cur_offs],0308h
        jmp rs22
rsm_2:
        mov word ptr cs:[scr_beg],76d0h
        mov word ptr cs:[scr_end],7ff3h
        mov word ptr cs:[cur_offs],0308h
        jmp rs22

rs1:    cmp byte ptr cs:[f_scr],SCR_LOW
        jnz rs2
; 25x64
        mov word ptr cs:[cur_offs],0
        mov word ptr cs:[scr_dim],184dh

        cmp byte ptr cs:[cModel],MODEL_P
        jne rsm_4

        mov word ptr cs:[scr_beg],77bdh
        mov word ptr cs:[scr_end],7f0dh+74
        jmp rs22
rsm_4:
        cmp byte ptr cs:[cModel],MODEL_A
        jne rsm_5

        mov word ptr cs:[scr_beg],0e2c2h
        mov word ptr cs:[scr_end],0ea12h+74
        jmp rs22
rsm_5:
        mov word ptr cs:[scr_beg],77c2h
        mov word ptr cs:[scr_end],7f12h+74
        jmp rs22
rs2:
; Auto
        push ax
        mov ah,byte ptr cs:[sh_height]
        mov al,byte ptr cs:[sh_width]
        sub ax,0101h
        mov word ptr cs:[scr_dim],ax
        mov ax,word ptr cs:[sh_scrbeg]
        mov word ptr cs:[scr_beg],ax
        add ax,word ptr cs:[sh_scrlen]
        dec ax
        mov word ptr cs:[scr_end],ax

        mov word ptr cs:[cur_offs],0303h
        cmp byte ptr cs:[cModel],MODEL_P
        je rsm_6
        mov word ptr cs:[cur_offs],0308h
rsm_6:
        pop ax

rs22:   push di
        cmp byte ptr cs:[f_font],FONT_OEM
        jz rs7
        lea di,symtablerk
       cmp byte ptr cs:[cModel],MODEL_M
       jne rs6
       cmp byte ptr cs:[f_refr],REFR_RT
       je rs6
       cmp byte ptr cs:[mikr_symg],0
       jz rs6
       lea di,symtablemikr2
        jmp rs6
rs7:    lea di,symtable
rs6:    mov word ptr cs:[symtable_ptr],di
        call pos_cursor
        push si
        push dx
        push cx
        push bx
        xor di,di
        mov si,word ptr cs:[scr_beg]
        mov cl,byte ptr cs:[scr_dim+1]
        inc cl
        xor ch,ch
        push ax
        mov ax,0b800h
        push es
        mov es,ax
        mov ah,07h
;        mov dl,ah
        cld
rs3:    push cx
;        mov ah,07h
        push di
        mov bx,word ptr cs:[symtable_ptr]
        mov cx,78
rs4:    lodsb
       xor dl,dl
        test al,al
        jns rs5

        cmp al,0c0h
        jb rs53
        cmp al,0f0h
        jae rs52
        mov al,0b0h
        jmp rs51
rs52:   xor al,al
        jmp rs51

; ��ࠡ�⪠ 梥� � ��ਡ�⮢
rs53:   cmp byte ptr cs:[f_refr],REFR_RT
        je rs52
        mov ah,7
        cmp byte ptr cs:[cModel],MODEL_R ; #### �� �஢. ���� (������).
        jne rs532
        push bx
        mov bl,al
        mov ah,1
        and ah,bl
        rol ah,1
        rol ah,1
        mov al,4
        and al,bl
        ror al,1
        or ah,al
        mov al,8
        and al,bl
        ror al,1
        ror al,1
        ror al,1
        or ah,al
        test ah,ah
        jnz rs533
;        or ah,08h
        mov ah,7
rs533:  mov al,bl
        pop bx
        ; DL=� (��� ���४樨 �।. ᨬ�.)
        mov dl,ah
rs532:
        test al,10h
        je rs531
        cmp byte ptr cs:[cModel],MODEL_M
        je rs531 ; �� ����� ��� ����⨢�
        rol ah,1
        rol ah,1
        rol ah,1
        rol ah,1
rs531:  test al,02h
        jz rs52
        or ah,80h
        jmp rs52
rs5:
        xlat byte ptr cs:symtable_ptr
rs51:
        stosw
       test dl,dl
       jz rs511
     test ah,0fh
     jnz rs513
     test ah,70h
     jz rs513
     mov al, byte ptr es:[di-3]
     test al,0fh
     jz rs513
     test al,70h
     jnz rs513
     jmp rs511
;       push ax
;       mov al, byte ptr es:[di-3]
;       test al,07h
;       jnz rs512
;       ; �।-���.
;       push dx
;       rol dl,1
;       rol dl,1
;       rol dl,1
;       rol dl,1
;       and al,8fh
;       or al,dl
;       pop dx
;       jmp rs513
;       ; �।-���.
;rs512: and al,0f8h
;       or al,dl
rs513:
        push ax
        and byte ptr es:[di-3],80h
        and ah,7fh
        or byte ptr es:[di-3],ah
        pop ax
 ;       mov byte ptr es:[di-3],ah
;       pop ax
rs511:
        loop rs4
        pop di
        pop cx
        add di,160
        loop rs3

        mov byte ptr cs:[f_refr_txt_scr],0

        pop es
        pop ax
        pop bx
        pop cx
        pop dx
        pop si
        pop di
        ret

rs_m80u:
        cmp byte ptr cs:[f_scr],SCR_GRAPH
        jne rsu8
        mov word ptr cs:[dma_begadr],0e800h
        mov word ptr cs:[dma_len],7ffh
        jmp set_graph_mode
rsu8:
        push di si dx cx bx

       ; �� 榥 2-� ࠧ. ����� �뭥�� � �⤥���� ��楤���. ###
       lea di,symtable
       cmp byte ptr cs:[f_font],FONT_OEM
       jz rsu9
       lea di,symtablerk
rsu9:  mov word ptr cs:[symtable_ptr],di

       ; ���祬 �����.
       mov dx,0ffffh
       mov ah,2
       mov bh,0
       int 10h
        mov di,816 ;###
        mov si,word ptr cs:[scr_beg]
        mov cx,32
        push ax
        mov ax,0b800h
        push es
        mov es,ax
        mov ah,07h
        cld
rsu3:   push cx di
        mov bx,word ptr cs:[symtable_ptr]
        mov cx,64

rsu4:   cmp byte ptr cs:[cModel],MODEL_M80
        jne rsu6

        lodsb
        mov ah,7
        test al,al
        jz rsu5
        mov ah,70h
        jmp rsu5

rsu6:   lodsb
        mov ah,7
        test al,al
        jns rsu7
        mov ah,70h
        jmp rsu7

rsu5:   mov al, byte ptr ds:[si+7ffh]
        and al,07fh
rsu7:   xlat byte ptr cs:symtable_ptr
        stosw
        loop rsu4
        pop di cx
        add di,160
        loop rsu3
        mov byte ptr cs:[f_refr_txt_scr],0
        pop es ax bx cx dx si di
        ret
refresh_scr endp

; ������ ����� 䨧. � �����. ���न��⠬� �����
cur_offs dw 0

; �����୮��� ��࠭� - 64x25 ��� 78x30
scr_dim dw 183fh

set_appropr_09_vect proc
        cmp byte ptr es:[f_vid],MEM_RW
        jne sav1
        call set_new_09_vect
sav1:   ret
set_appropr_09_vect endp

f_novesa db 0

set_graph_mode proc
        push ds
        push ax
        push bp
        push cx

        cmp byte ptr cs:[f_scr],SCR_GRAPH
        jne sgm6

        mov ax,10h
        int 10h

        call refr_sg_scr
        jmp sgm7

sgm6:
        cmp byte ptr cs:[f_novesa],1 ;OFF
        je sgm3
        cmp byte ptr cs:[f_novesa],2 ;6A
        je sgm4

        mov ax,4f02h
        mov bx,102h
        int 10h
;        mov ax,4f02h  ; 2 ࠧ� - �஡���� �� S3 Virge ��� Windows
;        mov bx,102h
;        int 10h
        cmp al,4fh
        jne sgm3
        test ah,ah
        jnz sgm3
        jmp sgm5

sgm4:   mov ax,6ah
        int 10h
sgm5:
        push dx
        mov dx,3ceh
        mov ax,0ff08h
        out dx,ax
        mov ax,5
        out dx,ax
        mov ax,3
        out dx,ax
        mov ax,0001h
        out dx,ax
        pop dx

        push es
        push di
        mov ax,0a000h
        mov es,ax
        mov cx,30000
        xor ax,ax
;    mov ax,-1 ; �⫠��� - ���� ��࠭
        cld
        xor di,di
        rep stosw
        pop di
        pop es

        mov word ptr cs:[write_byte_spec],offset write_byte_spec_800
        mov word ptr cs:[write_byte_orion],offset write_byte_orion_800
        jmp sgm2
sgm3:
        mov ax,12h
        int 10h
        mov word ptr cs:[write_byte_spec],offset write_byte_spec_640
        mov word ptr cs:[write_byte_orion],offset write_byte_orion_640
sgm2:
        cmp byte ptr cs:[cModel],MODEL_O
        je sgm8

        mov bp,9000h
        mov cx,3000h
 mov al,byte ptr cs:[cur_color_code]
 push ax
 push es
 mov ax, word ptr cs:[color_mem+2]
 mov es,ax
sgm1:   mov ah,byte ptr ds:[bp]
 mov al, byte ptr es:[bp-9000h]
 mov byte ptr cs:[cur_color_code],al
        call word ptr cs:[write_byte_spec]
        inc bp
        loop sgm1
 pop es
 pop ax
 mov byte ptr cs:[cur_color_code],al
 jmp sgm7

        mov byte ptr cs:[old_or_colormode],0ffh
        mov byte ptr cs:[old_or_scrpage],0ffh

sgm8:
        mov ax, word ptr cs:[mempage0+2]
        mov ds,ax
        push es
        mov ax, word ptr cs:[mempage1+2]
        mov es,ax
        mov bp,word ptr cs:[scr_beg]
        mov cx,3000h
sgm9:   mov ah,byte ptr ds:[bp]
        mov al,byte ptr es:[bp]
        call word ptr cs:[write_byte_orion]
        inc bp
        loop sgm9
        pop es

sgm7:
        pop cx
        pop bp
        pop ax
        pop ds
        ret
set_graph_mode endp

restore_mode proc
        cmp byte ptr cs:[cModel],MODEL_S
        je rm2
        cmp byte ptr cs:[cModel],MODEL_O
        je rm2
        cmp byte ptr cs:[f_scr],SCR_GRAPH
        jne rm1
rm2:    push ds
        push ax
        mov ax, word ptr cs:[mem+2]
        mov ds,ax
        call refresh_scr
        pop ax
        pop ds
rm1:    ret
restore_mode endp

draw_scr_or proc
        push ds
        push ax
        push bp
        push cx
        jmp sgm8 ;) ###
draw_scr_or endp

refr_sg_scr proc
        push es ds ax bx cx dx si di
        mov ax,cs
        mov ds,ax
        mov es,ax
        call DrawScr
        pop di si dx cx bx ax ds es
        ret
refr_sg_scr endp

end
