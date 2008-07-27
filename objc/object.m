/*!
@file object.m
@description Nu extensions to NSObject.
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
#import "object.h"
#import "class.h"
#import "method.h"
#import "objc_runtime.h"
#import "bridge.h"
#import "extensions.h"

// use this to look up selectors with symbols
@interface NuSelectorCache : NSObject
{
    NuSymbol *symbol;
    NuSelectorCache *parent;
    NSMutableDictionary *children;
    SEL selector;
}

@end

@implementation NuSelectorCache

+ (NuSelectorCache *) sharedSelectorCache
{
    static NuSelectorCache *sharedCache = nil;
    if (!sharedCache)
        sharedCache = [[self alloc] init];
    return sharedCache;
}

- (NuSelectorCache *) init
{
    [super init];
    symbol = nil;
    parent = nil;
    children = [[NSMutableDictionary alloc] init];
    selector = NULL;
    return self;
}

- (NuSymbol *) symbol {return symbol;}
- (NuSelectorCache *) parent {return parent;}
- (NSMutableDictionary *) children {return children;}

- (SEL) selector
{
    return selector;
}

- (void) setSelector:(SEL) s
{
    selector = s;
}

- (NuSelectorCache *) initWithSymbol:(NuSymbol *)s parent:(NuSelectorCache *)p
{
    [super init];
    symbol = s;
    parent = p;
    children = [[NSMutableDictionary alloc] init];
    selector = NULL;
    return self;
}

- (NSString *) selectorName
{
    NSMutableArray *selectorStrings = [NSMutableArray array];
    #ifdef DARWIN
    [selectorStrings addObject:[[self symbol] stringValue]];
    id p = parent;
    while ([p symbol]) {
        [selectorStrings addObject:[[p symbol] stringValue]];
        p = [p parent];
    }
    int max = [selectorStrings count];
    int i;
    for (i = 0; i < max/2; i++) {
        [selectorStrings exchangeObjectAtIndex:i withObjectAtIndex:(max - i - 1)];
    }
    #else
    [selectorStrings insertObject:[[self symbol] stringValue] atIndex:0];
    id p = parent;
    while ([p symbol]) {
        [selectorStrings insertObject:[[p symbol] stringValue] atIndex:0];
        p = [p parent];
    }
    #endif
    return [selectorStrings componentsJoinedByString:@""];
}

- (NuSelectorCache *) lookupSymbol:(NuSymbol *)childSymbol
{
    NuSelectorCache *child = [children objectForKey:childSymbol];
    if (!child) {
        child = [[NuSelectorCache alloc] initWithSymbol:childSymbol parent:self];
        NSString *selectorString = [child selectorName];
        #ifdef DARWIN
        [child setSelector:sel_registerName([selectorString cStringUsingEncoding:NSUTF8StringEncoding])];
        #else
        [child setSelector:sel_register_name([selectorString cStringUsingEncoding:NSUTF8StringEncoding])];
        #endif
        [children setValue:child forKey:(id)childSymbol];
    }
    return child;
}

@end

@implementation NSObject(Nu)
- (bool) atom
{
    return true;
}

- (id) evalWithContext:(NSMutableDictionary *) context
{
    return self;
}

- (id) stringValue
{
    #ifdef DARWIN
    return [NSString stringWithFormat:@"<%s:%x>", class_getName(object_getClass(self)), (long) self];
    #else
    return [NSString stringWithFormat:@"<%s:%x>", class_get_class_name(object_get_class(self)), (long) self];
    #endif
}

- (id) car
{
    [NSException raise:@"NuCarCalledOnAtom"
        format:@"car called on atom for object %@",
        self];
    return Nu__null;
}

- (id) cdr
{
    [NSException raise:@"NuCdrCalledOnAtom"
        format:@"cdr called on atom for object %@",
        self];
    return Nu__null;
}

- (id) sendMessage:(id)cdr withContext:(NSMutableDictionary *)context
{
    // By themselves, Objective-C objects evaluate to themselves.
    if (!cdr || (cdr == Nu__null))
        return self;

    // But when they're at the head of a list, that list is converted into a message that is sent to the object.
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    // Collect the method selector and arguments.
    // This seems like a bottleneck, and it also lacks flexibility.
    // Replacing explicit string building with the selector cache reduced runtimes by around 20%.
    // Methods with variadic arguments (NSArray arrayWithObjects:...) are not supported.
    NSMutableArray *args = [[NSMutableArray alloc] init];
    id cursor = cdr;
    SEL sel = 0;
    id nextSymbol = [cursor car];
    if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class])) {
        // The commented out code below was the original approach.
        // methods were identified by concatenating symbols and looking up the resulting method -- on every method call
        // that was slow but simple
        // NSMutableString *selectorString = [NSMutableString stringWithString:[nextSymbol stringValue]];
        NuSelectorCache *selectorCache = [[NuSelectorCache sharedSelectorCache] lookupSymbol:nextSymbol];
        cursor = [cursor cdr];
        while (cursor && (cursor != Nu__null)) {
            [args addObject:[cursor car]];
            cursor = [cursor cdr];
            if (cursor && (cursor != Nu__null)) {
                id nextSymbol = [cursor car];
                if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class]) && [nextSymbol isLabel]) {
                    // [selectorString appendString:[nextSymbol stringValue]];
                    selectorCache = [selectorCache lookupSymbol:nextSymbol];
                }
                cursor = [cursor cdr];
            }
        }
        // sel = sel_getUid([selectorString cStringUsingEncoding:NSUTF8StringEncoding]);
        sel = [selectorCache selector];
    }

    id target = self;

    // Look up the appropriate method to call for the specified selector.
    #ifdef DARWIN
    Method m;
    #else
    Method_t m = 0;
    #endif
    #ifdef LINUX
    if (sel) {
        #endif
                                                  // instead of isMemberOfClass:, which may be blocked by an NSProtocolChecker
        BOOL isAClass = (self->isa == [NuClass class]) ? YES : NO;
        if (isAClass) {
            // Class wrappers (objects of type NuClass) get special treatment. Instance methods are sent directly to the class wrapper object.
            // But when a class method is sent to a class wrapper, the method is instead sent as a class method to the wrapped class.
            // This makes it possible to call class methods from Nu, but there is no way to directly call class methods of NuClass from Nu.
            id wrappedClass = [((NuClass *) self) wrappedClass];
            m = class_getClassMethod(wrappedClass, sel);
            if (m)
                target = wrappedClass;
            else
            #ifdef DARWIN
                m = class_getInstanceMethod(object_getClass(self), sel);
            #else
            m = class_get_instance_method(object_getClass(self), sel);
            #endif
        }
        else {
            #ifdef DARWIN
            m = class_getInstanceMethod(object_getClass(self), sel);
            #else
            m = class_get_instance_method(object_getClass(self), sel);
            #endif
            if (!m) m = class_getClassMethod(object_getClass(self), sel);
        }
        #ifdef LINUX
    }
    #endif
    id result = Nu__null;
    if (m) {
        // We have a method that matches the selector.
        // First, evaluate the arguments.
        NSMutableArray *argValues = [[NSMutableArray alloc] init];
        int i;
        int imax = [args count];
        for (i = 0; i < imax; i++) {
            [argValues addObject:[[args objectAtIndex:i] evalWithContext:context]];
        }
        // Then call the method.
        if (sel == @selector(animator)) {
            imax = 0;                             // break here
        }
        result = nu_calling_objc_method_handler(target, m, argValues);
        [argValues release];
    }
    else {
        // If the head of the list is a label, we treat the list as a property list.
        // We just evaluate the elements of the list and return the result.
        if (nu_objectIsKindOfClass(self, [NuSymbol class]) && [((NuSymbol *)self) isLabel]) {
            NuCell *cell = [[NuCell alloc] init];
            [cell setCar: self];
            id cursor = cdr;
            id result_cursor = cell;
            while (cursor && (cursor != Nu__null)) {
                id arg = [[cursor car] evalWithContext:context];
                [result_cursor setCdr:[[[NuCell alloc] init] autorelease]];
                result_cursor = [result_cursor cdr];
                [result_cursor setCar:arg];
                cursor = [cursor cdr];
            }
            result = cell;
        }
        // Messaging null is ok.
        else if (self == Nu__null) {
        }
        // Otherwise, call the overridable handler for unknown messages.
        else {
            //NSLog(@"calling handle unknown message for %@", [cdr stringValue]);
            result = [self handleUnknownMessage:cdr withContext:context];
            //NSLog(@"result is %@", result);
        }
    }

    [args release];
    [result retain];
    [pool release];
    [result autorelease];
    return result;
}

- (id) evalWithArguments:(id)cdr context:(NSMutableDictionary *)context
{
    return [self sendMessage:cdr withContext:context];
}

+ (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context
{
    [NSException raise:@"NuUnknownMessage"
        format:@"unable to find message handler for %@",
        [cdr stringValue]];
    return Nu__null;
}

- (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context
{
    // Collect the method selector and arguments.
    // This seems like a bottleneck, and it also lacks flexibility.
    // Replacing explicit string building with the selector cache reduced runtimes by around 20%.
    // Methods with variadic arguments (NSArray arrayWithObjects:...) are not supported.
    NSMutableArray *args = [[NSMutableArray alloc] init];
    id cursor = cdr;
    SEL sel = 0;
    id nextSymbol = [cursor car];
    if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class])) {
        // The commented out code below was the original approach.
        // methods were identified by concatenating symbols and looking up the resulting method -- on every method call
        // that was slow but simple
        // NSMutableString *selectorString = [NSMutableString stringWithString:[nextSymbol stringValue]];
        NuSelectorCache *selectorCache = [[NuSelectorCache sharedSelectorCache] lookupSymbol:nextSymbol];
        cursor = [cursor cdr];
        while (cursor && (cursor != Nu__null)) {
            [args addObject:[cursor car]];
            cursor = [cursor cdr];
            if (cursor && (cursor != Nu__null)) {
                id nextSymbol = [cursor car];
                if (nu_objectIsKindOfClass(nextSymbol, [NuSymbol class]) && [nextSymbol isLabel]) {
                    // [selectorString appendString:[nextSymbol stringValue]];
                    selectorCache = [selectorCache lookupSymbol:nextSymbol];
                }
                cursor = [cursor cdr];
            }
        }
        // sel = sel_getUid([selectorString cStringUsingEncoding:NSUTF8StringEncoding]);
        sel = [selectorCache selector];
    }

    // If the object responds to methodSignatureForSelector:, we should create and forward an invocation to it.
    NSMethodSignature *methodSignature = sel ? [self methodSignatureForSelector:sel] : 0;
    if (methodSignature) {
        id result = [NSNull null];
        // Create an invocation to forward.
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
        [invocation setTarget:self];
        [invocation setSelector:sel];
        // Set any arguments to the invocation.
        int i;
        int imax = [args count];
        for (i = 0; i < imax; i++) {
            const char *argument_type = [methodSignature getArgumentTypeAtIndex:i+2];
            char *buffer = value_buffer_for_objc_type(argument_type);
            set_objc_value_from_nu_value(buffer, [[args objectAtIndex:i] evalWithContext:context], argument_type);
            [invocation setArgument:buffer atIndex:i+2];
            free(buffer);
        }
        // Forward the invocation.
        [self forwardInvocation:invocation];
        // Get the return value from the invocation.
        unsigned int length = [[invocation methodSignature] methodReturnLength];
        if (length > 0) {
            char *buffer = (void *)malloc(length);
            [invocation getReturnValue:buffer];
            result = get_nu_value_from_objc_value(buffer, [methodSignature methodReturnType]);
            free(buffer);
        }
        return result;
    }

    NuCell *cell = [[[NuCell alloc] init] autorelease];
    [cell setCar: self];
    [cell setCdr: cdr];
    [NSException raise:@"NuUnknownMessage"
        format:@"unable to find message handler for %@",
        [cell stringValue]];
    return Nu__null;
}

- (id) valueForIvar:(NSString *) name
{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        // look for sparse ivar storage
        Ivar __ivars = class_getInstanceVariable([self class], "__nuivars");
        if (__ivars) {
            NSMutableDictionary *sparseIvars = [self valueForIvar:@"__nuivars"];
            if (sparseIvars && (sparseIvars != Nu__null)) {
                id result = [sparseIvars objectForKey:name];
                return result;
            }
        }
        [NSException raise:@"NuNoInstanceVariable"
            format:@"Unable to get ivar named %@ for object %@",
            name, self];

        return Nu__null;
    }
    void *location = (void *)&(((char *)self)[ivar_getOffset(v)]);
    id result = get_nu_value_from_objc_value(location, ivar_getTypeEncoding(v));
    return result;
}

- (void) setValue:(id) value forIvar:(NSString *)name
{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        // look for sparse ivar storage
        Ivar __ivars = class_getInstanceVariable([self class], "__nuivars");
        if (__ivars) {
            NSMutableDictionary *sparseIvars = [self valueForIvar:@"__nuivars"];
            //NSLog(@"get sparse ivars dictionary: %@", sparseIvars);
            if (!sparseIvars || (sparseIvars == Nu__null)) {
                //NSLog(@"creating new sparse ivars dictionary");
                sparseIvars = [[[NSMutableDictionary alloc] init] autorelease];
                //NSLog(@"setting sparse ivars dictionary: %@", sparseIvars);
                [self setValue:sparseIvars forIvar:@"__nuivars"];
            }
            [self willChangeValueForKey:name];
            [sparseIvars setPossiblyNullObject:value forKey:name];
            [self didChangeValueForKey:name];
            return;
        }
        [NSException raise:@"NuNoInstanceVariable"
            format:@"Unable to set ivar named %@ for object %@",
            name, self];
        return;
    }
    [self willChangeValueForKey:name];
    void *location = (void *)&(((char *)self)[ivar_getOffset(v)]);
    const char *encoding = ivar_getTypeEncoding(v);
    if (encoding && (strlen(encoding) > 0) && (encoding[0] == '@')) {
        [value retain];
        [*((id *)location) release];
    }
    set_objc_value_from_nu_value(location, value, ivar_getTypeEncoding(v));
    [self didChangeValueForKey:name];
}

- (void) nuDealloc
{
    NSArray *ivarsToRelease = nu_ivarsToRelease([self class]);
    if (ivarsToRelease) {
        int count = [ivarsToRelease count];
        for (int i = 0; i < count; i++) {
            NSString *ivarName = [ivarsToRelease objectAtIndex:i];
            Ivar ivar = class_getInstanceVariable([self class], [ivarName cStringUsingEncoding:NSUTF8StringEncoding]);
            if (ivar) {
                // NSLog(@"releasing ivar %@", ivarName);
                void *location = (void *)&(((char *)self)[ivar_getOffset(ivar)]);
                [*((id *)location) release];
            }
        }
    }
    [self nuDealloc];
}

+ (NSArray *) classMethods
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int method_count;
    #ifdef DARWIN
    Method *method_list = class_copyMethodList(object_getClass([self class]), &method_count);
    #else
    Method_t *method_list = class_copyMethodList(object_getClass([self class]), &method_count);
    #endif
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[NuMethod alloc] initWithMethod:method_list[i]]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSArray *) instanceMethods
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int method_count;
    #ifdef DARWIN
    Method *method_list = class_copyMethodList([self class], &method_count);
    #else
    Method_t *method_list = class_copyMethodList([self class], &method_count);
    #endif
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[NuMethod alloc] initWithMethod:method_list[i]]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSArray *) classMethodNames
{
    Class c = [self class];
    return [[c classMethods] mapSelector:@selector(name)];
}

+ (NSArray *) instanceMethodNames
{
    Class c = [self class];
    return [[c instanceMethods] mapSelector:@selector(name)];
}

+ (NSArray *) instanceVariableNames
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int ivar_count;
    Ivar *ivar_list = class_copyIvarList([self class], &ivar_count);
    int i;
    for (i = 0; i < ivar_count; i++) {
        [array addObject:[NSString stringWithCString:ivar_getName(ivar_list[i]) encoding:NSUTF8StringEncoding]];
    }
    free(ivar_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSString *) signatureForIvar:(NSString *)name
{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    return [NSString stringWithCString:ivar_getTypeEncoding(v) encoding:NSUTF8StringEncoding];
}

+ (id) inheritedByClass:(NuClass *) newClass
{
    return nil;
}

+ (id) createSubclassNamed:(NSString *) subclassName
{
    Class c = [self class];
    const char *name = [subclassName cStringUsingEncoding:NSUTF8StringEncoding];

    // does the class already exist?
    Class s = objc_getClass(name);
    if (s) {
        // the subclass's superclass must be the current class!
        if (c != [s superclass]) {
            #ifdef DARWIN
            NSLog(@"Warning: Class %s already exists and is not a subclass of %s", name, class_getName(c));
            #else
            NSLog(@"Warning: Class %s already exists and is not a subclass of %s", name, class_get_class_name(c));
            #endif
        }
    }
    else {
        s = objc_allocateClassPair(c, name, 0);
        objc_registerClassPair(s);
    }
    NuClass *newClass = [[NuClass alloc] initWithClass:s];

    if ([self respondsToSelector:@selector(inheritedByClass:)]) {
        [self inheritedByClass:newClass];
    }

    return newClass;
}

/*
+ (id) addInstanceMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block
{
    Class c = [self class];
    return add_method_to_class(c, methodName, signature, block);
}

+ (id) addClassMethod:(NSString *)methodName signature:(NSString *)signature body:(NuBlock *)block
{
    Class c = [self class]->isa;
    return add_method_to_class(c, methodName, signature, block);
}
*/
+ (BOOL) copyInstanceMethod:(NSString *) methodName fromClass:(NuClass *)prototypeClass
{
    Class thisClass = [self class];
    Class otherClass = [prototypeClass wrappedClass];
    const char *method_name_str = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    #ifdef DARWIN
    SEL selector = sel_registerName(method_name_str);
    #else
    SEL selector = sel_register_name(method_name_str);
    #endif
    BOOL result = nu_copyInstanceMethod(thisClass, otherClass, selector);
    return result;
}

