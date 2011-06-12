;; test_varargs.nu
;;  tests for Nu support for blocks with variable numbers of arguments.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestVarArgs is NuTestCase
     
     (- (id) testSimple is
        (set f (do (a *b) (*b length)))
        (assert_throws "NuIncorrectNumberOfArguments" (f))
        (assert_equal 0 (f 1))
        (assert_equal 1 (f 1 2))
        (assert_equal 2 (f 1 2 3))
        (assert_equal 5 (f 1 2 3 4 5 6)))
     
     ;; the array operator is implemented with a varargs function
     (- (id) testArrayOperator is
        (set a (array 9 42 37 1 17 30 11 28))
        (set sorted (a sortedArrayUsingBlock:(do (x y) (y compare:x))))
        (assert_equal (array 42 37 30 28 17 11 9 1) sorted)
        (set a (array "mary" "christopher" "ed" "brian" "tim" "jennifer"))
        (set sorted (a sortedArrayUsingBlock:(do (x y) ((x length) compare:(y length)))))
        (assert_equal (array "ed" "tim" "mary" "brian" "jennifer" "christopher") sorted)
        (assert_equal 1 (sorted isEqualToArray:(array "ed" "tim" "mary" "brian" "jennifer" "christopher"))))
     
     ;; the dict operator is implemented with a varargs function
     (- (id) testDictOperator is
        (set d (dict 'foo 1 bar: (+ 2 2)))
        (assert_equal 1 (d objectForKey:'foo))
        (assert_equal 4 (d objectForKey:"bar"))))





