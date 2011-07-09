/* -----------------------------------------------------------------------
   types.c - Copyright (c) 1996, 1998  Red Hat, Inc.
   
   Predefined ffi_types needed by libffi.

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   ``Software''), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
   ----------------------------------------------------------------------- */

/* Hide the basic type definitions from the header file, so that we
   can redefine them here as "const".  */
#define LIBFFI_HIDE_BASIC_TYPES

#include "ffi.h"
#include <stdlib.h>
#include <TargetConditionals.h>

/* -----------------------------------------------------------------------
 ffi_common.h - Copyright (c) 1996  Red Hat, Inc.
 Copyright (C) 2007 Free Software Foundation, Inc
 
 Common internal definitions and macros. Only necessary for building
 libffi.
 ----------------------------------------------------------------------- */

#ifdef __cplusplus
extern "C" {
#endif
            
void bcopy(const void *s1, void *s2, size_t n);
#define memcpy(d, s, n) bcopy ((s), (d), (n))

#if defined(FFI_DEBUG)
#include <stdio.h>
#endif
    
#ifdef FFI_DEBUG
    void ffi_assert(char *expr, char *file, int line);
    void ffi_stop_here(void);
    void ffi_type_test(ffi_type *a, char *file, int line);
    
#define FFI_ASSERT(x) ((x) ? (void)0 : ffi_assert(#x, __FILE__,__LINE__))
#define FFI_ASSERT_AT(x, f, l) ((x) ? 0 : ffi_assert(#x, (f), (l)))
#define FFI_ASSERT_VALID_TYPE(x) ffi_type_test (x, __FILE__, __LINE__)
#else
#define FFI_ASSERT(x)
#define FFI_ASSERT_AT(x, f, l)
#define FFI_ASSERT_VALID_TYPE(x)
#endif
    
#define ALIGN(v, a)  (((((size_t) (v))-1) | ((a)-1))+1)
#define ALIGN_DOWN(v, a) (((size_t) (v)) & -a)
    
    /* Perform machine dependent cif processing */
    ffi_status ffi_prep_cif_machdep(ffi_cif *cif);
    
    /* Extended cif, used in callback from assembly routine */
    typedef struct
    {
        ffi_cif *cif;
        void *rvalue;
        void **avalue;
    } extended_cif;
    
    /* Terse sized type definitions.  */
    typedef unsigned int UINT8  __attribute__((__mode__(__QI__)));
    typedef signed int   SINT8  __attribute__((__mode__(__QI__)));
    typedef unsigned int UINT16 __attribute__((__mode__(__HI__)));
    typedef signed int   SINT16 __attribute__((__mode__(__HI__)));
    typedef unsigned int UINT32 __attribute__((__mode__(__SI__)));
    typedef signed int   SINT32 __attribute__((__mode__(__SI__)));
    typedef unsigned int UINT64 __attribute__((__mode__(__DI__)));
    typedef signed int   SINT64 __attribute__((__mode__(__DI__)));
    
    typedef float FLOAT32;
    
    void ffi_prep_args(char *stack, extended_cif *ecif);
    
#ifdef __cplusplus
}
#endif

/* Type definitions */

#define FFI_TYPEDEF(name, type, id)		\
struct struct_align_##name {			\
  char c;					\
  type x;					\
};						\
const ffi_type ffi_type_##name = {		\
  sizeof(type),					\
  offsetof(struct struct_align_##name, x),	\
  id, NULL					\
}

/* Size and alignment are fake here. They must not be 0. */
const ffi_type ffi_type_void = {
  1, 1, FFI_TYPE_VOID, NULL
};

FFI_TYPEDEF(uint8, UINT8, FFI_TYPE_UINT8);
FFI_TYPEDEF(sint8, SINT8, FFI_TYPE_SINT8);
FFI_TYPEDEF(uint16, UINT16, FFI_TYPE_UINT16);
FFI_TYPEDEF(sint16, SINT16, FFI_TYPE_SINT16);
FFI_TYPEDEF(uint32, UINT32, FFI_TYPE_UINT32);
FFI_TYPEDEF(sint32, SINT32, FFI_TYPE_SINT32);
FFI_TYPEDEF(uint64, UINT64, FFI_TYPE_UINT64);
FFI_TYPEDEF(sint64, SINT64, FFI_TYPE_SINT64);
FFI_TYPEDEF(pointer, void*, FFI_TYPE_POINTER);
FFI_TYPEDEF(float, float, FFI_TYPE_FLOAT);
FFI_TYPEDEF(double, double, FFI_TYPE_DOUBLE);

/* -----------------------------------------------------------------------
   raw_api.c - Copyright (c) 1999, 2008  Red Hat, Inc.

   Author: Kresten Krab Thorup <krab@gnu.org>

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   ``Software''), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
   ----------------------------------------------------------------------- */

