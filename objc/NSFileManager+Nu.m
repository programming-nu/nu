//
//  NSFileManager+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSFileManager+Nu.h"
#import "NuInternals.h"
#import <sys/stat.h>

@implementation NSFileManager(Nu)

// crashes
+ (id) _timestampForFileNamed:(NSString *) filename
{
    if (filename == Nu__null) return nil;
    NSError *error;
    NSDictionary *attributes = [[NSFileManager defaultManager]
                                attributesOfItemAtPath:[filename stringByExpandingTildeInPath]
                                error:&error];
    return [attributes valueForKey:NSFileModificationDate];
}

+ (id) creationTimeForFileNamed:(NSString *) filename
{
    if (!filename)
        return nil;
    const char *path = [[filename stringByExpandingTildeInPath] UTF8String];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    // return [NSDate dateWithTimeIntervalSince1970:sb.st_ctimespec.tv_sec];
    return [NSDate dateWithTimeIntervalSince1970:sb.st_ctime];
}

+ (id) modificationTimeForFileNamed:(NSString *) filename
{
    if (!filename)
        return nil;
    const char *path = [[filename stringByExpandingTildeInPath] UTF8String];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return nil;
    }
    return [NSDate dateWithTimeIntervalSince1970:sb.st_mtime];
}

+ (int) directoryExistsNamed:(NSString *) filename
{
    if (!filename)
        return NO;
    const char *path = [[filename stringByExpandingTildeInPath] UTF8String];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return NO;
    }
    return (S_ISDIR(sb.st_mode) != 0) ? 1 : 0;
}

+ (int) fileExistsNamed:(NSString *) filename
{
    if (!filename)
        return NO;
    const char *path = [[filename stringByExpandingTildeInPath] UTF8String];
    struct stat sb;
    int result = stat(path, &sb);
    if (result == -1) {
        return NO;
    }
    return (S_ISDIR(sb.st_mode) == 0) ? 1 : 0;
}

@end


