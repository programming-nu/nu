;; test_references.nu
;;  tests for Nu pass-by-reference extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestReferences is NuTestCase
	
     (imethod (id) testReturnByReference is          
          (class ReferenceClass is NSObject
               (+ (void) returnByReference:(id *) reference is
                  (reference setValue:99)))
          (ReferenceClass returnByReference:(set reference (NuReference new)))	
          (assert_equal 99 (reference value))))
