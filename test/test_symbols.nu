;; test_symbols.nu
;;  tests for Nu symbols.
;;
;;  Copyright (c) 2009 Tim Burks, Radtastical Inc.

(class TestSymbols is NuTestCase
     
     (- testDefined is
        (assert_equal nil (defined madeUpName))
        (assert_equal t (defined 123))
        (set madeUpName 123)
        (assert_equal t (defined madeUpName))))

