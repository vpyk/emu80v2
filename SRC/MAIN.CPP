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

#include "lib_symb.h"

#include <stdio.h>
#include <string.h>
#include <mem.h>
#include <io.h>

#include "emu80.h"
#include "graph.h"
#include "sb.h"

unsigned char cModel=MODEL_R;
unsigned char cMonitor=MON_DEF;

int ChooseModel();
int ChooseROM();
void RefreshMenu();
void TuneMenu();
void ClearDisabledMenuItems();
void LoadIniParams();
void ChooseDisk(short nDisk);
void ChooseDiskName(short nDisk, char *szFileName);
void AlterSpeed(short nSysReq);
void ReadSector(short wDisk, short wTrack, short wHead, short wSector);
void WriteSector(short wDisk, short wTrack, short wHead, short wSector);
int SaveSS();
int LoadSS();
void ShowHelp();
void GeneralError();
void ROMError();
void SymGenError();
void FontsError();
void ROMDiskError();

int LoadRK(FILE *f);
int LoadSSName(char *szCmdLineFileName);

static int bIsDefMem;

static FILE* fDiskA=0;
static FILE* fDiskB=0;

unsigned char acSectBufA[1024];
unsigned char acSectBufB[1024];

static short wMaxDelay,wMinDelay,wMaxDelaySB,wMinDelaySB;

static unsigned char acDefMons[6]={1,0,1,0,1,2}; // Мониторы по умолчанию
static unsigned char acMaxMonitor[6]={3,0,2,0,4,3}; // Кол-во Мониторов
//static unsigned char acDefMons[7]={1,0,1,0,1,2,1}; // Мониторы по умолчанию
//static unsigned char acMaxMonitor[7]={3,0,2,0,4,3,2}; // Кол-во Мониторов

void SetModel();
void SetMonitor();

void SetModel()
{
use_io_space=0;
keybin_port=1;
cur_off_rom=0x308;
draw_scr_len=78*30;
romvar_addr=0x7600;
curpos_addr=0x7602;
delay_norm=89;
delay_dma=58;
sh_width=78;
sh_height=30;
sh_scrlen=78*30;
sh_scrbeg=0x76d0;
reset_addr=0xf800;
ticks_per_44100th=40;
ticks_per_50ms=89;
delay_sb_dma=26;
delay_sb_norm=40;
switch (cModel)
  {
  case MODEL_P:
    scr_beg=0x77bd;
    scr_end=0x7f0d+74;
    cur_corr=0x304;
    cur_off_rom=0;
    draw_scr_beg=0x76d1;
    delay_norm=100;
    delay_dma=69;
    rom_adr=0xf000;
    rom_len=0x1000;
    ppi_portc_adr=0xd902;
    crt_port1_adr=0xd801;
    hook_proc_spk=hook_p;
    hook_proc_sb=hook_p_sb;
    ext_letter='P';
    ticks_per_44100th=45;
    ticks_per_50ms=100;
    delay_sb_dma=31;
    delay_sb_norm=45;
    break;
  case MODEL_A:
    sh_scrbeg=0xe1d0;
    scr_beg=0xe2c2;
    scr_end=0xea12;
    cur_corr=0x308;
    draw_scr_beg=0xe1d0;
    romvar_addr=0xe100;
    rom_adr=0xf000;
    rom_len=0x1000;
    ppi_portc_adr=0xee02;
    crt_port1_adr=0xef01;
    romname="roma.bin";
    hook_proc_spk=hook_a;
    hook_proc_sb=hook_a_sb;
    ext_letter='A';
    break;
  case MODEL_M:
    scr_beg=0x77c2;
    scr_end=0x7f12;
    cur_corr=0x308;
    keybin_port=0;
    draw_scr_beg=0x76d0;
    rom_adr=0xf800;
    rom_len=0x0800;
    ppi_portc_adr=0xc002;
    crt_port1_adr=0xd001;
    romname="romm.bin";
    hook_proc_spk=hook_m;
    hook_proc_sb=hook_m_sb;
    ext_letter='M';
    delay_dma=64;      // Но почему???
    delay_sb_dma=29;   //
    break;
  case MODEL_R:
    scr_beg=0x77c2;
    scr_end=0x7f12;
    cur_corr=0x308;
    draw_scr_beg=0x76d0;
    ppi_portc_adr=0x8002;
    crt_port1_adr=0xc001;
    hook_proc_spk=hook_r;
    hook_proc_sb=hook_r_sb;
    ext_letter='R';
    break;
  case MODEL_S:
    scr_beg=0x9000;
    scr_end=0xbfff;
    cur_corr=0x304;
    cur_off_rom=0;
    draw_scr_beg=0x76d1;
    delay_norm=100;
    delay_dma=100;
    rom_adr=0xc000;
    ppi_portc_adr=0xd902;
    crt_port1_adr=0xd801;
    hook_proc_spk=hook_s;
    hook_proc_sb=hook_s_sb;
    ext_letter='S';
    reset_addr=0xc000;
    ticks_per_44100th=45;
    ticks_per_50ms=100;
    delay_sb_dma=45;
    delay_sb_norm=45;
    break;
  case MODEL_O:
    scr_beg=0xc000;
    scr_end=0xefff;
    cur_corr=0x304;
    cur_off_rom=0;
    draw_scr_beg=0x76d1;
    delay_norm=125;
    delay_dma=125;
    rom_adr=0xf800;
    rom_len=0x800;
    ppi_portc_adr=0xf402;
    crt_port1_adr=0xd801;
    hook_proc_spk=hook_o;
    hook_proc_sb=hook_o_sb;
    ext_letter='O';
    reset_addr=0xf800;
    ticks_per_44100th=57;
    ticks_per_50ms=150;
    delay_sb_dma=57;
    delay_sb_norm=57;
    break;
  case MODEL_M80:
    use_io_space=1;
    scr_beg=0xe000;
    scr_end=0xefff;
    cur_corr=0x0;
    cur_off_rom=0;
    draw_scr_beg=0xe800;
    delay_norm=89;
    delay_dma=89;
    rom_adr=0xf800;
    rom_len=0x800;
    hook_proc_spk=hook_m80;
    hook_proc_sb=hook_m80_sb;
    ext_letter='8';
    ticks_per_44100th=450;
    ticks_per_50ms=89;
    delay_sb_dma=40;
    delay_sb_norm=40;
    break;
  case MODEL_U:
    use_io_space=1;
    scr_beg=0xe000; //###
    scr_end=0xefff; //###
    cur_corr=0x0;
    cur_off_rom=0;
    draw_scr_beg=0xe800;   //###
    delay_norm=89;         
    delay_dma=89;          
    rom_adr=0xf800;
    rom_len=0x800;
    hook_proc_spk=hook_u;
    hook_proc_sb=hook_u_sb;
    ext_letter='U';
    ticks_per_44100th=450;
    ticks_per_50ms=89;
    delay_sb_dma=40;
    delay_sb_norm=40;
    break;
  }
SetMonitor();
begin_scr=scr_beg;
curpos_addr=romvar_addr+2;
cur_speed=delay_dma;
cur_speed_sb=delay_sb_dma;
corr_key_tbl();
wMaxDelay=delay_norm*11/2;
wMinDelay=delay_norm*2/11;
wMaxDelaySB=delay_sb_norm*11/2;
wMinDelaySB=delay_sb_norm*2/11;
}

