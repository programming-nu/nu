//
//  NuBridgedBlock.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NuBridgedBlock.h"
#import "NuInternals.h"
#import "NuBridge.h"

#import <sys/stat.h>
#import <sys/mman.h>

#ifdef __BLOCKS__

static id make_cblock (NuBlock *nuBlock, NSString *signature);
static void objc_calling_nu_block_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata);
static char **generate_block_userdata(NuBlock *nuBlock, const char *signature);
static void *construct_block_handler(NuBlock *block, const char *signature);

@interface NuBridgedBlock ()
{
    NuBlock *nuBlock;
    id cBlock;
}
@end

@implementation NuBridgedBlock

+(id)cBlockWithNuBlock:(NuBlock*)nb signature:(NSString*)sig
{
    return [[[[self alloc] initWithNuBlock:nb signature:sig] autorelease] cBlock];
}

-(id)initWithNuBlock:(NuBlock*)nb signature:(NSString*)sig
{
    nuBlock = [nb retain];
    cBlock = make_cblock(nb,sig);
    
    return self;
}

-(NuBlock*)nuBlock
{return [[nuBlock retain] autorelease];}

-(id)cBlock
{return [[cBlock retain] autorelease];}

-(void)dealloc
{
    [nuBlock release];
    [cBlock release];
    [super dealloc];
}

@end

//the caller gets ownership of the block
static id make_cblock (NuBlock *nuBlock, NSString *signature)
{
    void *funcptr = construct_block_handler(nuBlock, [signature UTF8String]);
    
    int i = 0xFFFF;
    void(^cBlock)(void)=[^(void){printf("%i",i);} copy];
    
#ifdef __x86_64__
    /*  this is what happens when a block is called on x86 64
     mov    %rax,-0x18(%rbp)		//the pointer to the block object is in rax
     mov    -0x18(%rbp),%rax
     mov    0x10(%rax),%rax			//the pointer to the block function is at +0x10 into the block object
     mov    -0x18(%rbp),%rdi		//the first argument (this examples has no others) is always the pointer to the block object
     callq  *%rax
     */
    //2*(sizeof(void*)) = 0x10
    *((void **)(id)cBlock + 2) = (void *)funcptr;
#else
    /*  this is what happens when a block is called on x86 32
     mov    %eax,-0x14(%ebp)		//the pointer to the block object is in eax
     mov    -0x14(%ebp),%eax
     mov    0xc(%eax),%eax			//the pointer to the block function is at +0xc into the block object
     mov    %eax,%edx
     mov    -0x14(%ebp),%eax		//the first argument (this examples has no others) is always the pointer to the block object
     mov    %eax,(%esp)
     call   *%edx
     */
    //3*(sizeof(void*)) = 0xc
    *((void **)(id)cBlock + 3) = (void *)funcptr;
#endif
    return cBlock;
}

static void objc_calling_nu_block_handler(ffi_cif* cif, void* returnvalue, void** args, void* userdata)
{
    int argc = cif->nargs - 1;
    //void *ptr = (void*)args[0]  //don't need this first parameter
    // see objc_calling_nu_method_handler
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NuBlock *block = ((NuBlock **)userdata)[1];
    //NSLog(@"----------------------------------------");
    //NSLog(@"calling block %@", [block stringValue]);
    id arguments = [[NuCell alloc] init];
    id cursor = arguments;
    int i;
    for (i = 0; i < argc; i++) {
        NuCell *nextCell = [[NuCell alloc] init];
        [cursor setCdr:nextCell];
        [nextCell release];
        cursor = [cursor cdr];
        id value = get_nu_value_from_objc_value(args[i+1], ((char **)userdata)[i+2]);
        [cursor setCar:value];
    }
    //NSLog(@"in nu method handler, using arguments %@", [arguments stringValue]);
    id result = [block evalWithArguments:[arguments cdr] context:nil];
    //NSLog(@"in nu method handler, putting result %@ in %x with type %s", [result stringValue], (size_t) returnvalue, ((char **)userdata)[0]);
    char *resultType = (((char **)userdata)[0])+1;// skip the first character, it's a flag
    set_objc_value_from_nu_value(returnvalue, result, resultType);
    [arguments release];
    if (pool) {
        if (resultType[0] == '@')
            [*((id *)returnvalue) retain];
        [pool release];
        if (resultType[0] == '@')
            [*((id *)returnvalue) autorelease];
    }
}

