// overrides.m
//  Overrides to system library functions.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#include "mach_override.h"
#include "Foundation/Foundation.h"

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