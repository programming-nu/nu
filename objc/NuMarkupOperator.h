//
//  NuMarkupOperator.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>
#import "Nu.h"
#import "NuOperators.h"

@interface NuMarkupOperator : NuOperator
{
    NSString *tag;
    NSString *prefix;
    NSMutableArray *tagIds;
    NSMutableArray *tagClasses;
    id contents;
    BOOL empty; // aka a "void element"
}

+ (id) operatorWithTag:(NSString *) _tag;
+ (id) operatorWithTag:(NSString *) _tag prefix:(NSString *) _prefix;
+ (id) operatorWithTag:(NSString *) _tag prefix:(NSString *) _prefix contents:(id) _contents;

- (id) initWithTag:(NSString *) tag;
- (id) initWithTag:(NSString *) tag prefix:(NSString *) prefix contents:(id) contents;
- (void) setEmpty:(BOOL) e;

- (NSString *) tag;
- (NSString *) prefix;
- (id) contents;
- (BOOL) empty;

@end
