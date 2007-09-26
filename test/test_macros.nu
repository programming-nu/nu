;; test_macros.nu
;;  tests for Nu macros.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestMacros is NuTestCase
     
     (imethod (id) testFactorialFunction is
          (function fact (x)
               (if (== x 0) 
                   (then 1)
                   (else (* (fact (- x 1)) x))))      
          (assert_equal 24 (fact 4)))
     
     ;; recursive macro test case done wrong.
     ;; because x is not a gensym it keeps getting redefined in the recursive descent
     (imethod (id) testBrokenFactorialMacro is
          (macro mfact	
               (set x (eval (car margs)))
               (if (== x 0) 
                   (then 1)
                   (else (* (mfact (- x 1)) x))))          
          (assert_equal 0 (mfact 4)))
     
     ;; recursive macro test case done right.
     ;; names prefixed with the "__" sigil are gensyms.
     (imethod (id) testFactorialMacro is
          (macro mfact	
               (set __x (eval (car margs)))
               (if (== __x 0) 
                   (then 1)
                   (else (* (mfact (- __x 1)) __x))))          
          (assert_equal 24 (mfact 4)))
     
     ;; test string interpolation of gensyms
     (imethod (id) testGensymInterpolation is
          (macro interpolateGensym
			  (set __x 123)
			  (set __y 456)
			  "you got #{__x} and #{__y}")
		  (assert_equal "you got 123 and 456" (interpolateGensym)))	
     
     ;; test some macro implementation details
     (imethod (id) testMacroImplementation is
          (set s (NuSymbolTable sharedSymbolTable))
          (macro forty (set __x 22) (set __y (+ __x 18)))
          (set newBody (send forty body:(send forty body) withGensymPrefix:"g999" symbolTable:s))
          (assert_equal "((set g999__x 22) (set g999__y (+ g999__x 18)))" (newBody stringValue))))

