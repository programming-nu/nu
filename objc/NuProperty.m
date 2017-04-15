//
//  NuProperty.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//
#import <Foundation/Foundation.h>
#import "NuProperty.h"

#pragma mark - NuProperty.m

@interface NuProperty ()
{
    objc_property_t p;
}
@end

@implementation NuProperty

+ (NuProperty *) propertyWithProperty:(objc_property_t) property {
    return [[[self alloc] initWithProperty:property] autorelease];
}

- (id) initWithProperty:(objc_property_t) property
{
    if ((self = [super init])) {
        p = property;
    }
    return self;
}

- (NSString *) name
{
    return [NSString stringWithCString:property_getName(p) encoding:NSUTF8StringEncoding];
}

@end

