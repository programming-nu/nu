;; test_errors.nu
;;  tests for Nu errors that throw exceptions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

;; use these functions to call class construction operators outside of any class scope.
(function misplaced-imethod () (imethod foo is nil))
(function misplaced-cmethod () (cmethod foo is nil))
(function misplaced-ivar () (ivar (id) foo))
(function misplaced-ivars () (ivars))

(class TestErrors is NuTestCase
     
     (imethod (id) testMisplacedImethod is
          (try 
               (misplaced-imethod)
               (catch (exception) (set myException exception)))
          (assert_equal "NuMisplacedDeclaration" (myException name)))
     
     (imethod (id) testMisplacedCmethod is
          (try 
               (misplaced-cmethod)
               (catch (exception) (set myException exception)))
          (assert_equal "NuMisplacedDeclaration" (myException name)))
     
     (imethod (id) testMisplacedIvar is
          (try 
               (misplaced-ivar)
               (catch (exception) (set myException exception)))
          (assert_equal "NuMisplacedDeclaration" (myException name)))
     
     (imethod (id) testMisplacedIvars is
          (try 
               (misplaced-ivars)
               (catch (exception) (set myException exception)))
          (assert_equal "NuMisplacedDeclaration" (myException name)))
     
     (imethod (id) testUndefinedClass is
          (try 
               (class Undefined)
               (catch (exception) (set myException exception)))
          (assert_equal "NuUndefinedClass" (myException name)))
     
     (imethod (id) testUndefinedSuperClass is
          (try 
               (class Undefined is AlsoUndefined)
               (catch (exception) (set myException exception)))
          (assert_equal "NuUndefinedSuperclass" (myException name)))
     
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





