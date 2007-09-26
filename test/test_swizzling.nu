;; test_swizzling.nu
;;  tests for Nu method swizzling.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestSwizzling is NuTestCase
     
     (imethod (id) testInstanceMethodSwizzling is
          (class Test1 is NSObject
               (imethod (id) foo is "foo")
               (imethod (id) bar is "bar"))
          (set tester ((Test1 alloc) init))
          ;; before the swap
          (assert_equal "foo" (tester foo))
          (assert_equal "bar" (tester bar))
          ;; make the exchange
          (Test1 exchangeInstanceMethod:"foo" withMethod:"bar")
          ;; after the swap
          (assert_equal "bar" (tester foo))
          (assert_equal "foo" (tester bar))
          ;; put them back
          (Test1 exchangeInstanceMethod:"bar" withMethod:"foo")
          ;; now we should be back as we started
          (assert_equal "foo" (tester foo))
          (assert_equal "bar" (tester bar)))
     
     (imethod (id) testClassMethodSwizzling is
          (class Test2 is NSObject
               (cmethod (id) foo is "foo")
               (cmethod (id) bar is "bar"))         
          ;; before the swap
          (assert_equal "foo" (Test2 foo))
          (assert_equal "bar" (Test2 bar))
          ;; make the exchange
          (Test2 exchangeClassMethod:"foo" withMethod:"bar")
          ;; after the swap
          (assert_equal "bar" (Test2 foo))
          (assert_equal "foo" (Test2 bar))
          ;; put them back
          (Test2 exchangeClassMethod:"bar" withMethod:"foo")
          ;; now we should be back as we started
          (assert_equal "foo" (Test2 foo))
          (assert_equal "bar" (Test2 bar))))