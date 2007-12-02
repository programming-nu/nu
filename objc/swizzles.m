// swizzles.m
//  Some simple enhancements to standard container classes.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import <Cocoa/Cocoa.h>
#import "class.h"
#import "object.h"

@class NSCFDictionary;
@class NSCFArray;
@class NSCFSet;

@interface NSCFDictionarySwizzles : NSObject {}
@end

@implementation NSCFDictionarySwizzles

- (void)nuSetObject:(id)anObject forKey:(id)aKey
{
    [self nuSetObject:((anObject == nil) ? [NSNull null] : anObject) forKey:aKey];
}

@end

@interface NSCFArraySwizzles : NSObject {}
@end

@implementation NSCFArraySwizzles

- (void)nuAddObject:(id)anObject
{
    [self nuAddObject:((anObject == nil) ? [NSNull null] : anObject)];
}

- (void)nuInsertObject:(id)anObject atIndex:(NSUInteger)index
{
    [self nuInsertObject:((anObject == nil) ? [NSNull null] : anObject) atIndex:index];
}

- (void)nuReplaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
    [self nuReplaceObjectAtIndex:index withObject:((anObject == nil) ? [NSNull null] : anObject)];
}

@end

@interface NSCFSetSwizzles : NSObject {}
@end

@implementation NSCFSetSwizzles

- (void)nuAddObject:(id)anObject
{
    [self nuAddObject:((anObject == nil) ? [NSNull null] : anObject)];
}

@end

void nu_swizzleContainerClasses()
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [NSCFDictionary include:[NuClass classWithName:@"NSCFDictionarySwizzles"]];
    [NSCFArray include:[NuClass classWithName:@"NSCFArraySwizzles"]];
    [NSCFSet include:[NuClass classWithName:@"NSCFSetSwizzles"]];
    [NSCFDictionary exchangeInstanceMethod:@selector(setObject:forKey:) withMethod:@selector(nuSetObject:forKey:)];
    [NSCFArray exchangeInstanceMethod:@selector(addObject:) withMethod:@selector(nuAddObject:)];
    [NSCFArray exchangeInstanceMethod:@selector(insertObject:atIndex:) withMethod:@selector(nuInsertObject:atIndex:)];
    [NSCFArray exchangeInstanceMethod:@selector(replaceObjectAtIndex:withObject:) withMethod:@selector(nuReplaceObjectAtIndex:withObject:)];
    [NSCFSet exchangeInstanceMethod:@selector(addObject:) withMethod:@selector(nuAddObject:)];
    [pool release];
}
