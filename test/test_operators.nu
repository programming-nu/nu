;; test_operators.nu
;;  tests for Nu operators.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestOperators is NuTestCase
     
     ;; Our "ternary operator" is really a method and not an operator, but I think it belongs 
     ;; here in the same way that a tomato (a fruit) belongs in a salad of vegetables.
     (imethod (id) testTernaryOperator is
          (assert_equal "no" (nil ? "yes" : "no"))
          (assert_equal "no" (() ? "yes" : "no")) 
          (assert_equal "no" (0 ? "yes" : "no"))
          (assert_equal "yes" (t ? "yes" : "no"))
          (assert_equal "yes" ('(a b c) ? "yes" : "no"))
          (assert_equal "yes" (1 ? "yes" : "no"))
          (assert_equal "yes" ((== 4 (+ 2 2)) ? "yes" : "no"))
          (assert_equal "no" ((== 4 (+ 2 2 2)) ? "yes" : "no"))
          (set x 1) 
          (assert_equal "one" ((== x 0) ? "zero" : ((== x 1) ? "one" : "many")))
          (set x 2) 
          (assert_equal "many" ((== x 0) ? "zero" : ((== x 1) ? "one" : "many"))))
     
     ;; add more operator tests below...
     
     )
