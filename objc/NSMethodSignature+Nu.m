//
//  NSMethodSignature+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSMethodSignature+Nu.h"

@implementation NSMethodSignature(Nu)

- (NSString *) typeString
{
    // in 10.5, we can do this:
    // return [self _typeString];
    NSMutableString *result = [NSMutableString stringWithFormat:@"%s", [self methodReturnType]];
    NSInteger i;
    NSUInteger max = [self numberOfArguments];
    for (i = 0; i < max; i++) {
        [result appendFormat:@"%s", [self getArgumentTypeAtIndex:i]];
    }
    return result;
}

@end