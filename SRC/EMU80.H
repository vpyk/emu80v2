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

extern "C" void InitOnce();            // процедура иниц-ии при запуске
extern "C" char far *mempages[4];      // память эмулируемого ПК (4 стр.)
extern "C" char far *mempage0;         // память эмулируемого ПК (0 стр.)
extern "C" char far *color_mem;        // память цвета "Специалиста"
extern "C" char far *sym_gen;          // знакогенератор
extern "C" char color_table[4];        // таблица соответствия цветов
extern "C" void Start();               // запуск эмуляции
extern "C" void Resume();              // запуск эмуляции без иниц. рег-ров
extern "C" void Init();                // иниц-ия при смене типа ПК
extern "C" void LoadROM();             // загрузка соответствующего ПЗУ
extern "C" void ClearMem();            // очистка памяти сегмента 8080
extern "C" void SetDefParams();        // устанавливает параметры по умолчанию

extern "C" unsigned char use_io_space; // используются ли команды IN/OUT
extern "C" unsigned scr_beg;           // начало экрана
extern "C" unsigned scr_end;           // конец экрана
extern "C" unsigned cur_corr;          // текущая коррекция чего-то
extern "C" unsigned begin_scr;         // начало экрана
extern "C" unsigned cur_off_rom;       // текущее смещение координат
extern "C" unsigned draw_scr_beg;      // начало отображ. области экрана
extern "C" unsigned draw_scr_len;      // конец отображ. области экрана
extern "C" unsigned dma_begadr;        // начало экрана (по ПДП)
extern "C" unsigned dma_len;           // размер экрана -1 (по ПДП)
extern "C" unsigned romvar_addr;       // адрес переменной с адресом поз. курс.
extern "C" unsigned curpos_addr;       // адрес переменной с коорд. курсора
extern "C" unsigned delay_norm;        // нормальная задержка
extern "C" unsigned delay_dma;         // задержка в режиме ПДП
extern "C" unsigned cur_speed;         // текущая задержка
extern "C" unsigned cur_speed_sb;      // текущая задержка
extern "C" unsigned delay;             // текущая задержка (не запом.)
extern "C" unsigned delay_sb;          // текущая задержка (не запом.)
extern "C" unsigned rom_len;           // длина ПЗУ
extern "C" unsigned rom_adr;           // нач. адрес ПЗУ
extern "C" unsigned reset_addr;        // стартовый адрес
extern "C" unsigned char keybin_port;  // порт ввода с клавиатуры
extern "C" unsigned ppi_portc_adr;     // адрес порта C ППА             
extern "C" unsigned crt_port1_adr;     // адрес регистра управления ВГ75
extern "C" char near * romname;        // имя файла с ПЗУ
extern "C" void *(hook_proc_spk);      // текущая фунуция перехв. - PC Speaker
extern "C" void *(hook_proc_sb);       // текущая фунуция перехв. - Sound Blast.
extern "C" void hook_p();              // функция перехвата для "Партнера" - PCS
extern "C" void hook_r();              // функция перехвата для РК - PCS
extern "C" void hook_m();              // функция перехвата для "Микроши" - PCS
extern "C" void hook_a();              // функция перехвата для "Апогея" - PCS
extern "C" void hook_s();              // функция перехвата для "Специалиста"PCS
extern "C" void hook_o();              // функция перехвата для "Ориона" - PCS
extern "C" void hook_m80();            // функция перехвата для "Микро-80" - PCS
extern "C" void hook_u();              // функция перехвата для "ЮТ-88" - PCS
extern "C" void hook_p_sb();           // функция перехвата для "Партнера" - SB
extern "C" void hook_r_sb();           // функция перехвата для РК - SB
extern "C" void hook_m_sb();           // функция перехвата для "Микроши" - SB
extern "C" void hook_a_sb();           // функция перехвата для "Апогея" - SB
extern "C" void hook_s_sb();           // функция перехвата для "Специалиста"SB
extern "C" void hook_o_sb();           // функция перехвата для "Ориона" - SB
extern "C" void hook_m80_sb();         // функция перехвата для "Микро-80" - SB
extern "C" void hook_u_sb();           // функция перехвата для "ЮТ-88" - SB
extern "C" void corr_key_tbl();        // настраивает таблицы клав. под модель
extern "C" unsigned char ext_letter;   // последняя буква расширения RKx
extern "C" void set_text_mode();       // устанавливает текст. режим при необх.