/* This file defines generic functions for use with the raw api. */

#include <alloca.h>

size_t
ffi_raw_size (ffi_cif *cif)
{
  size_t result = 0;
  int i;

  ffi_type **at = cif->arg_types;

  for (i = cif->nargs-1; i >= 0; i--, at++)
    {
      if ((*at)->type == FFI_TYPE_STRUCT)
	result += ALIGN (sizeof (void*), FFI_SIZEOF_ARG);
      else
	result += ALIGN ((*at)->size, FFI_SIZEOF_ARG);
    }

  return result;
}


void
ffi_raw_to_ptrarray (ffi_cif *cif, ffi_raw *raw, void **args)
{
  unsigned i;
  ffi_type **tp = cif->arg_types;

  /* assume little endian */
  for (i = 0; i < cif->nargs; i++, tp++, args++)
    {	  
      if ((*tp)->type == FFI_TYPE_STRUCT)
	{
	  *args = (raw++)->ptr;
	}
      else
	{
	  *args = (void*) raw;
	  raw += ALIGN ((*tp)->size, sizeof (void*)) / sizeof (void*);
	}
    }
}

void
ffi_ptrarray_to_raw (ffi_cif *cif, void **args, ffi_raw *raw)
{
  unsigned i;
  ffi_type **tp = cif->arg_types;

  for (i = 0; i < cif->nargs; i++, tp++, args++)
    {	  
      switch ((*tp)->type)
	{
	case FFI_TYPE_UINT8:
	  (raw++)->uint = *(UINT8*) (*args);
	  break;

	case FFI_TYPE_SINT8:
	  (raw++)->sint = *(SINT8*) (*args);
	  break;

	case FFI_TYPE_UINT16:
	  (raw++)->uint = *(UINT16*) (*args);
	  break;

	case FFI_TYPE_SINT16:
	  (raw++)->sint = *(SINT16*) (*args);
	  break;

#if FFI_SIZEOF_ARG >= 4
	case FFI_TYPE_UINT32:
	  (raw++)->uint = *(UINT32*) (*args);
	  break;

	case FFI_TYPE_SINT32:
	  (raw++)->sint = *(SINT32*) (*args);
	  break;
#endif

	case FFI_TYPE_STRUCT:
	  (raw++)->ptr = *args;
	  break;

	case FFI_TYPE_POINTER:
	  (raw++)->ptr = **(void***) args;
	  break;

	default:
	  memcpy ((void*) raw->data, (void*)*args, (*tp)->size);
	  raw += ALIGN ((*tp)->size, FFI_SIZEOF_ARG) / FFI_SIZEOF_ARG;
	}
    }
}

#if !FFI_NATIVE_RAW_API


/* This is a generic definition of ffi_raw_call, to be used if the
 * native system does not provide a machine-specific implementation.
 * Having this, allows code to be written for the raw API, without
 * the need for system-specific code to handle input in that format;
 * these following couple of functions will handle the translation forth
 * and back automatically. */

void ffi_raw_call (ffi_cif *cif, void (*fn)(void), void *rvalue, ffi_raw *raw)
{
  void **avalue = (void**) alloca (cif->nargs * sizeof (void*));
  ffi_raw_to_ptrarray (cif, raw, avalue);
  ffi_call (cif, fn, rvalue, avalue);
}

#if FFI_CLOSURES		/* base system provides closures */

static void
ffi_translate_args (ffi_cif *cif, void *rvalue,
		    void **avalue, void *user_data)
{
  ffi_raw *raw = (ffi_raw*)alloca (ffi_raw_size (cif));
  ffi_raw_closure *cl = (ffi_raw_closure*)user_data;

  ffi_ptrarray_to_raw (cif, avalue, raw);
  (*cl->fun) (cif, rvalue, raw, cl->user_data);
}

ffi_status
ffi_prep_raw_closure_loc (ffi_raw_closure* cl,
			  ffi_cif *cif,
			  void (*fun)(ffi_cif*,void*,ffi_raw*,void*),
			  void *user_data,
			  void *codeloc)
{
  ffi_status status;

  status = ffi_prep_closure_loc ((ffi_closure*) cl,
				 cif,
				 &ffi_translate_args,
				 codeloc,
				 codeloc);
  if (status == FFI_OK)
    {
      cl->fun       = fun;
      cl->user_data = user_data;
    }

  return status;
}

#endif /* FFI_CLOSURES */
#endif /* !FFI_NATIVE_RAW_API */

#if FFI_CLOSURES

/* Again, here is the generic version of ffi_prep_raw_closure, which
 * will install an intermediate "hub" for translation of arguments from
 * the pointer-array format, to the raw format */

