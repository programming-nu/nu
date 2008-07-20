;; test_nu.nu
;;  tests for basic Nu functionality.
;;
;;  Copyright (c) 2008 Issac Trotts

(class TestNu is NuTestCase
     
     (imethod (id) testSymbol? is
         (assert_true (symbol? 'a))
         (assert_true (symbol? 'ab))
         (assert_false (symbol? 1))
         (assert_false (symbol? "a"))
         (assert_false (symbol? nil))
         (assert_false (symbol? '(a b))))

     (imethod (id) testAtom? is
         (assert_true (atom? 'a))
         (assert_true (atom? nil))
         (assert_true (atom? 1))
         (assert_true (atom? ""))  ;; debatable
         (assert_true (atom? "a"))  ;; debatable
         (assert_true (atom? 'a'))
         (assert_false (atom? '(1)))
         (assert_false (atom? '(array 1)))))
