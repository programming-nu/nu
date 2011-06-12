;; test_operators.nu
;;  tests for Nu operators.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestOperators is NuTestCase
     
     (- (id) testMinOperator is
        (assert_equal -5 (min (* 5 -1) 10 20 30 40 50000))
        (assert_equal 40.0 (min 40.0 400.0 19992.5))
        (assert_equal "a" (min "a" "b" "c" "d" "e"))
        (assert_equal 'x' (min 'x' 'y' 'z')))
     
     (- (id) testMaxOperator is
        (assert_equal 50000 (max -5 10 20 30 40 (* 500 100)))
        (assert_equal 19992.5 (max 40.0 400.0 19992.5))
        (assert_equal "e" (max "a" "b" "c" "d" "e"))
        (assert_equal 'z' (max 'x' 'y' 'z')))
     
     (- (id) testAddOperator is
        (assert_equal 3 (+ 1 1 -5 6))
        (assert_equal "hello, world" (+ "hello" "," " " "world")))
     
     (- (id) testSubtractOperator is
        (assert_equal -3 (- 3))
        (assert_equal 1 (- 4 2 1)))
     
     ;; turn this off by default; it's a good test, but it requires manual intervention
     (- (id) dontTestTheGetsOperator is
        (assert_not_equal nil gets)
        (puts "\nPlease don't enter anything.")
        (assert_equal (gets) ""))
     
     (- (id) testIfOperator is
        (set x 0)
        (assert_equal 'yes (if t 'yes))
        (assert_equal 'yes (if t (set x 1) 'yes))
        (assert_equal x 1)
        (assert_equal 'yes (if t 'yes (else (set x 'error))))
        (assert_equal x 1)
        (assert_equal 'yes (if t (then 'yes)))
        (assert_equal 'yes (if t (then (set x 2) 'yes)))
        (assert_equal x 2)
        (assert_equal 'yes (if t (then 'yes) (else (set x 'error))))
        (assert_equal x 2)
        (assert_equal 'no (if nil (else 'no)))
        (assert_equal 'no (if nil (else (set x 3) 'no)))
        (assert_equal x 3)
        (assert_equal 'no (if nil (set x 'error) (else 'no)))
        (assert_equal x 3)
        (assert_equal 'no (if nil (then (set x 'error)) (else 'no)))
        (assert_equal x 3))
     
     (- (id) testIfSugaredOperator is
        (set x 0)
        (assert_equal 'yes (if t then 'yes))
        (assert_equal 'yes (if t then (set x 1) 'yes))
        (assert_equal x 1)
        (assert_equal 'yes (if t then 'yes else (set x 'error)))
        (assert_equal x 1)
        (assert_equal 'yes (if t then 'yes (else (set x 'error))))
        (assert_equal x 1)
        (assert_equal 'no (if nil else 'no))
        (assert_equal 'no (if nil else (set x 2) 'no))
        (assert_equal x 2)
        (assert_equal 'no (if nil (set x 'error) else 'no))
        (assert_equal x 2)
        (assert_equal 'no (if nil then (set x 'error) else 'no))
        (assert_equal x 2)
        (assert_equal 'no (if nil (then (set x 'error)) else 'no))
        (assert_equal x 2))
     
     (- (id) testUnlessOperator is
        (set x 0)
        (assert_equal 'yes (unless nil 'yes))
        (assert_equal 'yes (unless nil (set x 1) 'yes))
        (assert_equal x 1)
        (assert_equal 'yes (unless nil 'yes (else (set x 'error))))
        (assert_equal x 1)
        (assert_equal 'yes (unless nil (then 'yes)))
        (assert_equal 'yes (unless nil (then (set x 2) 'yes)))
        (assert_equal x 2)
        (assert_equal 'yes (unless nil (then 'yes) (else (set x 'error))))
        (assert_equal x 2)
        (assert_equal 'no (unless t (else 'no)))
        (assert_equal 'no (unless t (else (set x 3) 'no)))
        (assert_equal x 3)
        (assert_equal 'no (unless t (set x 'error) (else 'no)))
        (assert_equal x 3)
        (assert_equal 'no (unless t (then (set x 'error)) (else 'no)))
        (assert_equal x 3))
     
     (- (id) testUnlessSugaredOperator is
        (set x 0)
        (assert_equal 'yes (unless nil then 'yes))
        (assert_equal 'yes (unless nil then (set x 1) 'yes))
        (assert_equal x 1)
        (assert_equal 'yes (unless nil then 'yes else (set x 'error)))
        (assert_equal x 1)
        (assert_equal 'yes (unless nil then 'yes (else (set x 'error))))
        (assert_equal x 1)
        (assert_equal 'no (unless t else 'no))
        (assert_equal 'no (unless t else (set x 2) 'no))
        (assert_equal x 2)
        (assert_equal 'no (unless t (set x 'error) else 'no))
        (assert_equal x 2)
        (assert_equal 'no (unless t then (set x 'error) else 'no))
        (assert_equal x 2)
        (assert_equal 'no (unless t (then (set x 'error)) else 'no))
        (assert_equal x 2))
     
     ;; support for elseif was removed because elseif is easily confused with elif (Python)
     ;; and elsif (Ruby), etc. and because cond does the job anyway.
     (- (id) dontTestIfElseifOperator is
        (set x 1)
        (set y 'true)
        (assert_equal 'one (if (eq x 0) 'none
                               elseif (eq x 1) 'one
                               else 'many))
        (assert_equal 'one (if (eq x 0) 'none
                               elseif (eq x 2) 'two
                               elseif (eq x 1) 'one
                               else 'more))
        (assert_equal 'one (if (eq x 0) (set y 'none)
                               elseif (eq x 1) 'one
                               else (set y 'many)))
        (assert_equal y 'true)
        (assert_equal 'one (if (eq x 0) (set y 'none)
                               elseif (eq x 2) (set y 'two)
                               elseif (eq x 1) 'one
                               else (set y 'more)))
        (assert_equal y 'true)
        (assert_equal 'one (if (eq x 0) 'none
                               elseif (eq x 1)
                               (set y 'one)
                               'one
                               else 'many))
        (assert_equal y 'one)
        (assert_equal 'one (if (eq x 0) 'none
                               elseif (eq x 2) 'two
                               elseif (eq x 1)
                               (set y 'two)
                               'one
                               else 'more))
        (assert_equal y 'two))
     
     (- (id) dontTestUnlessElseifOperator is
        (set x 1)
        (set y 'true)
        (assert_equal 'one (unless ((not (eq x 0))) 'none
                                   elseif (eq x 1) 'one
                                   else 'many))
        (assert_equal 'one (unless ((not (eq x 0))) 'none
                                   elseif (eq x 2) 'two
                                   elseif (eq x 1) 'one
                                   else 'more))
        (assert_equal 'one (unless ((not (eq x 0))) (set y 'none)
                                   elseif (eq x 1) 'one
                                   else (set y 'many)))
        (assert_equal y 'true)
        (assert_equal 'one (unless ((not (eq x 0))) (set y 'none)
                                   elseif (eq x 2) (set y 'two)
                                   elseif (eq x 1) 'one
                                   else (set y 'more)))
        (assert_equal y 'true)
        (assert_equal 'one (unless ((not (eq x 0))) 'none
                                   elseif (eq x 1)
                                   (set y 'one)
                                   'one
                                   else 'many))
        (assert_equal y 'one)
        (assert_equal 'one (unless ((not (eq x 0))) 'none
                                   elseif (eq x 2) 'two
                                   elseif (eq x 1)
                                   (set y 'two)
                                   'one
                                   else 'more))
        (assert_equal y 'two)))
