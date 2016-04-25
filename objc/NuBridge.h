//
//  NuBridge.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

#import "NuBlock.h"
#import "NuCell.h"

#import <dlfcn.h>
#if TARGET_OS_IPHONE
#import "ffi.h"
#else
#ifdef DARWIN
#import <ffi/ffi.h>
#else
#import <x86_64-linux-gnu/ffi.h>
#endif
#endif


ffi_type *ffi_type_for_objc_type(const char *typeString);


#import "NuMethod.h"

#pragma mark -
#pragma mark Interacting with the Objective-C Runtime

#import "NuClass.h"

