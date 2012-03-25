;; test_set.nu
;;  tests for Nu set extensions.
;;
;;  Copyright (c) 2010 Tim Burks, Radtastical Inc.

(class TestSet is NuTestCase
     
     (- testCreate is
        (set sample (NSSet setWithList:'(1 2 3 4 5 5 5)))
        (assert_equal '(1 2 3 4 5) (sort (sample list)))))