void SetMonitor()
{
if (cMonitor==0)
  cMonitor=acDefMons[cModel];
switch (cModel)
  {
  case MODEL_P:
    if (cMonitor==MON_P_V3)
      romname="romp.bin";
    else if (cMonitor==MON_P_V2)
      romname="rompv2.bin";
    break;
  case MODEL_R:
    if (cMonitor!=MON_R_4K)
      {
      rom_adr=0xf800;
      rom_len=0x0800;
      }
    else
      {
      rom_adr=0xf000;
      rom_len=0x1000;
      }
    if (cMonitor==MON_R_16)
      romname="romr16.bin";
    else if (cMonitor==MON_R_32)
      romname="romr.bin";
    else if (cMonitor==MON_R_4K)
      romname="romr4k.bin";
//    else if (cMonitor==MON_R_3)
//      romname="romr3.bin";
    break;
  case MODEL_S:
    if (cMonitor==MON_S_M)
      rom_len=0x2000;
    else if (cMonitor==MON_S_L)
      rom_len=0x3000;
    else
      rom_len=0x1000;
    if (cMonitor==MON_S_1)
      romname="roms1.bin";
    else if (cMonitor==MON_S_2)
      romname="roms.bin";
    else if (cMonitor==MON_S_M)
      romname="romsm.bin";
    else if (cMonitor==MON_S_L)
      romname="romsl.bin";
    break;
  case MODEL_O:
    if (cMonitor==MON_O_1)
      romname="romo1.bin";
    else if (cMonitor==MON_O_2)
      romname="romo.bin";
    else if (cMonitor==MON_O_PET)
      romname="romop.bin";
    break;
  case MODEL_M80:
//    if (cMonitor==MON_M80_O)
      romname="rom80.bin";
//    else if (cMonitor==MON_M80_R)
//      romname="rom8r.bin";
    break;
  case MODEL_U:
    romname="romu.bin";
    break;
  }
}

static char *ppcFileErrMess[1]={"Ошибка файловой операции"};
static char *ppcFormatErrMess[1]={"Неподдерживаемая модель компьютера"};
static char *ppcMonitorWarnMess[2]={"  Неизвестный тип Монитора",
                                    "Используется тип по умолчанию"};
static char *ppcFileSuccMess[1]={"Файл сохранен"};
static char *ppcGeneralErrMess[1]={"Фатальная ошибка"};
static char *ppcROMErrMess[1]={"Не найден один из файлов ПЗУ (rom*.bin)"};
static char *ppcSymGenErrMess[1]={"Не найден файл знакогенератора (symgen.bin)"};
static char *ppcFontsErrMess[1]={"Не найден файл шрифтов (fonts.bin)"};
static char *ppcROMDiskErrMess[1]={"Не найден файл ROMDISK'а"};

void GeneralError()
{
ShowMessage(ppcGeneralErrMess,1," Ошибка ",0,0);
}

void SymGenError()
{
ShowMessage(ppcSymGenErrMess,1," Ошибка ",0,0);
}

void FontsError()
{
ShowMessage(ppcFontsErrMess,1," Ошибка ",0,0);
}

void ROMDiskError()
{
ShowMessage(ppcROMDiskErrMess,1," Ошибка ",0,0);
}

void ROMError()
{
ShowMessage(ppcROMErrMess,1," Ошибка ",0,0);
}

void FileError()
{
ShowMessage(ppcFileErrMess,1," Ошибка ",0,0);
}

void FormatError()
{
ShowMessage(ppcFormatErrMess,1," Ошибка ",0,0);
}

void MonitorWarning()
{
ShowMessage(ppcMonitorWarnMess,2," Предупреждение ",0,0);
}

void ChooseDisk(short nDisk)
{
if (cModel!=MODEL_O)
  return;
set_text_mode();
StopSound();
f_file_ss=2;
f_choose_file=1;
getfilename();
char *szFileName=(char *)&filename;
int len=strlen(szFileName);
if (len!=0 && len<=16 && (strcspn(szFileName,".")==len))
  strcat(szFileName,".odi");
if (!*szFileName) return;

ChooseDiskName(nDisk, szFileName);
}

void ChooseDiskName(short nDisk, char *szFileName)
{
if (nDisk==0 && fDiskA!=0)
  {
  fclose(fDiskA);
  fDiskA=0;
  }
else if (nDisk==1 && fDiskB!=0)
  {
  fclose(fDiskB);
  fDiskB=0;
  }

FILE *f=fopen(szFileName,"r+b");

if (!f)
  {
  FileError();
  return;
  }

if (nDisk==0)
  fDiskA=f;
else
  fDiskB=f;
}

void ReadSector(short wDisk, short wTrack, short wHead, short wSector)
{
// printf("Read  %d %d %d %d\n",wDisk,wTrack,wHead,wSector);
FILE *f=wDisk?fDiskB:fDiskA;
unsigned char *buf=wDisk?acSectBufB:acSectBufA;
memset(buf,0xe5,1024);
if (f)
  {
  fseek(f,(long)wTrack*10240L+(long)wHead*5120L+(long)(wSector-1)*1024L,SEEK_SET);
  fread(buf,1024,1,f);
  }
}

void WriteSector(short wDisk, short wTrack, short wHead, short wSector)
{
// printf("Write %d %d %d %d\n",wDisk,wTrack,wHead,wSector);
FILE *f=wDisk?fDiskB:fDiskA;
unsigned char *buf=wDisk?acSectBufB:acSectBufA;
if (f)
  {
  fseek(f,(long)wTrack*10240L+(long)wHead*5120L+(long)(wSector-1)*1024L,SEEK_SET);
  fwrite(buf,1024,1,f);
  }
}

int Equals(unsigned short wAddr,unsigned short wEndAddr,char cPage)
{
char c=mempages[cPage][wAddr];
int n=0;
while ((mempages[cPage][wAddr]==c) && (wAddr<=wEndAddr) && (n<=254))
  {
  wAddr++;
  n++;
  }
return n;
}

void WriteMem(FILE *f, unsigned short wStart, unsigned short wEnd,
              char cCompression, char cPage=0)
{
if (cPage!=0) // Дополнительный блок
  fwrite(&cPage,1,1,f);
struct
 {
 char cCompType;
 unsigned short wCompLen;
 unsigned short wStart;
 unsigned short wLen;
 } h;
h.cCompType=cCompression;
h.wLen=wEnd-wStart+1;
h.wCompLen=wEnd-wStart+1;
h.wStart=wStart;
fwrite(&h,sizeof(h),1,f);
char byte;
if (cCompression==COMPRESSION_NONE)
  for (long i=(long)wStart;i<=(long)wEnd;i++)
    {
    byte=mempages[cPage][i];
    fwrite(&byte,1,1,f);
    }
else // COMPRESSION_RLE
  {
  long lCompLenPos=ftell(f)-6;
  unsigned short cb;
  unsigned long i=wStart;
  unsigned short wCompLen=0;
  while (i<=wEnd)
    {
    cb=Equals(i,wEnd,cPage);
    if (cb<=3 && mempages[cPage][i]!=(unsigned char)0xCB)
      {
      byte=mempages[cPage][i++];
      fwrite(&byte,1,1,f);
      wCompLen++;
      }
    else
      {
      byte=0xcb;
      fwrite(&byte,1,1,f);
      byte=mempages[cPage][i];
      fwrite(&byte,1,1,f);
      byte=cb;
      fwrite(&byte,1,1,f);
      i+=cb;
      wCompLen+=3;
      }
    }
  unsigned short lCurPos=ftell(f);
  fseek(f,lCompLenPos,SEEK_SET);
  wCompLen+=7;
  fwrite(&wCompLen,2,1,f);
  fseek(f,lCurPos,SEEK_SET);
  }
}

void ReadMem(FILE *f, int bExtended=0)
{
char cPage=0;
if (bExtended)
  fread(&cPage,1,1,f);
char cCompression;
unsigned short wCompLen;
unsigned short wStart;
unsigned short wLen;

fread(&cCompression,1,1,f);
fread(&wCompLen,1,2,f);
fread(&wStart,1,2,f);
fread(&wLen,1,2,f);

if ((long)wStart+(long)wLen>(long)rom_adr)
  f_saverom=1;

char b;
unsigned short cb;

//unsigned short i=wStart;
long i=(long)wStart;
while (i<=(long)wStart+(long)wLen-1L)
//while (wStart+wLen-1-i<=0x8000)
  {
  fread(&b,1,1,f);
  if (b!=(unsigned char)0xcb || cCompression==0)
    mempages[cPage][i++]=b;
  else
    {
    fread(&b,1,1,f);
    fread(&cb,1,1,f);
    cb&=0xff;
    for (int j=0;j<cb;j++)
      mempages[cPage][i++]=b;
    }
  }
}

