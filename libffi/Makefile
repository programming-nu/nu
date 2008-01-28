# Makefile for building libFFI for Nu

ARCH=-arch i386 -arch ppc
CFLAGS=-g -O3 -Wall -DMACOSX -Iinclude

OBJS=src/types.o src/prep_cif.o src/x86/ffi_darwin.o src/x86/darwin.o \
src/powerpc/ffi_darwin.o src/powerpc/darwin.o src/powerpc/darwin_closure.o

all: libffi.a

.S.o:
	gcc $(CFLAGS) $(ARCH) $(INCLUDES) -c $< -o $@

.c.o:
	gcc $(CFLAGS) $(ARCH) $(INCLUDES) -c $< -o $@

libffi.a: $(OBJS)
	libtool -static -o $@ $(OBJS)
	ranlib $@

.PHONY: clean
clean:
	find . -name "*.o" | xargs rm
	rm -f libffi.a

