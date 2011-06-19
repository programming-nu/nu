;; test_errors.nu
;;  tests for Nu errors that throw exceptions.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

;; use these functions to call class construction operators outside of any class scope.
(function misplaced-ivar () (ivar (id) foo))

(class TestErrors is NuTestCase
     
     (- (id) testMisplacedIvar is
        (try
            (misplaced-ivar)
            (catch (exception) (set myException exception)))
        (assert_equal "NuMisplacedDeclaration" (myException name)))
     
     (- (id) testUndefinedClass is
        (try
            (class Undefined)
            (catch (exception) (set myException exception)))
        (assert_equal "NuUndefinedClass" (myException name)))
     
     (- (id) testUndefinedSuperClass is
        (try
            (class Undefined is AlsoUndefined)
            (catch (exception) (set myException exception)))
        (assert_equal "NuUndefinedSuperclass" (myException name)))
     
     (- (id) testParseError is
        (try
            (parse "(1 + ))") ;; parse error
            (catch (exception) (set myException exception)))
        (assert_equal "NuParseError" (myException name)))
     
     (- (id) testUndefinedSymbol is
        (try
            foo ;; undefined symbol
            (catch (exception) (set myException exception)))
        (assert_equal "NuUndefinedSymbol" (myException name)))
     
     (- (id) testCarOnAtom is
        (try
            (car 'foo) ;; can't call car on atoms
            (catch (exception) (set myException exception)))
        (assert_equal "NuCarCalledOnAtom" (myException name)))
     
     (- (id) testCdrOnAtom is
        (try
            (cdr 'foo) ;; can't call cdr on atoms
            (catch (exception) (set myException exception)))
        (assert_equal "NuCdrCalledOnAtom" (myException name)))
     
     (- (id) testIncorrectNumberOfBlockArguments is
        (try
            ((do (x y) (+ x y)) 1 2 3) ;; incorrect number of block arguments
            (catch (exception) (set myException exception)))
        (assert_equal "NuIncorrectNumberOfArguments" (myException name))))
     
