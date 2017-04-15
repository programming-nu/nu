//
//  NuProperty.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>
#import <objc/objc.h>
#import <objc/runtime.h>

/*!
 @class NuProperty
 @abstract Wrapper for Objective-C properties.
 @discussion Preliminary and incomplete.
 */
@interface NuProperty : NSObject

/*! Create a property wrapper for the specified property (used from Objective-C). */
+ (NuProperty *) propertyWithProperty:(objc_property_t) property;
/*! Initialize a property wrapper for the specified property (used from Objective-C). */
- (id) initWithProperty:(objc_property_t) property;

@end