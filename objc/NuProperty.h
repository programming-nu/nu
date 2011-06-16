/*!
 @header NuProperty.h
 @discussion Declarations for NuProperty, a wrapper for ObjC properties
 @copyright Copyright (c) 2011 Radtastical Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

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
