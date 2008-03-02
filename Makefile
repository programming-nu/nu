#
# This Makefile is used to bootstrap Nu.
# Use it to build "mininush", a simpler and statically-linked
# version of nush, the Nu shell.
#

PREFIX?=/usr/local

ifeq ($(shell test -e /usr/lib/libffi.dylib && echo yes), yes)
	# Use the libffi that ships with OS X.
	FFI_LIB=-L/usr/lib -lffi
	FFI_INCLUDE=-I /usr/include/ffi
else
	# Use the libffi that is distributed with Nu.
	FFI_LIB=-L./libffi -lffi
	FFI_INCLUDE=-I ./libffi/include
endif

ifeq ($(shell test -e $(PREFIX)/lib/libpcre.dylib && echo yes), yes)
	# Use already-installed PCRE.
	PCRE_LIB=-L$(PREFIX)/lib -lpcre
	PCRE_INCLUDE=-I $(PREFIX)/include
else
	# Use PCRE in the Nu directory.
	PCRE_LIB=-Lpcre-7.5/.libs -lpcre
	PCRE_INCLUDE=-I pcre-7.5
endif

INCLUDES=$(FFI_INCLUDE) $(PCRE_INCLUDE)
LIBS=-lobjc -lreadline $(PCRE_LIB) $(FFI_LIB)
CFLAGS=-g -O2 -Wall -DMACOSX -DMININUSH -std=gnu99 -DLEOPARD_OBJC2
MFLAGS=-fobjc-exceptions
LDFLAGS=-framework Cocoa $(LIBS)

# FIXME add PREFIX/lib and PREFIX/include if they exist

OBJS=$(patsubst %.m,%.o, $(wildcard objc/*.m)) $(patsubst %.c,%.o, $(wildcard objc/*.c))

all: mininush

.m.o:
	gcc $(CFLAGS) $(MFLAGS) $(INCLUDES) -c $< -o $@

.c.o:
	gcc $(CFLAGS) $(INCLUDES) -c $< -o $@

mininush: $(OBJS)
	gcc $(OBJS) $(CFLAGS) -o $@ $(LDFLAGS)
	install_name_tool -change /usr/local/lib/libpcre.0.dylib pcre-7.5/.libs/libpcre.0.dylib $@

.PHONY: clean
clean:
	rm -f objc/*.o mininush

