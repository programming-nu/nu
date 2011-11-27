;; test_bridge.nu
;;  tests for the Nu bridge to Objective-C.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestBridge is NuTestCase
     (- (id) testConstants is
        (if (eq (uname) "Darwin")
        (set floatTypeSignature (if (eq (Nu sizeOfPointer) 8) (then "d") (else "f")))
        (assert_equal 0 (NuBridgedConstant constantWithName:"NSBlack" signature:floatTypeSignature))
        (assert_equal 1 (NuBridgedConstant constantWithName:"NSWhite" signature:floatTypeSignature))
        (assert_equal '(0 0 0 0) (NuBridgedConstant constantWithName:"NSZeroRect" signature:"{_NSRect}"))
        (assert_equal (NSApplication sharedApplication) (NuBridgedConstant constantWithName:"NSApp" signature:"@"))))
     
     (- (id) testFunctions is
        (set strcmp (NuBridgedFunction functionWithName:"strcmp" signature:"i**"))
        (assert_less_than 0 (strcmp "a" "b"))
        (assert_equal 0 (strcmp "b" "b"))
        (assert_greater_than 0 (strcmp "c" "b"))
        (set pow (NuBridgedFunction functionWithName:"pow" signature:"ddd"))
        (assert_equal 8 (pow 2 3)))
     
     (- (id) testBridgedStructs is
        ;; verifies that Nu methods can be created that return bridged structs to Objective-C callers.
        ;; Uses the builtin NuTestHelper class.
        (class StructHelper is NSObject
             (- (CGRect) CGRectValue is (list 1 2 3 4))
             (- (CGPoint) CGPointValue is (list 1 2))
             (- (CGSize) CGSizeValue is (list 3 4))
             (- (NSRange) NSRangeValue is (list 5 6)))
        (set structHelper (StructHelper new))
        (assert_equal (list 1 2 3 4) (NuTestHelper getCGRectFromProxy:structHelper))
        (assert_equal (list 1 2) (NuTestHelper getCGPointFromProxy:structHelper))
        (assert_equal (list 3 4) (NuTestHelper getCGSizeFromProxy:structHelper))
        (assert_equal (list 5 6) (NuTestHelper getNSRangeFromProxy:structHelper)))
     (- (id) testBlocks is
	(load "cblocks")
	(let ((num nil)
	      (num-array (array 1 2)))
	  (set equals-num? (cblock BOOL ((id) obj (unsigned long) idx (void*) stop)
				   (if (== obj num) YES (else NO))))
	  (set num 1)
	  (assert_equal 0 (num-array indexOfObjectPassingTest:equals-num?))
	  (set num 2)
	  (assert_equal 1 (num-array indexOfObjectPassingTest:equals-num?)))))

