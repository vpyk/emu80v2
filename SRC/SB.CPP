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

#include "sb.h"

unsigned short wSBPort=0x220;
unsigned short wSBDMA=1;

static int wDMABase=0x02;
static int wDMACounter=0x03;
static int wDMAPage=0x83;

static int Pages[4]={0x87,0x83,0x81,0x82};

static void *pDMABuf;

static int nCurPos;

static int bStarted=0;
int bSBPresent=0;

int t=0;

extern "C" int bWaitSnd=0;

int ResetDSP()
{
if (bStarted)
  {
  StopSound();
  return 1;
  }
_asm mov dx,wSBPort
_asm add dx,6
_asm mov al,1
_asm out dx,al
//_asm push dx
//_asm mov dx,388h
//_asm mov cx,100
//l2:
//_asm in al,dx
//_asm loop l2
//_asm pop dx
 _asm in al,dx
 _asm in al,dx
 _asm in al,dx
 _asm in al,dx
_asm xor al,al
_asm out dx,al
//_asm push dx
//_asm mov dx,388h
//_asm mov cx,1000
//l3:
//_asm in al,dx
//_asm loop l3
//_asm pop dx
 _asm add dx,8
 _asm mov cx,200
l6:
 _asm in al,dx
 _asm test al,al
 _asm js l5
 _asm loop l6
 _asm mov ax,0
 _asm jmp l4
l5:
//_asm add dx,4
 _asm sub dx,4
_asm in al,dx
_asm cmp al,0aah
_asm mov ax,0
_asm jne l4
_asm mov ax,1
l4:
_asm mov bSBPresent,ax
}

static void *pPhysBuf;

void AllocateDMABuf()
{
pPhysBuf=new char[1764*2];

unsigned long adr=(unsigned long)(void far *)(pPhysBuf);
adr=(adr & 0xffffL)+((adr & 0xffff0000)>>12);
int ofs=adr & 0xffff;
if (-ofs<=-1764)
 pDMABuf=pPhysBuf;
else
 pDMABuf=((char *)pPhysBuf)+1764;
for (int i=0;i<1764;((char *)pDMABuf)[i++]=0x80);
// for (i=0;i<1760;((char *)pDMABuf)[i+=2]=0);
}

void FreeDMABuf()
{
delete[] pPhysBuf;
}

void WriteDSP(int val)
{
_asm mov dx,wSBPort
_asm add dx,0ch
l1:
_asm in al,dx
_asm test al,al
_asm js l1
_asm mov ax,val
_asm out dx,al
}

void StartSound(SS_MODE ssMode)
{
unsigned short wDMAMode=ssMode==ssOut?0x58:0x54;
bSBPresent=ResetDSP();
bStarted=1;
AllocateDMABuf();
if (!bSBPresent)
  return;
wDMABase=wSBDMA<<1;
wDMACounter=wDMABase+1;
wDMAPage=Pages[wSBDMA];
//WriteDSP(0xa0);
WriteDSP(0x40);
WriteDSP(233);
WriteDSP(0x48);
WriteDSP(881 & 0xff);
WriteDSP((881 & 0xff00)>>8);  //#####?
WriteDSP(0xD1);
_asm out 0ch,al
_asm mov ax,wDMAMode;
_asm or ax,wSBDMA
_asm out 0bh,al
unsigned long adr=(unsigned long)(void far *)(pDMABuf);
adr=(adr & 0xffffL)+((adr & 0xffff0000)>>12);
int page=(adr & 0xf0000)>>16;
int ofs=adr & 0xffff;
_asm mov dx,wDMABase
_asm mov ax,ofs
_asm out dx,al
_asm mov al,ah
_asm out dx,al
_asm mov dx,wDMAPage
_asm mov ax,page
_asm out dx,al
_asm mov ax,1763
_asm mov dx,wDMACounter
_asm out dx,al
_asm mov al,ah
_asm out dx,al
_asm mov dx,0x0a
_asm mov ax,wSBDMA
_asm out dx,al
if (ssMode==ssOut)
  WriteDSP(0x90);
else
  WriteDSP(0x98);
//nCurPos=882;
nCurPos=0;
bWaitSnd=0;
}

int prev=0;

void StopSound()
{
_asm push ax
_asm push bx
_asm push cx
_asm push dx
_asm push si
_asm push di
if (!bStarted || !bSBPresent)
 goto l1;
bStarted=0;
bSBPresent=0;
_asm mov al,4
_asm or ax,wSBDMA
_asm mov dx,0x0a
_asm out dx,al
//WriteDSP(0xD3);
ResetDSP();
FreeDMABuf();
prev=0;
l1:
_asm pop di
_asm pop si
_asm pop dx
_asm pop cx
_asm pop bx
_asm pop ax
}

void WaitSound()
{
bWaitSnd=0;
if (!bSBPresent)
  return;

// Попытка устранить зависание...
 _asm mov dx,wSBPort
 _asm add dx,0eh
 _asm in al,dx


_asm out 0ch,al
_asm mov dx,wDMACounter

_asm cmp prev,0
_asm jz l5

l4:
//_asm mov cx,50000
//llll:
//_asm loop llll

_asm in al,dx
_asm mov ah,al
_asm in al,dx
_asm xchg al,ah
_asm cmp ax,882
_asm jae l4
_asm in al,dx
_asm mov ah,al
_asm in al,dx
_asm xchg al,ah
_asm cmp ax,882
_asm jae l4
_asm mov prev,0
_asm jmp l6

l5:
_asm in al,dx
_asm mov ah,al
_asm in al,dx
_asm xchg al,ah
_asm cmp ax,882
_asm jb l5
_asm mov prev,1

l6:
 _asm mov dx,wSBPort
 _asm add dx,0eh
 _asm in al,dx
//  _asm out 0ch,al
}


/*void PlayByte(unsigned char b)
{
((char *)pDMABuf)[nCurPos]=b+128;
nCurPos=(nCurPos+1)%1764;
if ((nCurPos==0) || (nCurPos==882))
  WaitSound();
}*/

void PlayByteNoWait(unsigned char b)
{
if (!bStarted)
  StartSound(ssOut);
((char *)pDMABuf)[nCurPos]=b+64;
nCurPos=(nCurPos+1)%1764;
if ((nCurPos==0) || (nCurPos==882))
  bWaitSnd=1;
}

unsigned char ReadByteNoWait()
{
if (!bStarted)
  StartSound(ssIn);
unsigned char res=((char *)pDMABuf)[nCurPos]>0?1:0;
nCurPos=(nCurPos+1)%1764;
if ((nCurPos==0) || (nCurPos==882))
  bWaitSnd=1;
return res;
}
