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

#ifndef _RSS_H
#define _RSS_H

#define USE_OPTIONAL

#define MODEL_R 0
#define MODEL_M 1
#define MODEL_P 2
#define MODEL_A 3
#define MODEL_S 4
#define MODEL_O 5
#define MODEL_M80 6
#define MODEL_U 7

#define MON_DEF 0

#define MON_O_1 1
#define MON_O_2 2
#define MON_O_PET 3

#define MON_R_32 1
#define MON_R_16 2
#define MON_R_4K 3
//#define MON_R_3 4

#define MON_S_2 1
#define MON_S_1 2
#define MON_S_M 3
#define MON_S_L 4

#define MON_P_V3 1
#define MON_P_V2 2

#define MON_M80_O 1
#define MON_M80_R 2

struct RKSS_MAIN_HEADER
  {
  unsigned long dwSig;
  unsigned char cModel;
  unsigned short wPC;
  unsigned short wBC;
  unsigned short wDE;
  unsigned short wHL;
  unsigned short wAF;
  unsigned short wSP;
  unsigned char cIF;
  };

struct RKSS_RK_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  unsigned short wScrBegAdr;
  unsigned short wScrLen;
  unsigned char cScrLines;
  unsigned char cScrCols;
  unsigned char cPortC;
  unsigned char cCurX;
  unsigned char cCurY;
#ifdef USE_OPTIONAL
  unsigned char acCrtParams[4];
  unsigned char cDmaMR;
  unsigned char wDmaBegAddr;
  unsigned char wDmaLen;
  unsigned char cCrtMReg;
  unsigned short wPitK0;
  unsigned short wPitK1;
  unsigned short wPitK2;
  unsigned short wPitCnt2;
  unsigned short wPitCnt0;
  unsigned short wPitCnt1;
  unsigned char cPitMode0;
  unsigned char cPitMode1;
  unsigned char cPitMode2;
  unsigned char cPitLd0;
  unsigned char cPitLd1;
  unsigned char cPitLd2;
#endif
  };

struct RKSS_PARTNER_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  unsigned short wScrBegAdr;
  unsigned short wScrLen;
  unsigned char cScrLines;
  unsigned char cScrCols;
  unsigned char cPortC;
  unsigned char cCurX;
  unsigned char cCurY;
#ifdef USE_OPTIONAL
  unsigned char acCrtParams[4];
  unsigned char cDmaMR;
  unsigned char wDmaBegAddr;
  unsigned char wDmaLen;
  unsigned char cCrtMReg;
#endif
  };

struct RKSS_MIKROSHA_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  unsigned short wScrBegAdr;
  unsigned short wScrLen;
  unsigned char cScrLines;
  unsigned char cScrCols;
  unsigned char cPortC;
  unsigned char cCurX;
  unsigned char cCurY;
#ifdef USE_OPTIONAL
  unsigned char acCrtParams[4];
  unsigned char cDmaMR;
  unsigned short wPitK2;
  unsigned char wDmaBegAddr;
  unsigned char wDmaLen;
  unsigned char cCrtMReg;
  unsigned char cPPI2B;
  unsigned short wPitK0;
  unsigned short wPitK1;
  unsigned short wPitCnt0;
  unsigned short wPitCnt1;
  unsigned short wPitCnt2;
  unsigned char cPitMode0;
  unsigned char cPitMode1;
  unsigned char cPitMode2;
  unsigned char cPitLd0;
  unsigned char cPitLd1;
  unsigned char cPitLd2;
#endif
  };

struct RKSS_APOGEY_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  unsigned short wScrBegAdr;
  unsigned short wScrLen;
  unsigned char cScrLines;
  unsigned char cScrCols;
  unsigned char cPortC;
  unsigned char cCurX;
  unsigned char cCurY;
#ifdef USE_OPTIONAL
  unsigned char acCrtParams[4];
  unsigned char cDmaMR;
  unsigned short wPitK0;
  unsigned short wPitK1;
  unsigned short wPitK2;
  unsigned char wDmaBegAddr;
  unsigned char wDmaLen;
  unsigned char cCrtMReg;
  unsigned short wPitCnt0;
  unsigned short wPitCnt1;
  unsigned short wPitCnt2;
  unsigned char cPitMode0;
  unsigned char cPitMode1;
  unsigned char cPitMode2;
  unsigned char cPitLd0;
  unsigned char cPitLd1;
  unsigned char cPitLd2;
#endif
  };

struct RKSS_SPEC_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  unsigned char cPortC;
  };

struct RKSS_ORION_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  unsigned char cPortC;
  unsigned char cColorMode;   //    ������� ०��� 梥⭮��
  unsigned char cMemPage;     //    ������ ��࠭�� �����
  unsigned char cScrPage;     //    ������ ��࠭��� �������
  unsigned char cExtBlocks;   //    ������⢮ �������⥫��� ������ ������
  };

struct RKSS_M80_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  };

struct RKSS_UT88_HEADER
  {
  unsigned short wHeaderLen;
  unsigned char cMonVer;
  };

struct RKSS_NULLEMUL_HEADER
  {
  unsigned long dwSig;
  unsigned short wHeaderLen;
  };

#define COMPRESSION_NONE 0
#define COMPRESSION_RLE 1

#endif
