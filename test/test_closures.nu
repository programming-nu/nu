;; test_closures.nu
;;  tests for Nu closures.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

;; These tests will fail with old-style (0.1.x) Nu closures,
;; which can be enabled by defining CLOSE_ON_VALUES at compilation time.
;; In Nu-0.2.0 and later, closures are made on name bindings.

(class TestClosures is NuTestCase
     
     (- (id) testAccumulator is
        ;; The accumulator function from Paul Graham's
        ;; "Revenge of the Nerds", http://www.paulgraham.com/icad.html
        (function make-accumulator (n)
             (do (i) (set n (+ n i))))
        (set accumulator (make-accumulator 0))
        (assert_equal 1 (accumulator 1))
        (assert_equal 3 (accumulator 2))
        (assert_equal 6 (accumulator 3))
        (set accumulator (make-accumulator 5))
        (assert_equal 6 (accumulator 1))
        (assert_equal 8 (accumulator 2))
        (assert_equal 11 (accumulator 3)))
     
     (- (id) testScoping is
        (set x 0)
        ;; Here we redefine x inside the let context, so
        ;; assignments to x in the block do not affect the outer x
        (10 times: (do (i) (let ((x x)) (set x (+ x 1)))))
        (assert_equal 0 x)
        ;; Here we refer to the outer binding of x, so
        ;; assignments to x in the block do affect the outer x
        (10 times: (do (i) (set x (+ x 1)) (set y x)))
        (assert_equal 10 x)
        (assert_equal 10 ((context) objectForKey:'x))
        ;; but assignments to y are invisible in the outer context
        (assert_equal nil ((context) objectForKey:'y))))