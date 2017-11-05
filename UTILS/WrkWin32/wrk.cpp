/*
 *  WrkWin32
 *  Copyright (C) 1998-2013 Viktor Pykhonin <pyk@mail.ru>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// wrk.cpp

#include <stdio.h>
#include <conio.h>
#include <io.h>
#include <iostream.h>
#include "snd.h"

int speed;
long startcount=0;

#define BUFSIZE 32768

char pcBuf[BUFSIZE];
long nCurPos;

void WriteBuf()
{
if (nCurPos==0)
  return;
PlayBlock(pcBuf,nCurPos);
nCurPos=0;
cout << "*";
}

void writeval(int val)
{
int n=speed;
while (n>0)
  {
  pcBuf[nCurPos++]=val;
  n--;
  if (nCurPos==BUFSIZE)
    WriteBuf();
  }
}

void writebit(int bit)
{
if (bit)
  {
  writeval(0xef);
  writeval(0x10);
  }
else
  {
  writeval(0x10);
  writeval(0xef);
  }
}

void writebyte(unsigned char byte)
{
int i;
for(i=0;i<8;i++)
  {
  writebit(byte & 0x80);
  byte=byte<<1;
  }
}

unsigned int i;
unsigned char *p;
unsigned int fs;

void writefile()
{
unsigned char *pp;
i=0;
nCurPos=0;

pp=p;
if (*p==0xe6)
  {
  if ((fs>=5) && ((*(long *)p)==0xe6e6e6e6L))
    if (*(p+4)!=0xe6)
      goto l1;
  cout << "\n��ଠ� � ᨭ�஡��⮬ ...\n";
  pp=p+1;
  fs--;
  }
l1:
cout << "������ 䠩�� : ";
if (fs<4 || *(long *)pp!=0xe6e6e6e6L)
  for (i=0;i<=255;i++)
    writebyte(0);
else
  {
  for (i=0;i<=63;i++)
    writebyte(0x55);
  for (i=0;i<=63;i++)
    writebyte(0);
  for (i=0;i<=63;i++)
    writebyte(0x55);
  for (i=0;i<=63;i++)
    writebyte(0);
  }
writebyte(0xe6);
for (i=0;i<fs;i++)
  writebyte(pp[i]);
WriteBuf();
WaitForEndPlaying();
}

int main(int argn, char **argc)
{
cout << "\nWriteRKWin v.1.10 - �⨫�� ����� 䠩��� � �ଠ� �� � ��.\n";
cout << "����: �.��宭�� - �.�����த, 1998 �.\n\n";
cout << "�ᯮ�짮�����: wrkwin32 <���_䠩��>\n\n";

if (argn!=2)
  {
  cout << "�訡�� � ��ࠬ����\n";
  return 1;
  }

FILE *f=fopen(argc[1],"rb");
if (!f)
  {
  cout << "�� ���� ������ 䠩� " << argc[1] << "\n";
  return 1;
  }

fs=filelength(fileno(f));

p=new unsigned char [fs];
if (!p)
  {
  cout << "�訡�� �뤥����� �����\n";
  return 1;
  }
if (fread(p,1,fs,f)!=fs)
  {
  cout << "�訡�� �⥭�� �室���� 䠩��\n";
  return 1;
  }
fclose(f);

if (!FindOutputDevice())
  {
  cout << "�� ������� ���ன�⢮ ��㪮���� �뢮�� !\n";
  return 1;
  }
if (!OpenOutputDevice(1,44100,8))
  {
  cout << "�� ���� ������ ���ன�⢮ �뢮�� !\n";
  return 1;
  }
cout << "����⠭� ����� (���.=20) : ";
cin >> speed;
cout << "\n������ ������䮭 � ������ �� ���� ������� (ESC-��室).\n";
if (getch()==27)
  {
  delete[] p;
  CloseOutputDevice();
  return 0;
  }
writefile();
CloseOutputDevice();
delete[] p;
cout << "\nOk! ���� ����ᠭ.\n";
return 0;
}


