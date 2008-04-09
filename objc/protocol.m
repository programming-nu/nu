/*!
@file protocol.m
@description Nu support for protocols.
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

#ifdef LINUX
#define true 1
#define false 0
#import <objc/objc.h>
#import <objc/objc-api.h>
#endif

#import <Foundation/Foundation.h>
#include "class.h"
#include "extensions.h"

#ifdef DARWIN
#include "objc/runtime.h"
#include "mach_override.h"
#endif

#ifdef LINUX
struct objc_method_description_list
{
    int count;
    struct objc_method_description list[1];
};
#endif

#ifndef IPHONE
#ifndef __x86_64__

@interface Protocol : NSObject
{
    @public
    char *protocol_name;
    struct objc_protocol_list *protocol_list;
    struct objc_method_description_list *instance_methods;
    struct objc_method_description_list *class_methods;
}

- (const char *) name;
+ (Protocol *) protocolWithName:(NSString *) name;
+ (Protocol *) protocolNamed:(NSString *) name;
+ (NSArray *) all;
- (Protocol *) initWithName:(NSString *) name;
- (NSArray *) methodDescriptions;
- (NSComparisonResult) compare:(Protocol *) other;
- (NSArray *) protocols;
- (void) addInstanceMethod:(NSString *)name withSignature:(NSString *)signature;
- (void) addClassMethod:(NSString *)name withSignature:(NSString *)signature;
@end

// When we create protocols at runtime, we put them here.
static NSMutableDictionary *nuProtocols;

@implementation Protocol (Nu)

+ (Protocol *) protocolWithName:(NSString *) name
{
    return [[[Protocol alloc] initWithName:name] autorelease];
}

+ (Protocol *) protocolNamed:(NSString *) name
{
    Protocol *protocol = objc_getProtocol([name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (protocol) return protocol;
    return nil;
}

+ (NSArray *) all
{
    unsigned int count;
    Protocol **protocolList = objc_copyProtocolList(&count);
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        [array addObject:protocolList[i]];
    }
    free(protocolList);
    return array;
}

- (Protocol *) initWithName:(NSString *) name
{
    [super init];
    protocol_name = strdup([name cStringUsingEncoding:NSUTF8StringEncoding]);
    protocol_list = NULL;
    instance_methods = NULL;
    class_methods = NULL;

    if (!nuProtocols)
        nuProtocols = [[NSMutableDictionary alloc] init];
    [nuProtocols setPossiblyNullObject:self forKey:name];
    return self;
}

static void addMethodDescriptionsToArray(Protocol *protocol, BOOL isRequiredMethod, BOOL isInstanceMethod, NSMutableArray *array)
{
    unsigned int count;
    struct objc_method_description *method_descriptions =
        protocol_copyMethodDescriptionList(protocol, isRequiredMethod, isInstanceMethod, &count);
    for (int i = 0; i < count; i++) {
        #ifdef DARWIN
        NSString *name = [NSString stringWithCString:sel_getName(method_descriptions[i].name) encoding:NSASCIIStringEncoding];
        #else
        NSString *name = [NSString stringWithCString:sel_get_name(method_descriptions[i].name) encoding:NSASCIIStringEncoding];
        #endif
        NSString *signature = [NSString stringWithCString:method_descriptions[i].types encoding:NSASCIIStringEncoding];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name",
            signature, @"signature",
            [NSNumber numberWithInt:(isRequiredMethod ? 1 : 0)], @"required",
            [NSNumber numberWithInt:(isInstanceMethod ? 1 : 0)], @"instance",
            nil];
        [array addObject:dictionary];
    }
    free(method_descriptions);
}

- (NSArray *) methodDescriptions
{
    NSMutableArray *array = [NSMutableArray array];
    addMethodDescriptionsToArray(self, true, true, array);
    addMethodDescriptionsToArray(self, true, false, array);
    addMethodDescriptionsToArray(self, false, true, array);
    addMethodDescriptionsToArray(self, false, false, array);
    return array;
}

- (NSComparisonResult) compare:(Protocol *) other
{
    return strcmp([self name], [other name]);
}

- (NSArray *) protocols
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count;
    Protocol **protocolList = protocol_copyProtocolList(self, &count);
    for (int i = 0; i < count; i++) {
        [array addObject:protocolList[i]];
    }
    free(protocolList);
    return array;
}

- (void) addInstanceMethod:(NSString *)name withSignature:(NSString *)signature
{
    #ifdef DARWIN
    SEL sel = sel_registerName([name cStringUsingEncoding:NSUTF8StringEncoding]);
    #else
    SEL sel = sel_register_name([name cStringUsingEncoding:NSUTF8StringEncoding]);
    #endif
    const char *types = [signature cStringUsingEncoding:NSUTF8StringEncoding];

    struct objc_method_description_list *oldList = self->instance_methods;

    //NSLog(@"old instance method list is %d", oldList);
    if (oldList) {
        struct objc_method_description_list *newList = (struct objc_method_description_list *) malloc
            (sizeof(struct objc_method_description_list) + oldList->count * (sizeof (struct objc_method_description)));
        memcpy(newList, oldList,
            (sizeof(struct objc_method_description_list) + (oldList->count-1) * (sizeof (struct objc_method_description))));
        newList->list[oldList->count].name = sel;
        newList->list[oldList->count].types = strdup(types);
        newList->count++;
        //free(oldList); leak. It seems that we can't free the lists created when protocols are loaded from compiled objects.
        self->instance_methods = newList;
    }
    else {
        struct objc_method_description_list *newList = (struct objc_method_description_list *) malloc
            (sizeof(struct objc_method_description_list));
        newList->list[0].name = sel;
        newList->list[0].types = strdup(types);
        newList->count = 1;
        self->instance_methods = newList;
    }
}

- (void) addClassMethod:(NSString *)name withSignature:(NSString *)signature
{
    #ifdef DARWIN
    SEL sel = sel_registerName([name cStringUsingEncoding:NSUTF8StringEncoding]);
    #else
    SEL sel = sel_register_name([name cStringUsingEncoding:NSUTF8StringEncoding]);
    #endif
    const char *types = [signature cStringUsingEncoding:NSUTF8StringEncoding];

    struct objc_method_description_list *oldList = self->class_methods;
    //NSLog(@"old class method list is %d", oldList);
    if (oldList) {
        struct objc_method_description_list *newList = (struct objc_method_description_list *) malloc
            (sizeof(struct objc_method_description_list) + oldList->count * (sizeof (struct objc_method_description)));
        memcpy(newList, oldList,
            (sizeof(struct objc_method_description_list) + (oldList->count-1) * (sizeof (struct objc_method_description))));
        newList->list[oldList->count].name = sel;
        newList->list[oldList->count].types = strdup(types);
        newList->count++;
        //free(oldList);
        self->class_methods = newList;
    }
    else {
        struct objc_method_description_list *newList = (struct objc_method_description_list *) malloc
            (sizeof(struct objc_method_description_list));
        newList->list[0].name = sel;
        newList->list[0].types = strdup(types);
        newList->count = 1;
        self->class_methods = newList;
    }
}

@end

@implementation NuClass (Protocols)

- (BOOL) addProtocol:(Protocol *)p
{
    return class_addProtocol(self->c, p);
}

- (BOOL) conformsToProtocol:(Protocol *)p
{
    return class_conformsToProtocol(self->c, p);
}

- (NSArray *) protocols
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count;
    Protocol **protocolList = class_copyProtocolList(self->c, &count);
    for (int i = 0; i < count; i++) {
        [array addObject:protocolList[i]];
    }
    free(protocolList);
    return array;
}

@end

typedef Protocol *(*objc_getProtocol_ptr)(const char *name);
static objc_getProtocol_ptr original_objc_getProtocol;

Protocol *nu_objc_getProtocol(const char *name)
{
    // NSLog(@"nu_objc_getProtocol %s", name);
    Protocol *p = (*original_objc_getProtocol)(name);
    if (p) return p;
    else if (nuProtocols) {
        // lookup protocol in our dictionary
        id key = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        return [nuProtocols objectForKey:key];
    } else
    return nil;
}

typedef Protocol **(*objc_copyProtocolList_ptr)(unsigned int *outCount);
static objc_copyProtocolList_ptr original_objc_copyProtocolList;

Protocol **nu_objc_copyProtocolList(unsigned int *outCount)
{
    //NSLog(@"nu_objc_copyProtocolList");
    Protocol **originalProtocolList = (*original_objc_copyProtocolList)(outCount);
    if (!nuProtocols || ([nuProtocols count] == 0)) {
        return originalProtocolList;
    }
    Protocol **newProtocolList = (Protocol **) malloc ((*outCount + [nuProtocols count]) * sizeof (Protocol *));
    for (int i = 0; i < *outCount; i++) {
        newProtocolList[i] = originalProtocolList[i];
    }
    id myProtocolArray = [nuProtocols allValues];
    for (int i = 0; i < [nuProtocols count]; i++) {
        newProtocolList[i+*outCount] = [myProtocolArray objectAtIndex:i];
    }
    free(originalProtocolList);
    *outCount += [nuProtocols count];
    return newProtocolList;
}
#endif

void nu_initProtocols()
{
    #ifndef __x86_64__
    static int initialized = 0;
    if (!initialized) {
        initialized = 1;
        nuProtocols = nil;
        // We wish that Protocal inherited from NSObject instead of Object, so we make it so.
        // This makes it easier to manipulate Protocols from Nu.
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [[NuClass classWithClass:[Protocol class]] setSuperclass:[NuClass classWithClass:[NSObject class]]];
        [pool release];
        #ifdef DARWIN
        // Since Apple doesn't have an API to add new protocols, we make our own.
        // We replace these functions with our own versions to include the protocols we create at runtime.
        mach_override("_objc_getProtocol", NULL, (void*)&nu_objc_getProtocol, (void**)&original_objc_getProtocol);
        mach_override("_objc_copyProtocolList", NULL, (void*)&nu_objc_copyProtocolList, (void**)&original_objc_copyProtocolList);
        #endif
    }
    #endif
}
#ifdef DARWIN
// bonus: I found this in the ObjC2.0 runtime.
@interface NuImage : NSObject
{
}

@end

@implementation NuImage

+ (NSArray *) all
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count;
    const char **names = objc_copyImageNames(&count);
    for (int i = 0; i < count; i++) {
        [array addObject:[NSString stringWithCString:names[i] encoding:NSUTF8StringEncoding]];
    }
    return array;
}

+ (NSArray *) classNamesForImageName:(NSString *) imageName
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int count;
    const char **names = objc_copyClassNamesForImage([imageName cStringUsingEncoding:NSUTF8StringEncoding], &count);
    for (int i = 0; i < count; i++) {
        [array addObject:[NSString stringWithCString:names[i] encoding:NSUTF8StringEncoding]];
    }
    return array;
}

@end
#endif
#endif
