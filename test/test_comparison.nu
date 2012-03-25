;; test_comparison.nu
;;  tests for Nu comparison operators.
;;
;;  Copyright (c) 2008 Tim Burks, Radtastical Inc.

(class TestComparison is NuTestCase
     
     (- testLessThan is
        (assert_equal t (< 1 2 3))
        (assert_equal t (< "a" "b" "c"))
        (assert_equal nil (< 1 2 3 3))
        (assert_equal nil (< "b" "a")))
     
     (- testGreaterThan is
        (assert_equal t (> 3 2 1))
        (assert_equal t (> "c" "b" "a"))
        (assert_equal nil (> 3 2 1 1))
        (assert_equal nil (> "a" "b")))
     
     (- testLessThanOrEqual is
        (assert_equal t (<= 1 2 2 3))
        (assert_equal t (<= "a" "b" "b" "c"))
        (assert_equal nil (<= 1 2 3 2))
        (assert_equal nil (<= "b" "a")))
     
     (- testGreaterThanOrEqual is
        (assert_equal t (>= 3 2 2 1))
        (assert_equal t (>= "c" "b" "b" "a"))
        (assert_equal nil (>= 3 2 1 2))
        (assert_equal nil (>= "a" "b")))
     
     (- testCustomComparison is
        
        (class NumericString is NSObject
             (+ stringWithString:s is ((self alloc) initWithString:s))
             (- initWithString:s is
                (self init)
                (set @string s)
                self)
             (- stringValue is @string)
             (- description is @string)
             (- (int) compare:(id) other is
                ((@string intValue) compare:((other stringValue) intValue))))
        
        (set x (NumericString stringWithString:"123"))
        (set y (NumericString stringWithString:"45"))
        (set z (NumericString stringWithString:"12"))
        
        (set a ((array x y z) sort))
        
        (assert_equal "12" ((a 0) stringValue))
        (assert_equal "45" ((a 1) stringValue))
        (assert_equal "123" ((a 2) stringValue))
        
        (assert_equal nil (<= x y))
        (assert_equal nil (< x y))
        (assert_equal t   (>= x y))
        (assert_equal t   (> x y))))