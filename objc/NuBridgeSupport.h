//
//  NuBridgeSupport.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>
#import "NuBridge.h"

#if !TARGET_OS_IPHONE
/*!
 @class NuBridgeSupport
 @abstract A reader for Apple's BridgeSupport files.
 @discussion Methods of this class are used to read Apple's BridgeSupport files.
 */
@interface NuBridgeSupport : NSObject
/*! Import a dynamic library at the specified path. */
+ (void)importLibrary:(NSString *) libraryPath;
/*! Import a BridgeSupport description of a framework from a specified path.  Store the results in the specified dictionary. */
+ (void)importFramework:(NSString *) framework fromPath:(NSString *) path intoDictionary:(NSMutableDictionary *) BridgeSupport;

@end
#endif