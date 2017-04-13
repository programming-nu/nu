//
//  NSData+Nu.m
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import "NSData+Nu.h"

@implementation NSData(Nu)

- (const unsigned char) byteAtIndex:(int) i
{
    const unsigned char buffer[2];
    [self getBytes:(void *)&buffer range:NSMakeRange(i,1)];
    return buffer[0];
}

#if !TARGET_OS_IPHONE
// Read the output of a shell command into an NSData object and return the object.
+ (NSData *) dataWithShellCommand:(NSString *) command
{
    return [self dataWithShellCommand:command standardInput:nil];
}

+ (NSData *) dataWithShellCommand:(NSString *) command standardInput:(id) input
{
    char *input_template = strdup("/tmp/nuXXXXXX");
    char *input_filename = mktemp(input_template);
    char *output_template = strdup("/tmp/nuXXXXXX");
    char *output_filename = mktemp(output_template);
    id returnValue = nil;
    if (input_filename || output_filename) {
        NSString *inputFileName = [NSString stringWithCString:input_filename encoding:NSUTF8StringEncoding];
        NSString *outputFileName = [NSString stringWithCString:output_filename encoding:NSUTF8StringEncoding];
        NSString *fullCommand;
        if (input) {
            if ([input isKindOfClass:[NSData class]]) {
                [input writeToFile:inputFileName atomically:NO];
            } else if ([input isKindOfClass:[NSString class]]) {
                [input writeToFile:inputFileName atomically:NO encoding:NSUTF8StringEncoding error:NULL];
            } else {
                [[input stringValue] writeToFile:inputFileName atomically:NO encoding:NSUTF8StringEncoding error:NULL];
            }
            fullCommand = [NSString stringWithFormat:@"%@ < %@ > %@", command, inputFileName, outputFileName];
        }
        else {
            fullCommand = [NSString stringWithFormat:@"%@ > %@", command, outputFileName];
        }
        const char *commandString = [fullCommand UTF8String];
        int result = system(commandString) >> 8;  // this needs an explanation
        if (!result)
            returnValue = [NSData dataWithContentsOfFile:outputFileName];
        system([[NSString stringWithFormat:@"rm -f %@ %@", inputFileName, outputFileName] UTF8String]);
    }
    free(input_template);
    free(output_template);
    return returnValue;
}
#endif

// Read the contents of standard input into a string.
+ (NSData *) dataWithStandardInput
{
    return [[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile];
}

// Helper. Included because it's so useful.
- (id) propertyListValue {
    return [NSPropertyListSerialization propertyListWithData:self
                                                     options:NSPropertyListImmutable
                                                      format:0
                                                       error:NULL];
}

@end