ffi_status
ffi_prep_raw_closure (ffi_raw_closure* cl,
		      ffi_cif *cif,
		      void (*fun)(ffi_cif*,void*,ffi_raw*,void*),
		      void *user_data)
{
  return ffi_prep_raw_closure_loc (cl, cif, fun, user_data, cl);
}

#endif /* FFI_CLOSURES */

/* -----------------------------------------------------------------------
   prep_cif.c - Copyright (c) 1996, 1998, 2007  Red Hat, Inc.

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   ``Software''), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
   ----------------------------------------------------------------------- */

/* Round up to FFI_SIZEOF_ARG. */

#define STACK_ARG_SIZE(x) ALIGN(x, FFI_SIZEOF_ARG)

/* Perform machine independent initialization of aggregate type
   specifications. */

static ffi_status initialize_aggregate(ffi_type *arg)
{
  ffi_type **ptr;

  FFI_ASSERT(arg != NULL);

  FFI_ASSERT(arg->elements != NULL);
  FFI_ASSERT(arg->size == 0);
  FFI_ASSERT(arg->alignment == 0);

  ptr = &(arg->elements[0]);

  while ((*ptr) != NULL)
    {
      if (((*ptr)->size == 0) && (initialize_aggregate((*ptr)) != FFI_OK))
	return FFI_BAD_TYPEDEF;

      /* Perform a sanity check on the argument type */
      FFI_ASSERT_VALID_TYPE(*ptr);

      arg->size = ALIGN(arg->size, (*ptr)->alignment);
      arg->size += (*ptr)->size;

      arg->alignment = (arg->alignment > (*ptr)->alignment) ?
	arg->alignment : (*ptr)->alignment;

      ptr++;
    }

  /* Structure size includes tail padding.  This is important for
     structures that fit in one register on ABIs like the PowerPC64
     Linux ABI that right justify small structs in a register.
     It's also needed for nested structure layout, for example
     struct A { long a; char b; }; struct B { struct A x; char y; };
     should find y at an offset of 2*sizeof(long) and result in a
     total size of 3*sizeof(long).  */
  arg->size = ALIGN (arg->size, arg->alignment);

  if (arg->size == 0)
    return FFI_BAD_TYPEDEF;
  else
    return FFI_OK;
}

#ifndef __CRIS__
/* The CRIS ABI specifies structure elements to have byte
   alignment only, so it completely overrides this functions,
   which assumes "natural" alignment and padding.  */

/* Perform machine independent ffi_cif preparation, then call
   machine dependent routine. */

ffi_status ffi_prep_cif(ffi_cif *cif, ffi_abi abi, unsigned int nargs,
			ffi_type *rtype, ffi_type **atypes)
{
  unsigned bytes = 0;
  unsigned int i;
  ffi_type **ptr;

  FFI_ASSERT(cif != NULL);
  FFI_ASSERT((abi > FFI_FIRST_ABI) && (abi <= FFI_DEFAULT_ABI));

  cif->abi = abi;
  cif->arg_types = atypes;
  cif->nargs = nargs;
  cif->rtype = rtype;

  cif->flags = 0;

  /* Initialize the return type if necessary */
  if ((cif->rtype->size == 0) && (initialize_aggregate(cif->rtype) != FFI_OK))
    return FFI_BAD_TYPEDEF;

  /* Perform a sanity check on the return type */
  FFI_ASSERT_VALID_TYPE(cif->rtype);

  /* x86-64 stack space allocation is handled in prep_machdep.  */
#if !defined __x86_64__ 
  /* Make space for the return structure pointer */
  if (cif->rtype->type == FFI_TYPE_STRUCT
#ifdef X86_DARWIN
      && (cif->rtype->size > 8)
#endif
     )
    bytes = STACK_ARG_SIZE(sizeof(void*));
#endif

  for (ptr = cif->arg_types, i = cif->nargs; i > 0; i--, ptr++)
    {

      /* Initialize any uninitialized aggregate type definitions */
      if (((*ptr)->size == 0) && (initialize_aggregate((*ptr)) != FFI_OK))
	return FFI_BAD_TYPEDEF;

      /* Perform a sanity check on the argument type, do this
	 check after the initialization.  */
      FFI_ASSERT_VALID_TYPE(*ptr);

#if !defined __x86_64__ 
	{
	  /* Add any padding if necessary */
	  if (((*ptr)->alignment - 1) & bytes)
	    bytes = ALIGN(bytes, (*ptr)->alignment);

	  bytes += STACK_ARG_SIZE((*ptr)->size);
	}
#endif
    }

  cif->bytes = bytes;

  /* Perform machine dependent cif processing */
  return ffi_prep_cif_machdep(cif);
}
#endif /* not __CRIS__ */

