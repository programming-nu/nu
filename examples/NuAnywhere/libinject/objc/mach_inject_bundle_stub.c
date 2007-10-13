/*******************************************************************************
    mach_inject_bundle_stub.c
        Copyright (c) 2005 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
        Some rights reserved: <http://creativecommons.org/licenses/by/2.0/>

    Design inspired by SCPatchLoader, by Jon Gotow of St. Clair Software:
        <http://www.stclairsoft.com>

    ***************************************************************************/

#include "mach_inject_bundle_stub.h"
#include "load_bundle.h"
#include "mach_inject.h"                          // for INJECT_ENTRY

#include <assert.h>
#include <mach/mach_init.h>
#include <mach/thread_act.h>
#include <pthread.h>
#include <Carbon/Carbon.h>

/**************************
 *
 *	Funky Protos
 *
 **************************/
#pragma mark    (Funky Protos)

void
INJECT_ENTRY(
ptrdiff_t                       codeOffset,
mach_inject_bundle_stub_param   *param,
size_t                          paramSize,
char                            *dummy_pthread_struc );

void*
pthread_entry(
mach_inject_bundle_stub_param   *param );

pascal
void
EventLoopTimerEntry(
EventLoopTimerRef               inTimer,
mach_inject_bundle_stub_param   *param );

/*******************************************************************************
 *
 *	Implementation
 *
 *******************************************************************************/
#pragma mark    -
#pragma mark    (Implementation)

void
INJECT_ENTRY(
ptrdiff_t                       codeOffset,
mach_inject_bundle_stub_param   *param,
size_t                          paramSize,
char                            *dummy_pthread_struct )
{
    assert( param );

    param->codeOffset = codeOffset;

    #if defined (__i386__)
    // On intel, per-pthread data is a zone of data that must be allocated.
    // if not, all function trying to access per-pthread data (all mig functions for instance)
    // will crash.
    extern void __pthread_set_self(char*);
    __pthread_set_self(dummy_pthread_struct);
    #endif

    pthread_attr_t attr;
    pthread_attr_init(&attr);

    int policy;
    pthread_attr_getschedpolicy( &attr, &policy );
    pthread_attr_setdetachstate( &attr, PTHREAD_CREATE_DETACHED );
    pthread_attr_setinheritsched( &attr, PTHREAD_EXPLICIT_SCHED );

    struct sched_param sched;
    sched.sched_priority = sched_get_priority_max( policy );
    pthread_attr_setschedparam( &attr, &sched );

    pthread_t thread;
    pthread_create( &thread,
        &attr,
        (void* (*)(void*))((long)pthread_entry + codeOffset),
        (void*) param );
    pthread_attr_destroy(&attr);

    thread_suspend(mach_thread_self());
}

void*
pthread_entry(
mach_inject_bundle_stub_param   *param )
{
    assert( param );

    EventLoopTimerProcPtr proc = (EventLoopTimerProcPtr) EventLoopTimerEntry;
    proc += param->codeOffset;
    EventLoopTimerUPP upp = NewEventLoopTimerUPP( proc );

    InstallEventLoopTimer( GetMainEventLoop(), 0, 0, upp, (void*)param, NULL );
    return NULL;
}

pascal
void
EventLoopTimerEntry(
EventLoopTimerRef               inTimer,
mach_inject_bundle_stub_param   *param )
{
    assert( inTimer );
    assert( param );

    static unsigned bundleLoaded = 0;
    if (!bundleLoaded) {
        load_bundle_package( param->bundlePackageFileSystemRepresentation );
        bundleLoaded = 1;
    }
}
