;; test_types.nu
;;  tests for Nu type handling.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestTypes is NuTestCase
     
     ;; void methods should always return void
     (imethod (id) testVoidMethodReturnTypes is          
          (class TestTypesClass is NSObject
               (imethod (void) test-imethod is 1234)
               (cmethod (void) test-cmethod is 1234))          
          (assert_equal nil (((TestTypesClass alloc) init) test-imethod))
          (assert_equal nil (TestTypesClass test-cmethod))))          