char back_colors[7]={0,0,0,1,0,2,3};

int SaveSS()
{
char b;
unsigned short w;
int i,j;

set_text_mode();
StopSound();
f_file_ss=1;
f_choose_file=0;
getfilename();
char *szFileName=(char *)&filename;
int len=strlen(szFileName);
if (len!=0 && len<=16 && (strcspn(szFileName,".")==len))
  strcat(szFileName,".rss");
if (!*szFileName) return 0;

FILE *f=fopen(szFileName,"wb");
if (!f)
  {
  FileError();
  return 0;
  }

  {
  RKSS_MAIN_HEADER mh;
  memset(&mh,0,sizeof(mh));
  mh.dwSig=0x53534b52; //RKSS
  mh.cModel=cModel;
  mh.wPC=reg_pc;
  mh.wAF=reg_af;
  mh.wBC=reg_bc;
  mh.wDE=reg_de;
  mh.wHL=reg_hl;
  mh.wSP=reg_sp;
  mh.cIF=int_flag;
  fwrite(&mh,sizeof(mh),1,f);
  }

if (cModel!=MODEL_S && cModel!=MODEL_O && cModel!=MODEL_M80 &&
    cModel!=MODEL_U && f_vid.cValue==MEM_NONE)
  {
  cur_x=mempages[0][curpos_addr];
  cur_y=mempages[0][curpos_addr+1];
  if (cModel==MODEL_P)
    cur_xy+=0x304;
  crt_param_1=0x4d;
  crt_param_2=0x1d;
  crt_param_3=0x99;
  if (cModel==MODEL_P)
    crt_param_4=0xd9;
  else if (cModel==MODEL_A)
    crt_param_4=0xd3;
  else
    crt_param_4=0x93;
  dma_mr=0xa4;
  pit_k2=1;
  }

switch (cModel)
  {
  case MODEL_R:
    {
    RKSS_RK_HEADER rrh;
    memset(&rrh,0,sizeof(rrh));
    rrh.cMonVer=cMonitor;
    rrh.wHeaderLen=sizeof(rrh);
    rrh.wScrBegAdr=sh_scrbeg;
    rrh.wScrLen=sh_scrlen;
    rrh.cScrLines=sh_height;
    rrh.cScrCols=sh_width;
    rrh.acCrtParams[0]=crt_param_1;
    rrh.acCrtParams[1]=crt_param_2;
    rrh.acCrtParams[2]=crt_param_3;
    rrh.acCrtParams[3]=crt_param_4;
    rrh.cDmaMR=dma_mr;
    rrh.wDmaBegAddr=dma_begadr;
    rrh.wDmaLen=dma_len;
    rrh.cCrtMReg=crt_mreg;
    rrh.wPitK0=pit_k0;
    rrh.wPitK1=pit_k1;
    rrh.wPitK2=pit_k2;
    rrh.wPitCnt0=pit_cnt0;
    rrh.wPitCnt1=pit_cnt1;
    rrh.wPitCnt2=pit_cnt2;
    rrh.cPitMode0=pit_mode0;
    rrh.cPitMode1=pit_mode1;
    rrh.cPitMode2=pit_mode2;
    rrh.cPitLd0=pit_ld0;
    rrh.cPitLd1=pit_ld1;
    rrh.cPitLd2=pit_ld2;
    rrh.cPortC=port_c&0xf;
    rrh.cCurX=cur_x;
    rrh.cCurY=cur_y;
    fwrite(&rrh,sizeof(rrh),1,f);
    break;
    }
  case MODEL_P:
    {
    RKSS_PARTNER_HEADER rph;
    memset(&rph,0,sizeof(rph));
    rph.cMonVer=cMonitor;
    rph.wHeaderLen=sizeof(rph);
    rph.wScrBegAdr=sh_scrbeg;
    rph.wScrLen=sh_scrlen;
    rph.cScrLines=sh_height;
    rph.cScrCols=sh_width;
    rph.acCrtParams[0]=crt_param_1;
    rph.acCrtParams[1]=crt_param_2;
    rph.acCrtParams[2]=crt_param_3;
    rph.acCrtParams[3]=crt_param_4;
    rph.cDmaMR=dma_mr;
    rph.wDmaBegAddr=dma_begadr;
    rph.wDmaLen=dma_len;
    rph.cCrtMReg=crt_mreg;
    rph.cPortC=port_c&0xf;
    rph.cCurX=cur_x;
    rph.cCurY=cur_y;
    fwrite(&rph,sizeof(rph),1,f);
    break;
    }
  case MODEL_M:
    {
    RKSS_MIKROSHA_HEADER rmh;
    memset(&rmh,0,sizeof(rmh));
    rmh.cMonVer=cMonitor;
    rmh.wHeaderLen=sizeof(rmh);
    rmh.wScrBegAdr=sh_scrbeg;
    rmh.wScrLen=sh_scrlen;
    rmh.cScrLines=sh_height;
    rmh.cScrCols=sh_width;
    rmh.acCrtParams[0]=crt_param_1;
    rmh.acCrtParams[1]=crt_param_2;
    rmh.acCrtParams[2]=crt_param_3;
    rmh.acCrtParams[3]=crt_param_4;
    rmh.cDmaMR=dma_mr;
    rmh.wDmaBegAddr=dma_begadr;
    rmh.wDmaLen=dma_len;
    rmh.cCrtMReg=crt_mreg;
    rmh.wPitK0=pit_k0;
    rmh.wPitK1=pit_k1;
    rmh.wPitK2=pit_k2;
    rmh.wPitCnt0=pit_cnt0;
    rmh.wPitCnt1=pit_cnt1;
    rmh.wPitCnt2=pit_cnt2;
    rmh.cPitMode0=pit_mode0;
    rmh.cPitMode1=pit_mode1;
    rmh.cPitMode2=pit_mode2;
    rmh.cPitLd0=pit_ld0;
    rmh.cPitLd1=pit_ld1;
    rmh.cPitLd2=pit_ld2;
    rmh.cPortC=port_c&0xf;
    rmh.cPPI2B=mikr_symg;
    rmh.cCurX=cur_x;
    rmh.cCurY=cur_y;
    fwrite(&rmh,sizeof(rmh),1,f);
    break;
    }
  case MODEL_A:
    {
    RKSS_APOGEY_HEADER rah;
    memset(&rah,0,sizeof(rah));
    rah.cMonVer=cMonitor;
    rah.wHeaderLen=sizeof(rah);
    rah.wScrBegAdr=sh_scrbeg;
    rah.wScrLen=sh_scrlen;
    rah.cScrLines=sh_height;
    rah.cScrCols=sh_width;
    rah.acCrtParams[0]=crt_param_1;
    rah.acCrtParams[1]=crt_param_2;
    rah.acCrtParams[2]=crt_param_3;
    rah.acCrtParams[3]=crt_param_4;
    rah.cDmaMR=dma_mr;
    rah.wDmaBegAddr=dma_begadr;
    rah.wDmaLen=dma_len;
    rah.cCrtMReg=crt_mreg;
    rah.wPitK0=pit_k0;
    rah.wPitK1=pit_k1;
    rah.wPitK2=pit_k2;
    rah.wPitCnt0=pit_cnt0;
    rah.wPitCnt1=pit_cnt1;
    rah.wPitCnt2=pit_cnt2;
    rah.cPitMode0=pit_mode0;
    rah.cPitMode1=pit_mode1;
    rah.cPitMode2=pit_mode2;
    rah.cPitLd0=pit_ld0;
    rah.cPitLd1=pit_ld1;
    rah.cPitLd2=pit_ld2;
    rah.cPortC=port_c&0xf;
    rah.cCurX=cur_x;
    rah.cCurY=cur_y;
    fwrite(&rah,sizeof(rah),1,f);
    break;
    }
  case MODEL_S:
    {
    RKSS_SPEC_HEADER rsh;
    memset(&rsh,0,sizeof(rsh));
    rsh.cMonVer=cMonitor;
    rsh.wHeaderLen=sizeof(rsh)+3072+3;
    rsh.cPortC=port_c&0xf0;
    fwrite(&rsh,sizeof(rsh),1,f);
    // Цвет (5цв.)
    b=0x01;
    fwrite(&b,1,1,f);
    w=3075;
    fwrite(&w,2,1,f);
    unsigned char col_b;
    for (i=0;i<3072;i++)
      {
      col_b=0;
      for (j=0;j<4;j++)
        {
        b=color_mem[i*4+j];
        b=back_colors[b];
        col_b=col_b>>2 | (b<<6);
        }
      fwrite(&col_b,1,1,f);
      }
    break;
    }
  case MODEL_O:
    {
    RKSS_ORION_HEADER roh;
    memset(&roh,0,sizeof(roh));
    roh.cMonVer=cMonitor;
    roh.wHeaderLen=sizeof(roh);
    roh.cPortC=port_c&0xf;
    roh.cMemPage=mem_page_no;
    roh.cScrPage=or_scrpage;
    roh.cColorMode=or_color_mode;
    roh.cExtBlocks=1;
    fwrite(&roh,sizeof(roh),1,f);
    break;
    }
  case MODEL_M80:
    {
    RKSS_M80_HEADER r8h;
    memset(&r8h,0,sizeof(r8h));
    r8h.cMonVer=cMonitor;
    r8h.wHeaderLen=sizeof(r8h);
    fwrite(&r8h,sizeof(r8h),1,f);
    break;
    }
  case MODEL_U:
    {
    RKSS_UT88_HEADER ruh;
    memset(&ruh,0,sizeof(ruh));
    ruh.cMonVer=cMonitor;
    ruh.wHeaderLen=sizeof(ruh);
    fwrite(&ruh,sizeof(ruh),1,f);
    break;
    }
  }

  {
  RKSS_EMUL_HEADER reh;
  reh.dwSig=0x30384d45;
  reh.wHeaderLen=sizeof(reh);
  reh.cSpeed=f_speed.cValue;
  reh.cMem=f_vid.cValue;
  reh.cHookF809=f_f809.cValue;
  reh.cScreen=f_scr.cValue;
  reh.cFont=f_font.cValue;
  reh.cSound=f_snd.cValue;
  reh.cTape=f_tape.cValue;
  reh.cRefr=f_refr.cValue;
  fwrite(&reh,sizeof(reh),1,f);
  }

  {
  char temp=f_saverom!=0?2:1;
  fwrite(&temp,1,1,f);
  }

switch (cModel)
  {
  case MODEL_M:
    WriteMem(f,0x0000,0x7fff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xf800,0xffff,COMPRESSION_RLE);
    break;
  case MODEL_R:
    WriteMem(f,0x0000,0x7fff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xf000,0xffff,COMPRESSION_RLE);
    break;
  case MODEL_P:
    WriteMem(f,0x0000,0xd7ff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xf000,0xffff,COMPRESSION_RLE);
    break;
  case MODEL_A:
    WriteMem(f,0x0000,0xeaff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xf000,0xffff,COMPRESSION_RLE);
    break;
  case MODEL_S:
    WriteMem(f,0x0000,0xbfff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xc000,0xdfff,COMPRESSION_RLE);
    break;
  case MODEL_O:
    WriteMem(f,0x0000,0xf3ff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xf800,0xffff,COMPRESSION_RLE);
    // Дополнительные блоки
    WriteMem(f,0x0000,0xf3ff,COMPRESSION_RLE,1);
    break;
  case MODEL_M80:
    WriteMem(f,0x0000,0xf7ff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xf800,0xffff,COMPRESSION_RLE);
    break;
  case MODEL_U:
    WriteMem(f,0x0000,0xf7ff,COMPRESSION_RLE);
    if (f_saverom!=0)
      WriteMem(f,0xf800,0xffff,COMPRESSION_RLE);
  }

fclose(f);
ShowMessage(ppcFileSuccMess,1,"",0,0);
return 1;
}

