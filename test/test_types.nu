;; test_types.nu
;;  tests for Nu type handling.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestTypes is NuTestCase
     
     ;; void methods should always return void
     (- (id) testVoidMethodReturnTypes is
        (class TestTypesClass is NSObject
             (- (void) test-instancemethod is 1234)
             (+ (void) test-classmethod is 1234))
        (assert_equal nil (((TestTypesClass alloc) init) test-instancemethod))
        (assert_equal nil (TestTypesClass test-classmethod))))