extern "C" unsigned short sh_scrbeg;   // начало экранной области
extern "C" unsigned char sh_height;    // количество строк
extern "C" unsigned char sh_width;     // количество символов в строке
extern "C" unsigned short sh_scrlen;   // длина экранной области
extern "C" unsigned char crt_param_1;  // параметр 1 программирования ВГ75
extern "C" unsigned char crt_param_2;  // параметр 2 программирования ВГ75
extern "C" unsigned char crt_param_3;  // параметр 3 программирования ВГ75
extern "C" unsigned char crt_param_4;  // параметр 4 программирования ВГ75
extern "C" unsigned char dma_mr;       // регистр режима ВТ57
extern "C" unsigned char crt_mreg;     // регистр режима ВГ75
extern "C" unsigned char mikr_symg;    // тек. знакогенератор "Микроши"
extern "C" unsigned short pit_k0;      // делитель канала 0 таймера
extern "C" unsigned short pit_k1;      // делитель канала 1 таймера
extern "C" unsigned short pit_k2;      // делитель канала 2 таймера
extern "C" unsigned short pit_cnt0;    // тек. знач. сч. канала 0 таймера
extern "C" unsigned short pit_cnt1;    // тек. знач. сч. канала 1 таймера
extern "C" unsigned short pit_cnt2;    // тек. знач. сч. канала 2 таймера
extern "C" unsigned char pit_mode0;   // режим сч. канала 0 таймера
extern "C" unsigned char pit_mode1;   // режим сч. канала 1 таймера
extern "C" unsigned char pit_mode2;   // режим сч. канала 2 таймера
extern "C" unsigned char pit_ld0;     // признак загрузки канала 0 таймера
extern "C" unsigned char pit_ld1;     // признак загрузки канала 1 таймера
extern "C" unsigned char pit_ld2;     // признак загрузки канала 2 таймера
extern "C" unsigned char port_c;       // порт C ВВ55
extern "C" unsigned char int_flag;     // признак разрешения прерываний
extern "C" unsigned char cur_x;        // координата X курсора
extern "C" unsigned char cur_y;        // координата Y курсора
extern "C" unsigned short cur_xy;      // координаты XY курсора
extern "C" unsigned char or_color_mode;// текущий режим экрана "Ориона"
extern "C" unsigned char mem_page_no;  // текущая страница памяти "Ориона"
extern "C" unsigned char or_scrpage;   // текущий экран "Ориона"
extern "C" unsigned char f_chscr;      // 1, если нужно перепрогр. экран
extern "C" unsigned char f_saverom;    // 1, если нужно сохранять ПЗУ в снапш.
extern "C" unsigned short ticks_per_44100th; // тактов на 1/44100-ю секунды
extern "C" unsigned short ticks_per_50ms;    // тактов на 50 мс
extern "C" unsigned short delay_sb_dma; // тактов на 1/44100 с учетом ПДП
extern "C" unsigned short delay_sb_norm;// тактов на 1/44100 без учета ПДП

extern "C" unsigned save_scr();        // сохраняет экран и возвращает id
extern "C" void rest_scr();            // восстанавливает экран по id в ax
extern "C" void getfilename();         // запрос имени файла
extern "C" void enable_ints();         // разрешение прерываний
extern "C" void disable_ints();        // запрещение прерываний
extern "C" void anal_params();         // обновление настроек
extern "C" void process_crt();         // прогр. экрана в сотв. с настройками
extern "C" void process_pit();         // прогр. таймера в сотв. с настройками
extern "C" void process_port_c();      // интерпр. содерж. порта C ППА
extern "C" void process_orion();       // обработка пар. Ориона при загр. снапш.
extern "C" char filename;              // введенное имя файла (1-й символ)
extern "C" char f_choose_file;         // 1, если выбираем файл
extern "C" char f_file_ss;             // 1, если файл снапшота, 2-ODI
extern "C" char f_novesa;              // 1, если не используем SVGA (VESA)
extern "C" char f_led;                 // 1, работаем со светодиодами клавиатуры
extern "C" char f_use8x12;             // 1, исп. шрифт 8x12 и режим 80x40
extern "C" unsigned short wSBPort;     // базовый адрес портов SB
extern "C" unsigned short wSBDMA;      // канал ПДП для SB
extern "C" char bNeedClearMem;         // 1, если нужно очищ. пам. при выб. ПК
extern "C" char com_path;              // путь к com-файлу
extern "C" char com_path_len;          // длина пути к com-файлу
extern "C" unsigned short vmem_off;    // смещ. в видеопам. экрана Спец. 800x600

extern "C" unsigned short reg_af;      // регистр AF
extern "C" unsigned short reg_bc;      // регистр BC
extern "C" unsigned short reg_de;      // регистр DE
extern "C" unsigned short reg_hl;      // регистр HL
extern "C" unsigned short reg_sp;      // регистр SP
extern "C" unsigned short reg_pc;      // регистр PC

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
