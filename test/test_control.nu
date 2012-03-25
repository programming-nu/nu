;; test_control.nu
;;  tests for Nu control structures.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestControl is NuTestCase
     
     (- (id) testIf is
        (set x 0)
        (if (== x 0)
            (then (set y 0) (set y (+ y 1)))
            (else (if (== x 1)
                      (then (set y 10) (set y (+ y 1)))
                      (else (set y 100) (set y (+ y 1)))
                      (set y (+ y 1))))
            (set y (+ y 1)))
        (assert_equal 2 y)
        
        (set x 1)
        (if (== x 0)
            (then (set y 0) (set y (+ y 1)))
            (else (if (== x 1)
                      (then (set y 10) (set y (+ y 1)))
                      (else (set y 100) (set y (+ y 1)))
                      (set y (+ y 1))))
            (set y (+ y 1)))
        (assert_equal 12 y)
        
        (set x 2)
        (if (== x 0)
            (then (set y 0) (set y (+ y 1)))
            (else (if (== x 1)
                      (then (set y 10) (set y (+ y 1)))
                      (else (set y 100) (set y (+ y 1)))
                      (set y (+ y 1))))
            (set y (+ y 1)))
        (assert_equal 101 y))
     
     (- (id) testUnless is
        (set x 0)
        (unless (!= x 0)
                (then (set y 0) (set y (+ y 1)))
                (else (unless (!= x 1)
                              (then (set y 10) (set y (+ y 1)))
                              (else (set y 100) (set y (+ y 1)))
                              (set y (+ y 1))))
                (set y (+ y 1)))
        (assert_equal 2 y)
        
        (set x 1)
        (unless (!= x 0)
                (then (set y 0) (set y (+ y 1)))
                (else (unless (!= x 1)
                              (then (set y 10) (set y (+ y 1)))
                              (else (set y 100) (set y (+ y 1)))
                              (set y (+ y 1))))
                (set y (+ y 1)))
        (assert_equal 12 y)
        
        (set x 2)
        (unless (!= x 0)
                (then (set y 0) (set y (+ y 1)))
                (else (unless (!= x 1)
                              (then (set y 10) (set y (+ y 1)))
                              (else (set y 100) (set y (+ y 1)))
                              (set y (+ y 1))))
                (set y (+ y 1)))
        (assert_equal 101 y))
     
     (- (id) testWhile is
        (set x 10)
        (set y 0)
        (while x
               (set y (+ y x))
               (set x (- x 1)))
        (assert_equal 55 y))
     
     (- (id) testUntil is
        (set x 10)
        (set y 0)
        (until (== x 0)
               (set y (+ y x))
               (set x (- x 1)))
        (assert_equal 55 y))
     
     (- (id) testWhileBreak is
        (set $count 0)
        (set x 10)
        (while (!= x 0)
               (set x (- x 1))
               (set y 10)
               (while (!= y 0)
                      (set y (- y 1))
                      (set $count (+ $count 1))
                      (if (eq y 5) (break))))
        (assert_equal 50 $count))
     
     (- (id) testWhileContinue is
        (set $count 0)
        (set x 10)
        (while (!= x 0)
               (set x (- x 1))
               (set y 10)
               (while (!= y 0)
                      (set y (- y 1))
                      (if (>= y 5) (continue))
                      (set $count (+ $count 1))))
        (assert_equal 50 $count))
     
     (- (id) testUntilBreak is
        (set count 0)
        (set x 10)
        (until (== x 0)
               (set x (- x 1))
               (set y 10)
               (until (== y 0)
                      (set y (- y 1))
                      (set count (+ count 1))
                      (if (eq y 5) (break))))
        (assert_equal 50 count))
     
     (- (id) testUntilContinue is
        (set count 0)
        (set x 10)
        (until (== x 0)
               (set x (- x 1))
               (set y 10)
               (until (== y 0)
                      (set y (- y 1))
                      (if (>= y 5) (continue))
                      (set count (+ count 1))))
        (assert_equal 50 count))
     
     (- (id) testLoopMacro is
        ;; here is a simple macro defining an unending loop
        (macro loop (*body)
         `(while t
             ,@*body))

        ;; here's a macro that decrements a named value
        (macro decrement (n)
         `(set ,n (- ,n 1)))

        ;; here's a macro that increments a named value
        (macro increment (n)
         `(set ,n (+ ,n 1)))
        
        ;; run the loop, breaking out after 5 iterations
        (set count 0)
        (set x 10)
        (loop
             (decrement x)
             (increment count)
             (if (eq x 5) (break)))
        (assert_equal 5 count)
        ;; run the loop, breaking out after 10 iterations
        ;; but only counting until the loop counter (x) drops below 5
        (set count 0)
        (set x 10)
        (loop
             (decrement x)
             (if (eq x 0) (break))
             (if (< x 5) (continue))
             (increment count))
        (assert_equal 5 count))
     
     (- (id) testFor is
        (set x 0)
        (for ((set i 1) (< i 10) (set i (+ i 1)))
             (set x (+ x i)))
        (assert_equal 45 x))
     
     (- (id) testForBreak is
        (set x 0)
        (for ((set i 1) (< i 10) (set i (+ i 1)))
             (if (== i 6) (break))
             (set x (+ x i)))
        (assert_equal 15 x))
     
     (- (id) testForContinue is
        (set x 0)
        (for ((set i 1) (< i 10) (set i (+ i 1)))
             (if (== i 6) (continue))
             (set x (+ x i)))
        (assert_equal 39 x))
     
     (- (id) testCond is
        (set x 0)
        (assert_equal 1
             (cond
                  ((== x 0) (set y 0)   (set y (+ y 1)))
                  ((== x 1) (set y 10)  (set y (+ y 1)))
                  (else     (set y 100) (set y (+ y 1)))))
        
        (set x 1)
        (assert_equal 11
             (cond
                  ((== x 0) (set y 0)   (set y (+ y 1)))
                  ((== x 1) (set y 10)  (set y (+ y 1)))
                  (else     (set y 100) (set y (+ y 1)))))
        
        (set x 2)
        (assert_equal 101
             (cond
                  ((== x 0) (set y 0)   (set y (+ y 1)))
                  ((== x 1) (set y 10)  (set y (+ y 1)))
                  (else     (set y 100) (set y (+ y 1)))))
        
        ;; test fallthrough
        (assert_equal 1
             (cond (1)
                   (else 2)))
        
        (assert_equal 1
             (cond (0)
                   (1)
                   (else 2)))
        
        (assert_equal 2
             (cond (0)
                   (0)
                   (else 2)))
        
        (assert_equal 2
             (cond (0)
                   (0)
                   (2))))
     
     (- (id) testCase is
        (set x 0)
        (assert_equal 1
             (case x
                   (0    (set y 0)   (set y (+ y 1)))
                   (1    (set y 10)  (set y (+ y 1)))
                   (else (set y 100) (set y (+ y 1)))))
        
        (set x 1)
        (assert_equal 11
             (case x
                   (0    (set y 0)   (set y (+ y 1)))
                   (1    (set y 10)  (set y (+ y 1)))
                   (else (set y 100) (set y (+ y 1)))))
        
        (set x 2)
        (assert_equal 101
             (case x
                   (0    (set y 0)   (set y (+ y 1)))
                   (1    (set y 10)  (set y (+ y 1)))
                   (else (set y 100) (set y (+ y 1)))))))

