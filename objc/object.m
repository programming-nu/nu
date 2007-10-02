// object.m
//  Nu extensions to NSObject.
//
//  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

#import "object.h"
#import "class.h"
#import "method.h"
#import "objc_runtime.h"
#import "bridge.h"

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
    selector = nil;
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
    selector = nil;
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
        child = [[NuSelectorCache alloc] initWithSymbol:childSymbol parent:self];
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

- (id) stringValue
{
    return [NSString stringWithFormat:@"<%s:%x>", [self class]->name, (long) self];
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
    if ([nextSymbol isKindOfClass:[NuSymbol class]]) {
        // The commented out code below was the original approach.
        // methods were identified by concatenatig symbols and looking up the resulting method -- on every method call
        // that was slow but simple
        // NSMutableString *selectorString = [NSMutableString stringWithString:[nextSymbol stringValue]];
        NuSelectorCache *selectorCache = [[NuSelectorCache sharedSelectorCache] lookupSymbol:nextSymbol];
        cursor = [cursor cdr];
        while (cursor && (cursor != Nu__null)) {
            [args addObject:[cursor car]];
            cursor = [cursor cdr];
            if (cursor && (cursor != Nu__null)) {
                id nextSymbol = [cursor car];
                if ([nextSymbol isKindOfClass:[NuSymbol class]] && [nextSymbol isLabel]) {
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
    if ([self isMemberOfClass:[NuClass class]]) {
        // Class wrappers (objects of type NuClass) get special treatment. Instance methods are sent directly to the class wrapper object.
        // But when a class method is sent to a class wrapper, the method is instead sent as a class method to the wrapped class.
        // This makes it possible to call class methods from Nu, but there is no way to directly call class methods of NuClass from Nu.
        id wrappedClass = [((NuClass *) self) wrappedClass];
        m = class_getClassMethod(wrappedClass, sel);
        if (m)
            target = wrappedClass;
        else
            m = class_getInstanceMethod([self class], sel);
    }
    else {
        m = class_getInstanceMethod([self class], sel);
        if (!m) m = class_getClassMethod([self class], sel);
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
        // There is no method that matches the selector.
        if ([self isKindOfClass: [NuSymbol class]] && [((NuSymbol *)self) isLabel]) {
            // If the head of the list is a label, we treat the list as a property list.
            // We just evaluate the elements of the list and return the result.
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
        else if (self == Nu__null) {
            // Messaging null is ok.
        }
        else {
            result = [self handleUnknownMessage:cdr withContext:context];
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

- (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context
{
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
    Ivar v = object_findInstanceVariable(self, [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        // look for sparse ivar storage
        Ivar __ivars = object_findInstanceVariable(self, "__nuivars");
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
    void *location = (void *)&(((char *)self)[v->ivar_offset]);
    id result = get_nu_value_from_objc_value(location, v->ivar_type);
    return result;
}

- (void) setValue:(id) value forIvar:(NSString *)name
{
    Ivar v = object_findInstanceVariable(self, [name cStringUsingEncoding:NSUTF8StringEncoding]);
    if (!v) {
        // look for sparse ivar storage
        Ivar __ivars = object_findInstanceVariable(self, "__nuivars");
        if (__ivars) {
            NSMutableDictionary *sparseIvars = [self valueForIvar:@"__nuivars"];
            //NSLog(@"get sparse ivars dictionary: %@", sparseIvars);
            if (!sparseIvars || (sparseIvars == Nu__null)) {
                //NSLog(@"creating new sparse ivars dictionary");
                sparseIvars = [[NSMutableDictionary alloc] init];
                //NSLog(@"setting sparse ivars dictionary: %@", sparseIvars);
                [self setValue:sparseIvars forIvar:@"__nuivars"];
            }
            [sparseIvars setObject:value forKey:name];
            return;
        }
        [NSException raise:@"NuNoInstanceVariable"
            format:@"Unable to set ivar named %@ for object %@",
            name, self];
        return;
    }
    void *location = (void *)&(((char *)self)[v->ivar_offset]);
    if (!strcmp(v->ivar_type, "@")) {
        [value retain];
        [*((id *)location) release];
    }
    set_objc_value_from_nu_value(location, value, v->ivar_type);
}

+ (NSArray *) classMethods
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int method_count;
    Method *method_list = class_copyMethodList(object_getClass([self class]), &method_count);
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
    Method *method_list = class_copyMethodList([self class], &method_count);
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[NuMethod alloc] initWithMethod:method_list[i]]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

+ (NSArray *) instanceVariableNames
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int ivar_count;
    Ivar *ivar_list = class_copyIvarList([self class], &ivar_count);
    int i;
    for (i = 0; i < ivar_count; i++) {
        [array addObject:[NSString stringWithCString:ivar_list[i]->ivar_name  encoding:NSUTF8StringEncoding]];
    }
    free(ivar_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
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
            NSLog(@"Warning: Class %s already exists and is not a subclass of %s", name, c->name);
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

+ (BOOL) copyInstanceMethod:(NSString *) methodName fromClass:(NuClass *)prototypeClass
{
    Class thisClass = [self class]->isa;
    Class otherClass = [prototypeClass wrappedClass];

    const char *method_name_str = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    SEL selector = sel_registerName(method_name_str);
    Method m = class_getInstanceMethod(otherClass, selector);
    if (!m) return false;
    IMP imp = method_getImplementation(m);
    if (!imp) return false;
    const char *signature = method_getTypeEncoding(m);
    if (!signature) return false;
    BOOL result = (class_replaceMethod(thisClass, selector, imp, signature) != 0);
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

+ (id) addInstanceVariable:(NSString *)variableName signature:(NSString *)signature
{
    Class thisClass = [self class];
    size_t size_of_objc_type(const char *typeString);

    struct objc_ivar_list *ivars = thisClass->ivars;
    if (ivars) {
        int i = 0;
        //for (i = 0; i < ivars->ivar_count; i++) {
        //struct objc_ivar *ivar = &(ivars->ivar_list[i]);
        //NSLog(@"ivar %d: %s %s %d", i, ivar->ivar_name, ivar->ivar_type, ivar->ivar_offset);
        //}
        struct objc_ivar *last_ivar = &(ivars->ivar_list[ivars->ivar_count-1]);
        int offset = last_ivar->ivar_offset  + size_of_objc_type(last_ivar->ivar_type);
        //NSLog(@"the next ivar goes here: %d", offset);
        struct objc_ivar *new_ivar = (struct objc_ivar *) malloc (sizeof (struct objc_ivar));
        new_ivar->ivar_name = strdup([variableName cStringUsingEncoding:NSUTF8StringEncoding]);
        new_ivar->ivar_type = strdup([signature cStringUsingEncoding:NSUTF8StringEncoding]);
        new_ivar->ivar_offset = offset;
        struct objc_ivar_list *new_ivar_list = (struct objc_ivar_list *) malloc (sizeof (struct objc_ivar_list) + (ivars->ivar_count) * sizeof(struct objc_ivar));
        new_ivar_list->ivar_count = ivars->ivar_count + 1;
        for (i = 0; i < ivars->ivar_count; i++)
            new_ivar_list->ivar_list[i] = ivars->ivar_list[i];
        new_ivar_list->ivar_list[ivars->ivar_count] = *new_ivar;
        thisClass->ivars = new_ivar_list;
        thisClass->instance_size += size_of_objc_type(new_ivar->ivar_type);
    }
    else {
        int offset = thisClass->instance_size;
        //NSLog(@"the next ivar goes here: %d", offset);
        struct objc_ivar *new_ivar = (struct objc_ivar *) malloc (sizeof (struct objc_ivar));
        new_ivar->ivar_name = strdup([variableName cStringUsingEncoding:NSUTF8StringEncoding]);
        new_ivar->ivar_type = strdup([signature cStringUsingEncoding:NSUTF8StringEncoding]);
        new_ivar->ivar_offset = offset;
        struct objc_ivar_list *new_ivar_list = (struct objc_ivar_list *) malloc (sizeof (struct objc_ivar_list));
        new_ivar_list->ivar_count = 1;
        new_ivar_list->ivar_list[0] = *new_ivar;
        thisClass->ivars = new_ivar_list;
        thisClass->instance_size += size_of_objc_type(new_ivar->ivar_type);
    }
    return Nu__null;
}

+ (NSString *) help
{
    return [NSString stringWithFormat:@"This is a class named %s.", [self class]->name];
}

- (NSString *) help
{
    return [NSString stringWithFormat:@"This is an instance of %s.", [self class]->name];
}

// adapted from the CocoaDev MethodSwizzling page

+ (BOOL) exchangeInstanceMethod:(SEL)sel1 withMethod:(SEL)sel2
{
    Class myClass = [self class];

    Method method1 = nil, method2 = nil;

    // First, look for the methods
    method1 = class_getInstanceMethod(myClass, sel1);
    method2 = class_getInstanceMethod(myClass, sel2);

    // If both are found, swizzle them
    if ((method1 != nil) && (method2 != nil)) {
        char *temp_types = method1->method_types;
        method1->method_types = method2->method_types;
        method2->method_types = temp_types;

        IMP temp_imp = method1->method_imp;
        method1->method_imp = method2->method_imp;
        method2->method_imp = temp_imp;
        return true;
    }
    else {
        if (method1 == nil) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == nil) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
        return false;
    }

    return YES;
}

+ (BOOL) exchangeClassMethod:(SEL)sel1 withMethod:(SEL)sel2
{
    Class myClass = [self class];

    Method method1 = nil, method2 = nil;

    // First, look for the methods
    method1 = class_getClassMethod(myClass, sel1);
    method2 = class_getClassMethod(myClass, sel2);

    // If both are found, swizzle them
    if ((method1 != nil) && (method2 != nil)) {
        char *temp_types = method1->method_types;
        method1->method_types = method2->method_types;
        method2->method_types = temp_types;

        IMP temp_imp = method1->method_imp;
        method1->method_imp = method2->method_imp;
        method2->method_imp = temp_imp;
        return true;
    }
    else {
        if (method1 == nil) NSLog(@"swap failed: can't find %s", sel_getName(sel1));
        if (method2 == nil) NSLog(@"swap failed: can't find %s", sel_getName(sel2));
        return false;
    }

    return YES;
}

@end
