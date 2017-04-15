//
//  NSDate+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSDate+Nu.h"

@implementation NSDate(Nu)

#ifndef LINUX
+ dateWithTimeIntervalSinceNow:(NSTimeInterval) seconds
{
    return [[[NSDate alloc] initWithTimeIntervalSinceNow:seconds] autorelease];
}
#endif

@end
