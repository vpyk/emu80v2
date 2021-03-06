/*
 *  Emu80 v. 2.86
 *  (c) Viktor Pykhonin <pyk@mail.ru>, 1997-2000
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef _EMU80_H
#define _EMU80_H

#include "rss.h"

#define SPEED_NORM 2
#define SPEED_MEDIUM 1
#define SPEED_HIGH 0

#define MEM_NONE 0
#define MEM_W 1
#define MEM_RW 2

#define HOOKF809_YES 1
#define HOOKF809_NO 0

#define SCR_AUTO 2
#define SCR_LOW 0
#define SCR_HIGH 1
#define SCR_GRAPH 3

#define FONT_OEM 0
#define FONT_RK 1

#define REFR_RT 0
#define REFR_50 1
#define REFR_COMB 2

#define SND_ON 0
#define SND_OFF 1
#define SND_SB 2

#define TAPE_FILE 0
#define TAPE_SBOUT 1
#define TAPE_SBIN 2

#define SYSREQ_MENU 0
#define SYSREQ_RESET 1
#define SYSREQ_MODEL 2
#define SYSREQ_SAVESS 3
#define SYSREQ_LOADSS 4
#define SYSREQ_HELP 5
#define SYSREQ_QUIT 6
#define SYSREQ_MODELNOCLEAR 7
#define SYSREQ_DISKA 8
#define SYSREQ_DISKB 9
#define SYSREQ_ROM 10
#define SYSREQ_SPEEDUP 11
#define SYSREQ_SPEEDDOWN 12

extern "C" void InitOnce();            // ��楤�� ����-�� �� ����᪥
extern "C" char far *mempages[4];      // ������ ��㫨�㥬��� �� (4 ���.)
extern "C" char far *mempage0;         // ������ ��㫨�㥬��� �� (0 ���.)
extern "C" char far *color_mem;        // ������ 梥� "���樠����"
extern "C" char far *sym_gen;          // ������������
extern "C" char color_table[4];        // ⠡��� ᮮ⢥��⢨� 梥⮢
extern "C" void Start();               // ����� ����樨
extern "C" void Resume();              // ����� ����樨 ��� ����. ॣ-஢
extern "C" void Init();                // ����-�� �� ᬥ�� ⨯� ��
extern "C" void LoadROM();             // ����㧪� ᮮ⢥�����饣� ���
extern "C" void ClearMem();            // ���⪠ ����� ᥣ���� 8080
extern "C" void SetDefParams();        // ��⠭�������� ��ࠬ���� �� 㬮�砭��

extern "C" unsigned char use_io_space; // �ᯮ������� �� ������� IN/OUT
extern "C" unsigned scr_beg;           // ��砫� ��࠭�
extern "C" unsigned scr_end;           // ����� ��࠭�
extern "C" unsigned cur_corr;          // ⥪��� ���४�� 祣�-�
extern "C" unsigned begin_scr;         // ��砫� ��࠭�
extern "C" unsigned cur_off_rom;       // ⥪�饥 ᬥ饭�� ���न���
extern "C" unsigned draw_scr_beg;      // ��砫� �⮡ࠦ. ������ ��࠭�
extern "C" unsigned draw_scr_len;      // ����� �⮡ࠦ. ������ ��࠭�
extern "C" unsigned dma_begadr;        // ��砫� ��࠭� (�� ���)
extern "C" unsigned dma_len;           // ࠧ��� ��࠭� -1 (�� ���)
extern "C" unsigned romvar_addr;       // ���� ��६����� � ���ᮬ ���. ����.
extern "C" unsigned curpos_addr;       // ���� ��६����� � ����. �����
extern "C" unsigned delay_norm;        // ��ଠ�쭠� ����প�
extern "C" unsigned delay_dma;         // ����প� � ०��� ���
extern "C" unsigned cur_speed;         // ⥪��� ����প�
extern "C" unsigned cur_speed_sb;      // ⥪��� ����প�
extern "C" unsigned delay;             // ⥪��� ����প� (�� �����.)
extern "C" unsigned delay_sb;          // ⥪��� ����প� (�� �����.)
extern "C" unsigned rom_len;           // ����� ���
extern "C" unsigned rom_adr;           // ���. ���� ���
extern "C" unsigned reset_addr;        // ���⮢� ����
extern "C" unsigned char keybin_port;  // ���� ����� � ����������
extern "C" unsigned ppi_portc_adr;     // ���� ���� C ���             
extern "C" unsigned crt_port1_adr;     // ���� ॣ���� �ࠢ����� ��75
extern "C" char near * romname;        // ��� 䠩�� � ���
extern "C" void *(hook_proc_spk);      // ⥪��� ����� ����. - PC Speaker
extern "C" void *(hook_proc_sb);       // ⥪��� ����� ����. - Sound Blast.
extern "C" void hook_p();              // �㭪�� ���墠� ��� "���⭥�" - PCS
extern "C" void hook_r();              // �㭪�� ���墠� ��� �� - PCS
extern "C" void hook_m();              // �㭪�� ���墠� ��� "�����" - PCS
extern "C" void hook_a();              // �㭪�� ���墠� ��� "������" - PCS
extern "C" void hook_s();              // �㭪�� ���墠� ��� "���樠����"PCS
extern "C" void hook_o();              // �㭪�� ���墠� ��� "�ਮ��" - PCS
extern "C" void hook_m80();            // �㭪�� ���墠� ��� "����-80" - PCS
extern "C" void hook_u();              // �㭪�� ���墠� ��� "��-88" - PCS
extern "C" void hook_p_sb();           // �㭪�� ���墠� ��� "���⭥�" - SB
extern "C" void hook_r_sb();           // �㭪�� ���墠� ��� �� - SB
extern "C" void hook_m_sb();           // �㭪�� ���墠� ��� "�����" - SB
extern "C" void hook_a_sb();           // �㭪�� ���墠� ��� "������" - SB
extern "C" void hook_s_sb();           // �㭪�� ���墠� ��� "���樠����"SB
extern "C" void hook_o_sb();           // �㭪�� ���墠� ��� "�ਮ��" - SB
extern "C" void hook_m80_sb();         // �㭪�� ���墠� ��� "����-80" - SB
extern "C" void hook_u_sb();           // �㭪�� ���墠� ��� "��-88" - SB
extern "C" void corr_key_tbl();        // ����ࠨ���� ⠡���� ����. ��� ������
extern "C" unsigned char ext_letter;   // ��᫥���� �㪢� ���७�� RKx
extern "C" void set_text_mode();       // ��⠭�������� ⥪��. ०�� �� �����.

extern "C" unsigned short sh_scrbeg;   // ��砫� ��࠭��� ������
extern "C" unsigned char sh_height;    // ������⢮ ��ப
extern "C" unsigned char sh_width;     // ������⢮ ᨬ����� � ��ப�
extern "C" unsigned short sh_scrlen;   // ����� ��࠭��� ������
extern "C" unsigned char crt_param_1;  // ��ࠬ��� 1 �ணࠬ��஢���� ��75
extern "C" unsigned char crt_param_2;  // ��ࠬ��� 2 �ணࠬ��஢���� ��75
extern "C" unsigned char crt_param_3;  // ��ࠬ��� 3 �ணࠬ��஢���� ��75
extern "C" unsigned char crt_param_4;  // ��ࠬ��� 4 �ணࠬ��஢���� ��75
extern "C" unsigned char dma_mr;       // ॣ���� ०��� ��57
extern "C" unsigned char crt_mreg;     // ॣ���� ०��� ��75
extern "C" unsigned char mikr_symg;    // ⥪. ������������ "�����"
extern "C" unsigned short pit_k0;      // ����⥫� ������ 0 ⠩���
extern "C" unsigned short pit_k1;      // ����⥫� ������ 1 ⠩���
extern "C" unsigned short pit_k2;      // ����⥫� ������ 2 ⠩���
extern "C" unsigned short pit_cnt0;    // ⥪. ����. ��. ������ 0 ⠩���
extern "C" unsigned short pit_cnt1;    // ⥪. ����. ��. ������ 1 ⠩���
extern "C" unsigned short pit_cnt2;    // ⥪. ����. ��. ������ 2 ⠩���
extern "C" unsigned char pit_mode0;   // ०�� ��. ������ 0 ⠩���
extern "C" unsigned char pit_mode1;   // ०�� ��. ������ 1 ⠩���
extern "C" unsigned char pit_mode2;   // ०�� ��. ������ 2 ⠩���
extern "C" unsigned char pit_ld0;     // �ਧ��� ����㧪� ������ 0 ⠩���
extern "C" unsigned char pit_ld1;     // �ਧ��� ����㧪� ������ 1 ⠩���
extern "C" unsigned char pit_ld2;     // �ਧ��� ����㧪� ������ 2 ⠩���
extern "C" unsigned char port_c;       // ���� C ��55
extern "C" unsigned char int_flag;     // �ਧ��� ࠧ�襭�� ���뢠���
extern "C" unsigned char cur_x;        // ���न��� X �����
extern "C" unsigned char cur_y;        // ���न��� Y �����
extern "C" unsigned short cur_xy;      // ���न���� XY �����
extern "C" unsigned char or_color_mode;// ⥪�騩 ०�� ��࠭� "�ਮ��"
extern "C" unsigned char mem_page_no;  // ⥪��� ��࠭�� ����� "�ਮ��"
extern "C" unsigned char or_scrpage;   // ⥪�騩 ��࠭ "�ਮ��"
extern "C" unsigned char f_chscr;      // 1, �᫨ �㦭� ��९ண�. ��࠭
extern "C" unsigned char f_saverom;    // 1, �᫨ �㦭� ��࠭��� ��� � ᭠��.
extern "C" unsigned short ticks_per_44100th; // ⠪⮢ �� 1/44100-� ᥪ㭤�
extern "C" unsigned short ticks_per_50ms;    // ⠪⮢ �� 50 ��
extern "C" unsigned short delay_sb_dma; // ⠪⮢ �� 1/44100 � ��⮬ ���
extern "C" unsigned short delay_sb_norm;// ⠪⮢ �� 1/44100 ��� ��� ���

extern "C" unsigned save_scr();        // ��࠭�� ��࠭ � �����頥� id
extern "C" void rest_scr();            // ����⠭�������� ��࠭ �� id � ax
extern "C" void getfilename();         // ����� ����� 䠩��
extern "C" void enable_ints();         // ࠧ�襭�� ���뢠���
extern "C" void disable_ints();        // ����饭�� ���뢠���
extern "C" void anal_params();         // ���������� ����஥�
extern "C" void process_crt();         // �ண�. ��࠭� � ��. � ����ன����
extern "C" void process_pit();         // �ண�. ⠩��� � ��. � ����ன����
extern "C" void process_port_c();      // �����. ᮤ��. ���� C ���
extern "C" void process_orion();       // ��ࠡ�⪠ ���. �ਮ�� �� ����. ᭠��.
extern "C" char filename;              // ��������� ��� 䠩�� (1-� ᨬ���)
extern "C" char f_choose_file;         // 1, �᫨ �롨ࠥ� 䠩�
extern "C" char f_file_ss;             // 1, �᫨ 䠩� ᭠���, 2-ODI
extern "C" char f_novesa;              // 1, �᫨ �� �ᯮ��㥬 SVGA (VESA)
extern "C" char f_led;                 // 1, ࠡ�⠥� � ᢥ⮤������ ����������
extern "C" char f_use8x12;             // 1, ��. ���� 8x12 � ०�� 80x40
extern "C" unsigned short wSBPort;     // ������ ���� ���⮢ SB
extern "C" unsigned short wSBDMA;      // ����� ��� ��� SB
extern "C" char bNeedClearMem;         // 1, �᫨ �㦭� ���. ���. �� ��. ��
extern "C" char com_path;              // ���� � com-䠩��
extern "C" char com_path_len;          // ����� ��� � com-䠩��
extern "C" unsigned short vmem_off;    // ᬥ�. � ��������. ��࠭� ����. 800x600

extern "C" unsigned short reg_af;      // ॣ���� AF
extern "C" unsigned short reg_bc;      // ॣ���� BC
extern "C" unsigned short reg_de;      // ॣ���� DE
extern "C" unsigned short reg_hl;      // ॣ���� HL
extern "C" unsigned short reg_sp;      // ॣ���� SP
extern "C" unsigned short reg_pc;      // ॣ���� PC

struct MENU_ITEM;

struct MENU_LINE
  {
  char cValue;
  near MENU_LINE * pmnNext;
  near MENU_LINE * pmnPrev;
  near MENU_ITEM * pmiItem;
  };

struct MENU_ITEM
  {
  char cValue;
  char x;
  char y;
  near MENU_ITEM * pmiNext;
  near MENU_ITEM * pmiPrev;
  near MENU_LINE * pmnNext;
  near MENU_LINE * pmnPrev;
  char cDisabled;
  };

extern "C" MENU_LINE f_speed;
extern "C" MENU_LINE f_vid;
extern "C" MENU_LINE f_f809;
extern "C" MENU_LINE f_scr;
extern "C" MENU_LINE f_font;
extern "C" MENU_LINE f_refr;
extern "C" MENU_LINE f_snd;
extern "C" MENU_LINE f_tape;

extern "C" MENU_ITEM i_spmed;
extern "C" MENU_ITEM i_vidno;
extern "C" MENU_ITEM i_f809yes;
extern "C" MENU_ITEM i_scrlow;
extern "C" MENU_ITEM i_scrhigh;
extern "C" MENU_ITEM i_scrgr;
extern "C" MENU_ITEM i_fontoem;
extern "C" MENU_ITEM i_refrcomb;
extern "C" MENU_ITEM i_refrrt;
extern "C" MENU_ITEM i_refr50;

struct RKSS_EMUL_HEADER
  {
  unsigned long dwSig;
  unsigned wHeaderLen;
  unsigned char cSpeed;
  unsigned char cMem;
  unsigned char cHookF809;
  unsigned char cScreen;
  unsigned char cFont;
  unsigned char cSound;
  unsigned char cTape;
  unsigned char cRefr;
  };

extern "C" unsigned char cModel;
extern "C" unsigned char acSectBufA[1024];
extern "C" unsigned char acSectBufB[1024];

extern "C" int ChooseModel();
extern "C" int ChooseROM();
extern "C" void AlterSpeed(short nSysReq);
extern "C" void ReadSector(short wDisk, short wTrack, short wHead, short wSector);
extern "C" void WriteSector(short wDisk, short wTrack, short wHead, short wSector);
extern "C" void RefreshMenu();
extern "C" void TuneMenu();
extern "C" void LoadIniParams();
extern "C" void ChooseDisk(short nDisk);
extern "C" int SaveSS();
extern "C" int LoadSS();
extern "C" void ShowHelp();
extern "C" void GeneralError();
extern "C" void ROMError();
extern "C" void SymGenError();
extern "C" void FontsError();
extern "C" void ROMDiskError();

extern "C" int LoadSSName(char *szCmdLineFileName=0);

#endif
