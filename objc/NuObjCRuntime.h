/*!
 @header NuObjCRuntime.h
 @discussion Nu extensions to the Objective-C runtime.
 Includes replacements for Objective-C 2.0 enhancements
 that are only available in Apple's OS X 10.5 (Leopard)
 plus a few things that aren't in the Objective-C runtime
 but should be.
 @copyright Copyright (c) 2007 Radtastical Inc.
 
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
#import <objc/objc.h>

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#ifdef IPHONE
#import "ffi.h"
#else
#import "ffi/ffi.h"
#endif

// We'd like for this to be in the ObjC2 API, but it isn't.  Apple thinks it's too dangerous.  It is dangerous.
void nu_class_addInstanceVariable_withSignature(Class thisClass, const char *variableName, const char *signature);

// These are just handy.
IMP nu_class_replaceMethod(Class cls, SEL name, IMP imp, const char *types);
BOOL nu_copyInstanceMethod(Class destinationClass, Class sourceClass, SEL selector);
BOOL nu_objectIsKindOfClass(id object, Class class);
void nu_markEndOfObjCTypeString(char *type, size_t len);

// This makes it safe to insert nil into container classes
void nu_swizzleContainerClasses(void);

