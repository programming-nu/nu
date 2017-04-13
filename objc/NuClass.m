//
//  NuClass.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuClass.h"
#import "NuInternals.h"

#import "NuProperty.h"
#import "NuEnumerable.h"
#import "NuMethod.h"

#pragma mark - NuClass.m

// getting a specific method...
// (set x (((Convert classMethods) select: (do (m) (eq (m name) "passRect:"))) objectAtIndex:0))

@interface NuClass ()
{
    Class c;
    BOOL isRegistered;
}
@end

@implementation NuClass

+ (NuClass *) classWithName:(NSString *)string
{
    const char *name = [string UTF8String];
    Class class = objc_getClass(name);
    if (class) {
        return [[[self alloc] initWithClass:class] autorelease];
    }
    else {
        return nil;
    }
}

+ (NuClass *) classWithClass:(Class) class
{
    if (class) {
        return [[[self alloc] initWithClass:class] autorelease];
    }
    else {
        return nil;
    }
}

- (id) initWithClassNamed:(NSString *) string
{
    const char *name = [string UTF8String];
    Class class = objc_getClass(name);
    return [self initWithClass: class];
}

- (id) initWithClass:(Class) class
{
    if ((self = [super init])) {
        c = class;
        isRegistered = YES;                           // unless we explicitly set otherwise
    }
    return self;
}

+ (NSArray *) all
{
    NSMutableArray *array = [NSMutableArray array];
    int numClasses = objc_getClassList(NULL, 0);
    if(numClasses > 0) {
        Class *classes = (Class *) malloc( sizeof(Class) * numClasses );
        objc_getClassList(classes, numClasses);
        int i = 0;
        while (i < numClasses) {
            NuClass *class = [[[NuClass alloc] initWithClass:classes[i]] autorelease];
            [array addObject:class];
            i++;
        }
        free(classes);
    }
    return array;
}

- (NSString *) name
{
    //	NSLog(@"calling NuClass name for object %@", self);
    return [NSString stringWithCString:class_getName(c) encoding:NSUTF8StringEncoding];
}

- (NSString *) stringValue
{
    return [self name];
}

- (Class) wrappedClass
{
    return c;
}

- (NSArray *) classMethods
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList(object_getClass([self wrappedClass]), &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

- (NSArray *) instanceMethods
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList([self wrappedClass], &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

/*! Get an array containing the names of the class methods of a class. */
- (NSArray *) classMethodNames
{
    id methods = [self classMethods];
    return [methods mapSelector:@selector(name)];
}

/*! Get an array containing the names of the instance methods of a class. */
- (NSArray *) instanceMethodNames
{
    id methods = [self instanceMethods];
    return [methods mapSelector:@selector(name)];
}

- (BOOL) isDerivedFromClass:(Class) parent
{
    Class myclass = [self wrappedClass];
    if (myclass == parent)
        return true;
    Class superclass = [myclass superclass];
    if (superclass)
        return nu_objectIsKindOfClass(superclass, parent);
    return false;
}

- (NSComparisonResult) compare:(NuClass *) anotherClass
{
    return [[self name] compare:[anotherClass name]];
}

- (NuMethod *) classMethodWithName:(NSString *) methodName
{
    const char *methodNameString = [methodName UTF8String];
    NuMethod *method = Nu__null;
    unsigned int method_count;
    Method *method_list = class_copyMethodList(object_getClass([self wrappedClass]), &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        if (!strcmp(methodNameString, sel_getName(method_getName(method_list[i])))) {
            method = [[[NuMethod alloc] initWithMethod:method_list[i]] autorelease];
        }
    }
    free(method_list);
    return method;
}

- (NuMethod *) instanceMethodWithName:(NSString *) methodName
{
    const char *methodNameString = [methodName UTF8String];
    NuMethod *method = Nu__null;
    unsigned int method_count;
    Method *method_list = class_copyMethodList([self wrappedClass], &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        if (!strcmp(methodNameString, sel_getName(method_getName(method_list[i])))) {
            method = [[[NuMethod alloc] initWithMethod:method_list[i]] autorelease];
        }
    }
    free(method_list);
    return method;
}

- (id) addInstanceMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block
{
    //NSLog(@"adding instance method %@", methodName);
    return add_method_to_class(c, methodName, signature, block);
}

- (id) addClassMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block
{
    NSLog(@"adding class method %@", methodName);
    return add_method_to_class(object_getClass(c), /* c->isa, */ methodName, signature, block);
}

- (id) addInstanceVariable:(NSString *)variableName signature:(NSString *)signature
{
    //NSLog(@"adding instance variable %@", variableName);
    nu_class_addInstanceVariable_withSignature(c, [variableName UTF8String], [signature UTF8String]);
    return Nu__null;
}

- (BOOL) isEqual:(NuClass *) anotherClass
{
    return c == anotherClass->c;
}

- (void) setSuperclass:(NuClass *) newSuperclass
{
    struct nu_objc_class
    {
        Class isa;
        Class super_class;
        // other stuff...
    };
    ((struct nu_objc_class *) self->c)->super_class = newSuperclass->c;
}

- (BOOL) isRegistered
{
    return isRegistered;
}

- (void) setRegistered:(BOOL) value
{
    isRegistered = value;
}

- (void) registerClass
{
    if (isRegistered == NO) {
        objc_registerClassPair(c);
        isRegistered = YES;
		if ([class_getSuperclass(self->c) respondsToSelector:@selector(inheritedByClass:)]) {
			[class_getSuperclass(self->c) inheritedByClass:self];
		}
    }
}

- (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context
{
    return [[self wrappedClass] handleUnknownMessage:cdr withContext:context];
}

- (NSArray *) instanceVariableNames {
    NSMutableArray *names = [NSMutableArray array];
    
    unsigned int ivarCount = 0;
    // Ivar *ivarList = class_copyIvarList(c, &ivarCount);
    
    NSLog(@"%d ivars", ivarCount);
    return names;
}

- (BOOL) addPropertyWithName:(NSString *) name {
    const objc_property_attribute_t attributes[10];
    unsigned int attributeCount = 0;
    return class_addProperty(c, [name UTF8String],
                             attributes,
                             attributeCount);
}

- (NuProperty *) propertyWithName:(NSString *) name {
    objc_property_t property = class_getProperty(c, [name UTF8String]);
    
    return [NuProperty propertyWithProperty:(objc_property_t) property];
}

- (NSArray *) properties {
    unsigned int property_count;
    objc_property_t *property_list = class_copyPropertyList(c, &property_count);
    
    NSMutableArray *properties = [NSMutableArray array];
    for (int i = 0; i < property_count; i++) {
        [properties addObject:[NuProperty propertyWithProperty:property_list[i]]];
    }
    free(property_list);
    return properties;
}

//OBJC_EXPORT objc_property_t class_getProperty(Class cls, const char *name)


@end
