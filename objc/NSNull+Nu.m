//
//  NSNull+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSNull+Nu.h"


@implementation NSNull(Nu)

- (bool) atom
{
    return true;
}

- (NSUInteger) length
{
    return 0;
}

- (NSUInteger) count
{
    return 0;
}

- (NSMutableArray *) array
{
    return @[];
}

- (NSString *) stringValue
{
    return @"()";
}

- (BOOL) isEqual:(id) other
{
    return ((self == other) || (other == 0)) ? 1l : 0l;
}

- (const char *) UTF8String
{
    return [[self stringValue] UTF8String];
}

@end

