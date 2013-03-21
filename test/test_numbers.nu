;; test_numbers.nu
;;  tests for Nu extensions to NSNumber.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestNumbers is NuTestCase
 
 (- testTimes is
    (set sum 0)
    (10 times:
        (do (i) (set sum (+ sum i))))
    (assert_equal 45 sum))
 
 (- testDownTo is
    (set firstValue nil)
    (set lastValue nil)
    (set sum 0)
    (10 downTo:5 do:
        (do (i)
            (set sum (+ sum i))
            (unless firstValue (set firstValue i))
            (set lastValue i)))
    (assert_equal 45 sum)
    (assert_equal 10 firstValue)
    (assert_equal 5 lastValue))
 
 (- testUpTo is
    (set firstValue nil)
    (set lastValue nil)
    (set sum 0)
    (5 upTo:10 do:
       (do (i)
           (set sum (+ sum i))
           (unless firstValue (set firstValue i))
           (set lastValue i)))
    (assert_equal 45 sum)
    (assert_equal 5 firstValue)
    (assert_equal 10 lastValue))
 
 (- testBooleans is
    ;; YES and NO should be bools and should show up as bools in property lists
    (assert_equal ((NSNumber numberWithBool:YES) class) (YES class))
    (assert_equal ((NSNumber numberWithBool:NO) class) (NO class))
    (assert (/<true\/>/ findInString: (NSString stringWithData:((dict x:YES) XMLPropertyListRepresentation) encoding:NSUTF8StringEncoding)))
    (assert (/<false\/>/ findInString: (NSString stringWithData:((dict x:NO) XMLPropertyListRepresentation) encoding:NSUTF8StringEncoding)))))