/*!
@header pointer.h
@discussion Declarations for the NuPointer class,
which wrap pointers to arbitrary locations in memory.
@copyright Copyright (c) 2007 Neon Design Technology, Inc.

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
#import "nutypes.h"

/*!
   @class NuPointer
   @abstract The Nu pointer wrapper.
   @discussion The NuPointer class provides a wrapper for pointers to arbitrary locations in memory.
*/
@interface NuPointer : NSObject
{
    void *pointer;
    NSString *typeString;
    bool thePointerIsMine;
}

/*! Get the value of the pointer. Don't call this from Nu. */
- (void *) pointer;
/*! Set the pointer.  Used by the bridge to create NuReference objects from pointers.  Don't call this from Nu. */
- (void) setPointer:(void *) pointer;
/*! Set the type of a pointer. This should be an Objective-C type encoding that begins with a "^". */
- (void) setTypeString:(NSString *) typeString;
/*! Get an Objective-C type string describing the pointer target. */
- (NSString *) typeString;
/*! Assume the pointer is a pointer to an Objective-C object. Get the object. You had better be right, or this will crash. */
- (id) object;
/*! Get the value of the pointed-to object, using the typeString to determine the correct type */
- (id) value;
/*! Helper function, used internally to reserve space for data of a specified type. */
- (void) allocateSpaceForTypeString:(NSString *) s;
@end