#if FFI_CLOSURES

ffi_status
ffi_prep_closure (ffi_closure* closure,
		  ffi_cif* cif,
		  void (*fun)(ffi_cif*,void*,void**,void*),
		  void *user_data)
{
  return ffi_prep_closure_loc (closure, cif, fun, user_data, closure);
}

#endif

#if !TARGET_IPHONE_SIMULATOR

#ifdef __arm__
extern void __clear_cache (void *beg, void *end);
#endif 

//extern void __clear_cache (void *start, void *end) {
//    sys_icache_invalidate(start, end-start);
//}

/* -----------------------------------------------------------------------
   ffi.c - Copyright (c) 1998, 2008  Red Hat, Inc.
   
   ARM Foreign Function Interface 

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   ``Software''), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
   ----------------------------------------------------------------------- */

/* ffi_prep_args is called by the assembly routine once stack space
   has been allocated for the function's arguments */

void ffi_prep_args(char *stack, extended_cif *ecif)
{
  register unsigned int i;
  register void **p_argv;
  register char *argp;
  register ffi_type **p_arg;

  argp = stack;

  if ( ecif->cif->flags == FFI_TYPE_STRUCT ) {
    *(void **) argp = ecif->rvalue;
    argp += 4;
  }

  p_argv = ecif->avalue;

  for (i = ecif->cif->nargs, p_arg = ecif->cif->arg_types;
       (i != 0);
       i--, p_arg++)
    {
      size_t z;

      /* Align if necessary */
      if (((*p_arg)->alignment - 1) & (unsigned) argp) {
	argp = (char *) ALIGN(argp, (*p_arg)->alignment);
      }

      if ((*p_arg)->type == FFI_TYPE_STRUCT)
	argp = (char *) ALIGN(argp, 4);

	  z = (*p_arg)->size;
	  if (z < sizeof(int))
	    {
	      z = sizeof(int);
	      switch ((*p_arg)->type)
		{
		case FFI_TYPE_SINT8:
		  *(signed int *) argp = (signed int)*(SINT8 *)(* p_argv);
		  break;
		  
		case FFI_TYPE_UINT8:
		  *(unsigned int *) argp = (unsigned int)*(UINT8 *)(* p_argv);
		  break;
		  
		case FFI_TYPE_SINT16:
		  *(signed int *) argp = (signed int)*(SINT16 *)(* p_argv);
		  break;
		  
		case FFI_TYPE_UINT16:
		  *(unsigned int *) argp = (unsigned int)*(UINT16 *)(* p_argv);
		  break;
		  
		case FFI_TYPE_STRUCT:
		  memcpy(argp, *p_argv, (*p_arg)->size);
		  break;

		default:
		  FFI_ASSERT(0);
		}
	    }
	  else if (z == sizeof(int))
	    {
	      *(unsigned int *) argp = (unsigned int)*(UINT32 *)(* p_argv);
	    }
	  else
	    {
	      memcpy(argp, *p_argv, z);
	    }
	  p_argv++;
	  argp += z;
    }
  
  return;
}

/* Perform machine dependent cif processing */
ffi_status ffi_prep_cif_machdep(ffi_cif *cif)
{
  /* Round the stack up to a multiple of 8 bytes.  This isn't needed 
     everywhere, but it is on some platforms, and it doesn't harm anything
     when it isn't needed.  */
  cif->bytes = (cif->bytes + 7) & ~7;

  /* Set the return type flag */
  switch (cif->rtype->type)
    {
    case FFI_TYPE_VOID:
    case FFI_TYPE_FLOAT:
    case FFI_TYPE_DOUBLE:
      cif->flags = (unsigned) cif->rtype->type;
      break;

    case FFI_TYPE_SINT64:
    case FFI_TYPE_UINT64:
      cif->flags = (unsigned) FFI_TYPE_SINT64;
      break;

    case FFI_TYPE_STRUCT:
      if (cif->rtype->size <= 4)
	/* A Composite Type not larger than 4 bytes is returned in r0.  */
	cif->flags = (unsigned)FFI_TYPE_INT;
      else
	/* A Composite Type larger than 4 bytes, or whose size cannot
	   be determined statically ... is stored in memory at an
	   address passed [in r0].  */
	cif->flags = (unsigned)FFI_TYPE_STRUCT;
      break;

    default:
      cif->flags = FFI_TYPE_INT;
      break;
    }

  return FFI_OK;
}

extern void ffi_call_SYSV(void (*)(char *, extended_cif *), extended_cif *,
			  unsigned, unsigned, unsigned *, void (*fn)(void));

