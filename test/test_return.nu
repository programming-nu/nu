;; test_return.nu
;;  tests for the Nu return operator.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestReturn is NuTestCase
     
     (- testReturnVoid is
        (function f (n)
             (if (>= n 0) (return))
             "negative")
        (assert_equal "negative" (f -1))
        (assert_equal nil (f 1)))
     
     (- testReturnValue is
        (function f (n)
             (if (> n 0) (return "positive"))
             (if (eq n 0) (return "zero"))
             "negative")
        (assert_equal "negative" (f -1))
        (assert_equal "zero" (f 0))
        (assert_equal "positive" (f 1)))
     
     (- testReturnNested is
        (function f (n)
             (if (> n 0) (return "positive"))
             (if (eq n 0) (return "zero"))
             "negative")
        (function g (n)
             (if (eq (f n) "positive") (return "+"))
             (if (eq (f n) "zero") (return "0"))
             "-")
        (assert_equal "-" (g -1))
        (assert_equal "0" (g 0))
        (assert_equal "+" (g 1)))
     
     (- testReturnFromMethod is
        (class ReturnTestClass is NSObject
             (- (id) sign:(id) n is
                (if (> n 0) (return "positive"))
                (if (eq n 0) (return "zero"))
                "negative")
             (+ (id) sign:(id) n is
                (if (> n 0) (return "+"))
                (if (eq n 0) (return "0"))
                "-"))
        (set rtc ((ReturnTestClass alloc) init))
        (assert_equal "negative" (rtc sign:-1))
        (assert_equal "zero" (rtc sign:0))
        (assert_equal "positive" (rtc sign:1))
        (assert_equal "-" (ReturnTestClass sign:-1))
        (assert_equal "0" (ReturnTestClass sign:0))
        (assert_equal "+" (ReturnTestClass sign:1))))