// Загрузка файлов RK (или BRU)
int LoadRK(FILE *f)
{
unsigned char bt;
unsigned long dwFileLen=filelength(fileno(f));
if (cModel!=MODEL_O)
  {
  if (dwFileLen<8)
    return 0;
  fread(&bt,1,1,f);
  if (bt!=0xe6)
    fseek(f,0,SEEK_SET);
  else
    dwFileLen--;
  unsigned short wBegAdr;
  unsigned short wEndAdr;
  if (cModel!=MODEL_S)
    {
    fread(((char *)&wBegAdr)+1,1,1,f);
    fread((char *)&wBegAdr,1,1,f);
    fread(((char *)&wEndAdr)+1,1,1,f);
    fread((char *)&wEndAdr,1,1,f);
    }
  else
    {
    fread(&wBegAdr,1,2,f);
    fread(&wEndAdr,1,2,f);
    }
  dwFileLen-=4;
  unsigned short wLen=wEndAdr-wBegAdr;
  if (wBegAdr==0xe6e6 | wBegAdr==0xd3d3)
    return 0; // Basic or EDM File 
  if (dwFileLen<wLen+2)
    return 0;
  for (unsigned int i=wBegAdr;i<=wEndAdr;i++)
    {
    fread(&bt,1,1,f);
    mempages[0][i]=bt;
    }
  }
else // MODEL_O
  {
  unsigned short wBruOfs=0;
  if (dwFileLen<32)
    return 0;
  unsigned short wReadLen;
  fseek(f,0x0a,SEEK_SET);
  fread(&wReadLen,1,2,f);
  if (wReadLen==0) // RKO
    {
    wBruOfs=0x4d;
    if (dwFileLen<wBruOfs+32)
      return 0;
    dwFileLen-=wBruOfs;
    fseek(f,0x0a+wBruOfs,SEEK_SET);
    fread(&wReadLen,1,2,f);
    } 
  wReadLen=(((wReadLen-1)|0xf)+17);
  if (dwFileLen<wReadLen)
    return 0;
//  short wCurAdr=0;
//  while (mempages[2][wCurAdr]!=0xff)
//    wCurAdr=wCurAdr+((((*(unsigned short far *)(mempages[2]+10))-1)|0x0f)+1);
  fseek(f,wBruOfs,SEEK_SET);
  for (unsigned int i=0;i<wReadLen;i++)
    {
    fread(&bt,1,1,f);
    mempages[1][/*wCurAdr+*/i]=bt;
    }
  mempages[1][/*wCurAdr+*/wReadLen]=0xff;
  }
return 1;
}

int LoadSS()
{
set_text_mode();
StopSound();
return LoadSSName(0);
}