void ffi_call(ffi_cif *cif, void (*fn)(void), void *rvalue, void **avalue)
{
  extended_cif ecif;

  int small_struct = (cif->flags == FFI_TYPE_INT 
		      && cif->rtype->type == FFI_TYPE_STRUCT);

  ecif.cif = cif;
  ecif.avalue = avalue;

  unsigned int temp;
  
  /* If the return value is a struct and we don't have a return	*/
  /* value address then we need to make one		        */

  if ((rvalue == NULL) && 
      (cif->flags == FFI_TYPE_STRUCT))
    {
      ecif.rvalue = alloca(cif->rtype->size);
    }
  else if (small_struct)
    ecif.rvalue = &temp;
  else
    ecif.rvalue = rvalue;

  switch (cif->abi) 
    {
    case FFI_SYSV:
      ffi_call_SYSV(ffi_prep_args, &ecif, cif->bytes, cif->flags, ecif.rvalue,
		    fn);

      break;
    default:
      FFI_ASSERT(0);
      break;
    }
  if (small_struct)
    memcpy (rvalue, &temp, cif->rtype->size);
}

/** private members **/

static void ffi_prep_incoming_args_SYSV (char *stack, void **ret,
					 void** args, ffi_cif* cif);

void ffi_closure_SYSV (ffi_closure *);

/* This function is jumped to by the trampoline */
unsigned int FFI_HIDDEN ffi_closure_SYSV_inner (ffi_closure *, void **, void *);

unsigned int
ffi_closure_SYSV_inner (closure, respp, args)
     ffi_closure *closure;
     void **respp;
     void *args;
{
  // our various things...
  ffi_cif       *cif;
  void         **arg_area;

  cif         = closure->cif;
  arg_area    = (void**) alloca (cif->nargs * sizeof (void*));  

  /* this call will initialize ARG_AREA, such that each
   * element in that array points to the corresponding 
   * value on the stack; and if the function returns
   * a structure, it will re-set RESP to point to the
   * structure return address.  */

  ffi_prep_incoming_args_SYSV(args, respp, arg_area, cif);

  (closure->fun) (cif, *respp, arg_area, closure->user_data);

  return cif->flags;
}

/*@-exportheader@*/
static void 
ffi_prep_incoming_args_SYSV(char *stack, void **rvalue,
			    void **avalue, ffi_cif *cif)
/*@=exportheader@*/
{
  register unsigned int i;
  register void **p_argv;
  register char *argp;
  register ffi_type **p_arg;

  argp = stack;

  if ( cif->flags == FFI_TYPE_STRUCT ) {
    *rvalue = *(void **) argp;
    argp += 4;
  }

  p_argv = avalue;

  for (i = cif->nargs, p_arg = cif->arg_types; (i != 0); i--, p_arg++)
    {
      size_t z;

      size_t alignment = (*p_arg)->alignment;
      if (alignment < 4)
	alignment = 4;
      /* Align if necessary */
      if ((alignment - 1) & (unsigned) argp) {
	argp = (char *) ALIGN(argp, alignment);
      }

      z = (*p_arg)->size;

      /* because we're little endian, this is what it turns into.   */

      *p_argv = (void*) argp;

      p_argv++;
      argp += z;
    }
  
  return;
}

/* How to make a trampoline.  */

#ifdef __arm__

// __clear_cache seems to be missing on iOS5, so we omit it. Danger, Will Robinson.

#define FFI_INIT_TRAMPOLINE(TRAMP,FUN,CTX)				\
({ unsigned char *__tramp = (unsigned char*)(TRAMP);			\
   unsigned int  __fun = (unsigned int)(FUN);				\
   unsigned int  __ctx = (unsigned int)(CTX);				\
   *(unsigned int*) &__tramp[0] = 0xe92d000f; /* stmfd sp!, {r0-r3} */	\
   *(unsigned int*) &__tramp[4] = 0xe59f0000; /* ldr r0, [pc] */	\
   *(unsigned int*) &__tramp[8] = 0xe59ff000; /* ldr pc, [pc] */	\
   *(unsigned int*) &__tramp[12] = __ctx;				\
   *(unsigned int*) &__tramp[16] = __fun;				\
 })

#else

#define FFI_INIT_TRAMPOLINE(TRAMP,FUN,CTX)				\
({ unsigned char *__tramp = (unsigned char*)(TRAMP);			\
   unsigned int  __fun = (unsigned int)(FUN);				\
   unsigned int  __ctx = (unsigned int)(CTX);				\
   *(unsigned int*) &__tramp[0] = 0xe92d000f; /* stmfd sp!, {r0-r3} */	\
   *(unsigned int*) &__tramp[4] = 0xe59f0000; /* ldr r0, [pc] */	\
   *(unsigned int*) &__tramp[8] = 0xe59ff000; /* ldr pc, [pc] */	\
   *(unsigned int*) &__tramp[12] = __ctx;				\
   *(unsigned int*) &__tramp[16] = __fun;				\
   __clear_cache((&__tramp[0]), (&__tramp[19]));			\
})

