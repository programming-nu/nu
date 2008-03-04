;; test_bridge.nu
;;  tests for the Nu bridge to Objective-C.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestBridge is NuTestCase
     (if (eq (uname) "Darwin")
         (imethod (id) testConstants is
              (set floatTypeSignature (if (eq (Nu sizeOfPointer) 8) (then "d") (else "f")))
              (assert_equal 0 (NuBridgedConstant constantWithName:"NSBlack" signature:floatTypeSignature))
              (assert_equal 1 (NuBridgedConstant constantWithName:"NSWhite" signature:floatTypeSignature))
              (assert_equal '(0 0 0 0) (NuBridgedConstant constantWithName:"NSZeroRect" signature:"{_NSRect}"))
              (assert_equal (NSApplication sharedApplication) (NuBridgedConstant constantWithName:"NSApp" signature:"@"))))
     
     (imethod (id) testFunctions is
          (set strcmp (NuBridgedFunction functionWithName:"strcmp" signature:"i**"))
          (assert_less_than 0 (strcmp "a" "b"))
          (assert_equal 0 (strcmp "b" "b"))
          (assert_greater_than 0 (strcmp "c" "b"))
          (set pow (NuBridgedFunction functionWithName:"pow" signature:"ddd"))
          (assert_equal 8 (pow 2 3))))

