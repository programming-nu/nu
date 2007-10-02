;; test_errors.nu
;;  tests for Nu errors that throw exceptions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestErrors is NuTestCase
     
     (imethod (id) testCarOnAtom is
          (try
              (car 'foo)
              (catch (exception)
                     (set myException exception)))
          (assert_equal "NuCarCalledOnAtom" (myException name)))
     
     (imethod (id) testCdrOnAtom is
          (try
              (cdr 'foo)
              (catch (exception)
                     (set myException exception)))
          (assert_equal "NuCdrCalledOnAtom" (myException name))))
