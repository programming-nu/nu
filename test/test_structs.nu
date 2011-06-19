;; test_structs.nu
;;  tests for Nu handling of common Cocoa structures.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(if (eq (uname) "Darwin")
    
    (class TestStructures is NuTestCase
         
         (- (id) testRect is
            (set v ((NSView alloc) init))
            (assert_equal '(0 0 0 0) (v frame))
            (v setFrame:'(1 2 3 4))
            (assert_equal '(1 2 3 4) (v frame))
            (v set:(frame:'(5 6 7 8)))
            (assert_equal '(5 6 7 8) (v frame))
            (v set:(frameOrigin:'(4 3) frameSize:'(2 1)))
            (assert_equal '(4 3 2 1) (v frame)))
         
         (- (id) testSize is
            (set v ((NSView alloc) init))
            (assert_equal '(0 0) (v frameSize))
            (v setFrameSize:'(1 2))
            (assert_equal '(1 2) (v frameSize))
            (v set:(frameSize:'(3 4)))
            (assert_equal '(3 4) (v frameSize)))
         
         (- (id) testPoint is
            (set v ((NSView alloc) init))
            (assert_equal '(0 0) (v frameOrigin))
            (v setFrameOrigin:'(1 2))
            (assert_equal '(1 2) (v frameOrigin))
            (v set:(frameOrigin:'(3 4)))
            (assert_equal '(3 4) (v frameOrigin)))
         
         (- (id) testRange is
            ;; I couldn't find a class that stored ranges inside it
            ;; (the way that NSView has internal NSRects), so I made one.
            (class ThingWithRange is NSObject
                 (ivar (NSRange) range))
            (set rangeThing ((ThingWithRange alloc) init))
            (assert_equal '(0 0) (rangeThing range))
            (rangeThing setRange:'(1 2))
            (assert_equal '(1 2) (rangeThing range))
            (rangeThing set:(range:'(3 4)))
            (assert_equal '(3 4) (rangeThing range))))
    
    ;; Obvious-looking methods that are missing in the NSView interface.
    (class NSView
         (- (NSSize) frameSize is
            (list ((self frame) third) ((self frame) fourth)))
         (- (NSPoint) frameOrigin is
            (list ((self frame) first) ((self frame) second)))))
