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

#include <mem.h>
 #include <stdio.h>

#include "symgen.h"
#include "emu80.h"
#include "rss.h"

void DrawScr()
{
int i,j,k;

unsigned char linebuf[1280];

memset(linebuf,0,1280);

////////////////////////////////////////////////
unsigned start=dma_begadr;
int lines,cols,height,u_line,curs_x,curs_y;
if (cModel==MODEL_M80 || cModel==MODEL_U)
  {
  lines=32;
  cols=64;
  height=8;
  curs_x=-1;
  curs_y=-1;
  }
else
  {
  lines=(crt_param_2&0x3f)+1;
  cols=(crt_param_1&0x7f)+1;
  height=(crt_param_3&0xf)+1;
  curs_x=cur_x;
  if (cModel==MODEL_P)
    curs_x--;
  curs_y=cur_y;
  if (cols>80)
    cols=80;
  u_line=((crt_param_3&0xf0)>>4);
  }
////////////////////////////////////////////////

static int old_vidofs=0;
static int old_full_height=0;

unsigned char far *vid=(unsigned char far*)0xa0000000;

int height_ofs=height>8?1:0;

int vidofs=14010-(lines*height*40);
if (vidofs<0) vidofs=10;

if (vidofs!=old_vidofs || old_full_height!=height*lines)
  {
  for (long l=0;l<38400;l++)
    vid[l]=0;
  }
old_vidofs=vidofs;
old_full_height=height*lines;

int h=height<=8?height:9;
static int blick_cnt=0;

unsigned char and_mask;
unsigned char xor_mask;
unsigned char outbyte;
unsigned long bufval;

unsigned char line_vsp;
unsigned char scr_vsp;

unsigned char *lp,*tlp;
unsigned char far *vp, far *tvp, far *mp;

// формируем экран
unsigned char bt;
unsigned short ofs=0;
int neg=0;
int blink=0;
int und=0;
scr_vsp=0xff;
if (cModel!=MODEL_P)
  ofs=128*3;
if (cModel==MODEL_A)
  ofs=int_flag?128*9:128*8;
else if (cModel==MODEL_M)
  ofs=mikr_symg?128*10:128*11;
vp=vid+vidofs;
mp=(unsigned char far *)(mempage0+start);
for (i=0;i<lines;i++)
  {
  line_vsp=0xff;
  if (cModel!=MODEL_M80 && cModel!=MODEL_U)
    for (j=0;j<cols;j++)
      {
  //    bt=mem[start+i*cols+j];
      bt=*mp++;
      if (bt<0x80)
        {
        and_mask=(blink && (blick_cnt<16))?0:0x3f;
        xor_mask=neg?0x3f:0;
        for (k=0;k<h;k++)
          {
  //        outbyte=sym_gen[(ofs+bt)*8+k];
  
          if (height_ofs)
            {
            if (k)
              outbyte=sym_gen[(ofs+bt)*8+k-1];
            else
              outbyte=0;
            }
          else
            outbyte=sym_gen[(ofs+bt)*8+k];
  
          if ((k==u_line) && und)
            outbyte=0x3f;
          if ((k==u_line) && (curs_x==j) && (curs_y==i) && (blick_cnt&8))
            outbyte^=0x3f;
          outbyte=outbyte&and_mask^xor_mask;
          outbyte&=scr_vsp;
          outbyte&=line_vsp;
          linebuf[j+k*80]=outbyte;
          }
        for (k=h;k<height;k++)
          {
          outbyte=0;
          if ((k==u_line) && und)
            outbyte=0x3f;
          if ((k==u_line) && (curs_x==j) && (curs_y==i) && (blick_cnt&8))
            outbyte=0x3f;
          outbyte=outbyte^xor_mask;
          linebuf[j+k*80]=outbyte;
          }
        }
      else if (bt<0xc0)
        {
        if (cModel==MODEL_P)
          {
          ofs=(((bt&4)>>2)|((bt&8)>>2)|((bt&1)<<2))*128;
          neg=bt&0x10;
          blink=bt&0x2;
          und=bt&0x20;
          }
        else if (cModel==MODEL_A || cModel==MODEL_R)
          {
          neg=bt&0x10;
          blink=bt&0x2;
  //        und=bt&0x20;
          }
        else if (cModel==MODEL_M)
          {
          blink=bt&0x2;
          }
  //      else if (cModel==MODEL_U)
  //        {
  //        neg=bt&0x80;
  //        }
        for (k=0;k<height;k++)
          {
          if (neg || ((k==u_line) && (curs_x==j) && (curs_y==i) && (blick_cnt&8)))
            linebuf[j+k*80]=0x3f;
          else
            linebuf[j+k*80]=0;
          }
        }
      else if (bt>=0xf0)
        {
        scr_vsp=bt&2?0:0xff;
        line_vsp=~scr_vsp;
        }  
      else
        { // Псевдографический код - заменяем на полосатый прямоугольник ;)
        for (k=0;k<h;k+=2)
          {
          ;
          outbyte=scr_vsp&line_vsp&((bt&2 && (blick_cnt<16))?0:0x3f);
          linebuf[j+k*80]=outbyte;
          linebuf[j+k*80+80]=0;
          }
        }
      }
  else  // Микро-80 или ЮТ-88
    for (j=0;j<cols;j++)
      {
      bt=*mp++;
        for (k=0;k<8;k++)
          {
          outbyte=sym_gen[(384+(bt&0x7f))*8+k];
          if (cModel==MODEL_U && (bt&0x80))
            outbyte^=0x3f;
          else if (cModel==MODEL_M80 && *(mp-0x801))
            outbyte^=0x3f;
          linebuf[j+k*80]=outbyte;
          }
      }

  lp=linebuf;
  for (k=0;k<height;k++)
    {
    tvp=vp;
    tlp=lp;
//    if (k<h)
//      for (j=0;j<cols;j++)
//        *(vp++)=*(lp++);
      for (j=0;j<20;j++)
        {
        bufval=(*lp++)<<6;
        bufval=(bufval|(*lp++))<<6;
        bufval=(bufval|(*lp++))<<6;
        bufval=bufval|(*lp++);
        bufval=(bufval&0xff00)|((bufval&0xff)<<16)|((bufval&0xff0000)>>16);
//        *(unsigned long far *)vp=bufval;
        *((unsigned short far *)vp)++=bufval;
        bufval>>=16;
        *((unsigned char far *)vp)++=bufval;
//        vp+=3;
        }
//    else
//    if (k<h)
//      for (j=0;j<cols;j++)
//        *(vp++)=0;
    vp=tvp+80;
    lp=tlp+80;
    }
  }

blick_cnt++;
blick_cnt%=32;
////////////////////////////////////////////////
}
