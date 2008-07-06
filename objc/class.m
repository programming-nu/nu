/*!
@file class.m
@description The Nu class abstraction.
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
#import "objc_runtime.h"
#import "class.h"
#import "method.h"
#import "block.h"
#import "cell.h"
#import "object.h"
#import "extensions.h"

// getting a specific method...
// (set x (((Convert classMethods) select: (do (m) (eq (m name) "passRect:"))) objectAtIndex:0))

@implementation NuClass

+ (NuClass *) classWithName:(NSString *)string
{
    const char *name = [string cStringUsingEncoding:NSUTF8StringEncoding];
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
    const char *name = [string cStringUsingEncoding:NSUTF8StringEncoding];
    Class class = objc_getClass(name);
    return [self initWithClass: class];
}

- (id) initWithClass:(Class) class
{
    [super init];
    c = class;
    isRegistered = YES;                           // unless we explicitly set otherwise
    return self;
}

+ (NSArray *) all
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    int numClasses = objc_getClassList(NULL, 0);
    if(numClasses > 0) {
        Class *classes = (Class *) malloc( sizeof(Class) * numClasses );
        objc_getClassList(classes, numClasses);
        int i = 0;
        while (i < numClasses) {
            NuClass *class = [[NuClass alloc] initWithClass:classes[i]];
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
    #ifdef DARWIN
    return [NSString stringWithCString:class_getName(c) encoding:NSUTF8StringEncoding];
    #else
    return [NSString stringWithCString:class_get_class_name(c) encoding:NSUTF8StringEncoding];
    #endif
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
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int method_count;
    #ifdef DARWIN
    Method *method_list = class_copyMethodList(object_getClass([self wrappedClass]), &method_count);
    #else
    Method_t *method_list = class_copyMethodList(object_get_class([self wrappedClass]), &method_count);
    #endif
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[NuMethod alloc] initWithMethod:method_list[i]]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

- (NSArray *) instanceMethods
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    unsigned int method_count;
    #ifdef DARWIN
    Method *method_list = class_copyMethodList([self wrappedClass], &method_count);
    #else
    Method_t *method_list = class_copyMethodList([self wrappedClass], &method_count);
    #endif
    int i;
    for (i = 0; i < method_count; i++) {
        [array addObject:[[NuMethod alloc] initWithMethod:method_list[i]]];
    }
    free(method_list);
    [array sortUsingSelector:@selector(compare:)];
    return array;
}

/*! Get an array containing the names of the class methods of a class. */
- (NSArray *) classMethodNames
{
    return [[self classMethods] mapSelector:@selector(name)];
}

/*! Get an array containing the names of the instance methods of a class. */
- (NSArray *) instanceMethodNames
{
    return [[self instanceMethods] mapSelector:@selector(name)];
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
    const char *methodNameString = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
    NuMethod *method = Nu__null;
    unsigned int method_count;
    #ifdef DARWIN
    Method *method_list = class_copyMethodList(object_getClass([self wrappedClass]), &method_count);
    #else
    Method_t *method_list = class_copyMethodList(object_get_class([self wrappedClass]), &method_count);
    #endif
    int i;
    for (i = 0; i < method_count; i++) {
        #ifdef DARWIN
        if (!strcmp(methodNameString, sel_getName(method_getName(method_list[i])))) {
            #else
            if (!strcmp(methodNameString, sel_get_name(method_getName(method_list[i])))) {
                #endif
                method = [[NuMethod alloc] initWithMethod:method_list[i]];
            }
        }
        free(method_list);
        return method;
    }

    - (NuMethod *) instanceMethodWithName:(NSString *) methodName
    {
        const char *methodNameString = [methodName cStringUsingEncoding:NSUTF8StringEncoding];
        NuMethod *method = Nu__null;
        unsigned int method_count;
        #ifdef DARWIN
        Method *method_list = class_copyMethodList([self wrappedClass], &method_count);
        #else
        Method_t *method_list = class_copyMethodList([self wrappedClass], &method_count);
        #endif
        int i;
        for (i = 0; i < method_count; i++) {
            #ifdef DARWIN
            if (!strcmp(methodNameString, sel_getName(method_getName(method_list[i])))) {
                #else
                if (!strcmp(methodNameString, sel_get_name(method_getName(method_list[i])))) {
                    #endif
                    method = [[NuMethod alloc] initWithMethod:method_list[i]];
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
            //NSLog(@"adding class method %@", methodName);
            #ifdef DARWIN
            return add_method_to_class(c->isa, methodName, signature, block);
            #else
            return add_method_to_class(c->class_pointer, methodName, signature, block);
            #endif
        }

        - (id) addInstanceVariable:(NSString *)variableName signature:(NSString *)signature
        {
            //NSLog(@"adding instance variable %@", variableName);
            class_addInstanceVariable_withSignature(c, [variableName cStringUsingEncoding:NSUTF8StringEncoding], [signature cStringUsingEncoding:NSUTF8StringEncoding]);
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
            }
        }

        - (id) handleUnknownMessage:(id) cdr withContext:(NSMutableDictionary *) context
        {
            return [[self wrappedClass] handleUnknownMessage:cdr withContext:context];
        }

        @end
