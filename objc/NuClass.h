/*!
@header class.h
@discussion Declarations for the NuClass class,
which represents classes in the Objective-C runtime.
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

@class NuMethod;
@class NuBlock;

/*!
    @class NuClass
    @abstract A Nu wrapper for class representations in the Objective-C runtime.
    @discussion NuClass provides an object wrapper for classes that are represented in the Objective-C runtime.
    NuClass objects are used in the Nu language to manipulate and extend Objective-C classes.
 */
@interface NuClass : NSObject
{
    Class c;
    BOOL isRegistered;
}

/*! Create a class wrapper for the specified class (used from Objective-C). */
+ (NuClass *) classWithClass:(Class) class;
/*! Create a class wrapper for the named Objective-C class. */
+ (NuClass *) classWithName:(NSString *)string;
/*! Initialize a class wrapper for the specified class (used from Objective-C). */
- (id) initWithClass:(Class) class;
/*! Initialize a class wrapper for the named Objective-C class. */
- (id) initWithClassNamed:(NSString *) name;
/*! Get the class corresponding to the NuClass wrapper (used from Objective-C). */
- (Class) wrappedClass;
/*! Get an array of all classes known to the Objective-C runtime.
Beware, some of these classes may be deprecated, undocumented, or otherwise unsafe to use. */
+ (NSArray *) all;
/*! Get the name of a class. */
- (NSString *) name;
/*! Get an array containing NuMethod representations of the class methods of a class. */
- (NSArray *) classMethods;
/*! Get an array containing NuMethod representations of the instance methods of a class. */
- (NSArray *) instanceMethods;
/*! Get an array containing the names of the class methods of a class. */
- (NSArray *) classMethodNames;
/*! Get an array containing the names of the instance methods of a class. */
- (NSArray *) instanceMethodNames;
/*! Determine whether a class is derived from another class. */
- (BOOL) isDerivedFromClass:(Class) parent;
/*! Compare a class with another class by name.  This allows arrays of classes to be easily sorted. */
- (NSComparisonResult) compare:(NuClass *) anotherClass;
/*! Get a class method by name. */
- (NuMethod *) classMethodWithName:(NSString *) methodName;
/*! Get an instance method by name. */
- (NuMethod *) instanceMethodWithName:(NSString *) methodName;
/*! Compare two classes for equality. */
- (BOOL) isEqual:(NuClass *) anotherClass;
/*! Change the superclass of a class. Be careful with this. */
- (void) setSuperclass:(NuClass *) newSuperclass;
/*! Add an instance method to a class with the specified name, type signature, and body. */
- (id) addInstanceMethod:(NSString *) methodName signature:(NSString *)signature body:(NuBlock *) block;
/*! Add a class method to a class with the specified name, type signature, and body. */
- (id) addClassMethod:(NSString *) methodName signature:(NSString *)signature body:(NuBlock *) block;
/*! Add an instance variable to the receiving class. This will cause problems if there are already instances of the receiving class. */
- (id) addInstanceVariable:(NSString *)variableName signature:(NSString *) signature;

- (BOOL) isRegistered;
- (void) setRegistered:(BOOL) value;
- (void) registerClass;
@end

@class NuBlock;

id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block);