int LoadSSName(char *szCmdLineFileName)
{
_asm push es
char *szFileName;

unsigned char b;
unsigned short w;

int i,j;

unsigned char cExtBlocks=0;

if (!szCmdLineFileName)
  {
  f_file_ss=1;
  f_choose_file=1;
  getfilename();
  szFileName=(char *)&filename;
  int len=strlen(szFileName);
  if (len!=0 && len<=16 && (strcspn(szFileName,".")==len))
  strcat(szFileName,".rss");
  }
else
  szFileName=szCmdLineFileName;

//puts(szFileName);
//_asm int 20h

if (!*szFileName) return 0;

FILE *f=fopen(szFileName,"rb");
if (!f)
  {
  FileError();
  return 0;
  }

unsigned long dwSig;
if (fread(&dwSig,1,4,f)!=4)
  {
  FileError();
  fclose(f);
  return 0;
  }

fseek(f,0,SEEK_SET);

if (dwSig!=0x53534b52)
  {
  unsigned long dwFileLen=filelength(fileno(f));
  if (dwFileLen==819200L) //ODI
    {
    fclose(f);
    ChooseDiskName(0, szFileName);
    return 2;
    }
// printf("%lx",dwSig);
  if (LoadRK(f))
    {
    fclose(f);
    return cModel==MODEL_O?3:2;
//    return 2;
    }
  else
    {
    FileError();
    fclose(f);
    return 0;
    }
  }

RKSS_MAIN_HEADER mh;
if (fread(&mh,sizeof(mh),1,f)!=1)
  {
  FileError();
  fclose(f);
  return 0;
  }
if (mh.cModel>7)
  {
  FormatError();
  fclose(f);
  return 0;
  }

cModel=mh.cModel;
SetModel();

// TuneMenu();
// RefreshMenu();
reg_pc=mh.wPC;
reg_af=mh.wAF;
reg_bc=mh.wBC;
reg_de=mh.wDE;
reg_hl=mh.wHL;
reg_sp=mh.wSP;
if (mh.cIF==1)
  enable_ints();
else
  disable_ints();

char cTemp;
int wHLen;

if (cModel==MODEL_R)
  {
  RKSS_RK_HEADER rrh;
  // установка полей по умолчанию
  rrh.acCrtParams[1]=0x4d;
  rrh.acCrtParams[1]=0x1d;
  rrh.acCrtParams[1]=0x99;
  rrh.acCrtParams[1]=0x93;
  rrh.cDmaMR=0xa4;
  rrh.cCrtMReg=0x27;
  rrh.wDmaBegAddr=0xffff;
  rrh.wDmaLen=0xffff;
  rrh.wPitK0=1;
  rrh.wPitK1=1;
  rrh.wPitK2=1;
  rrh.wPitCnt0=1;
  rrh.wPitCnt1=1;
  rrh.wPitCnt2=0;
  rrh.cPitMode0=0x26;
  rrh.cPitMode1=0x66;
  rrh.cPitMode2=0x90;
  rrh.cPitLd0=1;
  rrh.cPitLd1=1;
  rrh.cPitLd2=0; //####????
  fread(&rrh,2,1,f);
  wHLen=sizeof(rrh)>rrh.wHeaderLen?rrh.wHeaderLen:sizeof(rrh);
  fread((char near *)&rrh+2,wHLen-2,1,f);
  for (int i=rrh.wHeaderLen-sizeof(rrh);i>0;i--)
    fread(&cTemp,1,1,f);
  // Разбор параметров
  cMonitor=rrh.cMonVer;
  if (cMonitor>3)
    {
    MonitorWarning();
    cMonitor=0;
    }
  sh_scrbeg=rrh.wScrBegAdr;
  sh_scrlen=rrh.wScrLen;
  sh_height=rrh.cScrLines;
  sh_width=rrh.cScrCols;
  crt_param_1=rrh.acCrtParams[0];
  crt_param_2=rrh.acCrtParams[1];
  crt_param_3=rrh.acCrtParams[2];
  crt_param_4=rrh.acCrtParams[3];
  dma_mr=rrh.cDmaMR;
  crt_mreg=rrh.cCrtMReg;
  dma_begadr=rrh.wDmaBegAddr;
  dma_len=rrh.wDmaLen;
  pit_k0=rrh.wPitK0;
  pit_k1=rrh.wPitK1;
  pit_k2=rrh.wPitK2;
  pit_cnt0=rrh.wPitCnt0;
  pit_cnt1=rrh.wPitCnt1;
  pit_cnt2=rrh.wPitCnt2;
  pit_mode0=rrh.cPitMode0;
  pit_mode1=rrh.cPitMode1;
  pit_mode2=rrh.cPitMode2;
  pit_ld0=rrh.cPitLd0;
  pit_ld1=rrh.cPitLd1;
  pit_ld2=rrh.cPitLd2;
  port_c=rrh.cPortC;
  cur_x=rrh.cCurX;
  cur_y=rrh.cCurY;
  if (dma_begadr==0xffff)
    dma_begadr=sh_scrbeg;
  if (dma_len==0xffff)
    dma_len=sh_scrlen-1;
  }
else if (cModel==MODEL_P)
  {
  RKSS_PARTNER_HEADER rph;
  // установка полей по умолчанию
  rph.acCrtParams[1]=0x4d;
  rph.acCrtParams[1]=0x1d;
  rph.acCrtParams[1]=0x99;
  rph.acCrtParams[1]=0xd9;
  rph.cDmaMR=0xa4;
  rph.cCrtMReg=0x2b;
  fread(&rph,2,1,f);
  wHLen=sizeof(rph)>rph.wHeaderLen?rph.wHeaderLen:sizeof(rph);
  fread(((char near *)&rph)+2,wHLen-2,1,f);
  for (int i=rph.wHeaderLen-sizeof(rph);i>0;i--)
    fread(&cTemp,1,1,f);
  // Разбор параметров
  cMonitor=rph.cMonVer;
  if (cMonitor>2)
    {
    MonitorWarning();
    cMonitor=0;
    }
  sh_scrbeg=rph.wScrBegAdr;
  sh_scrlen=rph.wScrLen;
  sh_height=rph.cScrLines;
  sh_width=rph.cScrCols;
  crt_param_1=rph.acCrtParams[0];
  crt_param_2=rph.acCrtParams[1];
  crt_param_3=rph.acCrtParams[2];
  crt_param_4=rph.acCrtParams[3];
  dma_mr=rph.cDmaMR;
  crt_mreg=rph.cCrtMReg;
  dma_begadr=rph.wDmaBegAddr;
  dma_len=rph.wDmaLen;
  port_c=rph.cPortC;
  cur_x=rph.cCurX;
  cur_y=rph.cCurY;
  if (dma_begadr==0xffff)
    dma_begadr=sh_scrbeg;
  if (dma_len==0xffff)
    dma_len=sh_scrlen-1;
  }
else if (cModel==MODEL_M)
  {
  RKSS_MIKROSHA_HEADER rmh;
  // установка полей по умолчанию
  rmh.acCrtParams[1]=0x4d;
  rmh.acCrtParams[1]=0x1d;
  rmh.acCrtParams[1]=0x99;
  rmh.acCrtParams[1]=0x93;
  rmh.cDmaMR=0xa4;
  rmh.cCrtMReg=0x27;
  rmh.wPitK0=1;
  rmh.wPitK1=1;
  rmh.wPitK2=1;
  rmh.wPitCnt0=1;
  rmh.wPitCnt1=1;
  rmh.wPitCnt2=1;
  rmh.cPitMode0=0x36;
  rmh.cPitMode1=0x76;
  rmh.cPitMode2=0xb6;
  rmh.cPitLd0=0;
  rmh.cPitLd1=0;
  rmh.cPitLd2=0;
  rmh.cPPI2B=0;
  fread(&rmh,2,1,f);
  wHLen=sizeof(rmh)>rmh.wHeaderLen?rmh.wHeaderLen:sizeof(rmh);
  fread((char near *)&rmh+2,wHLen-2,1,f);
  for (int i=rmh.wHeaderLen-sizeof(rmh);i>0;i--)
    fread(&cTemp,1,1,f);
  // Разбор параметров
  sh_scrbeg=rmh.wScrBegAdr;
  sh_scrlen=rmh.wScrLen;
  sh_height=rmh.cScrLines;
  sh_width=rmh.cScrCols;
  crt_param_1=rmh.acCrtParams[0];
  crt_param_2=rmh.acCrtParams[1];
  crt_param_3=rmh.acCrtParams[2];
  crt_param_4=rmh.acCrtParams[3];
  dma_mr=rmh.cDmaMR;
  crt_mreg=rmh.cCrtMReg;
  dma_begadr=rmh.wDmaBegAddr;
  dma_len=rmh.wDmaLen;
  pit_k0=rmh.wPitK0;
  pit_k1=rmh.wPitK1;
  pit_k2=rmh.wPitK2;
  pit_cnt0=rmh.wPitCnt0;
  pit_cnt1=rmh.wPitCnt1;
  pit_cnt2=rmh.wPitCnt2;
  pit_mode0=rmh.cPitMode0;
  pit_mode1=rmh.cPitMode1;
  pit_mode2=rmh.cPitMode2;
  pit_ld0=rmh.cPitLd0;
  pit_ld1=rmh.cPitLd1;
  pit_ld2=rmh.cPitLd2;
  port_c=rmh.cPortC;
  mikr_symg=rmh.cPPI2B;
  cur_x=rmh.cCurX;
  cur_y=rmh.cCurY;
  if (dma_begadr==0xffff)
    dma_begadr=sh_scrbeg;
  if (dma_len==0xffff)
    dma_len=sh_scrlen-1;
  }
else if (cModel==MODEL_A)
  {
  RKSS_APOGEY_HEADER rah;
  // установка полей по умолчанию
  rah.acCrtParams[1]=0x4d;
  rah.acCrtParams[1]=0x1d;
  rah.acCrtParams[1]=0x99;
  rah.acCrtParams[1]=0xd3;
  rah.cDmaMR=0xa4;
  rah.cCrtMReg=0x27;
  rah.wPitK0=1;
  rah.wPitK1=1;
  rah.wPitK2=1;
  rah.wPitK0=1;
  rah.wPitK1=1;
  rah.wPitK2=1;
  rah.wPitCnt0=1;
  rah.wPitCnt1=1;
  rah.wPitCnt2=1;
  rah.cPitMode0=0x36;
  rah.cPitMode1=0x76;
  rah.cPitMode2=0xb6;
  rah.cPitLd0=0;
  rah.cPitLd1=0;
  rah.cPitLd2=0;
  fread(&rah,2,1,f);
  wHLen=sizeof(rah)>rah.wHeaderLen?rah.wHeaderLen:sizeof(rah);
  fread((char near *)&rah+2,wHLen-2,1,f);
  for (int i=rah.wHeaderLen-sizeof(rah);i>0;i--)
    fread(&cTemp,1,1,f);
  // Разбор параметров
  sh_scrbeg=rah.wScrBegAdr;
  sh_scrlen=rah.wScrLen;
  sh_height=rah.cScrLines;
  sh_width=rah.cScrCols;
  crt_param_1=rah.acCrtParams[0];
  crt_param_2=rah.acCrtParams[1];
  crt_param_3=rah.acCrtParams[2];
  crt_param_4=rah.acCrtParams[3];
  dma_mr=rah.cDmaMR;
  crt_mreg=rah.cCrtMReg;
  dma_begadr=rah.wDmaBegAddr;
  dma_len=rah.wDmaLen;
  pit_k0=rah.wPitK0;
  pit_k1=rah.wPitK1;
  pit_k2=rah.wPitK2;
  pit_cnt0=rah.wPitCnt0;
  pit_cnt1=rah.wPitCnt1;
  pit_cnt2=rah.wPitCnt2;
  pit_mode0=rah.cPitMode0;
  pit_mode1=rah.cPitMode1;
  pit_mode2=rah.cPitMode2;
  pit_ld0=rah.cPitLd0;
  pit_ld1=rah.cPitLd1;
  pit_ld2=rah.cPitLd2;
  port_c=rah.cPortC;
  cur_x=rah.cCurX;
  cur_y=rah.cCurY;
  if (dma_begadr==0xffff)
    dma_begadr=sh_scrbeg;
  if (dma_len==0xffff)
    dma_len=sh_scrlen-1;
  }
else if (cModel==MODEL_S)
  {
  RKSS_SPEC_HEADER rsh;
  // установка полей по умолчанию
  fread(&rsh,2,1,f);
  wHLen=sizeof(rsh)>rsh.wHeaderLen?rsh.wHeaderLen:sizeof(rsh);
  fread(((char near *)&rsh)+2,wHLen-2,1,f);
  //Цвет
  if (rsh.wHeaderLen>sizeof(rsh))
    {
    fread(&b,1,1,f);
    fread(&w,2,1,f);
    if (b!=1)
      {
      for (i=0;i<12288;i++)
        color_mem[i]=0;
      for (int i=rsh.wHeaderLen-sizeof(rsh)-3;i>0;i--)
        fread(&cTemp,1,1,f);
      }
    else
      {
      // Считываем цвет
      for (i=0;i<3072;i++)
        {
        fread(&b,1,1,f);
        for (j=0;j<4;j++)
          {
          color_mem[i*4+j]=color_table[b & 3];
          b>>=2;
          }
        }
      for (int i=rsh.wHeaderLen-sizeof(rsh)-3075;i>0;i--)
        fread(&cTemp,1,1,f);
      }
    }
  // Разбор параметров
  cMonitor=rsh.cMonVer;
  if (cMonitor>4)
    {
    MonitorWarning();
    cMonitor=0;
    }
  port_c=rsh.cPortC;
  }
else if (cModel==MODEL_O)
  {
  RKSS_ORION_HEADER roh;
  // установка полей по умолчанию
  fread(&roh,2,1,f);
  wHLen=sizeof(roh)>roh.wHeaderLen?roh.wHeaderLen:sizeof(roh);
  fread((char near *)&roh+2,wHLen-2,1,f);
  for (int i=roh.wHeaderLen-sizeof(roh);i>0;i--)
    fread(&cTemp,1,1,f);
  // Разбор параметров
  cMonitor=roh.cMonVer;
  if (cMonitor>3)
    {
    MonitorWarning();
    cMonitor=0;
    }
  port_c=roh.cPortC;
  or_scrpage=roh.cScrPage;
  mem_page_no=roh.cMemPage;
  or_color_mode=roh.cColorMode;
  cExtBlocks=roh.cExtBlocks;
  }
else if (cModel==MODEL_M80)
  {
  RKSS_M80_HEADER r8h;
  // установка полей по умолчанию
  fread(&r8h,2,1,f);
  wHLen=sizeof(r8h)>r8h.wHeaderLen?r8h.wHeaderLen:sizeof(r8h);
  fread(((char near *)&r8h)+2,wHLen-2,1,f);

  // Разбор параметров
  cMonitor=r8h.cMonVer;
  }
else if (cModel==MODEL_U)
  {
  RKSS_UT88_HEADER ruh;
  // установка полей по умолчанию
  fread(&ruh,2,1,f);
  wHLen=sizeof(ruh)>ruh.wHeaderLen?ruh.wHeaderLen:sizeof(ruh);
  fread(((char near *)&ruh)+2,wHLen-2,1,f);

  // Разбор параметров
  cMonitor=ruh.cMonVer;
//  port_c=rsh.cPortC;
  }

SetMonitor();

  {
  RKSS_EMUL_HEADER reh;
  // установка полей по умолчанию
  reh.cSpeed=SPEED_NORM;
  reh.cMem=MEM_RW;
  reh.cHookF809=HOOKF809_NO;
  reh.cScreen=SCR_AUTO;
  reh.cFont=FONT_RK;
  reh.cRefr=REFR_COMB;
  reh.cSound=SND_ON;
  reh.cTape=TAPE_FILE;
  fread(&reh,4,1,f);
  fread((char near *)&reh+4,2,1,f);
  if (reh.dwSig==0x30384d45) //EM80
    {
    wHLen=sizeof(reh)>reh.wHeaderLen?reh.wHeaderLen:sizeof(reh);
    fread((char near *)&reh+6,wHLen-6,1,f);
    }
  else
    wHLen=6;
  for (int i=reh.wHeaderLen-wHLen;i>0;i--)
    fread(&cTemp,1,1,f);
//  if (reh.dwSig==0x30384d45) //EM80
    {
    // Разбор параметров эмулятора
    ClearDisabledMenuItems();
    SetDefParams();
    f_speed.cValue=reh.cSpeed;
    f_vid.cValue=reh.cMem;
    f_f809.cValue=reh.cHookF809;
    f_scr.cValue=reh.cScreen;
    f_font.cValue=reh.cFont;
    if (cModel!=MODEL_S && cModel!=MODEL_O)
      f_refr.cValue=reh.cRefr;
    if (wHLen>=12)
      {
      f_snd.cValue=reh.cSound;
      if (wHLen>=13)
        f_tape.cValue=reh.cTape;
      }
    RefreshMenu();
    }
  }

char cBlocks;
fread(&cBlocks,1,1,f);

ClearMem();

LoadROM();

for (i=1;i<=(int)cBlocks;i++)
  {
  ReadMem(f);
  }

//if (cModel=MODEL_U)
//  // Дублируем видеообласть
//  for (w=0xe000;w<0xe800;w++)
//    mempages[0][w+0x800]=mempages[0][w];

for (i=1;i<=(int)cExtBlocks;i++)
  {
  ReadMem(f,1);
  }

TuneMenu();
RefreshMenu();

fclose(f);

Init();

//SetModel();
_asm pop es
_asm push bp
_asm push ds
_asm lds bp,mempage0
//anal_params();
process_crt();
process_pit();
process_port_c();
//process_orion();
_asm pop ds
_asm pop bp

return 1;
}

