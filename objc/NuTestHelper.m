//
//  NuTestHelper.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>
#import "Nu.h"

#import "NuTestHelper.h"
#ifdef DARWIN
#import <CoreGraphics/CoreGraphics.h>
#endif

#pragma mark - NuTestHelper.m

static BOOL verbose_helper = false;

@protocol NuTestProxy <NSObject>

#ifdef DARWIN
- (CGRect) CGRectValue;
- (CGPoint) CGPointValue;
- (CGSize) CGSizeValue;
#endif
- (NSRange) NSRangeValue;

@end

static int deallocationCount = 0;

@implementation NuTestHelper

+ (void) cycle
{
    NuTestHelper *object = [[NuTestHelper alloc] init];
    //Class before = object->isa;
    objc_setAssociatedObject(object, @"number", @"123", OBJC_ASSOCIATION_RETAIN);
    //Class after = object->isa;
    //SEL cxx_destruct = sel_registerName(".cxx_destruct");
    //NSLog(@"class %@ %@", before, after);
    //NSLog(@"responds? %d", [object respondsToSelector:cxx_destruct]);
    [object release];
}

+ (void) setVerbose:(BOOL) v
{
    verbose_helper = v;
}

+ (BOOL) verbose
{
    return verbose_helper;
}

+ (id) helperInObjCUsingAllocInit
{
    id object = [[[NuTestHelper alloc] init] autorelease];
    return object;
}

+ (id) helperInObjCUsingNew
{
    id object = [NuTestHelper new];
    // the GNUstep runtime returns nil from this call.
    [object autorelease];
    return object;
}

- (id) init
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper init %p)", self);
    return [super init];
}

- (id) retain
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper retain %p)", self);
    return [super retain];
}

- (oneway void) release
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper release %p)", self);
    [super release];
}

- (id) autorelease
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper autorelease %p)", self);
    return [super autorelease];
}

- (void) dealloc
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper dealloc %p)", self);
    deallocationCount++;
    [super dealloc];
}

- (void) finalize
{
    if (verbose_helper)
        NSLog(@"(NuTestHelper finalize %p)", self);
    deallocationCount++;
    [super finalize];
}

+ (void) resetDeallocationCount
{
    deallocationCount = 0;
}

+ (int) deallocationCount
{
    return deallocationCount;
}

#ifdef DARWIN
+ (CGRect) getCGRectFromProxy:(id<NuTestProxy>) proxy {
    return [proxy CGRectValue];
}

+ (CGPoint) getCGPointFromProxy:(id<NuTestProxy>) proxy {
    return [proxy CGPointValue];
}

+ (CGSize) getCGSizeFromProxy:(id<NuTestProxy>) proxy {
    return [proxy CGSizeValue];
}
#endif

+ (NSRange) getNSRangeFromProxy:(id<NuTestProxy>) proxy {
    return [proxy NSRangeValue];
}

@end
