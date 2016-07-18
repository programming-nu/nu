//
//  NuHandler.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#if !TARGET_OS_IPHONE


#import <Foundation/Foundation.h>

@class NuBlock;

#pragma mark - NuHandler.h

struct nu_handler_description
{
    IMP handler;
    char **description;
};


/*!
 @class NuHandlerWarehouse
 @abstract Internal class used to store and vend method implementations on platforms that don't allow them to be constructed at runtime.
 */
@interface NuHandlerWarehouse : NSObject
+ (void) registerHandlers:(struct nu_handler_description *) description withCount:(int) count forReturnType:(NSString *) returnType;
+ (IMP) handlerWithSelector:(SEL)sel block:(NuBlock *)block signature:(const char *) signature userdata:(char **) userdata;
@end

static void nu_handler(void *return_value,
                       struct nu_handler_description *description,
                       id receiver,
                       va_list ap);

#endif
