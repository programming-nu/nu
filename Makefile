#
# This Makefile is used to bootstrap Nu.
# Use it to build "mininush", a simpler and statically-linked
# version of nush, the Nu shell.
#

SYSTEM = $(shell uname)

PREFIX ?= /usr/local

ifeq ($(SYSTEM), Darwin)
	ifeq ($(shell test -e /usr/lib/libffi.dylib && echo yes), yes)
		# Use the libffi that ships with OS X.
		FFI_LIB = -L/usr/lib -lffi
		FFI_INCLUDE = -I/usr/include/ffi
		LEOPARD_CFLAGS = -DLEOPARD_OBJC2 
	else
		# Use the libffi that is distributed with Nu.
		FFI_LIB = -L./libffi -lffi
		FFI_INCLUDE = -I./libffi/include
		LEOPARD_CFLAGS =
	endif

	ifeq ($(shell test -e /Developer/SDKs/MacOSX10.7.sdk && echo yes), yes)
		# not a typo, we deliberatly stay back on the 10.6 SDK for now.
                LION_CFLAGS = -DLION -isysroot /Developer/SDKs/MacOSX10.6.sdk
        else
                LION_CFLAGS =
        endif

else # GNUstep
	FFI_LIB=-lffi
	FFI_INCLUDE=
endif

INCLUDES = $(FFI_INCLUDE) -I./include

ifeq ($(SYSTEM), Darwin)
	ifeq ($(shell test -d $(PREFIX)/include && echo yes), yes)
		INCLUDES += -I$(PREFIX)/include
	endif
	FRAMEWORKS = -framework Cocoa
	LIBS = -lobjc -lreadline
	ifeq ($(shell test -d $(PREFIX)/lib && echo yes), yes)
		LIBDIRS += -L$(PREFIX)/lib
	endif
else
	FRAMEWORKS =
	LIBS = -lm -lpcre -lreadline -lgnustep-base
	LIBDIRS =
endif

C_FILES = $(wildcard objc/*.c) $(wildcard pcre/*.c)
OBJC_FILES = $(wildcard objc/*.m) $(wildcard main/*.m)
GCC_FILES = $(OBJC_FILES) $(C_FILES)
GCC_OBJS = $(patsubst %.m, %.o, $(OBJC_FILES)) $(patsubst %.c, %.o, $(C_FILES))

CC = gcc
CFLAGS = -g -Wall -DMININUSH -std=gnu99 
MFLAGS = -fobjc-exceptions

# required to compile bundled PCRE source
CFLAGS += -DHAVE_CONFIG_H

ifeq ($(SYSTEM), Darwin)
	#CC = /Developer/usr/bin/llvm-gcc-4.2 
	CFLAGS += -DMACOSX -DDARWIN $(LEOPARD_CFLAGS) $(LION_CFLAGS) -Ipcre 
else
#	CFLAGS += -DLINUX
#	MFLAGS += -fconstant-string-class=NSConstantString
	MFLAGS += $(shell gnustep-config --objc-flags)
endif

ifeq ($(SYSTEM), Linux)
	CFLAGS += -DLINUX
endif

ifeq ($(SYSTEM), FreeBSD)
	CFLAGS += -DFREEBSD 
endif

# OpenSolaris "uname" kernel is "SunOS"
ifeq ($(SYSTEM), SunOS)
	CFLAGS += -DOPENSOLARIS
	LIBS += -lcurses
endif

LDFLAGS += $(FRAMEWORKS)
LDFLAGS += $(LIBS)
LDFLAGS += $(LIBDIRS)
LDFLAGS += $(FFI_LIB)
ifeq ($(SYSTEM), Darwin)
else
	LDFLAGS += $(shell gnustep-config --base-libs)
	LDFLAGS += -lobjc 
ifneq ($(SYSTEM), SunOS)
	LDFLAGS += -Wl,--rpath -Wl,/usr/local/lib
endif
endif

all: mininush

%.o: %.m
	$(CC) $(CFLAGS) $(MFLAGS) $(INCLUDES) -c $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.PHONY: mininush
mininush: $(GCC_OBJS)
	$(CC) $(GCC_OBJS) $(CFLAGS) -o mininush $(LDFLAGS)

.PHONY: clean
clean:
	rm -f objc/*.o main/*.o pcre/*.o

.PHONY: clobber
clobber: clean
	rm -f mininush

