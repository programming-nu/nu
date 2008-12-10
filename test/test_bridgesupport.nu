;; test_bridgesupport.nu
;;  tests for the Nu reader for Apple's BridgeSupport files.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(if (eq (uname) "Darwin")
    (import Foundation)
    
    (class TestBridgeSupport is NuTestCase
         
         (imethod (id) testConstants is
              (assert_equal "NSFileBusy" NSFileBusy))
         
         (imethod (id) testEnums is
              (assert_equal 4 NSGreaterThanComparison))
         
         (unless ((NSGarbageCollector defaultCollector) isEnabled)
                 (imethod (id) testFunctions is
                      (assert_equal 2 (NSMinY '(1 2 3 4)))))))
