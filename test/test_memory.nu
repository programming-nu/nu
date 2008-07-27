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
        (assert_equal 10 (NuTestHelper deallocationCount)))
     
     (- testIvarReleaseOnDealloc is
        (class IvarReleaseHelper is NuTestHelper
             ;;(ivar (id) x) ;; currently declared ivars are not released, this is consistent with unretained outlets
             (ivars)
             (ivar-accessors)
             (set myDeallocationCount 0) ;; closure gives this variable class scope.
             (+ (int) myDeallocationCount is myDeallocationCount)
             (- (void) dealloc is
                (set myDeallocationCount (+ myDeallocationCount 1))
                (set self nil) ;; remove self from the evaluation context to prevent a crash when the context releases its contents upon deallocation.
                (super dealloc)))
        (NuTestHelper resetDeallocationCount)
        (let () ;; let wraps its evaluation with a dedicated autorelease pool
             (set f ((IvarReleaseHelper alloc) init))
             (f setX:((IvarReleaseHelper alloc) init))
             (f setY:((IvarReleaseHelper alloc) init))
             ((f x) setX:(f y))
             (f setZ:(f x))
             (set f nil))
        (assert_equal 3 (NuTestHelper deallocationCount))
        (assert_equal 3 (IvarReleaseHelper myDeallocationCount))))

(class NuTestHelper
     (+ new is
        ((self alloc) init))
     
     (+ helperInNuUsingAllocInit is
        ((self alloc) init))
     
     (- init is
        (super init)
        self))