#endif


/* the cif must already be prep'ed */

ffi_status
ffi_prep_closure_loc (ffi_closure* closure,
		      ffi_cif* cif,
		      void (*fun)(ffi_cif*,void*,void**,void*),
		      void *user_data,
		      void *codeloc)
{
  FFI_ASSERT (cif->abi == FFI_SYSV);

  FFI_INIT_TRAMPOLINE (&closure->tramp[0], \
		       &ffi_closure_SYSV,  \
		       codeloc);
    
  closure->cif  = cif;
  closure->user_data = user_data;
  closure->fun  = fun;

  return FFI_OK;
}

#endif

#import "TargetConditionals.h"
#if TARGET_IPHONE_SIMULATOR


/* -----------------------------------------------------------------------
   ffi.c - Copyright (c) 1996, 1998, 1999, 2001, 2007, 2008  Red Hat, Inc.
           Copyright (c) 2002  Ranjit Mathew
           Copyright (c) 2002  Bo Thorsen
           Copyright (c) 2002  Roger Sayle
	   Copyright (C) 2008  Free Software Foundation, Inc.

   x86 Foreign Function Interface

   Permission is hereby granted, free of charge, to any person obtaining
   a copy of this software and associated documentation files (the
   ``Software''), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to
   permit persons to whom the Software is furnished to do so, subject to
   the following conditions:

   The above copyright notice and this permission notice shall be included
   in all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED ``AS IS'', WITHOUT WARRANTY OF ANY KIND,
   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
   MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
   NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.
   ----------------------------------------------------------------------- */

#ifndef __x86_64__

/* ffi_prep_args is called by the assembly routine once stack space
   has been allocated for the function's arguments */

void ffi_prep_args(char *stack, extended_cif *ecif)
{
  register unsigned int i;
  register void **p_argv;
  register char *argp;
  register ffi_type **p_arg;

  argp = stack;

  if (ecif->cif->flags == FFI_TYPE_STRUCT)
    {
      *(void **) argp = ecif->rvalue;
      argp += 4;
    }

  p_argv = ecif->avalue;

  for (i = ecif->cif->nargs, p_arg = ecif->cif->arg_types;
       i != 0;
       i--, p_arg++)
    {
      size_t z;

      /* Align if necessary */
      if ((sizeof(int) - 1) & (unsigned) argp)
	argp = (char *) ALIGN(argp, sizeof(int));

      z = (*p_arg)->size;
      if (z < sizeof(int))
	{
	  z = sizeof(int);
	  switch ((*p_arg)->type)
	    {
	    case FFI_TYPE_SINT8:
	      *(signed int *) argp = (signed int)*(SINT8 *)(* p_argv);
	      break;

	    case FFI_TYPE_UINT8:
	      *(unsigned int *) argp = (unsigned int)*(UINT8 *)(* p_argv);
	      break;

	    case FFI_TYPE_SINT16:
	      *(signed int *) argp = (signed int)*(SINT16 *)(* p_argv);
	      break;

	    case FFI_TYPE_UINT16:
	      *(unsigned int *) argp = (unsigned int)*(UINT16 *)(* p_argv);
	      break;

	    case FFI_TYPE_SINT32:
	      *(signed int *) argp = (signed int)*(SINT32 *)(* p_argv);
	      break;

	    case FFI_TYPE_UINT32:
	      *(unsigned int *) argp = (unsigned int)*(UINT32 *)(* p_argv);
	      break;

	    case FFI_TYPE_STRUCT:
	      *(unsigned int *) argp = (unsigned int)*(UINT32 *)(* p_argv);
	      break;

	    default:
	      FFI_ASSERT(0);
	    }
	}
      else
	{
	  memcpy(argp, *p_argv, z);
	}
      p_argv++;
      argp += z;
    }
  
  return;
}

