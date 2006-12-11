DIRSEPSTR=/
O=.obj
E=.exe
CC=cc
CFLAGS=-g
LDFLAGS=-g
YFLAGS=
FILES=COPYRIGHT README LOG iburg.h iburg.c gram.y gram.c iburg.1 makefile

all:		iburg$E

gram.c:		gram.y;		byacc $(YFLAGS) -o $@ $^

iburg.zip:	$(FILES)
		zip $@ $^ *.ps sample*.brg
		d=`pwd`; cd //atr/users/drh/pkg/iburg; zip $$d/$@ RCS/*.[chy1],v RCS/sample*
		d=`pwd`; cd /temp; zip $$d/$@ custom.mk

clobber::	clean
		rm -r y.tab.c gram.c iburg.zip *.ilk *.pdb
