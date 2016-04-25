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
    return [NSMutableArray array];
}

- (NSString *) stringValue
{
    return @"()";
}

- (BOOL) isEqual:(id) other
{
    return ((self == other) || (other == 0)) ? 1l : 0l;
}

- (const char *) cStringUsingEncoding:(NSStringEncoding) encoding
{
    return [[self stringValue] cStringUsingEncoding:encoding];
}

@end

