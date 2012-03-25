;; test_truth.nu
;;  tests for Nu representations of truth and falseness.
;;
;;  Copyright (c) 2007 Tim Burks, Radtastical Inc.

(class TestTruth is NuTestCase
     
     (- (id) testTrue is
        (assert_equal "true" (if 1 (then "true") (else "false")))
        (assert_equal "true" (if YES (then "true") (else "false")))
        (assert_equal "true" (if (list 1 2 3) (then "true") (else "false")))
        (assert_equal "true" (if "zero" (then "true") (else "false")))
        (assert_equal "true" (if "false" (then "true") (else "false"))))
     
     (- (id) testFalse is
        (assert_equal "false" (if 0 (then "true") (else "false")))
        (assert_equal "false" (if NO (then "true") (else "false")))
        (assert_equal "false" (if nil (then "true") (else "false")))))





