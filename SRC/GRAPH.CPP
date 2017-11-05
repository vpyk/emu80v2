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

#include <string.h>

#include "emu80.h"
#include "graph.h"

static void DrawHLine(int x1, int x2, int y);
static void DrawVLine(int x, int y1, int y2);
static void DrawStr(int x, int y, char *s);
static void DrawFrame();
static unsigned GetChar();

void DrawHLine(int x1, int x2, int y)
{
char far *p=(char far *)0xb8000000+y*160+x1*2;
for (int i=0;i<=x2-x1;i++,p+=2)
  *p='Í';
}

void DrawHLine1(int x1, int x2, int y)
{
char far *p=(char far *)0xb8000000+y*160+x1*2;
for (int i=0;i<=x2-x1;i++,p+=2)
  *p='Ä';
}

void DrawVLine(int x, int y1, int y2)
{
char far *p=(char far *)0xb8000000+y1*160+x*2;
for (int i=0;i<=y2-y1;i++,p+=160)
  *p='º';
}

void DrawStr(int x, int y, char *s)
{
char far *p=(char far *)0xb8000000+y*160+x*2;
while (*s)
  {
  *p=*(s++);
  p+=2;
  }
}

void DrawStrCol(int x, int y, char *s, char col)
{
char far *p=(char far *)0xb8000000+y*160+x*2;
while (*s)
  {
  *p=*(s++);
  *(p+1)=col;
  p+=2;
  }
}

void HighlightRect(int x1, int x2, int y1, int y2, int color)
{
int i,j;
char far *p=(char far *)0xb8000000+y1*160+x1*2+1;
for (i=0;i<=y2-y1;i++,p+=(160+x1+x1-x2-x2-2))
  for (j=0;j<=x2-x1;j++,p+=2)
    *p=color;
}

void FillRect(int x1, int x2, int y1, int y2, int ch)
{
int i,j;
char far *p=(char far *)0xb8000000+y1*160+x1*2;
for (i=0;i<=y2-y1;i++,p+=(160+x1+x1-x2-x2-2))
  for (j=0;j<=x2-x1;j++,p+=2)
    *p=ch;
}

static unsigned segScr;

void BeginDialog()
{
segScr=save_scr();
}

void EndDialog()
{
_AX=segScr;
rest_scr();
}

unsigned GetChar()
{
_asm mov ah,0
_asm int 16h
}

void DrawFrame(int x, int y, int w, int h, char *szHint, char *szHeader)
{
FillRect(x,x+w-1,y,y+h-1,0);
DrawHLine(x+1,x+w-2,y);
DrawHLine(x+1,x+w-2,y+h-1);
DrawVLine(x,y+1,y+h-2);
DrawVLine(x+w-1,y+1,y+h-2);
DrawHLine1(x+1,x+w-2,y+h-3);
DrawStr(x,y,"É");
DrawStr(x,y+h-1,"È");
DrawStr(x+w-1,y,"»");
DrawStr(x+w-1,y+h-1,"¼");
DrawStr(x,y+h-3,"Ç");
DrawStr(x+w-1,y+h-3,"¶");
HighlightRect(x,x+w-1,y,y+h-1,0x1e);
HighlightRect(x+1,x+w-2,y+1,y+h-4,0x1b);
DrawStrCol(x+(w-strlen(szHint))/2,y+h-2,szHint,0x1a);
DrawStrCol(x+(w-strlen(szHeader))/2,y,szHeader,0x1a);
}

int ShowMessage(char **ppcMes, int nLines,
                char *szHeader, int bChoice, int nCurChoice)
{
int res;
BeginDialog();
int nWidth=0;
int nLen;
int i;
for (i=0;i<nLines;i++)
  {
  nLen=strlen(ppcMes[i]);
  if (nLen>nWidth)
    nWidth=nLen;
  }
nWidth+=4;
int nHeight=nLines+4;
int xLeft=(80-nWidth)/2;
int yTop=(25-nHeight)/2;
DrawFrame(xLeft, yTop, nWidth, nHeight,
          bChoice?" Enter-¢ë¡®à  ESC-®â¬. ":" ESC - ¢®§¢à â ",
          szHeader);
for (i=0;i<nLines;i++)
  DrawStr(xLeft+2,yTop+1+i,ppcMes[i]);
if (bChoice)
  {
  int nPrevChoice=0;
  int key;
  res=-1;
  for(;;)
    {
    HighlightRect(xLeft+2,xLeft+nWidth-3,
                  yTop+1+nPrevChoice,yTop+1+nPrevChoice,0x1b);
    HighlightRect(xLeft+2,xLeft+nWidth-3,
                  yTop+1+nCurChoice,yTop+1+nCurChoice,0x3e);
    nPrevChoice=nCurChoice;
    key=GetChar();
    if ((key & 0xff)==0x0d)
      {
      res=nCurChoice;
      break;
      }
    else if ((key & 0xff)==0x1b)
      break;
    switch (key)
      {
      case 0x4800:
        nCurChoice=(nCurChoice+nLines-1)%nLines;
        break;
      case 0x5000:
        nCurChoice=(nCurChoice+1)%nLines;
      }
    }
  }
else
  res=GetChar();
EndDialog();
return res;
}

