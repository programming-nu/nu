//
//  NuBridgedFunction.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuBridgedFunction.h"
#import "NuBridge.h"
#import "NuInternals.h"

@interface NuBridgedFunction ()
{
    char *name;
    char *signature;
    void *function;
}
@end

@implementation NuBridgedFunction

- (void) dealloc
{
    free(name);
    free(signature);
    [super dealloc];
}

- (NuBridgedFunction *) initWithName:(NSString *)n signature:(NSString *)s
{
    name = strdup([n UTF8String]);
    signature = strdup([s UTF8String]);
    function = dlsym(RTLD_DEFAULT, name);
    if (!function) {
        [NSException raise:@"NuCantFindBridgedFunction"
                    format:@"%s\n%s\n%s\n", dlerror(),
         "If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.",
         "In Xcode, check the 'Preserve Private External Symbols' checkbox."];
    }
    return self;
}

+ (NuBridgedFunction *) functionWithName:(NSString *)name signature:(NSString *)signature
{
    const char *function_name = [name UTF8String];
    void *function = dlsym(RTLD_DEFAULT, function_name);
    if (!function) {
        [NSException raise:@"NuCantFindBridgedFunction"
                    format:@"%s\n%s\n%s\n", dlerror(),
         "If you are using a release build, try rebuilding with the KEEP_PRIVATE_EXTERNS variable set.",
         "In Xcode, check the 'Preserve Private External Symbols' checkbox."];
    }
    NuBridgedFunction *wrapper = [[[NuBridgedFunction alloc] initWithName:name signature:signature] autorelease];
    return wrapper;
}

- (id) evalWithArguments:(id) cdr context:(NSMutableDictionary *) context
{
    //NSLog(@"----------------------------------------");
    //NSLog(@"calling C function %s with signature %s", name, signature);
    id result;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    char *return_type_identifier = strdup(signature);
    nu_markEndOfObjCTypeString(return_type_identifier, strlen(return_type_identifier));
    
    int argument_count = 0;
    char *argument_type_identifiers[100];
    char *cursor = &signature[strlen(return_type_identifier)];
    while (*cursor != 0) {
        argument_type_identifiers[argument_count] = strdup(cursor);
        nu_markEndOfObjCTypeString(argument_type_identifiers[argument_count], strlen(cursor));
        cursor = &cursor[strlen(argument_type_identifiers[argument_count])];
        argument_count++;
    }
    //NSLog(@"calling return type is %s", return_type_identifier);
    int i;
    for (i = 0; i < argument_count; i++) {
        //    NSLog(@"argument %d type is %s", i, argument_type_identifiers[i]);
    }
    
    ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));
    
    ffi_type *result_type = ffi_type_for_objc_type(return_type_identifier);
    ffi_type **argument_types = (argument_count == 0) ? NULL : (ffi_type **) malloc (argument_count * sizeof(ffi_type *));
    for (i = 0; i < argument_count; i++)
        argument_types[i] = ffi_type_for_objc_type(argument_type_identifiers[i]);
    
    int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
    if (status != FFI_OK) {
        NSLog (@"failed to prepare cif structure");
        return [NSNull null];
    }
    
    id arg_cursor = cdr;
    void *result_value = value_buffer_for_objc_type(return_type_identifier);
    void **argument_values = (void **) (argument_count ? malloc (argument_count * sizeof(void *)) : NULL);
    
    for (i = 0; i < argument_count; i++) {
        argument_values[i] = value_buffer_for_objc_type( argument_type_identifiers[i]);
        id arg_value = [[arg_cursor car] evalWithContext:context];
        set_objc_value_from_nu_value(argument_values[i], arg_value, argument_type_identifiers[i]);
        arg_cursor = [arg_cursor cdr];
    }
    ffi_call(cif, FFI_FN(function), result_value, argument_values);
    result = get_nu_value_from_objc_value(result_value, return_type_identifier);
    
    // free the value structures
    for (i = 0; i < argument_count; i++) {
        free(argument_values[i]);
        free(argument_type_identifiers[i]);
    }
    free(argument_values);
    free(result_value);
    free(return_type_identifier);
    free(argument_types);
    free(cif);
    
    [result retain];
    [pool drain];
    [result autorelease];
    return result;
}

@end