static char **generate_block_userdata(NuBlock *nuBlock, const char *signature)
{
    NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:signature];
    const char *return_type_string = [methodSignature methodReturnType];
    NSUInteger argument_count = [methodSignature numberOfArguments];
    char **userdata = (char **) malloc ((argument_count+3) * sizeof(char*));
    userdata[0] = (char *) malloc (2 + strlen(return_type_string));
    
    //assume blocks never return retained results
    sprintf(userdata[0], " %s", return_type_string);
    
    //so first element is return type, second is nuBlock
    userdata[1] = (char *) nuBlock;
    [nuBlock retain];
    int i;
    for (i = 0; i < argument_count; i++) {
        const char *argument_type_string = [methodSignature getArgumentTypeAtIndex:i];
        userdata[i+2] = strdup(argument_type_string);
    }
    userdata[argument_count+2] = NULL;
    
#if 0
    NSLog(@"Userdata for block: %@, signature: %s", [nuBlock stringValue], signature);
    for (int i = 0; i < argument_count+2; i++)
    {	if (i != 1)
        NSLog(@"userdata[%i] = %s",i,userdata[i]);	}
#endif
    return userdata;
}


static void *construct_block_handler(NuBlock *block, const char *signature)
{
    char **userdata = generate_block_userdata(block, signature);
    
    int argument_count = 0;
    while (userdata[argument_count] != 0) argument_count++;
    argument_count-=1; //unlike a method call, c blocks have one, not two hidden args (see comments in make_cblock()
#if 0
    NSLog(@"using libffi to construct handler for nu block with %d arguments and signature %s", argument_count, signature);
#endif
    if (argument_count < 0) {
        NSLog(@"error in argument construction");
        return NULL;
    }
    
    ffi_type **argument_types = (ffi_type **) malloc ((argument_count+1) * sizeof(ffi_type *));
    ffi_type *result_type = ffi_type_for_objc_type(userdata[0]+1);
    
    argument_types[0] = ffi_type_for_objc_type("^?");
    
    for (int i = 1; i < argument_count; i++)
        argument_types[i] = ffi_type_for_objc_type(userdata[i+1]);
    argument_types[argument_count] = NULL;
    ffi_cif *cif = (ffi_cif *)malloc(sizeof(ffi_cif));
    if (cif == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for cif structure)", signature);
        return NULL;
    }
    int status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argument_count, result_type, argument_types);
    if (status != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_cif failed)", signature);
        return NULL;
    }
    ffi_closure *closure = (ffi_closure *)mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if (closure == (ffi_closure *) -1) {
        NSLog(@"unable to prepare closure for signature %s (mmap failed with error %d)", signature, errno);
        return NULL;
    }
    if (closure == NULL) {
        NSLog(@"unable to prepare closure for signature %s (could not allocate memory for closure)", signature);
        return NULL;
    }
    if (ffi_prep_closure(closure, cif, objc_calling_nu_block_handler, userdata) != FFI_OK) {
        NSLog(@"unable to prepare closure for signature %s (ffi_prep_closure failed)", signature);
        return NULL;
    }
    if (mprotect(closure, sizeof(closure), PROT_READ | PROT_EXEC) == -1) {
        NSLog(@"unable to prepare closure for signature %s (mprotect failed with error %d)", signature, errno);
        return NULL;
    }
    return (void*)closure;
}

#endif //__BLOCKS__