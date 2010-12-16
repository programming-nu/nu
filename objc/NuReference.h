/*!
@header reference.h
@discussion Declarations for the NuReference class,
which represents pointers to Objective-C objects.
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
   @class NuReference
   @abstract The Nu object wrapper.
   @discussion The NuReference class provides a wrapper for pointers to Objective-C objects.
   NuReference objects are used in the Nu language to capture arguments that are returned by value from Objective-C methods.
   For example, the following Nu method uses a NuReference to capture a returned-by-reference NSError:

<div style="margin-left:2em">
<code>
(imethod (id) save is<br/>
&nbsp;&nbsp;(set perror ((NuReference alloc) init))<br/>
&nbsp;&nbsp;(set result ((self managedObjectContext) save:perror))<br/>
&nbsp;&nbsp;(unless result<br/>
&nbsp;&nbsp;&nbsp;&nbsp;(NSLog "error: #{((perror value) localizedDescription)}"))<br/>
&nbsp;&nbsp;result)
</code>
</div>
*/
@interface NuReference : NSObject
{
    id *pointer;
    bool thePointerIsMine;
}

/*! Get the value of the referenced object. */
- (id) value;
/*! Set the value of the referenced object. */
- (void) setValue:(id) value;
/*! Set the pointer for a reference.  Used by the bridge to create NuReference objects from pointers.  Don't call this from Nu. */
- (void) setPointer:(id *) pointer;
/*! Get a pointer to the referenced object. Used by the bridge to Objective-C to convert NuReference objects to pointers.
    Don't call this from Nu.
*/
- (id *) pointerToReferencedObject;
/*! Retain the referenced object. Used by the bridge to Objective-C to retain values returned by reference. */
- (void) retainReferencedObject;
@end
