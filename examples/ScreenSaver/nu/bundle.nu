;;
;; NuScreenSaver/bundle.nu
;;
;; Copyright (c) 2007 Tim Burks, Radtastical Inc.
;;

(set MAX 20)

(function random (n) (NuMath integerMod:(NuMath random) by:n))

(class NuScreenSaver

     (imethod initWithFrame:frame isPreview:isPreview is
          (super initWithFrame:frame isPreview:isPreview)
          (set @color 0)
          (set @colors (NSMutableArray arrayWithList:(list (NSColor greenColor)
                                                           (NSColor redColor)
                                                           (NSColor blueColor)
                                                           (NSColor orangeColor)
                                                           (NSColor yellowColor)
                                                           (NSColor purpleColor))))
          (set @count 0)
          (self setOriginRandomly)
          self)
     
     (imethod (void) setOriginRandomly is
          (set rect (self frame))
          (set @origin (list (+ (rect first) (random (rect third)))
                             (+ (rect second) (random (rect fourth))))))
     
     (imethod animateOneFrame is
          (set @count (+ @count 1))
          (if (eq @count MAX)
              (set @count 0)
              (set @color (+ 1 @color))
              (if (eq @color (@colors count)) (set @color 0))
              (self setOriginRandomly))
          (self setNeedsDisplay:YES))
     
     (imethod drawRect:rect is
          ((NSColor blackColor) set)
          (NSRectFill rect)
          ((@colors @color) set)
          (set turtle ((Turtle alloc) init))
          (turtle moveToPoint:@origin)
          ((- MAX @count) times:
           (do (i)
               (turtle lineForward:(* 5 i))
               (turtle turnLeft)))
          (turtle stroke)))

(class Turtle is NSObject
     (ivars)
     
     (imethod init is
          (super init)
          (set @direction '(0 1))
          (set @path (NSBezierPath bezierPath))
          self)
     
     (imethod path is @path)
     
     (imethod moveToPoint:point is (@path moveToPoint:point))
     
     (imethod stroke is (@path stroke))
     
     (imethod turnLeft is
          (set @direction
               (case @direction
                     ('(0 1) '(-1 0))
                     ('(-1 0) '(0 -1))
                     ('(0 -1) '(1 0))
                     (else '(0 1)))))
     
     (imethod lineForward:distance is
          (@path relativeLineToPoint:(list (* distance (@direction first))
                                           (* distance (@direction second))))))