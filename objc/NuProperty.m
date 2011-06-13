//
//  NuProperty.m
//  Nu
//
//  Created by Tim Burks on 6/12/11.
//  Copyright 2011 Radtastical Inc. All rights reserved.
//

#import "NuProperty.h"

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