/* Perform machine dependent cif processing */
ffi_status ffi_prep_cif_machdep(ffi_cif *cif)
{
  /* Set the return type flag */
  switch (cif->rtype->type)
    {
    case FFI_TYPE_VOID:
#ifdef X86
    case FFI_TYPE_STRUCT:
#endif
#if defined(X86) || defined(X86_DARWIN)
    case FFI_TYPE_UINT8:
    case FFI_TYPE_UINT16:
    case FFI_TYPE_SINT8:
    case FFI_TYPE_SINT16:
#endif

    case FFI_TYPE_SINT64:
    case FFI_TYPE_FLOAT:
    case FFI_TYPE_DOUBLE:
//##    case FFI_TYPE_LONGDOUBLE:
      cif->flags = (unsigned) cif->rtype->type;
      break;

    case FFI_TYPE_UINT64:
      cif->flags = FFI_TYPE_SINT64;
      break;

#ifndef X86
    case FFI_TYPE_STRUCT:
      if (cif->rtype->size == 1)
        {
          cif->flags = FFI_TYPE_SMALL_STRUCT_1B; /* same as char size */
        }
      else if (cif->rtype->size == 2)
        {
          cif->flags = FFI_TYPE_SMALL_STRUCT_2B; /* same as short size */
        }
      else if (cif->rtype->size == 4)
        {
          cif->flags = FFI_TYPE_INT; /* same as int type */
        }
      else if (cif->rtype->size == 8)
        {
          cif->flags = FFI_TYPE_SINT64; /* same as int64 type */
        }
      else
        {
          cif->flags = FFI_TYPE_STRUCT;
        }
      break;
#endif

    default:
      cif->flags = FFI_TYPE_INT;
      break;
    }

#ifdef X86_DARWIN
  cif->bytes = (cif->bytes + 15) & ~0xF;
#endif

  return FFI_OK;
}

extern void ffi_call_SYSV(void (*)(char *, extended_cif *), extended_cif *,
			  unsigned, unsigned, unsigned *, void (*fn)(void));


void ffi_call(ffi_cif *cif, void (*fn)(void), void *rvalue, void **avalue)
{
  extended_cif ecif;
  ecif.cif = cif;
  ecif.avalue = avalue;
  
  /* If the return value is a struct and we don't have a return	*/
  /* value address then we need to make one		        */

  if ((rvalue == NULL) && 
      (cif->flags == FFI_TYPE_STRUCT))
    {
      ecif.rvalue = alloca(cif->rtype->size);
    }
  else
    ecif.rvalue = rvalue;
    
  
  switch (cif->abi) 
    {
    case FFI_SYSV:
      ffi_call_SYSV(ffi_prep_args, &ecif, cif->bytes, cif->flags, ecif.rvalue,
		    fn);
      break;
    default:
      FFI_ASSERT(0);
      break;
    }
}


/** private members **/

static void ffi_prep_incoming_args_SYSV (char *stack, void **ret,
					 void** args, ffi_cif* cif);
void FFI_HIDDEN ffi_closure_SYSV (ffi_closure *)
     __attribute__ ((regparm(1)));
unsigned int FFI_HIDDEN ffi_closure_SYSV_inner (ffi_closure *, void **, void *)
     __attribute__ ((regparm(1)));
void FFI_HIDDEN ffi_closure_raw_SYSV (ffi_raw_closure *)
     __attribute__ ((regparm(1)));

/* This function is jumped to by the trampoline */

unsigned int FFI_HIDDEN
ffi_closure_SYSV_inner (closure, respp, args)
     ffi_closure *closure;
     void **respp;
     void *args;
{
  /* our various things...  */
  ffi_cif       *cif;
  void         **arg_area;

  cif         = closure->cif;
  arg_area    = (void**) alloca (cif->nargs * sizeof (void*));  

  /* this call will initialize ARG_AREA, such that each
   * element in that array points to the corresponding 
   * value on the stack; and if the function returns
   * a structure, it will re-set RESP to point to the
   * structure return address.  */

  ffi_prep_incoming_args_SYSV(args, respp, arg_area, cif);

  (closure->fun) (cif, *respp, arg_area, closure->user_data);

  return cif->flags;
}

static void
ffi_prep_incoming_args_SYSV(char *stack, void **rvalue, void **avalue,
			    ffi_cif *cif)
{
  register unsigned int i;
  register void **p_argv;
  register char *argp;
  register ffi_type **p_arg;

  argp = stack;

  if ( cif->flags == FFI_TYPE_STRUCT ) {
    *rvalue = *(void **) argp;
    argp += 4;
  }

  p_argv = avalue;

  for (i = cif->nargs, p_arg = cif->arg_types; (i != 0); i--, p_arg++)
    {
      size_t z;

      /* Align if necessary */
      if ((sizeof(int) - 1) & (unsigned) argp) {
	argp = (char *) ALIGN(argp, sizeof(int));
      }

      z = (*p_arg)->size;

      /* because we're little endian, this is what it turns into.   */

      *p_argv = (void*) argp;

      p_argv++;
      argp += z;
    }
  
  return;
}

/* How to make a trampoline.  Derived from gcc/config/i386/i386.c. */

