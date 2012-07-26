#
# This Makefile is used to bootstrap Nu.
# Use it to build "mininush", a simpler and statically-linked
# version of nush, the Nu shell.
#

SYSTEM = $(shell uname)

PREFIX ?= /usr/local

# TOOLCHAIN = /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain
# SDKROOT   = /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer

ifeq ($(shell test -e /usr/lib/libffi.dylib && echo yes), yes)
	# Use the libffi that ships with OS X.
	FFI_LIB = -L/usr/lib -lffi
	FFI_INCLUDE = -I/usr/include/ffi
else
	# Use the libffi that is distributed with Nu.
	FFI_LIB = -L./libffi -lffi
	FFI_INCLUDE = -I./libffi/include
endif

ifeq ($(shell test -e $(SDKROOT)/SDKs/MacOSX10.7.sdk && echo yes), yes)
        LION_CFLAGS = -isysroot $(SDKROOT)/SDKs/MacOSX10.7.sdk
else
        LION_CFLAGS =
endif

INCLUDES = $(FFI_INCLUDE) -I./include

ifeq ($(shell test -d $(PREFIX)/include && echo yes), yes)
	INCLUDES += -I$(PREFIX)/include
endif
FRAMEWORKS = -framework Cocoa
LIBS = -lobjc -lreadline
ifeq ($(shell test -d $(PREFIX)/lib && echo yes), yes)
	LIBDIRS += -L$(PREFIX)/lib
endif

C_FILES = $(wildcard objc/*.c) 
OBJC_FILES = $(wildcard objc/*.m) $(wildcard main/*.m)
GCC_FILES = $(OBJC_FILES) $(C_FILES)
GCC_OBJS = $(patsubst %.m, %.o, $(OBJC_FILES)) $(patsubst %.c, %.o, $(C_FILES))

CC = gcc
CFLAGS = -g -Wall -DMININUSH 
MFLAGS = -fobjc-exceptions

ifeq ($(SYSTEM), Darwin)
	# as of around 10.7.3, clang becomes part of OS X
	CC = /usr/bin/clang
	ifneq ($(shell test -e $(CC) && echo yes), yes)
		CC = $(TOOLCHAIN)/usr/bin/clang
	endif
	CFLAGS += -DMACOSX -DDARWIN $(LION_CFLAGS)  
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
	rm -f objc/*.o main/*.o 

.PHONY: clobber
clobber: clean
	rm -f mininush