void RefreshMenuLine(MENU_LINE *pmlLine)
{
char cValue=pmlLine->cValue;
MENU_ITEM *pmi;
for (pmi=pmlLine->pmiItem;pmi->cValue!=cValue;pmi=pmi->pmiNext);
if (pmi->cDisabled)
  pmlLine->cValue=pmlLine->pmiItem->cValue;
else
  pmlLine->pmiItem=pmi;
}

void RefreshMenu()
{
RefreshMenuLine(&f_speed);
RefreshMenuLine(&f_vid);
RefreshMenuLine(&f_f809);
RefreshMenuLine(&f_scr);
RefreshMenuLine(&f_font);
RefreshMenuLine(&f_refr);
RefreshMenuLine(&f_snd);
RefreshMenuLine(&f_tape);
}

void TuneMenu()
{
unsigned char f_gr, f_vg;
if (cModel!=MODEL_S && cModel!=MODEL_O)
  f_gr=0;
else
  f_gr=1;
if (cModel!=MODEL_S && cModel!=MODEL_O &&
    cModel!=MODEL_U && cModel!=MODEL_M80)
  f_vg=0;
else
  {
  f_vg=1;
  f_refr.cValue=REFR_RT;
  }
i_spmed.cDisabled=f_vg;
i_vidno.cDisabled=f_vg;
i_f809yes.cDisabled=f_vg;
i_scrlow.cDisabled=f_vg;
i_scrhigh.cDisabled=f_vg;
i_scrgr.cDisabled=f_gr;
i_fontoem.cDisabled=f_gr;
i_refrcomb.cDisabled=f_vg;
i_refr50.cDisabled=f_vg;
if (cModel==MODEL_O)
  {
  i_refrcomb.cDisabled=0;
  i_refrrt.cDisabled=1;
  f_refr.cValue=REFR_COMB;
  }
}

