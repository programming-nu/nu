/*!
@file overrides.m
@description Overrides to system library functions.
@copyright Copyright (c) 2007 Neon Design Technology, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
#if defined(DARWIN) && !defined(IPHONE) && !defined(SNOWLEOPARD)

#include "mach_override.h"
#include "Foundation/Foundation.h"

#ifdef __x86_64__

// Since mach_override is not yet available for x86_64,
// use a quick-and-dirty substitute.

#include <mach-o/dyld.h>

static void *ptrToNSLog = 0;
static unsigned char firstByteOfNSLog = 0;

void nu_disableNSLog()
{
    int err = 0;
    if (ptrToNSLog == 0) {
        _dyld_lookup_and_bind("_NSLog", (void*) &ptrToNSLog, NULL);
        if (ptrToNSLog) {
            err = vm_protect( mach_task_self(),
                (vm_address_t) ptrToNSLog,
                sizeof(long), false, (VM_PROT_ALL | VM_PROT_COPY) );
            if (err)
                err = vm_protect( mach_task_self(),
                    (vm_address_t) ptrToNSLog, sizeof(long), false,
                    (VM_PROT_DEFAULT | VM_PROT_COPY) );
        }
    }
    if (!ptrToNSLog || err) {
        NSLog(@"failed to control NSLog");
    }
    else if (!firstByteOfNSLog) {
        firstByteOfNSLog = *((unsigned char *)ptrToNSLog);
        // this is not guaranteed to be atomic, so it's thread-unsafe
        *((unsigned char *)ptrToNSLog) = 0xc3;    // ret
    }
}

void nu_enableNSLog()
{
    if (ptrToNSLog) {
        *((unsigned char *)ptrToNSLog) = firstByteOfNSLog;
        firstByteOfNSLog = 0;
    }
}

#else

typedef void (*NSLogPtr)(NSString *format, ...);
static NSLogPtr g_originalNSLog;
static BOOL g_enableNSLog;

static void NuLog(void *format, ...)
{
    if (g_enableNSLog) {
        va_list ap;
        va_start (ap, format);
        NSLogv (format, ap);
        va_end (ap);
    }
    return;
}

void nu_disableNSLog()
{
    kern_return_t err;
    static int initialized = 0;
    if (!initialized) {
        initialized = 1;
        err = mach_override( "_NSLog", NULL, (void*)&NuLog, (void**)&g_originalNSLog);
    }
    g_enableNSLog = false;
}

void nu_enableNSLog()
{
    g_enableNSLog = true;
}
#endif
#else

void nu_disableNSLog()
{
}

void nu_enableNSLog()
{
}

#endif
