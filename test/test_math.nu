;; test_math.nu
;;  tests for Nu math functions.
;;
;;  Copyright (c) 2007 Michael Burks/Tim Burks, Neon Design Technology, Inc.

(set PI 3.14159)
(set E 2.71828)

(class TestMath is NuTestCase
     
     (imethod (id) testExp is
          (assert_equal 1 (NuMath exp:0))
          (assert_in_delta E (NuMath exp:1) 0.001))
     
     (imethod (id) testExp2 is
          (assert_equal 1 (NuMath exp2:0))
          (assert_in_delta 2 (NuMath exp2:1) 0.001))
     
     (imethod (id) testCos is
          (assert_in_delta -1 (NuMath cos:PI) 0.001)
          (assert_equal 1 (NuMath cos:0))
          (assert_in_delta 0 (NuMath cos:(* 1.5 PI)) 0.001))
     
     (imethod (id) testSin is
          (assert_equal 0 (NuMath sin:0))
          (assert_in_delta 0 (NuMath sin:PI) 0.001)
          (assert_in_delta 1 (NuMath sin:(* 0.5 PI)) 0.001))
     
     (imethod (id) testSqrt is
          (assert_equal 0 (NuMath sqrt:0))
          (assert_equal 1.5 (NuMath sqrt:2.25))
          (assert_in_delta 1.732 (NuMath sqrt:3) 0.001))
     
     (imethod (id) testCbrt is
          (assert_equal 0 (NuMath cbrt:0))
          (assert_equal 1.5 (NuMath cbrt:3.375))
          (assert_in_delta 1.587 (NuMath cbrt:4) 0.001))
     
     (imethod (id) testSquare is
          (assert_equal 49 (NuMath square:7))
          (assert_equal 20.25 (NuMath square:4.5)))
     
     (imethod (id) testLog is
          (assert_equal 0 (NuMath log:1))
          (assert_in_delta 2 (NuMath log:(* E E)) 0.001))
     
     (imethod (id) testLog2 is
          (assert_equal 0 (NuMath log2:1))
          (assert_in_delta 2 (NuMath log2:(* 2 2)) 0.001))
     
     (imethod (id) testLog10 is
          (assert_equal 0 (NuMath log10:1))
          (assert_in_delta 2 (NuMath log10:(* 10 10)) 0.001))
     
     (imethod (id) testAbs is
          (assert_equal 6 (NuMath abs:6))
          (assert_equal PI (NuMath abs:(- 0 PI))))
     
     (imethod (id) testFloor is
          (assert_equal 9 (NuMath floor:9.99))
          (assert_equal -10 (NuMath floor:-9.99))
          (assert_equal 3 (NuMath floor:PI))
          (assert_equal -4 (NuMath floor:(- 0 PI))))
     
     (imethod (id) testCeil is
          (assert_equal 10 (NuMath ceil:9.99))
          (assert_equal -9 (NuMath ceil:-9.99))
          (assert_equal 4 (NuMath ceil:PI))
          (assert_equal -3 (NuMath ceil:(- 0 PI))))
     
     (imethod (id) testRound is
          (assert_equal 10 (NuMath round:9.99))
          (assert_equal 10 (NuMath round:9.5))
          (assert_equal -10 (NuMath round:-9.99))
          (assert_equal 3 (NuMath round:PI))
          (assert_equal -3 (NuMath round:(- 0 PI))))
     
     (imethod (id) testIntegerDivide is
          (assert_equal 3 (NuMath integerDivide:10 by:3))
          (assert_equal 4 (NuMath integerDivide:17 by:4))
          (assert_equal 4 (NuMath integerDivide:16 by:4))
          (assert_equal -3  (NuMath integerDivide:-50 by:13)))     ;; questionable
     
     (imethod (id) testIntegerMod is
          (assert_equal 1 (NuMath integerMod:10 by:3))
          (assert_equal 1 (NuMath integerMod:17 by:4))
          (assert_equal 0 (NuMath integerMod:16 by:4))
          (assert_equal -11 (NuMath integerMod:-50 by:13)))			;; questionable
     
     (imethod (id) testRaiseNumber is
          (assert_equal 1 (NuMath raiseNumber:10 toPower:0))
          (assert_equal 169 (NuMath raiseNumber:13 toPower:2))
          (assert_equal 8 (NuMath raiseNumber:64 toPower:0.5))
          (assert_equal 0.5 (NuMath raiseNumber:4 toPower:-0.5)))
     
     (imethod (id) testArithmeticOperators is
          (assert_equal 4 	(+ 2 2))
          (assert_equal 15 	(- 20 5))
          (assert_equal 20 	(* 2 2 5))
          (assert_equal 13 	(/ 26 2))
          (assert_equal 64    (** 8 2))
          (assert_equal 7	(% 47 8))
          (assert_equal 4 	(& 7 12))
          (assert_equal 15 	(| 7 12)))
     
     (imethod (id) testComparisonOperators is
          (assert_equal nil (> 10 20))
          (assert_equal nil (> 20 20))
          (assert_equal t   (> 30 20))
          
          (assert_equal t   (< 10 20))
          (assert_equal nil (< 20 20))
          (assert_equal nil (< 30 20))
          
          (assert_equal nil (>= 10 20))
          (assert_equal t   (>= 20 20))
          (assert_equal t   (>= 30 20))
          
          (assert_equal t   (<= 10 20))
          (assert_equal t   (<= 20 20))
          (assert_equal nil (<= 30 20))
          
          (assert_equal t   (eq 20 20))
          (assert_equal nil (eq 30 20))
          
          (assert_equal t   (== 20 20))
          (assert_equal nil (== 30 20))
          
          (assert_equal nil (!= 20 20))
          (assert_equal t   (!= 30 20)))
     
     (imethod (id) testShiftOperators is
          (assert_equal 4   (<< 1 2))
          (assert_equal 1   (>> 4 2)))
     
     (imethod (id) testBooleanOperators is
          (assert_equal nil (and 1 2 3 0))
          (assert_equal 4   (and 1 2 3 4))
          
          (assert_equal nil (or 0 nil 0 0))
          (assert_equal 4   (or 0 nil 4 0))
          
          (assert_equal nil (not 1))
          (assert_equal nil (not t))
          (assert_equal t   (not 0))
          (assert_equal t   (not nil))))