+ (BOOL) include:(NuClass *)prototypeClass
{
    NSArray *methods = [prototypeClass instanceMethods];
    NSEnumerator *enumerator = [methods objectEnumerator];
    id method;
    while ((method = [enumerator nextObject])) {
        // NSLog(@"copying method %@", [method name]);
        [self copyInstanceMethod:[method name] fromClass:prototypeClass];
    }
    return true;
}

/*
+ (id) addInstanceVariable:(NSString *)variableName signature:(NSString *)signature
{
    Class thisClass = [self class];
    size_t size_of_objc_type(const char *typeString);

    class_addInstanceVariable_withSignature(thisClass, [variableName cStringUsingEncoding:NSUTF8StringEncoding], [signature cStringUsingEncoding:NSUTF8StringEncoding]);

    return Nu__null;
}
*/

+ (NSString *) help
{
    #ifdef DARWIN
    return [NSString stringWithFormat:@"This is a class named %s.", class_getName([self class])];
    #else
    return [NSString stringWithFormat:@"This is a class named %s.", class_get_class_name([self class])];
    #endif
}

- (NSString *) help
{
    #ifdef DARWIN
    return [NSString stringWithFormat:@"This is an instance of %s.", class_getName([self class])];
    #else
    return [NSString stringWithFormat:@"This is an instance of %s.", class_get_class_name([self class])];
    #endif
}

