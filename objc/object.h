/*!
@header object.h
@discussion Nu extensions to NSObject for higher-level programming.
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

#ifdef LINUX
#define bool char
#endif

#import <Foundation/Foundation.h>
@class NuBlock;
@class NuClass;
@class NuCell;

/*!
    @category NSObject(Nu)
    @abstract NSObject extensions for Nu programming.
*/
@interface NSObject(Nu)
/*! Returns true.  In Nu, virtually all Objective-C classes are considered atoms. */
- (bool) atom;
/*!
    Evaluation operator.  The Nu default is for an Objective-C object to evaluate to itself,
    but certain subclasses (such as NuSymbol and NSString) behave differently.
*/
- (id) evalWithContext:(NSMutableDictionary *) context;
/*! Gets the value of a specified instance variable. */
- (id) valueForIvar:(NSString *) name;
/*! Sets the value of a specified instance variable. */
- (void) setValue:(id) value forIvar:(NSString *) name;
/*! Get an array containing NuMethod representations of the class methods of a class. */
+ (NSArray *) classMethods;
/*! Get an array containing NuMethod representations of the instance methods of a class. */
+ (NSArray *) instanceMethods;
/*! Get an array containing the names of the class methods of a class. */
+ (NSArray *) classMethodNames;
/*! Get an array containing the names of the instance methods of a class. */
+ (NSArray *) instanceMethodNames;
/*! Get an array containing the names of all instance variables of the class. */
+ (NSArray *) instanceVariableNames;

/*! Create a subclass of a class with the specified name. */
+ (id) createSubclassNamed:(NSString *) subclassName;

/*! Copy a named instance method from another class to the receiving class. */
+ (BOOL) copyInstanceMethod:(NSString *) methodName fromClass:(NuClass *) prototypeClass;
/*! Copy all of the instance methods from a specified class to the receiving class. */
+ (BOOL) include:(NuClass *) prototypeClass;

/*! Send a message to an object with an execution context */
- (id) sendMessage:(id)cdr withContext:(NSMutableDictionary *)context;
/*! Evaluate a list with the receiving object at the head. Calls <b>sendMessage:withContext:</b> */
- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context;

/*! Handle an unknown message.  Override this in subclasses to provide dynamic method handling. */
- (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context;

/*! This method is automatically sent to a class whenever Nu code creates a subclass of that class.
Its default implementation does nothing.  Override it to track subclassing. */
+ (id) inheritedByClass:(NuClass *) newClass;

/*! Get a string providing a helpful description of an object.
This method should be overridden by subclasses to be more helpful. */
- (NSString *) help;

/*! Swap a pair of instance methods of the underlying class. */
+ (BOOL) exchangeInstanceMethod:(SEL)sel1 withMethod:(SEL)sel2;

/*! Swap a pair of class methods of the underlying class. */
+ (BOOL) exchangeClassMethod:(SEL)sel1 withMethod:(SEL)sel2;

/*! Concisely set key-value pairs from a property list. */
- (id) set:(NuCell *) propertyList;

@end
