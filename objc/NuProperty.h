//
//  NuProperty.h
//  Nu
//
//  Created by Tim Burks on 6/12/11.
//  Copyright 2011 Radtastical Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NuProperty : NSObject
{
    objc_property_t p;
}
   
/*! Create a property wrapper for the specified property (used from Objective-C). */
+ (NuProperty *) propertyWithProperty:(objc_property_t) property;
/*! Initialize a property wrapper for the specified property (used from Objective-C). */
- (id) initWithProperty:(objc_property_t) property;

@end
