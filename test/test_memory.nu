;; test_memory.nu
;;  tests for Nu memory management.
;;
;;  Copyright (c) 2008 Tim Burks, Neon Design Technology, Inc.

(class TestMemory is NuTestCase
     
     (- testCreationInObjCUsingObjC is
        (NuTestHelper resetDeallocationCount)
        (5 times:
           (do (i)
               (set x (NuTestHelper helperInObjCUsingAllocInit))))
        (assert_equal 5 (NuTestHelper deallocationCount)))
     
     (- testCreationInNuUsingObjC is
        (NuTestHelper resetDeallocationCount)
        (4 times:
           (do (i)
               (set x (NuTestHelper helperInNuUsingAllocInit))))
        (assert_equal 4 (NuTestHelper deallocationCount)))
     
     (- testCreationInObjCUsingNu is
        (NuTestHelper resetDeallocationCount)
        (3 times:
           (do (i)
               (set x (NuTestHelper helperInObjCUsingNew))))
        (assert_equal 3 (NuTestHelper deallocationCount)))
     
     (- testCreationInObjCUsingNuWithOwnership is
        (NuTestHelper resetDeallocationCount)
        (5 times:
           (do (j)
               (set a (array))
               (2 times:
                  (do (i)
                      (set x (NuTestHelper helperInObjCUsingNew))
                      (a << x)))
               (assert_equal 0 (NuTestHelper deallocationCount))))
        (assert_equal 10 (NuTestHelper deallocationCount))))

(class NuTestHelper
     (+ new is
        ((self alloc) init))
     
     (+ helperInNuUsingAllocInit is
        ((self alloc) init))
     
     (- init is
        (super init)
        self))