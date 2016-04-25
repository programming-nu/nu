//
//  NSBundle+Nu.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @category NSBundle(Nu)
 @abstract NSBundle extensions for Nu programming.
 */
@interface NSBundle (Nu)
/*! Get or load a framework by name. */
+ (NSBundle *) frameworkWithName:(NSString *) frameworkName;
/*! Load a Nu source file from the framework's resource directory. */
- (id) loadNuFile:(NSString *) nuFileName withContext:(NSMutableDictionary *) context;
@end