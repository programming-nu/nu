//
//  NuProfiler.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuProfiler.h"


#ifdef DARWIN
#import <mach/mach.h>
#import <mach/mach_time.h>
#endif

@interface NuProfileStackElement : NSObject
{
@public
    NSString *name;
    uint64_t start;
    NuProfileStackElement *parent;
}

@end

@interface NuProfileTimeSlice : NSObject
{
@public
    float time;
    int count;
}

@end

@implementation NuProfileStackElement

- (NSString *) name {return name;}
- (uint64_t) start {return start;}
- (NuProfileStackElement *) parent {return parent;}

- (NSString *) description
{
    return [NSString stringWithFormat:@"name:%@ start:%llx", name, start];
}

@end

@implementation NuProfileTimeSlice

- (float) time {return time;}
- (int) count {return count;}

- (NSString *) description
{
    return [NSString stringWithFormat:@"time:%f count:%d", time, count];
}

@end

@interface NuProfiler ()
{
    NSMutableDictionary *sections;
    NuProfileStackElement *stack;
}
@end

@implementation NuProfiler

static NuProfiler *defaultProfiler = nil;

+ (NuProfiler *) defaultProfiler
{
    if (!defaultProfiler)
        defaultProfiler = [[NuProfiler alloc] init];
    return defaultProfiler;
}

- (NuProfiler *) init
{
    self = [super init];
    sections = [[NSMutableDictionary alloc] init];
    stack = nil;
    return self;
}

- (void) start:(NSString *) name
{
#ifdef DARWIN
    NuProfileStackElement *stackElement = [[NuProfileStackElement alloc] init];
    stackElement->name = [name retain];
    stackElement->start = mach_absolute_time();
    stackElement->parent = stack;
    stack = stackElement;
#endif
}

- (void) stop
{
#ifdef DARWIN
    if (stack) {
        uint64_t current_time = mach_absolute_time();
        uint64_t time_delta = current_time - stack->start;
        struct mach_timebase_info info;
        mach_timebase_info(&info);
        float timeDelta = 1e-9 * time_delta * (double) info.numer / info.denom;
        //NSNumber *delta = [NSNumber numberWithFloat:timeDelta];
        NuProfileTimeSlice *entry = [sections objectForKey:stack->name];
        if (!entry) {
            entry = [[[NuProfileTimeSlice alloc] init] autorelease];
            entry->count = 1;
            entry->time = timeDelta;
            [sections setObject:entry forKey:stack->name];
        }
        else {
            entry->count++;
            entry->time += timeDelta;
        }
        [stack->name release];
        NuProfileStackElement *top = stack;
        stack = stack->parent;
        [top release];
    }
#endif
}

- (NSMutableDictionary *) sections
{
    return sections;
}

- (void) reset
{
    [sections removeAllObjects];
    while (stack) {
        NuProfileStackElement *top = stack;
        stack = stack->parent;
        [top release];
    }
}

@end
