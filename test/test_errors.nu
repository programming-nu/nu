;; test_errors.nu
;;  tests for Nu errors that throw exceptions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestErrors is NuTestCase
     
     (imethod (id) testParseError is
          (try
              (parse "(1 + ))") ;; parse error
              (catch (exception) (set myException exception)))
          (assert_equal "NuParseError" (myException name)))
     
     (imethod (id) testUndefinedSymbol is
          (try
              foo ;; undefined symbol
              (catch (exception) (set myException exception)))
          (assert_equal "NuUndefinedSymbol" (myException name)))
     
     (imethod (id) testCarOnAtom is
          (try
              (car 'foo) ;; can't call car on atoms
              (catch (exception) (set myException exception)))
          (assert_equal "NuCarCalledOnAtom" (myException name)))
     
     (imethod (id) testCdrOnAtom is
          (try
              (cdr 'foo) ;; can't call cdr on atoms
              (catch (exception) (set myException exception)))
          (assert_equal "NuCdrCalledOnAtom" (myException name)))
     
     (imethod (id) testIncorrectNumberOfBlockArguments is
          (try
              ((do (x y) (+ x y)) 1 2 3) ;; incorrect number of block arguments
              (catch (exception) (set myException exception)))
          (assert_equal "NuIncorrectNumberOfArguments" (myException name)))
     
     (imethod (id) testNoInstanceVariable is
          (try
              (class TestClass is NSObject
                   (imethod (id) accessMissingIvar is @foo))
              (((TestClass alloc) init) accessMissingIvar)
              (catch (exception) (set myException exception)))
          (assert_equal "NuNoInstanceVariable" (myException name))))