void ClearDisabledMenuItems()
{
i_spmed.cDisabled=0;
i_vidno.cDisabled=0;
i_f809yes.cDisabled=0;
i_scrlow.cDisabled=0;
i_scrhigh.cDisabled=0;
i_scrgr.cDisabled=0;
i_fontoem.cDisabled=0;
i_refrcomb.cDisabled=0;
i_refr50.cDisabled=0;
i_refrcomb.cDisabled=0;
i_refrrt.cDisabled=0;
}

static char *ppcModelList[8]={" Р А Д И О - 8 6 Р К ",
                              " М И К Р О Ш А",
                              " П А Р Т Н Е Р",
                              " А П О Г Е Й",
                              " С П Е Ц И А Л И С Т",
                              " О Р И О Н",
                              " М И К Р О - 8 0",
                              " Ю Т - 8 8",
                              };

static char *ppcROMOList[3]={"  M o n i t o r - 1  ",
                             "  M o n i t o r - 2  ",
                             "  П е т е р б у р г  ",
                              };

static char *ppcROMRList[3]={" M o n i t o r - 1 6 K ",
                             " M o n i t o r - 3 2 K ",
                             " Р а с ш и р е н н ы й ",
//                             " V e r s i o n   3 ",
                              };

static char *ppcROMSList[4]={" О р и г и н а л ь н ы й ",
                             " У л у ч ш е н н ы й ",
                             " О к о н н ы й ",
                             " П К \" Л И К \" ",
                              };

static char *ppcROMPList[2]={" М о н и т о р - В . 0 2 ",
                             " М о н и т о р - В . 0 3 ",
                              };

//static char *ppcROMM80List[2]={" О р и г и н а л ь н ы й ",
//                               " С о в м е с т и м ы й   с  Р К - 8 6 ",
//                                };

static unsigned wSaveES;

int ChooseModel()
{
set_text_mode();
StopSound();
_asm push es
int res=ShowMessage(ppcModelList,8," Выбор типа ПК ",1,cModel);
if (res!=-1)
  {
  ClearDisabledMenuItems();
  SetDefParams();
  LoadIniParams();
  cModel=res;
  if (bIsDefMem && ((cModel==MODEL_S) || (cModel==MODEL_O)))
    f_vid.cValue=MEM_RW;
  if ((cModel==MODEL_S) || (cModel==MODEL_O))
    f_scr.cValue=SCR_AUTO;
  RefreshMenu();
  TuneMenu();
  RefreshMenu();
  cMonitor=MON_DEF;
  SetModel();
  if (bNeedClearMem)
    ClearMem(); 
  LoadROM();
  Init();
  }
_asm pop es
return (res!=-1);
}

int ChooseROM()
{
int res;
if (cModel!=MODEL_O && cModel!=MODEL_R && cModel!=MODEL_S &&
    cModel!=MODEL_P/* && cModel!=MODEL_M80*/)
  return 0;
set_text_mode();
StopSound();
_asm push es
if (cModel==MODEL_O)
  res=ShowMessage(ppcROMOList,3," Выбор Монитора ",1,cMonitor-1)+1;
else if (cModel==MODEL_R)
  {
  res=ShowMessage(ppcROMRList,3," Выбор Монитора ",1,
  (cMonitor>2)?(cMonitor-1):(cMonitor-1)^1);
  res=res>1?res+1:(res^1)+1;
  }
else if (cModel==MODEL_S)
  {
  res=ShowMessage(ppcROMSList,4," Выбор Монитора ",1,
  (cMonitor>2)?(cMonitor-1):(cMonitor-1)^1);
  res=res>1?res+1:(res^1)+1;
  }
else if (cModel==MODEL_P)
  res=(ShowMessage(ppcROMPList,2," Выбор Монитора ",1,(cMonitor-1)^1)^1)+1;
//else if (cModel==MODEL_M80)
//  res=ShowMessage(ppcROMM80List,2," Выбор Монитора ",1,cMonitor-1)+1;
if (res>0)
  {
  cMonitor=res;
  SetModel(); //##### Лучше просто изменить имя файла с ПЗУ
  LoadROM();
  }
_asm pop es
return (res>0);
}

void AlterSpeed(short nSysReq)
{
if (f_snd.cValue!=SND_SB)
  {
  if (nSysReq==SYSREQ_SPEEDUP)
    {
    if (delay*6/5<wMaxDelay)
      delay=delay*6/5;
    }
  else
    {
    if (delay*5/6>wMinDelay)
      delay=delay*5/6;
    }
  }
else
  {
  if (nSysReq==SYSREQ_SPEEDUP)
    {
    if (delay_sb*6/5<wMaxDelaySB)
      delay_sb=delay_sb*6/5;
    }
  else
    {
    if (delay_sb*5/6>wMinDelaySB)
      delay_sb=delay_sb*5/6;
    }
  }
}

void trim(char *s)
{
char *p=s;
char *t=s;
while (*p==' ' || *p=='\t')
  p++;
while (*p!=' ' && *p!='\t' && *p!='\0' && *p!='\n')
  *t++=*p++;
*t='\0';
}

