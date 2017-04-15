//
//  NSFileManager+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @category NSFileManager(Nu)
 @abstract NSFileManager extensions for Nu programming.
 */
@interface NSFileManager (Nu)
/*! Get the creation time for a file. */
+ (id) creationTimeForFileNamed:(NSString *) filename;
/*! Get the latest modification time for a file. */
+ (id) modificationTimeForFileNamed:(NSString *) filename;
/*! Test for the existence of a directory. */
+ (int) directoryExistsNamed:(NSString *) filename;
/*! Test for the existence of a file. */
+ (int) fileExistsNamed:(NSString *) filename;
@end
