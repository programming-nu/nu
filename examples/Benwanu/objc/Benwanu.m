//
// Benwanu.m
//
// Multithreaded visualizer for the Mandelbrot set.
// Copyright (c) 2007 Tim Burks, Radtastical Inc.
//
// Adapted from an example in "Advanced Mac OS X Programming" by
// Aaron Hillegass and Mark Dalrymple.  Original version
// Copyright (c) 2002 Big Nerd Ranch. Used with permission.

@protocol ProgressReporting
- (void) setProgress:(id) progress;
@end

#import <Cocoa/Cocoa.h>
#include <complex.h>

#define MAX_ITERATIONS 100

// (x, y) is the coordinate to be drawn
// buffer points to the resulting RGB color value
void mandlebrot(double x, double y, unsigned char *buffer)
{
    complex c = x + (y * 1.0i);
    complex z = 0;
    int i;
    for (i = 0; i < MAX_ITERATIONS; i++) {
        z = (z * z) - c;
        if (cabs(z) > 10000) {
			int s = (MAX_ITERATIONS - i) * 256 / MAX_ITERATIONS;
			buffer[0] = 256 - (s % 128) * 2;       // red
			buffer[1] = buffer[0];			       // green
			buffer[2] = s;                         // blue
            return;
        }
    }
    buffer[0] = 0;
    buffer[1] = 0;
    buffer[2] = 0;
}

// This C function fills a region in a bitmap image for a specified server.
// Normally this would be an instance method of the server, but this is more fun to demonstrate.
void fillRegion(NSBitmapImageRep *imageRep, int offset, double minX, double minY, double maxX, double maxY, int w, int h, id server)
{
    double regionW = maxX - minX;
    double regionH = maxY - minY;

    unsigned char *ptr = (unsigned char *) [imageRep bitmapData] + offset * w * h * 3;
    int x, y;
    for (y = 0; y < h; y++) {
        // Update the progress bar on every nth row.
        if ((y % 10) == 0)
            [server setProgress:[NSNumber numberWithDouble:(100.0 * y) / h]];
        // Calculate where on the set this y is
        double regionY = maxY - (regionH * (double)y) / (double)h;
        for (x = 0; x < w; x++) {
            // Calculate where on the set this x is
            double regionX = minX + (regionW * (double)x) / (double)w;
            // Do the calculation and color the pixel.
            mandlebrot(regionX, regionY, ptr);
            // move the next pixel
            ptr += 3;
        }
    }
}
