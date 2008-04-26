/*!
@header super.h
@discussion Declarations for NuSuper, a Nu proxy for object superclasses.
NuSuper allows Nu method implementations to send messages to their superclass implementations.
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

#import <objc/objc.h>
#ifdef DARWIN
#ifndef IPHONE
#import <objc/objc-runtime.h>
#import <objc/objc-class.h>
#else
#import <objc/runtime.h>
#endif
#endif

/*!
    @class NuSuper
    @abstract The Nu superclass proxy, an implementation detail used by Nu methods.
    @discussion Instances of this class in Nu methods act as proxies for object superclasses.
    Each time a Nu implementation of a method is called,
    a NuSuper instance is created and inserted into the method's execution context with the name "super".
    This allows method implementations to send messages to superclass implementations.
    Typically, there is no need to directly interact with this class from Nu.
 */
@interface NuSuper : NSObject
{
    id object;
    Class class;
}

/*! Create a NuSuper proxy for an object with a specified class.
    Note that the object class must be explicitly specified.
    This is necessary to allow proper chaining of message sends
    to super when multilevel methods are used (typically for initialization),
    each calling the superclass version of itself. */
+ (NuSuper *) superWithObject:(id) o ofClass:(Class) c;
/*! Initialize a NuSuper proxy for an object with a specified class. */
- (NuSuper *) initWithObject:(id) o ofClass:(Class) c;
/*! Evalute a list headed by a NuSuper proxy.  If non-null, the remainder
    of the list is treated as a message that is sent to the object,
    but treating the object as if it is an instance of its immediate superclass.
    This is equivalent to sending a message to "super" in Objective-C. */
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context;

@end
