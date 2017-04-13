//
//  NuMethod.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//



#import "NuMethod.h"
#import "NuInternals.h"



#pragma mark - NuMethod.m
@interface NuMethod ()
{
    Method m;
}
@end

@implementation NuMethod

- (id) initWithMethod:(Method) method
{
    if ((self = [super init])) {
        m = method;
    }
    return self;
}

- (NSString *) name
{
    return m ? [NSString stringWithCString:(sel_getName(method_getName(m))) encoding:NSUTF8StringEncoding] : (NSString *) Nu__null;
}

- (int) argumentCount
{
    return method_getNumberOfArguments(m);
}

- (NSString *) typeEncoding
{
    return [NSString stringWithCString:method_getTypeEncoding(m) encoding:NSUTF8StringEncoding];
}

- (NSString *) signature
{
    const char *encoding = method_getTypeEncoding(m);
    NSInteger len = strlen(encoding)+1;
    char *signature = (char *) malloc (len * sizeof(char));
    method_getReturnType(m, signature, len);
    NSInteger step = strlen(signature);
    char *start = &signature[step];
    len -= step;
    int argc = method_getNumberOfArguments(m);
    int i;
    for (i = 0; i < argc; i++) {
        method_getArgumentType(m, i, start, len);
        step = strlen(start);
        start = &start[step];
        len -= step;
    }
    // printf("name:%s i:%d len:%d signature:%s\n", sel_getName(method_getName(m)), i, len, signature);
    id result = [NSString stringWithCString:signature encoding:NSUTF8StringEncoding];
    free(signature);
    return result;
}

- (NSString *) argumentType:(int) i
{
    if (i >= method_getNumberOfArguments(m))
        return nil;
    char *argumentType = method_copyArgumentType(m, i);
    id result = [NSString stringWithCString:argumentType encoding:NSUTF8StringEncoding];
    free(argumentType);
    return result;
}

- (NSString *) returnType
{
    char *returnType = method_copyReturnType(m);
    id result = [NSString stringWithCString:returnType encoding:NSUTF8StringEncoding];
    free(returnType);
    return result;
}

- (NuBlock *) block
{
    IMP imp = method_getImplementation(m);
    NuBlock *block = nil;
    if (nu_block_table) {
        block = [nu_block_table objectForKey:[NSNumber numberWithUnsignedLong:(unsigned long) imp]];
    }
    return block;
}

- (NSComparisonResult) compare:(NuMethod *) anotherMethod
{
    return [[self name] compare:[anotherMethod name]];
}

@end

