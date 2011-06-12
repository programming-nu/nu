;; test_bridgesupport.nu
;;  tests for the Nu reader for Apple's BridgeSupport files.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(unless (defined IPHONE)
(if (eq (uname) "Darwin")
    (import Foundation)
    
    (class TestBridgeSupport is NuTestCase
         
         (- (id) testConstants is
            (assert_equal "NSFileBusy" NSFileBusy))
         
         (- (id) testEnums is
            (assert_equal 4 NSGreaterThanComparison))
         
         (unless ((NSGarbageCollector defaultCollector) isEnabled)
                 (- (id) testFunctions is
                    (assert_equal 2 (NSMinY '(1 2 3 4))))))))
