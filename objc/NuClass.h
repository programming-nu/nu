//
//  NuClass.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

@class NuBlock;
@class NuMethod;

/*!
 @class NuClass
 @abstract A Nu wrapper for class representations in the Objective-C runtime.
 @discussion NuClass provides an object wrapper for classes that are represented in the Objective-C runtime.
 NuClass objects are used in the Nu language to manipulate and extend Objective-C classes.
 */
@interface NuClass : NSObject

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
