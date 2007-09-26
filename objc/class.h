/*!
    @header class.h
  	@copyright Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.
  	@discussion Declarations for the NuClass class,
 	which represents classes in the Objective-C runtime.
*/
#import <Foundation/Foundation.h>

@class NuMethod;

/*!
	@class NuClass
    @abstract A Nu wrapper for class representations in the Objective-C runtime.
    @discussion NuClass provides an object wrapper for classes that are represented in the Objective-C runtime.
    NuClass objects are used in the Nu language to manipulate and extend Objective-C classes.
 */
@interface NuClass : NSObject
{
	Class c;
}
/*! Create a class wrapper for the named Objective-C class. */
+ (Class) classWithName:(NSString *)string;
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
/*! Determine whether a class is derived from another class. */
- (BOOL) isDerivedFromClass:(Class) parent;
/*! Compare a class with another class by name.  This allows arrays of classes to be easily sorted. */
- (NSComparisonResult) compare:(NuClass *) anotherClass;
/*! Get a class method by name. */
- (NuMethod *) classMethodWithName:(NSString *) methodName;
/*! Get an instance method by name. */
- (NuMethod *) instanceMethodWithName:(NSString *) methodName;
@end

@class NuBlock;

id add_method_to_class(Class c, NSString *methodName, NSString *signature, NuBlock *block);
