//
//  NuMath.h
//  Nu
//
//  Created by Tim Burks on 4/24/16.
//
//

#import <Foundation/Foundation.h>

/*!
 @class NuMath
 @abstract A utility class that provides Nu access to common mathematical functions.
 @discussion The NuMath class provides a few common mathematical functions as class methods.
 */
@interface NuMath : NSObject
/*! Get the square root of a number. */
+ (double) sqrt: (double) x;
/*! Get the square of a number. */
+ (double) square: (double) x;
/*! Get the cubed root of a number. */
+ (double) cbrt: (double) x;
/*! Get the cosine of an angle. */
+ (double) cos: (double) x;
/*! Get the sine of an angle. */
+ (double) sin: (double) x;
/*! Get the largest integral value that is not greater than x.*/
+ (double) floor: (double) x;
/*! Get the smallest integral value that is greater than or equal to x.*/
+ (double) ceil: (double) x;
/*! Get the integral value nearest to x by always rounding half-way cases away from zero. */
+ (double) round: (double) x;
/*! Raise x to the power of y */
+ (double) raiseNumber: (double) x toPower: (double) y;
/*! Get the qouteint of x divided by y as an integer */
+ (int) integerDivide:(int) x by:(int) y;
/*! Get the remainder of x divided by y as an integer */
+ (int) integerMod:(int) x by:(int) y;
/*! Get a random integer. */
+ (long) random;
/*! Seed the random number generator. */
+ (void) srandom:(unsigned long) seed;
@end