// adapted from the CocoaDev MethodSwizzling page

+ (BOOL) exchangeInstanceMethod:(SEL)sel1 withMethod:(SEL)sel2
{
    Class myClass = [self class];
    #ifdef DARWIN
    Method method1 = NULL, method2 = NULL;
    #else
    Method_t method1 = NULL, method2 = NULL;
    #endif

    // First, look for the methods
    #ifdef DARWIN
    method1 = class_getInstanceMethod(myClass, sel1);
    method2 = class_getInstanceMethod(myClass, sel2);
    #else
    method1 = class_get_instance_method(myClass, sel1);
    method2 = class_get_instance_method(myClass, sel2);
    #endif
    // If both are found, swizzle them
    if ((method1 != NULL) && (method2 != NULL)) {
        method_exchangeImplementations(method1, method2);
        return true;
    }
    else {
        #ifdef DARWIN
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
        #else
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_get_name(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_get_name(sel2));
        #endif
        return false;
    }

    return YES;
}

+ (BOOL) exchangeClassMethod:(SEL)sel1 withMethod:(SEL)sel2
{
    Class myClass = [self class];
    #ifdef DARWIN
    Method method1 = NULL, method2 = NULL;
    #else
    Method_t method1 = NULL, method2 = NULL;
    #endif

    // First, look for the methods
    method1 = class_getClassMethod(myClass, sel1);
    method2 = class_getClassMethod(myClass, sel2);

    // If both are found, swizzle them
    if ((method1 != NULL) && (method2 != NULL)) {
        method_exchangeImplementations(method1, method2);
        return true;
    }
    else {
        #ifdef DARWIN
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
        #else
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_get_name(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_get_name(sel2));
        #endif
        return false;
    }

    return YES;
}

// Concisely set key-value pairs from a property list.
- (id) set:(NuCell *) propertyList
{
    id cursor = propertyList;
    while (cursor && (cursor != Nu__null) && ([cursor cdr]) && ([cursor cdr] != Nu__null)) {
        id key = [cursor car];
        id value = [[cursor cdr] car];
        id label = ([key isKindOfClass:[NuSymbol class]] && [key isLabel]) ? [key labelName] : key;
        if ([label isEqualToString:@"action"] && [self respondsToSelector:@selector(setAction:)]) {
            #ifdef DARWIN
            SEL selector = sel_registerName([value cStringUsingEncoding:NSUTF8StringEncoding]);
            #else
            SEL selector = sel_register_name([value cStringUsingEncoding:NSUTF8StringEncoding]);
            #endif
            [self setAction:selector];
        }
        else {
            [self setValue:value forKey:label];
        }
        cursor = [[cursor cdr] cdr];
    }
    return self;
}

@end
