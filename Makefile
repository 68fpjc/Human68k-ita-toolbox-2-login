# Makefile for ITA TOOLBOX #2 LOGIN

MAKE = make

AS = HAS060
ASFLAGS = -m 68000 -i $(INCLUDE)
LD = hlk
LDFLAGS = -x
CV = -CV -r
CP = cp
RM = -rm -f

INCLUDE = ../01-fish/include

DESTDIR   = A:/bin
BACKUPDIR = B:/login/0.6
RELEASE_ARCHIVE = LOGIN06
RELEASE_FILES = MANIFEST README ../NOTICE CHANGES login.1 login.x forever.1 forever.x passwd.5

EXTLIB = ../01-fish/lib/ita.l

###

PROGRAM = login.x forever.x

###

.PHONY : all clean clobber install release backup

.TERMINAL : *.h *.s

%.r : %.x
	$(CV) $<

%.x : %.o $(EXTLIB)
	$(LD) $(LDFLAGS) $^

%.o : %.s
	$(AS) $(ASFLAGS) $<

###

all:: $(PROGRAM)

clean::

clobber:: clean
	$(RM) *.bak *.$$* *.o *.x

###

$(PROGRAM:.x=.o) : $(INCLUDE)/doscall.h $(INCLUDE)/chrcode.h

$(EXTLIB)::
	cd $(@D); $(MAKE) $(@F)

include ../Makefile.sub

###