void AnalizeIniString(char *s)
{
if (!strnicmp(s,"speed=",6))
  {
  if (!stricmp(s+6,"normal"))
    f_speed.cValue=SPEED_NORM;
  else if (!stricmp(s+6,"medium"))
    f_speed.cValue=SPEED_MEDIUM;
  else if (!stricmp(s+6,"high"))
    f_speed.cValue=SPEED_HIGH;
  }
else if (!strnicmp(s,"mem=",4))
  {
  if (!stricmp(s+4,"none"))
    {f_vid.cValue=MEM_NONE;bIsDefMem=0;}
  else if (!stricmp(s+4,"write"))
    {f_vid.cValue=MEM_W;bIsDefMem=0;}
  else if (!stricmp(s+4,"rw"))
    {f_vid.cValue=MEM_RW;bIsDefMem=0;}
  }
else if (!strnicmp(s,"hookf809=",9))
  {
  if (!stricmp(s+9,"on"))
    f_f809.cValue=HOOKF809_YES;
  else if (!stricmp(s+9,"off"))
    f_f809.cValue=HOOKF809_NO;
  }
else if (!strnicmp(s,"screen=",7))
  {
  if (!stricmp(s+7,"auto"))
    f_scr.cValue=SCR_AUTO;
  else if (!stricmp(s+7,"graph"))
    f_scr.cValue=SCR_GRAPH;
  else if (!stricmp(s+7,"64x25"))
    f_scr.cValue=SCR_LOW;
  else if (!stricmp(s+7,"78x30"))
    f_scr.cValue=SCR_HIGH;
  }
else if (!strnicmp(s,"font=",5))
  {
  if (!stricmp(s+5,"oem"))
    f_font.cValue=FONT_OEM;
  else if (!stricmp(s+5,"rk"))
    f_font.cValue=FONT_RK;
  }
else if (!strnicmp(s,"refrtxt=",8))
  {
  if (!stricmp(s+8,"realtime"))
    f_refr.cValue=REFR_RT;
  else if (!stricmp(s+8,"50hz"))
    f_refr.cValue=REFR_50;
//  else if (!stricmp(s+5,"comb"))
//    f_refr.cValue=REFR_COMB;
  }
else if (!strnicmp(s,"sound=",6))
  {
  if (!stricmp(s+6,"on"))
    f_snd.cValue=SND_ON;
  else if (!stricmp(s+6,"off"))
    f_snd.cValue=SND_OFF;
  else if (!stricmp(s+6,"sb"))
    f_snd.cValue=SND_SB;
  }
else if (!strnicmp(s,"tape=",5))
  {
  if (!stricmp(s+5,"sb-in"))
    f_tape.cValue=TAPE_SBIN;
  else if (!stricmp(s+5,"sb-out"))
    f_tape.cValue=TAPE_SBOUT;
  }
else if (!strnicmp(s,"type=",5))
  {
  if (!stricmp(s+5,"rk86-32"))
    cModel=MODEL_R;
  else if (!stricmp(s+5,"partner"))
    cModel=MODEL_P;
  else if (!stricmp(s+5,"apogey"))
    cModel=MODEL_A;
  else if (!stricmp(s+5,"mikrosha"))
    cModel=MODEL_M;
  else if (!stricmp(s+5,"spec"))
    cModel=MODEL_S;
  else if (!stricmp(s+5,"orion"))
    cModel=MODEL_O;
  }
else if (!strnicmp(s,"use_vesa=",9))
  {
  if (!stricmp(s+9,"on"))
    f_novesa=0;
  else if (!stricmp(s+9,"off"))
    f_novesa=1;
  else if (!stricmp(s+9,"6a"))
    f_novesa=2;
  }
else if (!strnicmp(s,"sbport=",7))
  {
  if (!stricmp(s+7,"240"))
    wSBPort=0x240;
  }
else if (!strnicmp(s,"sbdma=",6))
  {
  if (!stricmp(s+6,"0"))
    wSBDMA=0;
  else if (!stricmp(s+6,"3"))
    wSBDMA=3;
  }
else if (!strnicmp(s,"led=",4))
  {
  if (!stricmp(s+4,"on"))
    f_led=1;
  else if (!stricmp(s+4,"off"))
    f_led=0;
  }
else if (!strnicmp(s,"matrox_fix=",11))
  {
  if (!stricmp(s+11,"on"))
    vmem_off=4404;
  }
else if (!strnicmp(s,"use_8x12=",8))
  {
  if (!stricmp(s+9,"off"))
    f_use8x12=0;
  }

if (f_vid.cValue==MEM_NONE)
  f_f809.cValue=HOOKF809_YES;
RefreshMenu();
}

// Загружает параметры из ini-файла, если он есть в текущей директории
void LoadIniParams()
{
char s[81];
FILE *f;
f=fopen("emu80.ini","r");
if (!f)
  {
  (&com_path)[com_path_len]=0;
  f=fopen(strcat(&com_path,"emu80.ini"),"r");
  }
bIsDefMem=1;
if (!f) return;
while (!feof(f))
  {
  fgets(s,81,f);
  trim(s);
  if ((*s)!='\0' && (*s)!=';')
    AnalizeIniString(s);
  }
fclose(f);
}

static char *ppcHelp[17]={" Горячие клавиши в режиме эмуляции: ",
                         " ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
                         "  F10 ........ выход в меню",
                         "  F9  ........ выбор компьютера ",
                         "  Alt-F9  .... выбор без оч. пам. ",
                         "  Alt-F8  .... выбор Монитора ",
                         "  Alt-F10 .... выход ",
                         "  Alt-F11 .... reset ",
                         "  F12 ........ пауза/возобновление ",
                         "  Alt-F1 ..... эта подсказка",
                         "  Alt-F2 ..... запись snapshot'а ",
                         "  Alt-F3 ..... загрузка (универс.) ",
                         "  Alt-F5 ..... выбор диска A: ",
                         "  Alt-F6 ..... выбор диска B: ",
                         "  Alt-PgUp ... ускорение работы ",
                         "  Alt-PgDn ... замедление работы ",
                         "  ScrollLock . перекл. QWERTY/ЙЦУКЕН ",
                         };

void ShowHelp()
{
set_text_mode();
StopSound();
ShowMessage(ppcHelp,17," Подсказка ",0,0);
}

//#include "sb.h"

char *szFileName;

int AnalizeOptions(int arg_n, char **arg_c)
{
int i, res=0;
szFileName="";
for (i=1;i<arg_n;i++)
  {
  if (!stricmp(arg_c[i],"-r"))
    cModel=MODEL_R;
  else if (!stricmp(arg_c[i],"-p"))
    cModel=MODEL_P;
  else if (!stricmp(arg_c[i],"-a"))
    cModel=MODEL_A;
  else if (!stricmp(arg_c[i],"-m"))
    cModel=MODEL_M;
  else if (!stricmp(arg_c[i],"-s"))
    cModel=MODEL_S;
  else if (!stricmp(arg_c[i],"-o"))
    cModel=MODEL_O;
  else if (!stricmp(arg_c[i],"-8"))
    cModel=MODEL_M80;
  else if (!stricmp(arg_c[i],"-u"))
    cModel=MODEL_U;
  else
    {
    szFileName=arg_c[i];
    res=1;
    };
  }
return res;
}

void _main(int arg_n, char **arg_c)
{
_asm push si
_asm push di
// StartSound();
InitOnce();
SetDefParams();
LoadIniParams();
ClearMem();
int res=0;
_asm pop di
_asm pop si
//  Init();
res=AnalizeOptions(arg_n, arg_c);
if (bIsDefMem && ((cModel==MODEL_S) || (cModel==MODEL_O)))
  f_vid.cValue=MEM_RW;
if ((cModel==MODEL_S) || (cModel==MODEL_O))
  f_scr.cValue=SCR_AUTO;
RefreshMenu();
if (res)
  {
//  printf("%s", szFileName);
  _asm push es
  res=LoadSSName(szFileName);
  _asm pop es
  }
else
  {
  SetModel();
  LoadROM();
  TuneMenu();
  RefreshMenu();
  Init();
  Start();
  }
if (res==2 || res==3)
  {
  SetModel();
  LoadROM();
  TuneMenu();
  RefreshMenu();
  Init();
  Start();
  }
else if (res==1)
  Resume();
//if (res==1)
//  Resume();
//else
//  Start();
}