#define FFI_INIT_TRAMPOLINE(TRAMP,FUN,CTX) \
({ unsigned char *__tramp = (unsigned char*)(TRAMP); \
   unsigned int  __fun = (unsigned int)(FUN); \
   unsigned int  __ctx = (unsigned int)(CTX); \
   unsigned int  __dis = __fun - (__ctx + 10);	\
   *(unsigned char*) &__tramp[0] = 0xb8; \
   *(unsigned int*)  &__tramp[1] = __ctx; /* movl __ctx, %eax */ \
   *(unsigned char *)  &__tramp[5] = 0xe9; \
   *(unsigned int*)  &__tramp[6] = __dis; /* jmp __fun  */ \
 })

#define FFI_INIT_TRAMPOLINE_STDCALL(TRAMP,FUN,CTX,SIZE)  \
({ unsigned char *__tramp = (unsigned char*)(TRAMP); \
   unsigned int  __fun = (unsigned int)(FUN); \
   unsigned int  __ctx = (unsigned int)(CTX); \
   unsigned int  __dis = __fun - (__ctx + 10); \
   unsigned short __size = (unsigned short)(SIZE); \
   *(unsigned char*) &__tramp[0] = 0xb8; \
   *(unsigned int*)  &__tramp[1] = __ctx; /* movl __ctx, %eax */ \
   *(unsigned char *)  &__tramp[5] = 0xe8; \
   *(unsigned int*)  &__tramp[6] = __dis; /* call __fun  */ \
   *(unsigned char *)  &__tramp[10] = 0xc2; \
   *(unsigned short*)  &__tramp[11] = __size; /* ret __size  */ \
 })

/* the cif must already be prep'ed */

ffi_status
ffi_prep_closure_loc (ffi_closure* closure,
		      ffi_cif* cif,
		      void (*fun)(ffi_cif*,void*,void**,void*),
		      void *user_data,
		      void *codeloc)
{
  if (cif->abi == FFI_SYSV)
    {
      FFI_INIT_TRAMPOLINE (&closure->tramp[0],
                           &ffi_closure_SYSV,
                           (void*)codeloc);
    }
  else
    {
      return FFI_BAD_ABI;
    }
    
  closure->cif  = cif;
  closure->user_data = user_data;
  closure->fun  = fun;

  return FFI_OK;
}

/* ------- Native raw API support -------------------------------- */

ffi_status
ffi_prep_raw_closure_loc (ffi_raw_closure* closure,
			  ffi_cif* cif,
			  void (*fun)(ffi_cif*,void*,ffi_raw*,void*),
			  void *user_data,
			  void *codeloc)
{
  int i;

  if (cif->abi != FFI_SYSV) {
    return FFI_BAD_ABI;
  }

  // we currently don't support certain kinds of arguments for raw
  // closures.  This should be implemented by a separate assembly language
  // routine, since it would require argument processing, something we
  // don't do now for performance.

  for (i = cif->nargs-1; i >= 0; i--)
    {
      FFI_ASSERT (cif->arg_types[i]->type != FFI_TYPE_STRUCT);
      FFI_ASSERT (cif->arg_types[i]->type != FFI_TYPE_LONGDOUBLE);
    }
  

  FFI_INIT_TRAMPOLINE (&closure->tramp[0], &ffi_closure_raw_SYSV,
		       codeloc);
    
  closure->cif  = cif;
  closure->user_data = user_data;
  closure->fun  = fun;

  return FFI_OK;
}

static void 
ffi_prep_args_raw(char *stack, extended_cif *ecif)
{
  memcpy (stack, ecif->avalue, ecif->cif->bytes);
}

/* we borrow this routine from libffi (it must be changed, though, to
 * actually call the function passed in the first argument.  as of
 * libffi-1.20, this is not the case.)
 */

extern void
ffi_call_SYSV(void (*)(char *, extended_cif *), extended_cif *, unsigned, 
	      unsigned, unsigned *, void (*fn)(void));

void
ffi_raw_call(ffi_cif *cif, void (*fn)(void), void *rvalue, ffi_raw *fake_avalue)
{
  extended_cif ecif;
  void **avalue = (void **)fake_avalue;

  ecif.cif = cif;
  ecif.avalue = avalue;
  
  /* If the return value is a struct and we don't have a return	*/
  /* value address then we need to make one		        */

  if ((rvalue == NULL) && 
      (cif->rtype->type == FFI_TYPE_STRUCT))
    {
      ecif.rvalue = alloca(cif->rtype->size);
    }
  else
    ecif.rvalue = rvalue;
    
  
  switch (cif->abi) 
    {
    case FFI_SYSV:
      ffi_call_SYSV(ffi_prep_args_raw, &ecif, cif->bytes, cif->flags,
		    ecif.rvalue, fn);
      break;
    default:
      FFI_ASSERT(0);
      break;
    }
}

#endif /* __x86_64__  */

#endif