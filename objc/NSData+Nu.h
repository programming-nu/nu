//
//  NSData+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>



/*!
 @category NSData(Nu)
 @abstract NSData extensions for Nu programming.
 @discussion NSData extensions for Nu programming.
 */
@interface NSData(Nu)

#if !TARGET_OS_IPHONE
/*! Run a shell command and return the results as data. */
+ (NSData *) dataWithShellCommand:(NSString *) command;

/*! Run a shell command with the specified data or string as standard input and return the results as data. */
+ (NSData *) dataWithShellCommand:(NSString *) command standardInput:(id) input;
#endif

/*! Return data read from standard input. */
+ (NSData *) dataWithStandardInput;

/*! Property list helper. Return the (immutable) property list value of the associated data. */
- (id) propertyListValue;

@end
