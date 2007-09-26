;; test_array.nu
;;  tests for Nu array extensions.
;;
;;  Copyright (c) 2007 Tim Burks, Neon Design Technology, Inc.

(class TestArray is NuTestCase
     
     (imethod (id) testCreate is
          (set a (NSMutableArray arrayWithList:'(1 2))) 
		  (a << "three")
          (assert_equal 3 (a count))
          (assert_equal 2 (a 1))
          (assert_equal "three" (a 2))))           
