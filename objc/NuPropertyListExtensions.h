/*!
 @header NuPropertyListExtensions.h
 @discussion Extensions to allow simper property list access.
 which wrap pointers to arbitrary locations in memory.
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

@interface NSObject (NuPropertyListExtensions) 

/*! Return the XML property list representation of the object. */
- (NSData *) XMLPropertyListRepresentation;

/*! Return the binary property list representation of the object. */
- (NSData *) binaryPropertyListRepresentation;

@end

@interface NSData (NuPropertyListExtensions) 

/*! Return the (immutable) property list value of the associated data. */
- (id) propertyListValue;
@end
