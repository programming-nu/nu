/*!
 @file NuObject.m
 @description Nu extensions to NSObject.
 @copyright Copyright (c) 2007 Radtastical Inc.
 
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
#import "NuObject.h"
#import "NuClass.h"
#import "NuMethod.h"
#import "NuObjCRuntime.h"
#import "NuBridge.h"
#import "NuExtensions.h"
#import "NuEnumerable.h"

@protocol NuCanSetAction
- (void) setAction:(SEL) action;
@end

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
    if ((self = [super init])) {
        symbol = nil;
        parent = nil;
        children = [[NSMutableDictionary alloc] init];
        selector = NULL;
    }
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
    if ((self = [super init])) {
        symbol = s;
        parent = p;
        children = [[NSMutableDictionary alloc] init];
        selector = NULL;
    }
    return self;
}

- (NSString *) selectorName
{
    NSMutableArray *selectorStrings = [NSMutableArray array];
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
    return [selectorStrings componentsJoinedByString:@""];
}

- (NuSelectorCache *) lookupSymbol:(NuSymbol *)childSymbol
{
    NuSelectorCache *child = [children objectForKey:childSymbol];
    if (!child) {
        child = [[[NuSelectorCache alloc] initWithSymbol:childSymbol parent:self] autorelease];
        NSString *selectorString = [child selectorName];
        [child setSelector:sel_registerName([selectorString cStringUsingEncoding:NSUTF8StringEncoding])];
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

- (NSString *) stringValue
{
    return [NSString stringWithFormat:@"<%s:%x>", class_getName(object_getClass(self)), (long) self];
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
    Method m;
    // instead of isMemberOfClass:, which may be blocked by an NSProtocolChecker
    BOOL isAClass = (object_getClass(self) == [NuClass class]);
    if (isAClass) {
        // Class wrappers (objects of type NuClass) get special treatment. Instance methods are sent directly to the class wrapper object.
        // But when a class method is sent to a class wrapper, the method is instead sent as a class method to the wrapped class.
        // This makes it possible to call class methods from Nu, but there is no way to directly call class methods of NuClass from Nu.
        id wrappedClass = [((NuClass *) self) wrappedClass];
        m = class_getClassMethod(wrappedClass, sel);
        if (m)
            target = wrappedClass;
        else
            m = class_getInstanceMethod(object_getClass(self), sel);
    }
    else {
        m = class_getInstanceMethod(object_getClass(self), sel);
        if (!m) m = class_getClassMethod(object_getClass(self), sel);
    }
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
        result = nu_calling_objc_method_handler(target, m, argValues);
        [argValues release];
    }
    else {
        // If the head of the list is a label, we treat the list as a property list.
        // We just evaluate the elements of the list and return the result.
        if (nu_objectIsKindOfClass(self, [NuSymbol class]) && [((NuSymbol *)self) isLabel]) {
            NuCell *cell = [[[NuCell alloc] init] autorelease];
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
        else if ( (target = [target forwardingTargetForSelector:sel]) ) {
            //NSLog(@"found forwarding target: %@ for selector: %@", target, NSStringFromSelector(sel));
            result = [target sendMessage:cdr withContext:context];
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
    [pool drain];
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


- (id) handleUnknownMessage:(id) message withContext:(NSMutableDictionary *) context
{
    // Collect the method selector and arguments.
    // This seems like a bottleneck, and it also lacks flexibility.
    // Replacing explicit string building with the selector cache reduced runtimes by around 20%.
    // Methods with variadic arguments (NSArray arrayWithObjects:...) are not supported.
    NSMutableArray *args = [NSMutableArray array];
    id cursor = message;
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
    
#define AUTOMATIC_IVAR_ACCESSORS
#ifdef AUTOMATIC_IVAR_ACCESSORS
    //NSLog(@"attempting to access ivar %@", [message stringValue]);
    int message_length = [message length];
    if (message_length == 1) {
        // try to automatically get an ivar
        NSString *ivarName = [[message car] stringValue];
        if ([self hasValueForIvar:ivarName]) {
            id result = [self valueForIvar:ivarName];
            return result;
        }
    }
    else if (message_length == 2) {
        // try to automatically set an ivar
        if ([[[[message car] stringValue] substringWithRange:NSMakeRange(0,3)] isEqualToString:@"set"]) {
            @try
            {
                id firstArgument = [[message car] stringValue];
                id variableName0 = [[firstArgument substringWithRange:NSMakeRange(3,1)] lowercaseString];
                id variableName1 = [firstArgument substringWithRange:NSMakeRange(4, [firstArgument length] - 5)];
                [self setValue:[[[message cdr] car] evalWithContext:context]
                       forIvar:[NSString stringWithFormat:@"%@%@", variableName0, variableName1]];
                return Nu__null;
            }
            @catch (id error) {
                // NSLog(@"skipping this error: %@", [error description]);
                // no ivar, keep going
            }
        }
    }
#endif
    NuCell *cell = [[[NuCell alloc] init] autorelease];
    [cell setCar:self];
    [cell setCdr:message];
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
        NSMutableDictionary *sparseIvars = [self associatedObjectForKey:@"__nuivars"];
        if (sparseIvars) {
            // NSLog(@"sparse %@", [sparseIvars description]);
            id result = [sparseIvars objectForKey:name];
            if (result) {
                return result;
            } else {
                return Nu__null;
            }
        }        
        return Nu__null;
    }
    void *location = (void *)&(((char *)self)[ivar_getOffset(v)]);
    id result = get_nu_value_from_objc_value(location, ivar_getTypeEncoding(v));
    return result;
}

- (BOOL) hasValueForIvar:(NSString *) name
{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        // look for sparse ivar storage
        NSMutableDictionary *sparseIvars = [self associatedObjectForKey:@"__nuivars"];
        if (sparseIvars) {
            // NSLog(@"sparse %@", [sparseIvars description]);
            id result = [sparseIvars objectForKey:name];
            if (result) {
                return YES;
            } else {
                return NO;
            }
        }        
        return NO;
    }
    //void *location = (void *)&(((char *)self)[ivar_getOffset(v)]);
    //id result = get_nu_value_from_objc_value(location, ivar_getTypeEncoding(v));
    return YES;
}


- (void) setValue:(id) value forIvar:(NSString *)name
{
    Ivar v = class_getInstanceVariable([self class], [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        NSMutableDictionary *sparseIvars = [self associatedObjectForKey:@"__nuivars"];
        if (!sparseIvars) {
            sparseIvars = [[[NSMutableDictionary alloc] init] autorelease];
            [self setRetainedAssociatedObject:sparseIvars forKey:@"__nuivars"];
        }
        [self willChangeValueForKey:name];
        [sparseIvars setPossiblyNullObject:value forKey:name];
        [self didChangeValueForKey:name];
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

+ (NSArray *) classMethods
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList(object_getClass([self class]), &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSArray *) instanceMethods
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned int method_count;
    Method *method_list = class_copyMethodList([self class], &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[[NuMethod alloc] initWithMethod:method_list[i]] autorelease]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSArray *) classMethodNames
{
    Class c = [self class];
    id methods = [c classMethods];
    return [methods mapSelector:@selector(name)];
    //    return [[c classMethods] mapSelector:@selector(name)];
}

+ (NSArray *) instanceMethodNames
{
    Class c = [self class];
    id methods = [c instanceMethods];
    return [methods mapSelector:@selector(name)];
    //    return [[c instanceMethods] mapSelector:@selector(name)];
}

+ (NSArray *) instanceVariableNames
{
    NSMutableArray *array = [NSMutableArray array];
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
            NSLog(@"Warning: Class %s already exists and is not a subclass of %s", name, class_getName(c));
        }
    }
    else {
        s = objc_allocateClassPair(c, name, 0);
        objc_registerClassPair(s);
    }
    NuClass *newClass = [[[NuClass alloc] initWithClass:s] autorelease];
    
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
    SEL selector = sel_registerName(method_name_str);
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

+ (NSString *) help
{
    return [NSString stringWithFormat:@"This is a class named %s.", class_getName([self class])];
}

- (NSString *) help
{
    return [NSString stringWithFormat:@"This is an instance of %s.", class_getName([self class])];
}

// adapted from the CocoaDev MethodSwizzling page

+ (BOOL) exchangeInstanceMethod:(SEL)sel1 withMethod:(SEL)sel2
{
    Class myClass = [self class];
    Method method1 = NULL, method2 = NULL;
    
    // First, look for the methods
    method1 = class_getInstanceMethod(myClass, sel1);
    method2 = class_getInstanceMethod(myClass, sel2);
    // If both are found, swizzle them
    if ((method1 != NULL) && (method2 != NULL)) {
        method_exchangeImplementations(method1, method2);
        return true;
    }
    else {
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
        return false;
    }
    
    return YES;
}

+ (BOOL) exchangeClassMethod:(SEL)sel1 withMethod:(SEL)sel2
{
    Class myClass = [self class];
    Method method1 = NULL, method2 = NULL;
    
    // First, look for the methods
    method1 = class_getClassMethod(myClass, sel1);
    method2 = class_getClassMethod(myClass, sel2);
    
    // If both are found, swizzle them
    if ((method1 != NULL) && (method2 != NULL)) {
        method_exchangeImplementations(method1, method2);
        return true;
    }
    else {
        if (method1 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == NULL) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
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
            SEL selector = sel_registerName([value cStringUsingEncoding:NSUTF8StringEncoding]);
            [(id<NuCanSetAction>) self setAction:selector];
        }
        else {
            [self setValue:value forKey:label];
        }
        cursor = [[cursor cdr] cdr];
    }
    return self;
}

- (void) setRetainedAssociatedObject:(id) object forKey:(id) key {
    if ([key isKindOfClass:[NSString class]]) 
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_RETAIN);
}

- (void) setAssignedAssociatedObject:(id) object forKey:(id) key {
    if ([key isKindOfClass:[NSString class]]) 
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_ASSIGN);
}

- (void) setCopiedAssociatedObject:(id) object forKey:(id) key {
    if ([key isKindOfClass:[NSString class]]) 
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    objc_setAssociatedObject(self, key, object, OBJC_ASSOCIATION_COPY);
}

- (id) associatedObjectForKey:(id) key {
    if ([key isKindOfClass:[NSString class]]) 
        key = [[NuSymbolTable sharedSymbolTable] symbolWithString:key];
    return objc_getAssociatedObject(self, key);
}

- (void) removeAssociatedObjects {
    objc_removeAssociatedObjects(self);
}

@end
